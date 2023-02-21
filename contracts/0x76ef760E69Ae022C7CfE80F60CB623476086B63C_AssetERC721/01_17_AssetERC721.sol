// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract AssetERC721 is ERC721Enumerable, CantBeEvil, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 private _currentTokenId;
    string private s_baseURI;
    mapping(uint256 => address) private _creator;
    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        LicenseVersion licenseVersion
    ) ERC721(name, symbol) CantBeEvil(licenseVersion) {
        s_baseURI = baseURI_;
        _currentTokenId = _currentTokenId.add(1);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        s_baseURI = baseURI_;
    }

    function mint(address to, string memory _tokenURI) external {
        super._safeMint(to, _currentTokenId);
        _tokenURIs[_currentTokenId] = _tokenURI;
        _creator[_currentTokenId] = to;
        _currentTokenId = _currentTokenId.add(1);
    }

    function burn(uint256 tokenId) external {
        super._burn(tokenId);
    }

    function batchMint(address to, uint256 amount, string[] memory tokenURIs) external {
        require(amount == tokenURIs.length, 'NOT MATCH AMOUNT TOKENURIS');
        for (uint256 i = 0; i < amount; i++) {
            uint tokenId = totalSupply().add(1);
            super._safeMint(to, tokenId);
            _tokenURIs[tokenId] = tokenURIs[i];
            _creator[tokenId] = to;
        }
    }

    function baseURI() external view returns (string memory) {
        return s_baseURI;
    }

    function creator(uint256 tokenId) external view returns (address) {
        return _creator[tokenId];
    }

    function tokensOfOwnerBySize(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > balanceOf(user) - cursor) {
            length = balanceOf(user) - cursor;
        }
        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = tokenOfOwnerByIndex(user, cursor + i);
        }
        return (values, cursor + length);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(s_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(s_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(s_baseURI, tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}