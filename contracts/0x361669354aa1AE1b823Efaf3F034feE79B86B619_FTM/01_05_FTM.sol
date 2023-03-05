// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fuck This Meta
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    [email protected]%[email protected]%%%BBB%BBBBBB&[email protected]%BBB%BBBBBBBBBBBBBBBBBBBBBBBB%BBBBBBBBBBBBBBBBBB%%%BBBB%BBBBBBBBBB%%BBBBBBBBBBBBBBB%%BBB%BBBBBBB%%%%BBB%B    //
//    %8888888%88888%888%%8%%%888%%8%%%%8%%8%%%%8%%%%8%%88%%%888%888%%88%%%%%%%88%888%%88%%%8%%%%8%%%%%%%888%%8%%%88%%888888888%8888888888888888888&88888%%    //
//    @[email protected]%BBBB8BBBBBBB%%BBBB%BBB%BBB%BB%%BBBB8BBBBB%%%%BB%BBBB&BBBB8BB%BBBB%8BBBBBBBBB%BB%BB%%8BBBBBBBBBBB%BBBBBBBBBB%%BBBBBB%B%BBBBBBBB%BBB%BBB%%BB%BBB    //
//    [email protected]%BBBBBBBB%[email protected]%BBBBBBBBBBBBBBBBB%[email protected]@BBBBBBBBBBBB    //
//    B%BBBB8BBBB8BBBBBBBB%BBBB%BBBBBBB%%%%%BBBBBBBBBB%[email protected]%BBBBBBB%BBBBB%BBBBBB8BBBBBB%BBBBBB%%BB%[email protected]%BBBBBBBBBBBBB%BBBBBBBB%%%BBBBBB%BBBBB%B%%BB%B%BBB    //
//    [email protected]@[email protected]%[email protected]@[email protected]%BBBBBBBBBBBBB%BBBBBBBBBBBBBBBBBBBBB    //
//    8888%888888&888&888888888888%8888888%8888%888%8888888%8888888888888888888888%8888%88%8%%%%88%8888888888888888888&8888888888888888888&8888888888888888    //
//    BB%BBB%BBBB8%BB%%BBB%BBBBBBBBBBBBBBBB%BBBBBBBB8B%BBBBBBBBBB8B%B%&BBB%%BBB8BBB8BBBB%%8888%%%%BBB%BBBBBBB%B%BB%BBBBBBBB%B%BB%BBBBB%%B%%%BBBBB%BB%BB%BBB    //
//    %%%BBBBBBBB&BBBBBBBB%BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB8BBBBBBBBBBBB%BBBBwf?/-?)][email protected]@BBBBBBBBBBBBBBBBBBBBBBBBB%BBBBBB    //
//    B%BBBB8BBBB8BBB%%B%%8BBB%BBBBBBBBB%BB%%BB%%%%BBBBBBBBBBB%%B8BBBB8BBBBBBBBBBBBBBBB%-][_~-[uw}BBBBBBBBBB%BB%%%8%%BB%BBBBBBBB%B%BB%BBB%B%%B%BBBB%%BBBB%B    //
//    BBBBBB%BBBBBBBBBBBBB%BBBBBBBB%BBB8BBB%BBBBBBBBBBBBBBBBB%BBBBB%%BBBBBBBBBBBBBBB8B%8[_-[jrQo8(BBB%BBB%BBBBB8BBBBBBBBB%B%BBBB%BBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    8888%8&8%%8&88888%%%8%%%888%88%%%8%%%%%%%%8%8%%8%%%%%%%%8%%%8888888%8888%88%%%#81r+XfYvZ#&%X%BB%888%8%%8888%888888888%%88888888888%88888888888888%8%B    //
//    BBBBBB%%[email protected]%BBBB%BBBBBB%%BBBBBBBBBBBBBBBBBBBBB%BBB%BBBB8BBBBBBBB8BBBB#&])>)1UvQM&BXBBB%B%BBBBBBBBBBBBBBBBBBBBBBBB%%BBBBBBB%%%BBB%BBBBBBBBBBB    //
//    BBBBBBBBBBB&BBBB%BBBBB%BB8BBBBBBB%[email protected]%[email protected]@BBBBB%BBBB#8|}~_?cjJ&&%[email protected]@@@BBBBBBBBBBBBBBBBBB    //
//    BBBBBB%BBBBWBBB%BBB%%BBBB%BBBB%%%%%%BBBBBB%BBB%BBBBBB%%%BBBBB%BBBBBBBBBBBBBBBBW%n1]L/Ljp&8&aBBBBBBB%B%BB%BBB%BBBBBBBBB%%BBBBBBBBBBB%BBB%B%BBB%BBB%%BB    //
//    BBBBBBBBBBBBBBBBBBBBB%BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB8BBBBBBBBBBBBB*8//iunJ1L&88bBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%B%BBBBB%BBBBBBBBBBBBBBB    //
//    888888&8888&8888888888888888888%888888888888%%%%%%%%%88888%88888888888888&888%M8}|_(tXrZ&&%b%%%88888&888888888888888888888&8888&888888888888888888888    //
//    [email protected]%BBBB8BBB%%B%B%BBBBBBBBBBB%BBBB%BBBB8%%BBBBBBB%B%%%BB%%%%%8%%B%BBBB8BBBBM&][~](x}c88%bBBB8BBBBBBBBB%BBBBBBB%BBB%BBBB%%BB%B%BBBBBBBBBBBBBBBBBBBB    //
//    BBBBBB%BBBB%BBBB%BBB%BBBB%BBBBBBBBBBB%BBBBBBBBBBBBBBBBBBBBBBBBBB%BBBB%BBBBBBBB*8{}+t(zxOW&%b%BB%BBBBBBBBBBBB%BBBB%[email protected]@BBBBBBBBBBBB%[email protected]    //
//    BBBBBBBBBBB%BBB8%B%%%BBBBB%B%WBBBBBB%8BBBB8BBBBBBBB%BB%%BBBBBBBB8%BB%B%B%BBBBBW8]f~YtYumW&%kBBBBBBB8BBB%BBB%WBBB%%BBB%BBBB8BBBBBBBB%BBBBB%BBBBBBB%[email protected]    //
//    BBBBBBBBBBB%[email protected]@BBBBBBBBBBBBBB%B%BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%B%BBB%%B8BBBB#8{X]r(YrJ&%BoBBB%BBBBBBBB%BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%BBBBBB    //
//    BBBBBBWBBB%&BBB%%BBB8BBBB%BBBBBBBBBBBBBBBB%BBBBBBBB%B%%%BBB%BBBBBBBB%%B%BBBBB%M81t<Xt0zc88%hBBB%BBBB%BB%%%BBBBBBB%%BB%BBB%%BBBBBB%B%%BBB%%%BB%8BB%B%B    //
//    BBBBB%8BBBBB%BBBBBBBBBBBBBBBBBBBBBBB%8%BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%*&}[+nxY{Y88%pBB%%BBBBBBBBBBBB8BBBB%%BBBBBBB%BBBBBBBBBBBB%[email protected]%BB%BBB    //
//    BB%BB%%BBBBWBB%&&BB8&BBBB8%%BBBBBBBBBBBBBBBBBB%BBBB%%%%B%%B%B8BB&BBBBBBBB%BBBB*&?[<(/f|C888b%BB%B%%%BBBB%8B%8%BB%8%B%8B%B%8BBBB8B%%%B%B%8%BBB%%%%8%%%    //
//    BBBBBBBBBBBBBBBBBB%88BBBB%BBBBBBBBBBBBBBBBBBBBBBBBB%BB%%BBBBBBBB8B%BBBB%%%BBB%M%xx]mfpjz&8%h%%%8BBBBBBBBBBBBBBBBBBBBBBBBBB%BBBBBBBBBBBBBBBBBB%BBBBBBB    //
//    %[email protected]%BBBB%BBBB%%%BBBBBBBB%BBBBBBBBBBBBB*8{)_ntunO88%kBBB%BBBBBBB%%BBB8B%%%%BBBB%BBBBBBBBBBBB%8BBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBB%BBBBBBBB%BBBB8BBBBBBBBBBBBBBBB8BB%%B8BB%B%BBBBB&B%%%%BBBB%%BBBBBBB*W[[<-}n)q88%b%BB%B%B%%BBBBBBBBBB%%8BBB%%BBB%BBBB%B8B%BBBBBBBBBBBBBBB%B    //
//    %88%%%%%%%%8%%%%%%%%%%%%%8%%%%%%%%%%%8%%%%8%%%%BBB%%%%%%%%%%%%%%8%%%8%%%%%%%%B#&]]</}U|J8&%d%BB%%%%%8%%%%%%%%%%%%8%%%88%%%%%%%%%8%%%%%%%%8%%%%8%88%%%    //
//    BB%BBB8BBB%8BBB%%BB%%BBBB8B%%B%%%%%BB8%B%B8BBB%BBB%%BBBB%%%8B%%%%BBBBB%BBBB8BB*&[?+[}JtU88%p%BBBBB%B%%B%%%B%%BB%B%BBB%%BBB8%%BB%B%B%B%BBB%BBBB%BB%B%B    //
//    BBBBBBBBBBB&%B%B%B%B8%B8B8BBBBBBBBBBBBBBBBBBBBBBBBB%%%BBBBBBBBBBBBBBBBB8BB%%BB#%Y/{n(Yvq&%%h%%%%BBBBBBBBBB%BBB%%%BBBB%%%B%%BBBBBBBBBBBBBBBBBBB%BBBB%B    //
//    BBBBBB&[email protected]@B8BBB%BBBB8BBBBBBBB%BB%BBBBBBBBBBB%B%BBBBB%8BBBB%BBBBB&%BBB%%%BBB%B%*&|j-)tm)q&&%h%B%%%%B%BBBBBB%BBBBBB%BBB%BBBB8%%%%%BBBBBBBB8B%B%%%BBBBBB    //
//    BBBBBB%BBBB%@BBBBBBB%BBBB%B%B%BBBBB%BBBBBB%BBBBBBBB%BBBBBBB%%BB%%BBBBBBB%BBBB%*&[?-|{n|O&&%h%B%%BBBBBBBBBBBB%%BBBBBBBBBBBB%BBBBBBBBB%[email protected]%%    //
//    %%%%%%%%%%%%%%%%%%%%%%%%%%BBBBBBBBBBBBBBBB%BBBBBBBBBBBBBBB%8B%%%B%%%8&&88888%%M&]?<|-v/C&8%qM&&&8888&8%B%BBB%%%%%8%%%%%%%%%B%%%%%%%%%%%%%%%%%%%BBBBB%    //
//    B8%BBB8BBB%&BBB%BBBB8%%%%&8BBBBBBBBBB8%BB%8%B%8BBB%B%%%%%B%%%%%%B%%81]r)f(jx]&M&/n>v[r/Y&8%j|)f|1ft{{-{XBBBB&BBBB%%BB%BBBB8BB%B%B%B%B%BB8BBBBBBBBBBBB    //
//    BB%%%%8%%%%%%BB%%%%B%%%%BBBB%&BBBBBBBBBBBBB%%BBBB%BB%BU]+-~~~~]?hM<-~]_-+{>?U{L&[j{Q1t_~]f&~1}?-|v+}-_(]%%BBBBBBBBBBB%%B%B%BBBBBBBBBBBBB%[email protected]%B    //
//    BBBBBB%%%%%WBBB%BBBB%BBBB8%%%%%%%BBB%BBBBB%%%%BBBBB%#w+-~__+_]C-CM<<+~-~>-_~b/p&?]~f1r_]~u8<-})})c(/)(zL*+OBBBB%%8&BBBBBBB&B%B%B%BB%BBBB%BBB%8%B%%%8%    //
//    %%%BBBBBBB%%%%%%BBBB%%%%%&BBB%BB%BBBBBBBBBB%%%BB%%%%?1>[~+i~[}k(xMi]?i<i<[j|w|bM_t>)?f_utU8~nJJULwOwLqwmMjo<-%BBBBBBBBBBBB%BBBBB%BBBBBBBBBBBBBBBBBBBB    //
//    BBBBBB8BBBB8B%B%%%%%8%%%%%%%%%%%%%%%%8%%%B%%JzXzzm%8[(?{<x}1rro1xo-)}[/-|fU/MrqM-t?u(f{fjU%nuQJUC#0LkWkhMrW}/%%B%8%%B%%BB%%%%%%%%%%%%%%%8%%%%&8%%88%%    //
//    BBBBBBBBBBBBBBBBBB%B&BBBBBBBB8%B%BBBB%%%B%Jturux|LCW)v_|]t1juf*rCM{nujf[ffqZ&zoW)r}uUOfcuX%zLQOLJ0OQLCJU0z&cX%BBB%BBBBBBBB%BBBB%BBBBBB%B%[email protected]    //
//    %%8%%%888%%&%%%%%%%%8%%%B8BBBBBBBBBBBBBB%oL(?//X~nc8-v1x?/-xntoJX#]uf?/}t10a8vmWXuv#W&W&8%%B%B%%%%%BBB%%%B%CJ%%%B%%%BBBB%%%%%%%%%%%%%%%%8%%%%8%%%%%BB    //
//    [email protected]@BB8BBBBBBBB%BBBB&BBBBBBBBB%%%BB#?_~!}]t|d#&}[_]~]?jY*Wz0q??}]?-tzJa&o%MYw88%%8%%BB%%%BB%%BBBBB%%%8qaB%%B%BBBBBBBB8BBBB%BBBBB%%B%[email protected]%BB    //
//    BBBBBB%BBB%8BB%%%BBB%BBBBBBBB%BB%BBBB%%%#<1+1frJ|oW&+({x<j]cJh8Mao<<+~1{{fQ*&#%B%%%%j<<>>><>ii>><<>>>>>-%%%k#B%BBB%BBBBBBB%BBBB%%%BBBBBBBBBBBB%B%BBBB    //
//    BBBBBB8BBBBBBBBBBBBB8BBBBBBBBBBBB%B%%B8hv[n(njrwjo#8?u(Y_/{XCo&W8M+r)(tY//p#8W%%%%v??]>>--}><+-_+[>+}/)(%%%%BBBBB%BBBBBBBB&%BBB%%%%B%BBBBBBBBB%BBBBBB    //
//    %%%%%%M%%%%%BB%%BBBBBBBBB%B%BBBBBBBBBB8k}YxvUzfkC*M%|X}Y-tcumW%&8&fn)CQwQmaW8&%%8%nw(|ut{{}{?}+[?X})C&vtM[C8%%BB%%%%%%BB%%%%BBBB%8BBBBBB8%%%%%%8BBBBB    //
//    B%BBBBWBBBBBBBBBBBB%8BBBB%B%B8BBBBBB%&8Q~t)zcXUmJMW8~x?j+rLYQk%&8&<f+nXqLQ*W%8%&_)]1[njUQJ0jn)ncLO/uoWmLWn%}L1%%%%BBBB%%%B%BBBB8BBB8%BBB&%%BBB8BB%B%B    //
//    [email protected]@@[email protected]@[email protected]%BBBBBBBB8L+{}|t(Lu&%%%~z?0+J{fLZ&%%&+z{0|zW&%8%%%%nm<v1nO0bO*OZdbkba*bM*W#%W8nm{t1W%[email protected]    //
//    [email protected]@BBB%BBBBW%BB%BBBB8%%B%%BBB8B%%8BBBB8O?x1tffzf88%8(r?/?jvzXq88%&?uttxwOaW&%%%8LY}xcQwahbh*#*k*Woom&8888&&#WWYc|jBBB%%BBB%BBBB%%%B%BBBB%BBBB%BBBBBBB    //
//    %%%%%%W%%%%8%%%%%%%%&%%%B%BBB%B%%%%%%%&L+((r1XCx8%%%J0{J+nrCmM%%%8}J|ncQoM8%B%%%dhwkooWdpk&aM*aqdWwkWW88Mqo%%8paJn%BBBBBBB%%%%%%%%B%%%%%%8%%%%%%%%%%%    //
//    B%BBBB%BBBB8BBB%%%BB8BBBB8BB%%BB%%B%B%&C<[{)[j0x&%%%%MfUQZZooW%%%&jruYJZ&W%%%BB%%%B%8%nuunptx|n/c%#M&kpa%%%B%B8%OO%B%%%BBB%BBBB%%%%%B%BB%BBBBB%BB%BBB    //
//    BB%BBBBBBBB%BBBBBBBBB%%%B%B%B8BBBBBBBB&L~}/tzu0v8%%BB%w/nunxnn%%%%%*xccfM*BBBBBBBBB%%BBBBBBBBBBBBBBBBBBB%%%phM%%wwBBB%%BBB8%BBB%%%B%BBBBBB%BBBBBBBBBB    //
//    B%BBBB%BBBB8BBB%8%%B%BBBBBBB%B%BBB%%BB&0}}+<v|1/[Yj8%B%B%%%BBB%%%%%%B%B%%%BBB88BBBBBBB%%%%8BBBBBBB%8%%%%8J*W&8%%ohBBB%BBBB%BBBB%BB%%%%%%%BBBB%%%B%BBB    //
//    BBBBBBBBBBB%BBBBBBBB%BBBBBBBB%BB%%%%BBWQ+{[j}((cnWMBBBBBBBBBB%BB%B%B%BBBB%BBBBBBBBBBB%%BBBBBB8B%%BB%%B%%%a8%%%%%M*BBB%BBBBBBBBBBBBBBBBBBBBBBB%%BBBBBB    //
//    %%8%%%W%%%%8%%%8%%%%8%%%%BBBB8BBBB%BB%&Q+?~-)/Zha8%%%%BBBBBBB%%BBBB%%B%%%B%BBBB%BB%%%%%BBBBB%BBBBBBB%%%%%%BB%BBB#hBBB%%%%%%%%%%8%%%%8%%%%88%%8%%%%8%%    //
//    B8BBBB8BBBB&BBBBBBBB&BBBBBBBBBBBBBBBB%8L<-]jt|f*w8%%%%BBBBBBBBBBBBBBBBBBBBBBBB%%ObQ[}}{}[}[}*%%%BBBBBBB%BBBBWBB%a#BBB%BBBB%BBBB%BBBBB%BBBB%%BBBBBBB%B    //
//    BBB%%B%BBBB8BB%BBBBBBBB%B%%BBBBBB%BB%B8Q+?<]_tUCJcx&%%BBBBBBBBBBBBBBBBBBBBB%%c)~~_~~~+~+__~~+~++++++++~-%%B%BBBB8%BBB%%[email protected]@BBBBBBB    //
//    B%[email protected]%BBBB%BBBB%BBB%BBB%BB%B8d/t{1/1(||[[((|)1)%%%%%%&vnrnzW%%B%qi<i!~!!<-~<+~__?+++++><<>>_~1&#888&d8BBBBBB%BBB%%B%%%BBB%%BBB%BBBB8B%%%%BB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%%BBBBBB%8%tjjxXc|un1z?fu+v1W%%%%%8Ldnuwbh1/|Cftf[||Xxv/fxvrfr)r//|ff)||v&#&dqMBBBBBBBBBBBB%BBBBBBBBBBBBB%B%BBB%BBBBBB    //
//    %88%%%8%%%%&%%%%8%%%%%%%B%%%%8%%%%%%BBBBWz-{(}[|}[-)}~})+(+czU8%%Mfv/}nnx{(1/-(juYQOmmpqpwbmwmppdpOZmdZw&pM%%%%%%%%%%%%%%%%%%%%8%%%%88%8%8%%%%%%%%%%%    //
//    B%BBBB8BBBB&[email protected]%%BB%&BB%BBBB%&BB%BBBBBB%M(Qtuxttf(x-x(nU}z{fnUpkkd)c/_c1xjjru1cLOZm#WWWMWW&W###MMMMkMM#MWW8BBBB%%8%BB%%BBB8%8BB%8BBBBBBBBBBB%&BBB%BBB    //
//    BB%%%%8B%BB%BBBB%BBBBBBBB%BBBBBBBBBBBBB%WYoZmpwkqZ0ZzcZZxUOYuCJ]?uj(X_z{vQCChLoo*hMW%MM&W*W#MMMMMWWM&8&888BBBBBBBBBBBB%[email protected]%BBB    //
//    BBBBBB%BBBB%BBBBBBBBBBBBBBBBBBBBBBBBBBB%%pbdbho#do#bqZhhhooLcQ0xuOc0X+C(OUaMo&&&&M&*WMWoWMW8WWM&88WW&&WWBBBBBBBBB%BBBBBBBB%BBB%%BBB%%BBBBBBBBBBBBBB%B    //
//    [email protected]qu/j/xCQJ0hZapo*bwObpQadhh&#8Ohmd&oo&#&MBBB%%BBBBBBBBBBBBB%BBBBBBBBBBBBBBBBBBB%BBBB%B    //
//    %%8%%%&%%%%&%%%88888%8%%%8%%%%%%%%%%%%%%%%%8%wOYQQ#ZQUbkd*kpCQ##O<{j)zU0dpohMCqQpha&hwZZaa8XmLOmZWpo8%%%%8%%%8%%%88%%888%%%%%%888%888%88%8%%8%8%%%8%%    //
//    B%%BBB&BBB%8BBB%%BBB8BBB%%BBB%BB%BBBB%BBBB%B%%%/XzOnnOvJYUp0OoM]?])fuzYUok*xcjwp#khoMaWbbdadWWWMa%BBBBB%B%BBBBBB%%%BB%B8%B8%BBB%8BB%%8BBB%%%B%%BB%%8B    //
//    BBBBBB%%%BBBBBBBBBBBBBBBB%BBBBBBB%BBB%BBBB%BBB%/x/rj-1((jaoao++?/XLYqQhb*xuYcYQC0ZphYqddbb0bak8%BBBBBBBBB%BBBBBBBB%BB%BBBB8BBBBBBBBBBBBBBB%BBB%BBB%BB    //
//    BBBBBB&BBBB&BBBBBBBB%BBBB%BBBBBBBBBBB%B%BBBB%B%ftuCLfjrzrh#t!i[rCX&XczqbM0JCkq*Od#hurtJpqmahBBBB%B%%BBBB%%%B&%%BB%BBB%BBBB8BBBBBBBBBB%%%BBBBBBBBBBBBB    //
//    [email protected]@BBBBBBBBBB%BBBB%BBBBBBB%%BBBBB%BBBBBB%BBB%jmph#dk*WJLOUtY0Ok##*WhdahhMWMW#*&h*#M##*M*odBB%%BBBBBBBBB%BBBBBBB%BBBBBBBBBBBBB%BBBBBBBBBBBBBBBBBBBB%    //
//    %88%%%W%%%%88%%88%%%88%%%8%%%%%%%%%%%%%%%%8%%BBCk*#O0Qpwtnf(nUwk*qW*8Zkdoq#M8a##*WM#WoW#%%B%%%%8%%%%%8%888%%8888%%8%%%%%%%8%%%%8%%%88%%%%%8%%88%%%8%%    //
//    BBBBBB8BBBB8BBBBBBBB%BBBB%BBBBBBBBBBB%BBBB8B%%BJh*oLYUxntJOwwpkaWMWW%qo#o*M&8*M##&WW88&M%%%%BBB8BBBBBBB%%%BB8BBBB%8%B%BBBB8%%BB%%BB%%BBBB%BBBB%BB%%8B    //
//    BBBBBBBBBBB%BBBBBBBB%BBBBBBBBBBBBBBBBBBBBBBBBB%qdmkqwXOCwbha#M*#W##W8Mb**hM&8*Mok#o&8888%BB%BBBBBBBBBBBBBBBB8BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%BB%BBB    //
//    [email protected]@[email protected]@@[email protected]@BBBBB%BBBBBBBB%rd0oJ#mb*hkkwMkkk*bw*abo*qWbaWa#hd#*W#b%BBBBBBBBBBBBBBBBBBBBB%BBBB%BBBBBBBB%%BBBBBBBBBBBBBBBBBB%BB%BBB    //
//    BBBBBBBBBBB%BBBBBBBB%BBBBBBBB%BBBBBBBBB%BBBBBBBzJXqvY0JcULc0zmuvULkb*paakh*aa*akho*o8BBBBB%%BBBBBBBBBBBB%%BBBBBBBBBBBBBBBBBB%BBB%%BBBBBBBBBBBBBBBBBBB    //
//    %88%%%&%%%%8%%%%8%%%&%%%%8%%%8%%%%%%%8%%%%%%%%%%%%%%8%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%8%%%8%%%%%%%%8%%%8%%%88%%%%88%%%%8%%%%%88%%%%%%8%%88%%%%8%    //
//    B%%BBB8BBBB&BBB%BBBB8BBBB8%B%BBBB&BBB%BBBBBBBB%B%B%BBB%%%%BBBBB%%%BB%%BBBBBBB8BBBBB%BB8BBBB%BBB%BBB8%BB%%%BB8BBBB8%%BBBBBB8BBBB%%BB%%%%BBBBBB%%BB%BBB    //
//    BBBBBB%[email protected]BBBBBBBBBBB%BBBBBBBBBBBB%BBB%BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%B    //
//    BBBBBB%[email protected]@[email protected]%BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%%BBBBBBBBBBBBBBBBBBBB    //
//    BBBBBB8BBBB%BBBBBBBB%BBBBBBBBBBB%BBBBBBBBBBBBBBBBBBBBBBB%BB%BBBB8BBBBBBBB%BBBBBBBBBBBB8BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB%[email protected]    //
//    %88%%%&%%%%&%%%88%%88%%%%%BBBBBB%%%%%8%%%%8%%%%%%%%%%%%%%%%&%%%B8%%%%%%%%8%%%%%%%%%%%%%%%%%8%%%%%%%%%%%%%%%%8%%%%%%%%88%%%8%%%%88888%8%%%88%%%%%%%%%%    //
//    B%BBBB%BBBBWBBB%%BB%8%%B%BBB%8BBBBBBBBBBBB%BBB%B%B%BBBBB%BB%BBBB%B%%%%BBB&B%BWBBB%B%BBB%%B%%BBB8BBBBBBB%BB%B8%BBBBBBB%BBBB%%%BB%%%B%BBBBBBBBB%%BB%B8B    //
//    BBBBBB&BBBB8BBBBBBBBBBBBBBBBBBBB%BBBBBBBBB8BBBBBBBBBBBBBBBBBBBBB%[email protected]%[email protected]@@[email protected]%BBBBBBBBBBBB%BBBBBBB    //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FTM is ERC721Creator {
    constructor() ERC721Creator("Fuck This Meta", "FTM") {}
}