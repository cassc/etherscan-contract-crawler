// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721.sol";
import "ERC721Burnable.sol";
import "Ownable.sol";
import "INFT.sol";

contract NFT is INFT, ERC721, ERC721Burnable, Ownable {
    event Mint(uint256 token, uint32 kind);

    uint256 private _idCount;
    mapping(uint256 => uint32) private _kinds;
    mapping(address => bool) private _extensions;

    constructor() ERC721("SEVEN NFT", "SEVENNFT") {}

    function setExtension(address address_, bool enable) external onlyOwner {
        _extensions[address_] = enable;
    }

    function isExtension(address address_) external view returns (bool) {
        return _extensions[address_];
    }

    function kindOf(uint256 id) external view returns (uint32) {
        return _kinds[id];
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://sevenf.sevenmeta.co/api/nft/metadata/";
    }

    function _mintOfKind(address to, uint32 kind) internal {
        _idCount += 1;
        _kinds[_idCount] = kind;
        emit Mint(_idCount, kind);
        _mint(to, _idCount);
    }

    function mint(address to, uint32 kind) external returns (uint256) {
        require(_extensions[msg.sender], "not extension");
        _mintOfKind(to, kind);
        return _idCount;
    }
}