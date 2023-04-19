// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVestable {
    function supportsVestableInterface() external returns (bool);

    /**
     * @dev Side effect that is called after valut is created.
     */
    function onVaultCreated(address vault) external;

    /**
     * @dev Side effect that is called after vesting is created.
     */
    function onVestingCreated(address vault) external;
}