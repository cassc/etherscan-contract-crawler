// SPDX-License-Identifier: Public Domain
pragma solidity =0.8.13;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Wrapper contract around USDC. Not to be used anywhere, or by anyone...
/// If you do use it, do so at your own risk.
/// @author Elliot Friedman
contract WUSDC is ERC20("Wrapped USDC", "WUSDC") {
    using SafeERC20 for IERC20;

    /// @notice reference to USDC on mainnet
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// @notice emitted on mint, minter is msg.sender
    event Mint(address indexed minter, uint256 amount);
    
    /// @notice emitted on redeem, redeemer is msg.sender
    event Redeem(address indexed redeemer, uint256 amount);

    /// @notice return decimals for WUSDC
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// ---------------- Mint Logic ----------------

    /// @notice mint WUSDC with USDC
    /// WUSDC is sent to msg.sender
    /// @param amount of WUSDC to mint
    function mint(uint256 amount) external {
        _mint(amount, msg.sender);
    }

    /// @notice mint WUSDC with USDC
    /// @param amount of WUSDC to mint
    /// @param to recipient of WUSDC
    function mint(uint256 amount, address to) external {
        _mint(amount, to);
    }

    /// ---------------- Redeem Logic ----------------

    /// @notice redeem WUSDC for USDC
    /// USDC is sent to msg.sender
    /// @param amount of WUSDC to redeem
    function redeem(uint256 amount) external {
        _redeem(amount, msg.sender);
    }

    /// @notice redeem WUSDC for USDC
    /// @param amount of WUSDC to redeem
    /// @param to recipient of USDC
    function redeem(uint256 amount, address to) external {
        _redeem(amount, to);
    }

    /// ---------------- Helpers ----------------

    function _redeem(uint256 amount, address to) private {
        /// check and effects
        _burn(msg.sender, amount); /// subtract internal balance first

        /// interaction
        USDC.safeTransfer(to, amount); /// pay out USDC

        emit Redeem(msg.sender, amount);
    }

    function _mint(uint256 amount, address to) private {
        /// check and effects
        USDC.safeTransferFrom(msg.sender, address(this), amount); /// sender always pays
        _mint(to, amount); /// mint WUSDC

        emit Mint(msg.sender, amount);
    }
}