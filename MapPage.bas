B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=13.4
@EndOfDesignText@
#Region Activity Attributes
    #FullScreen: False
    #IncludeTitle: False
#End Region

Sub Process_Globals
	Private sql1 As SQL
	Private sqlData As SQL
	
	Private TILE_SIZE As Int = 256
	Private MinTileX As Int, MaxTileX As Int
	Private MinTileY As Int, MaxTileY As Int

	Type MapNode (Lat As Double, Lon As Double, X22 As Double, Y22 As Double)
	
	Private router As Pathfinder
	
	Type BuildingInfo( _
		Name As String, _
		Category As String, _
		Description As String, _
		Rooms() As String, _
		PhotoFile As String, _
		Lat As Double, _
		Lon As Double _
	)
	
	Dim SelectedPinTag As String
End Sub

Sub Globals
	' --- THE LAYER SYSTEM ---
	Private pnlCanvasA As Panel
	Private pnlTouch As Panel  ' The fixed invisible glass that tracks your finger
	
	' --- THE TV WALL (HD Grid) ---
	Private Const MAX_COLS As Int = 15
	Private Const MAX_ROWS As Int = 25
	Private TileViewsA(MAX_COLS, MAX_ROWS) As ImageView
	Private TilesAcross As Int
	Private TilesDown As Int
	
	' --- MEMORY CACHE ---
	Private TileCache As Map
	Private ZoomBoundsCache As Map
	
	' --- CONTINUOUS CAMERA CACHE ---
	Private CameraZoom As Double
	Private CameraCenterX As Double
	Private CameraCenterY As Double
	Private InitialCameraZoom As Double
	Private InitialWorldX As Double
	Private InitialWorldY As Double
	Private LastRenderedZoom As Int = -1
	Private LastRenderedCenterX As Int = -999999
	Private LastRenderedCenterY As Int = -999999
	Private CurrentPanelScale As Float = -1
	
	' --- TOUCH & GESTURE CACHE ---
	Private LastTouchX As Float
	Private LastTouchY As Float
	Private IsPinching As Boolean = False
	Private InitialPinchDistance As Float = 0
	Private PinchMidX As Float
	Private PinchMidY As Float
	Private IgnoreNextDrag As Boolean = False
	Private IsUserTouching As Boolean = False

	' --- ROUTING CACHE ---
	Private pnlRoute As Panel
	Private cvsRoute As Canvas
	Private CurrentRoute As List
	Private RouteBaseX As Double = -999999
	Private RouteBaseY As Double = -999999
	Private RouteBaseZoom As Double = -1
	Private RoutePanelScale As Float = 1.0
	
	' --- TEST UI ---
	Private pnlTestUI As Panel
	Private txtStart As EditText
	Private txtEnd As EditText
	Private btnTestRoute As Button

	' --- GPS & BLUE DOT ---
	Private flp As FusedLocationProvider
	Private rp As RuntimePermissions
	Private pnlBlueDot As Panel
	Private DOT_SIZE As Int = 16dip
	Private CurrentLat As Double = 0
	Private CurrentLon As Double = 0
	Private DotX22 As Double = 0
	Private DotY22 As Double = 0
	
	' --- MAP PINS CACHE ---
	Private ActivePins As List
    
	Private BuildingButton As Panel
	Private MapButton As Panel
	Private QrButton As Panel
	Private searchEditText As EditText
	Private BottomPanel As Panel
	Private TopPanel As Panel

	Private appWidth    As Int
	Private appHeight   As Int
	
	Private TileLoadCount As Int

	Private ModeIcon As ImageView
	
	Dim BottomCard As ASDraggableBottomCard
	Dim btnNavigate     As Button
	Dim btnClose        As Button
	Dim lblCategory     As Label
	Dim lblBuildingName As Label
	Dim lblDescription  As Label
	Dim lblRoomsHeader  As Label
	Dim lblRooms        As Label
	Dim lblPhotosHeader As Label
	Dim imgPhoto        As ImageView
	
	Dim PinList As List
	Dim PinDataMap As Map

	Private DirectionB As Panel
	Private RefocusB As Panel
	Private CcsB As Panel
	Private CieB As Panel
	Private Coe1B As Panel
	Private Coe2B As Panel
	Private CsspB As Panel
	Private FromT As EditText
	Private PastilB As Panel
	Private ToT As EditText
	
	Private xui As XUI
	
	Dim LastEditText As EditText
	
	Private CcsL As Label
	Private CieL As Label
	Private Coe1 As Label
	Private Coe2 As Label
	Private CsspL As Label
	Private PastilL As Label
	Private DirectionP As Panel
End Sub

Sub Activity_Create(FirstTime As Boolean)
	' STEP 1 - Load layout first so buttons are initialized
	Activity.LoadLayout("Map")
	ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "sun.png")
	
#Region BSHEET
	BottomCard.Initialize(Me, "BottomCard")
	BottomCard.BodyDrag = True
	BottomCard.DarkPanelClickable = False
	BottomCard.UserCanClose = True
	BottomCard.Create( _
		Activity, _
		45%y, _
		85%y, _
		12%y, _
		100%x, _
		BottomCard.Orientation_MIDDLE _
	)
	BottomCard.CornerRadius_Header = 1.5%x

	BottomCard.HeaderPanel.Color = Colors.White

	' Drag pill
	Dim pill As Panel
	pill.Initialize("")
	Dim pillShape As ColorDrawable
	pillShape.Initialize(Colors.ARGB(120, 0, 0, 0), 1%x)
	pill.Background = pillShape
	Dim pillW As Int = 10%x
	Dim pillH As Int = 0.6%y
	BottomCard.HeaderPanel.AddView(pill, 50%x - pillW / 2, 1%y, pillW, pillH)

	btnNavigate.Initialize("btnNavigate")
	btnNavigate.Text = "  Navigate Here"
	btnNavigate.TextSize = 18
	btnNavigate.TextColor = Colors.White
	Dim navBtnW As Int = 65%x
	Dim navBtnH As Int = 6%y
	Dim btnShape As ColorDrawable
	btnShape.Initialize(Colors.ARGB(255, 160, 30, 45), 10%x)
	btnNavigate.Background = btnShape
	BottomCard.HeaderPanel.AddView(btnNavigate, 50%x - navBtnW / 2, 3%y, navBtnW, navBtnH)

	btnClose.Initialize("btnClose")
	btnClose.Text = "✕"
	btnClose.TextSize = 14
	btnClose.TextColor = Colors.ARGB(255, 80, 80, 80)
	Dim closeBtnSize As Int = 11%x
	Dim closeShape As ColorDrawable
	closeShape.Initialize(Colors.ARGB(255, 230, 230, 230), 4%x)
	btnClose.Background = closeShape
	BottomCard.HeaderPanel.AddView(btnClose, 96%x - closeBtnSize, 1.5%y, closeBtnSize, closeBtnSize)

	BottomCard.BodyPanel.Color = Colors.White
	Dim pad As Int = 5%x
	Dim curY As Int = 1%y

	lblCategory.Initialize("")
	lblCategory.TextSize = 14
	lblCategory.Typeface = Typeface.DEFAULT_BOLD
	lblCategory.TextColor = Colors.ARGB(255, 120, 120, 120)
	BottomCard.BodyPanel.AddView(lblCategory, pad, curY, 92%x, 3%y)
	curY = curY + 2.0%y

	lblBuildingName.Initialize("")
	lblBuildingName.TextSize = 22
	lblBuildingName.TextColor = Colors.ARGB(255, 160, 30, 45)
	lblBuildingName.Typeface = Typeface.DEFAULT_BOLD
	lblBuildingName.Gravity = Gravity.TOP
	BottomCard.BodyPanel.AddView(lblBuildingName, pad, curY, 92%x, 8%y)
	curY = curY + 6.0%y

	lblDescription.Initialize("")
	lblDescription.TextSize = 16
	lblDescription.TextColor = Colors.ARGB(255, 60, 60, 60)
	lblDescription.Gravity = Gravity.TOP
	BottomCard.BodyPanel.AddView(lblDescription, pad, curY, 92%x, 14%y)
	curY = curY + 15%y

	lblRoomsHeader.Initialize("")
	lblRoomsHeader.Text = "Rooms"
	lblRoomsHeader.TextSize = 18
	lblRoomsHeader.TextColor = Colors.Black
	lblRoomsHeader.Typeface = Typeface.DEFAULT_BOLD
	BottomCard.BodyPanel.AddView(lblRoomsHeader, pad, curY, 92%x, 4%y)
	curY = curY + 4.5%y

	lblRooms.Initialize("")
	lblRooms.TextSize = 16
	lblRooms.TextColor = Colors.ARGB(255, 60, 60, 60)
	lblRooms.Gravity = Gravity.TOP
	BottomCard.BodyPanel.AddView(lblRooms, pad, curY, 92%x, 10%y)
	curY = curY + 11%y

	lblPhotosHeader.Initialize("")
	lblPhotosHeader.Text = "Photos"
	lblPhotosHeader.TextSize = 18
	lblPhotosHeader.TextColor = Colors.Black
	lblPhotosHeader.Typeface = Typeface.DEFAULT_BOLD
	BottomCard.BodyPanel.AddView(lblPhotosHeader, pad, curY, 92%x, 4%y)
	curY = curY + 4.5%y

	imgPhoto.Initialize("")
	imgPhoto.Gravity = Gravity.FILL
	BottomCard.BodyPanel.AddView(imgPhoto, pad, curY, 92%x, 22%y)

	' Sheet stays hidden until a pin is tapped — do NOT call Show() here
#End Region

#Region MAP INIT
	If TileCache.IsInitialized = False Then TileCache.Initialize
	TileCache.Clear
	
	If ZoomBoundsCache.IsInitialized = False Then ZoomBoundsCache.Initialize
	
	' -----------------------------
	' DATABASE INIT
	' -----------------------------
	If File.Exists(File.DirInternal, "psu_map.mbtiles") = False Then
		File.Copy(File.DirAssets, "psu_map.mbtiles", File.DirInternal, "psu_map.mbtiles")
	End If
	
	' --- FORCE OVERWRITE DURING DEVELOPMENT ---
	' This guarantees you always have the newest database from your Files tab!
	File.Copy(File.DirAssets, "psu_data.db", File.DirInternal, "psu_data.db")
	
	If sql1.IsInitialized = False Then
		sql1.Initialize(File.DirInternal, "psu_map.mbtiles", False)
	End If
	
	If sqlData.IsInitialized = False Then
		sqlData.Initialize(File.DirInternal, "psu_data.db", False)
	End If
	
	router.Initialize(sqlData)
	
	' -----------------------------
	' PRE-CACHE BOUNDS FOR ALL ZOOMS
	' -----------------------------
	ZoomBoundsCache.Clear
	For z = 18 To 22
		Dim rsZ As ResultSet = sql1.ExecQuery2( _
			"SELECT MIN(tile_column), MAX(tile_column), MIN(tile_row), MAX(tile_row) FROM tiles WHERE zoom_level = ?", _
			Array As String(z))
		If rsZ.NextRow Then
			Dim bz(4) As Int
			bz(0) = rsZ.GetInt2(0)
			bz(1) = rsZ.GetInt2(1)
			bz(2) = rsZ.GetInt2(2)
			bz(3) = rsZ.GetInt2(3)
			ZoomBoundsCache.Put(z, bz)
		End If
		rsZ.Close
	Next
	
	' -----------------------------
	' SCREEN TILE COVERAGE
	' -----------------------------
	TilesAcross = Ceil((100%x / TILE_SIZE) * 1.5) + 2
	TilesDown = Ceil((100%y / TILE_SIZE) * 1.5) + 2

	If TilesAcross > MAX_COLS Then TilesAcross = MAX_COLS
	If TilesDown > MAX_ROWS Then TilesDown = MAX_ROWS
	
	' -----------------------------
	' MAP LAYER A
	' -----------------------------
	pnlCanvasA.Initialize("")
	pnlCanvasA.Color = Colors.RGB(238, 235, 225)
	Activity.AddView(pnlCanvasA, -TILE_SIZE, -TILE_SIZE, TilesAcross * TILE_SIZE, TilesDown * TILE_SIZE)
	
	For col = 0 To TilesAcross - 1
		For row = 0 To TilesDown - 1
			TileViewsA(col, row).Initialize("")
			TileViewsA(col, row).Gravity = Gravity.FILL
			pnlCanvasA.AddView(TileViewsA(col, row), col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
		Next
	Next
	
	' -----------------------------
	' ROUTE LAYER
	' -----------------------------
	pnlRoute.Initialize("")
	pnlRoute.Color = Colors.Transparent
	Activity.AddView(pnlRoute, 0, 0, 100%x, 100%y)
	cvsRoute.Initialize(pnlRoute)
	CurrentRoute.Initialize
	
	' -----------------------------
	' BLUE DOT
	' -----------------------------
	pnlBlueDot.Initialize("")
	Dim cd As ColorDrawable
	cd.Initialize2(Colors.Blue, DOT_SIZE / 2, 2dip, Colors.White)
	pnlBlueDot.Background = cd
	pnlBlueDot.Visible = False
	Activity.AddView(pnlBlueDot, 0, 0, DOT_SIZE, DOT_SIZE)
	
	' -----------------------------
	' TOUCH LAYER
	' -----------------------------
	pnlTouch.Initialize("")
	Activity.AddView(pnlTouch, 0, 0, 100%x, 100%y)
	
	Dim r As Reflector
	r.Target = pnlTouch
	r.SetOnTouchListener("MapTouch")
	
	' -----------------------------
	' MAP PINS
	' -----------------------------
	LoadFacilityPins
	
	' -----------------------------
	' INITIAL CAMERA SETTINGS
	' -----------------------------
	CameraZoom = 22.0
	CameraCenterX = GetTileX(120.655083, 22)
	CameraCenterY = GetTileY(14.997889, 22)
	
	RenderCamera
	
	' -----------------------------
	' TEST UI
	' -----------------------------
'	pnlTestUI.Initialize("")
'	pnlTestUI.Color = Colors.ARGB(220, 255, 255, 255)
'	Activity.AddView(pnlTestUI, 10dip, 10dip, 100%x - 20dip, 60dip)
'	
'	txtStart.Initialize("")
'	txtStart.Hint = "Fac ID 1"
'	txtStart.InputType = txtStart.INPUT_TYPE_NUMBERS
'	txtStart.TextColor = Colors.Black
'	pnlTestUI.AddView(txtStart, 10dip, 10dip, 80dip, 40dip)
'	
'	txtEnd.Initialize("")
'	txtEnd.Hint = "Fac ID 2"
'	txtEnd.InputType = txtEnd.INPUT_TYPE_NUMBERS
'	txtEnd.TextColor = Colors.Black
'	pnlTestUI.AddView(txtEnd, 100dip, 10dip, 80dip, 40dip)
'	
'	btnTestRoute.Initialize("btnTestRoute")
'	btnTestRoute.Text = "DRAW"
'	pnlTestUI.AddView(btnTestRoute, 190dip, 10dip, 80dip, 40dip)
	
	' -----------------------------
	' GPS PERMISSIONS (Placed last to prevent UI blocking)
	' -----------------------------
	rp.CheckAndRequest(rp.PERMISSION_ACCESS_FINE_LOCATION)
	Wait For Activity_PermissionResult (Permission As String, Result As Boolean)
	
	If Result Then
		flp.Initialize("flp")
		flp.Connect
	Else
		ToastMessageShow("Location permission denied. Blue Dot disabled.", True)
	End If
#End Region

#Region NAV-FOOT ANIM
	TopPanel.Top = -TopPanel.Height
	BottomPanel.Top = 100%y
	Sleep(300)
	TopPanel.SetLayoutAnimated(500, TopPanel.Left, 45dip, TopPanel.Width, TopPanel.Height)
	BottomPanel.SetLayoutAnimated(500, BottomPanel.Left, 100%y - BottomPanel.Height, BottomPanel.Width, BottomPanel.Height)
#End Region

	TopPanel.BringToFront
	BottomPanel.BringToFront
	RefocusB.BringToFront
	DirectionB.BringToFront
End Sub

Sub Activity_Resume
	appWidth  = Activity.Width
	appHeight = Activity.Height
End Sub

Sub Activity_Pause(UserClosed As Boolean)
	TileCache.Clear
	TileLoadCount = 0
	ActivePins.Clear
End Sub

#Region BOT CARD EVETS
Sub BottomCard_Open
	' kapag na trigger ung pagbukas ng sheet
	BottomPanel.Visible = False
	TopPanel.Visible = False
End Sub

Sub BottomCard_Opened
	' kapag nag bukas ung sheet
	Log("Sheet is fully open")
End Sub

Sub BottomCard_Close
	' kapag nag start closing animation
	Log("Sheet is closing")
End Sub

Sub BottomCard_Closed
	' kapag nag sara
	BottomPanel.Visible = True
	TopPanel.Visible = True
	TopPanel.Top = -TopPanel.Height
	BottomPanel.Top = 100%y
	TopPanel.SetLayoutAnimated(400, TopPanel.Left, 45dip, TopPanel.Width, TopPanel.Height)
	BottomPanel.SetLayoutAnimated(400, BottomPanel.Left, 100%y - BottomPanel.Height, BottomPanel.Width, BottomPanel.Height)
End Sub

Sub BottomCard_VisibleBodyHeightChanged(height As Double)
	' kapag dinadrag
End Sub
#End Region

Sub SetAnimation(InAnim As String, OutAnim As String)
	Dim r As Reflector
	Dim package As String
	Dim inAnimID, outAnimID As Int
    
	package = r.GetStaticField("anywheresoftware.b4a.BA", "packageName")
	inAnimID = r.GetStaticField(package & ".R$anim", InAnim)
	outAnimID = r.GetStaticField(package & ".R$anim", OutAnim)
    
	r.Target = r.GetActivity
	r.RunMethod4("overridePendingTransition", Array As Object(inAnimID, outAnimID), Array As String("java.lang.int", "java.lang.int"))
End Sub

#Region BUTTONS
Private Sub PastilB_Touch (Action As Int, X As Float, Y As Float)
	If LastEditText <> Null Then
		LastEditText.Text = PastilL.Text
	Else
		xui.MsgboxAsync("Notice", "Select what to fill in")
		Return
	End If
End Sub

Private Sub CsspB_Touch (Action As Int, X As Float, Y As Float)
	If LastEditText <> Null Then
		LastEditText.Text = CsspL.Text
	Else
		xui.MsgboxAsync("Notice", "Select what to fill in")
		Return
	End If
End Sub

Private Sub Coe2B_Touch (Action As Int, X As Float, Y As Float)
	If LastEditText <> Null Then
		LastEditText.Text = Coe2.Text
	Else
		xui.MsgboxAsync("Notice", "Select what to fill in")
		Return
	End If
End Sub

Private Sub Coe1B_Touch (Action As Int, X As Float, Y As Float)
	If LastEditText <> Null Then
		LastEditText.Text = Coe1.Text
	Else
		xui.MsgboxAsync("Notice", "Select what to fill in")
		Return
	End If
End Sub

Private Sub CieB_Touch (Action As Int, X As Float, Y As Float)
	If LastEditText <> Null Then
		LastEditText.Text = CieL.Text
	Else
		xui.MsgboxAsync("Notice", "Select what to fill in")
		Return
	End If
End Sub

Private Sub CcsB_Touch (Action As Int, X As Float, Y As Float)
	If LastEditText <> Null Then 
		LastEditText.Text = CcsL.Text
	Else 
		xui.MsgboxAsync("Notice", "Select what to fill in")
		Return
	End If
End Sub

Private Sub ArrowB_Click
	DirectionP.SetLayoutAnimated(600, 0, -100%y, 100%x, 90%y)
End Sub

Private Sub RefocusB_Touch (Action As Int, X As Float, Y As Float)
	
End Sub

Private Sub DirectionB_Touch (Action As Int, X As Float, Y As Float)
	DirectionP.BringToFront
	DirectionP.SetLayoutAnimated(600, 0, 0, 100%x, 100%y)
End Sub

Private Sub QrButton_Touch(Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		QrButton.Color = Colors.RGB(183, 43, 60)
	Else If Action = 1 Then
		QrButton.Color = Colors.RGB(156, 28, 28)
		StartActivity(QrScannerPage)
		SetAnimation("slide_in_right", "slide_out_left")
		TopPanel.SetLayoutAnimated(100, TopPanel.Left, -TopPanel.Height, TopPanel.Width, TopPanel.Height)
		BottomPanel.SetLayoutAnimated(100, BottomPanel.Left, 100%y, BottomPanel.Width, BottomPanel.Height)
		Activity.Finish
	End If
End Sub

Private Sub MapButton_Touch(Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		MapButton.Color = Colors.RGB(183, 43, 60)
	Else If Action = 1 Then
		MapButton.Color = Colors.RGB(156, 28, 28)
	End If
End Sub

Private Sub BuildingButton_Touch(Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		BuildingButton.Color = Colors.RGB(183, 43, 60)
	Else If Action = 1 Then
		BuildingButton.Color = Colors.RGB(156, 28, 28)
		StartActivity(PlacesPage)
		SetAnimation("slide_in_right", "slide_out_left")
		TopPanel.SetLayoutAnimated(100, TopPanel.Left, -TopPanel.Height, TopPanel.Width, TopPanel.Height)
		BottomPanel.SetLayoutAnimated(100, BottomPanel.Left, 100%y, BottomPanel.Width, BottomPanel.Height)
		Activity.Finish
	End If
End Sub

Private Sub ModeIcon_Click
	Starter.IsDarkMode = Not(Starter.IsDarkMode)
    
	If Starter.IsDarkMode Then
		ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "moon.png")
		TopPanel.Color    = Colors.RGB(30, 30, 30)
		BottomPanel.Color = Colors.RGB(30, 30, 30)
		searchEditText.Color = Colors.White
	Else
		ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "sun.png")
		TopPanel.Color    = Colors.RGB(255, 255, 255)
		BottomPanel.Color = Colors.RGB(142, 30, 44)
	End If
End Sub

Sub Activity_KeyPress(KeyCode As Int) As Boolean
	If KeyCode = KeyCodes.KEYCODE_BACK Then
		Return True
	End If
	Return False
End Sub
#End Region

#Region MAP THINGS

Sub LoadFacilityPins
	ActivePins.Initialize
	
	' 1. Pre-load your icons into memory
	Dim bmpBuilding As Bitmap = LoadBitmap(File.DirAssets, "building_icon_pin.png")
	Dim bmpFood As Bitmap = LoadBitmap(File.DirAssets, "food_icon_pin.png")
	Dim bmpDefault As Bitmap = bmpBuilding
	
	' 2. Query the database (Filter out Priority 0 entirely to save memory!)
	Dim rs As ResultSet = sqlData.ExecQuery("SELECT Category, Name, Lat, Lon, Priority FROM Facilities WHERE Priority > 0")
	
	Do While rs.NextRow
		Dim cat As String = rs.GetString("Category")
		Dim facName As String = rs.GetString("Name")
		Dim facLat As Double = rs.GetDouble("Lat")
		Dim facLon As Double = rs.GetDouble("Lon")
		Dim priorityLvl As Int = rs.GetInt("Priority")
		
		' 3. Choose the correct icon based on Category
		Dim selectedIcon As Bitmap
		If cat = "Building" Then
			selectedIcon = bmpBuilding
		Else If cat = "Food" Then
			selectedIcon = bmpFood
		Else
			selectedIcon = bmpDefault
		End If
		
		' 4. Translate Priority Number into Dual Zoom Thresholds
		Dim pinZoom As Double
		Dim nameZoom As Double
		
		If priorityLvl = 1 Then
			pinZoom = 17.5
			nameZoom = 19
		Else If priorityLvl = 2 Then
			pinZoom = 19
			nameZoom = 20.5
		Else If priorityLvl = 3 Then
			pinZoom = 20.5
			nameZoom = 21
		Else ' Priority 4
			pinZoom = 21
			nameZoom = 21.5
		End If
		
		' 5. Spawn the pin with BOTH Thresholds
		Dim pin As MapPin
		pin.Initialize(GetTileX(facLon, 22), GetTileY(facLat, 22), facName, selectedIcon, pinZoom, nameZoom)
		Activity.AddView(pin.BasePanel, 0, 0, 150dip, 60dip)
		ActivePins.Add(pin)
	Loop
	
	rs.Close
	Log("Successfully loaded " & ActivePins.Size & " facility pins from the database!")
End Sub

' ==============================================================================
' 1. TOUCH & GESTURE ENGINE
' ==============================================================================
Sub MapTouch (ViewTag As Object, Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean 'ignore
	Try
		Dim event As JavaObject = MotionEvent
		Dim pointerCount As Int = event.RunMethod("getPointerCount", Null)
		Dim actionMasked As Int = Bit.And(Action, 255)
		
		If actionMasked = 0 Or actionMasked = 5 Then IsUserTouching = True
		If actionMasked = 1 Or actionMasked = 3 Then IsUserTouching = False
		
		' --- PINCH ZOOM ---
		If pointerCount = 2 Then
			Dim x1 As Float = event.RunMethod("getX", Array As Object(0))
			Dim y1 As Float = event.RunMethod("getY", Array As Object(0))
			Dim x2 As Float = event.RunMethod("getX", Array As Object(1))
			Dim y2 As Float = event.RunMethod("getY", Array As Object(1))
			
			Dim distance As Float = Sqrt(Power(x1 - x2, 2) + Power(y1 - y2, 2))
			PinchMidX = (x1 + x2) / 2
			PinchMidY = (y1 + y2) / 2
			
			If actionMasked = 5 Or IsPinching = False Then
				IsPinching = True
				InitialPinchDistance = distance
				InitialCameraZoom = CameraZoom
				
				Dim worldPerTile As Double = WorldTilesPerScreenTile
				InitialWorldX = CameraCenterX + (((PinchMidX - (100%x / 2)) / TILE_SIZE) * worldPerTile)
				InitialWorldY = CameraCenterY - (((PinchMidY - (100%y / 2)) / TILE_SIZE) * worldPerTile)
				
				Return True
			End If
			
			If actionMasked = 2 And InitialPinchDistance > 0 Then
				Dim zoomDelta As Double = Logarithm(distance / InitialPinchDistance, 2)
				CameraZoom = InitialCameraZoom + zoomDelta
				
				If CameraZoom < 18 Then CameraZoom = 18
				If CameraZoom > 22 Then CameraZoom = 22
				
				Dim worldPerTile As Double = WorldTilesPerScreenTile
				CameraCenterX = InitialWorldX - (((PinchMidX - (100%x / 2)) / TILE_SIZE) * worldPerTile)
				CameraCenterY = InitialWorldY + (((PinchMidY - (100%y / 2)) / TILE_SIZE) * worldPerTile)
				
				ClampCamera
				RenderCamera
				
				Return True
			End If
		End If
		
		' --- DRAGGING ---
		If pointerCount = 1 And IsPinching = False Then
			If actionMasked = 0 Then ' ACTION_DOWN
				LastTouchX = X
				LastTouchY = Y
				IgnoreNextDrag = False
				Return True
				
			Else If actionMasked = 2 Then ' ACTION_MOVE
				If IgnoreNextDrag Then
					LastTouchX = X
					LastTouchY = Y
					IgnoreNextDrag = False
					Return True
				End If
				
				Dim deltaX As Float = X - LastTouchX
				Dim deltaY As Float = Y - LastTouchY
				
				If Abs(deltaX) > 1 Or Abs(deltaY) > 1 Then
					LastTouchX = X
					LastTouchY = Y
					DragCamera(deltaX, deltaY)
				End If
				
				Return True
			End If
		End If
		
		' --- TOUCH END / RELEASE ---
		If actionMasked = 1 Or actionMasked = 6 Or actionMasked = 3 Then
			If IsPinching Then
				IsPinching = False
				InitialPinchDistance = 0
				IgnoreNextDrag = True
				LastRenderedZoom = -1
				RenderCamera
			Else
				IgnoreNextDrag = True
				If actionMasked = 1 Then RenderCamera
			End If
		End If
		
	Catch
		Log("Crash Prevented in MapTouch")
	End Try
	
	Return True
End Sub

Sub DragCamera(deltaX As Float, deltaY As Float)
	Dim worldPerTile As Double = WorldTilesPerScreenTile
	CameraCenterX = CameraCenterX - ((deltaX / TILE_SIZE) * worldPerTile)
	CameraCenterY = CameraCenterY + ((deltaY / TILE_SIZE) * worldPerTile)

	ClampCamera
	RenderCamera
End Sub


' ==============================================================================
' 2. CAMERA & RENDERING PIPELINE
' ==============================================================================
Sub RenderCamera
	Dim baseZoom As Int = Round(CameraZoom)
	
	If baseZoom < 18 Then baseZoom = 18
	If baseZoom > 22 Then baseZoom = 22

	If IsPinching And LastRenderedZoom <> -1 Then
		baseZoom = LastRenderedZoom
	End If

	Dim zoomDifference As Double = CameraZoom - baseZoom
	Dim baseCenter() As Double = CameraCenterAtZoom(baseZoom)
	Dim centerIntX As Int = Floor(baseCenter(0))
	Dim centerIntY As Int = Floor(baseCenter(1))

	If IsPinching = False Then
		If baseZoom <> LastRenderedZoom Or centerIntX <> LastRenderedCenterX Or centerIntY <> LastRenderedCenterY Then
			RenderLayerA(baseZoom, baseCenter(0), baseCenter(1))
			LastRenderedZoom = baseZoom
			LastRenderedCenterX = centerIntX
			LastRenderedCenterY = centerIntY
		End If
	End If

	PositionLayer(pnlCanvasA, baseCenter(0), baseCenter(1), LastRenderedCenterX, LastRenderedCenterY, Power(2, zoomDifference))

	UpdateBlueDotPositionContinuous
	UpdatePinsContinuous
	UpdateRouteIfNeeded
End Sub

Sub RenderLayerA(RenderZoom As Int, CenterX As Double, CenterY As Double)
	Dim startCol As Int = Floor(CenterX) - Floor(TilesAcross / 2)
	Dim startRow As Int = Floor(CenterY) + Floor(TilesDown / 2)

	Dim needsDB As Boolean = False
	For col = 0 To TilesAcross - 1
		For row = 0 To TilesDown - 1
			Dim TileKey As String = RenderZoom & "_" & (startCol + col) & "_" & (startRow - row)
			If TileCache.ContainsKey(TileKey) = False Then
				needsDB = True
				Exit
			End If
		Next
		If needsDB Then Exit
	Next

	If needsDB Then
		Dim minX As Int = startCol
		Dim maxX As Int = startCol + TilesAcross - 1
		Dim minY As Int = startRow - TilesDown + 1
		Dim maxY As Int = startRow
		
		Dim rsBulk As ResultSet = sql1.ExecQuery2( _
			"SELECT tile_column, tile_row, tile_data FROM tiles WHERE zoom_level = ? AND tile_column >= ? AND tile_column <= ? AND tile_row >= ? AND tile_row <= ?", _
			Array As String(RenderZoom, minX, maxX, minY, maxY))
			
		Do While rsBulk.NextRow
			Dim tX As Int = rsBulk.GetInt2(0)
			Dim tY As Int = rsBulk.GetInt2(1)
			Dim tKey As String = RenderZoom & "_" & tX & "_" & tY
			
			If TileCache.ContainsKey(tKey) = False Then
				Dim data() As Byte = rsBulk.GetBlob2(2)
				Dim InStream As InputStream
				InStream.InitializeFromBytesArray(data, 0, data.Length)
				Try
					Dim bmpBulk As Bitmap
					bmpBulk.Initialize2(InStream)
					TileCache.Put(tKey, bmpBulk)
				Catch
					Log("OOM Prevented: Safely skipped loading a tile.")
				End Try
				InStream.Close
			End If
		Loop
		rsBulk.Close
	End If

	For col = 0 To TilesAcross - 1
		For row = 0 To TilesDown - 1
			Dim targetX As Int = startCol + col
			Dim targetY As Int = startRow - row
			
			Dim iv As ImageView = TileViewsA(col, row)
			Dim bmp As Bitmap = LoadTile(RenderZoom, targetX, targetY)
			
			If bmp <> Null And bmp.IsInitialized Then
				iv.Bitmap = bmp
			Else
				iv.Bitmap = Null
			End If
		Next
	Next
	
	EvictOldTiles
End Sub

Sub PositionLayer(TargetPanel As Panel, CenterXAtZoom As Double, CenterYAtZoom As Double, GridBaseX As Int, GridBaseY As Int, ScaleValue As Double)
	Dim centerCol As Int = Floor(TilesAcross / 2)
	Dim centerRow As Int = Floor(TilesDown / 2)

	Dim offsetX As Double = CenterXAtZoom - GridBaseX
	Dim offsetY As Double = CenterYAtZoom - GridBaseY

	TargetPanel.Left = -((centerCol + offsetX) * TILE_SIZE) + (100%x / 2)
	TargetPanel.Top = -((centerRow + (1 - offsetY)) * TILE_SIZE) + (100%y / 2)

	Dim scaleF As Float = ScaleValue
	Dim jo As JavaObject = TargetPanel
	Dim isScaled As Boolean = (Abs(scaleF - 1.0) > 0.001)
	
	If isScaled Then
		Dim pivotX As Float = (100%x / 2) - TargetPanel.Left
		Dim pivotY As Float = (100%y / 2) - TargetPanel.Top
		jo.RunMethod("setPivotX", Array As Object(pivotX))
		jo.RunMethod("setPivotY", Array As Object(pivotY))
		jo.RunMethod("setScaleX", Array As Object(scaleF))
		jo.RunMethod("setScaleY", Array As Object(scaleF))
		CurrentPanelScale = scaleF
	Else
		If CurrentPanelScale <> 1.0 Then
			Dim f1 As Float = 1.0
			jo.RunMethod("setScaleX", Array As Object(f1))
			jo.RunMethod("setScaleY", Array As Object(f1))
			CurrentPanelScale = 1.0
		End If
	End If
End Sub

Sub LoadTile(Z As Int, X As Int, Y As Int) As Bitmap
	Dim TileKey As String = Z & "_" & X & "_" & Y
	If TileCache.ContainsKey(TileKey) Then Return TileCache.Get(TileKey)
	Return Null
End Sub

Sub EvictOldTiles
	If TileCache.Size > 80 Then
		Dim keysToRemove As List
		keysToRemove.Initialize
		For Each k As String In TileCache.Keys
			keysToRemove.Add(k)
			If keysToRemove.Size >= 40 Then Exit
		Next
		For Each k As String In keysToRemove
			TileCache.Remove(k)
		Next
	End If
End Sub


' ==============================================================================
' 3. MATH & BOUNDARIES
' ==============================================================================
Sub ClampCamera
	Dim minZ As Double = 17.5
	Dim maxZ As Double = 22.0

	If CameraZoom < minZ Then CameraZoom = minZ
	If CameraZoom > maxZ Then CameraZoom = maxZ

	Dim baseZ As Int = Round(CameraZoom)
	If baseZ < 18 Then baseZ = 18
	
	If ZoomBoundsCache.ContainsKey(baseZ) Then
		Dim boundsObj As Object = ZoomBoundsCache.Get(baseZ)
		Dim bounds() As Int = boundsObj
		
		Dim tileFactor As Double = Power(2, 22 - baseZ)
		Dim absoluteMinX As Double = bounds(0) * tileFactor
		Dim absoluteMaxX As Double = (bounds(1) + 1) * tileFactor
		Dim absoluteMinY As Double = bounds(2) * tileFactor
		Dim absoluteMaxY As Double = (bounds(3) + 1) * tileFactor

		Dim worldPerTile As Double = WorldTilesPerScreenTile
		Dim halfScreenWidth As Double = ((100%x / TILE_SIZE) / 2.0) * worldPerTile
		Dim halfScreenHeight As Double = ((100%y / TILE_SIZE) / 2.0) * worldPerTile
		
		Dim safeMinX As Double = absoluteMinX + halfScreenWidth
		Dim safeMaxX As Double = absoluteMaxX - halfScreenWidth
		Dim safeMinY As Double = absoluteMinY + halfScreenHeight
		Dim safeMaxY As Double = absoluteMaxY - halfScreenHeight

		If safeMinX > safeMaxX Then
			CameraCenterX = (absoluteMinX + absoluteMaxX) / 2.0
		Else
			If CameraCenterX < safeMinX Then CameraCenterX = safeMinX
			If CameraCenterX > safeMaxX Then CameraCenterX = safeMaxX
		End If
		
		If safeMinY > safeMaxY Then
			CameraCenterY = (absoluteMinY + absoluteMaxY) / 2.0
		Else
			If CameraCenterY < safeMinY Then CameraCenterY = safeMinY
			If CameraCenterY > safeMaxY Then CameraCenterY = safeMaxY
		End If
	End If
End Sub

Sub WorldTilesPerScreenTile As Double
	Return Power(2, 22 - CameraZoom)
End Sub

Sub CameraCenterAtZoom(RenderZoom As Int) As Double()
	Dim factor As Double = Power(2, 22 - RenderZoom)
	Dim arr(2) As Double
	arr(0) = CameraCenterX / factor
	arr(1) = CameraCenterY / factor
	Return arr
End Sub

Sub GetTileX(Lon As Double, Zoom As Int) As Double
	Return (Lon + 180) / 360 * Power(2, Zoom)
End Sub

Sub GetTileY(Lat As Double, Zoom As Int) As Double
	Dim latRad As Double = Lat * cPI / 180
	Dim innerValue As Double = Tan(latRad) + (1 / Cos(latRad))
	Dim naturalLog As Double = Logarithm(innerValue, cE)
	Dim googleY As Double = (1 - (naturalLog / cPI)) / 2 * Power(2, Zoom)
	Return (Power(2, Zoom) - 1) - googleY
End Sub


' ==============================================================================
' 4. ROUTING ENGINE
' ==============================================================================
Sub btnTestRoute_Click
	If txtStart.Text = "" Or txtEnd.Text = "" Then
		ToastMessageShow("Please enter both Facility IDs!", False)
		Return
	End If
	
	Dim startFacID As Int = txtStart.Text
	Dim endFacID As Int = txtEnd.Text
	
	Dim startNodeID As Int = -1
	Dim startLat As Double, startLon As Double
	Dim endNodeID As Int = -1
	Dim endLat As Double, endLon As Double
	
	Dim rsStart As ResultSet = sqlData.ExecQuery2("SELECT TargetNodeID, Lat, Lon FROM Facilities WHERE FacilityID = ?", Array As String(startFacID))
	If rsStart.NextRow Then
		startNodeID = rsStart.GetInt("TargetNodeID")
		startLat = rsStart.GetDouble("Lat")
		startLon = rsStart.GetDouble("Lon")
	End If
	rsStart.Close
	
	Dim rsEnd As ResultSet = sqlData.ExecQuery2("SELECT TargetNodeID, Lat, Lon FROM Facilities WHERE FacilityID = ?", Array As String(endFacID))
	If rsEnd.NextRow Then
		endNodeID = rsEnd.GetInt("TargetNodeID")
		endLat = rsEnd.GetDouble("Lat")
		endLon = rsEnd.GetDouble("Lon")
	End If
	rsEnd.Close
	
	If startNodeID = -1 Or endNodeID = -1 Then
		ToastMessageShow("Invalid Facility ID entered!", True)
		Return
	End If
	
	CurrentRoute = router.GetShortestPath(startNodeID, endNodeID)
	
	If CurrentRoute.IsInitialized And CurrentRoute.Size > 0 Then
		Dim startBuilding As MapNode
		startBuilding.Initialize
		startBuilding.Lat = startLat
		startBuilding.Lon = startLon
		
		Dim endBuilding As MapNode
		endBuilding.Initialize
		endBuilding.Lat = endLat
		endBuilding.Lon = endLon
		
		CurrentRoute.InsertAt(0, startBuilding)
		CurrentRoute.Add(endBuilding)
		
		For i = 0 To CurrentRoute.Size - 1
			Dim mn As MapNode = CurrentRoute.Get(i)
			mn.X22 = GetTileX(mn.Lon, 22)
			mn.Y22 = GetTileY(mn.Lat, 22)
		Next
		
		RouteBaseZoom = -1
		DrawRouteLayerContinuous
	Else
		ToastMessageShow("No path found between those facilities!", True)
	End If
	
	Dim ime As IME
	ime.Initialize("")
	ime.HideKeyboard
End Sub

Sub UpdateRouteIfNeeded
	If CurrentRoute.IsInitialized = False Or CurrentRoute.Size < 2 Then Return

	If IsUserTouching = False Then
		If RouteBaseZoom <> CameraZoom Or RouteBaseX <> CameraCenterX Or RouteBaseY <> CameraCenterY Then
			DrawRouteLayerContinuous
		End If
	End If
	
	PositionRouteLayer
End Sub

Sub PositionRouteLayer
	If RouteBaseZoom = -1 Then Return

	Dim baseWorldPerTile As Double = Power(2, 22 - RouteBaseZoom)
	Dim offsetX As Double = ((RouteBaseX - CameraCenterX) / baseWorldPerTile) * TILE_SIZE
	Dim offsetY As Double = ((CameraCenterY - RouteBaseY) / baseWorldPerTile) * TILE_SIZE

	pnlRoute.Left = offsetX
	pnlRoute.Top = offsetY

	Dim scaleF As Float = Power(2, CameraZoom - RouteBaseZoom)
	Dim jo As JavaObject = pnlRoute
	Dim isScaled As Boolean = (Abs(scaleF - 1.0) > 0.001)
	
	If isScaled Then
		Dim pivotX As Float = (100%x / 2) - pnlRoute.Left
		Dim pivotY As Float = (100%y / 2) - pnlRoute.Top
		jo.RunMethod("setPivotX", Array As Object(pivotX))
		jo.RunMethod("setPivotY", Array As Object(pivotY))
		jo.RunMethod("setScaleX", Array As Object(scaleF))
		jo.RunMethod("setScaleY", Array As Object(scaleF))
		RoutePanelScale = scaleF
	Else
		If RoutePanelScale <> 1.0 Then
			Dim f1 As Float = 1.0
			jo.RunMethod("setScaleX", Array As Object(f1))
			jo.RunMethod("setScaleY", Array As Object(f1))
			RoutePanelScale = 1.0
		End If
	End If
End Sub

Sub DrawRouteLayerContinuous
	cvsRoute.DrawColor(Colors.Transparent)

	If CurrentRoute.IsInitialized = False Or CurrentRoute.Size < 2 Then
		pnlRoute.Invalidate
		Return
	End If

	pnlRoute.Left = 0
	pnlRoute.Top = 0
	Dim jo As JavaObject = pnlRoute
	Dim f1 As Float = 1.0
	jo.RunMethod("setScaleX", Array As Object(f1))
	jo.RunMethod("setScaleY", Array As Object(f1))
	RoutePanelScale = 1.0

	RouteBaseX = CameraCenterX
	RouteBaseY = CameraCenterY
	RouteBaseZoom = CameraZoom

	Dim prevX As Float = -1
	Dim prevY As Float = -1

	Dim baseThickness As Float = 10dip
	Dim dynamicThickness As Float = baseThickness * Power(2, CameraZoom - 22)
	If dynamicThickness < 2dip Then dynamicThickness = 2dip

	Dim worldPerTile As Double = WorldTilesPerScreenTile
	Dim halfWidth As Float = 100%x / 2
	Dim halfHeight As Float = 100%y / 2
	Dim scaleFactor As Double = TILE_SIZE / worldPerTile

	For i = 0 To CurrentRoute.Size - 1
		Dim mn As MapNode = CurrentRoute.Get(i)
		Dim pixelX As Float = ((mn.X22 - CameraCenterX) * scaleFactor) + halfWidth
		Dim pixelY As Float = ((CameraCenterY - mn.Y22) * scaleFactor) + halfHeight

		If i > 0 Then
			cvsRoute.DrawLine(prevX, prevY, pixelX, pixelY, Colors.ARGB(200, 30, 144, 255), dynamicThickness)
		End If

		prevX = pixelX
		prevY = pixelY
	Next

	pnlRoute.Invalidate
End Sub


' ==============================================================================
' 5. GPS & BLUE DOT
' ==============================================================================
Sub flp_ConnectionSuccess
	Log("GPS Engine Connected!")
	Dim LocationRequest1 As LocationRequest
	LocationRequest1.Initialize
	LocationRequest1.SetInterval(2000)
	LocationRequest1.SetPriority(LocationRequest1.Priority.PRIORITY_HIGH_ACCURACY)
	flp.RequestLocationUpdates(LocationRequest1)
End Sub

Sub flp_ConnectionFailed(ConnectionResult1 As Int)
	Log("GPS Engine Failed: " & ConnectionResult1)
End Sub

Sub flp_LocationChanged (Location1 As Location)
	CurrentLat = Location1.Latitude
	CurrentLon = Location1.Longitude
	
	DotX22 = GetTileX(CurrentLon, 22)
	DotY22 = GetTileY(CurrentLat, 22)
	
	pnlBlueDot.Visible = True
	UpdateBlueDotPositionContinuous
End Sub

Sub UpdateBlueDotPositionContinuous
	If CurrentLat = 0 And CurrentLon = 0 Then Return

	Dim worldPerTile As Double = WorldTilesPerScreenTile
	Dim pixelX As Float = (((DotX22 - CameraCenterX) / worldPerTile) * TILE_SIZE) + (100%x / 2)
	Dim pixelY As Float = (((CameraCenterY - DotY22) / worldPerTile) * TILE_SIZE) + (100%y / 2)

	pnlBlueDot.Left = pixelX - (DOT_SIZE / 2)
	pnlBlueDot.Top = pixelY - (DOT_SIZE / 2)
End Sub

Sub UpdatePinsContinuous
	If ActivePins.IsInitialized = False Then Return
	
	Dim worldPerTile As Double = WorldTilesPerScreenTile
	For Each pin As MapPin In ActivePins
		' We pass CameraZoom into the pin so it can check its Priority!
		pin.UpdatePosition(CameraCenterX, CameraCenterY, CameraZoom, worldPerTile, TILE_SIZE)
	Next
End Sub
#End Region

#Region EDIT TXT
Private Sub ToT_EnterPressed
	If ToT.Text = "" And FromT.Text = "" Then
		xui.MsgboxAsync("Error", "Fill in the spots")
	Else If ToT.Text = "" Then 
		xui.MsgboxAsync("Error", "Select your destination")
	Else If FromT.Text = "" Then
		xui.MsgboxAsync("Error", "Select your current location")
	End If
End Sub

Private Sub searchEditText_EnterPressed
	
End Sub

Private Sub FromT_EnterPressed
	If ToT.Text = "" And FromT.Text = "" Then
		xui.MsgboxAsync("Error", "Fill in the spots")
	Else If ToT.Text = "" Then
		xui.MsgboxAsync("Error", "Select your destination")
	Else If FromT.Text = "" Then
		xui.MsgboxAsync("Error", "Select your current location")
	End If
End Sub
#End Region

Private Sub ToT_FocusChanged (HasFocus As Boolean)
	If HasFocus Then
		LastEditText = ToT
	End If
End Sub

Private Sub FromT_FocusChanged (HasFocus As Boolean)
	If HasFocus Then
		LastEditText = FromT
	End If
End Sub