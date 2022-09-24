// SPDX-License-Identifier: MIT

/// @title Impermanence by Josh Pierce
/// @author transientlabs.xyz

/*
 __     __    __     ______   ______     ______     __    __     ______     __   __     ______     __   __     ______     ______    
/\ \   /\ "-./  \   /\  == \ /\  ___\   /\  == \   /\ "-./  \   /\  __ \   /\ "-.\ \   /\  ___\   /\ "-.\ \   /\  ___\   /\  ___\   
\ \ \  \ \ \-./\ \  \ \  _-/ \ \  __\   \ \  __<   \ \ \-./\ \  \ \  __ \  \ \ \-.  \  \ \  __\   \ \ \-.  \  \ \ \____  \ \  __\   
 \ \_\  \ \_\ \ \_\  \ \_\    \ \_____\  \ \_\ \_\  \ \_\ \ \_\  \ \_\ \_\  \ \_\\"\_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_____\ 
  \/_/   \/_/  \/_/   \/_/     \/_____/   \/_/ /_/   \/_/  \/_/   \/_/\/_/   \/_/ \/_/   \/_____/   \/_/ \/_/   \/_____/   \/_____/ 
                                                                                                                                    
*/

pragma solidity 0.8.14;

import "ERC721ATLMerkle.sol";

contract Impermanence is ERC721ATLMerkle {

    /**
    *   @param royaltyRecipient is the royalty recipient
    *   @param royaltyPercentage is the royalty percentage to set
    *   @param price is the mint price
    *   @param supply is the total token supply for minting
    *   @param merkleRoot is the allowlist merkle root
    *   @param admin is the admin address
    *   @param payout is the payout address
    */
    constructor (
        address royaltyRecipient,
        uint256 royaltyPercentage,
        uint256 price,
        uint256 supply,
        bytes32 merkleRoot,
        address admin,
        address payout)
        ERC721ATLMerkle(
            "Impermanence",
            "IMPERMANENCE",
            royaltyRecipient,
            royaltyPercentage,
            price,
            supply,
            merkleRoot,
            admin,
            payout
        )
    {}

    /// @notice function to change merkleroot if needed 
    /// @dev only admin or owner can execute
    /// @param _root is the new merkle root
    function setAllowlistMerkleRoot(bytes32 _root) external adminOrOwner {
        allowlistMerkleRoot = _root;
    }

    /// @notice function to set mint price
    /// @dev only admin or owner
    /// @param _price is the new mint price
    function setMintPrice(uint256 _price) external adminOrOwner {
        mintPrice = _price;
    }
}