B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' Class module: MapPin
Sub Class_Globals
	Private X22 As Double
	Private Y22 As Double
	
	' --- THE DUAL THRESHOLDS ---
	Private PinZoomThreshold As Double
	Private NameZoomThreshold As Double
	
	Public BasePanel As Panel
	Private ivIcon As ImageView
	Private lblTitle As Label
	
	Private PIN_WIDTH As Int = 150dip
	Private PIN_HEIGHT As Int = 60dip
	Private ICON_SIZE As Int = 28dip
	Private LABEL_HEIGHT As Int = 30dip
End Sub

Public Sub Initialize (pX22 As Double, pY22 As Double, pTitle As String, pIcon As Bitmap, pPinZoom As Double, pNameZoom As Double)
	X22 = pX22
	Y22 = pY22
	
	' Save both database priority thresholds
	PinZoomThreshold = pPinZoom
	NameZoomThreshold = pNameZoom
	
	' 1. Create the invisible base container
	BasePanel.Initialize("Pin")
	BasePanel.Color = Colors.Transparent
	
	' 2. Create the Custom Icon
	ivIcon.Initialize("")
	ivIcon.Bitmap = pIcon
	ivIcon.Gravity = Gravity.FILL
	BasePanel.AddView(ivIcon, (PIN_WIDTH / 2) - (ICON_SIZE / 2), LABEL_HEIGHT, ICON_SIZE, ICON_SIZE)
	
	' 3. Create the Text Label
	lblTitle.Initialize("")
	lblTitle.Text = pTitle
	lblTitle.TextColor = Colors.White
	lblTitle.TextSize = 11
	lblTitle.Typeface = Typeface.DEFAULT_BOLD
	lblTitle.Gravity = Gravity.CENTER
	lblTitle.Color = Colors.Transparent
	
	' Add the Black Outline Glow
	Dim radius As Float = 5.0
	Dim dx As Float = 0.0
	Dim dy As Float = 0.0
	Dim joLabel As JavaObject = lblTitle
	joLabel.RunMethod("setShadowLayer", Array As Object(radius, dx, dy, Colors.Black))
	
	BasePanel.AddView(lblTitle, 0, 0, PIN_WIDTH, LABEL_HEIGHT)
End Sub

Public Sub UpdatePosition(CameraX As Double, CameraY As Double, CurrentZoom As Double, WorldPerTile As Double, TileSize As Int)
	' --- PROGRESSIVE DISCLOSURE LOGIC ---
	
	' 1. Check if the entire pin should be hidden
	If CurrentZoom < PinZoomThreshold Then
		BasePanel.Visible = False
		Return
	Else
		BasePanel.Visible = True
	End If

	' 2. Check if the text label should be hidden
	If CurrentZoom < NameZoomThreshold Then
		lblTitle.Visible = False
	Else
		lblTitle.Visible = True
	End If

	' Standard GPU math
	Dim pixelX As Float = (((X22 - CameraX) / WorldPerTile) * TileSize) + (100%x / 2)
	Dim pixelY As Float = (((CameraY - Y22) / WorldPerTile) * TileSize) + (100%y / 2)
	
	BasePanel.Left = pixelX - (PIN_WIDTH / 2)
	BasePanel.Top = pixelY - PIN_HEIGHT
End Sub