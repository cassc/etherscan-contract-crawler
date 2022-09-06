// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@_  _%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@"[email protected]@@@@@@@@@@@@@P      ]@@@@@@@@@@@@@@@*%@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@   _"[email protected]@@@@@@@@@[email protected]@@@@@@@@N"_   [@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@ _ @[email protected]@@@@@NNP***""**[email protected]@@@W_   m_g]@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@@[email protected]@@@NM$g, _ _,,gg,,@wbb/X,/""[email protected],_"]@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]%@[email protected][email protected]@[email protected],{*'_       "[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@@"&%QlW"$lF,*[email protected]$ll$" ___  _       "[email protected]@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@MLll|$Q{LYl$M$QTlMl}l%#lg%w,_./_         _ *[email protected]@@@@@@@@@@@@@@@@    //
//      @@@@@@gl l Q|[email protected]@R,&l$LkQlLlgll&&[email protected]""__  _"*Q_   *_        *@@p_"%$,j @@@@@@    //
//      @@@@@@@p]'LL/@@[email protected]|LL$L|Q$NNP**"`_             %_     _  __    %@g   `]@@@@@@@    //
//      @@@@@@@@p''@@@l|Ml}|@&[email protected]&,     _            _   "b,         __  ]@@_ [email protected]@@@@@@@    //
//      @@@@@@@@@@@@@[email protected]@LL$L;g|$|[email protected]%F__      _  ___        "_          _   ]@@[email protected]@@@@@@@@    //
//      @@@@@@@@@@@@||[email protected]$kP"__ mmr**[email protected],__  _ _    ,,_      _     ]@@@@@@@@@@@    //
//      @@@@@@@@@@@|$$W$%%#%%"__ __ _r_    {_    _][email protected]@gg,,g, _      _      . [email protected]@@@@@@@@@    //
//      @@@@@@@@@@hF       _ _ __,gP_   _]P_    ,@@$&[email protected]@,.           _ -   ]@@@@@@@@@@    //
//      @@@@@M"[email protected]@W%mmm4M***Ww**`"_    ,@_    [email protected]%$%k%WgNg$lP" _       ._  _   @@P`[email protected]@@@    //
//      @N"]; [email protected]@    _         _    gP"_   ,p"   _,. ,'j%_    _  _ > _     _ [email protected]    "%@    //
//      bg_]j&&[email protected]@,ggwgmmM*^"`g,,ggN`     _g` _` "_`__'_ _ _        _      _  ]@h, "_ ,g    //
//      @@@@@g"`@@       _  _ _Z$" _,w  ,gN        ,    _  L        _ _   _   @@_ ,[email protected]@@@    //
//      @@@@@@@[email protected]@p ,,,,,,ww~* __     *M*    _ _ , #[email protected]@$g,   _       _ _ [email protected]@@@@@@@@@    //
//      @@@@@@@@@@@@P"`                _  _,,[email protected]$F"`""j*%[email protected]#$b  _       [email protected]@@@@@@@@@@    //
//      @@@@@@@@@@@C    ,,,[email protected]@@@@@@%%llEk&@mgg_     ]%i%[email protected]      _ ___ ]@@@@@@@@@@@    //
//      @@@@@@@@@@@@[email protected]@%LM&[email protected]&lLLg[[email protected]*"` """        [email protected]$|'lQQQk___    ___,@@[email protected]@@@@@@@@    //
//      @@@@@@@@R|"@@@ll|[email protected]@P_,,_    __,,_,,,@@$$$ggl$,l${_ __    _,@@`_]@@@@@@@@    //
//      @@@@@@@KQW|$%@@ll1LA$l$l$l{,[email protected]@[email protected]@,[email protected]$gjlQ#{l$%[email protected],*[email protected]@K_   /@@____"@@@@@@@    //
//      @@@@@@MW%&%&F%@@Q%%%Wi%&&%N#%&%%%]&&[email protected]$Q$%l&&%[email protected]   "%N ,@@P_  ___ [email protected]@@@@    //
//      @@@@@[email protected]@@@[email protected]@@@[+<r #~wL-=rL:,,F~.~C..-M~_  F [email protected]_   ,[email protected]@@[email protected]@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@g_           ,___ ,_ ,' :__g,,,_ ___ __,@@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@@@b,_    _,g*`_F"[ L_ L`Q_*w#g _`*[email protected]@[email protected]@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@ _"[email protected]@[email protected]"M"_ ,_,M"T,_'$L _ W,`"j%[email protected]@BK_ ]@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@ _.`  *[email protected]@@[email protected],, ]'*__;[email protected]@@@@P`_l;  ]@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@_` _;[email protected]@@@@@@@@[email protected]@@@@@@@@@@bp,,_ '[email protected]@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@L,[email protected]@@@@@@@@@@@@.^ L_ '[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@g L [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract XVI is ERC721Creator {
    constructor() ERC721Creator("Metis", "XVI") {}
}