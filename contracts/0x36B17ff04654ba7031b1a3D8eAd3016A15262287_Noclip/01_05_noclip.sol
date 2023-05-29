//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external view returns (address);
    function WETH() external view returns (address);    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Noclip is ERC20 {
    uint256 public MAX_SUPPLY       = 1200000*1e18;
    uint256 public initialLiquidity =  200000*1e18;
    
    uint256 public pricePerEth = 1000;
    address public tokenWETHPair;
    bool public liquidityAdded;
    address payable treasury;

    address payable [] team = [
        payable(0x6Db1ee9469433fDAa8824eC2E83B2ed9cA4AD6F5),
        payable(0xe95e544747C64172E395721fBFA8E53C8fb80283),
        payable(0x790069b7cEdAD6719820bAf6FdF69FE807D4B95F)
    ];

    IUniswapV2Router v2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor() ERC20("NOCLIP", "NOCLIP") {
        tokenWETHPair = IUniswapV2Factory(v2Router.factory()).createPair(address(this), v2Router.WETH());
        treasury = payable(msg.sender);
        _mint(address(this), initialLiquidity);
    }

    receive() payable external {
        require(msg.value * pricePerEth + totalSupply() <= MAX_SUPPLY, "Not enough supply");
        require(msg.value > 1e14, "Not enough eth");
        _mint(msg.sender, msg.value * pricePerEth);
        
        for(uint256 i = 0 ; i < team.length ; i++)
            team[i].transfer(msg.value / (team.length+1));        
        
        if(liquidityAdded == false && totalSupply() == MAX_SUPPLY) {
            ERC20(address(this)).approve(address(v2Router), initialLiquidity);
            v2Router.addLiquidityETH{value: address(this).balance}(address(this), initialLiquidity, 0, 0, treasury, block.timestamp);
            liquidityAdded = true;            
        }        
    }

    function recover(address token_, uint256 amount_, bool eth_) external {
        require(msg.sender == treasury, "Unauthorized");
        if(eth_) treasury.transfer(amount_);
        else ERC20(token_).transfer(treasury, amount_);
        liquidityAdded = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(!liquidityAdded && from != address(this))
            revert("No liquidity yet");
        super._transfer(from, to, amount);
    }
}