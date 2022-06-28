//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title AuroraFutures
/// @author Aurora Team
/// @dev Deposit AURORA tokens and receive AURORA_2022_11_18 redeemable 1:1
/// after November 18, 2022 at 12:00 UTC.
contract AuroraFutures is ERC20 {
    using SafeERC20 for IERC20;

    // AURORA token address deposited.
    IERC20 public auroraToken;
    // Block timestamp after which locked tokens become redeemable.
    uint256 public unlockTime;

    /// @param _auroraToken Address of token to be locked (AURORA).
    /// @param _unlockTime Block timestamp after which locked tokens become redeemable.
    /// @param _name Name of the futures token.
    /// @param _symbol Symbol of the futures token.
    constructor(
        IERC20 _auroraToken,
        uint256 _unlockTime,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(_unlockTime != 0, "ZERO_UNLOCK_TIME");
        require(_unlockTime < block.timestamp + 365 days, "UNLOCKTIME_TOO_FAR");
        require(address(_auroraToken) != address(0), "INVALID_ADDRESS");
        auroraToken = _auroraToken;
        unlockTime = _unlockTime;
    }

    /// @notice Deposit tokens to receive futures tokens.
    /// @param amount Amount of tokens to lock until unlockTime.
    /// @dev AuroraFutures must have been given approval by `msg.sender` to spend `amount` of tokens.
    function deposit(uint256 amount) external {
        _mint(msg.sender, amount);
        auroraToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Deposit tokens and transfer futures tokens to a recipient.
    /// @param recipient Address of the recipient of AuroraFutures tokens.
    /// @param amount Amount of tokens to lock until unlockTime.
    /// @dev AuroraFutures must have been given approval by `msg.sender` to spend `amount` of tokens.
    function depositTo(address recipient, uint256 amount) external {
        _mint(recipient, amount);
        auroraToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Redeem all futures tokens and unlock tokens 1:1.
    function redeemAll() external {
        uint256 amount = balanceOf(msg.sender);
        redeem(amount);
    }

    /// @notice Redeem `amount` of futures tokens and unlock tokens 1:1.
    /// @param amount Amount of tokens to redeem.
    function redeem(uint256 amount) public {
        require(unlockTime < block.timestamp, "UNLOCKTIME_NOT_PASSED");
        _burn(msg.sender, amount);
        auroraToken.safeTransfer(msg.sender, amount);
    }
}