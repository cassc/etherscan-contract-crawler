//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./priceCalculate.sol";

contract EverStaking is Ownable {
    using SafeMath for uint256;

    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 duration;
    }

    IERC20 public REWARD;
    IERC20 public STAKING;
    IERC20 public TOKEN;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;
    mapping(address => Stake) public stakeDetails;

    PriceCalculator public priceCalculator;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;

    uint256 public totalStaking;
    uint256 public rewardPerShare;

    uint256 public penaltyPercentage = 2;

    uint256 public minTokenPerShare = 1 * 10**18;

    uint256 public maxStakePercentage = 20;

    //APR is in percent * 100 (e.g. 2500 = 25% = 0.25)
    uint256 public currentApr = 3400;
    uint256 public poolStakePeriod = 60;

    uint256 public maxStakeTokensInThePool = 100000 * 10**18;

    uint256 public maxStakeTokensPerUser = 1000 * 10**18;

    uint256 public currentStakeInThePool;

    uint256 public bonusShareFactor = 200;
    uint256 public reserveRatio = 25;

    bool public useApy = false;
    IUniswapV2Router02 public router;

    uint256 public minStakeAmount = 1 * (10**18);

    uint256 secondsForDay = 86400;
    uint256 currentIndex;

    event NewStake(address staker, uint256 amount, uint256 time);
    event WithdrawAndExit(address staker, uint256 amount);
    event EmergencyWithdraw(address staker, uint256 amount);
    event CalcReward(
        uint256 amount,
        uint256 time,
        uint256 totalTime,
        uint256 apr,
        uint256 reward
    );

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    constructor() {
        REWARD = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        STAKING = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        TOKEN = IERC20(0xA87Ed75C257f1ec38393bEA0A83d55Ac2279D79c);

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        priceCalculator = new PriceCalculator();

        updatePool();
    }

    receive() external payable {}

    function purge(address receiver) external onlyOwner {
        uint256 balance = REWARD.balanceOf(address(this));
        REWARD.transfer(receiver, balance);
    }

    function getErc20Tokens(
        address bepToken,
        uint256 _amount,
        address receiver
    ) external onlyOwner {
        require(
            IERC20(bepToken).balanceOf(address(this)) >= _amount,
            "No enough tokens in the pool"
        );

        IERC20(bepToken).transfer(receiver, _amount);
    }

    function changePenaltyPercentage(uint256 _percentage) external onlyOwner {
        penaltyPercentage = _percentage;
    }

    function changePoolStakePeriod(uint256 _time) external onlyOwner {
        poolStakePeriod = _time;
    }

    function changeMaxStakePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Percentage can not be greater than 100%");
        maxStakePercentage = _percentage;
    }

    function changeMinimumStakeAmount(uint256 _amount) external onlyOwner {
        minStakeAmount = _amount;
    }

    function changeMinimumTokenPerShare(uint256 _amount) external onlyOwner {
        minTokenPerShare = _amount;
    }

    function changeBonusShareFactor(uint256 _value) external onlyOwner {
        bonusShareFactor = _value;
    }

    function changeRecerveRatio(uint256 _value) external onlyOwner {
        reserveRatio = _value;
    }

    function changeApr(uint256 _apr, bool _useApy) external onlyOwner {
        currentApr = _apr;
        useApy = _useApy;
    }

    function changeMaxTokenPerWallet(uint256 _amount) external onlyOwner {
        maxStakeTokensPerUser = _amount;
    }

    function changeMaxTokenPerPool(uint256 _amount) external onlyOwner {
        maxStakeTokensInThePool = _amount;
    }

    function setShare(
        address shareholder,
        uint256 amount,
        uint256 time
    ) internal {
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            totalShares = totalShares.sub(shares[shareholder].amount);
            shares[shareholder].amount = 0;
            removeShareholder(shareholder);
        }

        if (time == 0) {
            time = 1;
        }
        uint256 totalShareAmount = amount.mul(time);
        if (bonusShareFactor > 0) {
            totalShareAmount = totalShareAmount
                .mul(time.add(bonusShareFactor))
                .div(bonusShareFactor);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(
            totalShareAmount
        );
        shares[shareholder].amount = totalShareAmount;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return shareholders.length;
    }

    function getShareHoldersList() external view returns (address[] memory) {
        return shareholders;
    }

    function totalDistributedRewards() external view returns (uint256) {
        return totalDistributed;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    // staking

    function newStake(uint256 amount) public {
        // check user has ever earn tokens
        require(
            TOKEN.balanceOf(msg.sender) > 0,
            "You don't have any ever earn tokens"
        );
        uint256 userTokenValue = priceCalculator.getLatestPrice(
            address(TOKEN),
            TOKEN.balanceOf(msg.sender)
        );

        uint256 maxBusdAmountToStake = userTokenValue
            .mul(maxStakePercentage)
            .div(100);

        require(
            amount <= maxBusdAmountToStake,
            "You can not stake more than your token value"
        );
        require(
            amount <= maxStakeTokensPerUser,
            "You exceeded max token amount that one wallet can stake"
        );
        require(
            currentStakeInThePool.add(amount) <= maxStakeTokensInThePool,
            "Maximum pool token exceeded"
        );
        require(
            stakeDetails[msg.sender].amount == 0,
            "You Already have another running staking"
        );
        require(
            amount >= minStakeAmount,
            "You should stake more than minimum balance"
        );
        require(
            STAKING.balanceOf(msg.sender) >= amount,
            "You token balance is lower than requested staking amount"
        );

        STAKING.transferFrom(address(msg.sender), address(this), amount);
        totalStaking = totalStaking + amount;
        setShare(msg.sender, amount, poolStakePeriod);
        // stake time in seconds
        uint256 stakeTimeInSeconds = poolStakePeriod.mul(secondsForDay);
        // set stake details
        stakeDetails[msg.sender].amount = amount;
        stakeDetails[msg.sender].startTime = block.timestamp;
        stakeDetails[msg.sender].endTime = block.timestamp.add(
            stakeTimeInSeconds
        );
        stakeDetails[msg.sender].duration = poolStakePeriod;

        currentStakeInThePool = currentStakeInThePool.add(amount);

        emit NewStake(msg.sender, amount, poolStakePeriod);
        // update pool
        updatePool();
    }

    // remove
    function withdrawAndExit() public {
        require(
            stakeDetails[msg.sender].amount > 0,
            "You don't have any staking in this pool"
        );
        require(
            stakeDetails[msg.sender].endTime <= block.timestamp,
            "Lock time did not end. You cannot use normal withdraw"
        );
        updatePool();
        // get staked amount
        uint256 amountToSend = stakeDetails[msg.sender].amount;
        // calculate reward token
        uint256 rewardByShare = rewardPerShare.mul(shares[msg.sender].amount);
        uint256 totalTime = secondsForDay.mul(
            stakeDetails[msg.sender].duration
        );
        if (stakeDetails[msg.sender].duration == 0) {
            totalTime = block.timestamp.sub(stakeDetails[msg.sender].startTime);
        }
        uint256 rewardByApr = calculateReward(
            amountToSend,
            stakeDetails[msg.sender].duration,
            totalTime
        );
        uint256 rewardTokens = 0;
        if (rewardByApr < rewardByShare) {
            rewardTokens = rewardByApr;
        } else {
            rewardTokens = rewardByShare;
        }
        totalDistributed = totalDistributed.add(rewardTokens);
        // total amount to send user
        amountToSend = amountToSend.add(rewardTokens);

        require(
            REWARD.balanceOf(address(this)) >= amountToSend,
            "No enough tokens in the pool"
        );

        setShare(msg.sender, 0, 0);

        totalStaking = totalStaking.sub(stakeDetails[msg.sender].amount);

        currentStakeInThePool = currentStakeInThePool.sub(
            stakeDetails[msg.sender].amount
        );

        // reset stake details
        stakeDetails[msg.sender].amount = 0;
        stakeDetails[msg.sender].startTime = 0;
        stakeDetails[msg.sender].endTime = 0;
        // send tokens
        REWARD.transfer(msg.sender, amountToSend);

        emit WithdrawAndExit(msg.sender, amountToSend);
        updatePool();
    }

    function emergencyWithdraw() public {
        require(
            stakeDetails[msg.sender].amount > 0,
            "You don't have any staking in this pool"
        );
        require(
            stakeDetails[msg.sender].endTime > block.timestamp,
            "Lock time already finished. You cannot use emergency withdraw, use normal withdraw instead."
        );
        // get staked amount
        uint256 amountToSend = stakeDetails[msg.sender].amount;
        // calculate reward token
        uint256 totalTime = block.timestamp.sub(
            stakeDetails[msg.sender].startTime
        );
        uint256 lockTime = stakeDetails[msg.sender].duration.mul(secondsForDay);
        uint256 rewardByShare = rewardPerShare
            .mul(shares[msg.sender].amount)
            .mul(totalTime)
            .div(lockTime);
        uint256 rewardByApr = calculateReward(
            amountToSend,
            stakeDetails[msg.sender].duration,
            totalTime
        );
        uint256 rewardTokens = 0;
        if (rewardByApr < rewardByShare) {
            rewardTokens = rewardByApr;
        } else {
            rewardTokens = rewardByShare;
        }
        uint256 penaltyAmount = rewardTokens.mul(penaltyPercentage).div(100);

        amountToSend = amountToSend.add(rewardTokens).sub(penaltyAmount);

        require(
            REWARD.balanceOf(address(this)) >= amountToSend,
            "No enough tokens in the pool"
        );

        setShare(msg.sender, 0, 0);

        totalStaking = totalStaking.sub(stakeDetails[msg.sender].amount);
        currentStakeInThePool = currentStakeInThePool.sub(
            stakeDetails[msg.sender].amount
        );

        // reset stake details
        stakeDetails[msg.sender].amount = 0;
        stakeDetails[msg.sender].startTime = 0;
        stakeDetails[msg.sender].endTime = 0;

        // send tokens
        REWARD.transfer(msg.sender, amountToSend);

        emit EmergencyWithdraw(msg.sender, amountToSend);
        updatePool();
    }

    // update stake pool
    function updatePool() public {
        uint256 currentTokenBalance = REWARD.balanceOf(address(this));
        totalDividends = currentTokenBalance.sub(totalStaking);

        uint256 const = 100;
        if (totalShares > 0) {
            rewardPerShare = (totalDividends.div(totalShares)).mul(
                (const.sub(reserveRatio)).div(100)
            );
        }
        if (rewardPerShare < minTokenPerShare) {
            rewardPerShare = minTokenPerShare;
        }
    }

    function getUserInfo(address _wallet)
        public
        view
        returns (
            uint256 _amount,
            uint256 _startTime,
            uint256 _endTime
        )
    {
        _amount = stakeDetails[_wallet].amount;
        _startTime = stakeDetails[_wallet].startTime;
        _endTime = stakeDetails[_wallet].endTime;
    }

    function calculatRewardByAPY(
        uint256 amount,
        uint256 apr,
        uint256 timeDays
    ) public pure returns (uint256) {
        uint256 reward = amount;
        bool improveAccuracy = amount < 10**20;
        if (improveAccuracy) {
            //increase accuracy
            reward = reward.mul(10**20);
        }
        uint256 const3650000 = 3650000;
        for (uint256 i = 0; i < timeDays; i++) {
            //apr/(365*10000) gives the daily return. (3650000+apr)/3650000 = (1+apr/(365*10000))
            reward = reward.mul(const3650000.add(apr)).div(3650000);
        }
        if (improveAccuracy) {
            //increase accuracy
            reward = reward.div(10**20);
        }
        reward = reward.sub(amount);
        return reward;
    }

    ///return APY with precision of two digits after the point
    function calcApyMul100() public view returns (uint256) {
        uint256 amount = 1 * (10**18);
        uint256 rewardAmount = calculatRewardByAPY(amount, currentApr, 365);
        uint256 apyMul100 = rewardAmount.mul(10000).div(amount);
        return apyMul100;
    }

    function calculateReward(
        uint256 amount,
        uint256 time,
        uint256 totalTime
    ) internal returns (uint256) {
        uint256 rewardAmount = 0;

        if (!useApy) {
            rewardAmount = amount
                .mul(currentApr)
                .mul(totalTime)
                .div(secondsForDay.mul(365))
                .div(10000);
        } else {
            uint256 totalTimeDays = totalTime.div(secondsForDay); //rounded down, so partial day wouldn't count
            rewardAmount = calculatRewardByAPY(
                amount,
                currentApr,
                totalTimeDays
            );
        }
        emit CalcReward(amount, time, totalTime, currentApr, rewardAmount);
        return rewardAmount;
    }

    function buyTokenFromUsdc(uint256 _amount) external onlyOwner {
        require(
            REWARD.balanceOf(address(this)) >= _amount,
            "No enough Tokens in the pool"
        );

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(REWARD);
        path[1] = router.WETH();
        path[2] = address(TOKEN);

        REWARD.approve(address(router), _amount);

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );
    }

    function convertUsdcForEth(uint256 _amount) external onlyOwner {
        require(
            REWARD.balanceOf(address(this)) >= _amount,
            "No enough Tokens in the pool"
        );

        address[] memory path = new address[](2);
        path[0] = address(REWARD);
        path[1] = router.WETH();

        REWARD.approve(address(router), _amount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function sendTokens(uint256 _amount, address _address) external onlyOwner {
        require(
            TOKEN.balanceOf(address(this)) >= _amount,
            "No enough Tokens in the pool"
        );
        TOKEN.transfer(_address, _amount);
    }

    function sendUsdc(uint256 _amount, address _address) external onlyOwner {
        require(
            REWARD.balanceOf(address(this)) >= _amount,
            "No enough Tokens in the pool"
        );
        REWARD.transfer(_address, _amount);
    }

    function sendEth(uint256 _amount, address _address) external onlyOwner {
        require(
            address(this).balance >= _amount,
            "No enough Tokens in the pool"
        );
        payable(_address).transfer(_amount);
    }
}