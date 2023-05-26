// SPDX-License-Identifier: --🦉--

pragma solidity ^0.8.0;

import './InsuranceHelper.sol';

contract WiseInsurance is InsuranceHelper {

    function createStakeBulk(
        uint256[] memory _stakedAmount,
        uint64[] memory _lockDays,
        address[] memory _referrer
    )
        external
    {
        for(uint256 i = 0; i < _stakedAmount.length; i++) {
            createStake(
                _stakedAmount[i],
                _lockDays[i],
                _referrer[i]
            );
        }
    }

    function createStakeWithETH(
        uint64 _lockDays,
        address _referrer
    )
        external
        payable
    {
        address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = wiseToken;

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapExactETHForTokens{value: msg.value}(
            1,
            path,
            msg.sender,
            block.timestamp + 2 hours
        );

        createStake(
            amounts[1],
            _lockDays,
            _referrer
        );
    }

    function createStake(
        uint256 _stakedAmount,
        uint64 _lockDays,
        address _referrer
    )
        public
    {
        require(
            _lockDays <= MAX_STAKE_DAYS,
            DECREASE_STAKE_DURATION
        );

        require(
            allowInsurance == true,
            INSURANCE_DISABLED
        );

        uint256 toStake =  _stakedAmount * stakePercent / 100;
        uint256 toBuffer = _stakedAmount - toStake;

        uint256 toReturn = _calculateEmergencyAmount(
            toStake,
            principalCut
        );

        uint256 matureReturn = _calculateMatureAmount(
            toStake,
            toBuffer,
            principalCut
        );

        address staker = msg.sender;

        safeTransferFrom(
            wiseToken,
            staker,
            address(this),
            _stakedAmount
        );

        _increaseTotalStaked(
            toStake
        );

        _increaseTotalCovers(
            toReturn
        );

        require(
            getCoveredPercent() >= coverageThreshold,
            BELOW_COVERAGE_THRESHOLD
        );

        (bytes16 stakeID, uint256 stakedAmount, bytes16 referralID) =

        WISE_CONTRACT.createStake(
            toStake,
            _lockDays,
            _referrer
        );

        uint256 stakeIndex = insuranceStakeCounts[staker];

        insuranceStakes[staker][stakeIndex].stakeID = stakeID;
        insuranceStakes[staker][stakeIndex].stakedAmount = toStake;
        insuranceStakes[staker][stakeIndex].bufferAmount = toBuffer;
        insuranceStakes[staker][stakeIndex].matureAmount = matureReturn;
        insuranceStakes[staker][stakeIndex].emergencyAmount = toReturn;
        insuranceStakes[staker][stakeIndex].currentOwner = staker;
        insuranceStakes[staker][stakeIndex].isActive = true;

        _increaseInsuranceStakeCounts(staker);
        _increaseActiveInsuranceStakeCount();

        emit InsurancStakeOpened(
            stakeID,
            stakedAmount,
            toReturn,
            staker,
            stakeIndex,
            referralID
        );
    }

    function endStake(
        uint256 _stakeIndex
    )
        external
    {
        address _staker = msg.sender;

        if (checkMatureStake(
            _staker,
            _stakeIndex
        ) == false) {

            _emergencyExitStake(
                _staker,
                _stakeIndex
            );

        } else {

            _endMatureStake(
                _staker,
                _stakeIndex
            );
        }
    }

    function _emergencyExitStake(
        address _staker,
        uint256 _stakeIndex
    )
        internal
    {
        require(
            checkActiveStake(
                _staker,
                _stakeIndex
            ) == true,
            NOT_ACTIVE_STAKE
        );

        require(
            checkOwnership(
                _staker,
                _stakeIndex
            ) == true,
            NOT_YOUR_STAKE
        );

        _renounceStakeOwnership(
            _staker,
            _stakeIndex
        );

        _trackOwnerlessStake(
            _staker,
            _stakeIndex
        );

        emit NewOwnerlessStake (
            ownerlessStakeCount,
            _stakeIndex,
            _staker
        );

        _increaseOwnerlessStakeCount();
        _increaseActiveOwnerlessStakeCount();

        uint256 toReturn = getEmergencyAmount(
            _staker,
            _stakeIndex
        );

        bytes16 stakeID = getStakeID(
            _staker,
            _stakeIndex
        );

        uint256 matureLevel = checkMatureLevel(
            address(this),
            stakeID
        );

        uint256 amountAfterFee = penaltyFee(
            toReturn,
            matureLevel
        );

        safeTransfer(
            wiseToken,
            _staker,
            amountAfterFee
        );

        _increaseTotalMasterProfits(
            toReturn - amountAfterFee
        );

        _decreaseTotalCovers(
            toReturn
        );

        emit EmergencyExitStake(
            _staker,
            _stakeIndex,
            stakeID,
            amountAfterFee,
            toReturn,
            WISE_CONTRACT.currentWiseDay()
        );
    }

    function endMatureStake(
        address _staker,
        uint256 _stakeIndex
    )
        external
        onlyWorker
    {
        _endMatureStake(
            _staker,
            _stakeIndex
        );
    }

    function _endMatureStake(
        address _staker,
        uint256 _stakeIndex
    )
        internal
    {
        require(
            checkOwnership(
                _staker,
                _stakeIndex
            ) == true,
            NOT_YOUR_STAKE
        );

        require(
            checkMatureStake(
                _staker,
                _stakeIndex
            ) == true,
            NOT_MATURE_STAKE
        );

        require(
            checkActiveStake(
                _staker,
                _stakeIndex
            ) == true,
            NOT_ACTIVE_STAKE
        );

        _deactivateStake(
            _staker,
            _stakeIndex
        );

        _decreaseActiveInsuranceStakeCount();

        bytes16 stakeID = getStakeID(
            _staker,
            _stakeIndex
        );

        uint256 totalReward = WISE_CONTRACT.endStake(
            stakeID
        );

        uint256 stakedAmount = getStakedAmount(
            _staker,
            _stakeIndex
        );

        uint256 returnAmount = getMatureAmount(
            _staker,
            _stakeIndex
        );

        uint256 emergencyAmount = getEmergencyAmount(
            _staker,
            _stakeIndex
        );

        safeTransfer(
            wiseToken,
            _staker,
            returnAmount
        );

        uint256 rewardAfterFee = applyFee(
            totalReward,
            interestCut
        );

        safeTransfer(
            wiseToken,
            _staker,
            rewardAfterFee
        );

        _increaseTotalMasterProfits(
            stakedAmount > returnAmount ?
            stakedAmount - returnAmount : 0
        );

        _increaseTotalMasterProfits(
            totalReward - rewardAfterFee
        );

        _decreaseTotalStaked(
            stakedAmount
        );

        _decreaseTotalCovers(
            emergencyAmount
        );

        emit InsuranceStakeClosed(
            _staker,
            _stakeIndex,
            stakeID,
            returnAmount,
            rewardAfterFee
        );
    }

    function endOwnerlessStake(
        uint256 _ownerlessStakeIndex
    )
        external
        onlyWorker
    {
        (address staker, uint256 stakeIndex) =
        getStakeData(_ownerlessStakeIndex);

        require(
            checkOwnerlessStake(
                staker,
                stakeIndex
            ) == true,
            NOT_OWNERLESS_STAKE
        );

        require(
            checkMatureStake(
                staker,
                stakeIndex
            ) == true,
            NOT_MATURE_STAKE
        );

        require(
            checkActiveStake(
                staker,
                stakeIndex
            ) == true,
            NOT_ACTIVE_STAKE
        );

        _deactivateStake(
            staker,
            stakeIndex
        );

        _decreaseActiveInsuranceStakeCount();
        _decreaseActiveOwnerlessStakeCount();

        bytes16 stakeID = getStakeID(
            staker,
            stakeIndex
        );

        uint256 totalReward = WISE_CONTRACT.endStake(
            stakeID
        );

        uint256 stakedAmount = getStakedAmount(
            staker,
            stakeIndex
        );

        uint256 emergencyAmount = getEmergencyAmount(
            staker,
            stakeIndex
        );

        uint256 bufferAmount = getBufferAmount(
            staker,
            stakeIndex
        );

        _increaseTotalMasterProfits(
            totalReward
        );

        _increaseTotalMasterProfits(
            stakedAmount - emergencyAmount + bufferAmount
        );

        _decreaseTotalStaked(
            stakedAmount
        );

        emit OwnerlessStakeClosed (
            _ownerlessStakeIndex,
            staker,
            stakeIndex,
            stakeID,
            stakedAmount,
            totalReward
        );
    }

    function contributeAsPublic(
        uint256 _amount
    )
        external
    {
        address contributor = msg.sender;

        require(
            allowPublicContributions == true,
            PUBLIC_CONTRIBUTIONS_DISABLED
        );

        safeTransferFrom(
            wiseToken,
            contributor,
            address(this),
            _amount
        );

        uint256 percent = 100 + publicRewardPercent;
        uint256 toReturn = _amount * percent / 100;

        _increasePublicReward(
            contributor,
            toReturn
        );

        _increasePublicDebth(
            toReturn
        );

        require(
            totalPublicDebth <= publicDebthCap,
            EXCEEDING_PUBLIC_DEBTH_CAP
        );

        emit TreasuryFunded(
            _amount,
            contributor,
            getCurrentBuffer()
        );
    }

    function takePublicProfits()
        external
    {
        issuePublicProfits(
            msg.sender
        );
    }

    function issuePublicProfits(
        address _contributor
    )
        public
    {
        require(
            publicReward[_contributor] > 0,
            NO_REWARD_FOR_CONTRIBUTOR
        );

        require(
            totalPublicDebth > 0,
            NO_PUBLIC_DEBTH
        );

        require(
            totalPublicRewards > 0,
            NO_PUBLIC_REWARD_AVAILABLE
        );

        uint256 amount = publicReward[_contributor];

        _decreasePublicDebth(
            amount
        );

        _decreasePublicRewards(
            amount
        );

        _decreasePublicReward(
            _contributor,
            amount
        );

        safeTransfer(
            wiseToken,
            _contributor,
            amount
        );

        emit PublicProfit(
            _contributor,
            amount,
            totalPublicDebth,
            totalPublicRewards
        );
    }

    function givePublicRewards(
        uint256 _amount
    )
        external
        onlyMaster
    {
        _decreaseTotalMasterProfits(
            _amount
        );

        _increasePublicRewards(
            _amount
        );

        require(
            totalPublicRewards <= totalPublicDebth
        );

        require(
            getCoveredPercent(totalPublicRewards) >= payoutThreshold,
            BELOW_PAYOUT_THRESHOLD
        );

        require(
            allowPublicContributions == false,
            PUBLIC_CONTRIBUTION_MUST_BE_DISABLED
        );

        emit publicRewardsGiven(
            _amount,
            totalPublicDebth,
            totalPublicRewards
        );
    }

    function takeMasterProfits(
        uint256 _amount
    )
        external
        onlyMaster
    {
        require(
            totalPublicDebth == 0,
            PUBLIC_DEBTH_NOT_PAID
        );

        safeTransfer(
            wiseToken,
            insuranceMaster,
            _amount
        );

        if (activeInsuranceStakeCount > 0) {
            require(
                _amount <= totalMasterProfits
            );
        }

        _decreaseTotalMasterProfits(
            _amount
        );

        require(
            getCoveredPercent() >= payoutThreshold,
            BELOW_PAYOUT_THRESHOLD
        );

        emit ProfitsTaken(
            _amount,
            getCurrentBuffer()
        );
    }

    function openBufferStake(
        uint256 _amount,
        uint64 _duration,
        address _referrer
    )
        external
        onlyWorker
    {
        require(
            _duration <= maximumBufferStakeDuration
        );

        (bytes16 stakeID, uint256 stakedAmount, bytes16 referralID) =

        WISE_CONTRACT.createStake(
            _amount,
            _duration,
            _referrer
        );

        bufferStakes[bufferStakeCount].stakedAmount = _amount;
        bufferStakes[bufferStakeCount].stakeID = stakeID;
        bufferStakes[bufferStakeCount].isActive = true;

        _increaseTotalBufferStaked(
            _amount
        );

        require(
            totalBufferStaked <= bufferStakeCap
        );

        require(
            getCoveredPercent(_amount) >= coverageThreshold
        );

        _increaseBufferStakeCount();
        _increaseActiveBufferStakeCount();

        emit BufferStakeOpened(
            stakeID,
            stakedAmount,
            referralID
        );
    }

    function closeBufferStake(
        uint256 _stakeIndex
    )
        external
        onlyWorker
    {
        require(
            bufferStakes[_stakeIndex].isActive,
            NOT_ACTIVE_STAKE
        );

        bufferStakes[_stakeIndex].isActive = false;

        bytes16 stakeID = bufferStakes[_stakeIndex].stakeID;

        require(
            checkMatureStake(stakeID) == true,
            NOT_MATURE_STAKE
        );

        uint256 reward = WISE_CONTRACT.endStake(
            stakeID
        );

        uint256 staked = bufferStakes[_stakeIndex].stakedAmount;

        if (getBufferStakeInterest) {
            _withdrawDeveloperFunds(reward);
        } else {
            _increaseTotalMasterProfits(reward);
        }

        _decreaseTotalBufferStaked(
            staked
        );

        _decreaseActiveBufferStakeCount();

        emit BufferStakeClosed(
            stakeID,
            staked,
            reward
        );
    }

    function enableInsurance()
        external
        onlyMaster
    {
        allowInsurance = true;
    }

    function disableInsurance()
        external
        onlyMaster
    {
        allowInsurance = false;
    }

    /**
     * @notice ability to change worker address
     * @dev this address is used as helper
     * @param _newInsuranceWorker address new worker
     */
    function changeInsuranceWorker(
        address payable _newInsuranceWorker
    )
        external
        onlyMaster
    {
        insuranceWorker = _newInsuranceWorker;
    }

    /**
     * @notice ability for master to increase or decrease
     * percentage of the principal that gets staked
     * @param _newStakePercent in range between 85-100%
     */
    function changeStakePercent(
        uint256 _newStakePercent
    )
        external
        onlyMaster
    {
        require(
            _newStakePercent >= 85 &&
            _newStakePercent <= 100
        );

        stakePercent = _newStakePercent;
    }

    /**
     * @notice ability for master to increase or decrease
     * percentage of the interest that gets as fee
     * @param _newInterestCut in range between 0-10%
     */
    function changeInterestCut(
        uint256 _newInterestCut
    )
        external
        onlyMaster
    {
        require(
            _newInterestCut >= 0 &&
            _newInterestCut <= 10
        );

        interestCut = _newInterestCut;
    }

    /**
     * @notice ability for master to increase or decrease
     * percentage of the interest that gets as fee
     * @param _newPrincipalCut in range between 0-10%
     */
    function changePrincipalCut(
        uint256 _newPrincipalCut
    )
        external
        onlyMaster
    {
        require(
            _newPrincipalCut >= 0 &&
            _newPrincipalCut <= 10
        );

        principalCut = _newPrincipalCut;
    }

    /**
     * @notice ability for master to increase or decrease
     * percentage of the interest that gets as fee
     * @param _newPublicRewardPercent in range between 0-50%
     */
    function changePublicRewardPercent(
        uint256 _newPublicRewardPercent
    )
        external
        onlyMaster
    {
        require(
            _newPublicRewardPercent >= 0 &&
            _newPublicRewardPercent <= 50
        );

        publicRewardPercent = _newPublicRewardPercent;
    }

    function changePublicDebthCap(
        uint256 _newPublicDebthCap
    )
        external
        onlyMaster
    {
        publicDebthCap = _newPublicDebthCap;
    }

    function changeMaximumBufferStakeDuration(
        uint256 _newMaximumBufferStakeDuration
    )
        external
        onlyMaster
    {
        maximumBufferStakeDuration = _newMaximumBufferStakeDuration;
    }

    function changeBufferStakeCap(
        uint256 _newBufferStakeCap
    )
        external
        onlyMaster
    {
        bufferStakeCap = _newBufferStakeCap;
    }

    function changePenaltyThresholds(
        uint256 _newPenaltyThresholdA,
        uint256 _newPenaltyThresholdB,
        uint256 _newPenaltyA,
        uint256 _newPenaltyB
    )
        external
        onlyMaster
    {
        require(
            _newPenaltyThresholdB <= 50 &&
            _newPenaltyB <= 15 &&
            _newPenaltyA <= 25
        );

        require(
            _newPenaltyB <= _newPenaltyA &&
            _newPenaltyThresholdA <= _newPenaltyThresholdB
        );

        _newPenaltyThresholdA = _newPenaltyThresholdA;
        _newPenaltyThresholdB = _newPenaltyThresholdB;

        penaltyA = _newPenaltyA;
        penaltyB = _newPenaltyB;
    }

    /**
     * @notice ability for master to increase or decrease
     * coverage percent for taking profits from the contract
     * @param _newPayoutThreshold percent that needs to be covered
     */
    function changePayoutThreshold(
        uint256 _newPayoutThreshold
    )
        external
        onlyMaster
    {
        require(
            _newPayoutThreshold >= coverageThreshold
        );

        payoutThreshold = _newPayoutThreshold;
    }

    function changeCoverageThreshold(
        uint256 _newCoverageThreshold
    )
        external
        onlyMaster
    {
        coverageThreshold = _newCoverageThreshold;
    }

    function getCurrentBuffer() public view returns (uint256) {
        return WISE_CONTRACT.balanceOf(
            address(this)
        );
    }

    function getCoveredPercent() public view returns (uint256) {
		return totalCovers == 0 ? 100 : getCurrentBuffer() * 100 / totalCovers;
	}

    function getCoveredPercent(uint256 _amount) public view returns (uint256) {
		return totalCovers == 0 ? 100 : (getCurrentBuffer() - _amount) * 100 / totalCovers;
	}

    /**
     * @notice ability to check if stake opened
     * as insurance stake from contracts perspective
     * has now matured or not inside base layer
     * @param _stakeID percent regular stakeID
     */
    function checkMatureStake(
        bytes16 _stakeID
    )
        public
        view
        returns (bool)
    {
        return WISE_CONTRACT.checkMatureStake(
            address(this),
            _stakeID
        );
    }

    function canStake()
        external
        view
        returns (bool)
    {
        return getCoveredPercent() >= coverageThreshold;
    }

    /**
     * @notice ability to check if stake opened
     * as insurance stake from contracts perspective
     * has now matured or not inside base layer
     * @param _stakeOwner original owner
     * @param _stakeIndex index of the stake
     */
    function checkMatureStake(
        address _stakeOwner,
        uint256 _stakeIndex
    )
        public
        view
        returns (bool)
    {
        return WISE_CONTRACT.checkMatureStake(
            address(this),
            insuranceStakes[_stakeOwner][_stakeIndex].stakeID
        );
    }

    function _withdrawDeveloperFunds(
        uint256 _amount
    )
        internal
    {
        safeTransfer(
            wiseToken,
            insuranceMaster,
            _amount
        );

        emit DeveloperFundsRouted(
            _amount
        );
    }

    function withdrawOriginalFunds()
        external
        onlyMaster
    {
        uint256 amount = teamContribution;
        teamContribution = 0;
        safeTransfer(
            wiseToken,
            insuranceMaster,
            amount
        );
    }

    function fundTreasury(
        uint256 _amount
    )
        external
        onlyMaster
    {
        teamContribution =
        teamContribution + _amount;

        safeTransferFrom(
            wiseToken,
            insuranceMaster,
            address(this),
            _amount
        );
    }

    function saveTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
    {
        require(
            _tokenAddress != wiseToken
        );

        safeTransfer(
            _tokenAddress,
            insuranceMaster,
            _tokenAmount
        );
    }
}