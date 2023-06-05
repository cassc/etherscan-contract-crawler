// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICedarMinorVersionedV0 {
    function minorVersion() external view returns (uint256 minor, uint256 patch);
}

interface ICedarImplementationVersionedV0 {
    /// @dev Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function implementationVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );
}

interface ICedarImplementationVersionedV1 is ICedarImplementationVersionedV0 {
    /// @dev returns the name of the implementation interface such as ICedarERC721DropV3
    /// allows us to reliably emit the correct events
    function implementationInterfaceName() external view returns (string memory interfaceName);
}

interface ICedarImplementationVersionedV2 is ICedarImplementationVersionedV0 {
    /// @dev returns the name of the implementation interface such as impl/ICedarERC721Drop.sol:ICedarERC721DropV3
    function implementationInterfaceId() external view returns (string memory interfaceId);
}

interface ICedarVersionedV0 is ICedarImplementationVersionedV0, ICedarMinorVersionedV0, IERC165Upgradeable {}

interface ICedarVersionedV1 is ICedarImplementationVersionedV1, ICedarMinorVersionedV0, IERC165Upgradeable {}

interface ICedarVersionedV2 is ICedarImplementationVersionedV2, ICedarMinorVersionedV0, IERC165Upgradeable {}