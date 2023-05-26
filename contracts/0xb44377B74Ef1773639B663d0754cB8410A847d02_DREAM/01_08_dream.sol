// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DREAM is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;

    mapping (address => uint) private cooldown;

    mapping (address => uint256) private _rOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;

    bool public tradingOpen;
    bool public launched;
    bool private swapping;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool public cooldownEnabled = false;

    string private constant _name = "DREAM";
    string private constant _symbol = "DREAM";

    uint8 private constant _decimals = 18;

    uint256 private constant _tTotal = 1e8 * (10**_decimals);
    uint256 public _maxBuyAmount = _tTotal;
    uint256 public _maxSellAmount = _tTotal;
    uint256 public _maxWalletAmount = _tTotal;
    uint256 public tradingActiveBlock = 0;
    uint256 private blocksToBlacklist = 1;
    uint256 private constant feeDivisor = 1000;
    uint256 private _buyLiquidityFee = 30;
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
    uint256 private _buyTreasuryFee = 90;
    uint256 private _previousBuyTreasuryFee = _buyTreasuryFee;
    uint256 private _sellLiquidityFee = 50;
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;
    uint256 private _sellTreasuryFee = 100;
    uint256 private _previousSellTreasuryFee = _sellTreasuryFee;
    uint256 private tokensForLiquidity;
    uint256 private tokensForTreasury;
    uint256 private swapTokensAtAmount = 0;

    address payable private _liquidityWallet;
    address payable private _treasuryWallet;
    address private uniswapV2Pair;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor (address liquidityWallet, address treasuryWallet) {
        _liquidityWallet = payable(liquidityWallet);
        _treasuryWallet = payable(treasuryWallet);
        _rOwned[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[DEAD] = true;
        _isExcludedFromFee[_liquidityWallet] = true;
        _isExcludedFromFee[_treasuryWallet] = true;
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

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function setSwapEnabled(bool onoff) external onlyOwner(){
        swapEnabled = onoff;
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
        bool takeFee = false;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !swapping) {
            require(!bots[from] && !bots[to]);

            if (cooldownEnabled){
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                    require(cooldown[tx.origin] < block.number - 1 && cooldown[to] < block.number - 1, "Transfer delay enabled. Try again later.");
                    cooldown[tx.origin] = block.number;
                    cooldown[to] = block.number;
                }
            }

            takeFee = true;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading is not allowed yet.");
                require(amount <= _maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount.");
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromFee[from]) {
                require(tradingOpen, "Trading is not allowed yet.");
                require(amount <= _maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        _tokenTransfer(from,to,amount,takeFee, shouldSwap);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForTreasury;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 5) {
            contractBalance = swapTokensAtAmount * 5;
        }
        
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForTreasury = ethBalance.mul(tokensForTreasury).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForTreasury;
        
        tokensForLiquidity = 0;
        tokensForTreasury = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        (success,) = address(_treasuryWallet).call{value: address(this).balance}("");
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _liquidityWallet,
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        _treasuryWallet.transfer(amount);
    }
    
    function launch() external onlyOwner() {
        require(!launched,"Trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        _maxBuyAmount = 1e6 * (10**_decimals);
        _maxSellAmount = 1e6 * (10**_decimals);
        _maxWalletAmount = 2e6 * (10**_decimals);
        swapTokensAtAmount = 5e4 * (10**_decimals);
        launched = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen && launched,"Trading is already open");
        tradingOpen = true;
        tradingActiveBlock = block.number;
    }

    function setMaxBuyAmount(uint256 maxBuy) public onlyOwner {
        require(maxBuy >= 1e4 * (10**_decimals), "Max buy amount cannot be lower than 0.01% total supply.");
        _maxBuyAmount = maxBuy;
    }

    function setMaxSellAmount(uint256 maxSell) public onlyOwner {
        require(maxSell >= 1e4 * (10**_decimals), "Max sell amount cannot be lower than 0.01% total supply.");
        _maxSellAmount = maxSell;
    }
    
    function setMaxWalletAmount(uint256 maxToken) public onlyOwner {
        require(maxToken >= 1e5 * (10**_decimals), "Max wallet amount cannot be lower than 0.1% total supply.");
        _maxWalletAmount = maxToken;
    }
    
    function setSwapTokensAtAmount(uint256 newAmount) public onlyOwner {
        require(newAmount >= 1e3 * (10**_decimals), "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= 5e5 * (10**_decimals), "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
    }

    function setLiquidityWallet(address liquidityWallet) public onlyOwner() {
        require(liquidityWallet != ZERO, "liquidityWallet address cannot be 0");
        _isExcludedFromFee[_liquidityWallet] = false;
        _liquidityWallet = payable(liquidityWallet);
        _isExcludedFromFee[_liquidityWallet] = true;
    }

    function setTreasuryWallet(address treasuryWallet) public onlyOwner() {
        require(treasuryWallet != ZERO, "treasuryWallet address cannot be 0");
        _isExcludedFromFee[_treasuryWallet] = false;
        _treasuryWallet = payable(treasuryWallet);
        _isExcludedFromFee[_treasuryWallet] = true;
    }

    function setExcludedFromFees(address[] memory accounts, bool exempt) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = exempt;
        }
    }
    
    function setBots(address[] memory accounts, bool exempt) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            bots[accounts[i]] = exempt;
        }
    }

    function setBuyFee(uint256 buyLiquidityFee, uint256 buyTreasuryFee) external onlyOwner {
        require(buyLiquidityFee + buyTreasuryFee <= 200, "Must keep buy taxes below 20%");
        _buyLiquidityFee = buyLiquidityFee;
        _buyTreasuryFee = buyTreasuryFee;
    }

    function setSellFee(uint256 sellLiquidityFee, uint256 sellTreasuryFee) external onlyOwner {
        require(sellLiquidityFee + sellTreasuryFee <= 300, "Must keep sell taxes below 30%");
        _sellLiquidityFee = sellLiquidityFee;
        _sellTreasuryFee = sellTreasuryFee;
    }

    function setBlocksToBlacklist(uint256 blocks) public onlyOwner {
        blocksToBlacklist = blocks;
    }

    function removeAllFee() private {
        if(_buyLiquidityFee == 0 && _buyTreasuryFee == 0 && _sellLiquidityFee == 0 && _sellTreasuryFee == 0) return;
        
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousBuyTreasuryFee = _buyTreasuryFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        _previousSellTreasuryFee = _sellTreasuryFee;
        
        _buyLiquidityFee = 0;
        _buyTreasuryFee = 0;
        _sellLiquidityFee = 0;
        _sellTreasuryFee = 0;
    }
    
    function restoreAllFee() private {
        _buyLiquidityFee = _previousBuyLiquidityFee;
        _buyTreasuryFee = _previousBuyTreasuryFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
        _sellTreasuryFee = _previousSellTreasuryFee;
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
        if(tradingActiveBlock + blocksToBlacklist >= block.number){
            _totalFees = 999;
            liqFee = 10;
            trsryFee = 989;
        } else {
            _totalFees = _getTotalFees(isSell);
            if (isSell) {
                liqFee = _sellLiquidityFee;
                trsryFee = _sellTreasuryFee;
            } else {
                liqFee = _buyLiquidityFee;
                trsryFee = _buyTreasuryFee;
            }
        }

        uint256 fees = amount.mul(_totalFees).div(feeDivisor);
        tokensForLiquidity += fees * liqFee / _totalFees;
        tokensForTreasury += fees * trsryFee / _totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return _sellLiquidityFee + _sellTreasuryFee;
        }
        return _buyLiquidityFee + _buyTreasuryFee;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function unclog() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function distributeFees() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawStuckTokens(address tkn) external onlyOwner {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function removeLimits() external onlyOwner {
        _maxBuyAmount = _tTotal;
        _maxSellAmount = _tTotal;
        _maxWalletAmount = _tTotal;
        cooldownEnabled = false;
    }

}