// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "./interface/IERC1155Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Bulls and Apes Project - Traits Burner Helper
/// @author BAP Dev Team
/// @notice Handle the burning of Traits as deposit to be used off-chain
contract TraitsBurner is Ownable {
    /// @notice Master contract instance
    IERC1155Factory public traitsContract;

    /// @notice Event for Utilities burned on chain as deposit
    event TraitsBurnedOnChain(
        address user,
        uint256[] utilityIds,
        uint256[] amounts,
        uint256 timestamp
    );

    /// @notice Deploys the contract and sets the instances addresses
    /// @param traitsContractAddress: Address of the Master Contract
    constructor(
        address traitsContractAddress
    ) {
       traitsContract = IERC1155Factory(traitsContractAddress);
    }


    /// @notice Handle the burning of Traits as deposit to be used off-chain
    /// @param traitsIds: IDs of the Traits to burn
    /// @param amounts: Amounts to burn for each Utility
    /// @dev This contract must be approved by the user to spend the Traits
    function burnTraits(
        uint256[] memory traitsIds,
        uint256[] memory amounts
    ) external {
        require(
            traitsIds.length == amounts.length,
            "burnTraits: Arrays length mismatch"
        );

        for (uint256 i = 0; i < traitsIds.length; i++) {
            traitsContract.burn(msg.sender, traitsIds[i], amounts[i]);
        }

        emit TraitsBurnedOnChain(
            msg.sender,
            traitsIds,
            amounts,
            block.timestamp
        );
    }

    /// @notice Set the Traits Contract address   
    /// @param traitsContractAddress: Address of the Traits Contract
    function setTraitsContractAddress(
        address traitsContractAddress
    ) external onlyOwner {
        traitsContract = IERC1155Factory(traitsContractAddress);
    } 
}