// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wayang Kulit
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//                                    :|        :| ++  :|      //
//    :::| .::\ :\:| .::\ :::\ /::|   :|_/ :\:| :| :| :::|     //
//    :/\| `::| `::| `::| :|:| \::|   :|~\ `::| :| :|  :|      //
//              .,:'           ,.:/                            //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract WALI is ERC721Creator {
    constructor() ERC721Creator("Wayang Kulit", "WALI") {}
}