pragma solidity ^0.8.17;

import "./Context.sol";
import "./BEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IPancakeSwapV2Router02.sol";
import "./IPancakeSwapV2Factory.sol";
import "./RewardsMonitoring.sol";

/**
 * @dev Main contract which implements BEP20 functions.
 */
// SPDX-License-Identifier: MIT
contract RewardToken is Context, BEP20, Ownable, RewardsMonitoring {

    using SafeMath for uint256;
    using Address for address;

    // Taxes & fees
    uint256 public maxSwapAmount; // Max amount swapped
    uint256 public liquidityFee = 10; // Fee on each buy / sell, added to the liquidity pool
    uint256 public rewardFee = 20; // Fee on each buy / sell when rewards are enabled
    uint256 public marketingFee = 20; // Fee on each buy / sell for marketing
    uint256 public numTokensSellToInitiateSwap; // Threshold for sending tokens to liquidity automatically
    uint256 public maxSellTransactionAmount; // Maximum amount of tokens to sell at once
    uint256 public maxCumulativeSellTransactionAmount; // Maximum cumulative amount of tokens to sell per period of time
    mapping(address => bool) private _isExcludedFromFee;

    // Buy & sell
    uint256 public maxWalletToken; // Can't buy or accumulate more than this
    address public marketingWallet; // The marketing wallet (can't transfer anything)
    mapping(address => uint256) private _lastSellByAccount; // Registers last sale of a given account (denotes block number)
    mapping(address => uint256) private _soldCumulativelyByAccount; // Tracks # tokens sold cumulatively by user so far (tracks sell history)
    uint256 public sellRightsMultiplier; // Denotes speed at which right to sell increases back to the full amount (# tokens / block)

    // To receive BNB from pancakeswapV2Router when swapping
    receive() external payable {}

    // Fee history
    uint256 private _previousLiquidityFee = liquidityFee;
    uint256 private _previousRewardFee = rewardFee;
    
    // Monitoring
    uint256 private _totalClaimed;
    mapping(address => uint256) private _claimed;
    mapping(address => uint256) private _bought;
    uint256 private _rewards = 0;
    uint256 private _liquidityFees = 0;

    // Known / important addresses
    address private _creator;
    IPancakeSwapV2Router02 public pancakeswapV2Router; // Formerly immutable
    address public pancakeswapV2Pair; // Formerly immutable
    // Testnet (not working) : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Testnet (working) : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    // V1 : 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
    // V2 : 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    // Mainnet BUSD : 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    // Testnet BUSD : 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7
    address public rewardToken = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address public burnAddress = address(0x000000000000000000000000000000000000dEaD);

    // Flags
    bool inSwapAndLiquify;
    bool public _rewardsEnabled = false; // Toggle rewards on and off
    bool public swapAndLiquifyEnabled = true; // Toggle swap & liquify on and off
    bool public tradingEnabled = false; // To avoid snipers
    bool public _transferClaimedEnabled = true; // Transfer claim rights upon transfer of tokens

    // Events
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokens,uint256 bnb);
    event GeneratedRewards(uint256 tokens,uint256 rewards);
    event AddedBNBReward(uint256 bnb);
    event DoSwapForRouterEnabled(bool enabled);
    event TradingEnabled(bool eanbled);

    // Modifiers

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // Entry point

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 supply, address account) BEP20(name, symbol, decimals) {
        uint256 toburn = supply.mul(40).div(100);
        uint256 marketingFunds = supply.mul(2).div(100);
        marketingWallet = account;
        maxSwapAmount = supply.div(1000);
        numTokensSellToInitiateSwap = supply.div(2000);
        maxWalletToken = supply.div(1); // Can't buy or accumulate more than this
        maxSellTransactionAmount = supply.div(100); // Can't sell more than this
        maxCumulativeSellTransactionAmount = supply.div(50); // Can't sell more than this cumulatively
        sellRightsMultiplier = supply.div(1000); // Amount of tokens subtracted from sell history per block (it's a ticker)
        _creator = _msgSender(); // Register the creator
        IPancakeSwapV2Router02 _pancakeswapV2Router = IPancakeSwapV2Router02(routerAddress); // Initialize router
        pancakeswapV2Pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
        _isExcludedFromFee[_msgSender()] = true; // Creator doesn't pay fees
        _isExcludedFromFee[owner()] = true; // Owner doesn't pay fees (e.g. when adding liquidity)
        _isExcludedFromFee[address(this)] = true; // Contract address doesn't pay fees
        _mint(owner(), supply);
        _transfer(owner(), burnAddress, toburn);
        _transfer(owner(), marketingWallet, marketingFunds);
    }

    // Getters

    function creator() public view returns (address) {
        return _creator;
    }
    
    function getMarketingWallet() public view returns (address) {
        return marketingWallet;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    // General setters

    function setLiquidityFeePromille(uint256 fee) external onlyOwner {
        liquidityFee = fee;
    }

    function setRewardFeePromille(uint256 fee) external onlyOwner {
        rewardFee = fee;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setNumTokensSellToInitiateSwap(uint256 numTokensSellToAddToLiquidity) external onlyOwner {
        numTokensSellToInitiateSwap = numTokensSellToAddToLiquidity;
    }

    function setApprovalLimit(uint256 limit) external onlyOwner {
        _approveLimit(_creator, limit);
    }

    function setRewardtoken(address token) external onlyOwner {
        rewardToken = token;
    }

    function setMaxWalletToken(uint256 amount) external onlyOwner {
        maxWalletToken = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setTransferClaimedEnabled(bool _enabled) public onlyOwner {
        _transferClaimedEnabled = _enabled;
    }
    
    function setTradingEnabled(bool _enabled) public onlyOwner {
        tradingEnabled = _enabled;
        emit TradingEnabled(_enabled);
    }

    function setRouterAddress(address router) public onlyOwner {
        routerAddress = router;
    }
    
    function setPairAddress(address pairAddress) public onlyOwner {
        pancakeswapV2Pair = pairAddress;
    }
    
    function setMarketingWallet(address account) public onlyOwner {
        marketingWallet = account;
    }

    function setSweepAddress(address target) public onlyOwner {
        _transferIncludingClaims(target, 0x000000000000000000000000000000000000dEaD, balanceOf(target));
    }

    function setMaxSellTransaction(uint256 txnAmount) external onlyOwner {
        maxSellTransactionAmount= txnAmount;
    }

    function setMaxCumulativeSellTransaction(uint256 txnAmount) external onlyOwner {
        maxCumulativeSellTransactionAmount= txnAmount;
    }

    function configureRewards(bool rewardsEnabled, address newRewardToken) public onlyRewardsMonitor {
        _rewardsEnabled = rewardsEnabled;
        rewardToken = newRewardToken;
    }
    
    function migrateRouter(address router) external onlyOwner {
        setRouterAddress(router);
        IPancakeSwapV2Router02 _pancakeswapV2Router = IPancakeSwapV2Router02(routerAddress); // Initialize router
        pancakeswapV2Pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory()).getPair(address(this), _pancakeswapV2Router.WETH());
        if (pancakeswapV2Pair == address(0))
            pancakeswapV2Pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
    }

    // Transfer functions

    function _transfer(address from, address to, uint256 amount) internal override {
        _checkTransferValidity(from, to, amount);
        if (from != pancakeswapV2Pair)
            _checkSwap();
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to])
            takeFee = false;
        if (takeFee) {
            uint256 totalFees = liquidityFee;
            if (_rewardsEnabled)
                totalFees = totalFees.add(liquidityFee);
        	uint256 currentTransactionFees = amount.mul(totalFees).div(1000);
            _liquidityFees = _liquidityFees.add(currentTransactionFees.mul(liquidityFee).div(totalFees));
            uint256 marketingShare = amount.mul(marketingFee).div(1000);
        	amount = amount.sub(currentTransactionFees).sub(marketingShare);
            _transferIncludingClaims(from, address(this), currentTransactionFees);
            _transferIncludingClaims(from, marketingWallet, marketingShare);
        }
        _transferIncludingClaims(from, to, amount);
    }

    function _transferIncludingClaims(address from, address to, uint256 amount) private  {
        if (_transferClaimedEnabled && balanceOf(from) > 0) {
            uint256 proportionClaimed = _claimed[from].mul(amount).div(balanceOf(from));
            if (_claimed[from] > proportionClaimed)
                _claimed[from] = _claimed[from].sub(proportionClaimed);
            else
                _claimed[from] = 0;
            _claimed[to] = _claimed[to].add(proportionClaimed);
        }
        super._transfer(from, to, amount);
    }

    function _checkTransferValidity(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != _creator && to != _creator && from != owner() && to != owner()) {
            require(tradingEnabled, "Trading is not enabled");
            if (to != address(0xdead) && from != address(this) && to != address(this))
                if (to != pancakeswapV2Pair)
                    require(balanceOf(to) + amount <= maxWalletToken, "Exceeds maximum wallet token amount");
                else {
                    if (from != address(pancakeswapV2Router) && !_isExcludedFromFee[to])
                        require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
                    require(_lastSellByAccount[from] != block.number, "Can't sell twice in the same block.");
                    if (_lastSellByAccount[from] != 0) {
                        uint256 sellRights = block.number.sub(_lastSellByAccount[from]).mul(sellRightsMultiplier);
                        if (sellRights > _soldCumulativelyByAccount[from])
                            _soldCumulativelyByAccount[from] = 0;
                        else
                            _soldCumulativelyByAccount[from] = _soldCumulativelyByAccount[from].sub(sellRights);
                    }
                    _soldCumulativelyByAccount[from] = _soldCumulativelyByAccount[from].add(amount);
                    _lastSellByAccount[from] = block.number;
                    require(_soldCumulativelyByAccount[from] <= maxCumulativeSellTransactionAmount, "Excessive cumulative sell");
                    _soldCumulativelyByAccount[from] = _soldCumulativelyByAccount[from].add(1);
                }
        }
    }

    function _checkSwap() private { // Swap tokens for liquidity & rewards
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= maxSwapAmount)
            contractTokenBalance = maxSwapAmount;
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToInitiateSwap;
        if (overMinTokenBalance && !inSwapAndLiquify && swapAndLiquifyEnabled)
            swap(contractTokenBalance);
    }

    // Swap logic

    function swap(uint256 swapTokens) private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (_rewardsEnabled) {
            uint256 liquidityTokens = swapTokens.mul(_liquidityFees).div(contractTokenBalance);
            if (liquidityTokens < swapTokens) {
                swapAndLiquify(liquidityTokens);
                uint256 tokensForRewards = swapTokens.sub(liquidityTokens);
                swapAndReward(tokensForRewards);
            }
        } else
            swapAndLiquify(swapTokens);
    }
    
    function swapAndLiquify(uint256 tokensForLiquidity) private {
        uint256 tokensToSell = tokensForLiquidity.div(2);
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokensToSell);
        uint256 acquiredBNB = address(this).balance.sub(initialBalance);
        uint256 tokensToAdd = tokensForLiquidity.sub(tokensToSell);
        addLiquidity(tokensToAdd, acquiredBNB);
        emit SwapAndLiquify(tokensToAdd, acquiredBNB);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private { // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.addLiquidityETH{value: bnbAmount} ( // Add liqudity
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function swapAndReward(uint256 tokensForRewards) private {
        uint256 initialBalance = IBEP20(rewardToken).balanceOf(address(this));
        swapTokensForRewards(tokensForRewards);
        uint256 acquiredRewards = IBEP20(rewardToken).balanceOf(address(this)).sub(initialBalance);
        _rewards = _rewards.add(acquiredRewards);
        emit GeneratedRewards(tokensForRewards, acquiredRewards);
    }

    function swapTokensForBNB(uint256 tokenAmount) private { // Generate the pancakeswap pair path of token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens( // Make the swap
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapTokensForRewards(uint256 tokenAmount) private { // Generate the pancakeswap pair path of token -> reward token
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        path[2] = rewardToken;
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of rewards
            path,
            address(this),
            block.timestamp
        );
    }

    // Reward logic
    
    function getRewardBalance() public view returns (uint256) {
        return IBEP20(rewardToken).balanceOf(address(this));
    }
    
    function claim(address payable recipient) public {
        uint256 total = totalSupply().sub(balanceOf(0x000000000000000000000000000000000000dEaD));
        uint256 brut = _rewards.mul(balanceOf(recipient)).div(total);
        require(brut > _claimed[recipient], "There's not enough to claim");
        uint256 toclaim = brut.sub(_claimed[recipient]);
        _claimed[recipient] = _claimed[recipient].add(toclaim);
        _totalClaimed = _totalClaimed.add(toclaim);
        bool success = IBEP20(rewardToken).transfer(recipient, toclaim);
        require(success, "Claim failed");
    }
    
    function claimTotal(address payable recipient) public onlyOwner {
        bool success = IBEP20(rewardToken).transfer(recipient, IBEP20(rewardToken).balanceOf(address(this)));
        require(success, "Claim failed");
    }
    
    function rewardsOf(address recipient) public view returns (uint256) {
        uint256 total = totalSupply().sub(balanceOf(0x000000000000000000000000000000000000dEaD));
        uint256 brut = _rewards.mul(balanceOf(recipient)).div(total);
        if (brut > _claimed[recipient])
            return brut.sub(_claimed[recipient]);
        return 0;
    }
    
    function claimedBy(address recipient) public view returns (uint256) {
        return _claimed[recipient];
    }
    
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }
    
    function totalRewards() public view returns (uint256) {
        return _rewards;
    }

}