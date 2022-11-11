// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUZZ_GAFFcartoon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ZZZZZZZZZZZWgXHkZZZZZZf<~(<~~~~~~~:~~:~~~(J?????????z?<<::::::::?4+<:::jt....._<    //
//    ZZuZZuZZuZZZZWddKMWBKU~~~:~~~~~:::+_:~~~(J???????1?z1<::::~::~::(vn+;:+Id.~_~.~.    //
//    ZZZZZZZZZZZZZZZZZZZXW$.._>~~~~~(xz<~~~(+jI???????=I<<::~::~::~::?<::~<CJd:._:..~    //
//    ZuZZuZZuZZuZZuZZuZZV!.~._..~_(<<<~~~(JO1?????????zw+w+:~::~::(J>::~::::?w>._<...    //
//    ZZZZZZZZZZZZZZZZZXv..~.~.-(J!~~~~(JZI??1zx??????<(XuuX-:~::((C::~::~:~:(z:.(<~..    //
//    ZZuZZuZZuZZuZZuZV^..~._(+?~.~~_Jdkz1??I~~?Oz<Z77<(juuun:(((+-<::::::~::(d<.(<~.~    //
//    ZZZZuZZZZuZZZZX^..~._(+>.~.~.(6vXXXUwzzc~~:~~(>...(4uuuuuuXuXZn:~:~::::(d{.(;_..    //
//    ZuZZZZZuZZZZuZC..~.(+^...~.-J?uyC;;;;1~:~:~:3.......4ZXuV7OuuuZI:~::~::(zn-.(<~~    //
//    ZZZZZuZZZZuZX3~.~-+>..~...(Iz31+;;;;;;1JCz__->..~..._WZX>:?uuuuO:::::~(:<<zG,(/_    //
//    ZZuZZZZZuZZ0!..~(v..~..~~(zv<;jC;;;;<<++<<~~_o-...~..(ZZI::juuuXG::~(?:::::(?I(_    //
//    ZZZZuZZZZXf~.~-J~..~..~-J~=:1;;(<+z+>>>><<<_l(~;......WZZ+(Jwuuuzc::::~::~::::j-    //
//    uZuZZuuZX=..~(^...~..~(3~:~JC++<1>>>>>><~~~(J2l(~..~..(XZZ7<?zuuUw::~::~::~::~:0    //
//    ZZuZZXX9~.~-/..~..~._J>77c~?+z>>>>>>>+<(11md2Xv(_....._SZZI:(zuuuz>::::::::~::::    //
//    ZZZ0YzC~..(^..~..~.(Cj;;;?<Sz>>>>>>>1<<jxF(vjjJC+(-..<.(ZZX<::zzuuI:~:~:~:::~:::    //
//    UV>+z~..~(_..~..~.(O+d;;;;;Js>>>+<1<[email protected](1cJ4O>J<<J1+..jZXI::(XuuX::~:::~:::~:<    //
//    ;<<<_.~_~...~..~-JZZZK;;;jI?Jm>jzQgg,~~_.J<JIJ+z<_<~_1Ji_WZuwwywuuu>:::~::~:(-(J    //
//    <<~~..-}.~..~..(ZZZZX$;;(v?1<OVWNJ~CI1<_~(JdW0II;<.(!.-(?zkZZV777<+:::~::::~(J>:    //
//    <~...~_.~.~..~(XZuZV1I;;<1z+dC1<<_?uJJJJ?C>+J>2Iz</~(<~(/(zZXz(:::::~(!?+::<:<::    //
//    ~..~~.~.~~.~~(wZZZuWz>;<;zOC>><~~~~~1Cf>+>+>d<}$>I-<(Jv1ZIljZk?<::~::(..<1((((+z    //
//    .~~_,~~~.~~._dZuZZZZw;+I<Zo++<~_((J>J+D>>><<d~{I&I+</1wUwZx>4Zk?1+((J3.~OX6dY7~~    //
//    _(=<~~.~~___JZuZuZZXz+wI+0wwZ&uww<?jOwC<<~~~dJ{jjIvJXSZZzd((<UXOl>_Cj<~_rrZwt~~~    //
//    ~~~~~~~~_<>jZZZZZZVzrrrI+vrrwdZdw<;<Cum_~~~(MM]j&30kwZ<v<_l(wVlll>~cz(._wwOI-~~(    //
//    ~~~~~~_(JdZZZuZuZZI<;?7CjrrrrrIjO_~~>>dMaJJMMM](zzzuIVc>>lJ/?zl=l>_IvO-.wrwZx>+J    //
//    ~_(JdWZZZuZZuZZuX0I+?1<:J<+1CCXGl>~.1c4H>>>><<>(+z(r$ZXXIOwG_JOl=z(<Z<{_jrrvO1HX    //
//    XWZuuZuZZZZZZZZX+<<1;+v(<;;;;+XdIl(-+1XZr_~~~~>((2jrSzy(vIwZI(n?1z?(j<1~(rrrDzqq    //
//    ZZZZZuZV<>><_?TXXrz+i+J+<<<<;;jrklll:>(Z$~~~~~>(<SXOwo4ylzrZOljZo-(J<_(<(wrZI~?W    //
//    ZuZZuZX>>><~~~~~~?UwwwwAszz&&+uXOrll:+SZX~~~~~+_lI(lzCUZlwOZlzl4Ollr>_<{_jO3z:~>    //
//    ZuZuZZX>><~~~~~~~_C~(vVVwwOrrAW0l=lv:+df<~~~~~(.l1?yZ1dwlOzOOll1/77(<(;1~(:(j::(    //
//    ZZuZZuX2<~~(zA&-_~~~~c~~~jlvGwSrOlz>(Cv~~__~~~(.IOzXlJJXOlllIl=llllOr++v<.j((:::    //
//    ZZZZuZZk<~~~<XZZV4+,~~~~~(lll2?7OwI(>6<~~_~~(JX_(d?XjShXwvyOrzlzzrrrd5:zi._v(:~:    //
//    uZuZZZuX;~~~_JkZXjZXXC&-JIlzw>~~~~_<?QJ_~~~~?>8<(ZXZukuWwyUUwdAwrwy6<::j(:.(c<:~    //
//    ZZuZuZZZk~~~~(UYWjWXdzIzUXAA$<~~~~~~~_MMMMN0C1Or_SI_0w;;zwwO<jz????<::~?o(-~t>::    //
//    ZuZZZuZZXr~~~(J<VjXydOIzXXIllZG+._~~~_JMB:~~~~_I.1vJwwI;<0Xz<.GzOAz?1_::1:1.(z::    //
//    ZZuZZuZuV<((<^.<~?4zlzI<OXv<1v0C=?OOO&7~~~~~~~_j.(OOjXX<;?RXl__I???7731&(z<<.(_~    //
//    ZZuZZZZXV!...`....-JCzTzwwIzzC<<<<uZZ0<(~~~~~(JO_(wrZ7wr._?wv/<_zz:::~::(<I<>.<_    //
//    ZuZZZ=<(Jo.(<++__..<+pSZI<<:::::(vCvzZO0r~~(JC?1{.Xrrx0v,..(Iz(1(+C+-::~::J=c<.(    //
//    ZZuZ{(v$+>....-(..((1Oz<::~:~:(?~~~(JTw0ZIO<<:::>.(v0yw&J-,..?z1JIzz+<?<iv~~Iz<.    //
//    ZZXS<jr=JIHW$~+>((:<==Oz1J<<(>~~~~~~+=kwV3Z:::~:z-(J+<vTwo(!...(<1<<<<1v1-<-(j(1    //
//    uZZJ~(Ozz<z((+vGszG(<==O<1+>~~~~~~~(d+vwZSI:(J>?+?_1Ji((+<?1O1----..._<<(<<(<((:    //
//    ZZZX.(zIO1jeeewXV0v2:<==O=~~~~~~~(JC<::wOXI:~:::(1:_1<1-((((((jx71Cz1.__111-((2:    //
//    ZuZt-((IIzjmAsegAVv<::j>~~~~~~_(Jz<:((JuIwd77G&JJJ+<+-1vC?0<<<<<::>;<+O+_?+1_zo1    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract FUZZGAFF is ERC721Creator {
    constructor() ERC721Creator("FUZZ_GAFFcartoon", "FUZZGAFF") {}
}