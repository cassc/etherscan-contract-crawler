// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev required interface for the base contract for KnownOrigin Creator Contracts
 */
interface IKODABaseUpgradeable {
    error MaxRoyaltyPercentageExceeded();

    /// @dev Emitted when additional minter addresses are enabled or disabled
    event AdditionalMinterEnabled(address indexed _minter, bool _enabled);

    /// @dev Emitted when additional creator addresses are enabled or disabled
    event AdditionalCreatorEnabled(address indexed _creator, bool _enabled);

    /// @dev Emitted when the owner updates the default secondary royalty percentage
    event DefaultRoyaltyPercentageUpdated(uint256 _percentage);

    /// @dev Allows the owner to pause some contract actions
    function pause() external;

    /// @dev Allows the owner to unpause
    function unpause() external;

    /// @dev Allows the contract owner to update the default secondary sale royalty percentage
    function updateDefaultRoyaltyPercentage(uint256 _percentage) external;
}