// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: SKULLCRUSHERS
// contract by: buildship.xyz

import "./ERC721Community.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//      ###   #   #  #   #  #      #              ###   ####   #   #   ###   #   #  #####  ####    ###      //
//     #   #  #  #   #   #  #      #             #   #  #   #  #   #  #   #  #   #  #      #   #  #   #     //
//     #      # #    #   #  #      #             #      #   #  #   #  #      #   #  #      #   #  #         //
//      ###   ##     #   #  #      #             #      ####   #   #   ###   #####  ####   ####    ###      //
//         #  # #    #   #  #      #             #      # #    #   #      #  #   #  #      # #        #     //
//     #   #  #  #   #   #  #      #             #   #  #  #   #   #  #   #  #   #  #      #  #   #   #     //
//      ###   #   #   ###   #####  #####          ###   #   #   ###    ###   #   #  #####  #   #   ###      //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract SKULL is ERC721Community {
    constructor() ERC721Community("SKULLCRUSHERS", "SKULL", 1275, 20, START_FROM_ONE, "ipfs://bafybeibp2lewnkkexfl6xkjmuc5s5wb2g44i6pgykvupa5oji2undgphwq/",
                                  MintConfig(0.025 ether, 20, 20, 0, 0x29123eC8e68D5a02026b934F2BB353a40796A969, false, false, false)) {}
}