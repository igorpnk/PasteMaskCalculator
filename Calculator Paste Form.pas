
Procedure StartScript ();
var
Board              : IPCB_Board;         //Circuit Board Object Variable


Begin
     Board := PCBServer.GetCurrentPCBBoard;

     if Board = nil then // check for open circuit board
     Begin
          ShowError('Open PCBLib!');
          Exit;
     end;

     Form1.Show;

End;


procedure btAutoRotateClick(Sender: TObject);
var
Board         : IPCB_Board;
Pad           : IPCB_Pad;
begin
     Board := PCBServer.GetCurrentPCBBoard;

     if Board.SelectecObject[0] = nil then // check for open circuit board
     Begin
          ShowError('Please select Pad!');
          Exit;
     end;
     Pad := Board.SelectecObject[0];

     if Pad.XSizeOnLayer[eTopLayer] > Pad.YSizeOnLayer[eTopLayer] then
     begin
          rbRight.Checked := true;
     end else
     begin
          rbUp.Checked := true;
     end;


end;

procedure TForm1.btnGenerateFingerFormClick(Sender: TObject);
var
Padcache      : TPadCache;
XL,YU,XR,YD   : Tcoord;
Indent        : Double;
Rad,RadU      : Double;
Region        : IPCB_Region;
Board         : IPCB_Board;
GeomPoly      : IPCB_GeometricPolygon;
Contour       : IPCB_Contour;
Contour2      : IPCB_Contour;
Number        : Double;
track         : IPCB_Track;
RegPol        : IPCB_Polygon;
NewPoly       : IPCB_Polygon;
prim          : IPCB_Primitive;
text          : String;
Pad           : IPCB_Pad;


begin
     Board := PCBServer.GetCurrentPCBBoard;

     if Board.SelectecObject[0] = nil then // check for open circuit board
     Begin
          ShowError('Please select Pad!');
          Exit;
     end;

     Pad := Board.SelectecObject[0];

     if cbAutoDetect.Checked then
     begin
       btAutoRotateClick(Sender);
     end;

     PCBServer.PreProcess;


     Board.DispatchMessage(null, null, PCBM_ProcessStart, null);

     Padcache := Pad.Cache;

     Padcache.PasteMaskExpansion        := MMsToCoord(-2539);
     Padcache.PasteMaskExpansionValid   := eCacheManual;
     pad.Cache := Padcache;

     Str2Double(tbFingerIndent.Text,Indent);
     Str2Double(tbFingerRad.Text,Rad);

     XL:= Pad.x - Pad.XSizeOnLayer[eTopLayer]/2 + MMsToCoord(Indent);
     XR:= Pad.x + Pad.XSizeOnLayer[eTopLayer]/2 - MMsToCoord(Indent);
     YU:= Pad.y + Pad.YSizeOnLayer[eTopLayer]/2 - MMsToCoord(Indent);
     YD:= Pad.y - Pad.YSizeOnLayer[eTopLayer]/2 + MMsToCoord(Indent);

     if (rbRight.Checked | rbLeft.Checked) then
     begin
     XL:= Pad.x - Pad.YSizeOnLayer[eTopLayer]/2 + MMsToCoord(Indent);
     XR:= Pad.x + Pad.YSizeOnLayer[eTopLayer]/2 - MMsToCoord(Indent);
     YU:= Pad.y + Pad.XSizeOnLayer[eTopLayer]/2 - MMsToCoord(Indent);
     YD:= Pad.y - Pad.XSizeOnLayer[eTopLayer]/2 + MMsToCoord(Indent);
     end;

     Region := PCBServer.PCBObjectFactory(eRegionObject, eNoDimension, eCreate_Default);
     Contour2 := PCBServer.PCBContourFactory();

     Region.Layer := eTopPaste;

     PCBServer.PCBContourMaker.ArcResolution := MMsToCoord(0.001);

     PCBServer.PCBContourMaker.AddArcToContour(Contour2,270,180,XL+MMsToCoord(Rad),YD+MMsToCoord(Rad),MMsToCoord(Rad),true);

     RadU := XR - XL;

     PCBServer.PCBContourMaker.AddArcToContour(Contour2,180,0,XL+RadU/2,YU-RadU/2,RadU/2,true);

     PCBServer.PCBContourMaker.AddArcToContour(Contour2,0,270,XR-MMsToCoord(Rad),YD+MMsToCoord(Rad),MMsToCoord(Rad),true);

     Contour2.RotateAboutPoint(Pad.Rotation,pad.x,Pad.y);

     if (rbRight.Checked | rbLeft.Checked)then
     Contour2.RotateAboutPoint(-90,pad.x,Pad.y);

     if (rbDown.Checked | rbLeft.Checked) then
     Contour2.RotateAboutPoint(180,pad.x,Pad.y);

     GeomPoly := PCBServer.PCBGeometricPolygonFactory();
     GeomPoly.AddContour(Contour2);
     Region.GeometricPolygon := GeomPoly;

     Region.GraphicallyInvalidate;

     Board.AddPCBObject(Region);
     Board.DispatchMessage(Board.I_ObjectAddress, c_Broadcast, PCBM_BoardRegisteration, Region.I_ObjectAddress);

     Board.DispatchMessage(null, null, PCBM_ProcessEnd, null);

     PCBServer.PostProcess;
     Board.DispatchMessage(c_FromSystem, c_BroadCast, PCBM_YieldToRobots, c_NoEventData);
end;

procedure TForm1.btClearClick(Sender: TObject);
var
Board          : IPCB_Board;
IteratorHandle : IPCB_BoardIterator;
Region2         : IPCB_Region;

begin
     Board := PCBServer.GetCurrentPCBBoard;
     PCBServer.PreProcess;
     Board.BeginModify;
     IteratorHandle := Board.BoardIterator_Create;
     IteratorHandle.AddFilter_LayerSet(MkSet(eTopPaste));
     IteratorHandle.AddFilter_ObjectSet(MkSet(eRegionObject));
     IteratorHandle.AddFilter_Method(eProcessAll);
     Region2 := IteratorHandle.FirstPCBObject; // получаем первый компонент
     While (Region2 <> Nil) Do
     Begin
          Board.RemovePCBObject(Region2);
          Region2 := IteratorHandle.NextPCBObject;
     End;
     Board.BoardIterator_Destroy(IteratorHandle);
     Board.EndModify;
     Board.GraphicallyInvalidate;
     PCBServer.PostProcess;
     Board.ViewManager_FullUpdate;
end;
procedure TForm1.rbMatrixRectClick(Sender: TObject);
begin
     imMatrixRect.Visible := True;
     imMatrixSpacing.Visible := False;
end;


procedure TForm1.rbMatrixSpacingClick(Sender: TObject);
begin
     imMatrixRect.Visible := False;
     imMatrixSpacing.Visible := True;
end;



procedure TForm1.btnGenerateRoundedFormClick(Sender: TObject);
var
Padcache      : TPadCache;
XL,YU,XR,YD   : Tcoord;
Indent        : Double;
Rad,RadU      : Double;
Region        : IPCB_Region;
Board         : IPCB_Board;
GeomPoly      : IPCB_GeometricPolygon;
Contour       : IPCB_Contour;
Contour2      : IPCB_Contour;
Number        : Double;
track         : IPCB_Track;
RegPol        : IPCB_Polygon;
NewPoly       : IPCB_Polygon;
prim          : IPCB_Primitive;
text          : String;
Pad           : IPCB_Pad;


begin
     Board := PCBServer.GetCurrentPCBBoard;

     if Board.SelectecObject[0] = nil then // check for open circuit board
     Begin
          ShowError('Please select Pad!');
          Exit;
     end;

     Pad := Board.SelectecObject[0];

     if cbAutoDetect.Checked then
     begin
       btAutoRotateClick(Sender);
     end;

     PCBServer.PreProcess;

     Board.DispatchMessage(null, null, PCBM_ProcessStart, null);

     Padcache := Pad.Cache;

     Padcache.PasteMaskExpansion        := MMsToCoord(-2539);
     Padcache.PasteMaskExpansionValid   := eCacheManual;
     pad.Cache := Padcache;

     Str2Double(tbRoundedIndent.Text,Indent);
     Str2Double(tbRoundedRad.Text,Rad);

     XL:= Pad.x - Pad.XSizeOnLayer[eTopLayer]/2 + MMsToCoord(Indent);
     XR:= Pad.x + Pad.XSizeOnLayer[eTopLayer]/2 - MMsToCoord(Indent);
     YU:= Pad.y + Pad.YSizeOnLayer[eTopLayer]/2 - MMsToCoord(Indent);
     YD:= Pad.y - Pad.YSizeOnLayer[eTopLayer]/2 + MMsToCoord(Indent);

     if (rbRight.Checked | rbLeft.Checked) then
     begin
     XL:= Pad.x - Pad.YSizeOnLayer[eTopLayer]/2 + MMsToCoord(Indent);
     XR:= Pad.x + Pad.YSizeOnLayer[eTopLayer]/2 - MMsToCoord(Indent);
     YU:= Pad.y + Pad.XSizeOnLayer[eTopLayer]/2 - MMsToCoord(Indent);
     YD:= Pad.y - Pad.XSizeOnLayer[eTopLayer]/2 + MMsToCoord(Indent);
     end;

     Region := PCBServer.PCBObjectFactory(eRegionObject, eNoDimension, eCreate_Default);
     Contour2 := PCBServer.PCBContourFactory();

     Region.Layer := eTopPaste;

     PCBServer.PCBContourMaker.ArcResolution := MMsToCoord(0.001);

     PCBServer.PCBContourMaker.AddArcToContour(Contour2,270,180,XL+MMsToCoord(Rad),YD+MMsToCoord(Rad),MMsToCoord(Rad),true);

     PCBServer.PCBContourMaker.AddArcToContour(Contour2,180,90,XL+MMsToCoord(Rad),YU-MMsToCoord(Rad),MMsToCoord(Rad),true);

     PCBServer.PCBContourMaker.AddArcToContour(Contour2,90,0,XR-MMsToCoord(Rad),YU-MMsToCoord(Rad),MMsToCoord(Rad),true);
     //RadU := XR - XL;

     //PCBServer.PCBContourMaker.AddArcToContour(Contour2,180,0,XL+RadU/2,YU-RadU/2,RadU/2,true);

     PCBServer.PCBContourMaker.AddArcToContour(Contour2,0,270,XR-MMsToCoord(Rad),YD+MMsToCoord(Rad),MMsToCoord(Rad),true);

     Contour2.RotateAboutPoint(Pad.Rotation,pad.x,Pad.y);

     if (rbRight.Checked | rbLeft.Checked)then
     Contour2.RotateAboutPoint(-90,pad.x,Pad.y);

     if (rbDown.Checked | rbLeft.Checked) then
     Contour2.RotateAboutPoint(180,pad.x,Pad.y);

     GeomPoly := PCBServer.PCBGeometricPolygonFactory();
     GeomPoly.AddContour(Contour2);
     Region.GeometricPolygon := GeomPoly;

     Region.GraphicallyInvalidate;

     Board.AddPCBObject(Region);
     Board.DispatchMessage(Board.I_ObjectAddress, c_Broadcast, PCBM_BoardRegisteration, Region.I_ObjectAddress);

     Board.DispatchMessage(null, null, PCBM_ProcessEnd, null);

     PCBServer.PostProcess;
     Board.DispatchMessage(c_FromSystem, c_BroadCast, PCBM_YieldToRobots, c_NoEventData);
end;

procedure TForm1.tbFingerIndentChange(Sender: TObject);
begin
     tbMatrixIndent.Text := tbFingerIndent.Text;
     tbRoundedIndent.Text := tbFingerIndent.Text;

end;

procedure TForm1.tbRoundedIndentChange(Sender: TObject);
begin
     tbMatrixIndent.Text := tbRoundedIndent.Text;
     tbFingerIndent.Text := tbRoundedIndent.Text;
end;


procedure TForm1.tbMatrixIndentChange(Sender: TObject);
begin
      tbRoundedIndent.Text := tbMatrixIndent.Text;
      tbFingerIndent.Text := tbMatrixIndent.Text;
end;

procedure TForm1.tbFingerRadChange(Sender: TObject);
begin
     tbMatrixRad.Text := tbFingerRad.Text;
     tbRoundedRad.Text := tbFingerRad.Text;
end;

procedure TForm1.tbRoundedRadChange(Sender: TObject);
begin
     tbMatrixRad.Text := tbRoundedRad.Text;
     tbFingerRad.Text := tbRoundedRad.Text;
end;

procedure TForm1.tbMatrixRadChange(Sender: TObject);
begin
     tbRoundedRad.Text := tbMatrixRad.Text;
     tbFingerRad.Text := tbMatrixRad.Text;
end;


procedure TForm1.Label2Click(Sender: TObject);
begin   
    ShellLinkResolve('https://t.me/Wolfiit');
end;

