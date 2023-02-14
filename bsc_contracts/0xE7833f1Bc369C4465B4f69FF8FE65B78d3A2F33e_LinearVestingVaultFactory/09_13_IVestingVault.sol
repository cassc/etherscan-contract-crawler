// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ReentrancyGuardUpgradeable} from
    "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";

/**
 * @notice Interface for VestingVault contracts
 */
interface IVestingVault {
    event Claimed(address beneficiary, address token, uint256 amount);

    /// @notice Some parameters are invalid
    error InvalidParams();

    /// @notice A function is called by an unauthorized participant
    error Unauthorized();

    /// @notice No tokens are currently vested
    error NotVested();

    /// @notice attempts to claim an invalid amount
    error InvalidClaim();

    /**
     * @notice The token which is being vested
     */
    function token() external pure returns (IERC20Upgradeable);

    /**
     * @notice The address who the tokens are being vested to
     */
    function beneficiary() external pure returns (address);

    /**
     * @notice Claims any currently vested tokens to the beneficiary
     */
    function claim() external;

    /**
     * @notice Returns the amount of tokens that are currently vested
     * @return amount of tokens that are currently vested
     */
    function vested() external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that are currently unvested
     * @return amount of tokens that the are currently unvested
     */
    function unvested() external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that the beneficiary will have vested by the given timestamp
     * @param timestamp The timestamp to check vested amount on
     * @return amount of tokens that the beneficiary will have vested
     */
    function vestedOn(uint256 timestamp) external view returns (uint256);
}