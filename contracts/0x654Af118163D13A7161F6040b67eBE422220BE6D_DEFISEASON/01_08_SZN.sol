// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DEFISEASON is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;

    mapping (address => uint) private cd;

    mapping (address => uint256) private _rOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromTxLimits;
    mapping (address => bool) private _isBot;

    bool public tradingOpen;
    bool public launched;
    bool private swapping;
    bool private swapEnabled = false;
    bool public cdEnabled = false;

    string private constant _name = "DeFi Season";
    string private constant _symbol = "SZN";

    uint8 private constant _decimals = 18;

    uint256 private constant _tTotal = 1e8 * (10**_decimals);
    uint256 public maxBuy = _tTotal;
    uint256 public maxSell = _tTotal;
    uint256 public maxWallet = _tTotal;
    uint256 public tradingActiveBlock = 0;
    uint256 private _deadBlocks = 1;
    uint256 private _cdBlocks = 1;
    uint256 private constant FEE_DIVISOR = 1000;
    uint256 private _buyLiqFee = 20;
    uint256 private _previousBuyLiqFee = _buyLiqFee;
    uint256 private _buyVaultFee = 30;
    uint256 private _previousBuyVaultFee = _buyVaultFee;
    uint256 private _sellLiqFee = 20;
    uint256 private _previousSellLiqFee = _sellLiqFee;
    uint256 private _sellVaultFee = 30;
    uint256 private _previousSellVaultFee = _sellVaultFee;
    uint256 private tokensForLiq;
    uint256 private tokensForVault;
    uint256 private swapTokensAtAmount = 0;

    address payable private _liquidityWalletAddress;
    address payable private _vaultWalletAddress;
    address private uniswapV2Pair;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    
    constructor (address liquidityWalletAddress, address vaultWalletAddress) {
        _liquidityWalletAddress = payable(liquidityWalletAddress);
        _vaultWalletAddress = payable(vaultWalletAddress);
        _rOwned[_msgSender()] = _tTotal;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromTxLimits[owner()] = true;
        _isExcludedFromTxLimits[address(this)] = true;
        _isExcludedFromTxLimits[DEAD] = true;
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
        INTERNAL_transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        INTERNAL_approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        INTERNAL_transfer(sender, recipient, amount);
        INTERNAL_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function INTERNAL_approve(address owner, address spender, uint256 amount) private {
        require(owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function INTERNAL_transfer(address from, address to, uint256 amount) private {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !swapping) {
            require(!_isBot[from] && !_isBot[to]);

            if(!tradingOpen) {
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not allowed yet.");
            }

            if (cdEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(cd[tx.origin] < block.number - _cdBlocks && cd[to] < block.number - _cdBlocks, "Transfer delay enabled. Try again later.");
                    cd[tx.origin] = block.number;
                    cd[to] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromTxLimits[to]) {
                require(amount <= maxBuy, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds maximum wallet token amount.");
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromTxLimits[from]) {
                require(amount <= maxSell, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            INTERNAL_swapBack();
            swapping = false;
        }

        INTERNAL_tokenTransfer(from, to, amount, takeFee, shouldSwap);
    }

    function INTERNAL_swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiq + tokensForVault;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 5) {
            contractBalance = swapTokensAtAmount * 5;
        }
        
        uint256 liqTokens = contractBalance * tokensForLiq / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liqTokens);
        
        uint256 initialETHBalance = address(this).balance;

        INTERNAL_swapTokensForETH(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForVault = ethBalance.mul(tokensForVault).div(totalTokensToSwap);
        uint256 ethForLiq = ethBalance - ethForVault;
        
        tokensForLiq = 0;
        tokensForVault = 0;
        
        if(liqTokens > 0 && ethForLiq > 0) {
            INTERNAL_addLiquidity(liqTokens, ethForLiq);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiq, tokensForLiq);
        }
        
        (success,) = address(_vaultWalletAddress).call{value: address(this).balance}("");
    }

    function INTERNAL_swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        INTERNAL_approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function INTERNAL_addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        INTERNAL_approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _liquidityWalletAddress,
            block.timestamp
        );
    }
        
    function INTERNAL_sendETHToFee(uint256 amount) private {
        _vaultWalletAddress.transfer(amount);
    }
    
    function initialize() public onlyOwner {
        require(!launched,"Trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        INTERNAL_approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cdEnabled = true;
        maxBuy = 1e6 * (10**_decimals);
        maxSell = 1e6 * (10**_decimals);
        maxWallet = 2e6 * (10**_decimals);
        swapTokensAtAmount = 5e4 * (10**_decimals);
        launched = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function letsGo() public onlyOwner {
        require(!tradingOpen && launched,"Trading is already open");
        tradingOpen = true;
        tradingActiveBlock = block.number;
    }

    function CONFIG_setMaxBuy(uint256 amount) public onlyOwner {
        require(amount >= 1e4 * (10**_decimals), "Max buy cannot be lower than 0.01% total supply.");
        maxBuy = amount;
    }

    function CONFIG_setMaxSell(uint256 amount) public onlyOwner {
        require(amount >= 1e4 * (10**_decimals), "Max sell cannot be lower than 0.01% total supply.");
        maxSell = amount;
    }
    
    function CONFIG_setMaxWallet(uint256 amount) public onlyOwner {
        require(amount >= 1e5 * (10**_decimals), "Max wallet cannot be lower than 0.1% total supply.");
        maxWallet = amount;
    }
    
    function CONFIG_setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        require(amount >= 1e3 * (10**_decimals), "Swap amount cannot be lower than 0.001% total supply.");
        require(amount <= 5e5 * (10**_decimals), "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = amount;
    }

    function CONFIG_setLiquidityWalletAddress(address walletAddress) public onlyOwner {
        require(walletAddress != ZERO, "liquidityWallet address cannot be 0");
        _isExcludedFromFees[_liquidityWalletAddress] = false;
        _isExcludedFromTxLimits[_liquidityWalletAddress] = false;
        _liquidityWalletAddress = payable(walletAddress);
        _isExcludedFromFees[_liquidityWalletAddress] = true;
        _isExcludedFromTxLimits[_liquidityWalletAddress] = true;
    }

    function CONFIG_setVaultWalletAddress(address walletAddress) public onlyOwner {
        require(walletAddress != ZERO, "vaultWallet address cannot be 0");
        _isExcludedFromFees[_vaultWalletAddress] = false;
        _isExcludedFromTxLimits[_vaultWalletAddress] = false;
        _vaultWalletAddress = payable(walletAddress);
        _isExcludedFromFees[_vaultWalletAddress] = true;
        _isExcludedFromTxLimits[_vaultWalletAddress] = true;
    }

    function CONFIG_setExcludedFromFees(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = isEx;
        }
    }
    
    function CONFIG_setExcludedFromTxLimits(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromTxLimits[accounts[i]] = isEx;
        }
    }
    
    function CONFIG_setBots(address[] memory accounts, bool exempt) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isBot[accounts[i]] = exempt;
        }
    }

    function CONFIG_setBuyFees(uint256 buyLiquidityFee, uint256 buyVaultFee) public onlyOwner {
        require(buyLiquidityFee + buyVaultFee <= 200, "Must keep buy taxes below 20%");
        _buyLiqFee = buyLiquidityFee;
        _buyVaultFee = buyVaultFee;
    }

    function CONFIG_setSellFees(uint256 sellLiquidityFee, uint256 sellVaultFee) public onlyOwner {
        require(sellLiquidityFee + sellVaultFee <= 200, "Must keep sell taxes below 20%");
        _sellLiqFee = sellLiquidityFee;
        _sellVaultFee = sellVaultFee;
    }

    function CONFIG_setCDEnabled(bool onoff) public onlyOwner {
        cdEnabled = onoff;
    }

    function CONFIG_setSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function CONFIG_setDeadBlocks(uint256 blocks) public onlyOwner {
        _deadBlocks = blocks;
    }

    function CONFIG_setCDBlocks(uint256 blocks) public onlyOwner {
        _cdBlocks = blocks;
    }

    function INTERNAL_removeFees() private {
        if(_buyLiqFee == 0 && _buyVaultFee == 0 && _sellLiqFee == 0 && _sellVaultFee == 0) return;
        
        _previousBuyLiqFee = _buyLiqFee;
        _previousBuyVaultFee = _buyVaultFee;
        _previousSellLiqFee = _sellLiqFee;
        _previousSellVaultFee = _sellVaultFee;
        
        _buyLiqFee = 0;
        _buyVaultFee = 0;
        _sellLiqFee = 0;
        _sellVaultFee = 0;
    }
    
    function INTERNAL_restoreFees() private {
        _buyLiqFee = _previousBuyLiqFee;
        _buyVaultFee = _previousBuyVaultFee;
        _sellLiqFee = _previousSellLiqFee;
        _sellVaultFee = _previousSellVaultFee;
    }
        
    function INTERNAL_tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if(!takeFee) {
            INTERNAL_removeFees();
        } else {
            amount = INTERNAL_takeFees(sender, amount, isSell);
        }

        INTERNAL_vanillaTransfer(sender, recipient, amount);
        
        if(!takeFee) {
            INTERNAL_restoreFees();
        }
    }

    function INTERNAL_vanillaTransfer(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function INTERNAL_takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        uint256 liqFee;
        uint256 vaultFee;
        if(tradingActiveBlock + _deadBlocks >= block.number) {
            _totalFees = 999;
            liqFee = 10;
            vaultFee = 989;
        } else {
            _totalFees = INTERNAL_getTotalFees(isSell);
            if (isSell) {
                liqFee = _sellLiqFee;
                vaultFee = _sellVaultFee;
            } else {
                liqFee = _buyLiqFee;
                vaultFee = _buyVaultFee;
            }
        }

        uint256 fees = amount.mul(_totalFees).div(FEE_DIVISOR);
        tokensForLiq += fees * liqFee / _totalFees;
        tokensForVault += fees * vaultFee / _totalFees;
            
        if(fees > 0) {
            INTERNAL_vanillaTransfer(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    function INTERNAL_getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return _sellLiqFee + _sellVaultFee;
        }
        return _buyLiqFee + _buyVaultFee;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function CONFIG_unclogContract() public {
        require(_vaultWalletAddress == msg.sender);      
        uint256 contractBalance = balanceOf(address(this));
        INTERNAL_swapTokensForETH(contractBalance);
    }
    
    function CONFIG_distributeFeesAfterUnclog() public {
        require(_vaultWalletAddress == msg.sender);      
        uint256 contractETHBalance = address(this).balance;
        INTERNAL_sendETHToFee(contractETHBalance);
    }

    function CONFIG_rescueStuckETH() public {
        require(_vaultWalletAddress == msg.sender);      
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function CONFIG_rescueStuckTokens(address tkn) public {
        require(_vaultWalletAddress == msg.sender);      
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function CONFIG_removeTradingLimits() public onlyOwner {
        maxBuy = _tTotal;
        maxSell = _tTotal;
        maxWallet = _tTotal;
        cdEnabled = false;
    }

}