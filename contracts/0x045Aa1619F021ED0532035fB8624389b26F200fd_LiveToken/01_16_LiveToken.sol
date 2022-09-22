//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.8.0;
import "./ERC721Token.sol";
 
contract LiveToken is ERC721Token {

    constructor() ERC721Token(
            "Phases",                                   // _name,
            "PHASE",                                    // _symbol,
            "https://phases.metadata.webtrei.io",       // _metadataURI,
            0xD0E148753ab1DF7acB510d0843CBE69aFa6De655  // _receiver
        ) {
    }

}