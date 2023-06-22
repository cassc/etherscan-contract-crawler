// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ERC721Impl is ERC721Upgradeable, OwnableUpgradeable {
    string private _baseUri;

    function __ERC721Impl_init(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address owner
    ) external initializer {
        _baseUri = baseUri;
        __Ownable_init();
        __ERC721_init_unchained(name, symbol);
        _transferOwnership(owner);

        // mint 20 NFTs to owner
        for(uint256 i = 0; i < 20; i++) {
            ERC721Upgradeable._mint(owner, i);
        }
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        ERC721Upgradeable._mint(to, tokenId);
    }

    function mintBatch(address to, uint256[] memory ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            ERC721Upgradeable._mint(to, ids[i]);
        }
    }

    function setBaseURI(string memory newBaseUri) external onlyOwner {
        _baseUri = newBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
}