// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract AssetERC1155 is ERC1155, CantBeEvil, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 private _currentTokenId;
    mapping(uint256 => address) private _creator;
    mapping (uint256 => string) private _tokenURIs;

    constructor(
        string memory baseURI,
        LicenseVersion licenseVersion
    ) ERC1155(baseURI) CantBeEvil(licenseVersion) {
        super._setURI(baseURI);
        _currentTokenId = _currentTokenId.add(1);
    }

    function setURI(string memory baseURI) external onlyOwner {
        super._setURI(baseURI);
    }

    function mint(address to, uint256 amount, string memory tokenURI_) external {
        super._mint(to, _currentTokenId, amount, "");
        _creator[_currentTokenId] = to;
        _tokenURIs[_currentTokenId] = tokenURI_;
        _currentTokenId = _currentTokenId.add(1);
    }

    function mintAmount(address to, uint256 tokenId, uint256 amount) external {
        super._mint(to, tokenId, amount, "");
    }

    function batchMint(address to, uint256 tokenIdAmount, uint256[] memory amounts, string[] memory tokenURIs) external {
        require(tokenIdAmount == amounts.length, 'Invalid length');
        uint256[] memory tokenIds = new uint256[](tokenIdAmount);
        for (uint256 i = 0; i < tokenIdAmount; i++) {
            tokenIds[i] = i.add(_currentTokenId);
            _creator[i.add(_currentTokenId)] = to;
            _tokenURIs[i.add(_currentTokenId)] = tokenURIs[i];
        }
        super._mintBatch(to, tokenIds, amounts, "");
        _currentTokenId = _currentTokenId.add(tokenIdAmount);
    }

    function burn(address from, uint256 tokenId, uint256 amount) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
        super._burn(from, tokenId, amount);
    }

    function creator(uint256 tokenId) external view returns (address) {
        return _creator[tokenId];
    }

    function currentTokenId() external view returns (uint256) {
        return _currentTokenId;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory baseURI = super.uri(0);
        // If there is no base URI, return the token URI.
        if (bytes(baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }   

    function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }
}