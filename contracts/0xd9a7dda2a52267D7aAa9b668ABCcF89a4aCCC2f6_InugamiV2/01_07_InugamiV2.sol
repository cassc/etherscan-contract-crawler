// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*                                                          
@@@  @@@  @@@  @@@  @@@   @@@@@@@@   @@@@@@   @@@@@@@@@@   @@@  
@@@  @@@@ @@@  @@@  @@@  @@@@@@@@@  @@@@@@@@  @@@@@@@@@@@  @@@  
@@!  @@[email protected][email protected]@@  @@!  @@@  [email protected]@        @@!  @@@  @@! @@! @@!  @@!  
[email protected]!  [email protected][email protected][email protected]!  [email protected]!  @[email protected]  [email protected]!        [email protected]!  @[email protected]  [email protected]! [email protected]! [email protected]!  [email protected]!  
[email protected]  @[email protected] [email protected]!  @[email protected]  [email protected]!  [email protected]! @[email protected][email protected]  @[email protected][email protected][email protected]!  @!! [email protected] @[email protected]  [email protected]  
!!!  [email protected]!  !!!  [email protected]!  !!!  !!! [email protected]!!  [email protected]!!!!  [email protected]!   ! [email protected]!  !!!  
!!:  !!:  !!!  !!:  !!!  :!!   !!:  !!:  !!!  !!:     !!:  !!:  
:!:  :!:  !:!  :!:  !:!  :!:   !::  :!:  !:!  :!:     :!:  :!:  
 ::   ::   ::  ::::: ::   ::: ::::  ::   :::  :::     ::    ::  
:    ::    :    : :  :    :: :: :    :   : :   :      :    :    

Contract - https://t.me/geimskip
*/

import "./Uniswap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract InugamiV2 is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excludedFromRewardAddresses;
    
    bool public canTrade = false;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**18 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    address public marketingWallet;

    string private _name = "Inugami";
    string private _symbol = "INUGAMI";
    uint8 private _decimals = 18;
    
    uint256 public _reflectionTaxPercent = 2;
    uint256 private _previousReflectionTaxPercent = _reflectionTaxPercent;
    
    uint256 public _liquidityAndMarketingPercent = 8;
    uint256 private _previousLiquidityAndMarketingPercent = _liquidityAndMarketingPercent;
    uint256 public percentToMarketing = 50;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 public _maxTxAmount = 15 * _tTotal / 1000;  // 1.5% of total supply
    uint256 public swapTokenThreshold = 5 * _tTotal / 10000; // 0.05% of total supply
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[msg.sender] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        marketingWallet = owner();

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(balanceOf(sender) >= amount, "Insufficient balance");
        require(allowance(sender, msg.sender) >= amount, "Insufficient authorisation");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromRewardAddresses.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < _excludedFromRewardAddresses.length; i++) {
            if (_excludedFromRewardAddresses[i] == account) {
                _excludedFromRewardAddresses[i] = _excludedFromRewardAddresses[_excludedFromRewardAddresses.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromRewardAddresses.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function fullExclude(address account) public onlyOwner {
        excludeFromFee(account);
        excludeFromReward(account);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setPercentToMarketing(uint256 fee) public onlyOwner {
        percentToMarketing = fee;
    }

    function setMarketingWallet(address walletAddress) public onlyOwner {
        marketingWallet = walletAddress;
    }
    
    function setReflectionTaxPercent(uint256 reflectionPercent) external onlyOwner() {
        _reflectionTaxPercent = reflectionPercent;
    }
    
    function setLiquidityAndMarketingPercent(uint256 liquidityAndMarketingPercent) external onlyOwner() {
        _liquidityAndMarketingPercent = liquidityAndMarketingPercent;
    }
   
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }
    
    function setSwapThresholdAmount(uint256 SwapThresholdAmount) external onlyOwner() {
        swapTokenThreshold = SwapThresholdAmount;
    }
    
    function claimTokens(IERC20 tokenAddress, address walletaddress) external onlyOwner() {
        tokenAddress.transfer(walletaddress, tokenAddress.balanceOf(address(this)));
    }
    
    function claimBalance(address payable walletaddress) external onlyOwner() {
        walletaddress.transfer(address(this).balance);
    }
    
    function enableTrading() external onlyOwner() {
        require(!canTrade,"trading is already open");

        canTrade = true;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);

        swapAndLiquifyEnabled = true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateLiquidityAndMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromRewardAddresses.length; i++) {
            if (_rOwned[_excludedFromRewardAddresses[i]] > rSupply || _tOwned[_excludedFromRewardAddresses[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromRewardAddresses[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromRewardAddresses[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionTaxPercent).div(
            10**2
        );
    }

    function calculateLiquidityAndMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityAndMarketingPercent).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_reflectionTaxPercent == 0 && _liquidityAndMarketingPercent == 0) return;
        
        _previousReflectionTaxPercent = _reflectionTaxPercent;
        _previousLiquidityAndMarketingPercent = _liquidityAndMarketingPercent;
        
        _reflectionTaxPercent = 0;
        _liquidityAndMarketingPercent = 0;
    }
    
    function restoreAllFee() private {
        _reflectionTaxPercent = _previousReflectionTaxPercent;
        _liquidityAndMarketingPercent = _previousLiquidityAndMarketingPercent;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!isExcludedFromFee(from) && !isExcludedFromFee(to))
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= swapTokenThreshold;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function forceSwap() external onlyOwner {
        swapAndLiquify(balanceOf(address(this)));
    }

    function swapAndLiquify(uint256 tokensToUse) private lockTheSwap {
        uint256 marketingSell = tokensToUse.mul(percentToMarketing).div(100);
        uint256 tokensForLP = tokensToUse.sub(marketingSell);
        uint256 lpSell = tokensForLP.div(2);
        uint256 keepForLP = tokensForLP.sub(lpSell);

        uint256 tokensToSell = marketingSell.add(lpSell);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensToSell);
        uint256 ethRecieved = address(this).balance.sub(initialBalance);

        // Pay to marketing wallet
        uint256 marketingshare = ethRecieved.mul(marketingSell).div(tokensToSell);
        payable(marketingWallet).transfer(marketingshare);

        // Add liquidity to uniswap
        addLiquidity(keepForLP, ethRecieved.sub(marketingshare));

        emit SwapAndLiquify(tokensToSell, ethRecieved, keepForLP);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!canTrade){
            require(sender == owner(), "Trading not active, only owner can transfer"); // only owner allowed to trade or add liquidity
        }
        
        if(!takeFee)
            removeAllFee();
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function withdrawStuckEth() external onlyOwner {
        bool success;
        (success,) = address(owner()).call{value: address(this).balance}("");
    }

    function withdrawStuckTokens(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }
}