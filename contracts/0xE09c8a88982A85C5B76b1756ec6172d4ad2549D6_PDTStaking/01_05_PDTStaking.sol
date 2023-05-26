pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title   PDT Staking
/// @notice  Contract that allows users to stake PDT
/// @author  JeffX
contract PDTStaking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// EVENTS ///

    /// @notice            Emitted if epoch 0 is pushed back
    /// @param newEndTime  New end time of epoch 0
    event Epoch0PushedBack(uint256 indexed newEndTime);

    /// @notice                     Emitted if epoch length is updated
    /// @param previousEpochLength  Previous length of epochs
    /// @param newEpochLength       New length of epochs
    event EpochLengthUpdated(uint256 indexed previousEpochLength, uint256 indexed newEpochLength);

    /// @notice                 Emitted upon address staking
    /// @param to               Address of who is receiving credit of stake
    /// @param newStakeAmount   New stake amount of `to`
    /// @param newWeightAmount  New weight amount of `to`
    event Staked(address to, uint256 indexed newStakeAmount, uint256 indexed newWeightAmount);

    /// @notice                Emitted upon user unstaking
    /// @param staker          Address of who is unstaking
    /// @param amountUnstaked  Amount `staker` unstaked
    event Unstaked(address staker, uint256 indexed amountUnstaked);

    /// @notice               Emitted upon staker claiming
    /// @param staker         Address of who claimed rewards
    /// @param epochsClaimed  Array of epochs claimed
    /// @param claimed        Amount claimed
    event Claimed(address staker, uint256[] indexed epochsClaimed, uint256 indexed claimed);

    /// ERRORS ///

    /// @notice Error for if epoch is invalid
    error InvalidEpoch();
    /// @notice Error for if user has already claimed up to current epoch
    error ClaimedUpToEpoch();
    /// @notice Error for if staking more than balance
    error MoreThanBalance();
    /// @notice Error for if unstaking when nothing is staked
    error NothingStaked();
    /// @notice Error for if not owner
    error NotOwner();
    /// @notice Error for if zero address
    error ZeroAddress();
    /// @notice Error for if after epoch 0
    error AfterEpoch0();

    /// STRUCTS ///

    /// @notice                    Details for epoch
    /// @param totalToDistribute   Total amount of token to distribute for epoch
    /// @param totalClaimed        Total amount of tokens claimed from epoch
    /// @param startTime           Timestamp epoch started
    /// @param endTime             Timestamp epoch ends
    /// @param weightAtEnd         Weight of staked tokens at end of epoch
    struct Epoch {
        uint256 totalToDistribute;
        uint256 totalClaimed;
        uint256 startTime;
        uint256 endTime;
        uint256 weightAtEnd;
    }

    /// @notice                         Stake details for user
    /// @param amountStaked             Amount user has staked
    /// @param lastInteraction          Last timestamp user interacted
    /// @param weightAtLastInteraction  Weight of stake at last interaction
    struct Stake {
        uint256 amountStaked;
        uint256 lastInteraction;
        uint256 weightAtLastInteraction;
    }

    /// STATE VARIABLES ///

    /// @notice Time to double weight
    uint256 public immutable timeToDouble;
    /// @notice Epoch id
    uint256 public epochId;
    /// @notice Length of epoch
    uint256 public epochLength;
    /// @notice Last interaction with contract
    uint256 public lastInteraction;
    /// @notice Total amount of PDT staked
    uint256 public totalStaked;

    /// @notice Total amount of weight within contract
    uint256 internal _contractWeight;
    /// @notice Amount of unclaimed rewards
    uint256 public unclaimedRewards;

    /// @notice Current epoch
    Epoch public currentEpoch;

    /// @notice Address of PDT
    address public immutable pdt;
    /// @notice Address of prime
    address public immutable prime;
    /// @notice Address of owner
    address public owner;

    /// @notice If user has claimed for certain epoch
    mapping(address => mapping(uint256 => bool)) public userClaimedEpoch;
    /// @notice User's weight at an epoch
    mapping(address => mapping(uint256 => uint256)) internal _userWeightAtEpoch;
    /// @notice Epoch user has last interacted
    mapping(address => uint256) public epochLeftOff;
    /// @notice Epoch user has last claimed
    mapping(address => uint256) public claimLeftOff;
    /// @notice Id to epoch details
    mapping(uint256 => Epoch) public epoch;
    /// @notice Stake details of user
    mapping(address => Stake) public stakeDetails;

    /// CONSTRUCTOR ///

    /// @param _timeToDouble       Time for weight to double
    /// @param _epochLength        Length of epoch
    /// @param _firstEpochStartIn  Amount of time first epoch will start in
    /// @param _pdt                PDT token address
    /// @param _prime              Address of reward token
    /// @param _owner              Address of owner
    constructor(
        uint256 _timeToDouble,
        uint256 _epochLength,
        uint256 _firstEpochStartIn,
        address _pdt,
        address _prime,
        address _owner
    ) {
        timeToDouble = _timeToDouble;
        epochLength = _epochLength;
        currentEpoch.endTime = block.timestamp + _firstEpochStartIn;
        epoch[0].endTime = block.timestamp + _firstEpochStartIn;
        currentEpoch.startTime = block.timestamp;
        epoch[0].startTime = block.timestamp;
        require(_pdt != address(0), "Zero Addresss: PDT");
        pdt = _pdt;
        require(_prime != address(0), "Zero Addresss: PRIME");
        prime = _prime;
        require(_owner != address(0), "Zero Addresss: Owner");
        owner = _owner;
    }

    /// OWNER FUNCTION ///

    /// @notice                 Push back epoch 0, used in case PRIME can not be transferred at current end time
    /// @param _timeToPushBack  Amount of time to push epoch 0 back by
    function pushBackEpoch0(uint256 _timeToPushBack) external {
        if (msg.sender != owner) revert NotOwner();
        if (epochId != 0) revert AfterEpoch0();

        currentEpoch.endTime += _timeToPushBack;
        epoch[0].endTime += _timeToPushBack;

        emit Epoch0PushedBack(currentEpoch.endTime);
    }

    /// @notice              Update epoch length of contract
    /// @param _epochLength  New epoch length
    function updateEpochLength(uint256 _epochLength) external {
        if (msg.sender != owner) revert NotOwner();
        uint256 previousEpochLength_ = epochLength;
        epochLength = _epochLength;

        emit EpochLengthUpdated(previousEpochLength_, _epochLength);
    }

    /// @notice           Changing owner of contract to `newOwner_`
    /// @param _newOwner  Address of who will be the new owner of contract
    function transferOwnership(address _newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        if (_newOwner == address(0)) revert ZeroAddress();
        owner = _newOwner;
    }

    /// PUBLIC FUNCTIONS ///

    /// @notice  Update epoch details if time
    function distribute() external nonReentrant {
        _distribute();
    }

    /// @notice         Stake PDT
    /// @param _to      Address that will receive credit for stake
    /// @param _amount  Amount of PDT to stake
    function stake(address _to, uint256 _amount) external nonReentrant {
        if (IERC20(pdt).balanceOf(msg.sender) < _amount) revert MoreThanBalance();
        IERC20(pdt).safeTransferFrom(msg.sender, address(this), _amount);

        _distribute();
        _setUserWeightAtEpoch(_to);
        _adjustContractWeight(true, _amount);

        totalStaked += _amount;

        Stake memory _stake = stakeDetails[_to];

        if (_stake.amountStaked > 0) {
            uint256 _additionalWeight = _weightIncreaseSinceInteraction(
                block.timestamp,
                _stake.lastInteraction,
                _stake.amountStaked
            );
            _stake.weightAtLastInteraction += (_additionalWeight + _amount);
        } else {
            _stake.weightAtLastInteraction = _amount;
        }

        _stake.amountStaked += _amount;
        _stake.lastInteraction = block.timestamp;

        stakeDetails[_to] = _stake;

        emit Staked(_to, _stake.amountStaked, _stake.weightAtLastInteraction);
    }

    /// @notice     Unstake PDT
    /// @param _to  Address that will receive PDT unstaked
    function unstake(address _to) external nonReentrant {
        Stake memory _stake = stakeDetails[msg.sender];

        uint256 _stakedAmount = _stake.amountStaked;

        if (_stakedAmount == 0) revert NothingStaked();

        _distribute();
        _setUserWeightAtEpoch(msg.sender);
        _adjustContractWeight(false, _stakedAmount);

        totalStaked -= _stakedAmount;

        _stake.amountStaked = 0;
        _stake.lastInteraction = block.timestamp;
        _stake.weightAtLastInteraction = 0;

        stakeDetails[msg.sender] = _stake;

        IERC20(pdt).safeTransfer(_to, _stakedAmount);

        emit Unstaked(msg.sender, _stakedAmount);
    }

    /// @notice     Claims all pending rewards tokens for msg.sender
    /// @param _to  Address to send rewards to
    function claim(address _to) external nonReentrant {
        _setUserWeightAtEpoch(msg.sender);

        uint256 _pendingRewards;
        uint256 _claimLeftOff = claimLeftOff[msg.sender];

        if (_claimLeftOff == epochId) revert ClaimedUpToEpoch();

        for (_claimLeftOff; _claimLeftOff < epochId; ++_claimLeftOff) {
            if (!userClaimedEpoch[msg.sender][_claimLeftOff] && contractWeightAtEpoch(_claimLeftOff) > 0) {
                userClaimedEpoch[msg.sender][_claimLeftOff] = true;
                Epoch memory _epoch = epoch[_claimLeftOff];
                uint256 _weightAtEpoch = _userWeightAtEpoch[msg.sender][_claimLeftOff];

                uint256 _epochRewards = (_epoch.totalToDistribute * _weightAtEpoch) /
                    contractWeightAtEpoch(_claimLeftOff);
                if (_epoch.totalClaimed + _epochRewards > _epoch.totalToDistribute) {
                    _epochRewards = _epoch.totalToDistribute - _epoch.totalClaimed;
                }

                _pendingRewards += _epochRewards;
                epoch[_claimLeftOff].totalClaimed += _epochRewards;
            }
        }

        claimLeftOff[msg.sender] = epochId;
        unclaimedRewards -= _pendingRewards;
        IERC20(prime).safeTransfer(_to, _pendingRewards);
    }

    /// VIEW FUNCTIONS ///

    /// @notice                  Returns current pending rewards for next epoch
    /// @return pendingRewards_  Current pending rewards for next epoch
    function pendingRewards() external view returns (uint256 pendingRewards_) {
        return IERC20(prime).balanceOf(address(this)) - unclaimedRewards;
    }

    /// @notice              Returns total weight `_user` has currently
    /// @param _user         Address to calculate `userWeight_` of
    /// @return userWeight_  Weight of `_user`
    function userTotalWeight(address _user) public view returns (uint256 userWeight_) {
        Stake memory _stake = stakeDetails[_user];
        uint256 _additionalWeight = _weightIncreaseSinceInteraction(
            block.timestamp,
            _stake.lastInteraction,
            _stake.amountStaked
        );
        userWeight_ = _additionalWeight + _stake.weightAtLastInteraction;
    }

    /// @notice                  Returns total weight of contract at `_epochId`
    /// @param _epochId          Epoch to return total weight of contract for
    /// @return contractWeight_  Weight of contract at end of `_epochId`
    function contractWeightAtEpoch(uint256 _epochId) public view returns (uint256 contractWeight_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        return epoch[_epochId].weightAtEnd;
    }

    /// @notice             Returns amount `_user` has claimable for `_epochId`
    /// @param _user        Address to see `claimable_` for `_epochId`
    /// @param _epochId     Id of epoch wanting to get `claimable_` for
    /// @return claimable_  Amount claimable
    function claimAmountForEpoch(address _user, uint256 _epochId) external view returns (uint256 claimable_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        if (userClaimedEpoch[_user][_epochId] || contractWeightAtEpoch(_epochId) == 0) return 0;

        Epoch memory _epoch = epoch[_epochId];

        claimable_ = (_epoch.totalToDistribute * userWeightAtEpoch(_user, _epochId)) / contractWeightAtEpoch(_epochId);
    }

    /// @notice              Returns total weight of `_user` at `_epochId`
    /// @param _user         Address to calculate `userWeight_` of for `_epochId`
    /// @param _epochId      Epoch id to calculate weight of `_user`
    /// @return userWeight_  Weight of `_user` for `_epochId`
    function userWeightAtEpoch(address _user, uint256 _epochId) public view returns (uint256 userWeight_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        uint256 _epochLeftOff = epochLeftOff[_user];
        Stake memory _stake = stakeDetails[_user];

        if (_epochLeftOff > _epochId) userWeight_ = _userWeightAtEpoch[_user][_epochId];
        else {
            Epoch memory _epoch = epoch[_epochId];
            if (_stake.amountStaked > 0) {
                uint256 _additionalWeight = _weightIncreaseSinceInteraction(
                    _epoch.endTime,
                    _stake.lastInteraction,
                    _stake.amountStaked
                );
                userWeight_ = _additionalWeight + _stake.weightAtLastInteraction;
            }
        }
    }

    /// @notice                  Returns current total weight of contract
    /// @return contractWeight_  Total current weight of contract
    function contractWeight() external view returns (uint256 contractWeight_) {
        uint256 _weightIncrease = _weightIncreaseSinceInteraction(block.timestamp, lastInteraction, totalStaked);
        contractWeight_ = _weightIncrease + _contractWeight;
    }

    /// INTERNAL VIEW FUNCTION ///

    /// @notice                    Returns additional weight since `_lastInteraction` at `_timestamp`
    /// @param _timestamp          Timestamp calculating on
    /// @param _lastInteraction    Last interaction time
    /// @param _baseAmount         Base amount of PDT to account for
    /// @return additionalWeight_  Additional weight since `_lastinteraction` at `_timestamp`
    function _weightIncreaseSinceInteraction(
        uint256 _timestamp,
        uint256 _lastInteraction,
        uint256 _baseAmount
    ) internal view returns (uint256 additionalWeight_) {
        uint256 _timePassed = _timestamp - _lastInteraction;
        uint256 _multiplierReceived = (1e18 * _timePassed) / timeToDouble;
        additionalWeight_ = (_baseAmount * _multiplierReceived) / 1e18;
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice         Adjust contract weight since last interaction
    /// @param _stake   Bool if `_amount` is being staked or withdrawn
    /// @param _amount  Amount of PDT being staked or withdrawn
    function _adjustContractWeight(bool _stake, uint256 _amount) internal {
        uint256 _weightReceivedSinceInteraction = _weightIncreaseSinceInteraction(
            block.timestamp,
            lastInteraction,
            totalStaked
        );
        _contractWeight += _weightReceivedSinceInteraction;

        if (_stake) {
            _contractWeight += _amount;
        } else {
            if (userTotalWeight(msg.sender) > _contractWeight) _contractWeight = 0;
            else _contractWeight -= userTotalWeight(msg.sender);
        }

        lastInteraction = block.timestamp;
    }

    /// @notice        Set epochs of `_user` that they left off on
    /// @param _user   Address of user being updated
    function _setUserWeightAtEpoch(address _user) internal {
        uint256 _epochLeftOff = epochLeftOff[_user];

        if (_epochLeftOff != epochId) {
            Stake memory _stake = stakeDetails[_user];
            if (_stake.amountStaked > 0) {
                for (_epochLeftOff; _epochLeftOff < epochId; ++_epochLeftOff) {
                    Epoch memory _epoch = epoch[_epochLeftOff];
                    uint256 _additionalWeight = _weightIncreaseSinceInteraction(
                        _epoch.endTime,
                        _stake.lastInteraction,
                        _stake.amountStaked
                    );
                    _userWeightAtEpoch[_user][_epochLeftOff] = _additionalWeight + _stake.weightAtLastInteraction;
                }
            }

            epochLeftOff[_user] = epochId;
        }
    }

    /// @notice  Update epoch details if time
    function _distribute() internal {
        if (block.timestamp >= currentEpoch.endTime) {
            uint256 _additionalWeight = _weightIncreaseSinceInteraction(
                currentEpoch.endTime,
                lastInteraction,
                totalStaked
            );
            epoch[epochId].weightAtEnd = _additionalWeight + _contractWeight;

            ++epochId;

            Epoch memory _epoch;
            _epoch.totalToDistribute = IERC20(prime).balanceOf(address(this)) - unclaimedRewards;
            _epoch.startTime = block.timestamp;
            _epoch.endTime = block.timestamp + epochLength;

            currentEpoch = _epoch;
            epoch[epochId] = _epoch;

            unclaimedRewards += _epoch.totalToDistribute;
        }
    }
}