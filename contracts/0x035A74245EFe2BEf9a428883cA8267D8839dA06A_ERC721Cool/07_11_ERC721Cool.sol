// SPDX-License-Identifier: MIT

/**
* @title ERC721Cool Generic Contract
* @authors Tres Cool Labs (www.trescool.xyz)
* @notice This contract is uniquely designed to hardcode in perpetual carbon capture to any NFT use case that adopts this standard.
* This contract is not a complete NFT contract and requires additional functionality to complete it. 
* The code below encompases the implementation of ERCCooldown, needed for carbon capture.
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./ERCCooldown.sol";

/// @notice ERC721Cool Generic NFT Contract
contract ERC721Cool is ERCCooldown, ERC721A, Ownable {
    constructor() ERC721A("ERC721Cool", "CoolNFTs") ERCCooldown(1000, 500, 500) {}

    /// @notice Basic mint quanitity functionality
    /// @dev Sends quanity of NFTs to msg.sender
    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mintCooldown(msg.value);
        _mint(msg.sender, quantity);
    }

    /// @notice Interface Support
    function supportsInterface(bytes4 interfaceId) public view override(ERCCooldown, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Fallback function to receive secondary sales revenue
    /// @dev Processes a transfer cooldown using msg.value
    receive() payable external {
        _transferCooldown(msg.value);
    }

    /// @notice Fund withdraw function
    /// @dev Empties the smart contract balance to msd.sender as owner
    function withdraw() public onlyOwner {
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH");
    }
}