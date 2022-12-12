// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "../base/BaseNFT.sol";
import "./MintNFTStorage.sol";
import "./IMintNFT.sol";

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract MintNFT is IMintNFT, BaseNFT, MintNFTStorage {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    function __MintNFTContract_init(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri
    ) internal onlyInitializing {
        __BaseNFTContract_init(aclContract, name, symbol, baseUri, collectionUri);
        __MintNFTContract_init_unchained();
    }

    function __MintNFTContract_init_unchained() internal onlyInitializing {
        // nextTokenId is initialized to 1
        _tokenIdCounter.increment();
    }

    function mint(address to) external onlyMinter returns (uint256 tokenId) {
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}