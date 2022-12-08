// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StakingPool.sol";

import "../../tier-calculator/interfaces/ITierCalculator.sol";

contract StakingPenaltyPool is StakingPool {

    struct Penalty {
        uint256 duration;
        uint256 penaltyBP;
    }

    Penalty[] public allPenalties;

    event ChargedPenalty(uint256 penaltyAmount, uint256 penaltyBP);

    function __StakingPenaltyPool_init(
        IERC20Upgradeable _stakingToken,
        IERC20Upgradeable _poolToken,
        uint256 _startTime,
        uint256 _finishTime,
        uint256 _poolTokenAmount,
        bool _hasWhitelisting,
        IStakeMaster _stakeMaster,
        uint256 _depositFeeBP,
        address _feeTo
    ) public initializer {
        StakingPool.__StakingPool_init(
            _stakingToken,
            _poolToken,
            _startTime,
            _finishTime,
            _poolTokenAmount,
            _hasWhitelisting,
            _stakeMaster,
            _depositFeeBP,
            _feeTo
        );

        allPenalties.push(Penalty(_finishTime - _startTime, 3000));
    }

    function getPenaltyBP(uint256 _startTime) public view returns (uint256) {
        uint256 duration = now >= startTime ? now.sub(_startTime) : 0;

        uint256 len = allPenalties.length;
        for (uint256 i = 0; i < len; i++) {
            if (duration < allPenalties[i].duration) {
                return allPenalties[i].penaltyBP;
            }
        }

        return 0;
    }

    function getPenalty(uint256 _claimAmount) public view returns (uint256 penaltyAmount, uint256 penaltyBP) {
        penaltyBP = getPenaltyBP(startTime);
        penaltyAmount = _claimAmount.mul(penaltyBP).div(MAX_BPS);
    }

    function stakeTokens(uint256 _amountToStake) public override {
        super.stakeTokens(_amountToStake);

        if(stakeMaster.tierCalculator() != address(0)) {
            stakeMaster.resetStartOnce(msg.sender);
        }
    }

    function stakeFromLocker(uint256 _amountToStake) public override {
        super.stakeFromLocker(_amountToStake);

        if(stakeMaster.tierCalculator() != address(0)) {
            stakeMaster.resetStartOnce(tx.origin);
        }
    }

    // Leave the pool. Claim back your tokens.
    // Unlocks the staked + gained tokens and burns pool shares
    function withdrawStake(uint256 _amount) public override {
        (uint256 penaltyAmount, uint256 penaltyBP) = getPenalty(_amount);

        // IMPORTANT: first step – charge penalty, second step – withdraw without penalty
        _chargePenalty(msg.sender, penaltyAmount, penaltyBP);

        // update reward debt states after the penalty has been charged
        if (penaltyAmount > 0) {
            UserInfo storage user = userInfo[msg.sender];

            allRewardDebt = allRewardDebt.sub(user.rewardDebt);
            user.rewardDebt = user.amount.mul(accTokensPerShare).div(1e18);
            allRewardDebt = allRewardDebt.add(user.rewardDebt);
        }

        super.withdrawStake(_amount.sub(penaltyAmount));
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public override {
        (uint256 penaltyAmount, uint256 penaltyBP) = getPenalty(userInfo[msg.sender].amount);

        // IMPORTANT: first step – charge penalty, second step – emergencyWithdraw
        _chargePenalty(msg.sender, penaltyAmount, penaltyBP);
        super.emergencyWithdraw();
    }

    function updatePenalty(uint256 _index, uint256 _duration, uint256 _penaltyBP) external onlyOwnerOrAdmin {
        require(_index < allPenalties.length, "Incorrect index");
        require(_penaltyBP <= MAX_BPS, "Invalid penalty BP");

        Penalty storage item = allPenalties[_index];
        item.duration = _duration;
        item.penaltyBP = _penaltyBP;
    }

    function _chargePenalty(address _user, uint256 _penaltyAmount, uint256 _penaltyBP) internal {
        if (_penaltyAmount > 0) {
            userInfo[_user].amount = userInfo[_user].amount.sub(_penaltyAmount);
            allStakedAmount = allStakedAmount.sub(_penaltyAmount);
            stakingToken.safeTransfer(feeTo, _penaltyAmount);
        }

        emit ChargedPenalty(_penaltyAmount, _penaltyBP);
    }
}