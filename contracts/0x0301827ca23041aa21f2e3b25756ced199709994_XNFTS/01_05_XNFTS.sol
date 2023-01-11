// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XNFTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//    XXXXXXX       XXXXXXXNNNNNNNN        NNNNNNNNFFFFFFFFFFFFFFFFFFFFFFTTTTTTTTTTTTTTTTTTTTTTT   SSSSSSSSSSSSSSS     //
//    X:::::X       X:::::XN:::::::N       N::::::NF::::::::::::::::::::FT:::::::::::::::::::::T SS:::::::::::::::S    //
//    X:::::X       X:::::XN::::::::N      N::::::NF::::::::::::::::::::FT:::::::::::::::::::::TS:::::SSSSSS::::::S    //
//    X::::::X     X::::::XN:::::::::N     N::::::NFF::::::FFFFFFFFF::::FT:::::TT:::::::TT:::::TS:::::S     SSSSSSS    //
//    XXX:::::X   X:::::XXXN::::::::::N    N::::::N  F:::::F       FFFFFFTTTTTT  T:::::T  TTTTTTS:::::S                //
//       X:::::X X:::::X   N:::::::::::N   N::::::N  F:::::F                     T:::::T        S:::::S                //
//        X:::::X:::::X    N:::::::N::::N  N::::::N  F::::::FFFFFFFFFF           T:::::T         S::::SSSS             //
//         X:::::::::X     N::::::N N::::N N::::::N  F:::::::::::::::F           T:::::T          SS::::::SSSSS        //
//         X:::::::::X     N::::::N  N::::N:::::::N  F:::::::::::::::F           T:::::T            SSS::::::::SS      //
//        X:::::X:::::X    N::::::N   N:::::::::::N  F::::::FFFFFFFFFF           T:::::T               SSSSSS::::S     //
//       X:::::X X:::::X   N::::::N    N::::::::::N  F:::::F                     T:::::T                    S:::::S    //
//    XXX:::::X   X:::::XXXN::::::N     N:::::::::N  F:::::F                     T:::::T                    S:::::S    //
//    X::::::X     X::::::XN::::::N      N::::::::NFF:::::::FF                 TT:::::::TT      SSSSSSS     S:::::S    //
//    X:::::X       X:::::XN::::::N       N:::::::NF::::::::FF                 T:::::::::T      S::::::SSSSSS:::::S    //
//    X:::::X       X:::::XN::::::N        N::::::NF::::::::FF                 T:::::::::T      S:::::::::::::::SS     //
//    XXXXXXX       XXXXXXXNNNNNNNN         NNNNNNNFFFFFFFFFFF                 TTTTTTTTTTT       SSSSSSSSSSSSSSS       //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XNFTS is ERC721Creator {
    constructor() ERC721Creator("XNFTS", "XNFTS") {}
}