// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUZZGAFF_PFPcollection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    llll==??><;::::~~~~~~~~~~(1>?1wXXXXU&~~~~~~~~~~~~~~~~~~~~~~~~-~~~~:::<<>??==llll    //
//    lll=?>;;:::~~~~~~~~<~~~~~(+1zzWuzwOvUXJ+-,.`.......~~~~~~~~~~<~~~-((-~::<<<??=ll    //
//    l=?>;;:~~<~~~~~~~_(n_~~...?OyuuXUX&&uHWUUWW,...,````._...~~-(X&XXuuuXZVG-:<<<1=l    //
//    =?<;::~~~7<_~~~~~~~>~...`````_?7"77!.WVfAAQHVWUWW,```````..<JWXXUUUUXv?>J-~~:<+=    //
//    ?;::~~~~~_(<~~~~~.._`````````` ..(., .JHHeJWVWkyrXNVk+.-WVVWKzzwuzuuX6z+j%~~JwI>    //
//    ;:wun-~~_(Jn._~(((.... `..++..WVXUXXWWUUYUUWXHHHHNVWWWWKwrWVWywXUUUuuXmV?V1Z7Xt;    //
//    ::(V<?/~~~(3_JUuuXXXXuXKVKUrwXkV"!.`..`..`.`..(7OWkWArWWHWWV^` ??777!~~~~zC;;v::    //
//    :~~$;:?G~~~:z1zdSuuzOzuWWVWHK=.`.`..``.`.`..``.`..?HHkWWVfVWo``````...~jv;;;j>~:    //
//    ~~~(+;;;u,.(c;>zZUUUUXv``(JC_-..`.............__(<-<?WWVWrZWVN+`````.~(6>;:+IJy;    //
//    ~dXnJ<;:;?o`(jxzwXkV=` .d5<_<(!.X+.+_(;;< .<<_(__<+.>;T9kWArXHkRXW+.+J+t>;<Z>?X$    //
//    ~OV><O<;:<~C.````````.VW><-!__..WuX4XuXUWWXXuXXXUZ~. __?,("4HfWVHVWK1lv<;+Z<;;d:    //
//    ~(Z;:<z+<~~~(i````..AWW'.`..`.`.!WuX&<?7TTUVTY7!_..``.`.(.`jVRrVWH3~+<(+1C<:;+>~    //
//    ~~(<;;<v+~~:~_?,`.HWWf].`.`..`.J_(ZXuXn,`.`..+...;`..`.`.t` 4WkwV1+lll<J>;:;j>-_    //
//    ~J-?+;;;?1~~~..-1HSwdW_`..``.`.Z..(/HyyXW&,`.,L.`b.`..`.`,.``(V^<?1lv1v<;;;jCTuI    //
//    (XV<Ox:~~~1-~....(4U"v.`.`._.`.F...?(R7WUWkVG.X.`X.`..`...}`.^ -+:_(J<~~(jv<;;dC    //
//    ~?Z;;+6/~~:?1-...``(,{..`.`....3<_--?(L ?74wW0UuAW&.-`.`..}/ .(<!~<<~~~(J>;;<J<~    //
//    ~~(z<;;?6,~~__~_. `` t`(.`..((.>.-~~!?Jl.+.4-_((_1}.{.`.( %``` ..._~(J7<~(+J>(-~    //
//    ((J.JG<~:~7+-...``` .?~(-..,&0uJJJ+-...._?=i&.-gWmgm[`..e.<, `` --?<~~~~(J3;;jV~    //
//    (vXo<<?G,~~~._!_ ` `>-ZT94Xd#4XVQgXW6-.....(XVsTeu$(#"!-I?-(` ``...~~(J=<(;;jv~~    //
//    ~~?4tO<<<?1._... `` {-I:r.`,F?7dh.Eu$......_SGHH8o-,u...I+!(``  .._?<~~~~(+I--~~    //
//    ~._..Us<~__~_~_.`` `.-(+]`.j<.4uXwuV!........4XXX7` X-` h{(:` ` ..._((Jz7<;:JV~~    //
//    ~~(wytI?7Cw+--.. ` ``.,(%. b>-(.~! . ...`....-..,?_(Z[.`t('` `` ...~~~~~~;+/!.~~    //
//    ~~.`?Oyz<~~+>.... ``  :j!`.1v,.-'.!....`(_.`....-.-J+X..1. `` .--.-((((<vYWD`.~~    //
//    ~~.`.JU0Uw++z----. `` !,`.8jd7,.....`._!_~~..`...-JJV?h`,.`  .....~~~~~:(jXr`.~~    //
//    ~~. _7n<?Olllv._<...``<}.D(U<:?h-.`...........`.(Z::?S-h.1` .-_((((((-~(dHH...~~    //
//    ~~.`.fppWfTAs&J(zz-.(.<.=.U$::::<T1--......`-(J3:::::jv,T,>(,~-.._~~:~<SKWkb.~~~    //
//    ~~..,WwXK6zOlll=udY^..Y_` :::::::::(kVT3+-J7jX<:::::::~`..B,.?TuWGJ.~_;+uXH]-(<~    //
//    ~~~_ WkXI<;+jJUIlz-."(~`. :::::::::(Hkn_~~~JdWc:::::::: `.1-T+_(+1VSdWmXNdY(=<~~    //
//    ~~~~-(Wfk,.kZXXY17C1-(..`.::::::::+dNyWG-.(JyWH&+::::::_``,_.-_1+vXwwXXKWW,?>~~~    //
//    ~~~~(VkXW8kXX6uZz<<<<Z?_.(::::++WHWWHHWh<((VWHHWWWHa+:::.`.\-?/~~?wZWHHXyWC=<~~~    //
//    ~~~((HWOXkkSw1>_~_J.(>`-~<:+dHyyyyyyyHkHcJdkHVyyyyyyyHhJ_..,_~?x;;+HkXHWW8?=l<~~    //
//    ~_-j-_TKZKX=.$:;jC~~J`...dHyyyVyyVyWWkkHHWHHkbkVVyVyyyyyWh,`1-;j(WXWpWyWXWAlv~~~    //
//    ~~~z~(X0dWWL.T7!(<;J'.` +?WVVyyVyyVWkpWHHMHHkWKyyVyVVyVyW3>..$1V?WXWWHpHVXRk_~~~    //
//    :~~((SkdWwdV[.,`(v1{`..+z1,WyVyVWWWyyVV$HHHHyVyWWHkyyVyW1S<-.,+dVfHHXWWf.uXKh~~~    //
//    ;:~~dXzf4pyWSZ````,`..<z;;jJkyWWHkHHHyXJHHHdWyHWHHWWVyW4C<S<x??WSXpHKW$++vkWX~~:    //
//    ;::~XyWl~_HWWWW,`,`..<J;;;<dJkWWHkHWHW6MHHNbWVWWHXHHVWu3;;?kOI?zWbWWSWZ7<<XXX~::    //
//    <;::juX{~(WXWrWW/`.(<J;;;;>[email protected],kyVWWVyWu6z;;;?krG?14Y!(Xf~~_kX3:(<    //
//    =+;::?k$_(-4UHy=(<;+J;;;;;<=dMJkWSWyW4MHHHHHbdyWXXWWuMb1;++tZkXXz<?CwV<~~dY<OC>1    //
//    l=1<<::?6J+JZC.-&Juy<<;;;;[email protected],[email protected]@@@[email protected]&kz&++zZT1k.(++zl    //
//    tll=1+<(>(:<?<?KHAd1;<z;;<[email protected],[email protected]@[email protected]@@[email protected]=+;;;;?2>>>~~~~~:z<+1llt    //
//    ttttll==+<<;::(1TW3;1<<[email protected][email protected]#Oz=1;jz;?s?1-((<<+1zltttt    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract FUZZGAFF is ERC721Creator {
    constructor() ERC721Creator("FUZZGAFF_PFPcollection", "FUZZGAFF") {}
}