// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2023 EXPERT by 1C4RU5
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ____  _  _  ____  ____  ____  ____     //
//    (  __)( \/ )(  _ \(  __)(  _ \(_  _)    //
//     ) _)  )  (  ) __/ ) _)  )   /  )(      //
//    (____)(_/\_)(__)  (____)(__\_) (__)     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract EXPRT is ERC1155Creator {
    constructor() ERC1155Creator("2023 EXPERT by 1C4RU5", "EXPRT") {}
}