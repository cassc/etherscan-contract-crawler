// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IIndexToken is IERC20Upgradeable {
    event MinterSet(address indexed minter);

    ///=============================================================================================
    /// Initializer
    ///=============================================================================================

    function initialize(address _minter) external;

    ///=============================================================================================
    /// State
    ///=============================================================================================

    function minter() external view returns (address);

    ///=============================================================================================
    /// Mint Logic
    ///=============================================================================================

    /// @notice External mint function
    /// @dev Mint function can only be called externally by the controller
    /// @param to address
    /// @param amount uint256
    function mint(address to, uint256 amount) external;

    /// @notice External burn function
    /// @dev burn function can only be called externally by the controller
    /// @param from address
    /// @param amount uint256
    function burn(address from, uint256 amount) external;
}