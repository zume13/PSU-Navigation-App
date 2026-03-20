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
	Private BuildingView As ImageView
	Private MapButton As Panel
	Private MapView As ImageView
	Private QrButton As Panel
	Private QrView As ImageView
	Private searchEditText As EditText
	Private TopPanel As Panel
	Private BuildingButton As Panel
End Sub

Sub Activity_Create(FirstTime As Boolean)
	'Do not forget to load the layout file created with the visual designer. For example:
	Activity.LoadLayout("Qr")
	
	TopPanel.Top = -TopPanel.Height
	BottomPanel.Top = 100%y
	Sleep(300)
	TopPanel.SetLayoutAnimated(500, TopPanel.Left, 0, TopPanel.Width, TopPanel.Height)
	BottomPanel.SetLayoutAnimated(500, BottomPanel.Left, 100%y - BottomPanel.Height, BottomPanel.Width, BottomPanel.Height)
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)

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
Private Sub QrButton_Touch (Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		QrButton.Color = Colors.RGB(181, 33, 52)
	Else If Action = 1 Then
		QrButton.Color = Colors.RGB(142, 30, 44)
	End If
End Sub

Private Sub MapButton_Touch (Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		QrButton.Color = Colors.RGB(183, 43, 60)
	Else If Action = 1 Then
		QrButton.Color = Colors.RGB(156, 28, 28)
		StartActivity(MapPage)
		SetAnimation("slide_in_left", "slide_out_right")
		TopPanel.SetLayoutAnimated(100, TopPanel.Left, -TopPanel.Height, TopPanel.Width, TopPanel.Height)
		BottomPanel.SetLayoutAnimated(100, BottomPanel.Left, 100%y, BottomPanel.Width, BottomPanel.Height)
		Activity.Finish
	End If
End Sub

Private Sub BuildingButton_Touch (Action As Int, X As Float, Y As Float)
	If Action = 0 Then
		BuildingButton.Color = Colors.RGB(181, 33, 52)
	Else If Action = 1 Then
		BuildingButton.Color = Colors.RGB(142, 30, 44)
		StartActivity(PlacesPage)
		SetAnimation("slide_in_right", "slide_out_left")
		TopPanel.SetLayoutAnimated(100, TopPanel.Left, -TopPanel.Height, TopPanel.Width, TopPanel.Height)
		BottomPanel.SetLayoutAnimated(100, BottomPanel.Left, 100%y, BottomPanel.Width, BottomPanel.Height)
		Activity.Finish
	End If
End Sub
#End Region
