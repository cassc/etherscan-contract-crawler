// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./interfaces/ISynth.sol";

/**
 * @dev Synthesis must be owner of this contract.
 */
contract SynthERC20 is ISynthERC20, Ownable, ERC20Permit {
    
    /// @dev original token address
    address public originalToken;
    /// @dev original token chain id
    uint64 public chainIdFrom;
    /// @dev original chain symbol
    string public chainSymbolFrom;
    /// @dev synth type
    uint8 public synthType;
    /// @dev cap (max possible supply)
    uint256 public cap;
    /// @dev synth token address for backward compatibility with ISynthAdapter (which may has backed third-party synth)
    address public synthToken;

    /// @dev synth decimals
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address originalToken_,
        uint64 chainIdFrom_,
        string memory chainSymbolFrom_,
        SynthType synthType_
    ) ERC20Permit("EYWA") ERC20(name_, symbol_) {
        originalToken = originalToken_;
        chainIdFrom = chainIdFrom_;
        chainSymbolFrom = chainSymbolFrom_;
        _decimals = decimals_;
        synthType = uint8(synthType_);
        cap = 2 ** 256 - 1;
        synthToken = address(this);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function setCap(uint256 cap_) external onlyOwner {
        require(ERC20.totalSupply() <= cap_, "SynthERC20: cap exceeded");
        cap = cap_;
        emit CapSet(cap);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function mintWithAllowanceIncrease(
        address account,
        address spender,
        uint256 amount
    ) external onlyOwner {
        _mint(account, amount);
        _approve(account, spender, allowance(account, spender) + amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function burnWithAllowanceDecrease(
        address account,
        address spender,
        uint256 amount
    ) external onlyOwner {
        uint256 currentAllowance = allowance(account, spender);
        require(currentAllowance >= amount, "ERC20: decreased allowance below zero");

        _approve(account, spender, currentAllowance - amount);
        _burn(account, amount);
    }

    function decimals() public view override (ISynthAdapter, ERC20) returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap, "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}