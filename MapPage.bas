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

	Private appWidth    As Int
	Private appHeight   As Int
	
	Private TileLoadCount As Int

	Private IsDarkMode As Boolean = False
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

	' ── Header Panel ──────────────────────────────
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

	' ── Body Panel ────────────────────────────────
	BottomCard.BodyPanel.Color = Colors.White
	Dim pad As Int = 5%x
	Dim curY As Int = 1%y

	lblCategory.Initialize("")
	lblCategory.TextSize = 13
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
	lblDescription.TextSize = 14
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
	lblRooms.TextSize = 15
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
	TileLoadCount = 0

	TilesAcross = Ceil(100%x / TILE_SIZE) + 2
	TilesDown = Ceil(100%y / TILE_SIZE) + 2
    
	pnlMapContainer.Initialize("")
	pnlMapContainer.Color = Colors.RGB(238, 235, 225)
	Activity.AddView(pnlMapContainer, 0, 0, 100%x, 100%y)
    
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
    
	pnlBlueDot.Initialize("")
	Dim cd As ColorDrawable
	cd.Initialize2(Colors.Blue, DOT_SIZE / 2, 2dip, Colors.White)
	pnlBlueDot.Background = cd
	pnlBlueDot.Visible = False
	pnlCanvas.AddView(pnlBlueDot, 0, 0, DOT_SIZE, DOT_SIZE)
    
	rp.CheckAndRequest(rp.PERMISSION_ACCESS_FINE_LOCATION)
	Wait For Activity_PermissionResult (Permission As String, Result As Boolean)
	If Result Then
		flp.Initialize("flp")
		flp.Connect
	Else
		ToastMessageShow("Location permission denied. Blue Dot disabled.", True)
	End If

	Dim r As Reflector
	r.Target = pnlMapContainer
	r.SetOnTouchListener("maptouch")

	' Bring nav panels above map
	BottomPanel.BringToFront
	TopPanel.BringToFront

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

	' Initialize pin storage then place test pins
	PinList.Initialize
	PinDataMap.Initialize
	AddTestPins
	BottomCard.DarkPanel.BringToFront
	If SelectedPinTag <> "" Then
		If PinDataMap.ContainsKey("pin_" & SelectedPinTag) Then
			Dim b As BuildingInfo = PinDataMap.Get("pin_" & SelectedPinTag)
			OnMapPinClick(b)
		End If
		SelectedPinTag = ""
	End If
#End Region

#Region NAV-FOOT ANIM
	TopPanel.Top = -TopPanel.Height
	BottomPanel.Top = 100%y
	Sleep(300)
	TopPanel.SetLayoutAnimated(500, TopPanel.Left, 45dip, TopPanel.Width, TopPanel.Height)
	BottomPanel.SetLayoutAnimated(500, BottomPanel.Left, 100%y - BottomPanel.Height, BottomPanel.Width, BottomPanel.Height)
#End Region
End Sub

Sub Activity_Resume
	appWidth  = Activity.Width
	appHeight = Activity.Height
End Sub

Sub Activity_Pause(UserClosed As Boolean)
	TileCache.Clear
	TileLoadCount = 0
End Sub

Sub AddTestPins
	Dim b1 As BuildingInfo
	b1.Initialize
	b1.Category    = "Buildings"
	b1.Name        = "College of Computing Studies"
	b1.Description = "The university's central hub for technology, innovation, and digital learning."
	b1.Rooms       = Array As String("Floor 1: CS 101, CS 102, CS 103, CS 104, CS 105, Toilet Room", _
	                                  "Floor 2: CS 201, CS 202, CS 203, Faculty Room")
	b1.PhotoFile   = "ccs.jpg"
	b1.Lat         = 14.997889
	b1.Lon         = 120.655083
	AddPin(b1, "CCS")

	Dim b2 As BuildingInfo
	b2.Initialize
	b2.Category    = "Buildings"
	b2.Name        = "College of Engineering and Architecture"
	b2.Description = "Houses the College of Engineering and Architecture programs."
	b2.Rooms       = Array As String("Floor 1: Lecture Hall A, Lecture Hall B", _
	                                  "Floor 2: Drawing Room, Faculty Office")
	b2.PhotoFile   = "coe.jpg"
	b2.Lat         = 14.998100
	b2.Lon         = 120.655300
	AddPin(b2, "COE")

	Dim b3 As BuildingInfo
	b3.Initialize
	b3.Category    = "Buildings"
	b3.Name        = "College of Industrial Technology"
	b3.Description = "Focused on technical and industrial education."
	b3.Rooms       = Array As String("Floor 1: Shop 1, Shop 2", _
	                                  "Floor 2: Faculty Room")
	b3.PhotoFile   = "cit.jpg"
	b3.Lat         = 14.997700
	b3.Lon         = 120.655500
	AddPin(b3, "CIT")

	Dim b4 As BuildingInfo
	b4.Initialize
	b4.Category    = "Buildings"
	b4.Name        = "Auditorium"
	b4.Description = "Main venue for university events and ceremonies."
	b4.Rooms       = Array As String("Ground Floor: Main Hall, Stage")
	b4.PhotoFile   = "aud.jpg"
	b4.Lat         = 14.998300
	b4.Lon         = 120.654900
	AddPin(b4, "AUD")

	Dim b5 As BuildingInfo
	b5.Initialize
	b5.Category    = "Buildings"
	b5.Name        = "Administration Building"
	b5.Description = "Central administration and records office."
	b5.Rooms       = Array As String("Floor 1: Registrar, Cashier", _
	                                  "Floor 2: Office of the President")
	b5.PhotoFile   = "adm.jpg"
	b5.Lat         = 14.997600
	b5.Lon         = 120.654800
	AddPin(b5, "ADM")

	Dim b6 As BuildingInfo
	b6.Initialize
	b6.Category    = "Buildings"
	b6.Name        = "Library"
	b6.Description = "University library with digital and print resources."
	b6.Rooms       = Array As String("Floor 1: Circulation, Reading Area", _
	                                  "Floor 2: Archive")
	b6.PhotoFile   = "lib.jpg"
	b6.Lat         = 14.998000
	b6.Lon         = 120.655100
	AddPin(b6, "LIB")
End Sub

Sub AddPin(building As BuildingInfo, tag As String) 'tag is ung name name ng building or initials
	Dim pinSize As Int = 24dip
	Dim pin As Panel
	pin.Initialize("pin_" & tag)
	Dim pinShape As ColorDrawable
	pinShape.Initialize(Colors.ARGB(255, 160, 30, 45), pinSize / 2)
	pin.Background = pinShape
	pin.Tag = "pin_" & tag
	pnlCanvas.AddView(pin, 0, 0, pinSize, pinSize)

	' Position on map
	Dim StartCol As Int = CenterTileX - Floor(TilesAcross / 2)
	Dim StartRow As Int = CenterTileY + Floor(TilesDown / 2)
	Dim etx As Double = GetTileX(building.Lon, CurrentZoom)
	Dim ety As Double = GetTileY(building.Lat, CurrentZoom)
	pin.Left = (etx - StartCol) * TILE_SIZE - pinSize / 2
	pin.Top  = (StartRow - ety) * TILE_SIZE - pinSize / 2

	' Attach touch listener
	Dim r As Reflector
	r.Target = pin
	r.SetOnTouchListener("pin_Touch")

	PinList.Add(pin)
	PinDataMap.Put("pin_" & tag, building)
End Sub

Sub pin_Touch(ViewTag As Object, Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean
	If Action = 1 Then  ' ACTION_UP
		Dim tag As String = ViewTag
		If PinDataMap.ContainsKey(tag) Then
			Dim building As BuildingInfo = PinDataMap.Get(tag)
			OnMapPinClick(building)
		End If
	End If
	Return True
End Sub

Sub UpdateAllPinPositions
	Dim pinSize As Int = 24dip
	Dim StartCol As Int = CenterTileX - Floor(TilesAcross / 2)
	Dim StartRow As Int = CenterTileY + Floor(TilesDown / 2)
	For i = 0 To PinList.Size - 1
		Dim pin As Panel = PinList.Get(i)
		Dim tag As String = pin.Tag
		If PinDataMap.ContainsKey(tag) Then
			Dim b As BuildingInfo = PinDataMap.Get(tag)
			Dim etx As Double = GetTileX(b.Lon, CurrentZoom)
			Dim ety As Double = GetTileY(b.Lat, CurrentZoom)
			pin.Left = (etx - StartCol) * TILE_SIZE - pinSize / 2
			pin.Top  = (StartRow - ety) * TILE_SIZE - pinSize / 2
		End If
	Next
End Sub

Sub OnMapPinClick(building As BuildingInfo)
	lblCategory.Text     = building.Category
	lblBuildingName.Text = building.Name
	lblDescription.Text  = building.Description

	' Build bullet room list
	Dim roomText As String = ""
	For i = 0 To building.Rooms.Length - 1
		roomText = roomText & Chr(8226) & "  " & building.Rooms(i)
		If i < building.Rooms.Length - 1 Then roomText = roomText & CRLF
	Next
	lblRooms.Text = roomText

	' Load photo from assets
	If building.PhotoFile <> "" Then
		If File.Exists(File.DirAssets, building.PhotoFile) Then
			imgPhoto.Bitmap = LoadBitmap(File.DirAssets, building.PhotoFile)
		End If
	End If

	' Hide navbar then show sheet
	If BottomCard.IsOpen Then
		' Sheet already visible — content swaps in place
	Else
		BottomPanel.Visible = False
		TopPanel.Visible = False
		BottomCard.ExpandHalf
	End If
End Sub

Sub btnClose_Click
	BottomCard.Hide(False)
End Sub

Sub btnNavigate_Click
	ToastMessageShow("Navigating to: " & lblBuildingName.Text, False)
End Sub

#Region BOT CARD EVETS
Sub BottomCard_Open
	' kapag na trigger ung pagbukas ng sheet
	BottomPanel.Visible = False
	TopPanel.Visible = False
	pnlMapContainer.Enabled = False
End Sub

Sub BottomCard_Opened
	' kapag nag bukas ung sheet
	Log("Sheet is fully open")
	pnlMapContainer.Enabled = False
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
	pnlMapContainer.Enabled = True
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

Sub Activity_KeyPress(KeyCode As Int) As Boolean
	If KeyCode = KeyCodes.KEYCODE_BACK Then
		Return True
	End If
	Return False
End Sub
#End Region

#Region MAP THINGS
#Region MAP ENGINE
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
	UpdateAllPinPositions
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
						UpdateAllPinPositions
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
#End Region

#Region GPS
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
#End Region

#Region MATH
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
#End Region
#End Region
