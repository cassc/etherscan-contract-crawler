// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/BaseNFT.sol";
import "./StateNFTStorage.sol";
import "./IStateNFT.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract StateNFT is IStateNFT, BaseNFT, StateNFTStorage {
    function __StateNFTContract_init(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri
    ) internal onlyInitializing {
        __BaseNFTContract_init(aclContract, name, symbol, baseUri, collectionUri);
        __StateNFTContract_init_unchained();
    }

    function __StateNFTContract_init_unchained() internal onlyInitializing {}

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable) returns (string memory) {
        string memory baseURI = _baseURI();
        if (!_exists(tokenId)) return string(abi.encodePacked(baseURI, "burn"));
        if (bytes(baseURI).length == 0) return "";
        string memory number = Strings.toString(_tokenNumbers[tokenId]);
        string memory size = Strings.toString(uint256(_tokenSizes[tokenId]));
        string memory edition = Strings.toString(uint256(_tokenEditions[tokenId]));
        string memory redeemed = _tokenRedeems[tokenId] ? "1" : "0";
        return string(abi.encodePacked(baseURI, number, "/", edition, "/", size, "/", redeemed));
    }
}