// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Challe PFP from ESCA-NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                  ....J&gQQQkkQQma+J....                                                       //
//                                           ...gWYY"7<-_<~~` ``````` _?7"UHm+..                                                 //
//                                     ..(JXB"=` .-+<<<<<<<<<<<<<<<<<<<<<<<<;<OTWHaJ<<>;<_-...                                   //
//                                  .(+XY"!  .Jz1?>?<<<?!!~~~~~~!??<<<>>>?<!_._-.??TWHaz====1++<.                                //
//        `  `  `  `  `  `  `  `  .+WY^  ..z1<<!~-..(&&&eAAAAWWHHHHHHmg.._.+!((._1i._<7WHez===l=1<_.   `  `  `  `  `  `  `       //
//                              .WY^   .zv!_.(&&wVfVVVVfffVffffffVVVVVfVWH|1l.?7Wk-_Wo???7Wmx=====1<_                            //
//                           ..#=    .v!.(&yXfffffVVVVffffffffVffffffVfffWH,z:CWaJ?W,Ho??>??WHs=====z<                           //
//                         .(#^       (uwuXVffffVVVVVVVVffffffVfffffVVffffWh,1z-?TWWm,H|<????zWHx====z<.                   `     //
//         `    `    `    .#^         wuuXffVfffVWUWWWkWWWfffVVfffffVVVVWY!.(i.?<l<..mY~.-.?<???Wkz===1;.   `    `    `          //
//                      .H=          .ZuXfXVT1<<<<<<<<<<<177YUHHkkWffVX!.;<~.,?1z-.?!.(<(,?1i.?<?dHs===1;.                       //
//                    .Jf`          .w7?!?<::~:(<::~:~~~~~~<<::<<(7YWHm.<_jZXHHh.?1z.<<,WMMa.?1i.??Hkl==1<-                      //
//                   .W=           .=     .:~~(~~~.~~~~~~~~~_<_~~~<_~~X;1l,ZZZZZWHL(z.<<,yVWHm,jm,<+WNz===<-              `      //
//          `  `  ` .H'  .J!.....zI~     .<~~(~~~.~~.~~~.~~.~~<_~~~<<~(G.ll(WkXZZXHc1z.1+(VyVWHr4H,<?WHz===<_    `  `  `         //
//                 .#`  .v!.juXC!`.<~..(<<~.(<~~.~~.~.~.~.~-(((+JJJ++ggdL(l-?uXpWZUm,11.z1,74yWHLCH,<?WN====<_                   //
//                .#`  ,:.WSXXY!` ``~~~~~~~(<~~.-(JJ&dVYY"77<!_.~_..~.~_wi?1lW+/7X0=.xv(&/<lz-?"(Hf(_>1WRv<<<<~                  //
//               .H!  ,[email protected]!`. ` ..~.~~((+gVY"=<..~..~.~..~..~.~_.~.._~?Ow-?4ggm.g#=.fWHHa,?1lZ3,^,??Jm/((-u(<                 //
//        `     .m^  (z.4mW=` ___-~((JdY"7(>..~.~..~.~..~.~..~..~.~_.~...~.~?7X+(""=.ffffWbHHMNJJP.?>?><jHlll>P--..              //
//           `  dP  ,z?!.Y`` ~(++VY=~.~..._~~..~..~..~.~..~.~._..~.~.~.~..~..._<?<?HffpffbkbkbkkH](+>??>1H2;</.(z<-i.   `  `     //
//             .H` .z<~J^`..dYT>...~..~.~._~.~..~.~.~..~...~..(~..~.~.~.~..~..~__..?HffffbkkkkbbH].lz>??<qK<<-_,lz/,!            //
//             d] .v<.X+d9^ ..+_.~...~...~:...~..~...~..~..~..(<...~__...~..~...~...vWpXYC1HHHHHH].1<~(..(Hzl/l_<<?_.            //
//            .m` J?_"^.1:`-.(:`~.~..~..~.:..~..~..~..~..~..~.~1-.~.`_<_..~..__..~.~.<C+wrrrrrrdHh._J8XzUHmC<(^!((-i(.           //
//           .JK .?!-.<`(_`._<`` ..~..~...:~..~...~..~..~..~...(>`````_1-`  ```` .~._+wrrrrrrwwwyXHgHvvvwXml(-_(lll1t-...        //
//          .<d] (1<_ ._+ `~_```` ..~..~.~__~..~`..~..~_`____`_(<_`~..._1<.` ..~.-._<rrrrrZ><~7TWkyWmkXXXXmS==i(-((Y,.z<-u       //
//         .+=W].z-._~~kz``_~```.`` `_._<.+_ _~-````````` (:`` (<(<.~.~.(<<-..~..~.(jrrrrZ<``-~~~?HXWb?W:.g$==<.<<<,~(lz:J`      //
//        .+==W],z?>?<.Hv .~`.~..~.-.`.<.(<<`` <.``    ```_< . (<._1-....<-_<<_.~..:rrrrr<_` .(?+_(HyH/JnJm!=v.(lll([?<<7-       //
//       .+===W](?>?>:,H2_~ ~..~.....(<.~+~<_``_<` ....~.- <_..(<~ _~<-_._<..~<1-~~;rrrrO:_`..?<?1_JHXb.^.H[<=-_?<<(<====<_      //
//      .+====XL+??>?:JH$~...~..~.~-<!~.(>._< ..(: .~......(>.~+~_``` _<<<(:.__._<+<Orrrr:~((+. ??<(HyH""W#N.,?i((((======<_     //
//      :+==l=dH+>??>~df<..~..~..-(<.~.(>.__(<.~.__..~~.~..~1__<._`..J?7!-...dR``..JKrrrrX[~1?????<(HZH`.m!  ?H,?=========z;     //
//      <=====vmZ?>??_V<..~..~_(<<..~.(>.```_(<_.~~_...~.~..(<(>..?~.JWHWpppWbHa.` _HwrrrZH/_<??<<~(HXK`JP   ` ?h.=========;.    //
//      <======WR?>?!.<.~_-((<<_.(<~_<!~(((((-_1-..__.....~..<?~_`.WWfWWHHHHHkbkHh,_/HrrrrZHJ~~~~~(HyW%.H!     :?b.==l==l==<~    //
//      ;===l==vm2?<.<ux!~` ....~+~(<Qa(JQWWka.-<<_._~_.~..~.~1-_,kWV74uuuuuZWVWbbHn~JHwrrrrXHQ++WHyWP.HHMMMMmg&Jd[(=======;`    //
//      (+======XH??>;Jv``` .~..~?<~_(HWffWWkbbkHJ<<_.<-~...~._1-JVWnJXwkUwXXuX_?HbbH<_WmwrrrrrvyyyXY [email protected];[email protected]!(.((,_!     //
//       <1=l===zWR?>:.:`_` ..~.~>._.HfWKTJTXuUWHHc ?<-(<<-~..~_<-(SOtSX_ XdOOX{`HWY+~.dHNHAyrrdXkY^ [email protected]@#;[email protected]!   (T[     //
//        ;1=====vHk?:.! <_`_~...+_-dfWP.J&.wZVXXh!``` ?!`_?<+(((+;SlzO+TY1Z?td!.H=(>._WWMHMMH#=``` [email protected]@[email protected]@MNt     .:M     //
//         <1=l===vHk!(_ (1 `_.~.<_(HbK._kZkX (wZOr````````````````,2_(<__?<;jr`.-(>..([email protected]@[email protected]@M\      :+D     //
//          <1==z<<?WL(_(dkc.`_~.(jdbbR.`SlwvTYj1zI`````.```````````.1+....(J=``.(<.~(HMMMMgf!```.HTN,   ?7""HHMMN     .JY'      //
//           <+v((((jHkc:?HfAi. .(>?4HH;`,2~?<~<<+r`.`.``.`.`.`.``.```.<?<<~...-<!._(WWMMMCd-` .(@!<<N       :((M~?"""=`         //
//            ~__1llvJ?HJ-.WNMMN,(>,``.7 `.j-...(v```````-!`````.`````..-.....(?([email protected]<(UJ.H= ((jF      (:(#_z==<!           //
//             ~,-<<(~~JWh,HHWMMNg-d,.``... .?7?~``.``.`````.``````.``......._(dMHHNMM87N2<<uW9MMMMM,     .(++D.==z<!            //
//              _/<<<[email protected]"TN.-`......`````.``.``.``.``.``````....(MpfpkHM`((:+#.XY`   <:jF    .(KXu,?=z<!             //
//              ~(1=ij.!!<[email protected]  J]........``.``````. O,```.```.```````,NpWH#"` :((MM=`    .:<J].(((>J+(gxT,<`              //
//              _.?<<r,((-<.-,NNMMMNJ.JMe-.....``.``.``.````7``````.``.`..-dM"""  `  (JdNJ&&&&+(J,<de>.(z(b<Hd3(d\:              //
//                ``-._zll>v.M=      ?WNJTN,.`````````.``````.`.````...JWNM"       .d=           #<B.J===:J4aJJ=_!               //
//                   <,-;;(`d'     ...JJNJJMMMN+.....```.`.`.. ...+XHHWMMt        .Y         [email protected]_.(=v<J+N,_/`                 //
//                    _<<<~.F     .M9UWWWHHHHMMMMMMMMMMNNNMMHHHHfffWN#=,yr      .dF         .#:~d>7<<++<?XhW5(`                  //
//                    !+1li.b     .T>:(-(uZZZZZZXXUUUWWWWWpWHHYYYYY5   .y[    .= d(.........M>(g5<J5+a<j]+->/                    //
//                    ~.<?(%,N,.   _QsduZZuuZuZZZuuZZuZZk+++VTC;;++&!  ,y\ .?!`  H~??777777?NWB>:i?eJW$(}z>.(-                   //
//                      `[email protected]!` `   .MHMMMMMMMMMr:_j#~(YSd=_<<(?`                   //
//                        (+=1,N,_??<dNZuZuZZZuZZuZZuZuuZZZuZZZZZZWWNb~ .TQ,[email protected]:<Jtz_<(J9d!:        ,)            //
//                         ~+=.MWMMMMMMNZXQkZQkqkkkkXkkkZXXZXZuZuQk#""Br   ?M/[email protected]@M#_j#.==l_8T">:      .(t(.l          //
//                          _<[email protected]#`         [email protected]@M#:d\(===<v<>      .+ZXqyQX&..       //
//                           __MkWqqqmHHM9XuHmHmkHmHUXmHHkWmHgmkd]          .J] [email protected]@@[email protected]+F.==z<! !`    ....,XXo(L....      //
//                             dHWqqqHv1jggZZZuZUXWWZuZUWWWWHZWHdb          ~(@ [email protected]@@@@MhM_==v<`        [email protected]      //
//                              TNHqqqmHvzOI1OZZZZZuZZZuZZZZZZZuZWN,     ..~:JF([email protected]@@@[email protected]~(zz<!          IdUHmNgadQbeAd      //
//                               ,WNHqmHNgguJ+uuZZuZZuZuuuZuZuZZuZZWMNgJ--((+E([email protected]@@@[email protected]@HM%,<<!`           HMBY"""7"""YHH      //
//                                  ?T"""^[email protected]@@[email protected]@MM#!-!`                .{   .}/   .      //
//                                         ` ,YMHNmmmQkkXZZZuZZuZZuZx++jQ:~~~` ?YNNMMNM#"`                     /    J.+,  ,      //
//                                                   `??7"""""""""""""""^                                   ( jU-3r.\2D-.7       //
//                                                                                                          .1Z/"7777777<(..     //
//                                                                                                         !                `    //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ChalleESCA is ERC721Creator {
    constructor() ERC721Creator("Challe PFP from ESCA-NFT", "ChalleESCA") {}
}