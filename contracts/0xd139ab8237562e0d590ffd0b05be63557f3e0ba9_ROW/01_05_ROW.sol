// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rider On The Wheel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    [email protected]@@@@@@@@Wkkhkkkkkk&d%kkkkkkko%kbkk%kMkkkkb&kkkaMkkkkaopB8%[email protected]@[email protected]@@hkkkkkhkkkkkhkhh    //
//    [email protected]@@@[email protected]@@@@@@@@@@@ppdddddddddpW8ddbbdbdb8dddkkkadbbWpq*bb#dbbb%ddbbdMpp%[email protected]@@@*dddddddddddddddddddd%@dbdbdddddddddddddd    //
//    qqqqqqqqqqqqqqqqqpqqqqq&@@@@@@@@@@@@@@@@@@@@@@WqqqqpqpqqqqqWQ8qqqqqWq&qqq8odWpq%qWp#bbqqq#bqqqqqdww8#dhB%%W%@@Mqqqqqqqqqwqqwqqqqqq8qqqqqqqqqqqqqqqqqw    //
//    [email protected]@@@@@@@@@@@@@[email protected]@@@@@Bh&WmmZZZmZmmmZmq*%ZmmZmhmpmw%0W0wm&p%mw#ZmmwMmmmmm%ZZZZMBBmZ&[email protected]    //
//    [email protected]%Bq#[email protected]@000000000OOm*aO0OO0OO0000B080OOoMoW0OO0#[email protected]*OOO0qQOOO0BQ*MoO00*Bd000000Q000000000000O000000000O0O0O0000    //
//    [email protected]@@[email protected]@@%QLLLLLLLLLLLL0&QLLLLLLLLL%[email protected]&L0MBk0BLWOQo&0aLLQLqLLLLL%ZJqLao8LLhLLLLLCLLCLCCLLLLLLLCLCCLLCLLLLLLLLLLCL    //
//    JJJJUUJUJJJJJUJJUJJJJo#@@[email protected]@8UMhJJJJJJJJJJCJJhaJJJJJJCJbJJ%cWJUOLBaUJp&[email protected]&[email protected]@@@@@%UhJJJJJJJUUJJJJJUJJJJJUUUJUJUUJUJJJJJJJ    //
//    XXYYYYYXXYXXYYYYYYYYYkC%@#WaUUUUYwJMBJczzzb*dYYXYYYYYYYYU%OUUUYYUbUYUBUUbM8BU&U&BhCUCQQCwdJY&YYUYU%[email protected]@@@@@WYZYXYXYYYXYYYYYYYYYYXXYYYYYXYXYYYXYYYYY    //
//    [email protected]@@QzcX%cv&8muvnup8zzzzzzzzzzzoWXzzzzdCzz%h*X%#zY&[email protected]@@@@@%czOzzzzzzzzzzzzccczzzcczccczzccczzzzczz    //
//    uuuuuuuvuuuuuuvuuvuuvuJ0#[email protected]@@@@@@vvvbuuuuuuv%[email protected]&zzZzBYdZnvMUXuvMCzWvvzMuuvBuvuuvvuuucazuUuuc0vvvuvvvuuvuuuvuuuuuvuuuuuuuuuvuuuuu    //
//    [email protected]@@@@@@@@@@@@[email protected]%[email protected]@&vzq*zuo%hcnWnun%xxxnnxxnnxxx#%#*[email protected]@@@@@axxxxnxxxxxxnxxxxxxxxxxxxxxxxxx    //
//    [email protected]@@@@@@@@@@@[email protected]&CLZrbvmjJrwY%[email protected]@@@@B%[email protected]    //
//    [email protected]@@@@@@@@@@@@@fftffftfttfttttttttttttp08zttftfW/Cw/&xoj%8uftWxrWhWYWxCjrjfffffff8hQkttfjZBO%Cc*raXfftfftttttfttttttfttttttttttt    //
//    ||/|||||||///||/|//||/|[email protected]@@@@@@@@@Ba&B0t//|/||||///|||/|/||||||qO*t//%[email protected]%%Yb&ww/obb%**zj/ft/f%&p/t/ttmB&tjafjfrQdt/|//|///||//||||/|||/||||||/||    //
//    ((((((((()((((((((((((())vZc|(((M(B()()())(0%#Bor((((()((((((((())fMb%/rc&C%&))*/)(t%ZCd*W%|[email protected]%%%|/YMMn)))))))(&//t%WB|))((((((((()(((((()(((((((((((    //
//    111)11111)11111111111)111111111)%)8r)11111111111111{)xMBB%Y1)))111111)&U1%BoBq1{qt0{[email protected]@Bap#&rbX{11111111111#[email protected]@@@@B8)11111111111111111111111111111    //
//    {}}}{{{{}{{{{{{{{{{{{{{{{{{}{{}{{t)&{{{}{{{{{{}{}}}}{}{{{{}{{}1wBBq|{)1n{8%[email protected]@[email protected]%@k[8/dco1{{{{{{{{{{{}@@@@@@@@@o{{{{}{{{{{{{{{}{{}{}}{{{{{{{{    //
//    [[[[[}[[[[[[[[[[[}}}}}}}}[[[[}}}}B)B[[}}[[[}[}[[[}[[[[[[[[[[[[[[[}}}}}[email protected]@@@B)f%8%8*&%[email protected]@f{qca(}}[[}}[[[}}}@@@@@@@@@&}}}[}[[[[[}[[[[[[[}[}}[}[[[[[    //
//    ]]]]]]]]]]]]]]]]]]]]][email protected]@@@@@@@@8f}O8]]][]]]]]]]]]]]]]]]]]]]]]]]]]}[email protected]@@@@[email protected]@%[email protected]@@&zpBBBB&WaLU1[[[][]]]]]]][1Zp*}}Ba[[[]]]]]]]]]][]]]]]]]]]]]]]]]    //
//    [email protected]@@@@@@@@@@@B[B#0????????]????????????]]](o%[email protected]@@@@@@@[email protected]@%o/CQ<~][email protected][email protected]@B*?W*)nJk8OkBopu[-??????[(8a??]???-??????????????????-???    //
//    [email protected]@@@@@@@@@@&BBB_BB---_------_---_YM8ox<>~YMW%[email protected]@[email protected]%*+&#++_~Wh]+BBjBB*[email protected]&______-_][--]qB8J[[email protected]%X____--___-_--____---_____    //
//    [email protected]+BtjoY~q<%@@@>}x_+~_088Bk}+</#%%Wk/_+~+++++1o%[email protected]@@@[{8BY}0hpk<|#8_n?hk##XBqok&%Z+++++++++++++%@@@@@@@@@B+++++++++++++++++++++++    //
//    ~<~<~~~~<<~~~~<~~~B#@U}>->ia<>[email protected]@B##Bf!_J8%BBo(~<~~<<<~~~~<<<>[email protected]%@&qMW%a%>hio>tL%+UCqk%M1a_QCd?<BrMB~<<<<<<<<[email protected]@@@[email protected]@@@@B~<<<<<~~~<~<<<<<<<~~~n+    //
//    >>>>>>>i>>>>>>>>>>?8>>Zl(ll&!!M%@[email protected]>iiiiiiiii>i>>iii>iii>&a>>Um#[email protected]&8iBWBM8h*a~Lo-)z+lfLL%c&]8zM*fiv!M!-%fi>>[email protected]~{I%ci>i>>i>ii>>>>>i>>>i>>>>>>>>    //
//    !!!!!!!!!!!!!!!!!!!BII#IItlM!IWI;;X&[email protected][email protected]%|*IBp<LoWU/%<?i&8IlOX%twaCb>XhbCq8>I;#Y;IBbiiirBll;Bh!l!!!!!!!!!!l!!!!!!!!!l!!!!    //
//    IIIIIIIIIIII;IIIIIIB;Iw;;%@B8k8:;:;?X>z{;;II;IIIIIIIII;%BlI;;[email protected]@@@Bm~0[*%tbWaL[WxhI>[email protected](qBB&!*B|;:;lB:;;h%?B+voB#&bllIIIIII;II;IIIIIIIIIIIII    //
//    :::::::::::::::::::B!|@@@@@@@@B:::;v:&{8::::::::::::#@b]::,,:M/&[email protected]@@qUBWI%ohYBlMdx#<+i}:LI,Ma#B%#>%>%hzh#*;,:;>JtY;;B;;[email protected]@@@h8(,,:::::::::::::::::::    //
//    """"""""""""""^"""[email protected]@@@@@@@@@@@Bn",,M"n:%,"""""":&B""""""",[email protected]@@1]W8rou(Ow:z#_"naM%@@@@@wfkJ+&@x}8bd""""":&%@@@@@@@@@@Bi"""""""""""""""""""""    //
//    """"""^"^^"^"""^""}@@@@@@@@@@@@%?"""IB"W"Q"^^,#Wl""""""",[email protected]!:<lz&@@@Bq;q?b,&-0]([email protected]@@@@@@B-Mu:[email protected]|m#)8""^^")[email protected]@@@@@@@@@q:""""""^""^""""^""""""    //
//    ^^^^"^"^^"^""^^^^",[email protected]@@@[email protected]@@@@@@I^""")+1,b"WM-""^^^"^":8kB)[email protected]:M"""c,h>@@@@@@;:J,omp8""*@@@@@@@@@@YM+WfUBZ/B8-*"^^^[email protected]@@@@@@@@@,"^"^"""""^"""""""""^""    //
//    ^^""^^"^"^^^"^""^"""<@@@@@@@@@@@a"^"""B"k&p^^^""^^^"[email protected]]@(XB%IM,"",*xp,[email protected]@@@@Wt<(1Bpq%@@@@@@@@@@B)m"J8U&Y][email protected],&f"""B"i;::,|<%""^^""^""""""""^"""^"""    //
//    ^^^^^^""""^"^^^^""""""[email protected]@[email protected]&(""""^^""""@8,/""^^"""l8L"0QwhtB:@:"""Q^~|,Wbd::[email protected]@@@&[?]*@[email protected]@@@@@@@BB*1*:^}B:MObLB,YB""In""""")-B^^^"""""^"""^^^""""^"""    //
//    """^""""^"^^"""^""^^"""^"""""^"^""[email protected]@[email protected]@X"W,^""t*(,Xwmt#I&l]>"^^"8"%!"&Wr"W%,[email protected]@@@w8*[email protected]@@@@@@@B;!0un"";MY%&raa&i8""8"""^":[8""^^^^^^^^^^"""^^""""^"    //
//    ^^^""""^^^"^^""^""^^""^^^^^""^[email protected]@@@@@@@@@@@BW~"Bl""{B}BLlQJ:B"""""%"W:"8!8"MZ""[email protected]@@@@[email protected]@@@@@@@},IW/%""";M,8!k8Wk/h,z""^^^"w8"^^"^^""^^"^""^"^""""""    //
//    "^"^""^^^^^^^^^"^^""""^"^""""[email protected]@@@@@@@@@@@@BtMJ""[email protected],"_x,&"""""hZxl""W,%,&^"*([email protected]@@@@@@@@@@@@@;;l[rW"^^^,M"@,,wk}zY%L"]/--J0""""""^^^""""^"""""""""    //
//    ^^^^""^"^"""""^"""""^"^^"^"""@@@[email protected]@@@BBW<"">^"/Bc{Lz""I;a,d~^"^^"f:@"""%d8~U""p0hd,@@@@@@8%[email protected]@%@@@h#@/;""^^IW"%"""[email protected]@@@@@@:"^^"^"^^"""^"""^""""""    //
//    """""^"""""""^^^^""""^^""^"""i&Y";""u:,O""tWX8Q(c%"""",B";*^"^""@:Z{"""B,OwL^,LYhJ"[email protected]@@@BpWk#mB%%@@@@@W""""";8"&""}[email protected]@@@B*:_"^""""^"""""""^^""""""    //
//    "^"^"""^"""""""^"^"""^^^""""^tn"q"""a""o,"^[email protected]@!"""%,,%"""^^,B^B,^""_,wU""JrvvM"#@@@%/B8Ok#[email protected]@@@@@;""""""*,@,l088%{[email protected]+z,Y""^^"^^^^"^^^"""^^^"^^    //
//    """^""""""^""""""^"""^""^""""tnI["""%""/YBqI&/uB~Bl%:o),M,^""^"B"(t"""W*:%(""[email protected]&>@@@@[email protected]&[email protected]@@@@@@@@BI^^^""u|,@,/B*(tW0-zh",""^""^^^"""^^"""^""^^^    //
//    ^"^""^""^"""""^^^^^""""^^^"^^fW,i"""M""[email protected]@m&/jh"^"(*<%i"&,"[email protected]@@@[email protected]^",%&",8/",d|px*"[email protected]@@@@@@@@@@@@@@@@@@x""""^"Qt:M;%%"oW?8MxBMd"^""""""^"""^"""""^""    //
//    ^""""^"""^"^^""""^""""^^"^"1r}@@@@@@@B""Bt&/J?"^""",k%W%M%@@@@@@@@@@BMB%:8|";rxOh"""@@@@@@@@@@@@@@%,[email protected]@@B"""""""[email protected]@@@@@@0""""""^""""^""^^""""    //
//    "^"""""^^"""""^^"""^"^"^""""[email protected]@@@@@@@@@@@b|%,"""^""Y(*%@@@@@@@@@@@@@@@@@@ak,%jLfB"""[email protected]@@@@@@@@@@@B""^@@@@_"^""^""w%@@@@@@@@@@@@@X"""^"^^"""^^"^^"""""    //
//    ^"^^^^^^""""""^""""^"^"^^"""[email protected]@@@@@@@@@@@@#"""^""<[email protected]@@@@@@@@@@@@@@@@@@@@@WW%twfY""""@@@@@@@@@@@@%""""[email protected]@B""^"""""[email protected]@@@@@@@@@@@@1W,"""""^^^^^""^"""""    //
//    ^"^""^^""""""^"^"""""""^"^^"*@@@@@@@@@@@@@,""""^Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@Wkx|""^""@@@@@@@@@@@"""^""@@@B^"^"^""[email protected]@@@@@@@@@@BWYn%Q"^"^"""""""^"""^"    //
//    ""^"^""^""""^"""""""^""^""""^,[email protected]@@@@@@@BB&"""""%@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@Bz""^""[email protected]@@@@@@@@@""""^"&@@@B""""""[email protected]@@@@@@@@@,"~cvr%,^"""^""^^"""^^"    //
//    ^""^"^^^^"^""^"^^""""""^""^"""^"",,,zn/%"""[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@M,"^"(@@@@@@@@@@J""""""@@@@?""^""O""""l<0qd]+"^":Cux&p"""""""^^^"^""    //
//    ""^"^"^""^"""""^^^"^^"^"^""""^^""""oXxM,,[email protected]@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@BB""""&@@@@@@@@@B|""""",@@@B""""m""""[f"It/|o""^^"lpjn#,"^"""""^"^""    //
//    "^""^^"^^"^"^^"""^""^^^"""""""""""&|j*"[email protected]@@@@@@@@@h<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@:""*@@@@@@@@@@Bq"""""[email protected]@B""""*""""m,"I((awa""""^,kjr&m""""""^"^^^    //
//    "^""^""^""""^^"^^"^""""^"""""^^",B(U#""[email protected],@@@BJ%@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@8%}j%%@@@@@@@@@@#""^"""[email protected]@,^"M"""":&vBB&Bjiv:"^"""^lOfjo,""""^""^^    //
//    """""""""^""""^"^^""""^^"""^""^,#/n8"""[email protected]:&II""",%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@B""^^"""@@@""k,%[email protected]@@@@@@Cqk"""""^""Mu/@M"""""^^"    //
//    ^"^"^""^"""""""^"^""^"^^^"""^":L/u|""^^n#u::*;"""[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@W#@@@@@@@@@@@@W"^""""""@@>[email protected]@@@@@@@@@@WkLmL""^^^"^":O|/%:""""""    //
//    "^""""Yh,MZJ*[email protected]",""""^"""^"bft%!^"^^"""8,,%""wWM"[email protected]@@@@@@:"""%@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@Mq(!"^""[email protected]/&@@@@@[email protected]"^^^^^""""8r/@r"^"""    //
//    """<d*h&@k%a&@[email protected]"""^^^^^"%/tB,"^"^"""&W,:[email protected]"[email protected]@@@@@%""^"[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@%@@@@8WI::-BX8Q(m"^"""""""">Utjo"""^    //
//    ""]lBB#[email protected]@@[email protected]@%ZBf1"x"^^""!bt[8"""""""""[email protected];;#@IW?B"x#@@@@@@""^",[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@M%dbbdbb&#[email protected]@&@@@@@@@@@@%|oZ,YJ}/"""""""""":#f|B~""    //
//    ""|[email protected]@@@@@@@@@%k>,""""Mr|mY"""""""",[email protected]@[email protected]@@@@@%n,[email protected]@B,,,,[email protected]@@@@@@@@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@@@B%ddddd%*dbdbbb&@@@@@@@@@@[email protected]@@@@@@C,,,::;;lCz/kq"    //
//    "Wk:&@[email protected]@@@[email protected]@@@[email protected]&>?d,B/(&:::;:;:;;;>[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@[email protected]@@@@@@@@@@[email protected]@@@@B%[email protected]@@@@@@@@@@@@@@@@@@@@@j!!iii!iktt%    //
//    ,[email protected]@_i)[email protected]@[email protected]@*XhQf{[email protected]@@@@@@@@@@@@iii!!!!ii>[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@&[email protected]@@@@@%bdddbphdddddbd*@@@@@@@@@@@@kd;[email protected]@@@@@q<<~+~+~(aj    //
//    ::]&[email protected]%B:;t;[email protected]/bqiii>>>>>>>>><[email protected]@@@@@@@@@@B<<<<~~<[email protected]@@@@@@@@@@@@@%@@@@@@@@@@*[email protected]@@@@@[email protected]@@@@@@@@@@@@8%@B%@@@@@@%________o    //
//    l:#B%[email protected],::[email protected])[email protected]@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@bbdhtdd&@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@[email protected]&aX)]    //
//    [email protected](Moo|Yo+bhiBBpXcf%_-------------???????-?????][)[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@mdddd&%[email protected]@@@@@@@@qbddbdddb%[email protected]@@@@@@@@@@@@[email protected]@@@@hhhhhhaa    //
//    ?]]]fa##Z}hM-{bb-Udtm8?????]?]]??]]]][}fk%BB%88%8#[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@*aoaaaaa    //
//    ??]]??}]]]][j][[d#-%r]]][}ZMBBB%B888ohhhhhhhhhhhahhahhaaaaaaa#%@@@@@@@@@@@@@@@@@@@@@@@@oddbbbjWbdbbd&%@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@Bo%ooaoo    //
//    ][[]]]]][]]]]]u%[email protected]&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@dQbbbb0#kk#[email protected]@@@@[email protected]@@@@@@@@@@@@@@oooooo*[email protected]@@@@*oooooo    //
//    }{jpB%B%B%%Wah%-+%[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@@@@@@@@@@@@@Bo*o**oo*[email protected]@@@@B*oo*o*    //
//    hhhhhaaa8hhhk%ik%%haaaaaooooooooooooooooooooooooooooooooooooooo&@@@@@@@@@@@@@@@@@@@@@@@@@@mw#kkkMkahhkY#%[email protected]@@@@@[email protected]@@@@@@@@@@@@oo******[email protected]@@@@@&*o*o**    //
//    @@@*aaaab%@&W][email protected]@@@@@@ooooooooooooooooooo*ooo*o*oo**oo*oo***oo**@@@@@@@@@@@@@@@@@@@@@@@@WO%ZdkLkkhhOdh#B8JYC%@@#B*#@@@@@@@@@@@@**#*#***[email protected]@@@@BM*#****    //
//    @@@@@@@W%%[email protected]@@@@@@o*ooooo*o**o**o*o**o*oo****o*************[email protected]@@@@@@@@@@@@@@@@@@@@B#[email protected]@@@&8#&[email protected]@@@@@@@@@***#**##@@@@@@@B######    //
//    @@@@@@@@@@Y[%B88888%%[email protected]@@%****************************************#@@@@@@@@@@@@@@@@@@@@BW0&n&%&@mqoL&@@Wj#W#[email protected]@@@@@@@@@@%#*####[email protected]@@@@@@W######    //
//    @@@@@@@@@@@%8WMWMWW&&8%@@@B********#8&*##8***####*##**##***#####*###@@@@@@@@@@@@@@@@@@@8Bw1Lm%@%Q0fnbBBB#M#%@&@@[email protected]@@@@@@@@@#####[email protected]@@@@@@M######    //
//    @@@@@@[email protected]@@@@8MMMMM##MW&[email protected]@M#W*#o*###*####*#####*##*##*#############[email protected]@@@@@@@@@@@@@@@@@W###[email protected]@B#M&[email protected]@@@&&&&%M#@@@@@@@@@@#M##@@@@@@[email protected]%M###MMM    //
//    @@@@@@[email protected]@@@@@@*######MW&%@@B**##################################M###[email protected]@@@@@@@@@@@@@@@@@###MM##MMMMM#[email protected]@@@@@@@MM##@@@@@@@@@[email protected]@@@@@MMMMMM#M    //
//    @@@@@@B%[email protected]@@@@B###*##[email protected]@########M##############MM#M##M##M###MMM#[email protected]@@@@@@@[email protected]@@@@@@@#M#MM#M#[email protected]@@@@@@@MMMM%@@@@@@@@[email protected]@@@@MMMMMMMMM    //
//    @@@@@@888%[email protected]@@@&MMMMM#&%BBB%WMM##M#MM#M##M##M#MMM##MMMMMMM#MMMMMMMM##%@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@[email protected]@@@@%WMMMMMM    //
//    @@@@@@&8W8%[email protected]@@@@[email protected]@@@@@@@@@@@@BB#MMMMMMMMMMMMMMMMMMMMMMMMMM%%8%[email protected]%@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@&[email protected]@@@@@@MWWWWW    //
//    @@@@@@W&MW&%[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@oMMB%BMMMMMMMMMMMMMMMMMMM8%[email protected]@@@@@[email protected]@@@@@@[email protected]@@@@@@@[email protected]@@@@@@[email protected]@@@@@@WWWWWW    //
//    @@@@@@WWW#W&%[email protected]@@@@@@@@@@@@@@@@@@@@@@@*WWWWMWWMMMWMMMWMMWWMMWWMMMWWWWWMM%@@@@@[email protected]@@@@@@[email protected]@@@@@@[email protected]@@@@[email protected]@@@@@@WWWWW    //
//    @@@@@@WWM##W8%@@@@@@BBBB%%%%[email protected]@@@@@@oWWWWWMhW%o#[email protected]@@@@[email protected]@@@@@[email protected]@@@@[email protected]@@@@[email protected]@@@@@@W&&&    //
//    @@@@@@BWW##M&@@@@@BB%%%%%88888%%%[email protected]@@@@@[email protected]@@@@@@@@BoWWWWWWWW&[email protected]@@@@@[email protected]@@@@@WWWWWWWWWWWWWWWWWWWWWW&@@@@@@WWWWWWWWW&[email protected]@@@@W&WWW&@&@@@@@@&&&    //
//    @@@@@@@[email protected]@@@@B%888&&&&&&&&888%[email protected]@@@@%[email protected]@@@[email protected]@@@BWWWWW&%@%WWWWWWWW%@@@@@@W&@@@@@@@&W&[email protected]@&WWWWWWWWWW&W&@@@@@@WWW&&W&&&WW&@@@@8&&&&&&&[email protected]@@@@@&8&    //
//    @@@@@@@@WMM&@[email protected]@%%8&&WWMM%#WW&&&88%[email protected]@@@@@@@B88&&&8%[email protected]@%[email protected]@@@@@&W&@@@@@W&&WW&@@@@%&BWW&&&&&&&@@@@@&WW&&&&&&W&&&@@@@&&&&&&'''ll]]jjj00    //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ROW is ERC721Creator {
    constructor() ERC721Creator("Rider On The Wheel", "ROW") {}
}