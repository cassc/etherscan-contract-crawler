// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wildflower in Metaverse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//    //                                                                                                 //
//    //                          MMMMMMMMMMMMMMMMNXNMMMMMMMMMMMMMMMMMMMMM                               //
//    //                          MMMMMMMMMMMMMMMMk;kMMMMMMMMMMNk0WMMMMMMM                               //
//    //                          MMMMMMMMMMMMMMMMd.kMWMMMMMMNx:cOWMMMMMMM                               //
//    //                          MMMMWMMMMMMMMMMMd.dXXXWMMW0:;OWMMMMMMMMM                               //
//    //                          MMMWOooxOXWMMWXx' ....,:dl,oXMMMMMMMMMMM                               //
//    //                          MMMMN0xollcldl.    ..     ;KMMMMMMMMMMMM                               //
//    //                          MMMMMMMMMWKx'   .lO00Od'   cNMMMMMMMMMMM                               //
//    //                          MMMMMMMMMMM0'  .dWMMMMMO.  .dKKXXXXWMMMM                               //
//    //                          MMMMMMMMMWXd.   cNMMMMNd.  .:llllldXMMMM                               //
//    //                          MMMMMMW0occc:.   'clol,    'cx0NWWMMMMMM                               //
//    //                          MMMMMWOcoONMWO;.        .;x0kl:ckNMMMMMM                               //
//    //                          MMMMMMW-MMMMMMO,'cc:::'.oNMMMMNxl0MMMMMM                               //
//    //                          MMMMMMMM-MMMNx,cXMM-MMo.kMMMMMMMMMMMMMMM                               //
//    //                          MMMMMMMMM-MXl;kNMMMM-Ml'OMMMMMMMMMMMMMMM                               //
//    //                          MMMMMMMMMM-0xXMMMMMMM-klKMMMMMMMMMMMMMMM                               //
//    //                          MMM--MMMMMM-MMMMMMMMMM-NMMMMMMMMMMMMMMMM                               //
//    //                          WNNX--NNNWMN-KNNKXNNNWM-KKNNNXXNNXXWNKXW                               //
//    //                          Nkood--OO0MOx-kkoOKkxKNk-xk0dookOdxXkldK                               //
//    //                          M0O0ON--00NKO0K-0NN0k0NK0-KNO0O0XO0NKO0N                               //
//    //                          MMMMMMMM--MMMMMM-MMMMMMMMM-MMMMMMMMMMMMM                               //
//    //                                                                                                 //
//    //Y88b         / 888 888     888~-_   888~~  888       ,88~-_   Y88b         / 888~~  888~-_       //
//    // Y88b       /  888 888     888   \  888___ 888      d888   \   Y88b       /  888___ 888   \      //
//    //  Y88b  e  /   888 888     888    | 888    888     88888    |   Y88b  e  /   888    888    |     //
//    //   Y88bd8b/    888 888     888    | 888    888     88888    |    Y88bd8b/    888    888   /      //
//    //    Y88Y8Y     888 888     888   /  888    888      Y888   /      Y88Y8Y     888    888_-~       //
//    //     Y  Y      888 888____ 888_-~   888    888____   `88_-~        Y  Y      888___ 888 ~-_      //
//    //                                        _         _   _ __             ___              ___      //
//    //                                       |_) \_/   |_) |_  /  /\    |\/|  |  |   /\  |\ |  |       //
//    //                                       |_)  |    | \ |_ /_ /--\   |  | _|_ |_ /--\ | \| _|_      //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WM is ERC721Creator {
    constructor() ERC721Creator("Wildflower in Metaverse", "WM") {}
}