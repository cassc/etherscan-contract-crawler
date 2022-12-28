// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../owner/Operator.sol";

contract LPNode is ERC20, Operator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct User {
        uint256 totalDeposits;
        uint256 totalClaims;
        uint256 lastDistributePoints;
    }

    mapping(address => User) public users;

    IERC20 public immutable lpToken;
    uint256 public medalRate;
    uint256 public totalDeposited;
    uint256 public totalClaimed;
    uint256 public pendingRewards;
    uint256 public polRewards;
    uint256 public totalDistributeRewards;
    uint256 public totalDistributePoints;
    uint256 public lastDeliveryTime;
    uint256 public startTime;
    uint256 public lastResetDistributePoints;
    uint256 public lastResetTime;
    uint256 public rollingDuration = 24 hours;
    uint256 public rewardPercent = 150; // 1.50% Remain balance per rollingDuration
    uint256 public maxReturnPercent = 36500; // 365.00% Max Payout
    uint256 public polFeePercent = 400; // 4.00% to POL
    uint256 public claimFeePercent = 1000; // 10.00%
    uint256 public instantFeePercent = 600; // 6.00% to Instant Reward
    address public pol;
    bool public enabled = true;

    uint256 public constant MULTIPLIER = 1e18;
    uint256 public constant PERCENTAGE = 1e4; // x100 precision
    uint256 private userCounter;

    event PoolDeposited(
        address indexed account,
        uint256 timestamp,
        uint256 amount,
        uint256 medalAmount
    );

    event PoolClaimed(
        address indexed account,
        uint256 timestamp,
        uint256 amount,
        uint256 medalAmount
    );

    event SetStartTime(uint256 startTime);
    event SetPol(address _pol);
    event SetEnabled(bool _enabled);
    event SetPolFeePercent(uint256 _percent);
    event SetClaimFeePercent(uint256 _percent);
    event SetInstantFeePercent(uint256 _percent);
    event SetRewardPercent(uint256 _percent);
    event SetMaxReturnPercent(uint256 _percent);
    event SetRollingDuration(uint256 _duration);
    event ResetRewards(
        uint256 _now,
        uint256 lastResetDistributePoints,
        uint256 lastResetTime,
        uint256 pendingRewards
    );
    event ClaimPolRewards(uint256 polRewards);

    constructor(
        IERC20 _lpToken,
        address _pol,
        string memory _mpName,
        string memory _mpSymbol,
        uint256 _startTime,
        uint256 _medalRate
    ) ERC20(_mpName, _mpSymbol) {
        require(_startTime > block.timestamp, "LPNode: TIME_HAS_PASSED");
        lpToken = _lpToken;
        startTime = _startTime;
        medalRate = _medalRate;
        pol = _pol;
        lastDeliveryTime = _startTime;
    }

    receive() external payable {
        revert("LPNode: UNACCEPTED_AVAX");
    }

    function setStartTime(uint256 _startTime) external onlyOperator {
        require(startTime > block.timestamp, "LPNode: POOL_STARTED");
        require(_startTime > block.timestamp, "LPNode: TIME_HAS_PASSED");
        startTime = _startTime;
        lastDeliveryTime = _startTime;
        emit SetStartTime(startTime);
    }

    function setPol(address _pol) external onlyOperator {
        require(_pol != address(0), "LPNode: ADDRESS_ZERO");
        pol = _pol;
        emit SetPol(pol);
    }

    function setEnabled(bool _enabled) external onlyOperator {
        enabled = _enabled;
        emit SetEnabled(enabled);
    }

    function setPolFeePercent(uint256 _percent) external onlyOperator {
        require(_percent <= 400, "LPNode: OUT_OF_RANGE");
        polFeePercent = _percent;
        emit SetPolFeePercent(polFeePercent);
    }

    function setClaimFeePercent(uint256 _percent) external onlyOperator {
        require(
            _percent >= 1000 && _percent <= 2000,
            "LPNode: OUT_OF_RANGE"
        );
        claimFeePercent = _percent;
        emit SetClaimFeePercent(claimFeePercent);
    }

    function setInstantFeePercent(uint256 _percent) external onlyOperator {
        require(_percent <= 600, "LPNode: OUT_OF_RANGE");
        instantFeePercent = _percent;

        emit SetInstantFeePercent(instantFeePercent);
    }

    function setRewardPercent(uint256 _percent) external onlyOperator {
        require(_percent >= 150 && _percent <= 300, "LPNode: OUT_OF_RANGE");
        rewardPercent = _percent;
        emit SetRewardPercent(rewardPercent);
    }

    function setMaxReturnPercent(uint256 _percent) external onlyOperator {
        require(
            _percent >= 36500 && _percent <= 50000,
            "LPNode: OUT_OF_RANGE"
        );
        maxReturnPercent = _percent;
        emit SetMaxReturnPercent(maxReturnPercent);
    }

    function setRollingDuration(uint256 _duration) external onlyOperator {
        require(
            _duration >= 24 hours && _duration <= 48 hours,
            "LPNode: OUT_OF_RANGE"
        );
        rollingDuration = _duration;
        emit SetRollingDuration(maxReturnPercent);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function compound() external {
        address _sender = msg.sender;
        _compound(_sender);
    }

    function claimPolRewards() external {
        if (polRewards > 0) {
            lpToken.safeTransfer(pol, polRewards);
            polRewards = 0;
        }
        emit ClaimPolRewards(polRewards);
    }

    function resetRewards() external {
        uint256 _now = block.timestamp;
        require(
            _now >= lastResetTime.add(rollingDuration),
            "LPNode: TOO_EARLY"
        );
        lastDeliveryTime = _now;
        lastResetDistributePoints = totalDistributePoints;
        lastResetTime = _now;
        pendingRewards = 0;
        emit ResetRewards(
            lastDeliveryTime,
            lastResetDistributePoints,
            lastResetTime,
            pendingRewards
        );
    }

    function deposit(uint256 _amount) external {
        address _sender = msg.sender;
        require(_amount > 0, "LPNode: ZERO_AMOUNT");
        require(enabled && block.timestamp >= startTime, "LPNode: DISABLED");
        require(
            lpToken.balanceOf(_sender) >= _amount,
            "LPNode: INSUFFICIENT_BALANCE"
        );
        require(
            lpToken.allowance(_sender, address(this)) >= _amount,
            "LPNode: INSUFFICIENT_ALLOWANCE"
        );

        _claim(_sender);

        lpToken.safeTransferFrom(_sender, address(this), _amount);

        totalDeposited = totalDeposited.add(_amount);
        User storage user = users[_sender];

        // new user
        if (user.totalDeposits == 0) {
            userCounter++;
            user.lastDistributePoints = totalDistributePoints;
        }

        // the reward return reach to max
        if (user.totalDeposits != 0 && isMaxPayout(_sender)) {
            user.lastDistributePoints = totalDistributePoints;
        }

        // update deposit value
        user.totalDeposits = user.totalDeposits.add(_amount);

        uint256 instanceRewards = _amount.mul(instantFeePercent).div(
            PERCENTAGE
        );
        uint256 _polRewards = _amount.mul(polFeePercent).div(PERCENTAGE);

        polRewards = polRewards.add(_polRewards);
        uint256 medalAmount = _mintTokenByRate(_sender, _amount);
        _disperse(instanceRewards);

        emit PoolDeposited(_sender, block.timestamp, _amount, medalAmount);
    }

    function getPendingRewards(address _sender)
        external
        view
        returns (uint256)
    {
        if (users[_sender].totalDeposits == 0) return 0;

        uint256 rewards = _getPendingDistributionRewards(_sender).add(
            getDistributeReward().mul(allocPoints(_sender)).div(
                totalAllocPoints()
            )
        );
        uint256 totalClaims = users[_sender].totalClaims;
        uint256 _maxPayout = getMaxPayout(_sender);

        // Payout remaining if exceeds max payout
        if (totalClaims.add(rewards) > _maxPayout) {
            rewards = _maxPayout.sub(totalClaims);
        }

        // apply claim fee
        return rewards.sub(rewards.mul(claimFeePercent).div(PERCENTAGE));
    }

    function getEstimateMedalToken(uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256 medalAmount = _amount.mul(MULTIPLIER).div(medalRate);
        return medalAmount;
    }

    function getDayRewardEstimate(address _user)
        external
        view
        returns (uint dayRewardEstimate)
    {
        uint userAllocPoints = allocPoints(_user);
        if (userAllocPoints > 0 && !isMaxPayout(_user)) {
            uint256 rewardPerSecond = getBalancePool()
                .mul(rewardPercent)
                .div(PERCENTAGE)
                .div(rollingDuration);

            dayRewardEstimate = rewardPerSecond
                .mul(1 days)
                .mul(userAllocPoints)
                .div(totalAllocPoints());
        }
    }

    function getMaxPayout(address _sender) public view returns (uint256) {
        return
            users[_sender].totalDeposits.mul(maxReturnPercent).div(PERCENTAGE);
    }

    function isMaxPayout(address _sender) public view returns (bool) {
        return users[_sender].totalClaims >= getMaxPayout(_sender);
    }

    function getRewardPerSecond()
        public
        view
        returns (uint256 rewardPerSecond)
    {
        rewardPerSecond = getBalancePool()
            .mul(rewardPercent)
            .div(PERCENTAGE)
            .div(rollingDuration);
    }

    function getDistributeReward() public view returns (uint256) {
        if (lastDeliveryTime < block.timestamp) {
            uint256 poolBalance = getBalancePool();
            uint256 secondsPassed = block.timestamp.sub(lastDeliveryTime);
            uint256 rewards = secondsPassed.mul(getRewardPerSecond());
            return (rewards > poolBalance) ? poolBalance : rewards;
        }
        return 0;
    }

    function getBalance() public view returns (uint256) {
        return lpToken.balanceOf(address(this));
    }

    function getBalancePool() public view returns (uint256) {
        require(
            getBalance() >= pendingRewards.add(polRewards),
            "LPNode: Pool balance should greater than reward"
        );
        return getBalance().sub(pendingRewards).sub(polRewards);
    }

    function totalUsers() external view returns (uint256) {
        return userCounter;
    }

    function totalAllocPoints() public view returns (uint256) {
        return totalSupply().mul(MULTIPLIER).div(medalRate); // to lp
    }

    function allocPoints(address _account) public view returns (uint256) {
        return balanceOf(_account).mul(MULTIPLIER).div(medalRate); // to lp
    }

    function _deliveryRewards() internal {
        uint256 rewards = getDistributeReward();

        if (rewards > 0) {
            _disperse(rewards);
            lastDeliveryTime = block.timestamp;
        }
    }

    function _mintTokenByRate(address _sender, uint256 _amount)
        internal
        returns (uint256 medalAmount)
    {
        medalAmount = _amount.mul(MULTIPLIER).div(medalRate);
        _mint(_sender, medalAmount);
    }

    function _burnTokenByRate(address _sender, uint256 _amount)
        internal
        returns (uint256 medalAmount)
    {
        medalAmount = ((_amount.mul(MULTIPLIER).div(medalRate)).mul(PERCENTAGE))
            .div(maxReturnPercent);
        _burn(_sender, medalAmount);
    }

    function _disperse(uint256 _amount) internal {
        if (_amount > 0) {
            totalDistributePoints = totalDistributePoints.add(
                _amount.mul(MULTIPLIER).div(totalAllocPoints())
            );
            totalDistributeRewards = totalDistributeRewards.add(_amount);
            pendingRewards = pendingRewards.add(_amount);
        }
    }

    function _getPendingDistributionRewards(address _account)
        internal
        view
        returns (uint256)
    {
        if (isMaxPayout(_account)) return 0;

        uint256 newDividendPoints = totalDistributePoints.sub(
            users[_account].lastDistributePoints
        );
        uint256 distribute = allocPoints(_account).mul(newDividendPoints).div(
            MULTIPLIER
        );
        return distribute > pendingRewards ? pendingRewards : distribute;
    }

    function _claim(address _sender) internal {
        User memory user = users[_sender];

        // pass over reset time reset point
        if (user.lastDistributePoints < lastResetDistributePoints) {
            user.lastDistributePoints = lastResetDistributePoints;
        }
        _deliveryRewards();

        uint256 _rewards = _getPendingDistributionRewards(_sender);

        if (_rewards > 0) {
            pendingRewards = pendingRewards.sub(_rewards);
            uint256 _totalClaims = user.totalClaims;
            uint256 _maxPayout = getMaxPayout(_sender);

            // Payout remaining if exceeds max payout
            if (_totalClaims.add(_rewards) > _maxPayout) {
                _rewards = _maxPayout.sub(_totalClaims);
            }

            users[_sender].lastDistributePoints = totalDistributePoints;
            users[_sender].totalClaims = user.totalClaims.add(_rewards);
            totalClaimed = totalClaimed.add(_rewards);
            uint _rewardsAfterFee = _rewards.sub(
                _rewards.mul(claimFeePercent).div(PERCENTAGE)
            );
            uint medalAmount = _burnTokenByRate(_sender, _rewardsAfterFee);
            lpToken.safeTransfer(_sender, _rewardsAfterFee);

            emit PoolClaimed(
                _sender,
                block.timestamp,
                _rewardsAfterFee,
                medalAmount
            );
        }
    }

    function _compound(address _sender) internal {
        require(enabled && block.timestamp >= startTime, "LPNode: DISABLED");
        User storage user = users[_sender];
        // claim logic first
        // pass over reset time reset point
        if (user.lastDistributePoints < lastResetDistributePoints) {
            user.lastDistributePoints = lastResetDistributePoints;
        }

        _deliveryRewards();
        uint256 _rewards = _getPendingDistributionRewards(_sender);

        if (_rewards == 0) {
            return;
        }
        uint256 totalClaims = user.totalClaims;
        uint256 _maxPayout = getMaxPayout(_sender);

        // Payout remaining if exceeds max payout
        if (totalClaims.add(_rewards) > _maxPayout) {
            _rewards = _maxPayout.sub(totalClaims);
        }
        // update total
        pendingRewards = pendingRewards.sub(_rewards);

        // change claim
        user.totalClaims = user.totalClaims.add(_rewards);
        totalClaimed = totalClaimed.add(_rewards);

        user.lastDistributePoints = totalDistributePoints;
        // end claim
        // update deposit value
        user.totalDeposits = user.totalDeposits.add(_rewards);
        totalDeposited = totalDeposited.add(_rewards);

        uint256 medalAmount = _mintTokenByRate(_sender, _rewards);

        emit PoolDeposited(_sender, block.timestamp, _rewards, medalAmount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (from == address(0) || to == address(0)) return; // ignore mint and burn
        if (from == address(this) || to == address(this)) return; // ignore deposit, claim and compound

        _deliveryRewards();
        // from user
        uint256 lpAmount = amount.mul(medalRate).div(MULTIPLIER);

        User storage userTo = users[to];
        User storage userFrom = users[from];

        // sub deposit
        userFrom.totalDeposits = userFrom.totalDeposits.sub(lpAmount);

        // reset reward
        userFrom.lastDistributePoints = totalDistributePoints;

        if (userTo.totalDeposits == 0) {
            userCounter++;
            userTo.totalDeposits = lpAmount; // medal to lp
            userTo.lastDistributePoints = totalDistributePoints; // start reward
        } else {
            // if not compound all first
            _compound(to);
            // plus more value
            userTo.totalDeposits = userTo.totalDeposits.add(lpAmount);
            userTo.lastDistributePoints = totalDistributePoints; // reset reward
            // hard to return reward to user B, should claim before
        }

        if (userTo.totalDeposits != 0 && isMaxPayout(to)) {
            userTo.lastDistributePoints = totalDistributePoints;
        }
    }
}