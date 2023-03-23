// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IUniswapV2Router02.sol";

contract CS2 is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    
    uint256 public swapTokensThreshold;
        
    bool private _isSwapping;

    uint256 private _swapFee = 5;
    uint256 private _tokensForFee;
    address private _feeReceiver;

    // exlcude from fees and max transaction amount
    mapping (address => bool) public isExcludedFromFees;

    // any transfer *to* these addresses could be subject to a maximum transfer amount
    mapping (address => bool) private _automatedMarketMakerPairs;

    /**
     * @dev Throws if called by any account other than the _feeReceiver
     */
    modifier teamOROwner() {
        require(_feeReceiver == _msgSender() || owner() == _msgSender(), "Caller is not the _feeReceiver address nor owner.");
        _;
    }

    constructor() ERC20("CS2 Coin", "CS2") payable {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uint256 totalSupply = 1e7 * 1e18; // 10M

        swapTokensThreshold = totalSupply * 1 / 1000;

        _feeReceiver = owner();

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }
    
    /**
    * @dev Exclude from fee calculation
    */
    function excludeFromFees(address account, bool excluded) public teamOROwner {
        isExcludedFromFees[account] = excluded;
    }

    /**
    * @dev Update token fees (max set to initial fee)
    */
    function updateFees(uint256 fee) external teamOROwner {
        _swapFee = fee;

        require(_swapFee <= 5, "Must keep fees at 6% or less");
    }

    /**
    * @dev Update wallet that receives fees and newly added LP
    */
    function updateFeeReceiver(address newWallet) external teamOROwner {
        _feeReceiver = newWallet;
    }

    /**
    * @dev Very important function. 
    * Updates the threshold of how many tokens that must be in the contract calculation for fees to be taken
    */
    function updateSwapTokensThreshold(uint256 newThreshold) external teamOROwner returns (bool) {
  	    require(newThreshold >= totalSupply() * 1 / 100000, "Swap threshold cannot be lower than 0.001% total supply.");
  	    require(newThreshold <= totalSupply() * 5 / 1000, "Swap threshold cannot be higher than 0.5% total supply.");
  	    swapTokensThreshold = newThreshold;
  	    return true;
  	}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "_transfer:: Transfer from the zero address not allowed.");
        require(to != address(0), "_transfer:: Transfer to the zero address not allowed.");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensThreshold;
        if (
            canSwap &&
            !_isSwapping &&
            !_automatedMarketMakerPairs[from] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            _isSwapping = true;
            swapBack();
            _isSwapping = false;
        }

        bool takeFee = !_isSwapping;

        // if any addy belongs to _isExcludedFromFee or isn't a swap then remove the fee
        if (
            _swapFee == 0 ||
            isExcludedFromFees[from] || 
            isExcludedFromFees[to] || 
            (!_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to])
        ) takeFee = false;
        
        uint256 fees = 0;
        if (takeFee) {
            fees = amount.mul(_swapFee).div(100);
            _tokensForFee = amount.mul(_swapFee).div(100);
            
            if (fees > 0) 
                super._transfer(from, address(this), fees);
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
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

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _feeReceiver,
            block.timestamp
        );
    }

    function swapBack() internal {
        uint256 contractBalance = balanceOf(address(this));
        uint256 tokensForLiquidity = _tokensForFee.div(4); // 25% of the total fee
        uint256 tokensForFee = _tokensForFee.sub(tokensForLiquidity);
        
        if (contractBalance == 0 || _tokensForFee == 0) return;
        if (contractBalance > swapTokensThreshold) contractBalance = swapTokensThreshold;
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / _tokensForFee / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethFee = ethBalance.mul(tokensForFee).div(_tokensForFee);
        uint256 ethLiquidity = ethBalance - ethFee;
        
        _tokensForFee = 0;

        payable(_feeReceiver).transfer(ethFee);
                
        if (liquidityTokens > 0 && ethLiquidity > 0) 
            _addLiquidity(liquidityTokens, ethLiquidity);
    }

    /**
    * @dev Transfer eth stuck in contract to _feeReceiver
    */
    function withdrawContractETH() external {
        payable(_feeReceiver).transfer(address(this).balance);
    }

    /**
    * @dev In case swap wont do it and sells/buys might be blocked
    */
    function forceSwap() external teamOROwner {
        _swapTokensForEth(balanceOf(address(this)));
    }

    receive() external payable {}
}