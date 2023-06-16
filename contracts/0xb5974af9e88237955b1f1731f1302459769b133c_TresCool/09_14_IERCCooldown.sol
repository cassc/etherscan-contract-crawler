// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice Interface for general carbon removal
/// @dev An interface to retrieve the transfer and mint cooldown rates to assist with carbon removal
interface IERCCooldown {
    
    /// @dev Returns the shares to be used for carbon removal during a paid transfer or purchase
    function transferCooldownRate() external view returns(uint16);

    /// @dev Returns the shares to be used for carbon removal during a mint
    function mintCooldownRate() external view returns(uint16);
}