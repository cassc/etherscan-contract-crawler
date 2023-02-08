// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MQFShares is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 500000000000;
    uint256 public constant MAX_SUPPLY = 1000000000000;
    uint256 public constant MIN_MINT_PER_TX = 5000000000;
    uint256 public constant MAX_MINT_PER_TX = 25000000000;
    address public constant OWNER = 0x47B2fe2AFe990D7C6BF01bc9631ac399E7386A7b;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    using SafeERC20 for ERC20;

    constructor() ERC20("MQF Shares", "MQFS") {
        _mint(OWNER, INITIAL_SUPPLY);
    }

    function decimals() public pure override returns (uint8) {
		return 6;
	}

    function mint(uint256 _amount, bool _usdc) public {
        require(_amount >= MIN_MINT_PER_TX, "Amount is too small");
        require(_amount <= MAX_MINT_PER_TX, "Amount is too large");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Amount exceeds max supply");
        if (_usdc == true) {
            ERC20(USDC).transferFrom(msg.sender, OWNER, _amount);
        }
        if (_usdc == false) {
            ERC20(USDT).safeTransferFrom(msg.sender, OWNER, _amount);
        }
        _mint(msg.sender, _amount);
    }
}