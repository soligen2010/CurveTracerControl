
/*//////////////////////////////////////////////////////////////////
              -    FB Aka Heartman/Hearty 2016     -                   
              -   http://heartygfx.blogspot.com    -                  
              -       OpenScad Parametric Box      -                     
              -         CC BY-NC 3.0 License       -                      
////////////////////////////////////////////////////////////////////                                                                                                             
12/02/2016 - Fixed minor bug 
28/02/2016 - Added holes ventilation option                    
09/03/2016 - Added PCB feet support, fixed the shell artefact on export mode. 
21/11/2017 by Richard Pillay - Added ability to have up to 4 PCBs

*/////////////////////////// - Info - //////////////////////////////

// All coordinates are starting as integrated circuit pins.
// From the top view :

//   CoordD           <---       CoordC
//                                 ^
//                                 ^
//                                 ^
//   CoordA           --->       CoordB


////////////////////////////////////////////////////////////////////


////////// - Paramètres de la boite - Box parameters - /////////////

/* [Box dimensions] */
// - Longueur - Length  
  Length        = 135;       
// - Largeur - Width
  Width         = 210;                     
// - Hauteur - Height  
  Height        = 85;  
// - Epaisseur - Wall thickness  
  Thick         = 2;//[2:5]  
// - Extra Panel Thickness - Double thickness (except edge) 
// usefull if panel contains a difficult plug
  ThickPanels   = 1;// 0 or 1
/* [Box options] */
// - Diamètre Coin arrondi - Filet diameter  
  Filet         = 4;//[0.1:12] 
// - lissage de l'arrondi - Filet smoothness  
  Resolution    = 50;//[1:100] 
// - Tolérance - Tolerance (Panel/rails gap)
  m             = 0.9;
// Pieds PCB - PCB feet (x4 for each) 
  PCB01Feet       = 0;// [0:No, 1:Yes]
  PCB02Feet       = 0;// [0:No, 1:Yes]
  PCB03Feet       = 0;// [0:No, 1:Yes]
  PCB04Feet       = 0;// [0:No, 1:Yes]
// - Decorations to ventilation holes
  Vent          = 1;// [0:No, 1:Yes]
// - Decoration-Holes width (in mm)
      Vent_width    = 1.5;   


  
/* [PCB_Feet] */
//All dimensions are from the center foot axis

PCB01Text = "PSU";
// - Coin bas gauche - Low left corner X position
PCB01PosX         = 10;
// - Coin bas gauche - Low left corner Y position
PCB01PosY         = 4;
// - Longueur PCB01 - PCB01 Length
PCB01Length       = 75;
// - Largeur PCB01 - PCB01 Width
PCB01Width        = 55;
// - Heuteur pied - Feet height
PCB01FootHeight      = 10;
// - Diamètre pied - Foot diameter
PCB01FootDiam         = 8;
// - Diamètre trou - Hole diameter
PCB01FootHole        = 2;  

PCB02Text = "Main";
PCB02PosX           = 10;
PCB02PosY           = 73;
PCB02Length         = 75;
PCB02Width          = 115;
PCB02FootHeight     = 10;
PCB02FootDiam      = 8;
PCB02FootHole        = 2;  
  
PCB03Text = "Regulator";
PCB03PosX           = 70;
PCB03PosY         = 110;
PCB03Length       = 50;
PCB03Width        = 55;
PCB03FootHeight      = 15;
PCB03FootDiam         = 10;
PCB03FootHole        = 3;  
  
PCB04Text = "FanMount";
PCB04PosX         = 25;
PCB04PosY         = 33;
PCB04Length       = 105;
PCB04Width        = 105;
    PCB04FootHeight      = 5;
PCB04FootDiam         = 12;
PCB04FootHole        = 5;  
  

/* [STL element to export] */
//Coque haut - Top shell
TShell          = 0;// [0:No, 1:Yes]
//Coque bas- Bottom shell
BShell          = 0;// [0:No, 1:Yes]
//Panneau avant - Front panel
FPanL           = 1;// [0:No, 1:Yes]
//Panneau arrière - Back panel  
BPanL           = 0;// [0:No, 1:Yes]


  
/* [Hidden] */
// - Couleur coque - Shell color  
Couleur1        = "Orange";       
// - Couleur panneaux - Panels color    
Couleur2        = "OrangeRed";    
// Thick X 2 - making decorations thicker if it is a vent to make sure they go through shell
Dec_Thick       = Vent ? Thick*2 : Thick; 
// - Depth decoration
Dec_size        = Vent ? Thick*2 : 0.8;





/////////// - Boitier générique bord arrondis - Generic rounded box - //////////

module RoundBox($a=Length, $b=Width, $c=Height){// Cube bords arrondis
                    $fn=Resolution;            
                    translate([0,Filet,Filet]){  
                    minkowski (){                                              
                        cube ([$a-(Length/2),$b-(2*Filet),$c-(2*Filet)], center = false);
                        rotate([0,90,0]){    
                        cylinder(r=Filet,h=Length/2, center = false);
                            } 
                        }
                    }
                }// End of RoundBox Module

      
////////////////////////////////// - Module Coque/Shell - //////////////////////////////////         

module Coque(){//Coque - Shell  
    Thick = Thick*2;  
    difference(){    
        difference(){//sides decoration
            union(){    
                     difference() {//soustraction de la forme centrale - Substraction Fileted box
                      
                        difference(){//soustraction cube median - Median cube slicer
                            union() {//union               
                            difference(){//Coque    
                                RoundBox();
                                translate([Thick/2,Thick/2,Thick/2]){     
                                        RoundBox($a=Length-Thick, $b=Width-Thick, $c=Height-Thick);
                                        }
                                        }//Fin diff Coque                            
                                difference(){//largeur Rails        
                                     translate([Thick+m,Thick/2,Thick/2]){// Rails
                                          RoundBox($a=Length-((2*Thick)+(2*m)), $b=Width-Thick, $c=Height-(Thick*2));
                                                          }//fin Rails
                                     translate([((Thick+m/2)*1.55),Thick/2,Thick/2+0.1]){ // +0.1 added to avoid the artefact
                                          RoundBox($a=Length-((Thick*3)+2*m), $b=Width-Thick, $c=Height-Thick);
                                                    }           
                                                }//Fin largeur Rails
                                    }//Fin union                                   
                               translate([-Thick,-Thick,Height/2]){// Cube à soustraire
                                    cube ([Length+100, Width+100, Height], center=false);
                                            }                                            
                                      }//fin soustraction cube median - End Median cube slicer
                               translate([-Thick/2,Thick,Thick]){// Forme de soustraction centrale 
                                    RoundBox($a=Length+Thick, $b=Width-Thick*2, $c=Height-Thick);       
                                    }                          
                                }                                          


                difference(){// wall fixation box legs
                    union(){
                        translate([3*Thick +5,Thick,Height/2]){
                            rotate([90,0,0]){
                                    $fn=6;
                                    cylinder(d=16,Thick/2);
                                    }   
                            }
                            
                       translate([Length-((3*Thick)+5),Thick,Height/2]){
                            rotate([90,0,0]){
                                    $fn=6;
                                    cylinder(d=16,Thick/2);
                                    }   
                            }

                        }
                            translate([4,Thick+Filet,Height/2-57]){   
                             rotate([45,0,0]){
                                   cube([Length,40,40]);    
                                  }
                           }
                           translate([0,-(Thick*1.46),Height/2]){
                                cube([Length,Thick*2,10]);
                           }
                    } //Fin fixation box legs
            }

        union(){// outbox sides decorations
            
            for(i=[0:Thick:Length/4]){

                // Ventilation holes part code submitted by Ettie - Thanks ;) 
                    translate([10+i,-Dec_Thick+Dec_size,1]){
                    cube([Vent_width,Dec_Thick,Height/4]);
                    }
                    translate([(Length-10) - i,-Dec_Thick+Dec_size,1]){
                    cube([Vent_width,Dec_Thick,Height/4]);
                    }
                    translate([(Length-10) - i,Width-Dec_size,1]){
                    cube([Vent_width,Dec_Thick,Height/4]);
                    }
                    translate([10+i,Width-Dec_size,1]){
                    cube([Vent_width,Dec_Thick,Height/4]);
                    }
  
                
                    }// fin de for
               // }
                }//fin union decoration
            }//fin difference decoration


            union(){ //sides holes
                $fn=50;
                translate([3*Thick+5,20,Height/2+4]){
                    rotate([90,0,0]){
                    cylinder(d=2,20);
                    }
                }
                translate([Length-((3*Thick)+5),20,Height/2+4]){
                    rotate([90,0,0]){
                    cylinder(d=2,20);
                    }
                }
                translate([3*Thick+5,Width+5,Height/2-4]){
                    rotate([90,0,0]){
                    cylinder(d=2,20);
                    }
                }
                translate([Length-((3*Thick)+5),Width+5,Height/2-4]){
                    rotate([90,0,0]){
                    cylinder(d=2,20);
                    }
                }
            }//fin de sides holes

        }//fin de difference holes
}// fin coque 

////////////////////////////// - Experiment - ///////////////////////////////////////////





/////////////////////// - Foot with base filet - /////////////////////////////
module foot(FootDia,FootHole,FootHeight){
    Filet=2;
    color(Couleur1)   
    translate([0,0,Filet-1.5])
    //translate([(Thick*3)+(FootDia/2)+(Filet/2)+m,(Thick)+(FootDia/2)+(Filet/2),Thick])
    difference(){
    
    difference(){
            //translate ([0,0,-Thick]){
                cylinder(d=FootDia+Filet,FootHeight-Thick, $fn=100);
                        //}
                    rotate_extrude($fn=100){
                            translate([(FootDia+Filet*2)/2,Filet,0]){
                                    minkowski(){
                                            //square(10);
                                            square(FootHeight-Filet);
                                            circle(Filet, $fn=100);
                                        }
                                 }
                           }
                   }
            cylinder(d=FootHole,FootHeight+1, $fn=100);
               }          
}// Fin module foot
  
module Feet(PCBText, Length, Width, FootHeight, FootDiam, FootHole){     
//////////////////// - PCB only visible in the preview mode - /////////////////////    
    translate([3*Thick+2,Thick+5,FootHeight+(Thick/2)-0.5]){
    
    %square ([Length+10,Width+10]);
       translate([Length/2,Width/2,0.5]){ 
        color("Olive")
        %text(PCBText, halign="center", valign="center", font="Arial black");
       }
    } // Fin PCB 
  
    
////////////////////////////// - 4 Feet - //////////////////////////////////////////     
    translate([3*Thick+7,Thick+10,Thick/2]){
        foot(FootDiam, FootHole, FootHeight);
    }
    translate([(3*Thick)+Length+7,Thick+10,Thick/2]){
        foot(FootDiam, FootHole, FootHeight);
        }
    translate([(3*Thick)+Length+7,(Thick)+Width+10,Thick/2]){
        foot(FootDiam, FootHole, FootHeight);
        }        
    translate([3*Thick+7,(Thick)+Width+10,Thick/2]){
        foot(FootDiam, FootHole, FootHeight);
    }   

} // Fin du module Feet
 




 
 ////////////////////////////////////////////////////////////////////////
////////////////////// <- Holes Panel Manager -> ///////////////////////
////////////////////////////////////////////////////////////////////////

//                           <- Panel ->  
module Panel(Length,Width,Thick,Filet){
    scale([0.5,1,1])
    minkowski(){
            cube([Thick,Width-(Thick*2+Filet*2+m),Height-(Thick*2+Filet*2+m)]);
            translate([0,Filet,Filet])
            rotate([0,90,0])
            cylinder(r=Filet,h=Thick, $fn=100);
      }
    if (ThickPanels==1) {
        translate(v = [0,Thick*1.25,Thick*1.25]){
        scale([Thick/2*.75,1,1])
            minkowski(){
                cube([Thick,Width-(Thick*4.5+Filet*2+m),Height-(Thick*4.5+Filet*2+m)]);
                translate([0,Filet,Filet])
                rotate([0,90,0])
                cylinder(r=Filet,h=Thick, $fn=100);
        }
      }
   }
}



//                          <- Circle hole -> 
// Cx=Cylinder X position | Cy=Cylinder Y position | Cdia= Cylinder dia | Cheight=Cyl height
module CylinderHole(OnOff,Cx,Cy,Cdia){
    if(OnOff==1)
    translate([Cx,Cy,-1])
        cylinder(d=Cdia,10, $fn=50);
}
//                          <- Square hole ->  
// Sx=Square X position | Sy=Square Y position | Sl= Square Length | Sw=Square Width | Filet = Round corner
module SquareHole(OnOff,Sx,Sy,Sl,Sw,Filet){
    if(OnOff==1)
     minkowski(){
        translate([Sx+Filet/2,Sy+Filet/2,-1])
            cube([Sl-Filet,Sw-Filet,10]);
            cylinder(d=Filet,h=10, $fn=100);
       }
}


 
//                      <- Linear text panel -> 
module LText(OnOff,Tx,Ty,Font,Size,Content){
    if(OnOff==1)
    translate([Tx,Ty,Thick+.5])
    linear_extrude(height = 0.5){
    text(Content, size=Size, font=Font);
    }
}
//                     <- Circular text panel->  
module CText(OnOff,Tx,Ty,Font,Size,TxtRadius,Angl,Turn,Content){ 
      if(OnOff==1) {
      Angle = -Angl / len(Content);
      translate([Tx,Ty,Thick+.5])
          for (i= [0:len(Content)-1] ){   
              rotate([0,0,i*Angle+90+Turn])
              translate([0,TxtRadius,0]) {
                linear_extrude(height = 0.5){
                text(Content[i], font = Font, size = Size,  valign ="baseline", halign ="center");
                    }
                }   
             }
      }
}
////////////////////// <- New module Panel -> //////////////////////
module FPanL(){
    difference(){
        color(Couleur2)
        Panel(Length,Width,Thick,Filet);
    
 
    rotate([90,0,90]){
        color(Couleur2){
//                     <- Cutting shapes from here ->  
       // SquareHole  (1,20,20,15,10,1); //(On/Off, Xpos,Ypos,Length,Width,Filet)
       // SquareHole  (1,40,20,15,10,1);
       // SquareHole  (1,60,20,15,10,1); 
       // CylinderHole(1,27,40,8);       //(On/Off, Xpos, Ypos, Diameter)
       // CylinderHole(1,47,40,8);
       /// CylinderHole(1,67,40,8);
        SquareHole  (1,68,42,71.5,24.3,.5); //LCD
        CylinderHole(1,150,20,7.25); // Step Gain
        CylinderHole(1,60,20,7.25); // Signal gain
        CylinderHole(1,163,55,7.25); // LCD Encoder
        CylinderHole(1,190,55,9.25); // Step A
        CylinderHole(1,190,20,6.3); // Step Out
            
        CylinderHole(1,86,20,9.25); // Sig
        CylinderHole(1,105,20,9.25); // Gnd
        CylinderHole(1,124,20,9.25); // Step
            
        CylinderHole(1,17,55,14); // Power
        CylinderHole(1,17,20,6.3); // Freq
        CylinderHole(1,38,20,6.3); // Current
            
        CylinderHole(1,170,20,6.3); // Step +/-

        CylinderHole(1,45,55,9.25); // Sig Out BNC
            
            
       // SquareHole  (1,120,20,30,60,3);
//                            <- To here -> 
           }
       }
}
    color(Couleur1){
        translate ([(ThickPanels==1)?.5:-.6,0,0])
        rotate([90,0,90]){
//                      <- Adding text from here ->          
        //LText(1,10,70,"Arial Black",3,"Power");//(On/Off, Xpos, Ypos, "Font", Size, "Text")
        //LText(1,38.2,70,"Arial Black",3,"Probe");
        //LText(1,12,33,"Arial Black",3,"Freq");
        //LText(1,6.7,25,"Arial Black",3,"H");
        //LText(1,6.7,11,"Arial Black",3,"L");
        //LText(1,30.5,33,"Arial Black",3,"1 mA/V");
        //LText(1,29.5,6,"Arial Black",3,".1 mA/V");
            
        //LText(1,53.5,36,"Arial Black",3,"Probe");
        //LText(1,55,31,"Arial Black",3,"Gain");
            
        //LText(1,144.5,36,"Arial Black",3,"Step");
        //LText(1,144.5,31,"Arial Black",3,"Gain");
            
        //LText(1,165,36,"Arial Black",3,"Step");
        //LText(1,162,31,"Arial Black",3,"Polarity");
        //LText(1,177,24,"Arial Black",4,"+");
        //LText(1,177,10,"Arial Black",5,"-");

        //LText(1,180.5,70,"Arial Black",3,"Step Out");
        //LText(1,183,33,"Arial Black",3,"Step A");
 
        //LText(1,79.3,33,"Arial Black",3,"Probe");
        //LText(1,100,33,"Arial Black",3,"GND");
        //LText(1,118.6,33,"Arial Black",3,"Step");

 
            
        //LText(1,120,83,"Arial Black",4,"Level");
        //LText(1,20,11,"Arial Black",6,"  1     2      3");
        //CText(1,93,29,"Arial Black",4,10,180,0,"1 . 2 . 3 . 4 . 5 . 6");//(On/Off, Xpos, Ypos, "Font", Size, Diameter, Arc(Deg), Starting Angle(Deg),"Text")
//                            <- To here ->
            }
      }
}

module RPanL(){
    difference(){
        color(Couleur2)
        Panel(Length,Width,Thick,Filet);
    
 
    rotate([90,0,90]){
        color(Couleur2){
//                     <- Cutting shapes from here ->  
        SquareHole  (1,26.1,35.25,27,19,3); //(On/Off, Xpos,Ypos,Length,Width,Filet)
       // SquareHole  (1,110,45,60,60,1);
      //  SquareHole  (1,60,20,15,10,1); 
      //  CylinderHole(1,27,40,8);       //(On/Off, Xpos, Ypos, Diameter)
        CylinderHole(1,19.6,44.75,3.2);
        CylinderHole(1,59.6,44.75,3.2);
            
        CylinderHole(1,39.6,18,15);
      //  SquareHole  (1,20,50,80,30,3);
        //CylinderHole(1,115,50,3.2);
        //CylinderHole(1,165,50,3.2);
        //CylinderHole(1,115,100,3.2);
        //CylinderHole(1,165,100,3.2);
        //CylinderHole(1,140,75,55);
      //  SquareHole  (1,120,20,30,60,3);
//                            <- To here -> 
        CylinderHole(1,180,38,9.25); // Horizontal
        CylinderHole(1,145,38,9.25); // Vertical
           }
       }
}

    color(Couleur1){
        translate ([(ThickPanels==1)?.5:-.6,0,0])
        rotate([90,180,90]){
//                      <- Adding text from here ->          
        //LText(1,20,83,"Arial Black",4,"Digital Screen");//(On/Off, Xpos, Ypos, "Font", Size, "Text")
        //LText(1,120,83,"Arial Black",4,"Level");
        //LText(1,20,11,"Arial Black",6,"  1     2      3");
        //CText(1,93,29,"Arial Black",4,10,180,0,"1 . 2 . 3 . 4 . 5 . 6");//(On/Off, Xpos, Ypos, "Font", Size, Diameter, Arc(Deg), Starting Angle(Deg),"Text")
//                            <- To here ->
        LText(1,-189,-25,"Arial Black",5,"Horz");
        LText(1,-154,-25,"Arial Black",5,"Vert");
        LText(1,-189,-55,"Arial Black",5,"CH 1");
        LText(1,-155,-55,"Arial Black",5,"CH 2");
             }
      }
}


/////////////////////////// <- Main part -> /////////////////////////

if(TShell==1)
// Coque haut - Top Shell
        color( Couleur1,1){
            translate([0,Width,Height+0.2]){
                rotate([0,180,180]){
                        Coque();
                        }
                }
        }

if(BShell==1)
// Coque bas - Bottom shell
        color(Couleur1){ 
        Coque();
        }

// Pied support PCB01 - PCB01 feet
if (PCB01Feet==1)
// Feet
        translate([PCB01PosX,PCB01PosY,0]){ 
            Feet(PCB01Text, PCB01Length, PCB01Width, PCB01FootHeight, PCB01FootDiam, PCB01FootHole);     
        }

if (PCB02Feet==1)
// Feet
        translate([PCB02PosX,PCB02PosY,0]){ 
            Feet(PCB02Text, PCB02Length, PCB02Width, PCB02FootHeight, PCB02FootDiam, PCB02FootHole);     
        }

if (PCB03Feet==1)
// Feet
        translate([PCB03PosX,PCB03PosY,0]){ 
            Feet(PCB03Text, PCB03Length, PCB03Width, PCB03FootHeight, PCB03FootDiam, PCB03FootHole);     
        }

if (PCB04Feet==1)
// Feet
        translate([PCB04PosX,PCB04PosY,0]){ 
            Feet(PCB04Text, PCB04Length, PCB04Width, PCB04FootHeight, PCB04FootDiam, PCB04FootHole);     
        }

// Panneau avant - Front panel  <<<<<< Text and holes only on this one.
//rotate([0,-90,-90]) 
if(FPanL==1)
        translate([Length-(Thick*2+m/2),Thick+m/2,Thick+m/2])
        FPanL();

//Panneau arrière - Back panel
if(BPanL==1)
        color(Couleur2)
        translate([Thick+m/2,Thick+m/2,Thick+m/2])
        RPanL();