// SPDX-License-Identifier: MIT

/**
47 Ronin

“A man will only be as long as his life but his name will be for all time.”

Every 47th Ronin will earn the treasury of his life..
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


contract Ronin is Context, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    string private constant NAME = "47 Ronin";
    string private constant SYMBOL = "47RONIN";
    uint8 private constant DECIMALS = 18;

    uint256 private constant _totalSupply = 47000000 * 10 ** DECIMALS;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    bool public _tradingOpen = false;

    uint256 public _rewardBuyFee;
    uint256 public _marketingBuyFee;
    uint256 public _liquidityBuyFee;
    uint256 public _rewardSellFee;
    uint256 public _marketingSellFee;
    uint256 public _liquiditySellFee;
    uint256 public constant _maxFeePercentage = 10;
    address public _marketingWallet;
    address public _liquidityWallet;
    uint256 private _marketingBalance;
    uint256 private _rewardBalance;
    uint256 private _liquidityBalance;
    mapping(address => bool) private _feeExclusions;

    uint256 public _rewardCounter;
    uint256 public _rewardMinBuy = 1 * 10 ** (DECIMALS) / 10; //0.1 eth
    address public _lastWinner;
    uint256 private constant FORTY_SEVEN = 23;
    uint256 private constant ROUTER_FEE_PCT = 30; //uniswap take 0.3%
    uint256 private constant MAX_PCT = 10000;

    uint256 public _transactionUpperLimit = _totalSupply;
    uint256 private constant MIN_TRANS_UPPER_LIMIT = _totalSupply / 1000;
    mapping(address => bool) private _limitExclusions;

    uint8 constant FEE_EXEMPT = 0;
    uint8 constant TRANSFER = 1;
    uint8 constant BUY = 2;
    uint8 constant SELL = 3;

    IUniswapV2Router02 private _swapRouter;
    address public _swapPair;
    bool private _inSwap;

    event UpdateRewardCounter(
        uint256 currentCounter
    );

    event Reward(
        address winner,
        uint256 tokenAmount
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(address routerAddress) {
        _balances[_msgSender()] = totalSupply();

        _feeExclusions[address(this)] = true;
        _feeExclusions[_msgSender()] = true;
        _limitExclusions[_msgSender()] = true;

        _marketingWallet = _msgSender();
        _liquidityWallet = _msgSender();

        setFees(3, 2, 1, 5, 2, 1);
        setTransactionUpperLimit(_totalSupply / 100 + 1);
        if (routerAddress != address(0)) {
            setSwapRouter(routerAddress);
        }

        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    receive() external payable {}

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

    function setExcludedFromFees(address addr, bool value) external onlyOwner {
        _feeExclusions[addr] = value;
    }

    function setRewardMinBuy(uint256 rewardMinBuy) external onlyOwner {
        _rewardMinBuy = _rewardMinBuy;
    }

    function openTrading() external onlyOwner {
        _tradingOpen = true;
    }

    function removeLimit() external onlyOwner {
        _transactionUpperLimit = _totalSupply;
    }

    function setFees(
        uint256 marketingBuyFee,
        uint256 rewardBuyFee,
        uint256 liquidityBuyFee,
        uint256 marketingSellFee,
        uint256 rewardSellFee,
        uint256 liquiditySellFee
    )
    public
    onlyOwner
    {
        require(_maxFeePercentage >= marketingBuyFee + rewardBuyFee + liquidityBuyFee);
        require(_maxFeePercentage >= marketingSellFee + rewardSellFee + liquiditySellFee);
        _marketingBuyFee = marketingBuyFee;
        _rewardBuyFee = rewardBuyFee;
        _liquidityBuyFee = liquidityBuyFee;
        _marketingSellFee = marketingSellFee;
        _rewardSellFee = rewardSellFee;
        _liquiditySellFee = liquiditySellFee;
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

    function isExcludedFromLimit(address addr)
    public
    view
    returns (bool)
    {
        return _limitExclusions[addr];
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
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Invalid owner address");
        require(spender != address(0), "Invalid spender address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid transferring amount");

        if (!isExcludedFromLimit(sender) && !isExcludedFromLimit(recipient)) {
            require(amount <= _transactionUpperLimit, "Transferring amount exceeds the maximum allowed");
            require(_tradingOpen, "Trading is not open");
        }

        if (_inSwap) {
            basicTransfer(sender, recipient, amount);
            return;
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient balance");
        uint8 transferType = transferType(sender, recipient);
        uint256 afterFeeAmount = takeFees(amount, transferType);
        _balances[recipient] = _balances[recipient].add(afterFeeAmount);


        if (transferType == BUY || transferType == SELL) {
            _rewardCounter++;
            if (shouldReward(amount, transferType)) {
                //Only reward on BUY transaction => Then we send the reward for recipient (buyer)
                reward(recipient);
            }
            emit UpdateRewardCounter(_rewardCounter);
        }

        emit Transfer(sender, recipient, afterFeeAmount);
    }

    function transferType(address from, address to) internal view returns (uint8) {
        if (isExcludedFromFees(from) || isExcludedFromFees(to)) return FEE_EXEMPT;
        if (from == _swapPair) return BUY;
        if (to == _swapPair) return SELL;
        return TRANSFER;
    }

    function basicTransfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function takeFees(uint256 amount, uint8 transferType) private returns (uint256) {
        if (transferType != BUY && transferType != SELL) {
            return amount;
        }
        uint256 marketingPercentage = transferType == BUY ? _marketingBuyFee : _marketingSellFee;
        uint256 rewardPercentage = transferType == BUY ? _rewardBuyFee : _rewardSellFee;
        uint256 liquidityPercentage = transferType == BUY ? _liquidityBuyFee : _liquiditySellFee;

        uint256 marketingFee = amount.mul(marketingPercentage).div(100);
        uint256 rewardFee = amount.mul(rewardPercentage).div(100);
        uint256 liquidityFee = amount.mul(liquidityPercentage).div(100);

        _marketingBalance += marketingFee;
        _rewardBalance += rewardFee;
        _liquidityBalance += liquidityFee;

        uint256 totalFee = marketingFee.add(rewardFee).add(liquidityFee);
        _balances[address(this)] = _balances[address(this)].add(totalFee);
        uint256 afterFeeAmount = amount.sub(totalFee, "Insufficient amount");

        if (shouldSwapFees(transferType)) {
            swapFees();
            swapAndLiquify();
        }

        return afterFeeAmount;
    }

    function shouldSwapFees(uint8 transferType) private returns (bool) {
        return transferType == SELL && balanceOf(address(this)) > 0;
    }

    function swapFees() private swapping {
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

    function shouldReward(uint256 amount, uint8 transferType) private returns (bool){
        if (transferType != BUY) {
            return false;
        }
        if (_rewardCounter < FORTY_SEVEN) {
            return false;
        }
        if (_rewardMinBuy == 0) {
            return true;
        }
        address[] memory path = new address[](2);
        path[0] = _swapRouter.WETH();
        path[1] = address(this);

        // We don't subtract the buy fee since the amount is pre-tax
        uint256 tokensOut = _swapRouter.getAmountsOut(_rewardMinBuy, path)[1].mul(MAX_PCT.sub(ROUTER_FEE_PCT)).div(MAX_PCT);
        return amount >= tokensOut;
    }

    function reward(address winner) private {
        uint256 rewardAmount = _rewardBalance;
        _lastWinner = winner;
        _rewardCounter = 0;
        _rewardBalance = 0;
        basicTransfer(address(this), winner, rewardAmount);

        emit Reward(winner, rewardAmount);
    }

    //// private
    //// view / pure
    function totalFee()
    external
    view
    returns (uint256)
    {
        return _marketingBuyFee.add(_rewardBuyFee).add(_liquidityBuyFee);
    }

    //region IERC20
    function totalSupply()
    public
    override
    pure
    returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function balanceOf(address account)
    public
    view
    override
    returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
    public
    override
    returns (bool)
    {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()].sub(amount, "Insufficient allowance");
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    //region IERC20Metadata
    function name()
    public
    override
    pure
    returns (string memory)
    {
        return NAME;
    }

    function symbol()
    public
    override
    pure
    returns (string memory)
    {
        return SYMBOL;
    }

    function decimals()
    public
    override
    pure
    returns (uint8)
    {
        return DECIMALS;
    }
}