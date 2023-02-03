// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface INFTLaunchpad {
    /// @dev Only acessible by the Launchpad, secured by MaxLaunchpadSupply
    /// @param to Address receiving the minted tokens. size Amount to mint.
    function mintTo(address to, uint256 size) external;

    /// @return Maximum supply the launchpad can mint.
    function getMaxLaunchpadSupply() external view returns (uint256);

    /// @dev Cannot be bigger than getMaxLaunchpadSupply
    /// @return Current supply used up by the launchpad, cannot be bigger than getMaxLaunchpadSupply
    function getLaunchpadSupply() external view returns (uint256);
}