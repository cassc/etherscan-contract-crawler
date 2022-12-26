// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sylphy's Appreciation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    WZVuuX1XZk+wuuuXZuuuuuuuuuuuuuXXuuuXXuuuZuuZZuuuuuuuzuzzzzzXXzvvzvvvvvrvrvrrrrrrttttttllllltlllzOzz1vXP``````(-_dH%.`.>-    //
//    HS:_?7XZuCwuuuuuuuuuuXXuuuuuuXXZuXXUuZZuuZuuuuuuuuuzuuuXXXwwwwAwwwwwzvvrrrrrrrtrrrrtltttllllOOz===zO=zI-+zu+..+<?>.`-r_.    //
//    ?:(JuXZZuXuuZZuuuXXuZXuuuuuXXuXXWuuXuZuZuuuuuuuuXXXHMMMMMMMMMMMMMMMMMMHHmmAyrtrtttttOtllllll==lzOz==zz=Ozv!_UHm+_``.v_-(    //
//    wXXZuuXZZZZZZZZuXSXZuuXXuuZuuXXZZuXSuZuZZZXQQ9ZttXHWWUXZZuuVOOwwrZVUwzltOVWMMHmmAtttttlttOll======1=?zOzZ`..`?Ul+(+wc!_`    //
//    kZuuuuWZXXZuZuuXXuXUuXXuXZuXXXXXZuZZZuXQqMHMMrtOvrwXrrrrrwwXwz???1zOOOwwOllwXZOOVWHZtttllllll=====??zv7?C+--.-?UOv!?1-v<    //
//    [email protected]z??1llOtlOwzlOwllllllzXAOlll=z===?==zwwO=JHB=_<<?i  (%..    //
//    UUWkuuuuuuuuuXZuXXXZUuZuuXZuuuuuuXXHHHgMMHuX0OXtllllltOrOllllllllzOz====zlllOOzll==lzOlzUHszl========ztOXzC``` _ j>!<o<:    //
//    uuuuZuZZXuuuuZXXXuXXuXuuXuuuuuuXX80wXUXX0CzwIzZ1>>1<>>>1lz=llll====zz=?==?=z<?7wv=<<?<<~~?OUWAzllll==OvtwW:```.>(H;` ?<<    //
//    HXXkXZXyZXWZXWZWSXkuuuuXuuuuuuXH0twXwrvXI>>l<+rz+>?>>>>>1z===zOz???<<<<!~``  ```?_ ``` ~-``?0wUWAz==l==llC`` .WHHUU>_~<<    //
//    uZW%(NdyuXZuZuuXuXuuuuuuuuuZXW9ttwOtttw0llzr<;zzll??>>;>>1z??<<<<~.```-_````` .`` ~ ````_~ `_  ?7Wmsz===z-.+W#~wkXXZ-``_    //
//    uXf (>vWXWXXWuWSXWuZuuuuuuXdH0ttOlllllwzlllt1+zI==?<>;;;<<?>`````` _.``._.```` _```` <<<<(~_.<```(UXHmzzwXXMMMh(WWWR_``.    //
//    Xf__(<(yZWXXZZZuZuuuuuuuuXH#ZtOO====1zI1===t==1l???<<~```_-__````. .`` ``__```` _ ````_-`(_`` _-.`(_?OTWkuuWHMWRwyZXo...    //
//    $_((Z;(ZZUZXuuuuUXXuuzuuXM#OtOOl==1?>=<z===lz??z<<~.`.``. _.  ```````... `-_ `.~__.```` - _``````- ~.-1-?TuuWMHHkXyZXkXW    //
//    .++zz;dZZXXuuuuXXzuuuzXXWH0llOllz??>+v:j===zv<<<<```.`.```__`_ `_.`````` .`.<._``` -```` _ _. ```._.(- <_` ?OWMHgRWXWHyy    //
//    zzOO<+XyZXyuuuzuZzXzzXWSW0lllllllllzjz(jz?<<!-_._`.``` -`. _``_.` _``````` .jm,`. ...`.`` _ _ ~1x!~~_-_.(.`` [email protected]    //
//    ??z1jHWyZXWXZuuuZuWzzXSXSzOwll=l=lllzZ=zI!  _`_-  ```.` -``-<.._-` _.````` (HMHgf^``._ _____``.-1_``` _.`<-```?MggHyVWyy    //
//    1O1dMNVyZZyZuZuuZupXXSuXC1=Zl=ll=z=lOI<`~ ``_. _`..```` _...j+_.<-.._-`.`.J4dMH$ ````__``.`__`...1-. ``_ .O1-.`[email protected]    //
//    I=dWWHVyZZZZuZuuuzXXHuwk=zzI=====l==Z~.`__.` _`-__(<....(<..(Mm-.?+_.-<-.1dB=`<w{ ``` _```.`_  _ `_<<<-(<-(< _~.UHgHZVyZ    //
//    1dWyWWyZZXuuzuuzzzdHSvwIllt<1==??=v<I_.__<```(_._<~<<-((jI_-,K?9n-(G-~(vuW=`.` (O-`.``__````..` ~ ```` <-`._~_ ~(<?WXyZZ    //
//    WWVyWWZZuWuuXzuzuXWHwruI==t<::<<?z>~z_`_ +-.` <_._<:1+>?1C;<.S_._7n(4gXH91-```` <n.``` ~.```` _` _ ````.1-..` _ (+~(SZZZ    //
//    yfyyZZuZuuuzzzzuzXMSrrXv==t;::(<(<~.z_(_`(I+++(O,~(<:<>>>1;+>I_.`..?wHNI<~~<-.``(jo ``.._..```. `-_..__`(~~<<++;<zs_dXZu    //
//    ZWWZuuZuXXuuXzzzzXM0ltV=?1O::<<:<__(d+++-(zz????vA-<:::::<>;1I_`..`.-?zU+_~~:<<..>z> .` _` .```.``(_```-````.zl.._><zXuu    //
//    ZZWkuXXuuuzzzvrvwWWZllI???l:<<:(:(>+WI=zzltw+>>;<O01+(::::<;jI ..(+&zzZ0dWe---((++1w-```__ ````  ` >.`.```` _(Wx..__?Ruu    //
//    UVCz1zWuXvzzzwrrdHXZ==l????(<:<z>>?1HR=zZ1+Ok<;;;;vo<<<+++jxdUYT1<:<~~~~~_?Ts-_~<;<10_``._ _``.`_``(_._``` . +vHo-<__duZ    //
//    +==?=uSXuvzzzvrw0rzZ==l??1I+<:<Xc>>jM#OzI;;+XG<::::jz<<<<<(I(I;<<~~~~~~~~~~_<?O-___<jl ` (._````  `.<_``` .`(>(XWU0zzWZZ    //
//    ===uy0vvzzvzXzwZzfjz<<v:<jI=1+=Z>>;j#Vz>z>;;?Izx::~:1x::~_(S(<~~~~~~~~~~~~~~~~~(11-(=X-..(__```. .`.<_` .~`.v_(uI.-(<4uz    //
//    =zvTMkvvvXwzzXkId$<;<(O;;jZ1=?<X2;<dRzO<+o<::jz+I+:~~1<::_dZo<~~~~~~~~~~~__(_:_(d#0wwdo  j<_``.``.-`-z+<``.+~.(Xw-._<(zz    //
//    dWWWdHkvzZXwdbK(W6>:::z<1zZ+<><WI;;d0=Oc<d<:::1>;<1+_:1<:(V>jz_~~~~_((<<(+gHMHMMMMNNMMN+(zc_..``` _` j> `.(>` +(XX&(1wzv    //
//    yZZZWHWklltZXk$jH0<::_jz?zI<;;(WI;;dZugkcdN+:::1<:::?<_(1dC::1>~~(+<;+jgMMMMMMMMMMMNNNMeJJkv!```` .``({ ((y_..< wXkdkXvv    //
//    ZZZZWWWWkztlwU1VWI+1+?zI?1O:::(Ow(+d9C<~1<W6<::~<_~::::j++<~~:+++<;jdMMMMMMXXwWMHNzwTMNNMU'````.``.`. wz+ZS<-+<(dHkWHrrr    //
//    ZZZX6dHZZWylzZdwuI+v<<+w>?z<::(zdv<w<~~~~~(111_~~____::dDzv11<+zz<[email protected]?zdNM$~````.```..``(o___---(_dMXHSrrr    //
//    ZyWXWWZZZSWHdwHHH>(v:~~z<>1<::(WS<(O~~~~~~<<<;+1-~<._.(0I>~~~~~~:(dY><(HM9UXWW9UUMD~(dBW<`.``.````-.``.Ozv<~(;!-dMXHwrtO    //
//    ZZZZZXXWUUUWNWHWHI_<~:~(I;+><(JC+I:1~~~~~~~_1_::(<+(XA-t>~~~~~~~~(C~:~(dDlz<?V<<zXS<<z;j:````.``.`..`. +>_._<~.(dMHStttt    //
//    ZuuZZXWXWWXXMMkfHI_<:~~~I;><::j<;1<+<(((;<<<1O+(_:~?<~?<~~~~~~~~~~~~~~~(Sz1_(+<++z<;<;;+<`.`._.``..````(I=z<__(Z<X.?Oltt    //
//    uuuuuuuUWkXWXHHkWz_(<:~~(z;<<:z<:<+<GgggmQHHmme+<<<~~~~~~~~~~~~~~~~:~:::(TC::;:;;;;<:;;+~ `` _`.``.``...zzv::+1I<z<IJwlO    //
//    uuuuuuuuuwXSW0XWNI:_<<_:_z+;+<w++ugmdMMMMMMMqWWWm+~~~~~~~~~~~~~~~~~::~::::::;;>;;>>;;;;z__``._.``  ```` jI;<x=?z<(r(w?XV    //
//    uuuuuuuuzzWXHvXWNz>_<;;:_(O>;zkAgH##[email protected]_~~~~~~~___`__~~~~::~::::;;;;;;;;;;;+I=<-`(_```-_```__(yzz=v~z~(R+wl ?    //
//    uuuuuuzuzdSXKvXWNz<_(;;::(O<;[email protected]@@HWHXWHH<~~~~~_````. _~~:~~::~::::;;:;;;;;;;juk<_.+_..`~ ``.(_ uz?=!`__ dWU$-`    //
//    uuuuuzzzzXuWRvXWNz><_<::::jI;zpWMMM$?><[email protected]>z$_~~~~-`..._~~~~:~~~~:~::::::::::::+Od#:<(>_`` _```` <`.I??_` _.(WQk-`    //
//    uzuzzzzzzkuWkwydHI><_+<::;+w<zHWMMNz>;::?WOO<:(<<::~~~~~~__~~~~~~~~:~~:~~~~~~:~::~::(01JD((v;<``._```._j{ jz?_``__.WvVI     //
//    uzzzzzzzwSZXRzZdHI>;<(z<;;;(IdHMBHqHe<:::?WHy<::::~:~~~~~~~~~~~~~~~~~~~~~~~:~~~~~:(?<z>j>:Jv;<.._ ````~(R.(I?_`` _ dI<O_    //
//    zzuzzzzvwkw<WuZdHI;;:_1z::::1OMMHz<++1<<(<+v>;::::~:~~~~~~~~~~~~~~~~~~~~~~~~:~~:~~~(<:;z<j$;;<_ _```` _(H[ j1<`.`__($_+O    //
//    zzzzzzvvwkwczuXdHX;;:<(z+:::(jdWWNs>;;+>;<;;;;:::~:~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~(<::+>+WI<;:_-`````._.WN-(I< ```_.C  j    //
//    zzzzzvvrrXXk(XuK<w>;::_?l+(::<OzzXMm<;;>;;;;::::~:~~~~~~~~~~~~~~~(((+u+dk<~~~~~~_?>~~(?J1WI?<;__```` _  dWI.1<_`.` -(..d    //
//    zzzzvvrrrrZW<jXK<dI;::::+lz+::(XzX0ZHx;;;;;::::~:~~:~~~~~~~~_(+xrOOOv11zX>~~~~~~~~~~(+<_(Hv>>><_``.`._`.(XX>(<~.`.`_(I<?    //
//    zzzvvvvrrrtd9C(I-d0<;::::1tlz+:jXHvlzWs;::::::~:~~:~~~~~~~(gKwVlvz1<>>>;z<~~~~~~~~-(<!.-dMI>;+<```` (<``(Orv-<__``. .1<<    //
//    vvvvrrrvrOZ:(wX3 O+O;:::::+tO=1zd#O=dHWR_:~~~~~~~~~~~~~~~~?HHI1>>>>;>>;+>~~~~~~_(<<<_.-dMHI>;;>` _`.z>` (ltOI:___```_(z>    //
//    vvvrvrvrrU&J<;+! j;1z<::;::?====wNzOHkwdN-~~~~~~~~~~~~~~~~~_7O+>;;;;;;<<~~~~~__~:<~.`.dMHHR;>><.._.+zI` j=Otwz_ _.`` _O+    //
//    vrvrrvrrrrOUk+< `(>;1<:;;;1(<1==zWUAI=OVXN+:~~~~~~~~~~~~~~~~~~~<<<<<<~~~~~~~~~~~_`` (UMUHHb;;>_._ (=wI`.+=zOzZ<` _``` (I    //
//    rrrrrrrrrrtrOX{``(<;;1;:;;jNx:uz=VuZUXszlZTk+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~_`..Z1dStUHH<>;<~ (?zu>`.O=zrlwl``-_``` z    //
//    vrvrrrrrrrrrtX:``(z;;;;<;;;WHm+?XHuI=llOwUUOUe-._~~~~~~~~~~~~~~~~~~~~~~~~~~~~~_ .vC?>zZtZWww<+:.(??wI``.ZlztlOl ``__```_    //
//    rrrrrrrrrtttzC (.(z>;;;z2;;zZZWmx4XI====zzZllzUn..__~~~~~~~~~~~~~~~~~~~~~~~~_..dZ1??>zZttXkwO>-<>>zV~``-Z=lIlZjr`` ~ ```    //
//    rrrrrrrrtttOZ!.z_ 1+;>+zOz>(XuuXHNAO==llzvOl==zvdHk+--__~~~~~~~~~~~~~~~~~~~.(uSI?????dAwwwSZi(?>>zC````(Ill=v~dW-`` _```    //
//    rrrrrrttttlz> (O<`(??>+rjHs<OXzzXKvXUXwzwOlzllwOdHOllOOww&(--_~~~~~~~~~~~~(dUZI??????wOrrrsdHv?+v:``.``(Ilv!_(WXn.``--``    //
//    rrrrttttlv>-_ (O<[email protected]+wvvXSrrrrrtrOlllzrtXIlllllll=OdMHWHA+--_~~((WSO1????????zrrwXMXHKzC`````` z<~-..XpuWl `._ `    //
//    rttrtttz(>(k  jO?<`(z?td#0twOzXvXOrrrrrwZlllzrOw0lllllll=zOddHWM0rrZUSdW0I1?????????>1rwUOWHX#!```.````.(!_(VyVuXW-.` _`    //
//    rttttOdXI(W$  jtz>_.1jdHOlllzwxXktrrtrwZll=zrOzZlllllll==Ij0wWWMZtrrrrOv??????????>>>+vzOOVW=```.```` _<_.uVVVVuwwS-``_-    //
//    ttwZ=<<<z+z>_ jI?>>_(OW0lllltwHOZwtttwZll=zrOltlllllll=lv>dVdI=XZttllz???????????>+z1zC??jC~```````....-jpVyyyyuzrXk_` _    //
//    Z=<-((+gMMD_~`(I>>>><(0llllldWtOZrrOwOtOwXrOlOlllllll=1v<jZw$=1kOllz?????????>>>>+1ZC??1v!```````` . -&kzWyVyyy0zrrZn.`     //
//    gWKI??dHZXI(_``(z>>>jHSwllld0tOZtOwOOOwuvOtlOOlllll==zI<<[email protected]??????????>?>+zvC?>1uy!.``.`..```.dHHKvXyyyyy0vrrvwn.`    //
//    3.?A=1XWyXIJ[`` 1+>jWZttwXX6tOZtwZllzw0ZtllOOlllllllzI;:jwZzwXW$?????????>?>?>+zC+?jdWX!..._-(<- .JOWWWHwwZZyyykvOrrrds.    //
//     (.-7HK><?<dS-`` ?uWSAU0OtOSOzwZllwX0ZllltwOlllllllOI;;JwXzvrX6??>>?>>?>>?>>?1Xkz+wZvZ>_::(>;;;;(zlzXuuX0wZZZZZ0rwtrrrXn    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SYLA is ERC1155Creator {
    constructor() ERC1155Creator("Sylphy's Appreciation", "SYLA") {}
}