// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: B3NDRAGON 3ditions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xx____x____xx_xxx_x_____xx_____xxxxxxxxxxx_____xx____xx_xxx_x    //
//    x|xx_x|___x\|x\x|x|xx__x\|xx__x\xxxx/\xxx/x____|/x__x\|x\x|x|    //
//    x|x|_)x|__)x|xx\|x|x|xx|x|x|__)x|xx/xx\x|x|xx__|x|xx|x|xx\|x|    //
//    x|xx_x<|__x<|x.x`x|x|xx|x|xx_xx/xx/x/\x\|x|x|_x|x|xx|x|x.x`x|    //
//    x|x|_)x___)x|x|\xx|x|__|x|x|x\x\x/x____x|x|__|x|x|__|x|x|\xx|    //
//    x|____|____/|_|x\_|_____/|_|xx\_/_/xxxx\_\_____|\____/|_|x\_|    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract B3NX is ERC721Creator {
    constructor() ERC721Creator("B3NDRAGON 3ditions", "B3NX") {}
}