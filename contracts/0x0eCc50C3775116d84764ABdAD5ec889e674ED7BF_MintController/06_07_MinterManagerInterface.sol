//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

/**
 * @notice A contract that implements the MinterManagementInterface has external
 * functions for adding and removing minters and modifying their allowances.
 * An example is the FiatTokenV1 contract that implements USDC.
 */
interface MinterManagementInterface {
    function isMinter(address _account) external view returns (bool);

    function getMinterAllowance(address _minter) external view returns (uint256);

    function configureMinter(address _minter, uint256 _minterAllowedAmount)
        external
        returns (bool);

    function removeMinter(address _minter) external returns (bool);
}