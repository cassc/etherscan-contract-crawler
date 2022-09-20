/*
    https://oneeyedshiba.com
    https://t.me/OneEyedShibaPortal
    https://twitter.com/oeshib
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract OneEyedShiba is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router;

    mapping (address => uint) private _cooldown;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;

    bool public tradingOpen;
    bool private _swapping;
    bool public swapEnabled = false;
    bool public cooldownEnabled = false;
    bool public feesEnabled = true;

    string private constant _name = "One-eyed Shiba";
    string private constant _symbol = "OES";

    uint8 private constant _decimals = 18;

    uint256 private constant _totalSupply = 1e12 * (10**_decimals);

    uint256 public mxBuy = _totalSupply;
    uint256 public mxSell = _totalSupply;
    uint256 public mxWallet = _totalSupply;

    uint256 public launchBlock = 0;
    uint256 private _blocksToBlacklist = 0;
    uint256 private _cooldownBlocks = 0;

    uint256 public constant FEE_DIVISOR = 1000;

    uint256 public buyFee = 50;
    uint256 private _previousBuyFee = buyFee;
    uint256 public sellFee = 50;
    uint256 private _previousSellFee = sellFee;

    uint256 private _tokensForFee;
    uint256 private _swapTokensAtAmount = 0;

    address payable private feeWalletAddress;

    address private _uniswapV2Pair;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    
    constructor () {
        feeWalletAddress = payable(_msgSender());

        _balances[_msgSender()] = _totalSupply;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[DEAD] = true;

        emit Transfer(ZERO, _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        _checkERC20Basics(from, to, amount);
        bool shouldSwap = false;

        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !_swapping) _checkLimits(from, to, amount, shouldSwap);

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !feesEnabled) takeFee = false;

        bool canSwap = ((balanceOf(address(this))) > _swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !_swapping && takeFee) {
            _swapping = true;
            _swapBack();
            _swapping = false;
        }

        _tokenTransfer(from, to, amount, takeFee, shouldSwap);
    }

    function _checkERC20Basics(address from, address to, uint256 amount) private view {
        require(from != ZERO, "ERC20: Transfer from the zero address");
        require(to != ZERO, "ERC20: Transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
    }

    function _checkLimits(address from, address to, uint256 amount, bool shouldSwap) private {

        _checkTradingOpen(from, to);

        _checkCooldown(to);

        _checkBuyLimits(from, to, amount);

        _checkSellLimits(from, to, amount, shouldSwap);

    }

    function _checkTradingOpen(address from, address to) private view {
        if(!tradingOpen) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "ERC20: Trading is not allowed yet");
    }

    function _checkCooldown(address to) private {
        if (cooldownEnabled) {
            if (to != address(_uniswapV2Router) && to != address(_uniswapV2Pair)) {
                require(_cooldown[tx.origin] < block.number - _cooldownBlocks && _cooldown[to] < block.number - _cooldownBlocks, "ERC20: Transfer delay enabled. Try again later.");
                _cooldown[tx.origin] = block.number;
                _cooldown[to] = block.number;
            }
        }
    }

    function _checkBuyLimits(address from, address to, uint256 amount) private view {
        if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[to]) {
            require(amount <= mxBuy, "ERC20: Transfer amount exceeds the mxBuy");
            require(balanceOf(to) + amount <= mxWallet, "ERC20: Exceeds maximum wallet token amount");
        }
    }

    function _checkSellLimits(address from, address to, uint256 amount, bool shouldSwap) private view {
        if (to == _uniswapV2Pair && from != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[from]) {
            require(amount <= mxSell, "ERC20: Transfer amount exceeds the mxSell.");
            shouldSwap = true;
        }
    }

    function _swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        
        if (contractBalance == 0 || _tokensForFee == 0) return;

        if (contractBalance > _swapTokensAtAmount * 5) contractBalance = _swapTokensAtAmount * 5;

        swapTokensForETH(contractBalance); 
        
        _tokensForFee = 0;
        
        (success,) = address(feeWalletAddress).call{value: address(this).balance}("");
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        feeWalletAddress.transfer(amount);
    }

    function removeAllFee() private {
        if (buyFee == 0 && sellFee == 0) return;

        _previousBuyFee = buyFee;
        _previousSellFee = sellFee;
        
        buyFee = 0;
        sellFee = 0;
    }
    
    function restoreAllFee() private {
        buyFee = _previousBuyFee;
        sellFee = _previousSellFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if (!takeFee) removeAllFee();
        else amount = _takeFees(sender, amount, isSell);

        _transferStandard(sender, recipient, amount);
        
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        if (launchBlock + _blocksToBlacklist >= block.number) _totalFees = _getBotFees();
        else _totalFees = _getTotalFees(isSell);
        
        uint256 fees;
        if (_totalFees > 0) {
            fees = amount.mul(_totalFees).div(FEE_DIVISOR);
            _tokensForFee += fees * _totalFees / _totalFees;
        }
            
        if (fees > 0) _transferStandard(sender, address(this), fees);
            
        return amount -= fees;
    }

    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) return sellFee;
        return buyFee;
    }

    function _getBotFees() private pure returns(uint256) {
        return 899;
    }

    receive() external payable {}
    fallback() external payable {}

    function launch(uint256 blocks) public onlyOwner {
        require(!tradingOpen,"ERC20: Trading is already open");
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapV2Router), _totalSupply);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        mxBuy = _totalSupply.mul(1).div(100);
        mxSell = _totalSupply.mul(1).div(100);
        mxWallet = _totalSupply.mul(2).div(100);
        _swapTokensAtAmount = _totalSupply.mul(1).div(1000);
        tradingOpen = true;
        launchBlock = block.number;
        _blocksToBlacklist = blocks;
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
    }
    
    function setCooldownEnabled(bool onoff) public onlyOwner {
        cooldownEnabled = onoff;
    }

    function setSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function setFeesEnabled(bool onoff) public onlyOwner {
        feesEnabled = onoff;
    }    
    
    function setMaxBuy(uint256 amount) public onlyOwner {
        require(amount >= (totalSupply().mul(1).div(10000)), "ERC20: Max buy cannot be lower than 0.01% total supply");
        mxBuy = amount;
    }

    function setMaxSell(uint256 amount) public onlyOwner {
        require(amount >= (totalSupply().mul(1).div(10000)), "ERC20: Max sell cannot be lower than 0.01% total supply");
        mxSell = amount;
    }
    
    function setMaxWallet(uint256 amount) public onlyOwner {
        require(amount >= (totalSupply().mul(1).div(1000)), "ERC20: Max wallet cannot be lower than 0.1% total supply");
        mxWallet = amount;
    }
    
    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        require(amount >= (totalSupply().mul(1).div(100000)), "ERC20: Swap amount cannot be lower than 0.001% total supply");
        require(amount <= (totalSupply().mul(5).div(1000)), "ERC20: Swap amount cannot be higher than 0.5% total supply");
        _swapTokensAtAmount = amount;
    }

    function setFeeWalletAddress(address feeWalletAddy) public onlyOwner {
        require(feeWalletAddy != ZERO, "ERC20: feeWalletAddress address cannot be 0");
        feeWalletAddress = payable(feeWalletAddy);
        _isExcludedFromFees[feeWalletAddress] = true;
        _isExcludedMaxTransactionAmount[feeWalletAddress] = true;
    }

    function setBuyFee(uint256 newbuyFee) public onlyOwner {
        require(newbuyFee <= 100, "ERC20: Must keep buy taxes below 10%");
        buyFee = newbuyFee;
    }

    function setSellFee(uint256 newsellFee) public onlyOwner {
        require(newsellFee <= 100, "ERC20: Must keep sell taxes below 10%");
        sellFee = newsellFee;
    }

    function setCooldownBlocks(uint256 blocks) public onlyOwner {
        _cooldownBlocks = blocks;
    }

    function removeLimits() public onlyOwner {
        mxBuy = _totalSupply;
        mxSell = _totalSupply;
        mxWallet = _totalSupply;
        cooldownEnabled = false;
    }

    function excludeFromFees(address[] memory accounts, bool booly) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = booly;
    }
    
    function excludeFromMaxTransaction(address[] memory accounts, bool booly) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedMaxTransactionAmount[accounts[i]] = booly;
    }

    function manualUnclog() public {
        require(msg.sender == feeWalletAddress, "ERC20: Unauthorized");
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForETH(contractBalance);
    }
    
    function manualDistributeFees() public {
        require(msg.sender == feeWalletAddress, "ERC20: Unauthorized");
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function rescueETH() public {
        require(msg.sender == feeWalletAddress, "ERC20: Unauthorized.");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function rescueTokens(address tknAddy) public {
        require(msg.sender == feeWalletAddress, "ERC20: Unauthorized");
        require(tknAddy != address(this), "ERC20: Cannot withdraw this token");
        require(IERC20(tknAddy).balanceOf(address(this)) > 0, "ERC20: No tokens");
        uint amount = IERC20(tknAddy).balanceOf(address(this));
        IERC20(tknAddy).transfer(msg.sender, amount);
    }

}