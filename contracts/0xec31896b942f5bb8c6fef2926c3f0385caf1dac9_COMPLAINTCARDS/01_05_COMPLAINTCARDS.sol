// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COMPLAINTCARDS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//     +-+-+-+ +-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+ +-+-+ +-+-+-+-+    //
//     |T|H|E| |C|O|M|P|L|A|I|N|T| |C|A|R|D|S| |(|n|o|t|)| |B|Y| |6|5|2|9|    //
//     +-+-+-+ +-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+ +-+-+ +-+-+-+-+    //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract COMPLAINTCARDS is ERC1155Creator {
    constructor() ERC1155Creator("COMPLAINTCARDS", "COMPLAINTCARDS") {}
}