// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Token.sol";

/// @custom:security-contact [email protected]
contract FameMmaVipNFT is Token {
    constructor(string memory baseURI_) Token("FAME MMA VIP", "FAME VIP", baseURI_) {
        //
    }
}