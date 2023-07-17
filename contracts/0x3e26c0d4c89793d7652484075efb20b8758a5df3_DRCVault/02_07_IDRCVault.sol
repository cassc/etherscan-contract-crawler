// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.4;
pragma abicoder v2;

/**
 * @dev Interface of Digital Reserve contract.
 */
interface IDRCVault {
    /**
     * @dev Emit each time a deposit action happened.
     * @param user Address made the deposit.
     * @param amount DRC amount deposited.
     */
    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev Emit each time a withdraw action happened.
     * @param user Address made the withdrawal.
     * @param amount DRC amount withdrawn.
     */
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @dev Name of the contract
     */
    function name() external pure returns (string memory);

    /**
     * @dev DRC Address
     */
    function drcAddress() external view returns (address);

    /**
     * @dev Total DRC Amount locked
     */
    function totalAmountLocked() external view returns (uint256);

    /**
     * @dev DRC balance of an account in the Vault
     * @param account Address of an account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev DRC Vault holder list
     */
    function holders() external view returns (address[] memory);

    /**
     * @dev Deposit DRC to the Vault
     * @param account Address to deposit to
     * @param amount Amount of DRC to deposit
     */
    function deposit(address account, uint256 amount) external;

    /**
     * @dev Withdraw DRC from the Vault
     * @param amount Amount of DRC to withdraw
     */
    function withdraw(uint256 amount) external;
}