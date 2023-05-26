// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@10set/nft-minter-smart-contract/contracts/Token.sol";

/// @custom:security-contact [email protected]
contract TGLPArrlandNFT is Token {
    constructor(string memory baseURI_) Token("TGLP Arrland", "TGLP AR", baseURI_) {
        //
    }
}