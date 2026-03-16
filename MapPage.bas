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
	Private TILE_SIZE As Int = 256
	Private MinTileX As Int, MaxTileX As Int
	Private MinTileY As Int, MaxTileY As Int
	Private tmr         As Timer
	Private tmrFinish   As Timer
End Sub

Sub Globals
	Private pnlCanvas As Panel
	Private pnlMapContainer As Panel
    
	Private Const MAX_COLS As Int = 10
	Private Const MAX_ROWS As Int = 20
	Private TileViews(MAX_COLS, MAX_ROWS) As ImageView
	Private TilesAcross As Int
	Private TilesDown As Int
    
	Private CurrentZoom As Int = 22
	Private CenterTileX As Int
	Private CenterTileY As Int
    
	Private LastTouchX As Float
	Private LastTouchY As Float
    
	Private TileCache As Map
	Private BufferX As Int
	Private BufferY As Int
    
	Private IsPinching As Boolean = False
	Private InitialPinchDistance As Float = 0
	Private CurrentScale As Float = 1.0
	Private ZoomJustTriggered As Boolean = False
    
	Private flp As FusedLocationProvider
	Private rp As RuntimePermissions
    
	Private pnlBlueDot As Panel
	Private DOT_SIZE As Int = 16dip
	Private CurrentLat As Double = 0
	Private CurrentLon As Double = 0
	Private FirstSnapDone As Boolean = False
    
	Private BuildingButton As Panel
	Private MapButton As Panel
	Private QrButton As Panel
	Private searchEditText As EditText
	Private BottomPanel As Panel
	Private TopPanel As Panel

	Private NextPage    As Object
	Private pnlSlide    As Panel
	Private appWidth    As Int
	Private appHeight   As Int
	Private TileLoadCount As Int

	Private IsDarkMode As Boolean = False
	Private ModeIcon As ImageView
End Sub

Sub Activity_Create(FirstTime As Boolean)
	' STEP 1 - Load layout first so buttons are initialized
	Activity.LoadLayout("MapPage")
	ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "sun.png")
	
	If TileCache.IsInitialized = False Then TileCache.Initialize
	TileCache.Clear
	TileLoadCount = 0

	TilesAcross = Ceil(100%x / TILE_SIZE) + 2
	TilesDown = Ceil(100%y / TILE_SIZE) + 2
    
	' STEP 2 - Create fixed size container clipped to screen
	pnlMapContainer.Initialize("")
	pnlMapContainer.Color = Colors.RGB(238, 235, 225)
	Activity.AddView(pnlMapContainer, 0, 0, 100%x, 100%y)
    
	' STEP 3 - pnlCanvas goes INSIDE container
	pnlCanvas.Initialize("")
	pnlCanvas.Color = Colors.RGB(238, 235, 225)
	pnlMapContainer.AddView(pnlCanvas, -TILE_SIZE, -TILE_SIZE, TilesAcross * TILE_SIZE, TilesDown * TILE_SIZE)
    
	For col = 0 To TilesAcross - 1
		For row = 0 To TilesDown - 1
			TileViews(col, row).Initialize("")
			TileViews(col, row).Gravity = Gravity.FILL
			pnlCanvas.AddView(TileViews(col, row), col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
		Next
	Next
    
	' STEP 4 - Blue dot inside canvas
	pnlBlueDot.Initialize("")
	Dim cd As ColorDrawable
	cd.Initialize2(Colors.Blue, DOT_SIZE / 2, 2dip, Colors.White)
	pnlBlueDot.Background = cd
	pnlBlueDot.Visible = False
	pnlCanvas.AddView(pnlBlueDot, 0, 0, DOT_SIZE, DOT_SIZE)
    
	' STEP 5 - GPS permission
	rp.CheckAndRequest(rp.PERMISSION_ACCESS_FINE_LOCATION)
	Wait For Activity_PermissionResult (Permission As String, Result As Boolean)
	If Result Then
		flp.Initialize("flp")
		flp.Connect
	Else
		ToastMessageShow("Location permission denied. Blue Dot disabled.", True)
	End If

	' STEP 6 - Attach touch to container
	Dim r As Reflector
	r.Target = pnlMapContainer
	r.SetOnTouchListener("maptouch")

	' STEP 7 - Bring layout buttons to front
	' They are on Activity directly, above pnlMapContainer
	BottomPanel.BringToFront
	TopPanel.BringToFront

	' STEP 8 - Load map database
	If File.Exists(File.DirInternal, "dhvsu_map_test.mbtiles") = False Then
		File.Copy(File.DirAssets, "dhvsu_map_test.mbtiles", File.DirInternal, "dhvsu_map_test.mbtiles")
	End If
	If sql1.IsInitialized = False Then
		sql1.Initialize(File.DirInternal, "dhvsu_map_test.mbtiles", False)
	End If
    
	Dim rs As ResultSet = sql1.ExecQuery2("SELECT MIN(tile_column), MAX(tile_column), MIN(tile_row), MAX(tile_row) FROM tiles WHERE zoom_level = ?", Array As String(CurrentZoom))
	If rs.NextRow Then
		MinTileX = rs.GetInt2(0)
		MaxTileX = rs.GetInt2(1)
		MinTileY = rs.GetInt2(2)
		MaxTileY = rs.GetInt2(3)
		CenterTileX = MinTileX + (MaxTileX - MinTileX) / 2
		CenterTileY = MinTileY + (MaxTileY - MinTileY) / 2
		BufferX = Floor(Ceil(100%x / TILE_SIZE) / 2)
		BufferY = Floor(Ceil(100%y / TILE_SIZE) / 2)
	End If
	rs.Close
    
	Dim exactTileX As Double = GetTileX(120.655083, CurrentZoom)
	Dim exactTileY As Double = GetTileY(14.997889, CurrentZoom)
	CenterTileX = Floor(exactTileX)
	CenterTileY = Floor(exactTileY)
	pnlCanvas.Left = -TILE_SIZE
	pnlCanvas.Top = -TILE_SIZE
	RenderGrid
End Sub

Sub Activity_Resume
	appWidth  = Activity.Width
	appHeight = Activity.Height
End Sub

Sub Activity_Pause(UserClosed As Boolean)
	TileCache.Clear
	TileLoadCount = 0
End Sub

'===================================
' NAVIGATION
'===================================

Private Sub ModeIcon_Click
	IsDarkMode = Not(IsDarkMode)
    
	If IsDarkMode Then
		ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "moon.png")
		TopPanel.Color    = Colors.RGB(30, 30, 30)
		BottomPanel.Color = Colors.RGB(30, 30, 30)
		searchEditText.Color = Colors.White
		
	Else
		ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "sun.png")
		TopPanel.Color    = Colors.RGB(255, 255, 255)
		BottomPanel.Color = Colors.RGB(255, 255, 255)
	End If
End Sub

Sub GoToPage(NextActivity As Object)
	Activity.Color = Colors.RGB(156, 28, 28)
	NextPage = NextActivity

	pnlSlide.Initialize("")
	Activity.AddView(pnlSlide, appWidth - 1, 0, appWidth, appHeight)
	pnlSlide.Color = Colors.RGB(156, 28, 28)
	pnlSlide.Visible = True
	pnlSlide.BringToFront
	pnlSlide.SetLayoutAnimated(300, 0, 0, appWidth, appHeight)

	tmr.Initialize("tmr", 350)
	tmr.Enabled = True
End Sub

Sub tmr_Tick
	tmr.Enabled = False
	StartActivity(NextPage)
	Activity.Finish
End Sub

Sub GoBack
	Activity.Color = Colors.RGB(156, 28, 28)

	pnlSlide.Initialize("")
	Activity.AddView(pnlSlide, -appWidth, 0, appWidth, appHeight)
	pnlSlide.Color = Colors.RGB(156, 28, 28)
	pnlSlide.Visible = True
	pnlSlide.BringToFront
	pnlSlide.SetLayoutAnimated(300, 0, 0, appWidth, appHeight)

	tmrFinish.Initialize("tmrFinish", 350)
	tmrFinish.Enabled = True
End Sub

Sub tmrFinish_Tick
	tmrFinish.Enabled = False
	Activity.Finish
End Sub

'===================================
' BUTTON TOUCHES
'===================================

Private Sub searchButton_Click
End Sub

Private Sub QrButton_Touch(Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		QrButton.Color = Colors.RGB(183, 43, 60)
	Else If Action = 1 Then
		QrButton.Color = Colors.RGB(156, 28, 28)
		GoToPage(QrScannerPage)
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
		GoToPage(PlacesPage)
	End If
End Sub

'===================================
' BACK BUTTON
'===================================

Sub Activity_KeyPress(KeyCode As Int) As Boolean
	If KeyCode = KeyCodes.KEYCODE_BACK Then
		GoBack
		Return True
	End If
	Return False
End Sub

'===================================
' MAP ENGINE
'===================================

Sub LoadTile(Z As Int, X As Int, Y As Int) As Bitmap
	Dim TileKey As String = Z & "_" & X & "_" & Y
	If TileCache.ContainsKey(TileKey) Then Return TileCache.Get(TileKey)
    
	TileLoadCount = TileLoadCount + 1
	If TileLoadCount >= 10 Then
		TileCache.Clear
		TileLoadCount = 0
		Log("Cache cleared at 10 tiles")
	End If
    
	Dim bmp As Bitmap
	Dim rs As ResultSet = sql1.ExecQuery2("SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?", Array As String(Z, X, Y))
    
	If rs.NextRow Then
		Try
			Dim data() As Byte = rs.GetBlob2(0)
			Dim InStream As InputStream
			InStream.InitializeFromBytesArray(data, 0, data.Length)
			bmp.Initialize2(InStream)
			InStream.Close
			TileCache.Put(TileKey, bmp)
		Catch
			Log("Tile load failed: " & LastException.Message)
			TileCache.Clear
			TileLoadCount = 0
			rs.Close
			Return Null
		End Try
		rs.Close
		Return bmp
	End If
	rs.Close
	Return Null
End Sub

Sub RenderGrid
	Dim StartCol As Int = CenterTileX - Floor(TilesAcross / 2)
	Dim StartRow As Int = CenterTileY + Floor(TilesDown / 2)
    
	For col = 0 To TilesAcross - 1
		For row = 0 To TilesDown - 1
			Dim TargetX As Int = StartCol + col
			Dim TargetY As Int = StartRow - row
			Dim iv As ImageView = TileViews(col, row)
			Dim bmp As Bitmap = LoadTile(CurrentZoom, TargetX, TargetY)
			If bmp <> Null And bmp.IsInitialized Then
				iv.Bitmap = bmp
			Else
				iv.Bitmap = Null
			End If
		Next
	Next
End Sub

Sub ChangeZoom(TargetZoom As Int)
	If TargetZoom < 18 Or TargetZoom > 22 Then Return
	If TargetZoom = CurrentZoom Then Return

	Dim panOffsetX As Float = pnlCanvas.Left - (-TILE_SIZE)
	Dim panOffsetY As Float = pnlCanvas.Top - (-TILE_SIZE)

	If TargetZoom > CurrentZoom Then
		CenterTileX = CenterTileX * 2
		CenterTileY = CenterTileY * 2
		pnlCanvas.Left = -TILE_SIZE + (panOffsetX * 2)
		pnlCanvas.Top = -TILE_SIZE + (panOffsetY * 2)
	Else
		CenterTileX = Floor(CenterTileX / 2)
		CenterTileY = Floor(CenterTileY / 2)
		pnlCanvas.Left = -TILE_SIZE + (panOffsetX / 2)
		pnlCanvas.Top = -TILE_SIZE + (panOffsetY / 2)
	End If

	CurrentZoom = TargetZoom

	Dim rs As ResultSet = sql1.ExecQuery2("SELECT MIN(tile_column), MAX(tile_column), MIN(tile_row), MAX(tile_row) FROM tiles WHERE zoom_level = ?", Array As String(CurrentZoom))
	If rs.NextRow Then
		MinTileX = rs.GetInt2(0)
		MaxTileX = rs.GetInt2(1)
		MinTileY = rs.GetInt2(2)
		MaxTileY = rs.GetInt2(3)
	End If
	rs.Close

	Do While pnlCanvas.Left > 0
		CenterTileX = CenterTileX - 1
		pnlCanvas.Left = pnlCanvas.Left - TILE_SIZE
	Loop
	Do While pnlCanvas.Left < -(TILE_SIZE * 2)
		CenterTileX = CenterTileX + 1
		pnlCanvas.Left = pnlCanvas.Left + TILE_SIZE
	Loop
	Do While pnlCanvas.Top > 0
		CenterTileY = CenterTileY + 1
		pnlCanvas.Top = pnlCanvas.Top - TILE_SIZE
	Loop
	Do While pnlCanvas.Top < -(TILE_SIZE * 2)
		CenterTileY = CenterTileY - 1
		pnlCanvas.Top = pnlCanvas.Top + TILE_SIZE
	Loop
    
	For col = 0 To TilesAcross - 1
		For row = 0 To TilesDown - 1
			TileViews(col, row).Bitmap = Null
		Next
	Next
    
	TileCache.Clear
	TileLoadCount = 0
    
	RenderGrid
	UpdateBlueDotPosition
End Sub

Sub maptouch(ViewTag As Object, Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean 'ignore
	Try
		Dim event As JavaObject = MotionEvent
		Dim pointerCount As Int = event.RunMethod("getPointerCount", Null)
		Dim actionMasked As Int = Bit.And(Action, 255)

		If pointerCount = 2 Then
			IsPinching = True
			Dim x1 As Float = X
			Dim y1 As Float = Y
			Dim x2 As Float = event.RunMethod("getX", Array As Object(1))
			Dim y2 As Float = event.RunMethod("getY", Array As Object(1))
			Dim distance As Float = Sqrt(Power(x1 - x2, 2) + Power(y1 - y2, 2))
            
			If actionMasked = 5 Then
				InitialPinchDistance = distance
				ZoomJustTriggered = False
			Else If actionMasked = 2 Then
				If InitialPinchDistance > 0 Then
					CurrentScale = distance / InitialPinchDistance
					If ZoomJustTriggered Then
						If CurrentScale > 0.8 And CurrentScale < 1.2 Then
							ZoomJustTriggered = False
							InitialPinchDistance = distance
						End If
					Else
						If CurrentZoom < 22 And CurrentScale >= 2.0 Then
							ChangeZoom(CurrentZoom + 1)
							InitialPinchDistance = distance
							CurrentScale = 1.0
							ZoomJustTriggered = True
						Else If CurrentZoom > 18 And CurrentScale <= 0.5 Then
							ChangeZoom(CurrentZoom - 1)
							InitialPinchDistance = distance
							CurrentScale = 1.0
							ZoomJustTriggered = True
						End If
					End If
					If CurrentZoom <= 18 And CurrentScale < 1.0 Then CurrentScale = 1.0
					If CurrentZoom >= 22 And CurrentScale > 1.0 Then CurrentScale = 1.0
				End If
			End If
			Return True
		End If
        
		If pointerCount = 1 And IsPinching = False Then
			If actionMasked = 0 Then
				LastTouchX = X
				LastTouchY = Y
			Else If actionMasked = 2 Then
				Dim deltaX As Float = X - LastTouchX
				Dim deltaY As Float = Y - LastTouchY
				If Abs(deltaX) > 2 Or Abs(deltaY) > 2 Then
					Dim NextLeft As Float = pnlCanvas.Left + deltaX
					Dim NextTop As Float = pnlCanvas.Top + deltaY
					If (CenterTileX - BufferX) <= MinTileX And NextLeft > -TILE_SIZE Then NextLeft = -TILE_SIZE
					If (CenterTileX + BufferX) >= MaxTileX And NextLeft < -TILE_SIZE Then NextLeft = -TILE_SIZE
					If (CenterTileY + BufferY) >= MaxTileY And NextTop > -TILE_SIZE Then NextTop = -TILE_SIZE
					If (CenterTileY - BufferY) <= MinTileY And NextTop < -TILE_SIZE Then NextTop = -TILE_SIZE
					pnlCanvas.Left = NextLeft
					pnlCanvas.Top = NextTop
					LastTouchX = X
					LastTouchY = Y
					Dim NeedsRedraw As Boolean = False
					Do While pnlCanvas.Left > 0
						CenterTileX = CenterTileX - 1
						pnlCanvas.Left = pnlCanvas.Left - TILE_SIZE
						NeedsRedraw = True
					Loop
					Do While pnlCanvas.Left < -(TILE_SIZE * 2)
						CenterTileX = CenterTileX + 1
						pnlCanvas.Left = pnlCanvas.Left + TILE_SIZE
						NeedsRedraw = True
					Loop
					Do While pnlCanvas.Top > 0
						CenterTileY = CenterTileY + 1
						pnlCanvas.Top = pnlCanvas.Top - TILE_SIZE
						NeedsRedraw = True
					Loop
					Do While pnlCanvas.Top < -(TILE_SIZE * 2)
						CenterTileY = CenterTileY - 1
						pnlCanvas.Top = pnlCanvas.Top + TILE_SIZE
						NeedsRedraw = True
					Loop
					If NeedsRedraw Then
						RenderGrid
						UpdateBlueDotPosition
					End If
				End If
			End If
		End If
        
		If actionMasked = 1 Or actionMasked = 6 Then
			If IsPinching Then
				IsPinching = False
				ZoomJustTriggered = False
				CurrentScale = 1.0
				LastTouchX = X
				LastTouchY = Y
			End If
		End If

	Catch
		Log("Crash Prevented: " & LastException.Message)
		TileCache.Clear
		TileLoadCount = 0
	End Try
	Return True
End Sub

'===================================
' GPS
'===================================

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

Sub flp_LocationChanged(Location1 As Location)
	CurrentLat = Location1.Latitude
	CurrentLon = Location1.Longitude
	pnlBlueDot.Visible = True
	UpdateBlueDotPosition
End Sub

'===================================
' MATH
'===================================

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

Sub UpdateBlueDotPosition
	If CurrentLat = 0 And CurrentLon = 0 Then Return
	Dim exactTileX As Double = GetTileX(CurrentLon, CurrentZoom)
	Dim exactTileY As Double = GetTileY(CurrentLat, CurrentZoom)
	Dim StartCol As Int = CenterTileX - Floor(TilesAcross / 2)
	Dim StartRow As Int = CenterTileY + Floor(TilesDown / 2)
	Dim PixelX As Float = (exactTileX - StartCol) * TILE_SIZE
	Dim PixelY As Float = (StartRow - exactTileY) * TILE_SIZE
	pnlBlueDot.Left = PixelX - (DOT_SIZE / 2)
	pnlBlueDot.Top = PixelY - (DOT_SIZE / 2)
	pnlBlueDot.BringToFront
End Sub
