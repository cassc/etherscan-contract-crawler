// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Age Of Slayer
// contract by: buildship.xyz

import "./ERC721Community.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    zzzzccczccccccccccvvvvuvuuuununnnxnxxxxxxxxxrxxxxxxxxxnnnnnunuuuvuvvvccvccccccccczzczzzzzz    //
//    zcczzcccccccccccvvvvuvvuuunnnxxxxxrrrrrrrrxxrrrxxxrxrrxxxxnxnnnuuvuuvvvccvccccccccczzzzzzz    //
//    zzzcccccccccccvvvvuuvuuunnnxxxrrrrrjt/t//\\|||||\//tttfxxxxxxxnnunuuuvvvvccvcccccczccczzzz    //
//    ccczccccccccvvvvvuuunnnnxxxxrrrr///\fttt\/tfffjrrjjffff||tjjrxxxnnnnuuuvvvvcvccccccczzcccz    //
//    zzzccccccccvvcvvuuunnnxxxrrrr//\ft\\|t((\\((|\\|((|\/fjjrxxxxnuuuxnnnuuuvvvvcccccccccczz**    //
//    ccccccccccccvvvuuunnnxxrrrr/\f/\||()/((t//xvuuuvczcvxxrrxnnunxxnxnxnnnuuuvvvvvcccczzzz**zv    //
//    czccccccccvvvvvuunnxxxrrrf|f/\|()11|xxvczzccccccccccczz*##*zcvvcvnxxnnnuuuuvvvvczccrfz#W88    //
//    cccccccccvvvvvuunnxxxrrr\/t\|()1{}{uzccvcczzzzccccccccczzz##*zvvuvnxxxnnuuuuvcvuvcvc*rc#&8    //
//    ccccccccvvvvuuunnnxxrrx(f/|()1{}[/vuvvcczzzcccvvvcczzzzzzzz**#*vnurtxxxnnuuuvunuuc#WWWcu#W    //
//    cccccccvcvvuuunnnxxrrx)j/|()1{[[rcuuvczz**zccvvvvcczzzzzzzzzz*#*uuvrjxxxnnuunxuc#W&&8&##xu    //
//    ccccccccvvvuuunnxxrrr|f/\()1}[]jzvvcz*###zzcuuvvczzz***zzzzzzz##currunxxnunnun#WWW&%%&Mun)    //
//    cccccccvvvvuuunnxxrrr(t\|(1{[][*cuvc*##M#ccvuuvcczzz*#***zzzzz#Mcuufx(nxunvczuW&W#MB&nxf-<    //
//    cccccccvvvvvunnnxrrr(j/\()1}[?{zuuvzzzzzzcvuunuvcz**####*****z##vuvjr(nxnvcz*#&W*cuj|[-}\u    //
//    cccccccccvvuunnxxrrr(j/|(){}]?\W%8WMWWWWM#cvvnnuncz#*MM##****v*znuvxf\(?-}v*c*Mvf\{})jcccz    //
//    cccccccvvvuuunnxxrrr)j/|(){}]?-c*WMMWM#**zz****cz%8W#WMM###*cvzunnvv1\)\1{vcuf)})\nccccccc    //
//    ccccccvvvvuuunnxxrrr(j/\()1}[[xvffczzzzz*#W&&8&#M%MM#WMMMM#cvcvnf(xnnjjvcvunfnjuvccccccccc    //
//    ccccccvvvvvuunnnxrrr|jt\|(){{nvnnxxcz*MW&&&88&W*z##WWWWWM*vvzvujfuz*vturt\/u#MWMcccccccccz    //
//    cccccccccvvvuunnxxrrx)f/\|)1|nz##zz*#W&&WWWWWW&#nzM&WWWMzvccuuxj#&W&WMM*zccnvnf|[xcccccccc    //
//    ccccccccvvvvvuunnxxrr/tt/|()1{}rxxu#MMWMMMMWW&8W&88&&&M*cvnjrxz&WWWM#MW&WMznf)?i;]cccccczz    //
//    zcccccccvvvvuuuunnxxrx|ft/\|(11rvvnc**###MW&&&W#88&&&W*nrfrnz#88&WWWMMMMWWWMvt)?!>vccccccc    //
//    cccccccccvvvvuuunnxxxrx|ff/\|()|uzz**#*MWW&&&WM&88&W&W*uc#MM&8%%8WWMMMW#WWWWWMcf}_ucccczzz    //
//    zccccccccccvvuuuunnnxxrx//ft\\||vjrc*MWW&&WWMM&&8&WWWMM##MMW8%%%WMMM#M&W8&WWMMMW|+cccccccz    //
//    zzzcccccccvvvvvuuunnnxxxrj\tft|tu*#MWWM#MWWW&8&&WWM##MMWW&88%%%&WWWWW88&&&WWWMMMMM*cczzzzz    //
//    cccccccccccvvvvvvuunnnxxxrrf\/rxfjj/rf/tr*MW&WWMMMMMW&&8888%%&&&8888%%888&88&&WMMW&*cczzzz    //
//    zzzzcccccccccvvvvvvuunnnxxxrrrttjntr/jnuzWMMMMMMWW&&&888%%&W&8%%%%%%%8&&&W&&888&&WWW#zzzzz    //
//    zccccccccccccccvvvvvuunnnnxxuuunrtfuuMMMMMWWW&&&&8888%%8WW&8%%%8%%%%%%%888%8&%%%88&&WW*zzz    //
//    zzzzzczzvnzccccccccvunuuuuunnc/&8WWMMMWW&&88&&88%88%%8W&8%%8%%%88888888%%%%%%%%%%%88&W#zzz    //
//    zzzcczf]]tcvnnnxrrxrrtjcuuuunj|&%&&8888888&&88%%8&88W&%%%%%%8888&WMMMMW&88%%%%%%%%%%8W#zzz    //
//    zzzzzf\xW#zcvz*MMWM###M*uxrv*cj8%%%8888%8&&88%%8WWMW8%%%%%%%%%%%&&W##*##MMW&8%%%%%8%8&#zzz    //
//    zzzr))x##&#****zcccc#W&8&W*uvcc8%%%%%%88888%8WM##MW8&MMW8888%%%%%888&MMM#**#MW8%%%8%%&*zzz    //
//    zzrffr&#zzzzzcccccccM%%&*z#cjr&8%%%%88888%&MMMMMMM8Wcc#&&&&&&&&&&&&8888&&&M#*#W&8%%%%Mzzzz    //
//    *rcW%#zzzzzccczccccc#MMWW8MW8%%&88%%%%%%8MMWW&&WM&&*#WWWWWWWWWWWWWMMWWW&8%%%%%%%%%%8M*zzzz    //
//    cW8%&zzzzcczcn//xvzcz&M*z&%%%%%8888%%%%8WWWWW&&&&&MW&WW&MMMM#######MMMMMMMW&WWMMM#zzzzzzzz    //
//    W888zzzzzzzzvrtruuuzM&&&8%%%%%%%%8888&W&&&WW8%%8&W&&&WW8WMM####MMMMWMM#######zzzzzzzzzzzzz    //
//    888*zzzzzzzvnxztfuv%BB&88%8%%%B%%888MvW8&8&8888W#W888&8&MMMMWMM&&W&&&&W#MWWM#M*zzzzzzzzzzz    //
//    88#zzzzcvzx{[tnxfjnnxxMM*&8%BBMc88%8W&&888%88&M*M&8888%WMW888&&&&W&WMMWW&&&&WMM#zzzzzzzzzz    //
//    8Wzzzzu{]fuvf)t\{\uxnxccz&%B%%[W888%vvcW888%%88888888%8&88&W&WMMW#MW&&&&WMM&&WMM*zzzzzzzzz    //
//    8zzn}}rur/uuxnrjruuxrnczz%B%%zu88%%%%%88%%%%8%%%&8&MM8888WWMW&&&&&&&&&&88&WMW&&WM*zzzzzzzz    //
//    zzzu(jxvuunrfnxxuzcvnruzMB%%Wu8888%8888&8%888%%88&&zM88&888888888888&&88&&WWMW&%&MWM*zzzzz    //
//    z*M&M#vrjxvuuncnzzvzvnczW%%#&M&888&8%8&WW8&&88%88&W#W&88888&&&888&&&u1z&&&&&&&WM8WWWW*zzzz    //
//    %#M&%8&cnnxcuc*j)}(tjrzz8%WW8&888&&88&&WM8&&888%88WW8&888888888#;}<uMxv&&WWWWW&WMMW8&W*zzz    //
//    8&#z#*##vcvuuuuj(jxjjvzM%&W88888&&8%&&&&W&%&88888&8#&88888%88888rzWuM#?tzWWWW&&WM#z*#WWzzz    //
//    zzzczxrccvxjncrjjjrjczz8%%%%88&W&88%&&&&&&8%88888WW&888888888888&vcvWWMWWWWW&&&&WM#*##WMzz    //
//    nvzzznnzczfrrnnuunrj/u*%BB%%&88&&8%%8&88888%%%%%&M*W888888888&888888888&&88888888&W#MMM&zz    //
//    zzzzzzzzvfvzzcnrrunvx/u%B%%B%88&88%%888888888%%%8Wzz88888&&8%888888888888888888&&&WWWWW&zz    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////

contract AgeOfSlayer is ERC721Community {
    constructor() ERC721Community("Age Of Slayer", "AOS", 5555, 400, START_FROM_ONE, "ipfs://bafybeifsiqwtauiu2gpowl5exzfhx7ogegv5iwinxq6snrj3pbsuuodf6m/",
                                  MintConfig(0.003 ether, 50, 50, 0, 0xF5946d0AE1CeE1090028D9b152E1354CD9e7E8fc, false, false, false)) {}
}