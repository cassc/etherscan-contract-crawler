/**
*Submitted for verification at Etherscan.io on 2021-06-18
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract PANGCAH is ERC1155, Ownable, ERC1155Burnable {    
    constructor() ERC1155("") {}

    bool migrationActive = false;
    mapping (uint256 => string) private tokenUri;
    

    // Mint function
    function mintTicket(uint256[] calldata amount, address[] calldata receiver, uint256[] calldata tokenId) public onlyOwner {
        for(uint256 i = 0; i < receiver.length; i++) {
            _mint(receiver[i], tokenId[i], amount[i], "");
        }
    }

    function burnTicket(uint256 tokenId, uint256 amount) public {
        require(balanceOf(msg.sender, tokenId) >= amount, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, tokenId, amount); // Burn one the ERC-1155 token
    }

    function setTokenUri(uint256 tokenId, string calldata newUri) public onlyOwner {
        tokenUri[tokenId] = newUri;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenUri[tokenId];
    }
}