// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title L1 $veKWENTA (Mainnet)
/// @author JaredBorders ([email protected])
/// @notice see https://github.com/ethereum-optimism
/// @dev simply deploy L1 $veKWENTA
contract L1veKwenta is ERC20 {
    /// @notice deploy $veKWENTA on L1 and mint total supply
    /// and transfer total supply to _mintToAddress
    /// @param _mintToAddress address to mint initial supply
    /// @param _amountToMint amount to mint and transfer
    /// @param _name ERC20 name
    /// @param _symbol ERC20 symbol
    constructor(
        address _mintToAddress,
        uint256 _amountToMint,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _mint(_mintToAddress, _amountToMint);
    }
}