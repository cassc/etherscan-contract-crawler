//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";

contract LARRYSARCADE is ERC20, Ownable {

    address payable public developmentWalletAddress = payable(0x20431b8cf9FB20926eB673d33126AA44372D9a89);
    address payable public marketingWalletAddress = payable(0x8d290355A4f7e5DDd011F11ccb0E7bA388C2eBee);

    mapping (address => bool) public isExcludedFromFee;

    uint256 public _liquidityFee = 30;
    uint256 public _developmentFee = 20;
    uint256 public _marketingFee = 30;
    uint256 public totalFee = _liquidityFee + _developmentFee + _marketingFee;
    uint256 public constant DENOMINATOR = 1000;

    uint256 public minimumTokensBeforeSwap = 1_500* 10 ** decimals();

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event ETHSentTo(uint256 amount, address wallet);




    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () ERC20("Larry`s Arcade", "$LARCADE") {

        _mint(msg.sender, 10 ** 8 * 10 ** decimals());

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//router main
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(developmentWalletAddress)] = true;
        isExcludedFromFee[address(marketingWalletAddress)] = true;
        isExcludedFromFee[address(uniswapV2Router)] = true;

    }

    function updateIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function setTaxes(uint256 newLiquidityFee, uint256 newDev, uint256 newMarketing) external onlyOwner() {
        _liquidityFee = newLiquidityFee;
        _developmentFee = newDev;
        _marketingFee = newMarketing;
        totalFee = _liquidityFee + _developmentFee + _marketingFee;
    }

    function updateWallets(address newDevWalletAddress, address newMarketingWalletAddress) external onlyOwner() {
        developmentWalletAddress = payable(newDevWalletAddress);
        marketingWalletAddress = payable(newMarketingWalletAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function updateRouter(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress);

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapV2Pair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address
    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {

        if(inSwapAndLiquify)
        {
            super._transfer(sender, recipient, amount);
            return;
        }
        else
        {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

            if (overMinimumTokenBalance && !inSwapAndLiquify && sender != uniswapV2Pair && swapAndLiquifyEnabled)
            {
                swapAndSendToWallets(minimumTokensBeforeSwap);
            }

            if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]) {
                uint256 feeAmount = amount * totalFee / DENOMINATOR;
                amount -= feeAmount;
                super._transfer(sender, address(this), feeAmount);
            }
            super._transfer(sender, recipient, amount);
        }
    }

    function swapAndSendToWallets(uint256 tokens) private  lockTheSwap {
        uint256 liquidityTokens = tokens * _liquidityFee / 2 / totalFee;
        uint256 tokensToSwap = tokens - liquidityTokens;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensToSwap);
        uint256 receivedETH = address(this).balance - initialBalance;
        uint256 totalFeesAdjusted = totalFee - _liquidityFee / 2;

        uint256 liquidityETH = receivedETH * _liquidityFee / 2 / (totalFeesAdjusted);
        uint256 devETH = receivedETH * _developmentFee / (totalFeesAdjusted);
        uint256 marketingETH = receivedETH - liquidityETH - devETH;

        addLiquidity(liquidityTokens, liquidityETH);
        emit SwapAndLiquify(liquidityTokens, liquidityETH);
        bool success;
        (success,) = address(developmentWalletAddress).call{value: devETH}("");
        if (success) {
            emit ETHSentTo(devETH, developmentWalletAddress);
        }
        (success,) = address(marketingWalletAddress).call{value: marketingETH}("");
        if (success) {
            emit ETHSentTo(marketingETH, marketingWalletAddress);
        }
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
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
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
}