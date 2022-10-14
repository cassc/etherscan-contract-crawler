// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICedarMinorVersionedV0 {
    function minorVersion() external view returns (uint256 minor, uint256 patch);
}

interface ICedarImplementationVersionedV0 {
    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function implementationVersion()
    external
    view
    returns (
        uint256 major,
        uint256 minor,
        uint256 patch
    );
}

interface ICedarVersionedV0 is ICedarImplementationVersionedV0, ICedarMinorVersionedV0, IERC165Upgradeable {
}