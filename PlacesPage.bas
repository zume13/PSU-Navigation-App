B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Activity
Version=13.4
@EndOfDesignText@
#Region  Activity Attributes 
	#FullScreen: False
	#IncludeTitle: False
#End Region

Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.
End Sub

Sub Globals
	'These global variables will be redeclared each time the activity is created.
	'These variables can only be accessed from this module.
	Private BottomPanel As Panel
	Private BuildingButton As Panel
	Private MapButton As Panel
	Private ModeIcon As ImageView
	Private QrButton As Panel
	Private searchButton As Button
	Private searchEditText As EditText
	Private TopPanel As Panel
	
	Private NextPage    As Object
	Private pnlSlide    As Panel
	Private appWidth    As Int
	Private appHeight   As Int
	Private tmr         As Timer
	Private tmrFinish   As Timer

End Sub

Sub Activity_Create(FirstTime As Boolean)
	'Do not forget to load the layout file created with the visual designer. For example:
	Activity.Color = Colors.RGB(142, 30, 44)
	Activity.LoadLayout("PlacesPage")
	ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "sun.png")
	
End Sub

Sub Activity_Resume
	appWidth  = Activity.Width
	appHeight = Activity.Height
'	
'	If  Starter.IsDarkMode Then
'		ModeIcon.Bitmap      = LoadBitmap(File.DirAssets, "moon.png")
'		TopPanel.Color       = Colors.RGB(30, 30, 30)
'		BottomPanel.Color    = Colors.RGB(30, 30, 30)
'		searchEditText.Color = Colors.White
'	Else
'		ModeIcon.Bitmap   = LoadBitmap(File.DirAssets, "sun.png")
'		TopPanel.Color    = Colors.RGB(255, 255, 255)
'		BottomPanel.Color = Colors.RGB(255, 255, 255)
'	End If
End Sub

Sub Activity_Pause (UserClosed As Boolean)

End Sub


Private Sub searchButton_Click
	
End Sub

Private Sub QrButton_Touch (Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		QrButton.Color = Colors.RGB(183, 43, 60)
	Else If Action = 1 Then
		QrButton.Color = Colors.RGB(142, 30, 44)
		GoToPage(QrScannerPage)
	End If
End Sub

Private Sub ModeIcon_Click
'	Starter.IsDarkMode = Not(Starter.IsDarkMode)
'    
'	If Starter.IsDarkMode Then
'		ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "moon.png")
'		TopPanel.Color    = Colors.RGB(30, 30, 30)
'		BottomPanel.Color = Colors.RGB(30, 30, 30)
'		searchEditText.Color = Colors.White
'		
'	Else
'		ModeIcon.Bitmap = LoadBitmap(File.DirAssets, "sun.png")
'		TopPanel.Color    = Colors.RGB(255, 255, 255)
'		BottomPanel.Color = Colors.RGB(255, 255, 255)
'	End If
End Sub

Private Sub MapButton_Touch (Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		MapButton.Color = Colors.RGB(183, 43, 60)
	Else If Action = 1 Then
		MapButton.Color = Colors.RGB(142, 30, 44)
		GoToPage(MapPage)
	End If
End Sub

Private Sub BuildingButton_Touch (Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		BuildingButton.Color = Colors.RGB(183, 43, 60)
	Else If Action = 1 Then
		BuildingButton.Color = Colors.RGB(142, 30, 44)
	End If
End Sub

Sub GoToPage(NextActivity As Object)
	Activity.Color = Colors.RGB(142, 30, 44)
	NextPage = NextActivity

	pnlSlide.Initialize("")
	Activity.AddView(pnlSlide, appWidth - 1, 0, appWidth, appHeight)
	pnlSlide.Color = Colors.RGB(142, 30, 44)
	pnlSlide.Visible = True
	pnlSlide.BringToFront
	pnlSlide.SetLayoutAnimated(800, 0, 0, appWidth, appHeight)

	tmr.Initialize("tmr", 800)
	tmr.Enabled = True
End Sub

Sub tmr_Tick
	tmr.Enabled = False
	
	Dim jo As JavaObject
	jo.InitializeContext
	jo.RunMethod("overridePendingTransition", Array(0, 0))
	
	StartActivity(NextPage)
	
	jo.RunMethod("overridePendingTransition", Array(0, 0))
	
	Activity.Finish
End Sub


Sub GoBack
	Activity.Color = Colors.RGB(142, 30, 44)

	pnlSlide.Initialize("")
	Activity.AddView(pnlSlide, -appWidth, 0, appWidth, appHeight)
	pnlSlide.Color = Colors.RGB(142, 30, 44)
	pnlSlide.Visible = True
	pnlSlide.BringToFront
	pnlSlide.SetLayoutAnimated(800, 0, 0, appWidth, appHeight)

	tmrFinish.Initialize("tmrFinish", 800)
	tmrFinish.Enabled = True
End Sub

Sub tmrFinish_Tick
	tmrFinish.Enabled = False
	Activity.Finish
End Sub