// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";

contract TMDToken is ERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "TMD/not-authorized");
        _;
    }

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private usdt = 0x55d398326f99059fF775485246999027B3197955;
    address private uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public uniswapV2Pair;
    address public exchequer;
    uint256 public swapTokensAtAmount = 1000 * 1E18;
    uint256 public start;
    bool public openbuy;
    bool private swapping;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
  
    constructor() public ERC20("Talmud", "TMD") {
        wards[msg.sender] = 1;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Factory).createPair(address(this), usdt);
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        _mint(owner(), 1120000*1e18);
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }
    function setStart(uint256 time) external auth{
        start = time;
	}
    function setExchequer(address newexchequer) external auth{
        exchequer = newexchequer;
	}
    function setOpen() external auth{
        openbuy = !openbuy;
	}
    function setSwapTokensAtAmount(uint256 wad) external auth{
        swapTokensAtAmount = wad;
	}
    function excludeFromFees(address account, bool excluded) public auth {
        require(_isExcludedFromFees[account] != excluded, "TMD: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) public auth {
        require(automatedMarketMakerPairs[pair] != value, "TMD: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function init() public {
        IERC20(address(this)).approve(uniswapV2Router, ~uint256(0));
        IERC20(usdt).approve(uniswapV2Router, ~uint256(0));
    }
    function _transfer(address from,address to,uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && !swapping && !automatedMarketMakerPairs[from]) {
            swapping = true;
            super._transfer(address(this), deadWallet, contractTokenBalance.mul(1).div(6));
            swapTokensForUsdt(balanceOf(address(this)));
            swapping = false;
        }

        if((automatedMarketMakerPairs[to] && !_isExcludedFromFees[from]) ||
                 (automatedMarketMakerPairs[from] && !_isExcludedFromFees[to])) {
            if(!openbuy)  revert("TMD/Cannot be bought");
            bool open = (start == 0 || block.timestamp < start +1800);
            uint256 fee = amount.mul(3).div(100);
            if(open) fee = amount.mul(25).div(100);
            super._transfer(from, address(this), fee);
            if(open) super._transfer(address(this), deadWallet, fee.mul(22).div(25));
            amount = amount.sub(fee);
        }
        super._transfer(from, to, amount);       
    }
    function swapTokensForUsdt(uint256 tokenAmount) internal{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            exchequer,
            block.timestamp
        );
    }

    function withdraw(address asses, uint256 amount, address ust) public auth {
        IERC20(asses).transfer(ust, amount);
    }
}
contract TMTToken is ERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "TMT/not-authorized");
        _;
    }

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private usdt = 0x55d398326f99059fF775485246999027B3197955;
    address private uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public uniswapV2Pair;
    address public tmd;
    uint256 public swapTokensAtAmount = 10000 * 1E18;
    uint256 public start;
    bool public openbuy;
    bool private swapping;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
  
    constructor() public ERC20("Talmud", "TMT") {
        wards[msg.sender] = 1;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Factory).createPair(address(this), usdt);
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        _mint(owner(), 6*1e8*1e18);
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }
    function setStart(uint256 time) external auth{
        start = time;
	}
    function setTmd(address newtmd) external auth{
        tmd = newtmd;
	}
    function setOpen() external auth{
        openbuy = !openbuy;
	}
    function setSwapTokensAtAmount(uint256 wad) external auth{
        swapTokensAtAmount = wad;
	}
    function excludeFromFees(address account, bool excluded) public auth {
        require(_isExcludedFromFees[account] != excluded, "TMT: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) public auth {
        require(automatedMarketMakerPairs[pair] != value, "TMT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function init() public {
        IERC20(address(this)).approve(uniswapV2Router, ~uint256(0));
        IERC20(usdt).approve(uniswapV2Router, ~uint256(0));
    }
    function _transfer(address from,address to,uint256 amount) internal override {
        require(from != address(0), "TMT: transfer from the zero address");
        require(to != address(0), "TMT: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && !swapping && !automatedMarketMakerPairs[from]) {
            swapping = true;
            swapTokensForUsdt(balanceOf(address(this)));
            swapping = false;
        }

        if((automatedMarketMakerPairs[to] && !_isExcludedFromFees[from]) ||
                 (automatedMarketMakerPairs[from] && !_isExcludedFromFees[to])) {
            if(!openbuy)  revert("TMT/Cannot be bought");
            bool open = (start == 0 || block.timestamp < start +1800);
            uint256 fee = amount.mul(2).div(100);
            if(open) fee = amount.mul(25).div(100);
            super._transfer(from, address(this), fee);
            if(open) super._transfer(address(this), deadWallet, fee.mul(23).div(25));
            amount = amount.sub(fee);
        }
        super._transfer(from, to, amount);       
    }
    function swapTokensForUsdt(uint256 tokenAmount) internal{
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = usdt;
        path[2] = tmd;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            deadWallet,
            block.timestamp
        );
    }

    function withdraw(address asses, uint256 amount, address ust) public auth {
        IERC20(asses).transfer(ust, amount);
    }
}