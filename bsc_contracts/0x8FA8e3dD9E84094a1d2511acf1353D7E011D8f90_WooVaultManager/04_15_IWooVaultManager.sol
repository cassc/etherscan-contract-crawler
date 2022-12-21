// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title Vault reward manager interface for WooFi Swap.
interface IWooVaultManager {
    event VaultWeightUpdated(address indexed vaultAddr, uint256 weight);
    event RewardDistributed(address indexed vaultAddr, uint256 amount);

    /// @dev Gets the reward weight for the given vault.
    /// @param vaultAddr the vault address
    /// @return The weight of the given vault.
    function vaultWeight(address vaultAddr) external view returns (uint256);

    /// @dev Sets the reward weight for the given vault.
    /// @param vaultAddr the vault address
    /// @param weight the vault weight
    function setVaultWeight(address vaultAddr, uint256 weight) external;

    /// @dev Adds the reward quote amount.
    /// Note: The reward will be stored in this manager contract for
    ///       further weight adjusted distribution.
    /// @param quoteAmount the reward amount in quote token.
    function addReward(uint256 quoteAmount) external;

    /// @dev Pending amount in quote token for the given vault.
    /// @param vaultAddr the vault address
    function pendingReward(address vaultAddr) external view returns (uint256);

    /// @dev All pending amount in quote token.
    /// @return the total pending reward
    function pendingAllReward() external view returns (uint256);

    /// @dev Distributes the reward to all the vaults based on the weights.
    function distributeAllReward() external;

    /// @dev All the vaults
    /// @return the vault address array
    function allVaults() external view returns (address[] memory);

    /// @dev get the quote token address
    /// @return address of quote token
    function quoteToken() external view returns (address);
}