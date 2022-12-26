/**

Super Doge - genius token with self mooning algorithm.

Chat - https://t.me/SuperDoge_ERC20

*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface Hodl {
    function getBalance() external view returns (uint256);
    function sendReward(address to, uint256 amount) external returns (bool result);
}

contract SDOGE is ERC20, Ownable {
    using SafeMath for uint256;
    Hodl private _hodler;
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    address public _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public _uniswapV3Router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public _feeWallet;

    uint256 public _supportLevel;
    uint256 public _floorSellFee;
    uint256 public _marketingFee;
    uint256 public _liquidityFee;
    uint256 public _tokensForLiquidity;
    uint256 public _supportPercentBelowATH;
    uint256 public _addLiquidityAtAmount;

    bool public _tradingActive;
    bool private _isSwappingBack;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isNonUniswapExchange;
    mapping(address => bool) private _isBlackListedSender;
    mapping(address => bool) private _isBlackListed;

    event IsBuy(address indexed msgSender, address from, address to, uint256 tokensAmount, uint256 newUsdcBalance);
    event IsSell(address indexed msgSender, address from, address to, uint256 tokensAmount, uint256 newUsdcBalance);
    event IsLiquidityOperation(address indexed msgSender, address from, address to, uint256 tokensAmount, uint256 newUsdcBalance);
    event LiquidityAdded(uint256 usdcAmount, uint256 tokenAmount);
    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor() ERC20("Super Doge", "SDOGE") {
        _uniswapV2Router = IUniswapV2Router02(_router);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _usdc);
        _supportLevel = 0;
        _supportPercentBelowATH = 5;
        _floorSellFee = 30;
        _marketingFee = 1;
        _liquidityFee = 1;
        _addLiquidityAtAmount = 1000e18;
    }

    function init(address hodler, address owner) public onlyOwner {
        require(owner != address(0), "Address doesn't exist");

        _hodler = Hodl(hodler);
        _feeWallet = address(owner);
        excludeFromFees(address(owner), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        uint256 totalSupply = 10e6 * 1e18;

        _mint(owner, totalSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlackListed[to] || !_isBlackListed[from], "Address is blacklisted");
        require(!_isBlackListedSender[msg.sender], "msg.sender is blacklisted");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        (bool isSell, bool isBuy, bool isLiquidityOperation) = getTransactionType(from, to, amount);

        if (isLiquidityOperation || _isSwappingBack) {
            super._transfer(from, to, amount);
            return;
        }

        bool isSwap = isBuy || isSell;
        bool isExcludedFromFee = _isExcludedFromFees[from] || _isExcludedFromFees[to];

        if(!_tradingActive && !isExcludedFromFee && isSwap) require(false, "Trading is not yet active");

        bool shouldTakeFee = _tradingActive && isSwap;
        if (isExcludedFromFee) shouldTakeFee = false;

        (uint buyerRewardInUSDC, uint sellFeeInUSDC, uint tokensForLiquidity, uint tokensForMarketing) = calculateNewLevel(amount, isBuy);

        uint transferableAmount = amount;
        uint tokensToSellForRewards = 0;
        if (shouldTakeFee) {
            if (tokensForMarketing > 0 || tokensForLiquidity > 0) {
                super._transfer(from, _feeWallet, tokensForMarketing);
                super._transfer(from, address(this), tokensForLiquidity);
                _tokensForLiquidity += tokensForLiquidity;
                transferableAmount -= tokensForMarketing.add(tokensForLiquidity);
            }
            if (sellFeeInUSDC > 0) {
                tokensToSellForRewards = getAmountOutForUsdcSell(sellFeeInUSDC);
                super._transfer(from, address(this), tokensToSellForRewards);
                transferableAmount -= tokensToSellForRewards;
            }
        }

        if (isSell && !_isSwappingBack) {
            _isSwappingBack = true;
            swapBack(tokensToSellForRewards);
            _isSwappingBack = false;
        }

        if (!isSwap && !isLiquidityOperation && !isExcludedFromFee && _tokensForLiquidity >= _addLiquidityAtAmount) {
                bool added = addLiquidity(_tokensForLiquidity);
                if(added) _tokensForLiquidity = 0;
        }

        if (buyerRewardInUSDC > 0) {
            _hodler.sendReward(to, buyerRewardInUSDC);
        }

        super._transfer(from, to, transferableAmount);
    }

    function getTransactionType(address from, address to, uint256 amount) private returns (bool, bool, bool) {
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(_uniswapV2Pair).getReserves();
        uint newUsdcBalance = ERC20(_usdc).balanceOf(_uniswapV2Pair);

        bool isBuy = from == _uniswapV2Pair && to != address(_uniswapV2Router);
        bool isSell = false;
        bool isLiquidityOperation = false;

        if (_isNonUniswapExchange[msg.sender]) {
            isBuy = from == _uniswapV2Pair;
            isSell = to == _uniswapV2Pair;
        } else {
            if ((msg.sender == address(_uniswapV2Router) || msg.sender == address(_uniswapV3Router)) && to == _uniswapV2Pair) {
                if (newUsdcBalance > reserve0) isLiquidityOperation = true;
                else isSell = true;
            }

            if (newUsdcBalance < reserve0 && to != _uniswapV2Pair) {
                if (isBuy) {
                    isLiquidityOperation = true;
                    isBuy = false;
                }
            }
        }

        if (isBuy) emit IsBuy(msg.sender, from, to, amount, newUsdcBalance);
        if (isSell) emit IsSell(msg.sender, from, to, amount, newUsdcBalance);
        if (isLiquidityOperation) emit IsLiquidityOperation(msg.sender, from, to, amount, newUsdcBalance);

        return (isSell, isBuy, isLiquidityOperation);
    }

    function getAmountOutForUsdcSell(uint usdcIn) internal returns (uint tokensReceived) {
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(_uniswapV2Pair).getReserves();
        tokensReceived = getAmountIn(usdcIn, reserve1, reserve0);
    }

    function getNewPrice(bool isBuy, uint amount) internal returns (uint, uint) {
        uint newPrice = 0;
        uint usdcSpent = 0;
        uint usdcReceived = 0;
        uint usdcFee = 0;
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(_uniswapV2Pair).getReserves();
        if (isBuy) {
            usdcSpent = getAmountIn(amount, reserve0, reserve1);
            newPrice = getAmountOut(1e18, reserve1.sub(amount), reserve0.add(usdcSpent));
        } else {
            usdcReceived = getAmountOut(amount, reserve1, reserve0);
            newPrice = getAmountOut(1e18, reserve1.add(amount), reserve0.sub(usdcReceived));
            usdcFee = usdcReceived.mul(_floorSellFee).div(100);
        }
        return (newPrice, usdcFee);
    }

    function calculateNewLevel(uint amount, bool isBuy) internal returns (uint, uint, uint, uint) {
        (uint newPrice, uint usdcFee) = getNewPrice(isBuy, amount);
        uint currentPrice = getCurrentPrice();

        uint buyerRewardInUSDC = 0;
        uint sellFeeInUSDC = 0;
        uint tokensForLiquidity = 0;
        uint tokensForMarketing = 0;

        if (newPrice < _supportLevel) {
            if (isBuy) {
                uint priceMovePercentage = newPrice.sub(currentPrice).mul(100000000).div(_supportLevel.sub(currentPrice));
                uint usdcRewardsBank = _hodler.getBalance();
                if (usdcRewardsBank > 0) {
                    buyerRewardInUSDC = priceMovePercentage.mul(usdcRewardsBank).div(100000000);
                }
            } else {
                sellFeeInUSDC = usdcFee;
            }
        } else if (newPrice >= _supportLevel && currentPrice < _supportLevel) {
            buyerRewardInUSDC = _hodler.getBalance();
        } else {
            uint256 numerator = amount.div(100);
            tokensForLiquidity = numerator.mul(_liquidityFee);
            tokensForMarketing = numerator.mul(_marketingFee);
        }

        if (newPrice > _supportLevel) {
            uint tempSupport = newPrice.sub(newPrice.div(100).mul(_supportPercentBelowATH));
            if (tempSupport > _supportLevel) _supportLevel = tempSupport;
        }

        return (buyerRewardInUSDC, sellFeeInUSDC, tokensForLiquidity, tokensForMarketing);
    }

    function swapBack(uint tokenAmount) private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0 || tokenAmount == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdc;

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_hodler),
            block.timestamp
        );
    }

    function getCurrentPrice() public view returns (uint price) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_uniswapV2Pair).getReserves();
        price = getAmountOut(1e18, reserve1, reserve0);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function addLiquidity(uint256 tokenAmount) private returns (bool) {
        if (tokenAmount > balanceOf(address(this))) return false;

        uint256 tokensToBeAdded = tokenAmount.div(2);

        uint256 myUSDCBefore = ERC20(_usdc).balanceOf(address(_hodler));
        _isSwappingBack = true;
        swapBack(tokensToBeAdded);
        _isSwappingBack = false;
        uint256 myUSDCAfter = ERC20(_usdc).balanceOf(address(_hodler));
        uint256 usdcToAdd = myUSDCAfter.sub(myUSDCBefore);
        _hodler.sendReward(address(this), usdcToAdd);

        _approve(address(this), address(_uniswapV2Router), tokensToBeAdded);
        ERC20(_usdc).approve(address(_uniswapV2Router), usdcToAdd);

        _uniswapV2Router.addLiquidity(
            address(_usdc),
            address(this),
            usdcToAdd,
            tokensToBeAdded,
            0,
            0,
            _feeWallet,
            block.timestamp
        );

        emit LiquidityAdded(usdcToAdd, tokensToBeAdded);
        return true;
    }

    function enableTrading() public onlyOwner {
        _tradingActive = true;
        _supportLevel = getCurrentPrice();
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setFeeWallet(address feeWallet) public onlyOwner {
        _feeWallet = feeWallet;
    }

    function setSupportLevel(uint256 supportLevel) public onlyOwner {
        _supportLevel = supportLevel;
    }

    function setNonUniswapExchange(address account, bool exists) public onlyOwner {
        _isNonUniswapExchange[account] = exists;
    }

    function setFloorSellFee(uint256 floorSellFee) public onlyOwner {
        _floorSellFee = floorSellFee;
    }

    function setSupportPercentBelowATH(uint256 supportPercentBelowATH) public onlyOwner {
        _supportPercentBelowATH = supportPercentBelowATH;
    }

    function setAddLiquidityAtAmount(uint256 addLiquidityAtAmount) public onlyOwner {
        _addLiquidityAtAmount = addLiquidityAtAmount;
    }

    function SetUniswapV3Router(address uniswapV3Router) public onlyOwner {
        _uniswapV3Router = uniswapV3Router;
    }

    function setTokensForLiquidity(uint256 tokensForLiquidity) public onlyOwner {
        _tokensForLiquidity = tokensForLiquidity;
    }

    function setBlackListed(address sender, bool exists) public onlyOwner {
        _isBlackListed[sender] = exists;
    }

    function setBlackListedSender(address sender, bool exists) public onlyOwner {
        _isBlackListedSender[sender] = exists;
    }

    function setHodler(address hodler) public onlyOwner {
        _hodler = Hodl(hodler);
    }

    function rescue(address token) public onlyOwner {
        ERC20 Token = ERC20(token);
        uint256 balance = Token.balanceOf(address(this));
        if(balance > 0) Token.transfer(_msgSender(), balance);
    }

    function setFees(uint256 marketingFee, uint256 liquidityFee) public onlyOwner {
        require(marketingFee.add(liquidityFee) <= 10, "Fees can't be greater than 10%");
        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
    }
}