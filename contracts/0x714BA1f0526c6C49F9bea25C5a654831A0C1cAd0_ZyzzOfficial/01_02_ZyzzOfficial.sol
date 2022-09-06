// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: ZyzzNFT Official
// contract by: buildship.xyz

import "./ERC721Community.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//      _    _   __  __ _____ _____  _____ _   _   ____  _____            _    _ ___      //
//     | |  | | |  \/  |_   _|  __ \|_   _| \ | | |  _ \|  __ \     /\   | |  | |__ \     //
//     | |  | | | \  / | | | | |__) | | | |  \| | | |_) | |__) |   /  \  | |__| |  ) |    //
//     | |  | | | |\/| | | | |  _  /  | | | . ` | |  _ <|  _  /   / /\ \ |  __  | / /     //
//     | |__| | | |  | |_| |_| | \ \ _| |_| |\  | | |_) | | \ \  / ____ \| |  | ||_|      //
//      \____/  |_|  |_|_____|_|  \_\_____|_| \_| |____/|_|  \_\/_/    \_\_|  |_|(_)      //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////

contract ZyzzOfficial is ERC721Community {
    constructor() ERC721Community("ZyzzNFT Official", "ZyzzNFT", 4000, 10, START_FROM_ONE, "ipfs://bafybeieb2o6fqo4674acvqx57ftbalwwumjdaczfchwbpbxxaxjgbnomam/",
                                  MintConfig(0.003 ether, 5, 5, 0, 0xde2d1Af6aa90B81D91402d331faD6B5f2dba5482, false, false, false)) {}
}