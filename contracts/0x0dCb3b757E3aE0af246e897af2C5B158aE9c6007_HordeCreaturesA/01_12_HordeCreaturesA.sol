// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "../FlexibleMetadata.sol";
import "../EIP712Allowlisting.sol";
import "./HordeMintableA.sol";


contract HordeCreaturesA is HordeMintableA {  

    string tokenName = "Horde of the Undead: Creatures";
    string version = "1";
    string tokenSymbol = "HORDE2";

    constructor() ERC721A(tokenName, tokenSymbol) {
        setDomainSeparator(tokenName,version);
    }   

    function forceUnlock(uint256 tokenId) external onlyOwner {
        _forceUnlock(tokenId);
    }          
}