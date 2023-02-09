// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ZORDON is Context, ERC20, Ownable {

    using SafeMath for uint256;
    IUniswapV2Router02 private _uniswapV2Router;
    mapping (address => bool) private _excludedFees;
    mapping (address => bool) private _excludedLimits;
    bool public tradingEnabled;
    bool public swapEnabled;
    bool private _swapping;
    bool public initialized;
    bool public prepared;
    bool public ff;
    uint256 private constant _tSupply = 1e12 ether;
    uint256 public maxWallet = _tSupply;
    uint256 private _fee;
    uint256 public buyFee = 5;
    uint256 private _previousBuyFee = buyFee;
    uint256 public sellFee = 5;
    uint256 private _previousSellFee = sellFee;
    uint256 private _tokensForFee;
    address payable private _feeReceiver;
    address private _uniswapV2Pair;

    modifier lockSwap { _swapping = true; _; _swapping = false; }
    
    constructor() ERC20("ZORDON", "ZORDON") {

        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapV2Router), totalSupply());
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);

        _feeReceiver = payable(owner());
        _excludedFees[owner()] = true;
        _excludedFees[address(this)] = true;
        _excludedFees[address(0)] = true;
        _excludedFees[address(0xdead)] = true;

        _excludedLimits[owner()] = true;
        _excludedLimits[address(this)] = true;
        _excludedLimits[address(0)] = true;
        _excludedLimits[address(0xdead)] = true;

        // Can only be called during deployment
        _mint(owner(), _tSupply);
    }

    receive() external payable {}
    fallback() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ZORDON: transfer from the zero address.");
        require(to != address(0), "ZORDON: transfer to the zero address.");
        require(amount > 0, "ZORDON: transfer amount is zero.");

        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_swapping) {
            if(!tradingEnabled) require(_excludedFees[from] || _excludedFees[to]);
            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_excludedLimits[to]) require(balanceOf(to) + amount <= maxWallet);
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router)) shouldSwap = true;
        }

        if(_excludedFees[from] || _excludedFees[to]) takeFee = false;

        if (shouldSwap && swapEnabled && !_swapping && !_excludedFees[from] && !_excludedFees[to]) _swapBack(balanceOf(address(this)));

        _token_transfer(from, to, amount, takeFee, shouldSwap);
    }

    function _swapBack(uint256 contractBalance) internal lockSwap {
        if (contractBalance == 0 || _tokensForFee == 0) return;
        _swapExactTokensForETH(contractBalance);
        _tokensForFee = 0;
        bool success;
        (success,) = address(_feeReceiver).call{value: address(this).balance}("");
    }

    function _swapExactTokensForETH(uint256 token_amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), token_amount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(token_amount, 0, path, address(this), block.timestamp);
    }

    function morphosis() public onlyOwner {
        require(initialized, "ZORDON: Not initialized.");
        require(!tradingEnabled, "ZORDON: Trading already open.");
        swapEnabled = true;
        maxWallet = totalSupply().mul(2).div(100);
        tradingEnabled = true;
    }

    function getReady() public onlyOwner {
        require(!initialized, "ZORDON: Initialized.");
        buyFee = 25;
        sellFee = 25;
        initialized = true;
    }

    function finalForm() public onlyOwner {
        require(!ff, "ZORDON: Final form activated.");
        buyFee = 5;
        sellFee = 5;
        maxWallet = totalSupply();
        ff = true;
    }

    function setSwapEnabled(bool en) public onlyOwner {
        swapEnabled = en;
    }

    function excludeFromFees(address[] memory accounts, bool ex) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _excludedFees[accounts[i]] = ex;
    }
    
    function excludeLimits(address[] memory accounts, bool ex) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _excludedLimits[accounts[i]] = ex;
    }

    function _noToAllFees() internal {
        if (buyFee == 0 && sellFee == 0) return;
        _previousBuyFee = buyFee;
        _previousSellFee = sellFee;
        buyFee = 0;
        sellFee = 0;
    }
    
    function _yesToAllFees() internal {
        buyFee = _previousBuyFee;
        sellFee = _previousSellFee;
    }
        
    function _token_transfer(address sender, address recipient, uint256 amount, bool takeFee, bool sell) internal {
        if (!takeFee) _noToAllFees();
        else amount = _takeFees(sender, amount, sell);
        super._transfer(sender, recipient, amount);
        if (!takeFee) _yesToAllFees();
    }

    function _takeFees(address sender, uint256 amount, bool sell) internal returns (uint256) {
        if (sell) _fee = sellFee;
        else _fee = buyFee;
        
        uint256 fees;
        if (_fee > 0) {
            fees = amount.mul(_fee).div(100);
            _tokensForFee += fees * _fee / _fee;
        }

        if (fees > 0) super._transfer(sender, address(this), fees);
        return amount -= fees;
    }

    function unclog() public lockSwap {
        require(_msgSender() == _feeReceiver, "ZORDON: Forbidden.");
        _swapExactTokensForETH(balanceOf(address(this)));
        _tokensForFee = 0;
        bool success;
        (success,) = address(_feeReceiver).call{value: address(this).balance}("");
    }

    function unstuckTokens(address tkn) public {
        require(_msgSender() == _feeReceiver, "ZORDON: Forbidden.");
        require(tkn != address(this), "ZORDON: Unable to pull unstuck token.");
        bool success;
        if (tkn == address(0)) (success, ) = address(_feeReceiver).call{value: address(this).balance}("");
        else {
            require(IERC20(tkn).balanceOf(address(this)) > 0);
            uint amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }

}