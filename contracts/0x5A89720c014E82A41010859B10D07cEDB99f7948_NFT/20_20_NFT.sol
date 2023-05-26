// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { INFTRegistry } from "./interfaces/INFTRegistry.sol";
import { INFT } from "./interfaces/INFT.sol";

contract NFT is INFT, Ownable, ERC721URIStorage, ERC721Enumerable, ERC721Burnable, ERC2981 {
    INFTRegistry public registry;
    bool public registryDisabled;

    event RegistrySet(INFTRegistry indexed registry);
    event RegistryDisabled(bool indexed registryDisabled);
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltyReset(uint256 indexed tokenId);

    constructor(string memory name_, string memory symbol_, INFTRegistry registry_) ERC721(name_, symbol_) {
        registry = registry_;
    }

    function setRegistry(INFTRegistry registry_) external onlyOwner {
        registry = registry_;
        emit RegistrySet(registry_);
    }

    function setRegistryDisabled(bool registryDisabled_) external onlyOwner {
        registryDisabled = registryDisabled_;
        emit RegistryDisabled(registryDisabled_);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltySet(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
        emit TokenRoyaltyReset(tokenId);
    }

    function mint(uint256 tokenId, address receiver, string calldata tokenURI_) external onlyOwner {
        _safeMint(receiver, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    function transferOwnership(address newOwner) public override(INFT, Ownable) onlyOwner {
        super.transferOwnership(newOwner);
    }

    function burn(uint256 tokenId) public override(INFT, ERC721Burnable) {
        super.burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC165, ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        if (!_isValidAgainstRegistry(msg.sender)) {
            revert INFTRegistry.TransferNotAllowed(from, to, tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _isValidAgainstRegistry(address operator) internal view returns (bool) {
        return registryDisabled || registry.isAllowedOperator(operator);
    }
}