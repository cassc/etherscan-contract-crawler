/**
 * @title Interface Fee Vault
 * @dev IFeeVault contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

interface IFeeVault {
    function createLiquidity(address _token) external;
}
