// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Unite Club
// contract by: buildship.xyz

import "./ERC721Community.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    #  #         #     #                 ##   ##          #         //
//    #  #               #                #  #   #          #         //
//    #  #  ###   ##    ###    ##         #      #    #  #  ###       //
//    #  #  #  #   #     #    # ##        #      #    #  #  #  #      //
//    #  #  #  #   #     #    ##          #  #   #    #  #  #  #      //
//     ##   #  #  ###     ##   ##          ##   ###    ###  ###       //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////

contract UniteClub is ERC721Community {
    constructor() ERC721Community("Unite Club", "UC", 7200, 50, START_FROM_ONE, "ipfs://bafybeieyircr6gb2bjy733fkzkut6mu354dbwrzt4vmjdmrelzmslsla4e/",
                                  MintConfig(0.0021 ether, 5, 5, 0, 0x0Aac044b4266BDF98Ad7A4d94585dbF99bdE143E, false, false, false)) {}
}