// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kido's Art 721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz    //
//    zzuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzXXuzzuzuuXXuuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzuXyzuzzuzzuzzuzzu    //
//    zuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzuXXUuXZUXsOwXUUuXUWWHmmyzzuzzuzzuzzuzzuzzuzzuzQWzzuzzuzzuzzuzzz    //
//    zzzuzzzzzuzzzzzuzzzzzuzzzzzuzzzzzuzzuCSQWkXzXQmQgmWYY""""""TWdHyzzzuzzzzzuzzzzzXQkl.SzzzuzXeSzzuzzuz    //
//    zuzzzuzzuzzuzzuzzuzzuzzuzzuzzuzzuzzzZQ8JXXUQk"=-...<1OCCO&++....(?""""""771dXXw(dzzzzuzzzuzzuzzzzuzz    //
//    zzuzzzuzzzuzzuzzzzuzzzuzzuzzzzuzzuzzHdkX4J=.(7~__(((?71+<...~?"WHdWW0(,   ?XXzzzzzzzzzuzzzuzzuzzuzzz    //
//    zzzuzzzuzzzzuzzuzzzuzzzzuzzuzzzuzzuuN;KM^ !~`        ?~?-/~+_(!._?UXuUzXW&.. ~"Tkuzuzzuzuzzzzzuzzuzz    //
//    zuzzuzzzuzzuzzzzuzzzuzzuzzzzuzXXX9X48. =. ~.              ?~,?-/--?(JWXzzzzXn. _,RzzuzzzXQXuzzzuzzuz    //
//    zzuzzuzzzuzzuzuzzuzzzuzzuzuzZ"~-!.?J ?m,  !.                 _- ?.   ?THXuzzzzXh,(UXzzuzH.Juzuzzzzzu    //
//    zzzuzzuzzzuzzzzuzzuzzzuzzzX3.,!./~.~  dJ6. ._.                    _.   ~(4kzzX9yXS,.RzzuzzzzzzuzuzzZ    //
//    zuzzzzuzuzzuzzuzzzuzuzzuzu0,!  : .:<. .j11?i/.<.     _              ~.    .5XzXUzzun24zzzzXv7<zzzuzz    //
//    zzuzzuzzzuzzzuzzuzzzzuzzXu3./ /  ( (?,  </z;:C-/!.     .          1.        .SOXXzzzXLjXuzXSzSzzuzzu    //
//    zzzuzzzzzzuzzzzuzzuzzzzXu5y,>. _.. :/J/  ?,1_`_<<1.~~.. _          .+.     .. ?NUuzzzzL1uzzzzzuzzzuz    //
//    zuzzzuzuzzzuzzuzzuzuzuuGD#[<;_ :~j)<,,(G. .11.  _ ~_(<<.->-...       <...._! ...#4zuQzX-(kuzzuzzuzzz    //
//    zzuzzzuzuzzzuzzzzzzzzzZHWH$[}:  `j{(.z( ?i  ?J.   . .  ``_<_<<<<~~~__~<t      ? (gzzzuzlXzzuzzzuzzzu    //
//    zzzuzzzzzuzzzuzuzuzuzzdHXdb1]..  .)._}(-.`?n. (3,   ..     _  .     .~,.4,    , ,dkzzzXjzzzzuzzzuzzz    //
//    zuzzuzuzzuzuzzzzuzzzuXXHHPPvR ?  .{ ;( (,. (_=.. -"+,.     .;!    ..=!  4X,   J,,dXzuXt.Szuzzuzzzuzz    //
//    zzuzzzzuzzzzuzzzzzuzzuHWuXb.J (. !_ ( - _o~., ((N ..  ?7?-.,<<+..?^     ,k4.   M,MkXQKzzzuzzzzuzzuzz    //
//    zzzuzzuzzuzzzuzuzzzuzzXWWXF H]./-, 1_>(. ,(->`.,Mb `.._>~~~~_1``    {    4SD;  jHJXzzzzuzzzuzzuzzzuz    //
//    zuzzuzzzuzuzzzuzuzzzzzzUMM`.MN,N,.< <z.1  t 1i`jWX[ ` {(    _.      .    ,Nd3  ,ddzzzuzzuzzuzzzuzZCw    //
//    zzuzzzuzzzzuzzzzzuzuzuzzXF d#<?(B1-<-?4,< ,/.+l(Hgd,``..    ..-j     )   .HIM  .XSzuzzzzzuzzuzzzun.     //
//    zzzuzzzuzzuzzuzuzzzzuzzuq\.M<;;~?hJ7Xm..-i (,(_,#Y>b....     {:.;    l   .NdB .dVzzzuzuzzzzzzuzzzzzz    //
//    zuzzuzzzuzzzuzzzuzzzuw7^,&M5~`    .7`` <_i4,?+1,$;;d .-      {:(b    .   .OSKd8zzuzzzzzUSzuzzuzuzzuz    //
//    zzuzzuzzzuzzzuzzzuzZ                    .,Jjh,4o(+;J_..-.   ._`dR    d .P+SX1Szuzzuzuzzzzuzzuzzzuzzz    //
//    zzzzzzuzzzuzzzuzzzuX,                    .1777MMm3<J_.('..  ...NH` ` @ (ESQ$wuzzzzzuzuzzzzzuzzzzzuzz    //
//    zuzuzzuzuzzuzzzuzzzuh                     <>~    7"s/(].j}  .!dMF ` .NUd8q5wzzuzuzzzzzuzQZTTXzuzzzuz    //
//    zzuzzuzzzuzzuzzuzzuzX.                   ,^       .dY(E(d{.(<,MM'..#dHmmMSzzz7Ozzuzuzzzd`   ,zzuzzzu    //
//    zzzzuzzzzzuzzuzzuzzzX}                   !       .=.VGFJMrJQnMMP.8UzUzzzzzzuzzzzzzuzuzzdn&dXzzzzuzzz    //
//    zuzzzuzuzzzuzzzzzuzzzX.p.                   ,` `..VC<MdMHdVgMMHXzzzzzzXQggmXzuzuzzzzzuzuzzzzzCXzzuzz    //
//    zzuzzzuzuzzzuzuzzzuzzX,                    .TmdMB1<;(dHdQbUzzVuzuQgNMMMMMMMMMMNggmmXuzzzuzzuzzzuzzuz    //
//    zzuzuzzzzuzzzzzuzzzuzzX.           ` `    ,v??==??>?uNXXSzzuQgNMMMMMMMMNNMMMMMMMMMMMMMMMMMNNNggmQmXX    //
//    zuzzzuzzuzzuzuzzuzzzzzzh        ` ` `  ` .v?????<>>>>WXzXgNMMMMMMMMMMMMMMMMMMMMMMMNNMMMMMMMMMMMMMMMM    //
//    zzzzzzuzzzuzzzuzzuzuzuzuL       `   ..gJzI???=?<~?+uggNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNMMMMMMMMM    //
//    zuzuzzzuzzzuzzzuzzzzuzzzuh,.....JUMMNdSwZ???=1ggNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    zzuzuzzzuzzzuzzzuzzzzzuzzzzuuzuzzzuzuNI%+uggMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    zzzzzuzzzuzzzuzzzuzuzzzuzzzzzzzzzuzzzdNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    zuzzuzzuzzuzzuzuzzzzuzzzuzuzzuzuXZ7jdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    zzuzzzuzzzuzzzuzzuzzuzuzzzzuXv=<_(dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM""MMMMMMMMMMMMMMM    //
//    zzzuzzzuzzzuzzzzuzzuzzXXmXY_~~:(MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN   .MMMB""WMMMMMMM    //
//    zuzzuzzzuzzzuzuzzzzuZf-_:~::(JMMMMMMMMMMMMMMMMMMMMMMMMMM8-BMMMM#HMMMMMMMMMMMMMMMMMMMMMM'     dMMMMMM    //
//    zzuzzuzzzuzzzuzzuzzXJ>:~:~(+MMMMMMMMMMMMMMMMMMMMMMMMMNQMNdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN...JMMMMMMM8    //
//    zzzzzzuzzuzuzzzuzzuDr_~((dMMMMMMMMMMMMMMMMMMMMMMMMMNM#gMMMMMMMMMMMMMMMMMMMM#zVMMMMMMMMMMMMMMMMMMMSzz    //
//    zuzuzzuzzzuzzuzzzzzXNdMMMMMNMMMMMMMMMMMMMMMMMMMMM84dgMMMMMMMMMMMMMMMMMMMMMMMKzzuMMMMMMMMMMMMMMBzzzzz    //
//    zzuzzuzzuzzzuzzuzuX^(NNMMMMMMMMMMMMMMMMMMMMMMMMMKJQMMMMMMMMMMMMMMMMMMMMMMMMMMNXzzzVMMMMMMMNMUzzzzuzu    //
//    zzzzuzzzzuzzzzuzzVnJSHQMMMMMMMMMMMMMMMMMMMMMMMMMHMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmzuzzuzzzukXzzzuzzzuz    //
//    zuzzzuzuzzuzzuzzzzzzzzzdNMMMMMMMMMMMMMMMMMMMMM5dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNyzuzzuzzuzzuzzuzzzz    //
//    zzuzzzuzzzzuzzuzuzzzzzzzuzzXMMMMMMMMMMMMMMMMMbMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMF dMMMNXzzzuzzuzzuzzuzuz    //
//    zzuzuzzzuzzzuzzzzuzuzzuzzuuWMMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMMM`  .M=dMMMMMMMMNMMM#Xzuzzzzzuzz7?1zzu    //
//    zuzzzuzzuzuzzuzzuzzzuzzzzzzdMMMMMMMMMMMMMMMMNdMMMMMMMMMMMMMMMMMNNNgMMMMMMMMMMMMM#MMMMMNmuzzzuzo..zzz    //
//    zzzzzzuzzzzuzzzuzzuzzuzu[email protected]zuzzzuzzuzuz    //
//    zuzuzzzuzzuzzzuzzzzuzzzzuuuMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#zzzuzzuzZOzzz    //
//    zzuzuzzzuzzzuzzuzuzzzuzzzzuMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNmzzzzuzz    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract K721 is ERC721Creator {
    constructor() ERC721Creator("Kido's Art 721", "K721") {}
}