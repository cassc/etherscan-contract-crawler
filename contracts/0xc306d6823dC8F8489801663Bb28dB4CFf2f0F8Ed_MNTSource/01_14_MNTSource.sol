// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/ErrorCodes.sol";
import "./interfaces/IMNTSource.sol";

/**
 * @title MNTSource Contract
 * @notice Distributes a token to a different contract at a fixed rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Minterest
 */
contract MNTSource is IMNTSource, AccessControl {
    using SafeERC20 for IERC20;

    /// @dev Value is the Keccak-256 hash of "TOKEN_PROVIDER"
    bytes32 public constant TOKEN_PROVIDER =
        bytes32(0x8c60700f65fcee73179f64477eb1484ea199744913cfa6e5fe87df1dcd47e13d);

    /// @notice The block number when the MNTSource started (immutable)
    uint256 public immutable dripStart;

    /// @notice Tokens per block that to drip to target (immutable)
    uint256 public immutable dripRate;

    /// @notice Reference to token to drip (immutable)
    IERC20 public immutable token;

    /// @notice Target to receive dripped tokens (immutable)
    address public immutable target;

    /// @dev Amount of tokens available for drip
    uint256 public dripBalance;

    /// @notice Amount that has already been dripped
    uint256 public dripped;

    /**
     * @notice Constructs a MNTSource
     * @param admin_ Default admin and token provider
     * @param dripRate_ Number of tokens per block to drip
     * @param token_ The token to drip
     * @param target_ The recipient of dripped tokens
     */
    constructor(
        address admin_,
        uint256 dripRate_,
        IERC20 token_,
        address target_
    ) {
        require(admin_ != address(0), ErrorCodes.ZERO_ADDRESS);
        require(address(token_) != address(0), ErrorCodes.ZERO_ADDRESS);
        require(target_ != address(0), ErrorCodes.ZERO_ADDRESS);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TOKEN_PROVIDER, admin_);
        dripStart = block.number;
        dripRate = dripRate_;
        token = token_;
        target = target_;
        dripped = 0;
    }

    /// @inheritdoc IMNTSource
    function drip() external returns (uint256) {
        uint256 dripTotal = dripRate * (block.number - dripStart);
        uint256 deltaDrip = dripTotal - dripped;
        uint256 toDrip = Math.min(dripBalance, deltaDrip);

        dripped += toDrip;
        dripBalance -= toDrip;
        token.safeTransfer(target, toDrip);

        return toDrip;
    }

    /// @inheritdoc IMNTSource
    function refill(uint256 amount) external onlyRole(TOKEN_PROVIDER) {
        require(amount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        dripBalance += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IMNTSource
    function sweep(uint256 amount, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        require(amount <= token.balanceOf(address(this)) - dripBalance, ErrorCodes.INSUFFICIENT_LIQUIDITY);
        token.safeTransfer(recipient, amount);
    }
}