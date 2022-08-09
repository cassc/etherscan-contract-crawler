// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {$8liensMinter} from "./8liensMinter.sol";

/// @title 8liens
/// @author 8liens (https://twitter.com/8liensNFT)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract $8liens is $8liensMinter {
    constructor(
        address minter_,
        string memory contractURI_,
        address metadataManager_,
        address vrfHandler_
    ) $8liensMinter(minter_, contractURI, metadataManager_, vrfHandler_) {}
}