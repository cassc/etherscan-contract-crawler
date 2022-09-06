// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract ERC721MultiURIUpgradeable is Initializable, OwnableUpgradeable, ERC721Upgradeable {
    using StringsUpgradeable for uint256;

    string public baseTokenURI;

    string public bundleTokenURI;

    string private _mysteryBoxURI;

    struct MultiURI {
        // 0: baseTokenURI
        // 1: bundleTokenURI
        // 2: uris[0]
        // 3: uris[1]
        // 4: uris[2]
        uint8 displayId;
        string[3] uris;
    }

    mapping(uint256 => MultiURI) private _tokenURIs;

    function __ERC721MultiURI_init(string memory _baseTokenURI, string memory _boxURI) internal onlyInitializing {
        __ERC721MultiURI_init_unchained(_baseTokenURI, _boxURI);
    }

    function __ERC721MultiURI_init_unchained(string memory _baseTokenURI, string memory _boxURI)
        internal
        onlyInitializing
    {
        baseTokenURI = _baseTokenURI;
        _mysteryBoxURI = _boxURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBundleTokenURI(string memory _bundleTokenURI) public onlyOwner {
        bundleTokenURI = _bundleTokenURI;
    }

    function setMysteryBoxURI(string memory _uri) public onlyOwner {
        _mysteryBoxURI = _uri;
    }

    function setTokenURI(
        uint256 tokenId,
        uint256 pos,
        string memory uri
    ) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721MultiURI: caller is not owner nor approved");
        require(pos < 3, "ERC721MultiURI: uri pos out of index");

        _tokenURIs[tokenId].uris[pos] = uri;
    }

    function setDisplayTokenURI(uint256 tokenId, uint8 displayId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721MultiURI: caller is not owner nor approved");
        require(displayId < 5, "ERC721MultiURI: display id out of index");
        string memory uri = displayURI(tokenId, displayId);
        require(bytes(uri).length > 0, "ERC721MultiURI: empty uri");

        _tokenURIs[tokenId].displayId = displayId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721MultiURI: URI query for nonexistent token");

        uint8 displayId = _tokenURIs[tokenId].displayId;
        string memory uri = displayURI(tokenId, displayId);
        if (bytes(uri).length > 0) {
            return uri;
        }

        return super.tokenURI(tokenId);
    }

    function displayURI(uint256 tokenId, uint8 displayId) public view virtual returns (string memory) {
        if (displayId == 0) {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : _mysteryBoxURI;
        }
        if (displayId == 1) {
            if (bytes(bundleTokenURI).length > 0) {
                return string(abi.encodePacked(bundleTokenURI, tokenId.toString()));
            }
        } else {
            string memory uri = _tokenURIs[tokenId].uris[displayId - 2];
            if (bytes(uri).length > 0) {
                return uri;
            }
        }
        return "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        delete _tokenURIs[tokenId];
    }
}