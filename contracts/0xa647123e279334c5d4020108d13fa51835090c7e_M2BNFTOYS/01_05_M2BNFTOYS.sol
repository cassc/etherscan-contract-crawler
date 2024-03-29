// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLACKCATDEAD NON FUNGIBLE TOYS COMPANY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//       _____     __         _____      _____    __  __     _____     _____      _______     _____       _____     _____      _____        //
//     /\  __/\   /\_\       /\___/\    /\ __/\  /\_\\  /\  /\ __/\   /\___/\   /\_______)\  /\ __/\    /\_____\   /\___/\    /\ __/\       //
//     ) )(_ ) ) ( ( (      / / _ \ \   ) )__\/ ( ( (/ / /  ) )__\/  / / _ \ \  \(___  __\/  ) )  \ \  ( (_____/  / / _ \ \   ) )  \ \      //
//    / / __/ /   \ \_\     \ \(_)/ /  / / /     \ \_ / /  / / /     \ \(_)/ /    / / /     / / /\ \ \  \ \__\    \ \(_)/ /  / / /\ \ \     //
//    \ \  _\ \   / / /__   / / _ \ \  \ \ \_    / /  \ \  \ \ \_    / / _ \ \   ( ( (      \ \ \/ / /  / /__/_   / / _ \ \  \ \ \/ / /     //
//     ) )(__) ) ( (_____( ( (_( )_) )  ) )__/\ ( (_(\ \ \  ) )__/\ ( (_( )_) )   \ \ \      ) )__/ /  ( (_____\ ( (_( )_) )  ) )__/ /      //
//     \/____\/   \/_____/  \/_/ \_\/   \/___\/  \/_//__\/  \/___\/  \/_/ \_\/    /_/_/      \/___\/    \/_____/  \/_/ \_\/   \/___\/       //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract M2BNFTOYS is ERC1155Creator {
    constructor() ERC1155Creator("BLACKCATDEAD NON FUNGIBLE TOYS COMPANY", "M2BNFTOYS") {}
}