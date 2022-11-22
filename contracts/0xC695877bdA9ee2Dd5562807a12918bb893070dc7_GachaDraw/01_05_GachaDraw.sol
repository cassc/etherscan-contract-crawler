// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnimeMetaverseTicket.sol";
import "./IAnimeMetaverseReward.sol";

/// @notice Should have sufficient reward for gacha activity
/// @dev Use this custom error on revert function whenever there is insufficiant reward
error InsufficientReward();

/// @notice Should provide a valid activity Id for any gacha activity
/// @dev Use this custom error on revert function whenever invalid activity Id
error InvalidActivity();

/// @notice Should provide a valid activity type either FREE_ACTIVITY_TYPE or PREMIUM_ACTIVITY_TYPE
/// @dev Use this custom error on revert function whenever the activity type is not valid
error InvalidActivityType();

/// @notice Should draw ticket for a active gacha activity
/// @dev Use this custom error on revert function the activity is not active
error InactiveActivity();

/// @notice Should draw ticket for a active gacha activity
/// @dev Use this custom error on revert function draw is out of event timestamp
error ActivityTimestampError();

/// @notice Should input valid address other than 0x0
/// @dev Use this custom error on revert function whenever validating address
error InvalidAddress();

/// @notice Should provide valid timestamp
/// @dev Use this custom error on revert function whenever there is invalid timestamp
error InvalidTimestamp();

/// @notice Should provide valid amount of ticket
/// @dev Use this custom error on revert function whenever there is invalid amount of ticket
error InsufficientTicket();

/// @notice Should provide valid array length as input
/// @dev Use this custom error on revert function whenever the array length does not match
error InvalidInputLength();

/// @notice Should provide valid input
/// @dev Use this custom error with message on revert function whenever the input is not valid
error InvalidInput(string message);

contract GachaDraw is Ownable {
    /// @notice Emit when a new activity is created
    /// @dev Emeits in createActivity method
    /// @param _activityId New activity Id
    /// @param _startTimestamp Activity starting timestamp
    /// @param _endTimestamp Activity end timestamp
    /// @param _rewardTokenSupply Maximumreward supply for this activity
    event ActivityCreated(
        uint256 _activityId,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] _rewardTokenSupply
    );

    /// @notice Emit a gacha draw is completed
    /// @dev Emeits in drawTicket function
    /// @param _activityId Gacha activity Id
    /// @param _walletAddress Activity event Id
    /// @param _ticketType Used ticket type
    /// @param _ticketAmount Amount of ticket used for draw
    /// @param _drawIndex Gacha draw index
    event DrawCompleted(
        uint256 _activityId,
        address _walletAddress,
        uint256 _ticketType,
        uint256 _ticketAmount,
        uint256 _drawIndex
    );

    modifier validActivity(uint256 _activityId) {
        if (_activityId > totalActivities || _activityId < 1) {
            revert InvalidActivity();
        }
        _;
    }

    modifier validActivityType(uint256 _activitType) {
        if (
            !(_activitType == FREE_ACTIVITY_TYPE ||
                _activitType == PREMIUM_ACTIVITY_TYPE)
        ) {
            revert InvalidActivityType();
        }
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier validTimestamp(uint256 _startTimestamp, uint256 _endTimestamp) {
        if (_endTimestamp <= _startTimestamp) {
            revert InvalidTimestamp();
        }
        _;
    }

    uint256 public constant FREE_ACTIVITY_TYPE = 1;
    uint256 public constant PREMIUM_ACTIVITY_TYPE = 2;

    /// @dev Ticket smart contract instance
    IAnimeMetaverseTicket public TicketContract;
    /// @dev Reward smart contract instance
    IAnimeMetaverseReward public RewardContract;

    /// @dev Activity structure for keeping track all activity information
    struct Activity {
        uint256 activityId;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 activityType;
        bool isActive;
        uint256[] rewardTokenIds;
        uint256[] totalGivenRewardSupply;
        uint256[] maximumRewardSupply;
        uint256 remainingRewardSupply;
    }

    /// @dev Mapping to store activity information
    mapping(uint256 => Activity) public activities;

    uint256 public totalActivities;
    uint256 public totalRewardWon;
    uint256 public totalCompleteDraws;
    uint256 public maxRewardTokenId = 18;

    /// @dev Create gacha draw contract instance
    /// @param _ticketContractAddress Ticket contract address
    /// @param _rewardContractAddress Reward contract address
    constructor(address _ticketContractAddress, address _rewardContractAddress)
    {
        TicketContract = IAnimeMetaverseTicket(_ticketContractAddress);
        RewardContract = IAnimeMetaverseReward(_rewardContractAddress);
    }

    /// @notice Owner only method for updating ticket token contract
    /// @dev Update ticket contract address
    /// @param _ticketContractAddress New ticket contract address
    function setTicketContract(address _ticketContractAddress)
        external
        onlyOwner
        validAddress(_ticketContractAddress)
    {
        TicketContract = IAnimeMetaverseTicket(_ticketContractAddress);
    }

    /// @notice Owner only method for updating max Id range for reward token
    /// @dev Update max reward tokenId range
    /// @param _maxRewardTokenId New range for reward tokenId
    function setMaxRewardTokenId(uint256 _maxRewardTokenId) external onlyOwner {
        maxRewardTokenId = _maxRewardTokenId;
    }

    /// @notice Owner only method for updating reward token contract
    /// @dev Update reward contract address
    /// @param _rewardContractAddress New reward contract address
    function setRewardContract(address _rewardContractAddress)
        external
        onlyOwner
        validAddress(_rewardContractAddress)
    {
        RewardContract = IAnimeMetaverseReward(_rewardContractAddress);
    }

    /// @notice Owner only method for creating an activity for gacha draw
    /// @dev Create a new activity
    /// @param _startTimestamp Activity starting time
    /// @param _endTimestamp Activity ending time
    /// @param _activityType Activity type: free or premium
    /// @param _rewardTokenIds tokenIds for giving reward
    /// @param _maxRewardSupply Max supply for each tokenId
    function createActivity(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _activityType,
        uint256[] calldata _rewardTokenIds,
        uint256[] calldata _maxRewardSupply
    )
        external
        onlyOwner
        validActivityType(_activityType)
        validTimestamp(_startTimestamp, _endTimestamp)
    {
        if (_rewardTokenIds.length != _maxRewardSupply.length) {
            revert InvalidInputLength();
        }

        uint256 remainingRewardSupply;
        for (uint256 index = 0; index < _rewardTokenIds.length; index++) {
            remainingRewardSupply =
                remainingRewardSupply +
                _maxRewardSupply[index];
            if (
                _rewardTokenIds[index] > maxRewardTokenId ||
                _rewardTokenIds[index] < 1
            ) {
                revert InvalidInput("Invalid reward tokenId.");
            }
        }

        /// @dev validate supply input
        if (remainingRewardSupply < 1) {
            revert InsufficientReward();
        }

        totalActivities++;

        /// @dev Store activity information in map
        activities[totalActivities] = Activity({
            activityId: totalActivities,
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp,
            activityType: _activityType,
            isActive: true,
            totalGivenRewardSupply: new uint256[](_maxRewardSupply.length),
            maximumRewardSupply: _maxRewardSupply,
            remainingRewardSupply: remainingRewardSupply,
            rewardTokenIds: _rewardTokenIds
        });

        /// @dev emit event after creating activity
        emit ActivityCreated(
            totalActivities,
            _startTimestamp,
            _endTimestamp,
            _maxRewardSupply
        );
    }

    /// @notice Owner only method for updating activity status
    /// @dev Sets activity as active or inactive
    /// @param _activityId Activity Id for which the status will be updated
    /// @param _flag Activity status flag
    function setActivityStatus(uint256 _activityId, bool _flag)
        external
        onlyOwner
        validActivity(_activityId)
    {
        activities[_activityId].isActive = _flag;
    }

    /// @notice Owner only method for updating activity timestamp
    /// @dev Update new timestamp
    /// @param _activityId Activity Id for which the timestamp will be updated
    /// @param _startTimestamp New start timestamp
    /// @param _endTimestamp New end timestamp
    function setActivityTimestamp(
        uint256 _activityId,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    )
        external
        onlyOwner
        validActivity(_activityId)
        validTimestamp(_startTimestamp, _endTimestamp)
    {
        activities[_activityId].startTimestamp = _startTimestamp;
        activities[_activityId].endTimestamp = _endTimestamp;
    }

    /// @notice Owner only method for updating max supply for an activity
    /// @dev Update activity reward supply
    /// @param _activityId Selected activity
    /// @param _maxRewardSupply Max supply for each tokenId
    function updateMaximumRewardSupply(
        uint256 _activityId,
        uint256[] calldata _maxRewardSupply
    ) external onlyOwner validActivity(_activityId) {
        if (
            _maxRewardSupply.length !=
            activities[_activityId].rewardTokenIds.length
        ) {
            revert InvalidInputLength();
        }

        uint256 newMaxRewardSupply;
        uint256 totalSupplyInCirculation;

        for (uint256 index = 0; index < _maxRewardSupply.length; index++) {
            if (
                _maxRewardSupply[index] <
                activities[_activityId].totalGivenRewardSupply[index]
            ) {
                revert InvalidInput(
                    "Maximum Supply Can Not Be Lower Than Total Supply."
                );
            }

            totalSupplyInCirculation += activities[_activityId]
                .totalGivenRewardSupply[index];
            newMaxRewardSupply = newMaxRewardSupply + _maxRewardSupply[index];
            activities[_activityId].maximumRewardSupply[
                index
            ] = _maxRewardSupply[index];
        }

        activities[_activityId].remainingRewardSupply =
            newMaxRewardSupply -
            totalSupplyInCirculation;
    }

    /// @notice External function for gacha draw. It burns tickets and provide rewards
    /// @dev Randomly choice reward tickets, burn the gacha tickets and then mint the reward for user
    /// @param _activityId Id of the activity for which users want to draw tickets
    /// @param _ticketAmount Id of the activity for getting total reward token supply
    function drawTicket(uint256 _activityId, uint256 _ticketAmount)
        external
        validActivity(_activityId)
    {
        /// @notice Reverts if the activity is not active
        /// @dev Validates if the activity is active or not
        if (!activities[_activityId].isActive) {
            revert InactiveActivity();
        }

        /// @notice Reverts if current timestamp is out of range of the activity start and end timestamp
        /// @dev Validates if the current timestamp is within activity start and end timestamp
        if (
            block.timestamp < activities[_activityId].startTimestamp ||
            block.timestamp > activities[_activityId].endTimestamp
        ) {
            revert ActivityTimestampError();
        }

        if (_ticketAmount < 1) {
            revert InsufficientTicket();
        }

        /// @notice Reverts if the rewards supply is not enough
        /// @dev Validates if there are enough tickets or not
        if (activities[_activityId].remainingRewardSupply < _ticketAmount) {
            revert InsufficientReward();
        }

        /// @dev Burns the tickets
        TicketContract.burn(
            activities[_activityId].activityType,
            msg.sender,
            _ticketAmount
        );
        unchecked {
            totalCompleteDraws++;
        }

        /// @dev For each tickets burns the tickets and mint a random reward
        for (
            uint256 ticketAmountIndex = 0;
            ticketAmountIndex < _ticketAmount;
            ticketAmountIndex = _uncheckedIncOne(ticketAmountIndex)
        ) {
            uint256 randomIndex = getRandomNumber(
                activities[_activityId].remainingRewardSupply
            );

            uint256 selectedTokenId;
            uint256 indexCount;

            /// @dev Find out the choosen reward time and increase it's supply
            for (
                uint256 rewardTokenIndex = 0;
                rewardTokenIndex <
                activities[_activityId].rewardTokenIds.length;
                rewardTokenIndex = _uncheckedIncOne(rewardTokenIndex)
            ) {
                uint256 toBeMintedId = activities[_activityId]
                    .maximumRewardSupply[rewardTokenIndex] -
                    activities[_activityId].totalGivenRewardSupply[
                        rewardTokenIndex
                    ];
                indexCount = _uncheckedIncDelta(indexCount, toBeMintedId);
                if (toBeMintedId > 0 && indexCount >= randomIndex) {
                    selectedTokenId = activities[_activityId].rewardTokenIds[
                        rewardTokenIndex
                    ];
                    activities[_activityId].totalGivenRewardSupply[rewardTokenIndex] = 
                    _uncheckedIncOne(
                        activities[_activityId].totalGivenRewardSupply[rewardTokenIndex]
                    );
                    break;
                }
            }

            ///@dev Mints one randomly choosen reward ticket
            RewardContract.mint(
                ticketAmountIndex + 1,
                totalCompleteDraws,
                _activityId,
                msg.sender,
                selectedTokenId,
                1,
                ""
            );

            unchecked {
                activities[_activityId].remainingRewardSupply--;
                totalRewardWon++;
            }
        }

        emit DrawCompleted(
            _activityId,
            msg.sender,
            activities[_activityId].activityType,
            _ticketAmount,
            totalCompleteDraws
        );
    }

    /// @notice Internal function for generating random number
    /// @dev Generate a randmom number where, 0 <= randomnumber < _moduler
    /// @param _moduler The range for generating random number
    function getRandomNumber(uint256 _moduler) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        totalRewardWon
                )
            )
        );

        return (seed - ((seed / _moduler) * _moduler));
    }

    /// @notice getTotalRewardSupply is a external view method which has no gas fee
    /// @dev Provides the saved total reward token supply for any activity
    /// @param _activityId Id of the activity for getting total reward token supply
    function getTotalRewardSupply(uint256 _activityId)
        external
        view
        returns (uint256[] memory)
    {
        return activities[_activityId].totalGivenRewardSupply;
    }

    /// @notice getMaximumRewardSupply is a external view method which has no gas fee
    /// @dev Provides the saved maximum reward token supply for any activity
    /// @param _activityId Id of the activity for getting maximum reward token supply
    function getMaximumRewardSupply(uint256 _activityId)
        external
        view
        returns (uint256[] memory)
    {
        return activities[_activityId].maximumRewardSupply;
    }

    /// @notice getRewardTokenIds is a external view method which has no gas fee
    /// @dev Provides the saved reward token Ids for any activity
    /// @param _activityId Id of the activity for getting reward tokenIds
    function getRewardTokenIds(uint256 _activityId)
        external
        view
        returns (uint256[] memory)
    {
        return activities[_activityId].rewardTokenIds;
    }

    /// @dev Unchecked increment function, just to reduce gas usage
    /// @notice This value can not be greater than 36000 for reward count because we will have maximum 36000 rewards
    /// @notice For reward tokenId count this value can not be greater that 18
    /// @param val value to be incremented by 1, should not overflow 2**256 - 1
    /// @return incremented value
    function _uncheckedIncOne(uint256 val) internal pure returns (uint256) {
        return _uncheckedIncDelta(val, 1);
    }

    /// @dev Unchecked increment function, just to reduce gas usage
    /// @notice This value can not be greater than 36000 for reward count because we will have maximum 36000 rewards
    /// @notice For reward tokenId count this value can not be greater that 18
    /// @param val value to be incremented by delta, ensure that it should not overflow 2**256 - 1 before calling this function
    /// @return incremented value
    function _uncheckedIncDelta(uint256 val, uint256 delta)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return val + delta;
        }
    }
}