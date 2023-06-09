// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Interface for the HyperCycleToken.sol contract.
interface IHYPC is IERC20 {
    /*
     * Accesses the ERC20 functions of the HYPC contract. The burn function
     * is also exposed for future contracts.
    */
    /// @notice Burns an amount of the HyPC ERC20.
    function burn(uint256 amount) external;
}