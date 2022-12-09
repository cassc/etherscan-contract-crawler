// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IStakeManager.sol";
import "../IERC20Mintable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract StakeManager is IStakeManager, AccessControlUpgradeable {
    //# Token related variables
    IERC20Mintable internal token;
    uint256 internal tokenDecimals;
    uint256 internal calculatoryPips;

    //# Plan related variables
    bytes32[] internal planHashes;
    mapping(bytes32 => Plan) internal plans;

    //# Settings
    bool internal compoundEnabled;
    uint256 internal compoundPeriod;

    uint256 internal maxTokensIssued;
    uint256 internal pairTokensIssued;

    //# Stakes
    mapping(address => bytes32[]) internal userStakes;
    mapping(bytes32 => Stake) internal stakes;

    //#Token pricing
    address internal router;
    address[] internal pairTokens;

    //# Upgradability
    bool private constructed;

    //#V2
    uint256 internal expectedTokensIssued;
    uint256 internal tvl;
    mapping(bytes32 => uint256) internal stakeBlock;
    mapping(bytes32 => uint256) internal distributedAwards;

    function initialize(
        address token_,
        uint256 calculatoryPips_,
        address router_
    ) public virtual initializer {
        if (!constructed) {
            require(token_ != address(0), "StakeManager: Invalid token address");
            require(router_ != address(0), "StakeManager: Invalid router address");
            token = IERC20Mintable(token_);
            tokenDecimals = token.decimals();
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            calculatoryPips = calculatoryPips_;
            router = router_;
        }
    }

    function setPlan(
        uint256 period,
        uint256 apy,
        uint256 emergencyTax,
        uint256 minimalAmount
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes32) {
        require(period != 0 && apy != 0, "StakeManager: Invalid staking plan data");
        bytes32 planId = keccak256(abi.encode(period, apy, emergencyTax));
        Plan storage plan = plans[planId];
        if (plan.period == period) {
            plan.active = true;
            emit PlanSet(msg.sender, planId, period, apy, emergencyTax, minimalAmount, plan.pips);
            return planId;
        } else if (plan.period == 0) {
            plan.period = period;
            plan.apy = apy;
            plan.emergencyTax = emergencyTax;
            plan.minimalAmount = minimalAmount;
            plan.active = true;
            plan.pips = calculatoryPips;
            bytes32[] storage planIds = planHashes;
            planIds.push(planId);
            emit PlanSet(msg.sender, planId, period, apy, emergencyTax, minimalAmount, plan.pips);
            return planId;
        }
        revert("StakeManager: Invalid operation");
    }

    function deactivatePlan(bytes32 planId) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        Plan storage plan = plans[planId];
        require(plan.period != 0, "StakeManager: Invalid staking plan");
        plan.active = false;
        emit PlanDisabled(msg.sender, planId, plan.period, plan.apy, plan.emergencyTax, plan.pips);
    }

    function setCompoundEnabled(bool compoundEnabled_) external override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        compoundEnabled = compoundEnabled_;
        emit CompoundEnabled(msg.sender, compoundEnabled_);
        return compoundEnabled_;
    }

    function getCompoundEnabled() external view override returns (bool) {
        return compoundEnabled;
    }

    function setCompoundPeriod(uint256 compoundPeriod_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        require(compoundPeriod_ > 0, "StakeManager: Invalid compound period");
        compoundPeriod = compoundPeriod_;
        emit CompoundSet(msg.sender, compoundPeriod);
        return compoundPeriod;
    }

    modifier _maxTokensMintedCheck(uint256 maxTokensMinted) virtual {
        _;
    }

    function setMaxTokensMinted(uint256 maxTokensMinted)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        _maxTokensMintedCheck(maxTokensMinted)
        returns (uint256)
    {
        require(
            maxTokensMinted > expectedTokensIssued,
            "StakeManager: Already minted tokens are more than proposed mintable amount"
        );
        maxTokensIssued = maxTokensMinted;
        emit MaxTokensMinted(msg.sender, maxTokensMinted);
        return maxTokensMinted;
    }

    function getMaxTokensMinted() external view override returns (uint256) {
        return maxTokensIssued;
    }

    function getCompoundPeriod() external view override returns (uint256) {
        return compoundPeriod;
    }

    function getPricePairs() external view override returns (address[] memory) {
        return pairTokens;
    }

    function getPips() external view override returns (uint256) {
        return calculatoryPips;
    }

    function getIssuedTokens() external view override returns (uint256) {
        return pairTokensIssued;
    }

    function getExpectedIssuedTokens() external view returns (uint256) {
        return expectedTokensIssued;
    }

    function getTVL() external view returns (uint256) {
        return tvl;
    }

    function getRouter() external view override returns (address) {
        return router;
    }

    function setPricePair(address nativeToken, address stableToken)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address[] memory)
    {
        require(nativeToken != address(0) && stableToken != address(0), "StakeManager: Invalid pricePair address");
        delete pairTokens;
        pairTokens = new address[](2);
        pairTokens[0] = nativeToken;
        pairTokens[1] = stableToken;
        emit PricePairSet(msg.sender, pairTokens);
        return pairTokens;
    }

    function stake(
        uint256 amount,
        bytes32 planId,
        bool compound
    ) public virtual override returns (bytes32) {
        _transferTokens(msg.sender, amount);
        return _stake(msg.sender, amount, planId, compoundEnabled ? compound : false);
    }

    function stakeCombined(
        uint256 amount,
        bytes32 planId,
        bool compound,
        //@TODO change to a single stake
        bytes32[] calldata stakes_,
        bool toWithdrawRewards
    ) external virtual override returns (bytes32) {
        _transferTokens(msg.sender, amount);
        uint256 amountCombined = amount;
        bytes32[] memory combinableStakes = getCombinableStakes(msg.sender, amount, planId);
        bytes32 stakeId = stakes_[0];
        Stake storage userStake;
        for (uint256 k = 0; k < combinableStakes.length; k++) {
            if (stakeId == combinableStakes[k]) {
                userStake = stakes[stakeId];
                if (toWithdrawRewards) {
                    _withdrawRewards(userStake, stakeId, msg.sender);
                } else {
                    uint256 rewards = _calculateRewards(userStake, userStake.lastWithdrawn, block.timestamp);
                    amountCombined += rewards;
                    pairTokensIssued += rewards;
                }
                bytes32[] memory stakesToCombine = new bytes32[](1);
                stakesToCombine[0] = stakeId;
                return
                    _stakeCombined(
                        msg.sender,
                        amountCombined,
                        planId,
                        compoundEnabled ? compound : false,
                        stakesToCombine
                    );
            }
        }
        revert("StakeManager: Invalid stake to be combined");
    }

    function _stakeCombined(
        address sender,
        uint256 amount,
        bytes32 planId,
        bool compound,
        bytes32[] memory stakes_
    ) internal virtual returns (bytes32) {
        sender;
        amount;
        planId;
        compound;
        stakes_;
        return bytes32(0);
        //revert("StakeManager: method no implemented");
    }

    function emergencyExit(bytes32 stakeId) external override returns (uint256 withdrawn, uint256 emergencyLoss) {
        _removeUserStake(msg.sender, stakeId);
        Stake memory userStake = stakes[stakeId];
        require(userStake.account == msg.sender, "StakeManager: Invalid stake");

        Plan memory plan = plans[userStake.planId];
        uint256 deadline = userStake.depositTime + plan.period * 1 days;
        require(block.timestamp <= deadline, "StakeManager: Can unstake");
        uint256 rewards = _calculateRewards(userStake, userStake.lastWithdrawn, block.timestamp);
        uint256 eLOnDistributed = (distributedAwards[stakeId] * plan.emergencyTax) / 100;
        emergencyLoss = ((userStake.amount + rewards) * plan.emergencyTax) / 100 + eLOnDistributed;
        withdrawn = (userStake.amount + rewards) - emergencyLoss;

        pairTokensIssued -= eLOnDistributed;
        pairTokensIssued += rewards > 0 ? rewards - ((rewards * plan.emergencyTax) / 100) : 0;
        _subExcessExpectedRewards(
            _calculateRewards(userStake, _calculateLastWithdrawn(userStake), deadline) +
                eLOnDistributed +
                ((rewards * plan.emergencyTax) / 100)
        );
        tvl -= userStake.amount;
        _exitWithdraw(withdrawn, userStake.amount);
        _emitEmergencyExit(withdrawn, stakeId, userStake, plan);
        delete stakes[stakeId];
        delete stakeBlock[stakeId];
        delete distributedAwards[stakeId];
    }

    function _subExcessExpectedRewards(uint256 expectedRewards) internal {
        require(
            expectedTokensIssued - expectedRewards >= pairTokensIssued,
            "StakeManager: Expected rewards cannot be less than already issued tokens"
        );
        expectedTokensIssued -= expectedRewards;
    }

    function _exitWithdraw(uint256 withdrawn, uint256 totalAmount) internal virtual {
        withdrawn;
        totalAmount;
        //revert("StakeManager: Method not yet implemented");
    }

    function _emitEmergencyExit(
        uint256 withdrawn,
        bytes32 stakeId,
        Stake memory userStake,
        Plan memory plan
    ) internal {
        (
            address[] memory tokenAddresses,
            uint256[] memory priceComparison,
            bool[] memory stakedMoreExpensive
        ) = _calculateTokenPrice();

        emit EmergencyExited(
            msg.sender,
            userStake.amount,
            withdrawn,
            userStake.planId,
            stakeId,
            userStake.depositTime,
            userStake.depositTime + plan.period * 1 days,
            plan.period,
            plan.apy,
            plan.emergencyTax,
            userStake.compound,
            tokenAddresses,
            priceComparison,
            stakedMoreExpensive,
            calculatoryPips
        );
    }

    function _removeUserStake(address owner, bytes32 stakeId) internal {
        bytes32[] memory _userStakes = userStakes[owner];
        if (_userStakes.length > 1) {
            bytes32[] memory newUserStakes = new bytes32[](_userStakes.length - 1);
            uint256 newUserStakesIter = newUserStakes.length - 1;
            for (uint256 i = _userStakes.length; i > 0; i--) {
                if (_userStakes[i - 1] != stakeId) {
                    newUserStakes[newUserStakesIter] = _userStakes[i - 1];
                    newUserStakesIter = newUserStakesIter > 0 ? newUserStakesIter - 1 : 0;
                }
            }
            userStakes[owner] = newUserStakes;
        } else userStakes[owner] = new bytes32[](0);
        _unregisterStake(owner, stakeId);
    }

    function _unregisterStake(address owner, bytes32 stakeId) internal virtual {
        owner;
        stakeId;
    }

    function unstake(bytes32 stakeId) external override returns (uint256) {
        return _unstake(stakeId, msg.sender);
    }

    function unstakeTo(bytes32 stakeId, address recipient) external override returns (uint256) {
        return _unstake(stakeId, recipient);
    }

    function _unstake(bytes32 stakeId, address recipient) internal returns (uint256) {
        _removeUserStake(msg.sender, stakeId);
        Stake storage userStake = stakes[stakeId];
        require(userStake.account == msg.sender, "StakeManager: Invalid stake");
        Plan memory plan = plans[userStake.planId];
        require(
            block.timestamp >= userStake.depositTime + plan.period * 1 days,
            "StakeManager: Stake not yet available to unstake"
        );
        uint256 amount = userStake.amount;
        uint256 rewards = _withdrawRewards(userStake, stakeId, recipient);
        _emitUnstaked(userStake, rewards, stakeId, plan);
        tvl -= amount;
        delete stakes[stakeId];
        delete stakeBlock[stakeId];
        require(token.transfer(recipient, amount), "PoolStakeManager: Cannot make transfer");
        return amount + rewards;
    }

    function _emitUnstaked(
        Stake memory userStake,
        uint256 rewards,
        bytes32 stakeId,
        Plan memory plan
    ) internal {
        (
            address[] memory tokenAddresses,
            uint256[] memory priceComparison,
            bool[] memory stakedMoreExpensive
        ) = _calculateTokenPrice();
        bool tempCompound = userStake.compound;
        emit Unstaked(
            msg.sender,
            userStake.amount,
            userStake.amount + rewards,
            userStake.planId,
            stakeId,
            userStake.depositTime,
            block.timestamp,
            plan.period,
            plan.apy,
            plan.emergencyTax,
            tempCompound,
            tokenAddresses,
            priceComparison,
            stakedMoreExpensive,
            calculatoryPips
        );
    }

    function withdrawRewards(bytes32 stakeId) external override returns (uint256) {
        Stake storage userStake = stakes[stakeId];
        require(userStake.account == msg.sender, "StakeManager: Invalid stake");

        return _withdrawRewards(userStake, stakeId, msg.sender);
    }

    function withdrawRewardsTo(bytes32 stakeId, address recipient) external override returns (uint256) {
        Stake storage userStake = stakes[stakeId];
        require(userStake.account == msg.sender, "StakeManager: Invalid stake");

        return _withdrawRewards(userStake, stakeId, recipient);
    }

    function _withdrawRewards(
        Stake storage userStake,
        bytes32 stakeId,
        address recipient
    ) internal returns (uint256) {
        uint256 rewards = _calculateRewards(userStake, userStake.lastWithdrawn, block.timestamp);
        pairTokensIssued += rewards;
        if (rewards > 0) {
            distributedAwards[stakeId] += rewards;
            _withdrawMethod(recipient, rewards);
            userStake.lastWithdrawn = _calculateLastWithdrawn(userStake);
            _emitRewardsWithdrawn(rewards, userStake, stakeId);
        }
        return rewards;
    }

    function _calculateLastWithdrawn(Stake memory userStake) internal view returns (uint256) {
        (bool success, uint256 mod) = SafeMathUpgradeable.tryMod(
            block.timestamp - userStake.lastWithdrawn,
            userStake.compoundPeriod
        );
        if (success) {
            return block.timestamp - mod;
        } else {
            return block.timestamp;
        }
    }

    function _withdrawMethod(address recipient, uint256 amount) internal virtual {
        recipient;
        amount;
        //revert("StakeManager: Method not yet implemented");
    }

    function _emitRewardsWithdrawn(
        uint256 rewards,
        Stake memory userStake,
        bytes32 stakeId
    ) internal {
        (
            address[] memory tokenAddresses,
            uint256[] memory priceComparison,
            bool[] memory stakedMoreExpensive
        ) = _calculateTokenPrice();
        emit RewardsWithdrawn(
            msg.sender,
            rewards,
            userStake.planId,
            stakeId,
            userStake.amount,
            block.timestamp,
            tokenAddresses,
            priceComparison,
            stakedMoreExpensive,
            calculatoryPips
        );
    }

    function _calculateRewards(
        Stake memory userStake,
        uint256 startPeriod,
        uint256 endPeriod
    ) internal view returns (uint256) {
        require(endPeriod > startPeriod && endPeriod > userStake.depositTime, "StakeManager: Invalid periods");
        Plan memory userPlan = plans[userStake.planId];
        uint256 startTime = startPeriod > userStake.depositTime ? startPeriod : userStake.depositTime;
        uint256 endTime = endPeriod < userStake.depositTime + userPlan.period * 1 days
            ? endPeriod
            : userStake.depositTime + userPlan.period * 1 days;
        if (startTime >= endTime) {
            return 0;
        }
        uint256 timeDifference = endTime - startTime;
        (, uint256 rewardingTimes) = SafeMathUpgradeable.tryDiv(timeDifference, userStake.compoundPeriod);
        (, uint256 periodDelimiter) = SafeMathUpgradeable.tryDiv((365 * 1 days), userStake.compoundPeriod);
        uint256 tokenMultiplier = 10**(tokenDecimals);
        uint256 pips = 10**calculatoryPips;
        uint256 stakedAmount = userStake.amount;
        if (userStake.compound) {
            (, uint256 percentPerPeriod) = SafeMathUpgradeable.tryDiv(userPlan.apy * tokenMultiplier, periodDelimiter);
            uint256 skippedTimeDifference = startTime - userStake.depositTime;
            uint256 skippedTimes = skippedTimeDifference / userStake.compoundPeriod;
            uint256 skippedRewards = 0;
            for (uint256 i = 0; i < skippedTimes; i++) {
                bool successSkipped = false;
                uint256 resSkipped = 0;
                (successSkipped, resSkipped) = SafeMathUpgradeable.tryDiv(
                    (stakedAmount + skippedRewards) * percentPerPeriod,
                    100 * tokenMultiplier * pips
                );
                if (successSkipped) skippedRewards += resSkipped;
                else revert("StakeManager: Cannot calculate rewards");
            }
            uint256 rewards = 0;
            for (uint256 i = 0; i < rewardingTimes; i++) {
                bool successRewards = false;
                uint256 resRewards = 0;
                (successRewards, resRewards) = SafeMathUpgradeable.tryDiv(
                    ((stakedAmount + skippedRewards + rewards) * percentPerPeriod),
                    (100 * tokenMultiplier * pips)
                );
                if (successRewards) rewards += resRewards;
                else revert("StakeManager: Cannot calculate rewards");
            }
            return rewards;
        } else {
            bool successRewards = false;
            uint256 resRewards = 0;
            (successRewards, resRewards) = SafeMathUpgradeable.tryDiv(
                stakedAmount * rewardingTimes * userPlan.apy * tokenMultiplier,
                periodDelimiter * tokenMultiplier * 100 * pips
            );
            if (successRewards) return (resRewards);
            else revert("StakeManager: Cannot calculate rewards");
        }
    }

    function expectedRevenue(
        uint256 amount,
        bytes32 planId,
        bool compound,
        uint256 startPeriod,
        uint256 endPeriod
    ) public view virtual override returns (uint256) {
        Plan memory plan = plans[planId];
        require(plan.active, "StakeManager: Plan Inactive");
        Stake memory tempStake = Stake(
            msg.sender,
            amount,
            startPeriod,
            planId,
            compoundEnabled ? compound : false,
            compoundPeriod,
            startPeriod
        );
        return _calculateRewards(tempStake, startPeriod, endPeriod);
    }

    function _transferTokens(address account, uint256 amount) internal {
        require(amount > 0, "StakeManager: Invalid staking amount");
        require(token.allowance(account, address(this)) >= amount, "StakeManager: Increase allowance");
        require(token.transferFrom(account, address(this), amount), "StakeManager: Cannot make transfer");
    }

    function _calculateTokenPrice()
        internal
        view
        returns (
            address[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        if (pairTokens.length == 0) {
            return (new address[](0), new uint256[](0), new bool[](0));
        }
        address[] memory tokenAddresses = new address[](pairTokens.length + 1);
        tokenAddresses[0] = address(token);
        for (uint256 i = 0; i < pairTokens.length; i++) {
            tokenAddresses[i + 1] = pairTokens[i];
        }

        bool[] memory stakedMoreExpensive = new bool[](pairTokens.length + 1);
        stakedMoreExpensive[0] = false;
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(10**tokenDecimals, tokenAddresses);
        for (uint256 i = 1; i < amounts.length; i++) {
            stakedMoreExpensive[i] = amounts[i] >= 10**tokenDecimals;
        }
        return (tokenAddresses, amounts, stakedMoreExpensive);
    }

    function _stake(
        address account,
        uint256 amount,
        bytes32 planId,
        bool compound
    ) internal returns (bytes32) {
        Plan memory chosenPlan = plans[planId];
        require(amount >= chosenPlan.minimalAmount, "StakeManager: staking amount is less than plan minimum");
        require(chosenPlan.apy != 0 && chosenPlan.active, "StakeManager: Invalid planId");
        require(chosenPlan.active, "StakeManager: Plan inactive");
        require(compoundPeriod != 0, "StakeManager: Invalid compound period");

        uint256 depositTime = block.timestamp;
        bytes32 stakeId = keccak256(
            abi.encode(
                account,
                amount,
                depositTime,
                chosenPlan.period,
                chosenPlan.apy,
                chosenPlan.emergencyTax,
                compound,
                compoundPeriod
            )
        );
        //Emits earlier than it should, due to `Stack too deep` error
        uint256 deadline = depositTime + 1 days * chosenPlan.period;
        Stake memory newStake = Stake(account, amount, depositTime, planId, compound, compoundPeriod, depositTime);
        tvl += amount;
        uint256 expectedRewards = _calculateRewards(newStake, depositTime, deadline + 2);
        _addExpectedRewards(expectedRewards);
        _emitStaked(msg.sender, amount, planId, stakeId, depositTime, deadline, chosenPlan, compound);
        _registerStake(msg.sender, stakeId, amount);
        Stake memory stakeEntry = stakes[stakeId];
        require(stakeEntry.account == address(0), "StakeManager: Stake exists");

        stakes[stakeId] = newStake;
        stakeBlock[stakeId] = block.number;
        bytes32[] storage _userStakes = userStakes[account];
        _userStakes.push(stakeId);

        return stakeId;
    }

    function _addExpectedRewards(uint256 expectedRewards) internal {
        require(
            expectedTokensIssued + expectedRewards <= /* buffer*/
                maxTokensIssued,
            "StakeManager: Rewards will exceed current token minting limit"
        );
        expectedTokensIssued += expectedRewards;
    }

    function _registerStake(
        address owner,
        bytes32 stakeId,
        uint256 amount
    ) internal virtual {
        owner;
        stakeId;
        amount;
    }

    function _emitStaked(
        address account,
        uint256 amount,
        bytes32 planId,
        bytes32 stakeId,
        uint256 depositTime,
        uint256 deadline,
        Plan memory plan,
        bool compound
    ) internal {
        (
            address[] memory tokenAddresses,
            uint256[] memory priceComparison,
            bool[] memory stakedMoreExpensive
        ) = _calculateTokenPrice();
        emit Staked(
            account,
            amount,
            planId,
            stakeId,
            depositTime,
            deadline,
            plan.period,
            plan.apy,
            plan.emergencyTax,
            compound,
            tokenAddresses,
            priceComparison,
            stakedMoreExpensive,
            calculatoryPips
        );
    }

    //getters
    function getStakes() external view override returns (StakeData[] memory) {
        return getStakesByAddress(msg.sender);
    }

    function getStakesByAddress(address owner) public view override returns (StakeData[] memory) {
        bytes32[] memory stakeIds = userStakes[owner];
        StakeData[] memory userStakeData = new StakeData[](stakeIds.length);
        for (uint256 i = 0; i < userStakeData.length; i++) {
            Stake memory userStake = stakes[stakeIds[i]];
            userStakeData[i] = StakeData(
                userStake.account,
                stakeIds[i],
                userStake.amount,
                userStake.depositTime,
                stakeBlock[stakeIds[i]],
                userStake.planId,
                userStake.compound,
                userStake.compoundPeriod,
                userStake.lastWithdrawn
            );
        }
        return userStakeData;
    }

    function getStakesById(bytes32[] memory stakeIds) public view override returns (Stake[] memory) {
        Stake[] memory _stakes = new Stake[](stakeIds.length);
        for (uint256 i = 0; i < _stakes.length; i++) {
            _stakes[i] = stakes[stakeIds[i]];
        }
        return _stakes;
    }

    function getDistributedAmount(bytes32 stakeId) external view override returns (uint256) {
        return distributedAwards[stakeId];
    }

    function getCombinableStakes(
        address owner,
        uint256 amount,
        bytes32 planId
    ) public view virtual override returns (bytes32[] memory) {
        owner;
        amount;
        planId;
        return new bytes32[](0);
        //revert("StakeManager: Base class does not implement the method");
    }

    function getStakeRewards(
        bytes32 stakeId,
        uint256 startPeriod,
        uint256 endPeriod
    ) external view returns (uint256) {
        Stake memory userStake = stakes[stakeId];
        return _calculateRewards(userStake, startPeriod, endPeriod);
    }

    function getPlan(bytes32 planId) external view override returns (Plan memory) {
        return plans[planId];
    }

    function getPlans() external view override returns (Plan[] memory plan, bytes32[] memory planIds) {
        plan = new Plan[](planHashes.length);
        planIds = planHashes;
        for (uint256 i = 0; i < plan.length; i++) {
            plan[i] = plans[planHashes[i]];
        }
    }

    function getToken() external view override returns (address) {
        return address(token);
    }

    uint256[50] private gap;
}