//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGuardable {
    /**
     * @param guardians Array of addresses to enable/disable for the guardian role.
     * @param enableds Array of boolean values enabling or disabling the guardian role for each address in the guardians array.
     * @notice The guardians and enableds arrays must have the same length.
     */
    function setGuardians(address[] calldata guardians, bool[] calldata enableds) external;

    function isGuardian(address guardian) external view returns (bool);
}