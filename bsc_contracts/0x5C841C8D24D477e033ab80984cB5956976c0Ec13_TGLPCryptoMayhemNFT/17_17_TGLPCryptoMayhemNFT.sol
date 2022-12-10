// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@10set/nft-minter-smart-contract/contracts/Token.sol";

/// @custom:security-contact [email protected]
contract TGLPCryptoMayhemNFT is Token {
    constructor(string memory baseURI_) Token("TGLP Mayhem", "TGLP CM", baseURI_) {
        //
    }
}