/*

88                        88                           ,adba,              88                        88
88                        88                           8I  I8              88                        88
88                        88                           "8bdP'              88                        88
88,dPPYba,   88       88  88,dPPYba,   88       88    ,d8"8b  88   ,adPPYb,88  88       88   ,adPPYb,88  88       88
88P'    "8a  88       88  88P'    "8a  88       88  .dP'   Yb,8I  a8"    `Y88  88       88  a8"    `Y88  88       88
88       d8  88       88  88       d8  88       88  8P      888'  8b       88  88       88  8b       88  88       88
88b,   ,a8"  "8a,   ,a88  88b,   ,a8"  "8a,   ,a88  8b,   ,dP8b   "8a,   ,d88  "8a,   ,a88  "8a,   ,d88  "8a,   ,a88
8Y"Ybbd8"'    `"YbbdP'Y8  8Y"Ybbd8"'    `"YbbdP'Y8  `Y8888P"  Yb   `"8bbdP"Y8   `"YbbdP'Y8   `"8bbdP"Y8   `"YbbdP'Y8

https://t.me/bubududuerc
https://twitter.com/BUBU_erc
https://twitter.com/DUDU_erc
https://www.bubududu.xyz/

*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);

        return a % b;
    }
}

contract BUBUDUDU is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public immutable deployer;
    address public immutable marketingWallet;
    address public immutable buybackWallet;
    address public vaultWallet;

    uint256 public mintAmount = 88888888 * 10 ** decimals();
    uint256 public maxHoldingAmount   = mintAmount / 200;  // 0.50% max wallet holdings
    uint256 public swapTokensAtAmount = mintAmount / 2000; // 0.05% max before swapBack

    uint256 public totalFees    = 5; // total percent
    uint256 public prizeFee     = 2; // percent to prize
    uint256 public buybackFee   = 1; // percent to buyback
    uint256 public marketingFee = 1; // percent to marketing
    uint256 public liquidityFee = 1; // percent to liquidity

    bool private swapping;
    bool public swapEnabled = true;
    bool public limitOn = true;

    mapping (address => bool) public blacklist;
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isExcludedMaxTxAmount;
    mapping (address => bool) public tradingPairs;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event VaultWalletUpdated(address indexed newVaultWallet, address indexed oldVaultWallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    modifier onlyDeployer() {
        // some things need to be callable even after renounce
        require(msg.sender == deployer, "shoo");
        _;
    }

    constructor(string memory name, address _marketingWallet, address _buybackWallet, address _tempVaultWallet) ERC20(name, name) {

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
          .createPair(address(this), uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        deployer = address(owner());
        vaultWallet = _tempVaultWallet; // temporary fee receiver
        buybackWallet = _buybackWallet;
      	marketingWallet = _marketingWallet;

        excludeFromFees(deployer, true); // Owner address
        excludeFromFees(address(this), true); // CA
        excludeFromFees(address(0xdead), true); // Burn address
        excludeFromFees(_marketingWallet, true);
        excludeFromFees(_tempVaultWallet, true);
        excludeFromFees(_buybackWallet, true);

        /* _mint only called once and CANNOT be called again */
        _mint(deployer, mintAmount);
    }

    receive() external payable {}

    // DEPLOYER-ONLY FUNCTIONS
    function updateSwapEnabled(bool enabled) public onlyDeployer {
        swapEnabled = enabled;
    }

    function updateVaultWallet(address newVaultWallet) public onlyDeployer {
        emit VaultWalletUpdated(newVaultWallet, vaultWallet);
        vaultWallet = newVaultWallet;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyDeployer {
        require(pair != uniswapV2Pair, "The pair cannot be removed from tradingPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        tradingPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    // FIN DEPLOYER-ONLY FUNCTIONS


    // OWNER-ONLY FUNCTIONS
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
  	    require(newAmount >= totalSupply() / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() / 200, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function setRule(bool _limitOn, uint256 _maxHoldingAmount) external onlyOwner {
        limitOn = _limitOn;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function updateFees(uint256 _prizeFee, uint256 _buybackFee, uint256 _marketingFees, uint256 _liquidityFee) external onlyOwner {
        prizeFee = _prizeFee;
        buybackFee = _buybackFee;
        marketingFee = _marketingFees;
        liquidityFee = _liquidityFee;
        totalFees = _prizeFee + _buybackFee + _marketingFees + _liquidityFee;
        require(totalFees <= 20, "Fee too high");
    }
    // FIN OWNER-ONLY FUNCTIONS


    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklist[to] && !blacklist[from], "bl");

        if (amount == 0) {
          super._transfer(from, to, 0);
          return;
        }

        bool isBuy = tradingPairs[from];
        bool isSell = tradingPairs[to];
        bool excluded = isExcludedFromFees[from] || isExcludedFromFees[to];

        if (
            limitOn &&
            isBuy &&
            from != owner() &&
            to != owner() &&
            to != address(0xdead) &&
            !swapping
        ) {
            // a token buy while we have limits on
            require(amount + balanceOf(to) <= maxHoldingAmount, "Too many tokens");
        }

    		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        bool takeFee = !swapping;
        if (excluded) {
            takeFee = false;
        }

        if (canSwap && swapEnabled && !swapping && isSell && !excluded) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            if (isSell) {
                fees = amount.mul(totalFees).div(100);
                super._transfer(from, address(this), fees);
                amount -= fees;
            } else if (isBuy) {
          	    fees = amount.mul(totalFees).div(100);
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
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
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 pctTokensForLiquidity = liquidityFee.mul(100).div(totalFees).div(2);
        uint256 tokensForLiquidity = contractBalance.div(pctTokensForLiquidity);
        uint256 tokensToSwapForEth = contractBalance.sub(tokensForLiquidity);
        swapTokensForEth(tokensToSwapForEth);
        uint256 divisor = totalFees.mul(2).sub(liquidityFee);
        uint256 ethForLiquidity = address(this).balance.div(divisor);
        addLiquidity(tokensForLiquidity, ethForLiquidity);
        emit SwapAndLiquify(tokensToSwapForEth, ethForLiquidity, tokensForLiquidity);
        bool success;
        uint256 ethToDisperse = address(this).balance;
        (success,) = marketingWallet.call{value: ethToDisperse.mul(marketingFee.mul(100).div(totalFees)).div(100)}("");
        require(success);
        (success,) = buybackWallet.call{value: ethToDisperse.mul(buybackFee.mul(100).div(totalFees)).div(100)}("");
        require(success);
        (success,) = vaultWallet.call{value: address(this).balance}("");
        require(success);
    }
}