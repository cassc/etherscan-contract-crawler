// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

/**
 * @title Interface for IELVault
 * @notice Vault will manage methods for rewards, commissions, tax
 */
interface IELVault {
    /**
     * @notice transfer ETH
     * @param _amount transfer amount
     * @param _to transfer to address
     */
    function transfer(uint256 _amount, address _to) external;

    /**
     * @notice transfer ETH
     * @param _amount transfer amount
     */
    function reinvestment(uint256 _amount) external;
}