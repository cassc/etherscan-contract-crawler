// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Pankeki is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;

    bool public tradingOpen;
    bool private _swapping;
    bool public swapEnabled;

    uint256 private constant _totalSupply = 10_000_000 * (10**18);

    uint256 public maxBuyAmnt = _totalSupply.mul(12).div(1000);
    uint256 public maxSellAmnt = _totalSupply.mul(12).div(1000);
    uint256 public maxWalletAmnt = _totalSupply.mul(12).div(1000);

    uint256 public swapFee = 8;
    uint256 private _previousSwapFee = swapFee;

    uint256 private _tokensForSwapFee;
    uint256 private _swapTokensAtAmount = _totalSupply.mul(7).div(10000);

    address payable private swapFeeCollector;
    address private _uniswapV2Pair;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    
    constructor () ERC20("Pankeki", "KEKI") {
        _uniswapV2Router = IUniswapV2Router02(0xEfF92A263d31888d860bD50809A8D171709b7b1c);
        _approve(address(this), address(_uniswapV2Router), _totalSupply);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);

        swapFeeCollector = payable(_msgSender());

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[DEAD] = true;

        _mint(owner(), _totalSupply);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != ZERO, "KEKI: transfer from the zero address");
        require(to != ZERO, "KEKI: transfer to the zero address");
        require(amount > 0, "KEKI: Transfer amount must be greater than zero");

        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !_swapping) {
            if(!tradingOpen) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "KEKI: Trading is not allowed yet.");

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxBuyAmnt, "KEKI: Transfer amount exceeds the maxBuyAmnt.");
                require(balanceOf(to) + amount <= maxWalletAmnt, "KEKI: Exceeds maximum wallet token amount.");
            }
            
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxSellAmnt, "KEKI: Transfer amount exceeds the maxSellAmnt.");
                
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = (contractBalance > _swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !_swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            _swapping = true;
            _swapBack(contractBalance);
            _swapping = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapBack(uint256 contractBalance) internal {
        if (contractBalance == 0 || _tokensForSwapFee == 0) return;

        if (contractBalance > _swapTokensAtAmount * 5) contractBalance = _swapTokensAtAmount * 5;

        _swapTokensForETH(contractBalance); 
        
        _tokensForSwapFee = 0;
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            swapFeeCollector,
            block.timestamp
        );
    }

    function _removeSwapFee() internal {
        if (swapFee == 0) return;
        _previousSwapFee = swapFee;
        swapFee = 0;
    }
    
    function _restoreSwapFee() internal {
        swapFee = _previousSwapFee;
    }
        
    function _tokenTransfer(address from, address to, uint256 amount, bool takeFee) internal {
        if (!takeFee) _removeSwapFee();
        else amount = _takeSwapFees(from, amount);

        super._transfer(from, to, amount);
        
        if (!takeFee) _restoreSwapFee();
    }

    function _takeSwapFees(address from, uint256 amount) internal returns (uint256) {
        if (swapFee > 0) {
            uint256 fees = amount.mul(swapFee).div(100);
            _tokensForSwapFee += fees * swapFee / swapFee;

            if (fees > 0) super._transfer(from, address(this), fees);

            amount -= fees;
        }

        return amount;
    }
    
    function openTrading() public onlyOwner {
        require(!tradingOpen,"KEKI: Trading is already open");
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        tradingOpen = true;
    }

    function setBuyAmnt(uint256 _maxBuyAmnt) public onlyOwner {
        require(_maxBuyAmnt >= (totalSupply().mul(1).div(1000)), "KEKI: Max buy amount cannot be lower than 0.1% total supply.");
        maxBuyAmnt = _maxBuyAmnt;
    }

    function setSellAmnt(uint256 _maxSellAmnt) public onlyOwner {
        require(_maxSellAmnt >= (totalSupply().mul(1).div(1000)), "KEKI: Max sell amount cannot be lower than 0.1% total supply.");
        maxSellAmnt = _maxSellAmnt;
    }
    
    function setWalletAmnt(uint256 _maxWalletAmnt) public onlyOwner {
        require(_maxWalletAmnt >= (totalSupply().mul(1).div(100)), "KEKI: Max wallet amount cannot be lower than 1% total supply.");
        maxWalletAmnt = _maxWalletAmnt;
    }
    
    function setSwapTokensAtAmount(uint256 _swapAmountAmnt) public onlyOwner {
        require(_swapAmountAmnt >= (totalSupply().mul(1).div(100000)), "KEKI: Swap amount cannot be lower than 0.001% total supply.");
        require(_swapAmountAmnt <= (totalSupply().mul(5).div(1000)), "KEKI: Swap amount cannot be higher than 0.5% total supply.");
        _swapTokensAtAmount = _swapAmountAmnt;
    }

    function setSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function setSwapFeeCollector(address swapFeeCollectorAddy) public onlyOwner {
        require(swapFeeCollectorAddy != ZERO, "KEKI: swapFeeCollector address cannot be 0");
        swapFeeCollector = payable(swapFeeCollectorAddy);
        _isExcludedFromFees[swapFeeCollectorAddy] = true;
        _isExcludedMaxTransactionAmount[swapFeeCollectorAddy] = true;
    }

    function setExcludedFromFees(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = isEx;
    }
    
    function setExcludeFromMaxTransaction(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedMaxTransactionAmount[accounts[i]] = isEx;
    }

    function rescueETH() public onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function rescueTokens(address tokenAddy) public onlyOwner {
        require(IERC20(tokenAddy).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tokenAddy).balanceOf(address(this));
        IERC20(tokenAddy).transfer(msg.sender, amount);
    }

    receive() external payable {}
    fallback() external payable {}

}