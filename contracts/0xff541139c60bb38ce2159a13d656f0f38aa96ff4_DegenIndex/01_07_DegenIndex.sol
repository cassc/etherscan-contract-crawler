// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Degen Index Token
/// @author no-op.eth // xlmoose.eth
contract DegenIndex is Ownable, Pausable, ERC20 {
    /// Total amount of tokens
    uint256 public constant TOTAL_SUPPLY = 100_000_000 ether;
    /// Allocation for LPs
    uint256 public constant LIQUIDITY = TOTAL_SUPPLY * 95 / 100;
    /// Reserve amount of tokens for developers
    uint256 public constant RESERVE = TOTAL_SUPPLY * 5 / 100;

    /// Amount must be greater than zero
    error NoZeroTransfers();
    /// Paused
    error ContractPaused();

    constructor(address _dev) ERC20("Degen Index", "DI") {
        _mint(msg.sender, LIQUIDITY);
        _mint(_dev, RESERVE);

        _pause();
    }

    /// @notice Pause trading
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause trading
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Hook that is called before any transfer of tokens.  This includes
     * minting and burning.
     *
     * Checks:
     * - transfer amount is non-zero
     * - contract is not paused.
     * - owner allowed to set up LP during pause.
     */
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        if (amount == 0) revert NoZeroTransfers();
        if (paused() && (owner() != sender && owner() != recipient)) revert ContractPaused();
        super._beforeTokenTransfer(sender, recipient, amount);
    }
}