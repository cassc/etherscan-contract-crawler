// SPDX-License-Identifier: MIT                                                                               

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract OCDNC is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public immutable uniswapV2Pair;
    address buyBurnAddy = 0x56d10fDbbE04F3439730442420B652A45F86B102;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = true;
    bool public transferDelayEnabled = true;
    bool private inSwap;
    bool private swapping;
    
    uint256 public supply = 1 * 1e6 * 1e18;

    uint256 public walletDigit = 2;
    uint256 public transDigit = 1;
    uint256 public delayDigit = 1;
    uint256 public swapDigit = 5;

    uint256 public maxTransactionAmount = supply * transDigit / 100;
    uint256 public swapTokensAtAmount = supply * swapDigit / 10000;
    uint256 public maxWallet = supply * walletDigit / 100;

    uint256 public buyBuybackFee = 10;
    uint256 public buyTotalFees = buyBuybackFee;

    uint256 public sellBuybackFee = 10;
    uint256 public sellTotalFees = sellBuybackFee;
    
    uint256 public tokensForBuyback;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    mapping (address => bool) private bots;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => uint256) private _holderLastTransferTimestamp;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20("Orally Consume Deez Nuts Cousin", "OCDNC") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(_uniswapV2Router)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmount[DEAD] = true;

        _approve(owner(), address(uniswapV2Router), supply);
        _mint(msg.sender, supply);
    }

    receive() external payable {}
    fallback() external payable {}
    
    function updateTransDigit(uint256 newNum) external onlyOwner {
        require(newNum >= 1);
        transDigit = newNum;
        updateLimits();
    }

    function updateWalletDigit(uint256 newNum) external onlyOwner {
        require(newNum >= 1);
        walletDigit = newNum;
        updateLimits();
    }

    function updateSwapDigit(uint256 newNum) external onlyOwner {
        require(newNum >= 1);
        swapDigit = newNum;
        updateLimits();
    }

    function updateDelayDigit(uint256 newNum) external onlyOwner{
        delayDigit = newNum;
    }
    
    function updateBuyFees(uint256 _buybackFee) external onlyOwner {
        buyBuybackFee = _buybackFee;
        buyTotalFees = buyBuybackFee;
        require(buyTotalFees <= 15, "Must keep buy fees at 15% or less");
    }
    
    function updateSellFees(uint256 _buybackFee) external onlyOwner {
        sellBuybackFee = _buybackFee;
        sellTotalFees = sellBuybackFee;
        require(sellTotalFees <= 20, "Must keep sell fees at 20% or less");
    }

    function updateBuyBurnAddy(address newAddy) external onlyOwner {
        buyBurnAddy = newAddy;
    }

    function setExcludedFromFees(address[] memory accounts, bool isEx) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = isEx;
        }
    }
    
    function setExcludeFromMaxTransaction(address[] memory accounts, bool isEx) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedMaxTransactionAmount[accounts[i]] = isEx;
        }
    }
    
    function setBots(address[] memory accounts, bool exempt) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            bots[accounts[i]] = exempt;
        }
    }

    function updateLimits() private {
        maxTransactionAmount = supply * transDigit / 100;
        swapTokensAtAmount = supply * swapDigit / 10000;
        maxWallet = supply * walletDigit / 100;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");
        
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != ZERO &&
                to != DEAD &&
                !swapping
            ) {
                require(!bots[from] && !bots[to]);

                if(!tradingActive) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
  
                if (transferDelayEnabled) {
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "Transfer Delay enabled. Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number + delayDigit;
                    }
                }

                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) { // when buy
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) { // when sell
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                } else if(!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
            canSwap &&
            !swapping &&
            swapEnabled &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] &&
            !inSwap
        ) {
            swapping = true;
            
            swapBack();

            swapping = false;
        }
        
        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;

        if(takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount.mul(sellTotalFees).div(100);
                tokensForBuyback += fees * sellBuybackFee / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForBuyback += fees * buyBuybackFee / buyTotalFees;
            }
            
            if(fees > 0) {
                super._transfer(from, address(this), fees);
            }
            
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp.add(300)
        );
        
    }

    function swapETHForTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            buyBurnAddy,
            block.timestamp.add(300)
        );
        
    }
    
    function swapBack() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        
        if(contractBalance == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 5) {
          contractBalance = swapTokensAtAmount * 5;
        }

        swapTokensForETH(contractBalance); 
        
        tokensForBuyback = 0;
    }

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Trading is already active.");
        tradingActive = true;
    }

    function setLimitsInEffect(bool enabled) external onlyOwner {
        limitsInEffect = enabled;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setTransferDelayEnabled(bool enabled) external onlyOwner {
        transferDelayEnabled = enabled;
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

    function buyTokens(uint256 amount) external onlyOwner {
        if (amount > 0 && amount <= address(this).balance && !inSwap) {
            swapETHForTokens(amount);
        }
    }

    function burnTokens(uint256 amount) external onlyOwner {
        if (amount > 0 && amount <= balanceOf(address(this)) && !inSwap) {
            _burn(address(this), amount);
            supply = totalSupply();
            updateLimits();
        }
    }
    
}