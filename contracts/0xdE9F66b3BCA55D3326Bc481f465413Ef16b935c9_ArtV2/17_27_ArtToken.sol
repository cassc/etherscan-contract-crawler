// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ArtData.sol";

  /*$$$$$  /$$$$$$$  /$$$$$$$$
 /$$__  $$| $$__  $$|__  $$__/
| $$  \ $$| $$  \ $$   | $$
| $$$$$$$$| $$$$$$$/   | $$
| $$__  $$| $$__  $$   | $$
| $$  | $$| $$  \ $$   | $$
| $$  | $$| $$  | $$   | $$
|__/  |__/|__/  |__/   |_*/

abstract contract Artful is Ownable, ArtMeta {
    ArtMeta _meta;
    ArtData _data;

    function _tokenToArt(uint tokenId) virtual internal view returns (uint);

    function meta() external view returns (ArtMeta) {
        return _meta;
    }

    function data() external view returns (ArtData) {
        return _data;
    }

    function tokenDataURI(uint tokenId) external view returns (string memory) {
        return _tokenDataURI(tokenId);
    }

    function _tokenDataURI(uint tokenId) internal view returns (string memory) {
        return address(_meta) == address(0)
            ? _data.tokenDataURI(_tokenToArt(tokenId))
            : _meta.tokenDataURI(tokenId);
    }

    function tokenData(uint tokenId) external view returns (string memory) {
        return address(_meta) == address(0)
            ? _data.tokenData(_tokenToArt(tokenId))
            : _meta.tokenData(tokenId);
    }

    function tokenImage(uint tokenId) external view returns (string memory) {
        return address(_meta) == address(0)
            ? _data.tokenImage(_tokenToArt(tokenId))
            : _meta.tokenImage(tokenId);
    }

    function tokenImageURI(uint tokenId) external view returns (string memory) {
        return address(_meta) == address(0)
            ? _data.tokenImageURI(_tokenToArt(tokenId))
            : _meta.tokenImageURI(tokenId);
    }

    function setDescriptor(ArtMeta desc_) external onlyOwner {
        _meta = desc_;
    }

    function _getArt(uint id) internal view returns (Art memory) {
        return _data.getArt(id);
    }

    constructor(ArtData data_) {
        _data = data_;
    }
}

 /*$$$$$$$ /$$$$$$  /$$   /$$ /$$$$$$$$ /$$   /$$  /$$$$$$
|__  $$__//$$__  $$| $$  /$$/| $$_____/| $$$ | $$ /$$__  $$
   | $$  | $$  \ $$| $$ /$$/ | $$      | $$$$| $$| $$  \__/
   | $$  | $$  | $$| $$$$$/  | $$$$$   | $$ $$ $$|  $$$$$$
   | $$  | $$  | $$| $$  $$  | $$__/   | $$  $$$$ \____  $$
   | $$  | $$  | $$| $$\  $$ | $$      | $$\  $$$ /$$  \ $$
   | $$  |  $$$$$$/| $$ \  $$| $$$$$$$$| $$ \  $$|  $$$$$$/
   |__/   \______/ |__/  \__/|________/|__/  \__/ \_____*/

abstract contract ArtToken is Artful, ERC721 {
    string private _name;
    string private _symbol;

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        return _tokenDataURI(tokenId);
    }

    constructor(
        string memory name_,
        string memory symbol_,
        ArtData data_
    ) Artful(data_) ERC721(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
}