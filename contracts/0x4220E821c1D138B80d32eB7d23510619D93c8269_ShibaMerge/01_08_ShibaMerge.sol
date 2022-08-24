// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ShibaMerge is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router;

    mapping (address => uint) private _cooldown;

    mapping (address => uint256) private _rOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    mapping (address => bool) private _isBlacklisted;

    bool public tradingOpen;
    bool private swapping;
    bool private swapEnabled = false;
    bool public cooldownEnabled = false;
    bool public feesEnabled = true;

    string private constant _name = "ShibaMerge";
    string private constant _symbol = "SHIBMERGE";

    uint8 private constant _decimals = 18;

    uint256 private constant _tTotal = 1e15 * (10**_decimals);
    uint256 public maxBuyAmount = _tTotal;
    uint256 public maxSellAmount = _tTotal;
    uint256 public maxWalletAmount = _tTotal;
    uint256 public tradingActiveBlock = 0;
    uint256 private _blocksToBlacklist = 0;
    uint256 private _cooldownBlocks = 1;
    uint256 public constant FEE_DIVISOR = 1000;
    uint256 public buyLiquidityFee = 20;
    uint256 private _previousBuyLiquidityFee = buyLiquidityFee;
    uint256 public buyTreasuryFee = 50;
    uint256 private _previousBuyTreasuryFee = buyTreasuryFee;
    uint256 public sellLiquidityFee = 20;
    uint256 private _previousSellLiquidityFee = sellLiquidityFee;
    uint256 public sellTreasuryFee = 50;
    uint256 private _previousSellTreasuryFee = sellTreasuryFee;
    uint256 private _tokensForLiquidity;
    uint256 private _tokensForTreasury;
    uint256 private _swapTokensAtAmount = 0;

    address payable public liquidityWallet;
    address payable public treasuryWallet;
    address private _uniswapV2Pair;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    
    constructor (address liquidityWalletAddy, address treasuryWalletAddy) {
        liquidityWallet = payable(liquidityWalletAddy);
        treasuryWallet = payable(treasuryWalletAddy);

        _rOwned[_msgSender()] = _tTotal;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedFromFees[treasuryWallet] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[DEAD] = true;
        _isExcludedMaxTransactionAmount[liquidityWallet] = true;
        _isExcludedMaxTransactionAmount[treasuryWallet] = true;

        emit Transfer(ZERO, _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
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

    function setCooldownEnabled(bool onoff) public onlyOwner {
        cooldownEnabled = onoff;
    }

    function setSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function setFeesEnabled(bool onoff) public onlyOwner {
        feesEnabled = onoff;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !swapping) {
            require(!_isBlacklisted[from] && !_isBlacklisted[to]);

            if(!tradingOpen) {
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not allowed yet.");
            }

            if (cooldownEnabled) {
                if (to != address(_uniswapV2Router) && to != address(_uniswapV2Pair)){
                    require(_cooldown[tx.origin] < block.number - _cooldownBlocks && _cooldown[to] < block.number - _cooldownBlocks, "Transfer delay enabled. Try again later.");
                    _cooldown[tx.origin] = block.number;
                    _cooldown[to] = block.number;
                }
            }

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds maximum wallet token amount.");
            }
            
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !feesEnabled) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > _swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        _tokenTransfer(from, to, amount, takeFee, shouldSwap);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForTreasury;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > _swapTokensAtAmount * 5) {
            contractBalance = _swapTokensAtAmount * 5;
        }
        
        uint256 liquidityTokens = contractBalance * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForETH(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForTreasury = ethBalance.mul(_tokensForTreasury).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForTreasury;
        
        _tokensForLiquidity = 0;
        _tokensForTreasury = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, _tokensForLiquidity);
        }
        
        (success,) = address(treasuryWallet).call{value: address(this).balance}("");
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        treasuryWallet.transfer(amount);
    }

    function isBlacklisted(address wallet) external view returns (bool) {
        return _isBlacklisted[wallet];
    }
    
    function launch(uint256 blocks) public onlyOwner {
        require(!tradingOpen, "Trading is already open");
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Router = uniswapV2Router;
        _approve(address(this), address(_uniswapV2Router), _tTotal);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        maxBuyAmount = 5e12 * (10**_decimals);
        maxSellAmount = 5e12 * (10**_decimals);
        maxWalletAmount = 1e13 * (10**_decimals);
        _swapTokensAtAmount = 5e11 * (10**_decimals);
        tradingOpen = true;
        tradingActiveBlock = block.number;
        _blocksToBlacklist = blocks;
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
    }

    function setMaxBuyAmount(uint256 maxBuy) public onlyOwner {
        require(maxBuy >= 1e11 * (10**_decimals), "Max buy amount cannot be lower than 0.01% total supply.");
        maxBuyAmount = maxBuy;
    }

    function setMaxSellAmount(uint256 maxSell) public onlyOwner {
        require(maxSell >= 1e11 * (10**_decimals), "Max sell amount cannot be lower than 0.01% total supply.");
        maxSellAmount = maxSell;
    }
    
    function setMaxWalletAmount(uint256 maxToken) public onlyOwner {
        require(maxToken >= 1e12 * (10**_decimals), "Max wallet amount cannot be lower than 0.1% total supply.");
        maxWalletAmount = maxToken;
    }
    
    function setSwapTokensAtAmount(uint256 swapAmount) public onlyOwner {
        require(swapAmount >= 1e10 * (10**_decimals), "Swap amount cannot be lower than 0.001% total supply.");
        require(swapAmount <= 5e12 * (10**_decimals), "Swap amount cannot be higher than 0.5% total supply.");
        _swapTokensAtAmount = swapAmount;
    }

    function setLiquidityWallet(address liquidityWalletAddy) public onlyOwner {
        require(liquidityWalletAddy != ZERO, "liquidityWallet address cannot be 0");
        _isExcludedFromFees[liquidityWallet] = false;
        _isExcludedMaxTransactionAmount[liquidityWallet] = false;
        liquidityWallet = payable(liquidityWalletAddy);
        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedMaxTransactionAmount[liquidityWallet] = true;
    }

    function setTreasuryWallet(address treasuryWalletAddy) public onlyOwner {
        require(treasuryWalletAddy != ZERO, "treasuryWallet address cannot be 0");
        _isExcludedFromFees[treasuryWallet] = false;
        _isExcludedMaxTransactionAmount[treasuryWallet] = false;
        treasuryWallet = payable(treasuryWalletAddy);
        _isExcludedFromFees[treasuryWallet] = true;
        _isExcludedMaxTransactionAmount[treasuryWallet] = true;
    }

    function setExcludedFromFees(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = isEx;
        }
    }
    
    function setExcludeFromMaxTransaction(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedMaxTransactionAmount[accounts[i]] = isEx;
        }
    }
    
    function setBlacklisted(address[] memory accounts, bool exempt) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isBlacklisted[accounts[i]] = exempt;
        }
    }

    function setBuyFee(uint256 newBuyLiquidityFee, uint256 newBuyTreasuryFee) public onlyOwner {
        require(newBuyLiquidityFee + newBuyTreasuryFee <= 200, "Must keep buy taxes below 20%");
        buyLiquidityFee = newBuyLiquidityFee;
        buyTreasuryFee = newBuyTreasuryFee;
    }

    function setSellFee(uint256 newSellLiquidityFee, uint256 newSellTreasuryFee) public onlyOwner {
        require(newSellLiquidityFee + newSellTreasuryFee <= 200, "Must keep sell taxes below 20%");
        sellLiquidityFee = newSellLiquidityFee;
        sellTreasuryFee = newSellTreasuryFee;
    }

    function setCooldownBlocks(uint256 blocks) public onlyOwner {
        _cooldownBlocks = blocks;
    }

    function removeAllFee() private {
        if(buyLiquidityFee == 0 && buyTreasuryFee == 0 && sellLiquidityFee == 0 && sellTreasuryFee == 0) return;
        
        _previousBuyLiquidityFee = buyLiquidityFee;
        _previousBuyTreasuryFee = buyTreasuryFee;
        _previousSellLiquidityFee = sellLiquidityFee;
        _previousSellTreasuryFee = sellTreasuryFee;
        
        buyLiquidityFee = 0;
        buyTreasuryFee = 0;
        sellLiquidityFee = 0;
        sellTreasuryFee = 0;
    }
    
    function restoreAllFee() private {
        buyLiquidityFee = _previousBuyLiquidityFee;
        buyTreasuryFee = _previousBuyTreasuryFee;
        sellLiquidityFee = _previousSellLiquidityFee;
        sellTreasuryFee = _previousSellTreasuryFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if(!takeFee) {
            removeAllFee();
        } else {
            amount = _takeFees(sender, amount, isSell);
        }

        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        uint256 liqFee;
        uint256 trsryFee;
        if(tradingActiveBlock + _blocksToBlacklist >= block.number) {
            _totalFees = 799;
            liqFee = 10;
            trsryFee = 789;
        } else {
            _totalFees = _getTotalFees(isSell);
            if (isSell) {
                liqFee = sellLiquidityFee;
                trsryFee = sellTreasuryFee;
            } else {
                liqFee = buyLiquidityFee;
                trsryFee = buyTreasuryFee;
            }
        }

        uint256 fees = amount.mul(_totalFees).div(FEE_DIVISOR);
        _tokensForLiquidity += fees * liqFee / _totalFees;
        _tokensForTreasury += fees * trsryFee / _totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return sellLiquidityFee + sellTreasuryFee;
        }
        return buyLiquidityFee + buyTreasuryFee;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function unclog() public onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForETH(contractBalance);
    }
    
    function distributeFees() public onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        require(tkn != address(this), "Cannot withdraw this token");
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function removeLimits() public onlyOwner {
        maxBuyAmount = _tTotal;
        maxSellAmount = _tTotal;
        maxWalletAmount = _tTotal;
        cooldownEnabled = false;
    }

}