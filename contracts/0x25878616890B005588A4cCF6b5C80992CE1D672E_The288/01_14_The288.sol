// SPDX-License-Identifier: MIT

/// @title THE 288
/// @author transientlabs.xyz

/*
__/\\\\\\\\\\\\\\\__/\\\________/\\\__/\\\\\\\\\\\\\\\______________/\\\\\\\\\_________/\\\\\\\\\________/\\\\\\\\\____        
 _\///////\\\/////__\/\\\_______\/\\\_\/\\\///////////_____________/\\\///////\\\_____/\\\///////\\\____/\\\///////\\\__       
  _______\/\\\_______\/\\\_______\/\\\_\/\\\_______________________\///______\//\\\___\/\\\_____\/\\\___\/\\\_____\/\\\__      
   _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\\\\\\\\\_________________________/\\\/____\///\\\\\\\\\/____\///\\\\\\\\\/___     
    _______\/\\\_______\/\\\/////////\\\_\/\\\///////_______________________/\\\//_______/\\\///////\\\____/\\\///////\\\__    
     _______\/\\\_______\/\\\_______\/\\\_\/\\\___________________________/\\\//_________/\\\______\//\\\__/\\\______\//\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________________/\\\/___________\//\\\______/\\\__\//\\\______/\\\__  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\\\____________/\\\\\\\\\\\\\\\__\///\\\\\\\\\/____\///\\\\\\\\\/___ 
        _______\///________\///________\///__\///////////////____________\///////////////_____\/////////________\/////////_____
*/

pragma solidity 0.8.14;

import "ERC721ATLMerkle.sol";

contract The288 is ERC721ATLMerkle {

    constructor(
        address royaltyRecipient,
        uint256 royaltyPercentage,
        uint256 price,
        uint256 supply,
        bytes32 merkleRoot,
        address admin,
        address payout
    )
        ERC721ATLMerkle(
            "THE 288",
            "288",
            royaltyRecipient,
            royaltyPercentage,
            price,
            supply,
            merkleRoot,
            admin,
            payout
        )
    {}

    /// @notice function to update merkle root
    /// @dev admin or owner
    function setAllowlistMerkleRoot(bytes32 newMerkleRoot) external adminOrOwner {
        allowlistMerkleRoot = newMerkleRoot;
    }

    /// @notice function to set mint price
    /// @dev only admin or owner
    function setMintPrice(uint256 newPrice) external adminOrOwner {
        mintPrice = newPrice;
    }
}