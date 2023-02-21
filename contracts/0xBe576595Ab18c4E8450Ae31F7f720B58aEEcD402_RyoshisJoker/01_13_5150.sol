// https://t.me/StraitJackets

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache-2.0

import "./SafeMath.sol";
import "./Address.sol";
import "./RewardsToken.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";
import "./IRewardsTracker.sol";


contract RyoshisJoker is RewardsToken {
    using SafeMath for uint256;
    using Address for address;
    
    
    uint256 private constant REWARDS_TRACKER_IDENTIFIER = 99; 
    uint256 private constant TOTAL_SUPPLY = 1000000 * (10**9);

    uint256 public maxTxAmount = TOTAL_SUPPLY.mul(2).div(1000); 

    uint256 private platformFee = 100; 
    uint256 private _previousPlatformFee = platformFee;

    uint256 public devFee = 1400; 
    uint256 public sellDevFee = 1400; 
    uint256 private _previousDevFee = devFee;
    
    uint256 public rewardsFee = 0; 
    uint256 public sellRewardsFee = 0; 
    uint256 private _previousRewardsFee = rewardsFee;

    uint256 public launchSellFee = 0; 
    uint256 private _previousLaunchSellFee = launchSellFee;
    
    mapping(address => bool) public uniswapv2contracts;

    address payable private _platformWalletAddress =
        payable(0x3B4E4F7827857830243a4cef28DfB81A864b22Aa); 
    address payable private _devWalletAddress =
        payable(0x62bB06D9229f4F1f31669B472907ebae96CcbBA1); 

    uint256 public blacklistDeadline = 0;
    uint256 public launchSellFeeDeadline = 0;

    IRewardsTracker private _rewardsTracker;

   
    bool public useGenericTransfer = true;

   
    bool private preparedForLaunch = false;

    
    mapping(address => bool) public isBlacklisted;
    
    
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;
    
    
    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    bool currentlySwapping; 
    bool public swapAndRedirectEthFeesEnabled = true;

    uint256 private minTokensBeforeSwap = 5000 * 10**9;

    
     
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndRedirectEthFeesUpdated(bool enabled);
    event OnSwapAndRedirectEthFees(
        uint256 tokensSwapped,
        uint256 ethToDevWallet
    );
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    event GenericTransferChanged(bool useGenericTransfer);
    event ExcludeFromFees(address wallet);
    event IncludeInFees(address wallet);
    event DevWalletUpdated(address newDevWallet);
    event RewardsTrackerUpdated(address newRewardsTracker);
    event RouterUpdated(address newRouterAddress);
    event FeesChanged(
        uint256 newDevFee,
        uint256 newSellDevFee,
        uint256 newRewardsFee,
        uint256 newSellRewardsFee
    );
    event LaunchFeeUpdated(uint256 newLaunchSellFee);

    modifier lockTheSwap() {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }

    constructor() ERC20("Ryoshi's Joker", unicode"5150🔥") {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 
        );

        
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        
        uniswapV2Router = _uniswapV2Router;
        
       
        _mint(owner(), TOTAL_SUPPLY);

        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        
        
        excludeFromRewards(address(this));
        excludeFromRewards(owner());
        excludeFromRewards(address(0xdead));
        excludeFromRewards(uniswapV2Pair);

        
        uniswapv2contracts[uniswapV2Pair] = true;
    }

    
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        
        require(preparedForLaunch || _msgSender() == owner(), "Contract has not been prepared for launch and user is not owner");
        
        require(
            !isBlacklisted[from] && !isBlacklisted[to],
            "Blacklisted address"
        );

        if(useGenericTransfer){
            super._transfer(from, to, amount);
            return;
        }

        if (!uniswapv2contracts[from] && !uniswapv2contracts[to]) {
            super._transfer(from, to, amount);
            return;
        }

        if (
            !_isExcludedFromMaxTx[from] &&
            !_isExcludedFromMaxTx[to]
        ) {
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maxTxAmount"
            );
        }

        
        uint256 baseRewardsFee = rewardsFee;
        uint256 baseDevFee = devFee; 
        if (to == uniswapV2Pair) {
            devFee = sellDevFee;
            rewardsFee = sellRewardsFee;

            if (launchSellFeeDeadline >= block.timestamp) {
                devFee = devFee.add(launchSellFee);
            }
        }


        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap; 
        if (
            overMinTokenBalance &&
            !currentlySwapping &&
            from != uniswapV2Pair &&
            swapAndRedirectEthFeesEnabled
        ) {
            
            swapAndRedirectEthFees(contractTokenBalance);
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            removeAllFee();
        }


        
    (uint256 tTransferAmount, uint256 tFee) = _getValues(amount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(tTransferAmount);



        _takeFee(tFee);

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            restoreAllFee();
        }
        
        
        devFee = baseDevFee;
        rewardsFee = baseRewardsFee;
        emit Transfer(from, to, tTransferAmount);
    }

    
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _takeFee(uint256 fee) private {
        _balances[address(this)] = _balances[address(this)].add(fee);
    }

    function calculateFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        uint256 totalFee = devFee.add(rewardsFee).add(platformFee); 
        return _amount.mul(totalFee).div(10000);
    }

    function removeAllFee() private {
        if (devFee == 0 && rewardsFee == 0 && platformFee == 0) return;

        _previousPlatformFee = platformFee;
        _previousDevFee = devFee;
        _previousRewardsFee = rewardsFee;
        platformFee = 0;
        devFee = 0;
        rewardsFee = 0;
    }

    function restoreAllFee() private {
        platformFee = _previousPlatformFee;
        devFee = _previousDevFee;
        rewardsFee = _previousRewardsFee;
    }

    function swapAndRedirectEthFees(uint256 contractTokenBalance)
        private
        lockTheSwap
    {
        uint256 totalRedirectFee = devFee.add(rewardsFee).add(platformFee);
        if (totalRedirectFee == 0) return;
        
       
        uint256 initialBalance = address(this).balance; 

        
        swapTokensForEth(contractTokenBalance);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        if (newBalance > 0) {
            
            uint256 platformBalance = newBalance.mul(platformFee).div(totalRedirectFee);
            sendEthToWallet(_platformWalletAddress, platformBalance);

            
            uint256 rewardsBalance = newBalance.mul(rewardsFee).div(totalRedirectFee);
            if (rewardsBalance > 0 && address(_rewardsTracker) != address(0)) {
                try _rewardsTracker.addAllocation{value: rewardsBalance}(REWARDS_TRACKER_IDENTIFIER) {} catch {}
            }
            
            
            uint256 devBalance = newBalance.mul(devFee).div(totalRedirectFee);
            sendEthToWallet(_devWalletAddress, devBalance);

            emit OnSwapAndRedirectEthFees(contractTokenBalance, newBalance);
        }
    }

    function sendEthToWallet(address wallet, uint256 amount) private {
        if (amount > 0) {
            payable(wallet).transfer(amount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        
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

    function prepareForLaunch() external onlyOwner {
        require(!preparedForLaunch, "Already prepared for launch");

        
        preparedForLaunch = true;

        
        blacklistDeadline = block.timestamp + 24 hours;

        
        launchSellFeeDeadline = block.timestamp + 3 days;
    }

    function setUseGenericTransfer(bool genericTransfer) external onlyOwner {
        useGenericTransfer = genericTransfer;
        emit GenericTransferChanged(genericTransfer);
    }

    function blacklistAddress(address account, bool value) public onlyOwner {
        if (value) {
            require(block.timestamp < blacklistDeadline, "The ability to blacklist accounts has been disabled.");
        }
        isBlacklisted[account] = value;
    }

    
    
    function setMaxTxPercent(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx >= 5, "Max TX should be above 0.5%");
        maxTxAmount = TOTAL_SUPPLY.mul(newMaxTx).div(1000);
        emit MaxTxAmountUpdated(maxTxAmount);
    }
    
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

     function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFees(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFees(account);
    }
    function setFees(
        uint256 newPlatformFee,
        uint256 newDevFee,
        uint256 newSellDevFee,
        uint256 newRewardsFee,
        uint256 newSellRewardsFee
    ) external onlyOwner {
        require(
            newPlatformFee <= 2000 &&
            newDevFee <= 2000 &&
            newSellDevFee <= 2000 &&
            newRewardsFee <= 2000 &&
            newSellRewardsFee <= 2000,
            "Fees exceed maximum allowed value"
        );
        platformFee = newPlatformFee;
        devFee = newDevFee;
        sellDevFee = newSellDevFee;
        rewardsFee = newRewardsFee;
        sellRewardsFee = newSellRewardsFee;
        emit FeesChanged(newDevFee, newSellDevFee, newRewardsFee, newSellRewardsFee);
    }

    function setLaunchSellFee(uint256 newLaunchSellFee) external onlyOwner {
        require(newLaunchSellFee <= 2500, "Maximum launch sell fee is 25%");
        launchSellFee = newLaunchSellFee;
        emit LaunchFeeUpdated(newLaunchSellFee);
    }

    function setDevWallet(address payable newDevWallet)
        external
        onlyOwner
    {
        _devWalletAddress = newDevWallet;
        emit DevWalletUpdated(newDevWallet);
    }

    function setPlatformWallet(address payable newPlatformWallet)
        external
        onlyOwner
    {
        _platformWalletAddress = newPlatformWallet;
    }
    
    function setRewardsTracker(address payable newRewardsTracker)
        external
        onlyOwner
    {
        _rewardsTracker = IRewardsTracker(newRewardsTracker);
        emit RewardsTrackerUpdated(newRewardsTracker);
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        IUniswapV2Router _newUniswapRouter = IUniswapV2Router(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newUniswapRouter.factory())
            .createPair(address(this), _newUniswapRouter.WETH());
        uniswapV2Router = _newUniswapRouter;
    }

    function setSwapAndRedirectEthFeesEnabled(bool enabled) external onlyOwner {
        swapAndRedirectEthFeesEnabled = enabled;
        emit SwapAndRedirectEthFeesUpdated(enabled);
    }

    function setMinTokensBeforeSwap(uint256 minTokens) external onlyOwner {
        minTokensBeforeSwap = minTokens * 10**9;
        emit MinTokensBeforeSwapUpdated(minTokens);
    }
    
    
    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external onlyOwner {
        uint256 contractEthBalance = address(this).balance;
        sendEthToWallet(_devWalletAddress, contractEthBalance);
    } 

    
    function addPairAddress(address _newPair, bool value) public onlyOwner{
        uniswapv2contracts[_newPair] = value;
    }


}