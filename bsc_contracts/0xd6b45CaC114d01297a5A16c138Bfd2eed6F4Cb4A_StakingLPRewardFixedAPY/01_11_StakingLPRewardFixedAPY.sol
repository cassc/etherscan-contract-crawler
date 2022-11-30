// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface INimbusPair is IERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface INimbusRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IStakingRewards {
    function earned(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function stakeFor(uint256 amount, address user) external;
    function getReward() external;
    function getRewardForUser(address user) external;
    function withdraw(uint256 nonce) external;
    function withdrawAndGetReward(uint256 nonce) external;
}

interface IPriceFeed {
    function queryRate(address sourceTokenAddress, address destTokenAddress) external view returns (uint256 rate, uint256 precision);
    function wbnbToken() external view returns(address);
}

contract StakingLPRewardFixedAPY is IStakingRewards, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for INimbusPair;

    IERC20 public rewardsToken;
    IERC20 public rewardsPaymentToken;
    INimbusPair public immutable stakingLPToken;

    INimbusRouter public swapRouter;
    address public immutable lPPairTokenA;
    address public immutable lPPairTokenB;
    uint256 public rewardRate; 
    uint256 public rateChangesNonce;
    uint256 public constant rewardDuration = 365 days; 

    mapping(address => mapping(uint256 => StakeNonceInfo)) public stakeNonceInfos;
    mapping(address => uint256) public stakeNonces;
    mapping(uint256 => APYCheckpoint) APYcheckpoints;

    struct StakeNonceInfo {
        uint256 stakeTime;
        uint256 stakingLPTokenAmount;
        uint256 rewardsTokenAmount;
        uint256 rewardRate;
    }

    struct APYCheckpoint {
        uint256 timestamp;
        uint256 rewardRate;
    }

    uint256 private _totalSupply;
    uint256 private _totalSupplyRewardEquivalent;
    uint256 private immutable _tokenADecimalCompensate;
    uint256 private immutable _tokenBDecimalCompensate;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesRewardEquivalent;

    bool public usePriceFeeds;
    bool public tokenAUsePriceFeed;
    bool public tokenBUsePriceFeed;
    IPriceFeed public priceFeed;

    event RewardRateUpdated(uint256 indexed rateChangesNonce, uint256 rewardRate, uint256 timestamp);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed paymentToken, uint256 reward);
    event RescueIERC20(address indexed to, address indexed token, uint256 amount);
    event UpdateUsePriceFeeds(bool indexed usePriceFeeds);
    event RewardsPaymentTokenChanged(address indexed newRewardsPaymentToken);

    constructor(
        address _rewardsToken,
        address _rewardsPaymentToken,
        address _stakingLPToken,
        address _lPPairTokenA,
        address _lPPairTokenB,
        address _swapRouter,
        uint _rewardRate
    ) {
        require(_rewardsToken != address(0) && _stakingLPToken != address(0) && _lPPairTokenA != address(0) && _lPPairTokenB != address(0) && _swapRouter != address(0), "StakingLPRewardFixedAPY: Zero address(es)");
        rewardsToken = IERC20(_rewardsToken);
        rewardsPaymentToken = IERC20(_rewardsPaymentToken);
        stakingLPToken = INimbusPair(_stakingLPToken);
        swapRouter = INimbusRouter(_swapRouter);
        rewardRate = _rewardRate;
        lPPairTokenA = _lPPairTokenA;
        lPPairTokenB = _lPPairTokenB;
        uint tokenADecimals = IERC20Metadata(_lPPairTokenA).decimals();
        require(tokenADecimals >= 6, "StakingLPRewardFixedAPY: small amount of decimals");
        _tokenADecimalCompensate = tokenADecimals - 6;
        uint tokenBDecimals = IERC20Metadata(_lPPairTokenB).decimals();
        require(tokenBDecimals >= 6, "StakingLPRewardFixedAPY: small amount of decimals");
        _tokenBDecimalCompensate = tokenBDecimals - 6;
        emit RewardRateUpdated(rateChangesNonce, _rewardRate, block.timestamp);
        APYcheckpoints[rateChangesNonce++] = APYCheckpoint(block.timestamp, rewardRate);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function totalSupplyRewardEquivalent() external view returns (uint256) {
        return _totalSupplyRewardEquivalent;
    }

    function getDecimalPriceCalculationCompensate() external view returns (uint tokenADecimalCompensate, uint tokenBDecimalCompensate) { 
        tokenADecimalCompensate = _tokenADecimalCompensate;
        tokenBDecimalCompensate = _tokenBDecimalCompensate;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function balanceOfRewardEquivalent(address account) external view returns (uint256) {
        return _balancesRewardEquivalent[account];
    }

    function earnedByNonce(address account, uint256 nonce) public view returns (uint256) {
        uint256 amount = stakeNonceInfos[account][nonce].rewardsTokenAmount * 
            (block.timestamp - stakeNonceInfos[account][nonce].stakeTime) *
             stakeNonceInfos[account][nonce].rewardRate / (100 * rewardDuration);
        return getTokenAmountForToken(address(rewardsToken), address(rewardsPaymentToken), amount);
    }

    function getTokenAmountForToken(address tokenSrc, address tokenDest, uint tokenAmount) public view returns (uint) { 
        if (tokenSrc == tokenDest) return tokenAmount;
        if (usePriceFeeds && address(priceFeed) != address(0)) {
            (uint256 rate, uint256 precision) = priceFeed.queryRate(tokenSrc, tokenDest);
            return tokenAmount * rate / precision;
        } 
        address[] memory path = new address[](2);
        path[0] = tokenSrc;
        path[1] = tokenDest;
        return swapRouter.getAmountsOut(tokenAmount, path)[1];
    }

    function earned(address account) public view override returns (uint256 totalEarned) {
        for (uint256 i = 0; i < stakeNonces[account]; i++) {
            totalEarned += earnedByNonce(account, i);
        }
    }

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(amount > 0, "StakingLPRewardFixedAPY: Cannot stake 0");
        // permit
        IERC20Permit(address(stakingLPToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(amount, msg.sender);
    }

    function stake(uint256 amount) external override nonReentrant {
        require(amount > 0, "StakingLPRewardFixedAPY: Cannot stake 0");
        _stake(amount, msg.sender);
    }

    function stakeFor(uint256 amount, address user) external override nonReentrant {
        require(amount > 0, "StakingLPRewardFixedAPY: Cannot stake 0");
        require(user != address(0), "StakingLPRewardFixedAPY: Cannot stake for zero address");
        _stake(amount, user);
    }

    function _stake(uint256 amount, address user) private {
        IERC20(address(stakingLPToken)).safeTransferFrom(msg.sender, address(this), amount);
        uint amountRewardEquivalent = getCurrentLPPrice() * amount / 1e18;

        _totalSupply += amount;
        _totalSupplyRewardEquivalent += amountRewardEquivalent;
        _balances[user] += amount;

        uint stakeNonce = stakeNonces[user]++;
        stakeNonceInfos[user][stakeNonce].stakingLPTokenAmount = amount;
        stakeNonceInfos[user][stakeNonce].stakeTime = block.timestamp;
        stakeNonceInfos[user][stakeNonce].rewardRate = rewardRate;
        stakeNonceInfos[user][stakeNonce].rewardsTokenAmount = amountRewardEquivalent;
        _balancesRewardEquivalent[user] += amountRewardEquivalent;
        emit Staked(user, amount);
    }


    //A user can withdraw its staking tokens even if there is no rewards tokens on the contract account
    function withdraw(uint256 nonce) public override nonReentrant {
        require(stakeNonceInfos[msg.sender][nonce].stakingLPTokenAmount > 0, "StakingLPRewardFixedAPY: This stake nonce was withdrawn");
        uint amount = stakeNonceInfos[msg.sender][nonce].stakingLPTokenAmount;
        uint amountRewardEquivalent = stakeNonceInfos[msg.sender][nonce].rewardsTokenAmount;
        _totalSupply -= amount;
        _totalSupplyRewardEquivalent -= amountRewardEquivalent;
        _balances[msg.sender] -= amount;
        _balancesRewardEquivalent[msg.sender] -= amountRewardEquivalent;
        stakeNonceInfos[msg.sender][nonce].stakingLPTokenAmount = 0;
        stakeNonceInfos[msg.sender][nonce].rewardsTokenAmount = 0;
        stakingLPToken.safeTransfer(msg.sender, amount);
        
        emit Withdrawn(msg.sender, amount);
    }

      function getReward() public override nonReentrant whenNotPaused {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            for (uint256 i = 0; i < stakeNonces[msg.sender]; i++) {
                stakeNonceInfos[msg.sender][i].stakeTime = block.timestamp;
            }
            rewardsPaymentToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, address(rewardsPaymentToken), reward);
        }
    }

    function getRewardForUser(address user) public override nonReentrant whenNotPaused {
        require(msg.sender == owner(), "StakingLPRewardFixedAPY :: isn`t allowed to call rewards");
        uint256 reward = earned(user);
        if (reward > 0) {
            for (uint256 i = 0; i < stakeNonces[user]; i++) {
                stakeNonceInfos[user][i].stakeTime = block.timestamp;
            }
            rewardsPaymentToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(user, address(rewardsPaymentToken), reward);
        }
    }


    function withdrawAndGetReward(uint256 nonce) external override {
        getReward();
        withdraw(nonce);
    }

    function getCurrentLPPrice() public view returns (uint) {
        // LP PRICE = 2 * SQRT(reserveA * reaserveB ) * SQRT(token1/RewardTokenPrice * token2/RewardTokenPrice) / LPTotalSupply
        uint tokenAToRewardPrice;
        uint tokenBToRewardPrice;
        address rewardToken = address(rewardsToken);    
        address[] memory path = new address[](2);
        path[1] = address(rewardToken);

        if (lPPairTokenA != rewardToken) {
            path[0] = lPPairTokenA;
            if (tokenAUsePriceFeed) {
                (uint256 rate, uint256 precision) = priceFeed.queryRate(path[0], path[1]);
                tokenAToRewardPrice = 10 ** 6 * rate / precision;
            } else tokenAToRewardPrice = swapRouter.getAmountsOut(10 ** 6, path)[1];
            
            if (_tokenADecimalCompensate > 0) 
                tokenAToRewardPrice = tokenAToRewardPrice * (10 ** _tokenADecimalCompensate);
        } else {
            tokenAToRewardPrice = 1e18;
        }
        
        if (lPPairTokenB != rewardToken) {
            path[0] = lPPairTokenB;
            if (tokenBUsePriceFeed) {
                (uint256 rate, uint256 precision) = priceFeed.queryRate(path[0], path[1]);
                tokenBToRewardPrice = 10 ** 6 * rate / precision;
            } else tokenBToRewardPrice = swapRouter.getAmountsOut(10 ** 6, path)[1];
            if (_tokenBDecimalCompensate > 0)
                tokenBToRewardPrice = tokenBToRewardPrice * (10 ** _tokenBDecimalCompensate);
        } else {
            tokenBToRewardPrice = 1e18;
        }

        uint totalLpSupply = IERC20(stakingLPToken).totalSupply();
        require(totalLpSupply > 0, "StakingLPRewardFixedAPY: No liquidity for pair");
        (uint reserveA, uint reaserveB,) = stakingLPToken.getReserves();
        uint price = 
            uint(2) * Math.sqrt(reserveA * reaserveB)
            * Math.sqrt(tokenAToRewardPrice * tokenBToRewardPrice) / totalLpSupply;
        
        return price;
    }

    function exit() external {
        getReward();
        for (uint256 i = 0; i < stakeNonces[msg.sender]; i++) {
            if (stakeNonceInfos[msg.sender][i].stakingLPTokenAmount > 0) {
                withdraw(i);
            }
        }

        stakeNonces[msg.sender] = 0;
    }

    function updateRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
        emit RewardRateUpdated(rateChangesNonce, _rewardRate, block.timestamp);
        APYcheckpoints[rateChangesNonce++] = APYCheckpoint(block.timestamp, _rewardRate);
    }

    function updateSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "StakingLPRewardFixedAPY: Address is zero");
        swapRouter = INimbusRouter(newSwapRouter);
    }

    function updateRewardsPaymentToken(address newRewardsPaymentToken) external onlyOwner {
        require(Address.isContract(newRewardsPaymentToken), "StakingLPRewardFixedAPY: Address is zero");
        rewardsPaymentToken = IERC20(newRewardsPaymentToken);

        emit RewardsPaymentTokenChanged(newRewardsPaymentToken);
    }

    function updateTokenUsePriceFeeds(bool _tokenAUsePriceFeed, bool _tokenBUsePriceFeed) external onlyOwner {
        tokenAUsePriceFeed = _tokenAUsePriceFeed;
        tokenBUsePriceFeed = _tokenBUsePriceFeed;
    }

    function updateUsePriceFeeds(bool isUsePriceFeeds) external onlyOwner {
        usePriceFeeds = isUsePriceFeeds;
        emit UpdateUsePriceFeeds(isUsePriceFeeds);
    }

    function updatePriceFeed(address newPriceFeed) external onlyOwner {
        require(newPriceFeed != address(0), "StakingLPRewardFixedAPY: Address is zero");
        priceFeed = IPriceFeed(newPriceFeed);
    }

    function rescueIERC20(address to, address token, uint256 amount) external onlyOwner whenPaused {
        require(to != address(0), "StakingRewardFixedAPY: Cannot rescue to the zero address");
        require(amount > 0, "StakingRewardFixedAPY: Cannot rescue 0");
        
        IERC20(token).safeTransfer(to, amount);
        emit RescueIERC20(to, address(token), amount);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }
}