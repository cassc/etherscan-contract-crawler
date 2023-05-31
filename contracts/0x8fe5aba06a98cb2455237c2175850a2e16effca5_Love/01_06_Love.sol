// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0<0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Love is ERC20, Ownable {

  
     bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;
   
    
    constructor() ERC20("LOVE", "LV") {
         _mint(msg.sender, 3800000000 * 10 ** decimals());
    }

   


    function blacklist(address _address,bool _isBlacklisting) external onlyOwner{
        blacklists[_address] = _isBlacklisting;
    }
    function setRule(bool _limited,address _uniswapV2Pair,uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    
      
    

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
     ) override internal virtual {
        require(!blacklists[to] && !blacklists[from],"Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <=maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }
    
   
    
}