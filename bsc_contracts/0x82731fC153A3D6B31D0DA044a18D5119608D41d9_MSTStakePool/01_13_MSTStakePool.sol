// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IMetaSportsToken} from "./interfaces/IMetaSportsToken.sol";

contract MSTStakePool is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IMetaSportsToken;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    struct StakingPeriod {
        uint256 rewardPerBlockForStaking;
        uint256 periodLengthInBlock;
    }

    struct UserInfo {
        uint256 totalLockedAmount;
        uint256 totalLockedWeight;
        EnumerableSet.UintSet orderIds; // OrderInfo.orderId
    }

    struct QueryUserInfo {
        uint256 totalLockedAmount;
        uint256 totalLockedWeight;
        uint256[] orderIds;
    }

    struct OrderInfo {
        uint256 orderId;
        address user;
        uint256 lockStartTime;
        uint256 lockEndTime;
        uint256 lockedAmount;
        uint256 lockedWeight;
        uint256 multiplier;
        uint256 earnedReward;
    }

    struct PoolConfig {
        uint256 pid;
        uint256 lockDuration;
        uint256 multiplier;
    }

    struct QueryOrderInfo {
        uint256 orderId;
        address user;
        uint256 lockStartTime;
        uint256 lockEndTime;
        uint256 lockedAmount;
        uint256 lockedWeight;
        uint256 multiplier;
        uint256 earnedReward;
        uint256 pendingRewards;
    }

    struct StakeInfo {
        uint256 numberPeriods;
        uint256 accWeightPerShare;
        uint256 currentPhase;
        uint256 endBlock;
        uint256 lastRewardBlock;
        uint256 rewardPerBlockForStaking;
        uint256 totalAmountStaked;
        uint256 totalWeightStaked;
        uint256 realWeightStaked;
        PoolConfig[] poolConfigs;
    }

    uint256 public constant PRECISION_FACTOR = 10**12;
    uint256 public constant INIT_WEIGHT = 200000000 ether;
    uint256 public constant MIN_DEPOSIT_AMOUNT = 1000 ether;
    uint256 public constant MULTIPLIER_FACTOR = 100; //realmultiplier=multiplier/MULTIPLIER_FACTOR 100/100 = 1
    uint256 public immutable START_BLOCK;
    uint256 public numberPeriods;
    uint256 public accWeightPerShare;
    uint256 public currentPhase;
    uint256 public endBlock;
    uint256 public lastRewardBlock;
    uint256 public rewardPerBlockForStaking;
    uint256 public totalAmountStaked;
    uint256 public totalWeightStaked;
    uint256 public realWeightStaked;
    IMetaSportsToken public immutable mstToken;
    Counters.Counter public orderId;

    mapping(uint256 => StakingPeriod) public stakingPeriod; //phase -> StakingPeriod
    mapping(uint256 => OrderInfo) public orderInfos; // orderId-> OrderInfo
    mapping(address => UserInfo) private userInfos; // user->UserInfo
    mapping(uint => uint) private rewardIndexOf;

    EnumerableSet.UintSet totalOrderIds;
    PoolConfig[] public poolConfigs;

    event Deposit(
        address indexed user,
        uint256 indexed orderId,
        uint256 amount,
        uint256 weight,
        uint256 lockDuration
    );

    event Withdraw(
        address indexed user,
        uint256 indexed orderId,
        uint256 amount,
        uint256 weight,
        uint256 reward
    );

    event NewRewardsPerBlock(
        uint256 indexed currentPhase,
        uint256 startBlock,
        uint256 rewardPerBlockForStaking
    );

    constructor(
        address _token,
        uint256 _startBlock,
        uint256[] memory _rewardsPerBlockForStaking,
        uint256[] memory _periodLengthesInBlocks,
        uint256 _numberPeriods
    ) {
        require(
            (_periodLengthesInBlocks.length == _numberPeriods) &&
                (_rewardsPerBlockForStaking.length == _numberPeriods) &&
                (_rewardsPerBlockForStaking.length == _numberPeriods),
            "MSTStakePool: Lengthes must match numberPeriods"
        );
        uint256 nonCirculatingSupply = IMetaSportsToken(_token).supplyCap() -
            IMetaSportsToken(_token).totalSupply();
        uint256 amountTokensToBeMinted;
        for (uint256 i = 0; i < _numberPeriods; i++) {
            amountTokensToBeMinted += (_rewardsPerBlockForStaking[i] *
                _periodLengthesInBlocks[i]);

            stakingPeriod[i] = StakingPeriod({
                rewardPerBlockForStaking: _rewardsPerBlockForStaking[i],
                periodLengthInBlock: _periodLengthesInBlocks[i]
            });
        }
        require(
            amountTokensToBeMinted <= nonCirculatingSupply,
            "MSTStakePool: Wrong reward parameters"
        );

        rewardPerBlockForStaking = _rewardsPerBlockForStaking[0];
        mstToken = IMetaSportsToken(_token);
        START_BLOCK = _startBlock;
        endBlock = _startBlock + _periodLengthesInBlocks[0];
        numberPeriods = _numberPeriods;
        lastRewardBlock = _startBlock;
        totalWeightStaked = INIT_WEIGHT;

        poolConfigs.push(PoolConfig(1, 90 days, 100));
        poolConfigs.push(PoolConfig(2, 180 days, 150));
        poolConfigs.push(PoolConfig(3, 365 days, 210));
    }

    function addPoolConfig(
        uint256 _pid,
        uint256 _lockDuration,
        uint256 _multiplier
    ) public onlyOwner {
        require(
            _pid > 0 && _lockDuration > 0 && _multiplier > 0,
            "AddPoolConfig: Parameters is invalid"
        );
        for (uint i = 0; i < poolConfigs.length; i++) {
            require(
                _pid != poolConfigs[i].pid,
                "AddPoolConfig: Pid already exists"
            );
            require(
                _lockDuration != poolConfigs[i].lockDuration,
                "AddPoolConfig: LockDuration already exists"
            );
        }
        poolConfigs.push(PoolConfig(_pid, _lockDuration, _multiplier));
    }

    function removePoolConfig(uint256 _pid) public onlyOwner {
        require(_pid > 0, "RemovePoolConfig: Parameters is invalid");
        uint j = 0;
        bool flag;
        for (uint i = 0; i < poolConfigs.length; i++) {
            if (_pid == poolConfigs[i].pid) {
                j = i;
                flag = true;
                break;
            }
        }
        if (flag) {
            delete poolConfigs[j];
        }
    }

    function addStakingPeriod(
        uint256[] memory _rewardsPerBlockForStaking,
        uint256[] memory _periodLengthesInBlocks,
        uint256 _numberPeriods
    ) public onlyOwner {
        require(
            (_periodLengthesInBlocks.length == _numberPeriods) &&
                (_rewardsPerBlockForStaking.length == _numberPeriods) &&
                (_rewardsPerBlockForStaking.length == _numberPeriods),
            "AddStakingPeriod: Lengthes must match numberPeriods"
        );
        uint256 nonCirculatingSupply = mstToken.supplyCap() -
            mstToken.totalSupply();
        uint256 amountTokensToBeMinted;
        for (uint256 i = 0; i < numberPeriods; i++) {
            amountTokensToBeMinted += (stakingPeriod[i]
                .rewardPerBlockForStaking *
                stakingPeriod[i].periodLengthInBlock);
        }
        for (uint256 i = 0; i < _numberPeriods; i++) {
            amountTokensToBeMinted += (_rewardsPerBlockForStaking[i] *
                _periodLengthesInBlocks[i]);
        }
        require(
            amountTokensToBeMinted <= nonCirculatingSupply,
            "AddStakingPeriod: Wrong reward parameters"
        );
        for (uint256 i = 0; i < _numberPeriods; i++) {
            stakingPeriod[numberPeriods + i] = StakingPeriod({
                rewardPerBlockForStaking: _rewardsPerBlockForStaking[i],
                periodLengthInBlock: _periodLengthesInBlocks[i]
            });
        }
        numberPeriods += _numberPeriods;
    }

    function _getPoolMultiplier(uint256 _duration)
        internal
        view
        returns (uint256)
    {
        require(
            _duration > 0 && _duration <= 365 days,
            "_getPoolMultiplier: Lock duration is invalid"
        );
        for (uint256 i = 0; i < poolConfigs.length; i++) {
            if (_duration == poolConfigs[i].lockDuration) {
                return poolConfigs[i].multiplier;
            }
        }
        return 0;
    }

    function _calculateRewards(uint256 _orderId) private view returns (uint) {
        uint shares = orderInfos[_orderId].lockedWeight;
        return
            (shares * (accWeightPerShare - rewardIndexOf[_orderId])) /
            PRECISION_FACTOR;
    }

    function _calculateRewardsEarned(uint256 _orderId)
        internal
        view
        returns (uint)
    {
        return orderInfos[_orderId].earnedReward + _calculateRewards(_orderId);
    }

    function _updateRewards(uint256 _orderId) private {
        rewardIndexOf[_orderId] = accWeightPerShare;
        orderInfos[_orderId].earnedReward += _calculateRewards(_orderId);
    }

    function deposit(uint256 _amount, uint256 _lockDuration)
        external
        whenNotPaused
    {
        require(
            _amount >= MIN_DEPOSIT_AMOUNT,
            "Deposit: Amount must more than MIN_DEPOSIT_AMOUNT"
        );

        uint256 poolMultiplier = _getPoolMultiplier(_lockDuration);
        require(poolMultiplier > 0, "Deposit: Lock duration is invalid");

        _updatePool();

        mstToken.safeTransferFrom(msg.sender, address(this), _amount);

        //OrderInfo
        orderId.increment();
        uint256 id = orderId.current();
        uint256 lockStartTime = block.timestamp;
        uint256 lockEndTime = block.timestamp + _lockDuration;
        uint256 lockedWeight = (_amount * poolMultiplier) / MULTIPLIER_FACTOR;
        orderInfos[id] = OrderInfo(
            id,
            msg.sender,
            lockStartTime,
            lockEndTime,
            _amount,
            lockedWeight,
            poolMultiplier,
            0
        );

        _updateRewards(id);

        // UserInfo
        UserInfo storage userInfo = userInfos[msg.sender];
        userInfo.totalLockedAmount += _amount;
        userInfo.totalLockedWeight += lockedWeight;
        userInfo.orderIds.add(id);

        // Global param
        totalAmountStaked += _amount;
        realWeightStaked += lockedWeight;
        if (realWeightStaked >= INIT_WEIGHT) {
            totalWeightStaked += (realWeightStaked - INIT_WEIGHT);
        }
        totalOrderIds.add(id);

        // event
        emit Deposit(msg.sender, id, _amount, lockedWeight, _lockDuration);
    }

    function withdraw(uint256 _orderId) external whenNotPaused {
        require(orderInfos[_orderId].lockedAmount > 0, "Withdraw: No Staking");
        require(
            orderInfos[_orderId].user == msg.sender,
            "Withdraw: Not the owner"
        );
        require(
            block.timestamp > orderInfos[_orderId].lockEndTime,
            "Withdraw: The order have locked"
        );

        _updatePool();

        OrderInfo storage orderInfo = orderInfos[_orderId];

        // OrderInfo
        uint256 pendingRewards = _calculateRewardsEarned(_orderId);
        orderInfo.earnedReward = 0;
        uint256 amountToTransfer = orderInfo.lockedAmount + pendingRewards;
        uint256 weight = orderInfo.lockedWeight;

        // Transfer MST tokens to the sender
        mstToken.safeTransfer(msg.sender, amountToTransfer);

        // UserInfo
        UserInfo storage userInfo = userInfos[orderInfo.user];
        userInfo.totalLockedAmount -= orderInfo.lockedAmount;
        userInfo.totalLockedWeight -= orderInfo.lockedWeight;
        userInfo.orderIds.remove(_orderId);

        // Global param
        totalAmountStaked -= orderInfo.lockedAmount;
        realWeightStaked -= orderInfo.lockedWeight;
        if (realWeightStaked < INIT_WEIGHT) {
            totalWeightStaked = INIT_WEIGHT;
        } else {
            totalWeightStaked -= orderInfo.lockedWeight;
        }
        totalOrderIds.remove(_orderId);

        delete orderInfos[_orderId];

        emit Withdraw(
            msg.sender,
            _orderId,
            amountToTransfer,
            weight,
            pendingRewards
        );
    }

    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalAmountStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        // Calculate multiplier
        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

        // Calculate rewards for staking and others
        uint256 tokenRewardForStaking = multiplier * rewardPerBlockForStaking;

        // Check whether to adjust multipliers and reward per block
        while (
            (block.number > endBlock) && (currentPhase < (numberPeriods - 1))
        ) {
            // Update rewards per block
            _updateRewardsPerBlock(endBlock);

            uint256 previousEndBlock = endBlock;

            // Adjust the end block
            endBlock += stakingPeriod[currentPhase].periodLengthInBlock;

            // Adjust multiplier to cover the missing periods with other lower inflation schedule
            uint256 newMultiplier = _getMultiplier(
                previousEndBlock,
                block.number
            );

            // Adjust token rewards
            tokenRewardForStaking += (newMultiplier * rewardPerBlockForStaking);
        }

        // Mint tokens only if token rewards for staking are not null
        if (tokenRewardForStaking > 0) {
            // It allows protection against potential issues to prevent funds from being locked
            bool mintStatus = mstToken.mint(
                address(this),
                tokenRewardForStaking
            );
            if (mintStatus) {
                accWeightPerShare =
                    accWeightPerShare +
                    ((tokenRewardForStaking * PRECISION_FACTOR) /
                        totalWeightStaked);
            }
        }

        // Update last reward block only if it wasn't updated after or at the end block
        if (lastRewardBlock <= endBlock) {
            lastRewardBlock = block.number;
        }
    }

    function _updateRewardsPerBlock(uint256 _newStartBlock) internal {
        // Update current phase
        currentPhase++;

        // Update rewards per block
        rewardPerBlockForStaking = stakingPeriod[currentPhase]
            .rewardPerBlockForStaking;

        emit NewRewardsPerBlock(
            currentPhase,
            _newStartBlock,
            rewardPerBlockForStaking
        );
    }

    function _calculatePendingRewards(uint256 _orderId)
        internal
        view
        returns (uint256)
    {
        if ((block.number > lastRewardBlock) && (totalWeightStaked != 0)) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

            uint256 tokenRewardForStaking = multiplier *
                rewardPerBlockForStaking;

            uint256 adjustedEndBlock = endBlock;
            uint256 adjustedCurrentPhase = currentPhase;

            // Check whether to adjust multipliers and reward per block
            while (
                (block.number > adjustedEndBlock) &&
                (adjustedCurrentPhase < (numberPeriods - 1))
            ) {
                // Update current phase
                adjustedCurrentPhase++;

                // Update rewards per block
                uint256 adjustedRewardPerBlockForStaking = stakingPeriod[
                    adjustedCurrentPhase
                ].rewardPerBlockForStaking;

                // Calculate adjusted block number
                uint256 previousEndBlock = adjustedEndBlock;

                // Update end block
                adjustedEndBlock =
                    previousEndBlock +
                    stakingPeriod[adjustedCurrentPhase].periodLengthInBlock;

                // Calculate new multiplier
                uint256 newMultiplier = (block.number <= adjustedEndBlock)
                    ? (block.number - previousEndBlock)
                    : stakingPeriod[adjustedCurrentPhase].periodLengthInBlock;

                // Adjust token rewards for staking
                tokenRewardForStaking += (newMultiplier *
                    adjustedRewardPerBlockForStaking);
            }

            uint256 adjustedWeightPerShare = accWeightPerShare +
                (tokenRewardForStaking * PRECISION_FACTOR) /
                totalWeightStaked;

            return
                orderInfos[_orderId].earnedReward +
                (orderInfos[_orderId].lockedWeight *
                    (adjustedWeightPerShare - rewardIndexOf[_orderId])) /
                PRECISION_FACTOR;
        } else {
            return
                orderInfos[_orderId].earnedReward +
                (orderInfos[_orderId].lockedWeight *
                    (accWeightPerShare - rewardIndexOf[_orderId])) /
                PRECISION_FACTOR;
        }
    }

    function calculatePendingRewards(uint256 _orderId)
        public
        view
        returns (uint256)
    {
        require(
            totalOrderIds.contains(_orderId),
            "CalculatePendingRewards:OrderId is invalid"
        );
        if ((block.number > lastRewardBlock) && (totalWeightStaked != 0)) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

            uint256 tokenRewardForStaking = multiplier *
                rewardPerBlockForStaking;

            uint256 adjustedEndBlock = endBlock;
            uint256 adjustedCurrentPhase = currentPhase;

            // Check whether to adjust multipliers and reward per block
            while (
                (block.number > adjustedEndBlock) &&
                (adjustedCurrentPhase < (numberPeriods - 1))
            ) {
                // Update current phase
                adjustedCurrentPhase++;

                // Update rewards per block
                uint256 adjustedRewardPerBlockForStaking = stakingPeriod[
                    adjustedCurrentPhase
                ].rewardPerBlockForStaking;

                // Calculate adjusted block number
                uint256 previousEndBlock = adjustedEndBlock;

                // Update end block
                adjustedEndBlock =
                    previousEndBlock +
                    stakingPeriod[adjustedCurrentPhase].periodLengthInBlock;

                // Calculate new multiplier
                uint256 newMultiplier = (block.number <= adjustedEndBlock)
                    ? (block.number - previousEndBlock)
                    : stakingPeriod[adjustedCurrentPhase].periodLengthInBlock;

                // Adjust token rewards for staking
                tokenRewardForStaking += (newMultiplier *
                    adjustedRewardPerBlockForStaking);
            }

            uint256 adjustedWeightPerShare = accWeightPerShare +
                (tokenRewardForStaking * PRECISION_FACTOR) /
                totalWeightStaked;

            return
                orderInfos[_orderId].earnedReward +
                (orderInfos[_orderId].lockedWeight *
                    (adjustedWeightPerShare - rewardIndexOf[_orderId])) /
                PRECISION_FACTOR;
        } else {
            return
                orderInfos[_orderId].earnedReward +
                (orderInfos[_orderId].lockedWeight *
                    (accWeightPerShare - rewardIndexOf[_orderId])) /
                PRECISION_FACTOR;
        }
    }

    function _getMultiplier(uint256 from, uint256 to)
        internal
        view
        returns (uint256)
    {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }

    function getUserOrderInfo(address _user)
        public
        view
        returns (QueryOrderInfo[] memory orders)
    {
        uint256[] memory _orderIds = userInfos[_user].orderIds.values();
        uint256 len = _orderIds.length;
        orders = new QueryOrderInfo[](len);
        for (uint256 i = 0; i < len; i++) {
            orders[i] = QueryOrderInfo(
                _orderIds[i],
                _user,
                orderInfos[_orderIds[i]].lockStartTime,
                orderInfos[_orderIds[i]].lockEndTime,
                orderInfos[_orderIds[i]].lockedAmount,
                orderInfos[_orderIds[i]].lockedWeight,
                orderInfos[_orderIds[i]].multiplier,
                orderInfos[_orderIds[i]].earnedReward,
                _calculatePendingRewards(_orderIds[i])
            );
        }
        return orders;
    }

    function getUserOrderInfoWithoutPendingReward(address _user)
        public
        view
        returns (OrderInfo[] memory orders)
    {
        uint256[] memory _orderIds = userInfos[_user].orderIds.values();
        uint256 len = _orderIds.length;
        orders = new OrderInfo[](len);
        for (uint256 i = 0; i < len; i++) {
            orders[i] = orderInfos[_orderIds[i]];
        }
        return orders;
    }

    function getTotalOrderIds()
        public
        view
        returns (uint256[] memory orderIds)
    {
        return totalOrderIds.values();
    }

    function getUserOrderIds(address _user)
        public
        view
        returns (uint256[] memory orderIds)
    {
        return userInfos[_user].orderIds.values();
    }

    function getUserInfo(address _user)
        public
        view
        returns (QueryUserInfo memory userInfo)
    {
        return
            QueryUserInfo(
                userInfos[_user].totalLockedAmount,
                userInfos[_user].totalLockedWeight,
                userInfos[_user].orderIds.values()
            );
    }

    function getOrderInfoBatch(uint256[] calldata _orderIds)
        public
        view
        returns (OrderInfo[] memory orders)
    {
        require(
            _orderIds.length > 0 && _orderIds.length <= 1000,
            "getOrderInfoBatch: OrderId list length exceed limit"
        );
        uint256 len = _orderIds.length;
        orders = new OrderInfo[](len);
        for (uint256 i = 0; i < len; i++) {
            orders[i] = orderInfos[_orderIds[i]];
        }
        return orders;
    }

    function getStakeInfo() public view returns (StakeInfo memory stakeInfo) {
        return
            StakeInfo(
                numberPeriods,
                accWeightPerShare,
                currentPhase,
                endBlock,
                lastRewardBlock,
                rewardPerBlockForStaking,
                totalAmountStaked,
                totalWeightStaked,
                realWeightStaked,
                poolConfigs
            );
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function withdrawBalance() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            Address.sendValue(payable(owner()), balance);
        }
    }

    function withdrawERC20(address _tokenContract)
        external
        onlyOwner
        nonReentrant
    {
        uint256 balance = IERC20(_tokenContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_tokenContract).safeTransfer(owner(), balance);
        }
    }
}