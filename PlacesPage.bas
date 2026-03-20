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
	Type BuildingEntry( _
		Tag As String, _
		Name As String, _
		Category As String, _
		Description As String, _
		Rooms() As String, _
		PhotoFile As String, _
		Lat As Double, _
		Lon As Double _
	)
End Sub

Sub Globals
	Private BottomPanel As Panel
	Private BuildingButton As Panel
	Private BuildingView As ImageView
	Private MapButton As Panel
	Private MapView As ImageView
	Private QrButton As Panel
	Private QrView As ImageView
	Private TopPanel As Panel

	Private pnlCategory As Panel
	Private pnlBuildings As Panel
	Private CurrentCategory As String
	Private AllBuildings As List
	Private TopPanelLabel As Label
	
	Private svBuildings As ScrollView
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.LoadLayout("Places")

	Dim contentTop As Int = TopPanel.Height
	Dim contentH As Int = 100%y - TopPanel.Height - BottomPanel.Height

	' Category screen
	pnlCategory.Initialize("")
	pnlCategory.Color = Colors.RGB(245, 245, 245)
	Activity.AddView(pnlCategory, 0, contentTop, 100%x, contentH)

	' Buildings screen (hidden by default)
	pnlBuildings.Initialize("")
	pnlBuildings.Color = Colors.RGB(245, 245, 245)
	Activity.AddView(pnlBuildings, 0, contentTop, 100%x, contentH)
	pnlBuildings.Visible = False

	TopPanel.BringToFront
	BottomPanel.BringToFront

	InitBuildingData
	BuildCategoryScreen

	TopPanel.Top = -TopPanel.Height
	BottomPanel.Top = 100%y
	Sleep(300)
	TopPanel.SetLayoutAnimated(500, TopPanel.Left, 0, TopPanel.Width, TopPanel.Height)
	BottomPanel.SetLayoutAnimated(500, BottomPanel.Left, 100%y - BottomPanel.Height, BottomPanel.Width, BottomPanel.Height)
End Sub

#Region BUILDING DATA INIT 
Sub InitBuildingData
	AllBuildings.Initialize

	AddBuilding("CCS",  "College of Computing Studies", "Buildings", "The university's central hub for technology, innovation, and digital learning.", _
		Array As String("Floor 1: CS 101, CS 102, CS 103", "Floor 2: CS 201, CS 202"), "ccs.jpg", 14.997889, 120.655083)

	AddBuilding("COE",  "College of Engineering and Architecture", "Buildings", "Houses the College of Engineering and Architecture programs.", _
		Array As String("Floor 1: Lecture Hall A, Lecture Hall B", "Floor 2: Drawing Room"), "coe.jpg", 14.998100, 120.655300)

	AddBuilding("CIT",  "College of Industrial Technology", "Buildings", "Focused on technical and industrial education.", _
		Array As String("Floor 1: Shop 1, Shop 2", "Floor 2: Faculty Room"), "cit.jpg", 14.997700, 120.655500)

	AddBuilding("AUD",  "Auditorium", "Buildings", "Main venue for university events and ceremonies.", _
		Array As String("Ground Floor: Main Hall, Stage"), "aud.jpg", 14.998300, 120.654900)

	AddBuilding("ADM",  "Administration Building", "Buildings", "Central administration and records office.", _
		Array As String("Floor 1: Registrar, Cashier", "Floor 2: Office of the President"), "adm.jpg", 14.997600, 120.654800)

	AddBuilding("LIB",  "Library", "Buildings", "University library with digital and print resources.", _
		Array As String("Floor 1: Circulation, Reading Area", "Floor 2: Archive"), "lib.jpg", 14.998000, 120.655100)

	AddBuilding("CAFE", "Main Canteen", "Food and Drinks","University main canteen serving meals daily.", _
		Array As String("Stall 1: Rice Meals", "Stall 2: Snacks and Drinks"), "cafe.jpg", 14.997500, 120.655200)

	AddBuilding("LAB1", "Science Laboratory", "Laboratories", "General science laboratory for experiments.", _
		Array As String("Room 1: Chem Lab", "Room 2: Bio Lab"), "lab1.jpg", 14.998200, 120.655400)

	AddBuilding("CR1",  "Main Comfort Room", "Toilets", "Main comfort room near the administration building.", _
		Array As String("Ground Floor: Male CR, Female CR"), "cr1.jpg", 14.997650, 120.654850)
End Sub

#End Region

Sub AddBuilding(tag As String, name As String, category As String, description As String, rooms() As String, photoFile As String, lat As Double, lon As Double)
	Dim b As BuildingEntry
	b.Initialize
	b.Tag         = tag
	b.Name        = name
	b.Category    = category
	b.Description = description
	b.Rooms       = rooms
	b.PhotoFile   = photoFile
	b.Lat         = lat
	b.Lon         = lon
	AllBuildings.Add(b)
End Sub

#Region CATERGORY LIST PAGE
Sub BuildCategoryScreen
	Dim catNames(5) As String
	Dim catIcons(5) As String
	catNames(0) = "Buildings"       : catIcons(0) = "icon_building.png"
	catNames(1) = "Food and Drinks" : catIcons(1) = "icon_food.png"
	catNames(2) = "Rooms"           : catIcons(2) = "icon_room.png"
	catNames(3) = "Laboratories"    : catIcons(3) = "icon_lab.png"
	catNames(4) = "Toilets"         : catIcons(4) = "icon_toilet.png"
	
	Dim rowH As Int = 12%y
	Dim pad As Int = 4%x
	
	For i = 0 To 4
		Dim rowTop As Int = i * rowH
		
		' Row panel
		Dim row As Panel
		row.Initialize("cat_" & catNames(i))
		row.Color = Colors.White
		row.Tag = "cat_" & catNames(i)
		pnlCategory.AddView(row, 0, rowTop, 100%x, rowH)
		
		' Divider
		Dim divider As Panel
		divider.Initialize("")
		divider.Color = Colors.ARGB(40, 0, 0, 0)
		pnlCategory.AddView(divider, pad, rowTop + rowH, 100%x - pad * 2, 1dip)

		' Icon
		Dim icon As ImageView
		icon.Initialize("")
		icon.Gravity = Gravity.FILL
		If File.Exists(File.DirAssets, catIcons(i)) Then
			icon.Bitmap = LoadBitmap(File.DirAssets, catIcons(i))
		End If
		row.AddView(icon, pad, rowH / 2 - 2%y, 8%x, 4%y)

		' Label
		Dim lbl As Label
		lbl.Initialize("")
		lbl.Text = catNames(i)
		lbl.TextSize = 16
		lbl.TextColor = Colors.RGB(40, 40, 40)
		lbl.Typeface = Typeface.DEFAULT_BOLD
		lbl.Gravity = Gravity.CENTER_VERTICAL
		row.AddView(lbl, 14%x, 0, 72%x, rowH)

		' Arrow
		Dim arrow As Label
		arrow.Initialize("")
		arrow.Text = "›"
		arrow.TextSize = 26
		arrow.TextColor = Colors.RGB(160, 30, 45)
		arrow.Gravity = Gravity.CENTER
		row.AddView(arrow, 90%x, 0, 6%x, rowH)

		' Touch listener
		Dim r As Reflector
		r.Target = row
		r.SetOnTouchListener("catrow_Touch")
	Next
End Sub

Sub catrow_Touch(ViewTag As Object, Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean
	If Action = 0 Then
		For i = 0 To pnlCategory.NumberOfViews - 1
			Dim v As Object = pnlCategory.GetView(i)
			If v Is Panel Then
				Dim p As Panel = v
				If p.Tag <> Null Then
					If p.Tag = ViewTag Then
						p.Color = Colors.ARGB(20, 160, 30, 45)
					End If
				End If
			End If
		Next
	Else If Action = 1 Then
		For i = 0 To pnlCategory.NumberOfViews - 1
			Dim v As Object = pnlCategory.GetView(i)
			If v Is Panel Then
				Dim p As Panel = v
				If p.Tag <> Null Then
					If p.Tag = ViewTag Then
						p.Color = Colors.White
					End If
				End If
			End If
		Next
		Dim tag As String = ViewTag
		ShowBuildingScreen(tag.SubString(4))
	End If
	Return True
End Sub
#End Region

#Region BUILDING LIST PAGE
Sub ShowBuildingScreen(category As String)
	CurrentCategory = category
	pnlBuildings.RemoveAllViews

	Dim pad As Int = 4%x

	Dim btnBack As Label
	btnBack.Initialize("btnBack")
	btnBack.Text = "‹"
	btnBack.TextSize = 25
	btnBack.TextColor = Colors.White
	btnBack.Gravity = Gravity.CENTER
	TopPanel.AddView(btnBack, 0, -20, 12%x, 8%y)

	TopPanelLabel.Text = category

	Dim r As Reflector
	r.Target = btnBack
	r.SetOnTouchListener("btnBack_Touch")

	' ScrollView for list
	Dim listH As Int = pnlBuildings.Height 
	svBuildings.Initialize(listH)
	pnlBuildings.AddView(svBuildings, 0, 0, 100%x, listH)

	' Filter by category
	Dim filtered As List
	filtered.Initialize
	For i = 0 To AllBuildings.Size - 1
		Dim b As BuildingEntry = AllBuildings.Get(i)
		If b.Category = category Then filtered.Add(b)
	Next

	Dim rowH As Int = 14%y
	svBuildings.Panel.Height = rowH * filtered.Size

	For i = 0 To filtered.Size - 1
		Dim b As BuildingEntry = filtered.Get(i)
		Dim rowTop As Int = i * rowH

		' Row
		Dim row As Panel
		row.Initialize("bld_" & b.Tag)
		row.Color = Colors.White
		row.Tag = "bld_" & b.Tag
		svBuildings.Panel.AddView(row, 0, rowTop, 100%x, rowH)

		' Divider
		Dim divider As Panel
		divider.Initialize("")
		divider.Color = Colors.ARGB(40, 0, 0, 0)
		svBuildings.Panel.AddView(divider, pad, rowTop + rowH, 100%x - pad * 2, 1dip)

		' Thumbnail
		Dim thumb As ImageView
		thumb.Initialize("")
		thumb.Gravity = Gravity.FILL
		Dim thumbSize As Int = 10%y
		If File.Exists(File.DirAssets, b.PhotoFile) Then
			thumb.Bitmap = LoadBitmap(File.DirAssets, b.PhotoFile)
		Else
			Dim placeholder As ColorDrawable
			placeholder.Initialize(Colors.ARGB(255, 200, 200, 200), 1%x)
			thumb.Background = placeholder
		End If
		row.AddView(thumb, pad, rowH / 2 - thumbSize / 2, 23%x, thumbSize)

		Dim lblName As Label
		lblName.Initialize("")
		Dim displayName As String = b.Name
		If displayName.Length > 28 Then displayName = displayName.SubString2(0, 26) & "..."
		lblName.Text = displayName
		lblName.TextSize = 15
		lblName.TextColor = Colors.RGB(40, 40, 40)
		lblName.Typeface = Typeface.DEFAULT_BOLD
		lblName.Gravity = Gravity.CENTER_VERTICAL
		row.AddView(lblName, 30%x, 0, 66%x, rowH)

		Dim arrow As Label
		arrow.Initialize("")
		arrow.Text = "›"
		arrow.TextSize = 26
		arrow.TextColor = Colors.RGB(160, 30, 45)
		arrow.Gravity = Gravity.CENTER
		row.AddView(arrow, 90%x, 0, 6%x, rowH)

		Dim r2 As Reflector
		r2.Target = row
		r2.SetOnTouchListener("bldrow_Touch")
	Next

	pnlCategory.Visible = False
	pnlBuildings.Visible = True
End Sub

Sub bldrow_Touch(ViewTag As Object, Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean
	If Action = 0 Then
		For i = 0 To svBuildings.Panel.NumberOfViews - 1
			Dim v As Object = svBuildings.Panel.GetView(i)
			If v Is Panel Then
				Dim p As Panel = v
				If p.Tag <> Null Then
					If p.Tag = ViewTag Then p.Color = Colors.ARGB(20, 160, 30, 45)
				End If
			End If
		Next
	Else If Action = 1 Then
		For i = 0 To svBuildings.Panel.NumberOfViews - 1
			Dim v As Object = svBuildings.Panel.GetView(i)
			If v Is Panel Then
				Dim p As Panel = v
				If p.Tag <> Null Then
					If p.Tag = ViewTag Then p.Color = Colors.White
				End If
			End If
		Next
		Dim tag As String = ViewTag
		MapPage.SelectedPinTag = tag.SubString(4)
		StartActivity(MapPage)
		SetAnimation("slide_in_left", "slide_out_right")
		TopPanel.SetLayoutAnimated(100, TopPanel.Left, -TopPanel.Height, TopPanel.Width, TopPanel.Height)
		BottomPanel.SetLayoutAnimated(100, BottomPanel.Left, 100%y, BottomPanel.Width, BottomPanel.Height)
		Activity.Finish
	End If
	Return True
End Sub

Sub btnBack_Touch(ViewTag As Object, Action As Int, X As Float, Y As Float, MotionEvent As Object) As Boolean
	If Action = 1 Then
		pnlBuildings.Visible = False
		pnlCategory.Visible = True
		TopPanelLabel.Text = "Places"
	End If
	Return True
End Sub
#End Region
Sub Activity_Resume
End Sub

Sub Activity_Pause(UserClosed As Boolean)
End Sub

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
		QrButton.Color = Colors.RGB(181, 33, 52)
	Else If Action = 1 Then
		QrButton.Color = Colors.RGB(142, 30, 44)
		StartActivity(QrScannerPage)
		SetAnimation("slide_in_left", "slide_out_right")
		TopPanel.SetLayoutAnimated(100, TopPanel.Left, -TopPanel.Height, TopPanel.Width, TopPanel.Height)
		BottomPanel.SetLayoutAnimated(100, BottomPanel.Left, 100%y, BottomPanel.Width, BottomPanel.Height)
		Activity.Finish
	End If
End Sub

Private Sub MapButton_Touch(Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		MapButton.Color = Colors.RGB(181, 33, 52)
	Else If Action = 1 Then
		MapButton.Color = Colors.RGB(142, 30, 44)
		StartActivity(MapPage)
		SetAnimation("slide_in_left", "slide_out_right")
		TopPanel.SetLayoutAnimated(100, TopPanel.Left, -TopPanel.Height, TopPanel.Width, TopPanel.Height)
		BottomPanel.SetLayoutAnimated(100, BottomPanel.Left, 100%y, BottomPanel.Width, BottomPanel.Height)
		Activity.Finish
	End If
End Sub

Private Sub BuildingButton_Touch(Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		BuildingButton.Color = Colors.RGB(181, 33, 52)
	Else If Action = 1 Then
		BuildingButton.Color = Colors.RGB(142, 30, 44)
	End If
End Sub
#End Region
