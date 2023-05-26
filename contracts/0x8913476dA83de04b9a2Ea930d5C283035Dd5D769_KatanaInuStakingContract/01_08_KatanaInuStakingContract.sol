// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Ownable.sol";

/**
 * @notice
 * A stake struct is used to represent the way we store stakes,
 * A Stake will contain the users address, the duration (0 for imediate withdrawal or 1 / 2 / 3 years), the amount staked and a timestamp,
 * Since which is when the stake was made
 * _stakeCheckPointIndex: The index in the checkpoints array of the current stake
 */
struct Stake {
    uint256 _amount;
    uint256 _since;
    IERC20 _stakingToken;
    uint256 _stakaAmount;
    uint256 _estimatedReward;
    APY _estimatedAPY;
    uint256 _rewardStartDate; //This date will change as the amount staked increases
    bool _exists;
}

/***@notice Struct to store Staking Contract Parameters */
struct StakingContractParameters {
    uint256 _minimumStake;
    uint256 _maxSupply;
    uint256 _totalReward;
    IERC20 _stakingToken;
    uint256 _stakingDuration;
    uint256 _maximumStake;
    //staking starting parameters
    uint256 _minimumNumberStakeHoldersBeforeStart;
    uint256 _minimumTotalStakeBeforeStart;
    uint256 _startDate;
    uint256 _endDate;
    //vesting parameters
    Percentage _immediateRewardPercentage;
    uint256 _cliffDuration;
    Percentage _cliffRewardPercentage;
    uint256 _linearDuration;
}

struct Percentage {
    uint256 _percentage;
    uint256 _percentageBase;
}

struct StakingContractParametersUpdate {
    uint256 _minimumStake;
    uint256 _maxSupply;
    uint256 _totalReward;
    IERC20 _stakingToken;
    uint256 _stakingDuration;
    uint256 _maximumStake;
    uint256 _minimumNumberStakeHoldersBeforeStart;
    uint256 _minimumTotalStakeBeforeStart;
    Percentage _immediateRewardPercentage;
    uint256 _cliffDuration;
    Percentage _cliffRewardPercentage;
    uint256 _linearDuration;
}

struct APY {
    uint256 _apy;
    uint256 _base;
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 */
contract KatanaInuStakingContract is
    ERC20("STAKA Token", "STAKA"),
    Ownable,
    Pausable
{
    using SafeMath for uint256;

    ///////////// Events ///////////////////
    /**
     * @dev Emitted when a user stakes tokens
     */
    event Staked(
        address indexed stakeholder,
        uint256 amountStaked,
        IERC20 stakingToken,
        uint256 xKataAmount
    );

    /**
     * @dev Emitted when a user withdraw stake
     */
    event Withdrawn(
        address indexed stakeholder,
        uint256 amountStaked,
        uint256 amountReceived,
        IERC20 stakingToken
    );

    /**
     * @dev Emitted when a user withdraw stake
     */
    event EmergencyWithdraw(
        address indexed stakeholder,
        uint256 amountSKataBurned,
        uint256 amountReceived
    );

    ///////////////////////////////////////

    ///// Fields //////////
    /*** @notice Stakes by stakeholder address */
    mapping(address => Stake) public _stakeholdersMapping;
    uint256 _currentNumberOfStakeholders;

    /*** @notice Staking contract parameters */
    StakingContractParameters private _stakingParameters;

    /***@notice Total Kata Staked */
    uint256 private _totalKataStaked;

    /***@notice Total Kata rewards claimed */
    uint256 private _totalKataRewardsClaimed;

    bool private _stakingStarted;

    ////////////////////////////////////////

    constructor(address stakingTokenAddress) {
        _stakingParameters._stakingToken = IERC20(stakingTokenAddress);
        _stakingParameters._minimumNumberStakeHoldersBeforeStart = 1;
    }

    /***@notice Update Staking Parameters: _startDate can't be updated, it is automatically set when the first stake is created */
    function updateStakingParameters(
        StakingContractParametersUpdate calldata stakingParameters
    ) external onlyOwner {
        _stakingParameters._minimumStake = stakingParameters._minimumStake;
        _stakingParameters._maxSupply = stakingParameters._maxSupply;
        _stakingParameters._totalReward = stakingParameters._totalReward;
        _stakingParameters._stakingToken = IERC20(
            stakingParameters._stakingToken
        );
        _stakingParameters._stakingDuration = stakingParameters
            ._stakingDuration;
        if (_stakingStarted) {
            _stakingParameters._endDate =
                _stakingParameters._startDate +
                _stakingParameters._stakingDuration;
        }
        if (!_stakingStarted) {
            // No need to update these paraeter if the staking has already started
            _stakingParameters
                ._minimumNumberStakeHoldersBeforeStart = stakingParameters
                ._minimumNumberStakeHoldersBeforeStart;
            _stakingParameters._minimumTotalStakeBeforeStart = stakingParameters
                ._minimumTotalStakeBeforeStart;
            if (
                (_stakingParameters._minimumTotalStakeBeforeStart == 0 ||
                    _totalKataStaked >=
                    _stakingParameters._minimumTotalStakeBeforeStart) &&
                (_stakingParameters._minimumNumberStakeHoldersBeforeStart ==
                    0 ||
                    _currentNumberOfStakeholders >=
                    _stakingParameters._minimumNumberStakeHoldersBeforeStart)
            ) {
                _stakingStarted = true;
                _stakingParameters._startDate = block.timestamp;
                _stakingParameters._endDate =
                    _stakingParameters._startDate +
                    _stakingParameters._stakingDuration;
            }
        }
        _stakingParameters._maximumStake = stakingParameters._maximumStake;

        //Update reward schedule array
        _stakingParameters._immediateRewardPercentage = stakingParameters
            ._immediateRewardPercentage;
        _stakingParameters._cliffDuration = stakingParameters._cliffDuration;
        _stakingParameters._cliffRewardPercentage = stakingParameters
            ._cliffRewardPercentage;
        _stakingParameters._linearDuration = stakingParameters._linearDuration;
    }

    /***@notice Stake Kata coins in exchange for xKata coins to earn a share of the rewards */
    function stake(uint256 amount) external onlyUser whenNotPaused {
        //Check the amount is >= _minimumStake
        require(
            amount >= _stakingParameters._minimumStake,
            "Amount below the minimum stake"
        );
        //Check the amount is <= _maximumStake
        require(
            _stakingParameters._maximumStake == 0 ||
                amount <= _stakingParameters._maximumStake,
            "amount exceeds maximum stake"
        );
        //Check if the new stake will exceed the maximum supply for this pool
        require(
            (_totalKataStaked + amount) <= _stakingParameters._maxSupply,
            "You can not exceeed maximum supply for staking"
        );

        require(
            !_stakingStarted || block.timestamp < _stakingParameters._endDate,
            "The staking period has ended"
        );
        //Check if the totalReward have been already claimed, in theory this should always be true,
        //but added the extra check for additional safety
        require(
            _totalKataRewardsClaimed < _stakingParameters._totalReward,
            "All rewards have been distributed"
        );

        Stake memory newStake = createStake(amount);
        _totalKataStaked += amount;
        if (!_stakeholdersMapping[msg.sender]._exists) {
            _currentNumberOfStakeholders += 1;
        }
        //Check if the staking period did not end
        if (
            !_stakingStarted &&
            (_stakingParameters._minimumTotalStakeBeforeStart == 0 ||
                _totalKataStaked >=
                _stakingParameters._minimumTotalStakeBeforeStart) &&
            (_stakingParameters._minimumNumberStakeHoldersBeforeStart == 0 ||
                _currentNumberOfStakeholders >=
                _stakingParameters._minimumNumberStakeHoldersBeforeStart)
        ) {
            _stakingStarted = true;
            _stakingParameters._startDate = block.timestamp;
            _stakingParameters._endDate =
                _stakingParameters._startDate +
                _stakingParameters._stakingDuration;
        }
        //Transfer amount to contract (this)
        if (
            !_stakingParameters._stakingToken.transferFrom(
                msg.sender,
                address(this),
                amount
            )
        ) {
            revert("couldn 't transfer tokens from sender to contract");
        }

        _mint(msg.sender, newStake._stakaAmount);

        //Update stakeholders

        if (!_stakeholdersMapping[msg.sender]._exists) {
            _stakeholdersMapping[msg.sender] = newStake;
            _stakeholdersMapping[msg.sender]._exists = true;
        } else {
            _stakeholdersMapping[msg.sender]
                ._rewardStartDate = calculateNewRewardStartDate(
                _stakeholdersMapping[msg.sender],
                newStake
            );
            _stakeholdersMapping[msg.sender]._amount += newStake._amount;
            _stakeholdersMapping[msg.sender]._stakaAmount += newStake
                ._stakaAmount;
        }
        //Emit event
        emit Staked(
            msg.sender,
            amount,
            _stakingParameters._stakingToken,
            newStake._stakaAmount
        );
    }

    function calculateNewRewardStartDate(
        Stake memory existingStake,
        Stake memory newStake
    ) private pure returns (uint256) {
        uint256 multiplier = (
            existingStake._rewardStartDate.mul(existingStake._stakaAmount)
        ).add(newStake._rewardStartDate.mul(newStake._stakaAmount));
        uint256 divider = existingStake._stakaAmount.add(newStake._stakaAmount);
        return multiplier.div(divider);
    }

    /*** @notice Withdraw stake and get initial amount staked + share of the reward */
    function withdrawStake(uint256 amount) external onlyUser whenNotPaused {
        require(
            _stakeholdersMapping[msg.sender]._exists,
            "Can not find stake for sender"
        );
        require(
            _stakeholdersMapping[msg.sender]._amount >= amount,
            "Can not withdraw more than actual stake"
        );
        Stake memory stakeToWithdraw = _stakeholdersMapping[msg.sender];
        require(stakeToWithdraw._amount > 0, "Stake alreday withdrawn");
        //Reward proportional to amount withdrawn
        uint256 reward = (
            computeRewardForStake(block.timestamp, stakeToWithdraw, true).mul(
                amount
            )
        ).div(stakeToWithdraw._amount);
        //Check if there is enough reward tokens, this is to avoid paying rewards with other stakeholders stake
        uint256 currentRewardBalance = getRewardBalance();
        require(
            reward <= currentRewardBalance,
            "The contract does not have enough reward tokens"
        );
        uint256 totalAmoutToWithdraw = reward + amount;
        //Calculate nb STAKA to burn:
        uint256 nbStakaToBurn = (stakeToWithdraw._stakaAmount.mul(amount)).div(
            stakeToWithdraw._amount
        );

        _stakeholdersMapping[msg.sender]._amount -= amount;
        _stakeholdersMapping[msg.sender]._stakaAmount -= nbStakaToBurn;

        _totalKataStaked = _totalKataStaked - amount;
        _totalKataRewardsClaimed += reward;
        //Transfer amount to contract (this)
        if (
            !stakeToWithdraw._stakingToken.transfer(
                msg.sender,
                totalAmoutToWithdraw
            )
        ) {
            revert("couldn 't transfer tokens from sender to contract");
        }
        _burn(msg.sender, nbStakaToBurn);
        emit Withdrawn(
            msg.sender,
            stakeToWithdraw._amount,
            totalAmoutToWithdraw,
            stakeToWithdraw._stakingToken
        );
    }

    /***@notice withdraw all stakes of a given user without including rewards */
    function emergencyWithdraw(address stakeHolderAddress) external onlyOwner {
        require(
            _stakeholdersMapping[stakeHolderAddress]._exists,
            "Can not find stake for sender"
        );
        require(
            _stakeholdersMapping[stakeHolderAddress]._amount > 0,
            "Can not any stake for supplied address"
        );

        uint256 totalAmoutTowithdraw;
        uint256 totalSKataToBurn;
        totalAmoutTowithdraw = _stakeholdersMapping[stakeHolderAddress]._amount;
        totalSKataToBurn = _stakeholdersMapping[stakeHolderAddress]
            ._stakaAmount;
        if (
            !_stakeholdersMapping[stakeHolderAddress]._stakingToken.transfer(
                stakeHolderAddress,
                _stakeholdersMapping[stakeHolderAddress]._amount
            )
        ) {
            revert("couldn 't transfer tokens from sender to contract");
        }
        _stakeholdersMapping[stakeHolderAddress]._amount = 0;
        _stakeholdersMapping[stakeHolderAddress]._exists = false;
        _stakeholdersMapping[stakeHolderAddress]._stakaAmount = 0;

        _totalKataStaked = _totalKataStaked - totalAmoutTowithdraw;
        _burn(stakeHolderAddress, totalSKataToBurn);
        emit EmergencyWithdraw(
            stakeHolderAddress,
            totalSKataToBurn,
            totalAmoutTowithdraw
        );
    }

    /***@notice Get an estimate of the reward  */
    function getStakeReward(uint256 targetTime)
        external
        view
        onlyUser
        returns (uint256)
    {
        require(
            _stakeholdersMapping[msg.sender]._exists,
            "Can not find stake for sender"
        );
        Stake memory targetStake = _stakeholdersMapping[msg.sender];
        return computeRewardForStake(targetTime, targetStake, true);
    }

    /***@notice Get an estimate of the reward  */
    function getEstimationOfReward(uint256 targetTime, uint256 amountToStake)
        external
        view
        returns (uint256)
    {
        Stake memory targetStake = createStake(amountToStake);
        return computeRewardForStake(targetTime, targetStake, false);
    }

    function getAPY() external view returns (APY memory) {
        if (
            !_stakingStarted ||
            _stakingParameters._endDate == _stakingParameters._startDate ||
            _totalKataStaked == 0
        ) return APY(0, 1);

        uint256 targetTime = 365 days;
        if (
            _stakingParameters._immediateRewardPercentage._percentage == 0 &&
            _stakingParameters._cliffRewardPercentage._percentage == 0 &&
            _stakingParameters._cliffDuration == 0 &&
            _stakingParameters._linearDuration == 0
        ) {
            uint256 reward = _stakingParameters
                ._totalReward
                .mul(targetTime)
                .div(
                    _stakingParameters._endDate.sub(
                        _stakingParameters._startDate
                    )
                );
            return APY(reward.mul(100000).div(_totalKataStaked), 100000);
        }
        return getAPYWithVesting();
    }

    function getAPYWithVesting() private view returns (APY memory) {
        uint256 targetTime = 365 days;
        Stake memory syntheticStake = Stake(
            _totalKataStaked,
            block.timestamp,
            _stakingParameters._stakingToken,
            totalSupply(),
            0,
            APY(0, 1),
            block.timestamp,
            true
        );
        uint256 reward = computeRewardForStakeWithVesting(
            block.timestamp + targetTime,
            syntheticStake,
            true
        );
        return APY(reward.mul(100000).div(_totalKataStaked), 100000);
    }

    /***@notice Create a new stake by taking into account accrued rewards when estimating the number of xKata tokens in exchange for Kata tokens */
    function createStake(uint256 amount) private view returns (Stake memory) {
        uint256 xKataAmountToMint;
        uint256 currentTimeStanp = block.timestamp;
        if (_totalKataStaked == 0 || totalSupply() == 0) {
            xKataAmountToMint = amount;
        } else {
            //Add multiplication by 1 + time to maturity ratio
            uint256 multiplier = amount
                .mul(
                    _stakingParameters._endDate.sub(
                        _stakingParameters._startDate
                    )
                )
                .div(
                    _stakingParameters._endDate.add(currentTimeStanp).sub(
                        2 * _stakingParameters._startDate
                    )
                );
            xKataAmountToMint = multiplier.mul(totalSupply()).div(
                _totalKataStaked
            );
        }
        return
            Stake(
                amount,
                currentTimeStanp,
                _stakingParameters._stakingToken,
                xKataAmountToMint,
                0,
                APY(0, 1),
                currentTimeStanp,
                true
            );
    }

    /*** Stats functions */

    /***@notice returns the amount of Kata tokens available for rewards */
    function getRewardBalance() public view returns (uint256) {
        uint256 stakingTokenBalance = _stakingParameters
            ._stakingToken
            .balanceOf(address(this));
        uint256 rewardBalance = stakingTokenBalance.sub(_totalKataStaked);
        return rewardBalance;
    }

    /***@notice returns the amount of Kata tokens withdrawn as rewards */
    function getTotalRewardsClaimed() public view returns (uint256) {
        return _totalKataRewardsClaimed;
    }

    function getRequiredRewardAmountForPerdiod(uint256 endPeriod)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return caluclateRequiredRewardAmountForPerdiod(endPeriod);
    }

    function getRequiredRewardAmount() external view returns (uint256) {
        return caluclateRequiredRewardAmountForPerdiod(block.timestamp);
    }

    ///////////////////////////////////////////////////////////////

    function caluclateRequiredRewardAmountForPerdiod(uint256 endPeriod)
        private
        view
        returns (uint256)
    {
        if (
            !_stakingStarted ||
            _stakingParameters._endDate == _stakingParameters._startDate ||
            _totalKataStaked == 0
        ) return 0;
        uint256 requiredReward = _stakingParameters
            ._totalReward
            .mul(endPeriod.sub(_stakingParameters._startDate))
            .div(_stakingParameters._endDate.sub(_stakingParameters._startDate))
            .sub(_totalKataRewardsClaimed);
        return requiredReward;
    }

    /***@notice Calculate the reward for a give stake if withdrawn at 'targetTime' */
    function computeRewardForStake(
        uint256 targetTime,
        Stake memory targetStake,
        bool existingStake
    ) private view returns (uint256) {
        if (
            _stakingParameters._immediateRewardPercentage._percentage == 0 &&
            _stakingParameters._cliffRewardPercentage._percentage == 0 &&
            _stakingParameters._cliffDuration == 0 &&
            _stakingParameters._linearDuration == 0
        ) {
            return
                computeReward(
                    _stakingParameters._totalReward,
                    targetTime,
                    targetStake._stakaAmount,
                    targetStake._rewardStartDate,
                    existingStake
                );
        }
        return
            computeRewardForStakeWithVesting(
                targetTime,
                targetStake,
                existingStake
            );
    }

    function computeRewardForStakeWithVesting(
        uint256 targetTime,
        Stake memory targetStake,
        bool existingStake
    ) private view returns (uint256) {
        uint256 accumulatedReward;
        uint256 currentStartTime = targetStake._rewardStartDate;
        uint256 currentTotalRewardAmount = (
            _stakingParameters._totalReward.mul(
                _stakingParameters._immediateRewardPercentage._percentage
            )
        ).div(_stakingParameters._immediateRewardPercentage._percentageBase);

        if (
            (currentStartTime + _stakingParameters._cliffDuration) >= targetTime
        ) {
            return
                computeReward(
                    currentTotalRewardAmount,
                    targetTime,
                    targetStake._stakaAmount,
                    currentStartTime,
                    existingStake
                );
        }

        accumulatedReward += computeReward(
            currentTotalRewardAmount,
            currentStartTime + _stakingParameters._cliffDuration,
            targetStake._stakaAmount,
            currentStartTime,
            existingStake
        );

        currentStartTime = currentStartTime + _stakingParameters._cliffDuration;
        currentTotalRewardAmount += (
            _stakingParameters._totalReward.mul(
                _stakingParameters._cliffRewardPercentage._percentage
            )
        ).div(_stakingParameters._cliffRewardPercentage._percentageBase);

        if (
            _stakingParameters._linearDuration == 0 ||
            (currentStartTime + _stakingParameters._linearDuration) <=
            targetTime
        ) {
            // 100% percent of the reward vested
            currentTotalRewardAmount = _stakingParameters._totalReward;

            return (
                accumulatedReward.add(
                    computeReward(
                        currentTotalRewardAmount,
                        targetTime,
                        targetStake._stakaAmount,
                        currentStartTime,
                        existingStake
                    )
                )
            );
        }
        // immediate + cliff + linear proportion of the reward
        currentTotalRewardAmount += (
            _stakingParameters._totalReward.sub(currentTotalRewardAmount)
        ).mul(targetTime - currentStartTime).div(
                _stakingParameters._linearDuration
            );
        accumulatedReward += computeReward(
            currentTotalRewardAmount,
            targetTime,
            targetStake._stakaAmount,
            currentStartTime,
            existingStake
        );
        return accumulatedReward;
    }

    /***@notice Calculate the reward for a give stake if withdrawn at 'targetTime' */
    function computeReward(
        uint256 applicableReward,
        uint256 targetTime,
        uint256 stakaAmount,
        uint256 rewardStartDate,
        bool existingStake
    ) private view returns (uint256) {
        uint256 mulltiplier = stakaAmount
            .mul(applicableReward)
            .mul(targetTime.sub(rewardStartDate))
            .div(
                _stakingParameters._endDate.sub(_stakingParameters._startDate)
            );

        uint256 divider = existingStake
            ? totalSupply()
            : totalSupply().add(stakaAmount);
        return mulltiplier.div(divider);
    }

    /**
     * @notice
     * Update Staking Token
     */
    function setStakingToken(address stakingTokenAddress) external onlyOwner {
        _stakingParameters._stakingToken = IERC20(stakingTokenAddress);
    }

    /*** @notice Withdraw reward */
    function withdrawFromReward(uint256 amount) external onlyOwner {
        //Check if there is enough reward tokens, this is to avoid paying rewards with other stakeholders stake
        require(
            amount <= getRewardBalance(),
            "The contract does not have enough reward tokens"
        );
        //Transfer amount to contract (this)
        if (!_stakingParameters._stakingToken.transfer(msg.sender, amount)) {
            revert("couldn 't transfer tokens from sender to contract");
        }
    }

    /**
     * @notice
     * Return the total amount staked
     */
    function getTotalStaked() external view returns (uint256) {
        return _totalKataStaked;
    }

    /**
     * @notice
     * Return the value of the penalty for early exit
     */
    function getContractParameters()
        external
        view
        returns (StakingContractParameters memory)
    {
        return _stakingParameters;
    }

    /**
     * @notice
     * Return stakes for msg.sender
     */
    function getStake() external view returns (Stake memory) {
        Stake memory currentStake = _stakeholdersMapping[msg.sender];
        if (!currentStake._exists) {
            // Return empty stake
            return
                Stake(
                    0,
                    0,
                    _stakingParameters._stakingToken,
                    0,
                    0,
                    APY(0, 1),
                    0,
                    false
                );
        }
        if (_stakingStarted) {
            currentStake._estimatedReward = computeRewardForStake(
                block.timestamp,
                currentStake,
                true
            );
            currentStake._estimatedAPY = APY(
                computeRewardForStake(
                    currentStake._rewardStartDate + 365 days,
                    currentStake,
                    true
                ).mul(100000).div(currentStake._amount),
                100000
            );
        }
        return currentStake;
    }

    function shouldStartContract(
        uint256 newTotalKataStaked,
        uint256 newCurrentNumberOfStakeHolders
    ) private view returns (bool) {
        if (
            _stakingParameters._minimumTotalStakeBeforeStart > 0 &&
            newTotalKataStaked <
            _stakingParameters._minimumTotalStakeBeforeStart
        ) {
            return false;
        }
        if (
            _stakingParameters._minimumNumberStakeHoldersBeforeStart > 0 &&
            newCurrentNumberOfStakeHolders <
            _stakingParameters._minimumNumberStakeHoldersBeforeStart
        ) {
            return false;
        }
        return true;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0))
            //Nothing to do when _mint is called
            return;
        if (to == address(0))
            //Nothing to do when _burn is called
            return;

        Stake memory fromStake = _stakeholdersMapping[from];
        uint256 amountOfKataToTransfer = (
            _stakeholdersMapping[from]._amount.mul(amount)
        ).div(_stakeholdersMapping[from]._stakaAmount);

        fromStake._exists = true;
        fromStake._stakaAmount = amount;
        fromStake._amount = amountOfKataToTransfer;
        if (!_stakeholdersMapping[to]._exists) {
            _stakeholdersMapping[to] = fromStake;
            _stakeholdersMapping[from]._stakaAmount -= amount;
            _stakeholdersMapping[from]._amount -= amountOfKataToTransfer;
        } else {
            _stakeholdersMapping[to]
                ._rewardStartDate = calculateNewRewardStartDate(
                _stakeholdersMapping[to],
                fromStake
            );
            _stakeholdersMapping[to]._stakaAmount += amount;
            _stakeholdersMapping[to]._amount += amountOfKataToTransfer;
            _stakeholdersMapping[from]._stakaAmount -= amount;
            _stakeholdersMapping[from]._amount -= amountOfKataToTransfer;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * onlyUser
     * @dev guard contracts from calling method
     **/
    modifier onlyUser() {
        require(msg.sender == tx.origin);
        _;
    }
}