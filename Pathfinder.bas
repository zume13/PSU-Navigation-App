B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' Class Module: Pathfinder
Sub Class_Globals
	Private sql As SQL
	Private GraphNodes As Map ' Holds NodeID -> Main.MapNode
	Private GraphEdges As Map ' Holds NodeID -> Map of (NeighborID -> Distance)
End Sub

' Initializes the object and loads the graph into RAM for instant pathfinding
Public Sub Initialize(db As SQL)
	sql = db
	GraphNodes.Initialize
	GraphEdges.Initialize
	LoadGraphFromDB
End Sub

' --- MEMORY CACHING: Loads SQLite into RAM ---
Private Sub LoadGraphFromDB
	' 1. Load all Nodes into memory
	Dim rs As ResultSet = sql.ExecQuery("SELECT NodeID, Lat, Lon FROM Nodes")
	Do While rs.NextRow
		Dim mn As MapNode
		mn.Initialize
		mn.Lat = rs.GetDouble("Lat")
		mn.Lon = rs.GetDouble("Lon")
		GraphNodes.Put(rs.GetInt("NodeID"), mn)
	Loop
	rs.Close

	' 2. Load all Edges into memory (Bidirectional)
	Dim rsEdges As ResultSet = sql.ExecQuery("SELECT NodeA, NodeB, Distance FROM Edges")
	Do While rsEdges.NextRow
		Dim nA As Int = rsEdges.GetInt("NodeA")
		Dim nB As Int = rsEdges.GetInt("NodeB")
		
		' Auto-calculate the real distance using the Lat/Lon of the two nodes!
		Dim node1 As MapNode = GraphNodes.Get(nA)
		Dim node2 As MapNode = GraphNodes.Get(nB)
		Dim dist As Double = CalculateDistance(node1.Lat, node1.Lon, node2.Lat, node2.Lon)
		
		' --- ADD THIS LINE TO VERIFY THE MATH ---
		'Log("Edge from Node " & nA & " to " & nB & " is exactly: " & NumberFormat(dist, 1, 2) & " meters")

		' Build Path from A to B
		If GraphEdges.ContainsKey(nA) = False Then
			Dim neighborsA As Map
			neighborsA.Initialize
			GraphEdges.Put(nA, neighborsA)
		End If
		Dim nA_Map As Map = GraphEdges.Get(nA)
		nA_Map.Put(nB, dist)

		' Build Path from B to A (Walkways go both directions!)
		If GraphEdges.ContainsKey(nB) = False Then
			Dim neighborsB As Map
			neighborsB.Initialize
			GraphEdges.Put(nB, neighborsB)
		End If
		Dim nB_Map As Map = GraphEdges.Get(nB)
		nB_Map.Put(nA, dist)
	Loop
	rsEdges.Close
	Log("Pathfinder Loaded: " & GraphNodes.Size & " nodes ready.")
End Sub

' --- DIJKSTRA'S SHORTEST PATH ALGORITHM ---
Public Sub GetShortestPath(StartID As Int, TargetID As Int) As List
	Dim RouteList As List
	RouteList.Initialize

	' Safety check
	If GraphNodes.ContainsKey(StartID) = False Or GraphNodes.ContainsKey(TargetID) = False Then
		Log("Routing Error: Start or Target Node missing.")
		Return RouteList
	End If

	Dim Distances As Map
	Dim Previous As Map
	Dim Unvisited As List

	Distances.Initialize
	Previous.Initialize
	Unvisited.Initialize

	' Set initial distances to "Infinity"
	For Each NodeID As Int In GraphNodes.Keys
		Distances.Put(NodeID, 999999999)
		Unvisited.Add(NodeID)
	Next
	Distances.Put(StartID, 0) ' Start node is 0 meters away

	
	
	' The Algorithm Loop
	Do While Unvisited.Size > 0
		' Find the unvisited node with the smallest known distance
		Dim CurrentNode As Int = -1
		Dim MinDist As Double = 999999999

		For i = 0 To Unvisited.Size - 1
			Dim nID As Int = Unvisited.Get(i)
			Dim d As Double = Distances.Get(nID)
			If d < MinDist Then
				MinDist = d
				CurrentNode = nID
			End If
		Next

		' Stop if we hit a dead end, or if we found the target building!
		If CurrentNode = -1 Or CurrentNode = TargetID Then Exit

		' Mark current node as visited
		Unvisited.RemoveAt(Unvisited.IndexOf(CurrentNode))

		' Check neighbors and calculate edge weights
		If GraphEdges.ContainsKey(CurrentNode) Then
			Dim Neighbors As Map = GraphEdges.Get(CurrentNode)
			For Each NeighborID As Int In Neighbors.Keys
				If Unvisited.IndexOf(NeighborID) > -1 Then ' Only check unvisited neighbors
					Dim altDist As Double = Distances.Get(CurrentNode) + Neighbors.Get(NeighborID)
					Dim currentNeighborDist As Double = Distances.Get(NeighborID)

					' If we found a faster shortcut, update it!
					If altDist < currentNeighborDist Then
						Distances.Put(NeighborID, altDist)
						Previous.Put(NeighborID, CurrentNode)
					End If
				End If
			Next
		End If
	Loop

	' --- RECONSTRUCT THE PATH ---
	Dim PathNodes As List
	PathNodes.Initialize

	Dim StepNode As Int = TargetID
	If Previous.ContainsKey(StepNode) Or StepNode = StartID Then
		Do While StepNode <> StartID
			PathNodes.Add(StepNode)
			StepNode = Previous.Get(StepNode)
		Loop
		PathNodes.Add(StartID)
	End If

	' The path was built backwards (Target to Start), so we reverse it
	For i = PathNodes.Size - 1 To 0 Step -1
		Dim nID As Int = PathNodes.Get(i)
		RouteList.Add(GraphNodes.Get(nID)) ' Convert NodeID back to actual Lat/Lon
	Next

	Return RouteList
End Sub

' --- HAVERSINE FORMULA (Calculates exact meters between two GPS coordinates) ---
Private Sub CalculateDistance(Lat1 As Double, Lon1 As Double, Lat2 As Double, Lon2 As Double) As Double
	Dim R As Double = 6371000 ' Earth's radius in meters
	Dim dLat As Double = (Lat2 - Lat1) * cPI / 180
	Dim dLon As Double = (Lon2 - Lon1) * cPI / 180
	
	Dim lat1Rad As Double = Lat1 * cPI / 180
	Dim lat2Rad As Double = Lat2 * cPI / 180
	
	Dim a As Double = Sin(dLat / 2) * Sin(dLat / 2) + Cos(lat1Rad) * Cos(lat2Rad) * Sin(dLon / 2) * Sin(dLon / 2)
	Dim c As Double = 2 * ATan2(Sqrt(a), Sqrt(1 - a))
	
	Return R * c ' Returns the distance in exact meters!
End Sub