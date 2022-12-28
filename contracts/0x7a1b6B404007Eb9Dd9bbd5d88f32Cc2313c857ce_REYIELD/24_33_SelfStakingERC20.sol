// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./RERC20.sol";
import "./ISelfStakingERC20.sol";
import "../Library/CheapSafeERC20.sol";
import "../Library/Roles.sol";

using CheapSafeERC20 for IERC20;

/**
    An ERC20 which gives out staking rewards just for owning the token, without the need to interact with staking contracts

    This seems... odd.  But it was necessary to avoid weird problems with other approaches with a separate staking contract

    The functionality is similar to masterchef or other popular staking contracts, with some notable differences:

        Interacting with it doesn't trigger rewards to be sent to you automatically
            Instead, it's tracked via "Owed" storage slots
            Necessary to stop contracts from accidentally earning USDC (ie: Uniswap, Sushiswap, etc)
        We add a reward, and it's split evenly over a period of time
        We can exclude addresses from receiving rewards (curve pools, uniswap, sushiswap, etc)
 */
abstract contract SelfStakingERC20 is RERC20, ISelfStakingERC20
{
    bytes32 private constant TotalStakingSupplySlot = keccak256("SLOT:SelfStakingERC20:totalStakingSupply");
    bytes32 private constant TotalRewardDebtSlot = keccak256("SLOT:SelfStakingERC20:totalRewardDebt");
    bytes32 private constant TotalOwedSlot = keccak256("SLOT:SelfStakingERC20:totalOwed");
    bytes32 private constant RewardInfoSlot = keccak256("SLOT:SelfStakingERC20:rewardInfo");
    bytes32 private constant RewardPerShareSlot = keccak256("SLOT:SelfStakingERC20:rewardPerShare");
    bytes32 private constant UserRewardDebtSlotPrefix = keccak256("SLOT:SelfStakingERC20:userRewardDebt");
    bytes32 private constant UserOwedSlotPrefix = keccak256("SLOT:SelfStakingERC20:userOwed");

    bytes32 private constant DelegatedClaimerRole = keccak256("ROLE:SelfStakingERC20:delegatedClaimer");
    bytes32 private constant RewardManagerRole = keccak256("ROLE:SelfStakingERC20:rewardManager");
    bytes32 private constant ExcludedRole = keccak256("ROLE:SelfStakingERC20:excluded");

    struct RewardInfo 
    {
        uint32 lastRewardTimestamp;
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint160 amountToDistribute;
    }

    bool public constant isSelfStakingERC20 = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable rewardToken;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol, uint8 _decimals) 
        RERC20(_name, _symbol, _decimals)
    {
        rewardToken = _rewardToken;
    }

    // Probably hooked up using functions from "Owned"
    function getSelfStakingERC20Owner() internal virtual view returns (address);

    /** The total supply MINUS balances held by excluded addresses */
    function totalStakingSupply() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalStakingSupplySlot).value; }

    function userRewardDebtSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(UserRewardDebtSlotPrefix, user))); }
    function userOwedSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(UserOwedSlotPrefix, user))); }

    function isExcluded(address user) public view returns (bool) { return Roles.hasRole(ExcludedRole, user); }
    function isDelegatedClaimer(address user) public view returns (bool) { return Roles.hasRole(DelegatedClaimerRole, user); }
    function isRewardManager(address user) public view returns (bool) { return Roles.hasRole(RewardManagerRole, user); }

    modifier onlySelfStakingERC20Owner()
    {
        if (msg.sender != getSelfStakingERC20Owner()) { revert NotSelfStakingERC20Owner(); }
        _;
    }

    function getRewardInfo()
        internal
        view
        returns (RewardInfo memory rewardInfo)
    {
        unchecked
        {
            uint256 packed = StorageSlot.getUint256Slot(RewardInfoSlot).value;
            rewardInfo.lastRewardTimestamp = uint32(packed >> 224);
            rewardInfo.startTimestamp = uint32(packed >> 192);
            rewardInfo.endTimestamp = uint32(packed >> 160);
            rewardInfo.amountToDistribute = uint160(packed);
        }
    }
    function setRewardInfo(RewardInfo memory rewardInfo)
        internal
    {
        unchecked
        {
            StorageSlot.getUint256Slot(RewardInfoSlot).value = 
                (uint256(rewardInfo.lastRewardTimestamp) << 224) |
                (uint256(rewardInfo.startTimestamp) << 192) |
                (uint256(rewardInfo.endTimestamp) << 160) |
                uint256(rewardInfo.amountToDistribute);
        }
    }

    /** 
        Excludes/includes an address from being able to receive rewards

        Any rewards already owing will be lost to the user, and will end up being added into the rewards pool next time rewards are added
     */
    function setExcluded(address user, bool excluded)
        public
        onlySelfStakingERC20Owner
    {
        if (isExcluded(user) == excluded) { return; }

        /*
            Our strategy is
                Nuke their balance (forces calculations to be done, too) 
                Set them as excluded/included
                If they're being excluded, we nuke their owed rewards
                Restore their balance
        */
        
        uint256 balance = balanceOf(user);
        if (balance > 0)
        {
            burnCore(user, balance);
        }

        Roles.setRole(ExcludedRole, user, excluded);

        if (excluded)
        {
            StorageSlot.Uint256Slot storage owedSlot = userOwedSlot(user);
            uint256 oldOwed = owedSlot.value;
            if (oldOwed != 0)
            {
                owedSlot.value = 0;
                StorageSlot.getUint256Slot(TotalOwedSlot).value -= oldOwed;
            }
        }

        if (balance > 0)
        {
            mintCore(user, balance);
        }

        emit Excluded(user, excluded);
    }

    function checkUpgrade(address newImplementation)
        internal
        virtual
        override
        view
        onlySelfStakingERC20Owner
    {
        ISelfStakingERC20 newContract = ISelfStakingERC20(newImplementation);
        assert(newContract.isSelfStakingERC20());
        if (newContract.rewardToken() != rewardToken) { revert WrongRewardToken(); }
        super.checkUpgrade(newImplementation);
    }

    function rewardData()
        public
        view
        returns (uint256 lastRewardTimestamp, uint256 startTimestamp, uint256 endTimestamp, uint256 amountToDistribute)
    {
        RewardInfo memory rewardInfo = getRewardInfo();
        lastRewardTimestamp = rewardInfo.lastRewardTimestamp;
        startTimestamp = rewardInfo.startTimestamp;
        endTimestamp = rewardInfo.endTimestamp;
        amountToDistribute = rewardInfo.amountToDistribute;
    }

    /** Calculates how much NEW reward should be released based on the distribution rate and time passed */
    function calculateReward(RewardInfo memory reward)
        private
        view
        returns (uint256)
    {
        if (block.timestamp <= reward.lastRewardTimestamp ||
            reward.lastRewardTimestamp >= reward.endTimestamp ||
            block.timestamp <= reward.startTimestamp ||
            reward.startTimestamp == reward.endTimestamp)
        {
            return 0;
        }
        uint256 from = reward.lastRewardTimestamp < reward.startTimestamp ? reward.startTimestamp : reward.lastRewardTimestamp;
        uint256 until = block.timestamp < reward.endTimestamp ? block.timestamp : reward.endTimestamp;
        return reward.amountToDistribute * (until - from) / (reward.endTimestamp - reward.startTimestamp);
    }

    function pendingReward(address user)
        public
        view
        returns (uint256)
    {
        if (isExcluded(user)) { return 0; }
        uint256 perShare = StorageSlot.getUint256Slot(RewardPerShareSlot).value;
        RewardInfo memory reward = getRewardInfo();
        uint256 totalStaked = totalStakingSupply();
        if (totalStaked != 0) 
        {
            perShare += calculateReward(reward) * 1e30 / totalStaked;
        }
        return balanceOf(user) * perShare / 1e30 - userRewardDebtSlot(user).value + userOwedSlot(user).value;
    }

    /** Updates the state with any new rewards, and returns the new rewardPerShare multiplier */
    function update() 
        private
        returns (uint256 rewardPerShare)
    {
        StorageSlot.Uint256Slot storage rewardPerShareSlot = StorageSlot.getUint256Slot(RewardPerShareSlot);
        rewardPerShare = rewardPerShareSlot.value;        
        RewardInfo memory reward = getRewardInfo();
        uint256 rewardToAdd = calculateReward(reward);
        if (rewardToAdd == 0) { return rewardPerShare; }

        uint256 totalStaked = totalStakingSupply();
        if (totalStaked > 0) 
        {
            rewardPerShare += rewardToAdd * 1e30 / totalStaked;
            rewardPerShareSlot.value = rewardPerShare;
        }

        reward.lastRewardTimestamp = uint32(block.timestamp);
        setRewardInfo(reward);
    }

    /** Adds rewards and updates the timeframes.  Any leftover rewards not yet distributed are added */
    function addReward(uint256 amount, uint256 startTimestamp, uint256 endTimestamp)
        public
    {
        if (!isRewardManager(msg.sender) && msg.sender != getSelfStakingERC20Owner()) { revert NotRewardManager(); }
        if (startTimestamp < block.timestamp) { startTimestamp = block.timestamp; }
        if (startTimestamp >= endTimestamp || endTimestamp > type(uint32).max) { revert InvalidParameters(); }
        uint256 rewardPerShare = update();
        rewardToken.transferFrom(msg.sender, address(this), amount);
        uint256 amountToDistribute = rewardToken.balanceOf(address(this)) + StorageSlot.getUint256Slot(TotalRewardDebtSlot).value - StorageSlot.getUint256Slot(TotalOwedSlot).value - totalStakingSupply() * rewardPerShare / 1e30;
        if (amountToDistribute > type(uint160).max) { revert TooMuch(); }
        setRewardInfo(RewardInfo({
            amountToDistribute: uint160(amountToDistribute),
            startTimestamp: uint32(startTimestamp),
            endTimestamp: uint32(endTimestamp),
            lastRewardTimestamp: uint32(block.timestamp)
        }));
        emit RewardAdded(amount);
    }

    function addRewardPermit(uint256 amount, uint256 startTimestamp, uint256 endTimestamp, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        IERC20Permit(address(rewardToken)).permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        addReward(amount, startTimestamp, endTimestamp);
    }

    /** Pays out all rewards */
    function claim()
        public
    {
        claimCore(msg.sender);
    }

    function claimFor(address user)
        public
    {
        if (!isDelegatedClaimer(msg.sender)) { revert NotDelegatedClaimer(); }
        claimCore(user);
    }

    function claimCore(address user)
        private
    {
        if (isExcluded(user)) { return; }
        uint256 rewardPerShare = update();
        StorageSlot.Uint256Slot storage owedSlot = userOwedSlot(user);
        uint256 oldOwed = owedSlot.value;
        StorageSlot.getUint256Slot(TotalOwedSlot).value -= oldOwed;
        StorageSlot.Uint256Slot storage rewardDebtSlot = userRewardDebtSlot(user);
        uint256 oldDebt = rewardDebtSlot.value;
        uint256 newDebt = balanceOf(user) * rewardPerShare / 1e30;
        uint256 claimAmount = oldOwed + newDebt - oldDebt;
        if (claimAmount == 0) { return; }
        owedSlot.value = 0;
        rewardDebtSlot.value = newDebt;
        StorageSlot.Uint256Slot storage totalRewardDebtSlot = StorageSlot.getUint256Slot(TotalRewardDebtSlot);
        totalRewardDebtSlot.value = totalRewardDebtSlot.value + newDebt - oldDebt;
        sendReward(user, claimAmount);
    }

    function sendReward(address user, uint256 amount)
        private
    {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (amount > balance) { amount = balance; }
        rewardToken.safeTransfer(user, amount);
        emit RewardPaid(user, amount);
    }

    /** update() must be called before this */
    function updateOwed(address user, uint256 rewardPerShare, uint256 currentBalance, uint256 newBalance)
        private
    {
        StorageSlot.Uint256Slot storage rewardDebtSlot = userRewardDebtSlot(user);
        uint256 oldDebt = rewardDebtSlot.value;
        uint256 pending = currentBalance * rewardPerShare / 1e30 - oldDebt;
        StorageSlot.getUint256Slot(TotalOwedSlot).value += pending;
        userOwedSlot(user).value += pending;
        uint256 newDebt = newBalance * rewardPerShare / 1e30;
        rewardDebtSlot.value = newDebt;
        StorageSlot.Uint256Slot storage totalRewardDebtSlot = StorageSlot.getUint256Slot(TotalRewardDebtSlot);
        totalRewardDebtSlot.value = totalRewardDebtSlot.value + newDebt - oldDebt;
    }

    function setDelegatedClaimer(address user, bool enable)
        public
        onlySelfStakingERC20Owner
    {
        Roles.setRole(DelegatedClaimerRole, user, enable);
    }

    function setRewardManager(address user, bool enable)
        public
        onlySelfStakingERC20Owner
    {
        Roles.setRole(RewardManagerRole, user, enable);
    }

    function beforeTransfer(address _from, address _to, uint256 _amount) 
        internal
        override
    {
        bool fromExcluded = isExcluded(_from);
        bool toExcluded = isExcluded(_to);
        if (!fromExcluded || !toExcluded)
        {
            uint256 rewardPerShare = update();
            uint256 balance;
            if (!fromExcluded)
            {
                balance = balanceOf(_from);
                updateOwed(_from, rewardPerShare, balance, balance - _amount);
            }
            if (!toExcluded)
            {
                balance = balanceOf(_to);
                updateOwed(_to, rewardPerShare, balance, balance + _amount);
            }
        }
        if (fromExcluded || toExcluded)
        {
            StorageSlot.Uint256Slot storage totalStaked = StorageSlot.getUint256Slot(TotalStakingSupplySlot);
            totalStaked.value = 
                totalStaked.value
                + (fromExcluded ? _amount : 0)
                - (toExcluded ? _amount : 0);
        }
    }    

    function beforeBurn(address _from, uint256 _amount) 
        internal
        override
    {
        if (!isExcluded(_from))
        {
            uint256 rewardPerShare = update();
            uint256 balance = balanceOf(_from);
            updateOwed(_from, rewardPerShare, balance, balance - _amount);
            StorageSlot.getUint256Slot(TotalStakingSupplySlot).value -= _amount;
        }
    }

    function beforeMint(address _to, uint256 _amount) 
        internal
        override
    {
        if (!isExcluded(_to))
        {
            uint256 rewardPerShare = update();
            uint256 balance = balanceOf(_to);
            updateOwed(_to, rewardPerShare, balance, balance + _amount);
            StorageSlot.getUint256Slot(TotalStakingSupplySlot).value += _amount;
        }
    }
}