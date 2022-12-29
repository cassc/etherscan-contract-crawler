// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TopRewardNFT is ERC721, Ownable {
    string private baseURI;
    mapping(address => bool) private admins;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_)
    ERC721(name_, symbol_) {
        baseURI = string(abi.encodePacked(baseURI_));
    }

    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || admins[_msgSender()], "onlyOwnerOrAdmin: caller is not the owner or admins");
        _;
    }

    function mint(address to, uint256 tokenId) external onlyOwnerOrAdmin
    {
        _mint(to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = string(abi.encodePacked(newBaseURI));
    }

    function addAdmin(address to) external onlyOwner {
        admins[to] = true;
    }

    function removeAdmin(address to) external onlyOwner {
        admins[to] = false;
    }
}