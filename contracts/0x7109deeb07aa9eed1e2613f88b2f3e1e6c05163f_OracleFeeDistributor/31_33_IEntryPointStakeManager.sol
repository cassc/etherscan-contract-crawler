// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IEntryPointStakeManager {

    /// @return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}