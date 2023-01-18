// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../common/ReentrancyGuard.sol";

contract FracClone is ERC1155, Ownable, ReentrancyGuard {

    using Strings for uint256;

    // Optional base URI
    string public baseURI = "";

    /**
     * @dev Set to new uri
     * @param uri_ new uri
     */
    function setURI(string memory uri_) public onlyOwner {
        baseURI = uri_;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    constructor() ERC1155("") {}


    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
        nonReentrant
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
        nonReentrant
    {
        _mintBatch(to, ids, amounts, data);
    }
}