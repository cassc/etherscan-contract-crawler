// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
            .-'''-.                     
           '   _    \                   
/|       /   /` '.   \                  
||      .   |     \  '   _.._           
||      |   '      |  '.' .._|          
||  __  \    \     / / | '       __     
||/'__ '.`.   ` ..' /__| |__  .:--.'.   
|:/`  '. '  '-...-'`|__   __|/ |   \ |  
||     | |             | |   `" __ | |  
||\    / '             | |    .'.''| |  
|/\'..' /              | |   / /   | |_ 
'  `'-'`               | |   \ \._,\ '/ 
                       |_|    `--'  `"  
author: dragon dnoyf (it's french)
 */
contract BOFA is ERC20, Ownable {
    constructor () ERC20("BOFA", "BOFA") {
         _mint(msg.sender, TOTAL_SUPPLY);
    }

    mapping (address => bool) public gotEem;

    // SIX NINE DOT FOUR TWENTY BILLION
    uint256 constant public TOTAL_SUPPLY = 69420000000000000000000000000;

    bool public isLimited;
    uint256 public maxAmount;
    uint256 public minAmount;
    address public uniswapContract;
    address presaleContract;

    function toggleEem(address[] calldata eem) external onlyOwner {
        for (uint256 i = 0; i < eem.length; i++) {
            gotEem[eem[i]] = !gotEem[eem[i]];
        }
    }

    function setPresaleContract(address addr) external onlyOwner {
        presaleContract = addr;
    }

    function setRule(bool isLimited_, address uniswapContract_, uint256 max_, uint256 min_) external onlyOwner {
        isLimited = isLimited_;
        uniswapContract = uniswapContract_;
        maxAmount = max_;
        minAmount = min_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!gotEem[from] && !gotEem[to], "HA_GOT_EEM");

        if (uniswapContract == address(0)) {
            require(from == owner() || from == presaleContract || to == owner(), "TRADING_NOT_ACTIVE");
            return;
        }

        if (isLimited && from == uniswapContract) {
            require(super.balanceOf(to) + amount <= maxAmount && super.balanceOf(to) + amount >= minAmount, "FORBID");
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}