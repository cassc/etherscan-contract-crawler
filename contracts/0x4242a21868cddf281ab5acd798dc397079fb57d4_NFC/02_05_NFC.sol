// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NON-FUNGIBLE CASTLE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                                     //
//                                                      |*~=-.,        //
//                                                      |_,-'`         //
//                                                      |              //
//                                                      |              //
//                                                     /^\             //
//                       !_                           /   \            //
//                       |*`~-.,                     /,    \           //
//                       |.-~^`                     /#"     \          //
//                       |                        _/##_   _  \_        //
//                  _   _|  _   _   _            [ ]_[ ]_[ ]_[ ]       //
//                 [ ]_[ ]_[ ]_[ ]_[ ]            |_=_-=_ - =_|        //
//               !_ |_=_ =-_-_  = =_|           !_ |=_= -    |         //
//               |*`--,_- _        |            |*`~-.,= []  |         //
//               |.-'|=     []     |   !_       |_.-"`_-     |         //
//               |   |_=- -        |   |*`~-.,  |  |=_-      |         //
//              /^\  |=_= -        |   |_,-~`  /^\ |_ - =[]  |         //
//          _  /   \_|_=- _   _   _|  _|  _   /   \|=_-      |         //
//         [ ]/,    \[ ]_[ ]_[ ]_[ ]_[ ]_[ ]_/,    \[ ]=-    |         //
//          |/#"     \_=-___=__=__- =-_ -=_ /#"     \| _ []  |         //
//         _/##_   _  \_-_ =  _____       _/##_   _  \_ -    |\        //
//        [ ]_[ ]_[ ]_[ ]=_0~{_ _ _}~0   [ ]_[ ]_[ ]_[ ]=-   | \       //
//        |_=__-_=-_  =_|-=_ |  ,  |     |_=-___-_ =-__|_    |  \      //
//         | _- =-     |-_   | ((* |      |= _=       | -    |___\     //
//         |= -_=      |=  _ |  `  |      |_-=_       |=_    |/+\|     //
//         | =_  -     |_ = _ `-.-`       | =_ = =    |=_-   ||+||     //
//         |-_=- _     |=_   =            |=_= -_     |  =   ||+||     //
//         |=_- /+\    | -=               |_=- /+\    |=_    |^^^|     //
//         |=_ |+|+|   |= -  -_,--,_      |_= |+|+|   |  -_  |=  |     //
//         |  -|+|+|   |-_=  / |  | \     |=_ |+|+|   |-=_   |_-/      //
//         |=_=|+|+|   | =_= | |  | |     |_- |+|+|   |_ =   |=/       //
//         | _ ^^^^^   |= -  | |  <&>     |=_=^^^^^   |_=-   |/        //
//         |=_ =       | =_-_| |  | |     |   =_      | -_   |         //
//         |_=-_       |=_=  | |  | |     |=_=        |=-    |         //
//    ^^^^^^^^^^`^`^^`^`^`^^^""""""""^`^^``^^`^^`^^`^`^``^`^``^``^^    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract NFC is ERC721Creator {
    constructor() ERC721Creator("NON-FUNGIBLE CASTLE", "NFC") {}
}