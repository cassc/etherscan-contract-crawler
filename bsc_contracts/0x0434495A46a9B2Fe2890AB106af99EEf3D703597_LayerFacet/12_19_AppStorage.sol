/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.8.17;

import "../interfaces/IDiamondCut.sol";

contract Storage {
    // Contracts stored the contract addresses of various important contracts to Farm.
    struct Contracts {
        address topcorn;
        address pair;
        address pegPair;
        address wbnb;
        address router;
        address topcornProtocol;
        address dlp;
    }
}

struct AppStorage {
    Storage.Contracts c;
    uint256 reentrantStatus; // An intra-transaction state variable to protect against reentrance
    uint256 reserveLP;
    bool paused; // True if is Paused.
}