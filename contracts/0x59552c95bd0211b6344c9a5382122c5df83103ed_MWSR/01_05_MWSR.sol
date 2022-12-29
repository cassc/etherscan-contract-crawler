// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MWSR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//       *              (   (         //
//     (  `   (  (      )\ ))\ )      //
//     )\))(  )\))(   '(()/(()/(      //
//    ((_)()\((_)()\ )  /(_))(_))     //
//    (_()((_)(())\_)()(_))(_))       //
//    |  \/  \ \((_)/ // __| _ \      //
//    | |\/| |\ \/\/ / \__ \   /      //
//    |_|  |_| \_/\_/  |___/_|_\      //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract MWSR is ERC721Creator {
    constructor() ERC721Creator("MWSR", "MWSR") {}
}