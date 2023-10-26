// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import openzeppelin ownable
import "@openzeppelin/contracts/access/Ownable.sol";

contract IGGY is ERC20, Ownable, ReentrancyGuard {
    // =========================================================================
    // dependencies.
    // =========================================================================

    IUniswapV2Router02 public constant router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable deployer;
    address public marketingWallet;

    // =========================================================================
    // rewards management.
    // =========================================================================

    // numerator multiplier so ETHR does not get rounded to 0.
    uint256 private constant precision = 1e18;

    // the amount of ETH per share.
    uint256 private ETHR;

    // total shares of this token.
    // (different from total supply because of fees and excluded wallets).
    uint256 public totalShares;

    // total amount of ETH ever distributed.
    uint256 public totalETHRewards;

    //Anti-bot and limitations
    uint256 public startBlock = 0;
    uint256 public deadBlocks = 2;
    mapping(address => bool) public isBlacklisted;
    uint256 public maxWallet;

    // shareholders record.
    // (non excluded addresses are updated after they send/receive tokens).
    mapping(address => Share) private shareholders;

    struct Share {
        uint256 amount; // recorded balance after last transfer.
        uint256 earned; // amount of ETH earned but not claimed yet.
        uint256 ETHRLast; // ETHR value of the last time ETH was earned.
        uint256 lastBlockUpdate; // last block share was updated.
    }

    // =========================================================================
    // fees.
    // =========================================================================

    // bps denominator.
    uint256 public constant feeDenominator = 10000;

    // buy taxes bps.
    uint256 public buyRewardFee = 0;
    uint256 public buyMarketingFee = 2000;
    uint256 public buyTotalFee = buyRewardFee + buyMarketingFee;

    // sell taxes bps.
    uint256 public sellRewardFee = 0;
    uint256 public sellMarketingFee = 3000;
    uint256 public sellTotalFee = sellRewardFee + sellMarketingFee;

    // amm pair addresses the tranfers from/to are taxed.
    // (populated with WETH/this token pair address in the constructor).
    mapping(address => bool) public pairs;

    // addresses not receiving rewards.
    // (populated with this token address in the constructor).
    mapping(address => bool) public excludedFromRewards;

    // =========================================================================
    // claims.
    // =========================================================================

    // total claimed EHT.
    uint256 public totalClaimedETH;

    // total claimed ERC20.
    mapping(address => uint256) public totalClaimedERC20;

    // =========================================================================
    // marketing.
    // =========================================================================

    // the amount of this token collected as marketing fee.
    uint256 private _marketingFeeAmount;

    // =========================================================================
    // Events.
    // =========================================================================

    event ClaimETH(address indexed addr, uint256 amount);
    event ClaimERC20(
        address indexed addr,
        address indexed token,
        uint256 amount
    );

    // =========================================================================
    // constructor.
    // =========================================================================

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        uint256 _totalSupply = 1_000_000_000 * 10 ** decimals();
        maxWallet = _totalSupply / 100;
        // create an amm pair with WETH.
        // pair gets automatically excluded from rewards.
        createAmmPairWith(router.WETH());

        // exclude this contract and router from rewards.
        _excludeFromRewards(address(this));
        _excludeFromRewards(address(router));
        _excludeFromRewards(msg.sender);

        // mint total supply to owner.
        _mint(address(this), _totalSupply);

        deployer = marketingWallet = msg.sender;
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function blacklistAddress(
        address _target,
        bool _status
    ) external onlyOwner {
        isBlacklisted[_target] = _status;
    }

    function init() external payable onlyOwner {
        require(startBlock == 0, "already initialized");
        startBlock = block.number;
        _addLiquidity();
    }

    function removeLimits() external onlyOwner {
        maxWallet = totalSupply();
    }

    // =========================================================================
    // exposed view functions.
    // =========================================================================

    function currentRewards() public view returns (uint256) {
        uint256 balance = balanceOf(address(this));

        if (balance > _marketingFeeAmount) {
            return balance - _marketingFeeAmount;
        }

        return 0;
    }

    function currentRewards(address addr) public view returns (uint256) {
        uint256 currentTotalShares = totalShares;

        if (currentTotalShares == 0) return 0;

        return
            (currentRewards() * shareholders[addr].amount) / currentTotalShares;
    }

    function pendingRewards(address addr) external view returns (uint256) {
        return _pendingRewards(shareholders[addr]);
    }

    // =========================================================================
    // exposed user functions.
    // =========================================================================

    function claim() external nonReentrant {
        uint256 claimedETH = _claim(msg.sender);

        if (claimedETH == 0) return;

        payable(msg.sender).transfer(claimedETH);

        totalClaimedETH += claimedETH;

        emit ClaimETH(msg.sender, claimedETH);
    }

    function claim(address token, uint256 minAmountOut) external nonReentrant {
        uint256 claimedETH = _claim(msg.sender);

        if (claimedETH == 0) return;

        uint256 claimedERC20 = _swapETHToERC20(
            claimedETH,
            token,
            msg.sender,
            minAmountOut
        );

        totalClaimedERC20[token] += claimedERC20;

        emit ClaimERC20(msg.sender, token, claimedERC20);
    }

    function distribute() external {
        uint256 amountToSwap = currentRewards();
        uint256 currentTotalShares = totalShares;

        require(amountToSwap > 0, "no reward to distribute");
        require(currentTotalShares > 0, "no one to distribute");
        require(
            shareholders[msg.sender].lastBlockUpdate < block.number,
            "transfer and distribute not allowed"
        );

        uint256 swappedETH = _swapback(amountToSwap);

        ETHR += (swappedETH * precision) / currentTotalShares;

        totalETHRewards += swappedETH;
    }

    function createAmmPairWith(address addr) public {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

        address pair = factory.createPair(addr, address(this));

        pairs[pair] = true;

        _excludeFromRewards(pair);
    }

    function recordAmmPairWith(address addr) public {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

        address pair = factory.getPair(addr, address(this));

        pairs[pair] = true;

        _excludeFromRewards(pair);
    }

    function sweep(address addr) external {
        require(address(this) != addr, "cant sweep this token");

        IERC20 token = IERC20(addr);

        uint256 amount = token.balanceOf(address(this));

        token.transfer(deployer, amount);
    }

    function sweepETH() external onlyOwner {
        uint256 amount = address(this).balance;

        payable(deployer).transfer(amount);
    }

    // =========================================================================
    // exposed admin functions.
    // =========================================================================

    function excludeFromRewards(address addr) external onlyOwner {
        _excludeFromRewards(addr);
    }

    function includeToRewards(address addr) external onlyOwner {
        _includeToRewards(addr);
    }

    function setBuyFee(
        uint256 rewardFee,
        uint256 marketingFee
    ) external onlyOwner {
        require(rewardFee + marketingFee <= 30000, "30% total buy fee max");

        buyRewardFee = rewardFee;
        buyMarketingFee = marketingFee;
        buyTotalFee = rewardFee + marketingFee;
    }

    function setSellFee(
        uint256 rewardFee,
        uint256 marketingFee
    ) external onlyOwner {
        require(rewardFee + marketingFee <= 30000, "30% total sell fee max");

        sellRewardFee = rewardFee;
        sellMarketingFee = marketingFee;
        sellTotalFee = rewardFee + marketingFee;
    }

    function marketingFeeAmount() external view onlyOwner returns (uint256) {
        return _marketingFeeAmount;
    }

    function withdrawMarketing() external {
        uint256 amount = _marketingFeeAmount;

        _marketingFeeAmount = 0;

        uint256 _amountOut = _swapback(amount);
        payable(marketingWallet).transfer(_amountOut);
    }

    // =========================================================================
    // internal functions.
    // =========================================================================

    /**
     * Override the transfer method in order to take fee when transfer is from/to
     * a registered amm pair.
     *
     * - transfers from/to this contract are not taxed
     * - transfers from/to owner of this contract are not taxed.
     * - transfers from/to uniswap router are not taxed.
     * - marketing fees are collected here.
     * - taxes are sent to this very contract for later distribution.
     * - updates the shares of both the from and to addresses.
     */

    function _addLiquidity() internal {
        uint256 ts = balanceOf(address(this));
        uint256 initialBalance = address(this).balance;
        _approve(address(this), address(router), ts);

        router.addLiquidityETH{value: initialBalance}(
            address(this),
            ts,
            0,
            0,
            deployer,
            block.timestamp
        );
    }

    function _antiBot(address from, address to) internal {
        if (block.number <= startBlock + deadBlocks) {
            if (pairs[from]) {
                isBlacklisted[to] = true;
            }
            if (pairs[to]) {
                isBlacklisted[from] = true;
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBlacklisted[from], "blacklisted");

        // get owner address.
        address owner = owner();

        // get the addresses excluded from taxes.
        bool isSelf = address(this) == from || address(this) == to;
        bool isOwner = owner == from || owner == to;
        bool isRouter = address(router) == from || address(router) == to;

        // check if it is a taxed buy or sell.
        bool isTaxedBuy = pairs[from] && !isSelf && !isOwner && !isRouter;
        bool isTaxedSell = pairs[to] && !isSelf && !isOwner && !isRouter;

        // compute the reward fees and the marketing fees.
        uint256 rewardFee = (isTaxedBuy ? buyRewardFee : 0) +
            (isTaxedSell ? sellRewardFee : 0);
        uint256 marketingFee = (isTaxedBuy ? buyMarketingFee : 0) +
            (isTaxedSell ? sellMarketingFee : 0);

        // compute the fee amount.
        uint256 transferRewardFeeAmount = (amount * rewardFee) / feeDenominator;
        uint256 transferMarketingFeeAmount = (amount * marketingFee) /
            feeDenominator;
        uint256 transferTotalFeeAmount = transferRewardFeeAmount +
            transferMarketingFeeAmount;

        if (!pairs[to] && !isSelf && !isRouter) {
            require(amount + balanceOf(to) <= maxWallet, "max-wallet-reached");
        }

        // actually transfer the tokens minus the fee.
        super._transfer(from, to, amount - transferTotalFeeAmount);
        if (pairs[from])
            _antiBot(from, to);

        // accout fot the marketing fee if any.
        if (transferMarketingFeeAmount > 0) {
            _marketingFeeAmount += transferMarketingFeeAmount;
        }

        // transfer the total fee amount to this contract if any.
        if (transferTotalFeeAmount > 0) {
            super._transfer(from, address(this), transferTotalFeeAmount);
        }

        // updates shareholders values.
        _updateShare(from);
        _updateShare(to);
    }

    /**
     * Update the total shares and the shares of the given address if it is not
     * excluded from rewards.
     *
     * Earn first with his current share amount then update shares according to
     * its new balance.
     */
    function _updateShare(address addr) private {
        if (excludedFromRewards[addr]) return;

        Share storage share = shareholders[addr];

        _earn(share);

        uint256 balance = balanceOf(addr);

        totalShares = totalShares - share.amount + balance;

        share.amount = balance;
        share.lastBlockUpdate = block.number;
    }

    /**
     * Compute the pending rewards of the given share.
     *
     * The rewards earned since the last transfer are added to the already earned
     * rewards.
     */
    function _pendingRewards(
        Share memory share
    ) private view returns (uint256) {
        uint256 RDiff = ETHR - share.ETHRLast;
        uint256 earned = (share.amount * RDiff) / precision;

        return share.earned + earned;
    }

    /**
     * Earn the rewards of the given share.
     */
    function _earn(Share storage share) private {
        uint256 pending = _pendingRewards(share);

        share.earned = pending;
        share.ETHRLast = ETHR;
    }

    /**
     * Claim the ETH rewards of user and returns the amount.
     */
    function _claim(address addr) private returns (uint256) {
        Share storage share = shareholders[addr];

        _earn(share);

        uint256 earned = share.earned;

        share.earned = 0;

        return earned;
    }

    /**
     * Exclude the given address from rewards.
     *
     * Earn its rewards then remove it from total shares.
     */
    function _excludeFromRewards(address addr) private {
        excludedFromRewards[addr] = true;

        Share storage share = shareholders[addr];

        _earn(share);

        totalShares -= share.amount;

        share.amount = 0;
    }

    /**
     * Include the given address to rewards.
     *
     * It must be excluded first.
     *
     * Add its balance to totalShares.
     */
    function _includeToRewards(address addr) private {
        require(
            excludedFromRewards[addr],
            "the given address must be excluded"
        );

        excludedFromRewards[addr] = false;

        Share storage share = shareholders[addr];

        uint256 balance = balanceOf(addr);

        totalShares += balance;

        share.amount = balance;
        share.ETHRLast = ETHR;
    }

    /**
     * Sell the given amount of tokens for ETH and return the amount received.
     */
    function _swapback(uint256 amount) private returns (uint256) {
        // approve router to spend tokens.
        _approve(address(this), address(router), amount);

        // keep the original ETH balance to compute the swapped amount.
        uint256 originalBalance = payable(address(this)).balance;

        // swapback the whole amount to eth.
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        // return the received amount.
        return payable(address(this)).balance - originalBalance;
    }

    /**
     * Sell the given amount of ETH for given ERC20 address to a given address and returns
     * the amount it received.
     */
    function _swapETHToERC20(
        uint256 ETHAmount,
        address token,
        address to,
        uint256 minAmountOut
    ) private returns (uint256) {
        uint256 originalBalance = IERC20(token).balanceOf(to);

        // swapback the given ETHAmount to token.
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ETHAmount
        }(minAmountOut, path, to, block.timestamp);

        return IERC20(token).balanceOf(to) - originalBalance;
    }

    /**
     * Only receive ETH from uniswap (router or pair).
     */
    receive() external payable {
        require(
            msg.sender == address(router) || pairs[msg.sender],
            "cant send eth to this address"
        );
    }
}