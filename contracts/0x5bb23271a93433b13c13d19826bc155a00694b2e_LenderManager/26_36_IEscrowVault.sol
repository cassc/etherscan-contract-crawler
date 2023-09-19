// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IEscrowVault {
    /**
     * @notice Deposit tokens on behalf of another account
     * @param account The address of the account
     * @param token The address of the token
     * @param amount The amount to increase the balance
     */
    function deposit(address account, address token, uint256 amount) external;
}