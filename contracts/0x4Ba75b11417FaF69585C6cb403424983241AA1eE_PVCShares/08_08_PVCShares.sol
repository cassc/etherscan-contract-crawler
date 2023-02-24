// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PVCShares is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 1500000000000;
    uint256 public constant MAX_SUPPLY = 2000000000000;
    uint256 public constant MIN_MINT_PER_TX = 10000000000;
    uint256 public constant MAX_MINT_PER_TX = 25000000000;
    address public constant OWNER = 0x599D84ED5a575Ac6e91D58B7D409b6BEdd2404A9;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    using SafeERC20 for ERC20;

    constructor() ERC20("PVC Shares", "PVCS") {
        _mint(OWNER, INITIAL_SUPPLY);
    }

    function decimals() public pure override returns (uint8) {
		return 6;
	}

    function mint(uint256 _amount, bool _usdc) external {
        require(_amount >= MIN_MINT_PER_TX, "Amount is too small");
        require(_amount <= MAX_MINT_PER_TX, "Amount is too large");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Amount exceeds max supply");
        uint256 estimatedPrice = _calculatePrice(totalSupply() - INITIAL_SUPPLY);
        uint256 estimatedAmount = (_amount * estimatedPrice) / 1000;
        if (_usdc == true) {
            ERC20(USDC).transferFrom(msg.sender, OWNER, estimatedAmount);
        }
        if (_usdc == false) {
            ERC20(USDT).safeTransferFrom(msg.sender, OWNER, estimatedAmount);
        }
        _mint(msg.sender, _amount);
    }

    function getCurrentPrice() external view returns (uint256) {
        uint256 currentSupply = totalSupply();
        uint256 price = _calculatePrice(currentSupply - INITIAL_SUPPLY);
        return price;
    }

    function _calculatePrice(uint256 _amount) internal pure returns (uint256) {
        uint256 price = 0;
        if (_amount < 25000000000) {
            price = 950;
        } else if (_amount < 50000000000) {
            price = 960;
        } else if (_amount < 75000000000) {
            price = 970;
        } else if (_amount < 100000000000) {
            price = 980;
        } else if (_amount < 150000000000) {
            price = 990;
        } else if (_amount < 250000000000) {
            price = 1000;
        } else if (_amount < 300000000000) {
            price = 1010;
        } else if (_amount < 350000000000) {
            price = 1020;
        } else if (_amount < 400000000000) {
            price = 1030;
        } else if (_amount < 450000000000) {
            price = 1040;
        } else {
            price = 1050;
        }
        return price;
    }
}