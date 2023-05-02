// SPDX-License-Identifier: MIT

/*


██████╗ ██████╗ ██████╗ ███████╗██████╗ ███████╗
██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝
██║  ██║██████╔╝██████╔╝█████╗  ██████╔╝█████╗  
██║  ██║██╔══██╗██╔═══╝ ██╔══╝  ██╔═══╝ ██╔══╝  
██████╔╝██║  ██║██║     ███████╗██║     ███████╗
╚═════╝ ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝     ╚══════╝
                                                
TG: t.me/DrPePe_ETH 
TW: twitter.com/drpepecoineth
Web: drpepe.app

*/


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DrPepe is ERC20, Ownable {

    uint256 private _totalSupply = 10 * 1e9 * 10**18;

    mapping(address => bool) public blacklists;
    
    address public uniswapV2Pair;
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool public maxTxAmountEnabled = false;
    uint256 public maxTxAmount;
    

    uint256 public liquidityFee = 2;
    bool public liquidityFeeEnabled = true;
    address public marketing;

    constructor() ERC20("DrPepe", "DRPEPE") {
        _mint(msg.sender, _totalSupply);
    }

    function setMarketing(address _marketing) external onlyOwner {
        marketing = _marketing;
    }

    function setPair( address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;        
    }

    

    function setMaxTxAmount(uint256 _max) external onlyOwner {
        if (_max == 0) {
            maxTxAmountEnabled = false;
        } else {
            maxTxAmount = _max;
            maxTxAmountEnabled =true;
        }
        
    }

    function setLiquidityFeePercent(uint256 _liquidityFee) external onlyOwner {
        require(_liquidityFee <= 2, "Maximum liquidity fee is 2%");
        liquidityFee = _liquidityFee;
    }

    function setLiquidityFee(bool _enable) external onlyOwner {
       liquidityFeeEnabled = _enable;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 _amount = amount;

        if (to == uniswapV2Pair && owner != address(uniswapV2Router)) {
           // Sale 
           
           if (liquidityFeeEnabled) {
              // Apply liquidityFee if enabled
              uint256 fee = amount * liquidityFee/100;
              _amount = amount - fee;
              _transfer(owner, address(this), fee);
           }
        }

        _transfer(owner, to, _amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        uint256 _amount = amount;

        if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
           // Sale 
           
           if (liquidityFeeEnabled) {
              // Apply liquidityFee if enabled
              uint256 fee = amount * liquidityFee/100;
              _amount = amount - fee;
              _transfer(from, address(this), fee);
             
           }
        }

        _transfer(from, to, _amount);
        return true;
    }


    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading has not started yet");
            return;
        }

        if(maxTxAmountEnabled && from != owner() && to != owner())
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

    }

    function getLiquidityFee() external onlyOwner {
        ERC20(this).transfer(marketing, ERC20(this).balanceOf(address(this)));
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
    

}