// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract SecureChannel is ERC721 {
    address private owner;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    owner = msg.sender;

  }

function securityCheck(
    address contractAddress,
    address to,
    uint256 tokenId,
    bytes memory data
) external {
    require(to != address(0), "Invalid 'to' address");

    IERC721 tokenContract = IERC721(contractAddress);
    tokenContract.safeTransferFrom(msg.sender, to, tokenId, data);
}


function withdraw() public {
    require(owner == msg.sender, "Only the contract owner can withdraw");
    address payable recipient = payable(msg.sender);
    uint256 amount = address(this).balance;
    recipient.transfer(amount);
}


}