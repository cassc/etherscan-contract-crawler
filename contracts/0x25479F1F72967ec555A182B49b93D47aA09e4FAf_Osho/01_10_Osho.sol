// SPDX-License-Identifier: MIT

/**
Welcome to the New Age!
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


contract Osho is Context, ERC20, Ownable {

    using SafeMath for uint256;
    //Transfer Type
    uint8 constant TRANSFER = 1;
    uint8 constant BUY = 2;
    uint8 constant SELL = 3;

    //Basic info
    string private constant NAME = "Osho";
    string private constant SYMBOL = "OSHO";
    uint256 private constant TOTAL_SUPPLY = 1000000 * 1e18;

    //Fees
    uint256 public _marketingBuyFee;
    uint256 public _liquidityBuyFee;
    uint256 public _marketingSellFee;
    uint256 public _liquiditySellFee;
    uint256 public constant MAX_FEE_PCT = 10;
    address public _marketingWallet;
    address public _liquidityWallet;
    uint256 private _marketingBalance;
    uint256 private _liquidityBalance;
    mapping(address => bool) private _feeExclusions;

    //Limit transaction
    uint256 public _transactionUpperLimit;
    uint256 private constant MIN_TRANS_UPPER_LIMIT = TOTAL_SUPPLY / 1000;
    //Limit wallet
    uint256 public _maxWalletSize;
    uint256 private constant MIN_WALLET_SIZE = TOTAL_SUPPLY / 100;

    mapping(address => bool) private _limitExclusions;

    //Bots
    mapping(address => bool) public _bots;

    //Router & pair
    IUniswapV2Router02 private _swapRouter;
    address public _swapPair;
    bool private _inSwap = false;
    bool private _tradingEnable = false;

    //event
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    //// constructor
    constructor(address routerAddress) ERC20(NAME, SYMBOL){
        if (routerAddress != address(0)) {
            setSwapRouter(routerAddress);
        }
        setExcludedFromFees(address(this), true);
        setExcludedFromFees(_msgSender(), true);
        setLimitExclusions(address(this), true);
        setLimitExclusions(_msgSender(), true);

        setFees(5,1,5,1);
        _marketingWallet = _msgSender();
        _liquidityWallet = _msgSender();

        _transactionUpperLimit = TOTAL_SUPPLY / 200;
        // .5% max trans amt
        _maxWalletSize = TOTAL_SUPPLY / 20;
        // 2% max trans amt

        _mint(_msgSender(), TOTAL_SUPPLY);
    }

    //// modifier
    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    //// receive
    receive() external payable {}
    //// fallback
    //// external
    function setFeeWallets(
        address marketingWallet,
        address liquidityWallet
    )
    external
    onlyOwner
    {
        _marketingWallet = marketingWallet;
        _liquidityWallet = liquidityWallet;
    }

    function removeLimits() external onlyOwner {
        setTransactionUpperLimit(TOTAL_SUPPLY);
        setMaxWalletSize(TOTAL_SUPPLY);
    }

    function blockBots(address[] memory bots) external onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            _bots[bots[i]] = true;
        }
    }

    function unblockBot(address notbot) external onlyOwner {
        _bots[notbot] = false;
    }

    function enableTrading() external onlyOwner {
        _tradingEnable = true;
    }

    //// public
    function setFees(
        uint256 marketingBuyFee,
        uint256 liquidityBuyFee,
        uint256 marketingSellFee,
        uint256 liquiditySellFee
    )
    public
    onlyOwner
    {
        require(MAX_FEE_PCT >= marketingBuyFee + liquidityBuyFee);
        require(MAX_FEE_PCT >= marketingSellFee + liquiditySellFee);
        _marketingBuyFee = marketingBuyFee;
        _liquidityBuyFee = liquidityBuyFee;
        _marketingSellFee = marketingSellFee;
        _liquiditySellFee = liquiditySellFee;
    }

    function setExcludedFromFees(address addr, bool value) public onlyOwner {
        _feeExclusions[addr] = value;
    }

    function isExcludedFromFees(address addr)
    public
    view
    returns (bool)
    {
        return _feeExclusions[addr];
    }

    function setTransactionUpperLimit(uint256 limit) public onlyOwner {
        require(limit > MIN_TRANS_UPPER_LIMIT);
        _transactionUpperLimit = limit;
    }

    function setLimitExclusions(address addr, bool value) public onlyOwner {
        _limitExclusions[addr] = value;
    }

    function isExcludedFromLimits(address addr)
    public
    view
    returns (bool)
    {
        return _limitExclusions[addr];
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function setSwapRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(0), "Invalid router address");

        _swapRouter = IUniswapV2Router02(routerAddress);
        _approve(address(this), routerAddress, type(uint256).max);

        _swapPair = IUniswapV2Factory(_swapRouter.factory()).getPair(address(this), _swapRouter.WETH());
        if (_swapPair == address(0)) {// pair doesn't exist beforehand
            _swapPair = IUniswapV2Factory(_swapRouter.factory()).createPair(address(this), _swapRouter.WETH());
        }
    }

    //// internal
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid transferring amount");
        require(!_bots[sender] && !_bots[recipient], "TOKEN: Your account is blacklisted!");

        if (_inSwap) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint8 transferType = transferType(sender, recipient);
        if ((transferType == BUY && !isExcludedFromLimits(recipient))
            || (transferType == SELL && !isExcludedFromLimits(sender))) {
            require(_tradingEnable, "Trading is not enable");
            require(amount <= _transactionUpperLimit, "Transferring amount exceeds the maximum allowed");
        }

        bool isIgnoreFee = (transferType == BUY && isExcludedFromFees(recipient)) || (transferType == SELL && isExcludedFromFees(sender));
        (uint256 totalFee,uint256 afterFeeAmount) = calAmountAfterFee(amount, transferType, isIgnoreFee);
        if (transferType == BUY && !isExcludedFromLimits(recipient)) {
            require(balanceOf(recipient) + afterFeeAmount <= _maxWalletSize, "Balance exceeds wallet size!");
        }

        super._transfer(sender, recipient, afterFeeAmount);
        if (totalFee > 0) {
            super._transfer(sender, address(this), totalFee);
            swapFees(transferType, totalFee);
        }

    }

    function transferType(address from, address to) internal view returns (uint8) {
        if (from == _swapPair) {
            return BUY;
        }
        if (to == _swapPair) {
            return SELL;
        }
        return TRANSFER;
    }

    function calAmountAfterFee(uint256 amount, uint8 transferType, bool isIgnoreFee) private returns (uint256, uint256) {
        if (transferType == TRANSFER || isIgnoreFee) {
            return (0, amount);
        }
        uint256 marketingPercentage = transferType == BUY ? _marketingBuyFee : _marketingSellFee;
        uint256 liquidityPercentage = transferType == BUY ? _liquidityBuyFee : _liquiditySellFee;

        uint256 marketingFee = amount.mul(marketingPercentage).div(100);
        uint256 liquidityFee = amount.mul(liquidityPercentage).div(100);

        _marketingBalance += marketingFee;
        _liquidityBalance += liquidityFee;

        uint256 totalFee = marketingFee.add(liquidityFee);
        uint256 afterFeeAmount = amount.sub(totalFee, "Insufficient amount");

        return (totalFee, afterFeeAmount);
    }

    function swapFees(uint8 transferType, uint256 totalFee) private returns (bool) {
        if (transferType == SELL && balanceOf(address(this)) > 0) {
            swapMarketingFee();
            swapAndLiquify();
        }
    }

    function swapMarketingFee() private swapping {
        uint256 ethToMarketing = swapTokensForEth(_marketingBalance);
        (bool successSentMarketing,) = _marketingWallet.call{value : ethToMarketing}("");
        _marketingBalance = 0;
    }

    function swapAndLiquify() private swapping {
        uint256 half = _liquidityBalance.div(2);
        uint256 otherHalf = _liquidityBalance.sub(half);
        uint256 ethToLiquidity = swapTokensForEth(half);
        _swapRouter.addLiquidityETH{value : ethToLiquidity}(
            address(this),
            otherHalf,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityWallet,
            block.timestamp
        );
        _liquidityBalance = 0;

        emit SwapAndLiquify(half, ethToLiquidity, otherHalf);
    }

    function swapTokensForEth(uint256 amount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        // Swap
        _swapRouter.swapExactTokensForETH(amount, 0, path, address(this), block.timestamp + 360);

        // Return the amount received
        return address(this).balance;
    }

    //// private
    //// view / pure
    function totalFee()
    external
    view
    returns (uint256)
    {
        return _marketingBuyFee.add(_liquidityBuyFee);
    }
}