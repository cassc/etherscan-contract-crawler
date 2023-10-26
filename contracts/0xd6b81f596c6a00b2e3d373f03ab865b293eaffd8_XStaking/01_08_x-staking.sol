// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.18;

    import "@openzeppelin/[email protected]/access/Ownable.sol";
    import "@openzeppelin/[email protected]/security/ReentrancyGuard.sol";
    import "@openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol";

    contract XStaking is Ownable, ReentrancyGuard {
        using SafeERC20 for IERC20;

        struct Stakeholder {
            address addr;
            Stake[] stakes;
        }

        struct RewardPlan {
            uint256 index;
            string name;
            uint256 duration;
            uint256 rewardsTotal;
            uint256 rewardsAvailable;
            uint256 maxCap;
            uint256 maxPerWallet;
            uint256 totalStaked;
            uint256 currentStaked;
            uint256 createdAt;
            uint256 deletedAt;
        }

        struct Stake {
            uint256 index;
            uint256 amount;
            uint256 rewardPlanIndex;
            uint256 createdAt;
        }

        address private _owner;
        IERC20 public token;

        mapping(address => Stakeholder) public stakeholders;

        uint256 public totalStaked;

        RewardPlan[] public rewardPlans;

        constructor(address _token) {
            _owner = msg.sender;
            token = IERC20(_token);
        }

        modifier onlyStakeholder() {
            require(isStakeholder(msg.sender), "Staking: caller is not the stakeholder");
            _;
        }

        modifier validRewardPlanIndex(uint256 _index) {
            require(_index < rewardPlans.length, "Staking: reward plan does not exist");
            _;
        }

        modifier validStakeIndex(address _stakeholder, uint256 _index) {
            Stake[] memory _stakes = stakeholders[_stakeholder].stakes;
            require(_index < _stakes.length, "Staking: stake does not exist");
            _;
        }

        function getRewardPlans()
            external
            view
            returns (RewardPlan[] memory)
        {
            return rewardPlans;
        }

        function stakesOf(address _stakeholder)
            external
            view
            returns (Stake[] memory)
        {
            return stakeholders[_stakeholder].stakes;
        }

        function balance()
            public
            view
            returns (uint256)
        {
            return token.balanceOf(address(this));
        }

        function isStakeholder(address _stakeholder)
            public
            view
            returns (bool)
        {
            return stakeholders[_stakeholder].addr != address(0);
        }

        function stake(uint256 _amount, uint256 _rewardPlanIndex)
            public
            nonReentrant
            validRewardPlanIndex(_rewardPlanIndex)
        {
            require(_amount > 0, "Staking: amount cannot be zero");
            RewardPlan memory _rewardPlan = rewardPlans[_rewardPlanIndex];
            require(_rewardPlan.deletedAt == 0, "Staking: reward plan does not exist");
            if (!isStakeholder(msg.sender)) {
                addStakeholder(msg.sender);
            }
            require(_rewardPlan.totalStaked + _amount <= _rewardPlan.maxCap, "Staking: pool overflow.");
            require(_rewardPlan.maxPerWallet >= _amount, "Staking: limit per wallet reached.");
            require(stakeholders[msg.sender].stakes.length < 1, "Staking: you've got active stake already");
            Stake memory _stake = Stake({
                index: stakeholders[msg.sender].stakes.length,
                amount: _amount,
                rewardPlanIndex: _rewardPlanIndex,
                createdAt: block.timestamp
            });
            stakeholders[msg.sender].stakes.push(_stake);
            totalStaked += _amount;
            rewardPlans[_rewardPlanIndex].currentStaked += _amount;
            rewardPlans[_rewardPlanIndex].totalStaked += _amount;
            token.safeTransferFrom(msg.sender, address(this), _amount);
            emit StakeCreated(msg.sender, _stake, _rewardPlan);
        }

        function unstake(uint256 _stakeIndex)
            public
            nonReentrant
            onlyStakeholder
            validStakeIndex(msg.sender, _stakeIndex)
        {
            Stake memory _stake = stakeholders[msg.sender].stakes[_stakeIndex];
            uint256 _amount = _stake.amount;
            require(_amount > 0, "Staking: stake does not exist");
            RewardPlan memory _rewardPlan = rewardPlans[_stake.rewardPlanIndex];
            require(_amount == _stake.amount, "Staking: not enough staked tokens");
            require(_amount <= _rewardPlan.currentStaked, "Staking: not enough staked tokens");
            uint256 _reward = calculateReward(_stake);
            totalStaked -= _amount;
            rewardPlans[_stake.rewardPlanIndex].currentStaked -= _amount;
            stakeholders[msg.sender].stakes[_stakeIndex] = stakeholders[msg.sender].stakes[stakeholders[msg.sender].stakes.length - 1];
            stakeholders[msg.sender].stakes.pop();
            if(block.timestamp - _stake.createdAt > _rewardPlan.duration) {
                require(_rewardPlan.rewardsAvailable >= _reward, "Staking: not enough rewards in pool");
                rewardPlans[_stake.rewardPlanIndex].rewardsAvailable -= _reward;
                token.safeTransfer(msg.sender, _amount + _reward);    
            } else {
                rewardPlans[_stake.rewardPlanIndex].totalStaked -= _amount;
                token.safeTransfer(msg.sender, _amount);    
            }
            emit StakeRemoved(msg.sender, _stake, _rewardPlan);
        }

        function addReward(uint256 _amount, uint256 _rewardPlanIndex)
            public
            onlyOwner
        {
            rewardPlans[_rewardPlanIndex].rewardsTotal += _amount;
            rewardPlans[_rewardPlanIndex].rewardsAvailable += _amount;
            token.safeTransferFrom(msg.sender, address(this), _amount);
            emit RewardAdded(_amount, _rewardPlanIndex);
        }

        function removeReward(uint256 _amount, uint256 _rewardPlanIndex)
            public
            onlyOwner
        {
            require(rewardPlans[_rewardPlanIndex].rewardsTotal >= _amount, "Rewards: not enough in reward pool");
            require(rewardPlans[_rewardPlanIndex].rewardsAvailable >= _amount, "Rewards: not enough in reward pool");
            rewardPlans[_rewardPlanIndex].rewardsTotal -= _amount;
            rewardPlans[_rewardPlanIndex].rewardsAvailable -= _amount;
            token.safeTransferFrom(address(this), msg.sender, _amount);
            emit RewardRemoved(_amount, _rewardPlanIndex);
        }

        function createRewardPlan(string memory _name, uint256 _duration, uint256 _maxCap, uint256 _maxPerWallet)
            public
            onlyOwner
        {
            require(_duration > 0, "Plan: duration cannot be zero");
            RewardPlan memory _rewardPlan = RewardPlan({
                index: rewardPlans.length,
                name: _name,
                duration: _duration * (1 days),
                rewardsTotal: 0,
                rewardsAvailable: 0,
                totalStaked: 0,
                currentStaked: 0,
                maxCap: _maxCap,
                maxPerWallet: _maxPerWallet,
                createdAt: block.timestamp,
                deletedAt: 0
            });
            rewardPlans.push(_rewardPlan);
            emit RewardPlanCreated(_rewardPlan);
        }

        function updateRewardPlan(uint256 _index, string memory _name, uint256 _maxCap, uint256 _maxPerWallet)
            public
            onlyOwner
            validRewardPlanIndex(_index)
        {
            rewardPlans[_index].name = _name;
            rewardPlans[_index].maxCap = _maxCap;
            rewardPlans[_index].maxPerWallet = _maxPerWallet;
            emit RewardPlanUpdated(rewardPlans[_index]);
        }

        function removeRewardPlan(uint256 _index)
            public
            onlyOwner
            validRewardPlanIndex(_index)
        {
            require(rewardPlans[_index].deletedAt == 0, "Plan: reward plan does not exist");
            rewardPlans[_index].deletedAt = block.timestamp;
            emit RewardPlanRemoved(rewardPlans[_index]);
        }

        function calculateReward(Stake memory _stake)
            internal
            view
            onlyStakeholder
            returns (uint256)
        {
            RewardPlan memory _rewardPlan = rewardPlans[_stake.rewardPlanIndex];
            require(_rewardPlan.currentStaked > 0, "Staking: nothing staked yet");
            return _stake.amount * _rewardPlan.rewardsAvailable / _rewardPlan.currentStaked;
        }

        function showRewards(uint256 _stakeIndex) 
            public
            view
            returns (uint256)
        {
            return calculateReward(stakeholders[msg.sender].stakes[_stakeIndex]);
        }

        function addStakeholder(address _stakeholder)
            internal
        {
            stakeholders[_stakeholder].addr = _stakeholder;
        }

        event StakeCreated(address indexed stakeholder, Stake stake, RewardPlan rewardPlan);
        event StakeRemoved(address indexed stakeholder, Stake stake, RewardPlan rewardPlan);
        event RewardAdded(uint256 amount, uint256 rewardPlanIndex);
        event RewardRemoved(uint256 amount, uint256 rewardPlanIndex);
        event RewardPlanCreated(RewardPlan rewardPlan);
        event RewardPlanUpdated(RewardPlan rewardPlan);
        event RewardPlanRemoved(RewardPlan rewardPlan);
    }