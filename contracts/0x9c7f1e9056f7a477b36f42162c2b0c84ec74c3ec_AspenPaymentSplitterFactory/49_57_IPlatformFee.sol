// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// NOTE: Deprecated from v2 onwards
interface IPublicPlatformFeeV0 {
    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);
}

interface IDelegatedPlatformFeeV0 {
    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address platformFeeRecipient, uint16 platformFeeBps);
}

// Note: this is deprecated as we moved this logic in global config module
interface IRestrictedPlatformFeeV0 {
    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;
}