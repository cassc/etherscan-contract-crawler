// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import 'sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol';
import { MessageBusSender} from 'sgn-v2-contracts/contracts/message/messagebus/MessageBusSender.sol';

import './interfaces/IIFRetrievableStakeWeight.sol';
import './interfaces/IIFBridgableStakeWeight.sol';

// IFAllocationMaster is responsible for persisting all launchpad state between project token sales
// in order for the sales to have clean, self-enclosed, one-time-use states.

// IFAllocationMaster is the master of allocations. He can remember everything and he is a smart guy.
contract IFAllocationMaster is
    Ownable,
    ReentrancyGuard,
    IIFRetrievableStakeWeight,
    IIFBridgableStakeWeight
{
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // CONSTANTS

    // number of decimals of rollover factors
    uint64 constant ROLLOVER_FACTOR_DECIMALS = 10**18;

    // STRUCTS

    // Celer Multichain Integration
    address public immutable messageBus;

    // A checkpoint for marking stake info at a given block
    struct UserCheckpoint {
        // timestamp number of checkpoint
        uint80 timestamp;
        // amount staked at checkpoint
        uint104 staked;
        // amount of stake weight at checkpoint
        uint192 stakeWeight;
        // number of finished sales at time of checkpoint
        uint24 numFinishedSales;
    }

    // A checkpoint for marking stake info at a given block
    struct TrackCheckpoint {
        // timestamp number of checkpoint
        uint80 timestamp;
        // amount staked at checkpoint
        uint104 totalStaked;
        // amount of stake weight at checkpoint
        uint192 totalStakeWeight;
        // number of finished sales at time of checkpoint
        uint24 numFinishedSales;
    }

    // Info of each track. These parameters cannot be changed.
    struct TrackInfo {
        // name of track
        string name;
        // token to stake (e.g., IDIA)
        ERC20 stakeToken;
        // weight accrual rate for this track (stake weight increase per timestamp per stake token)
        uint24 weightAccrualRate;
        // amount rolled over when finished sale counter increases (with decimals == ROLLOVER_FACTOR_DECIMALS)
        // e.g., if rolling over 20% when sale finishes, then this is 0.2 * ROLLOVER_FACTOR_DECIMALS, or
        // 200_000_000_000_000_000
        uint64 passiveRolloverRate;
        // amount rolled over when finished sale counter increases, and user actively elected to roll over
        uint64 activeRolloverRate;
        // maximum total stake for a user in this track
        uint104 maxTotalStake;
    }

    // INFO FOR FACTORING IN ROLLOVERS

    // the number of checkpoints of a track -- (track, finished sale count) => timestamp number
    mapping(uint24 => mapping(uint24 => uint80))
        public trackFinishedSaleTimestamps;

    // stake weight each user actively rolls over for a given track and a finished sale count
    // (track, user, finished sale count) => amount of stake weight
    mapping(uint24 => mapping(address => mapping(uint24 => uint192)))
        public trackActiveRollOvers;

    // total stake weight actively rolled over for a given track and a finished sale count
    // (track, finished sale count) => total amount of stake weight
    mapping(uint24 => mapping(uint24 => uint192))
        public trackTotalActiveRollOvers;

    // TRACK INFO

    // array of track information
    TrackInfo[] public tracks;

    // whether track is disabled -- (track) => disabled status
    mapping(uint24 => bool) public trackDisabled;

    // whether user has emergency withdrawn from track -- (track, user) => status
    mapping(uint24 => mapping(address => bool)) public hasEmergencyWithdrawn;

    // number of unique stakers on track -- (track) => staker count
    mapping(uint24 => uint256) public numTrackStakers;

    // array of unique stakers on track -- (track) => address array
    // users are only added on first checkpoint to maintain unique
    mapping(uint24 => address[]) public trackStakers;

    // the number of checkpoints of a track -- (track) => checkpoint count
    mapping(uint24 => uint32) public trackCheckpointCounts;

    // track checkpoint mapping -- (track, checkpoint number) => TrackCheckpoint
    mapping(uint24 => mapping(uint32 => TrackCheckpoint))
        public trackCheckpoints;

    // max stakes seen for each track -- (track) => max stake seen on track
    mapping(uint24 => uint104) public trackMaxStakes;

    // USER INFO

    // the number of checkpoints of a user for a track -- (track, user address) => checkpoint count
    mapping(uint24 => mapping(address => uint32)) public userCheckpointCounts;

    // user checkpoint mapping -- (track, user address, checkpoint number) => UserCheckpoint
    mapping(uint24 => mapping(address => mapping(uint32 => UserCheckpoint)))
        public userCheckpoints;

    // EVENTS

    event AddTrack(string indexed name, address indexed token);
    event DisableTrack(uint24 indexed trackId);
    event ActiveRollOver(uint24 indexed trackId, address indexed user);
    event BumpSaleCounter(uint24 indexed trackId, uint32 newCount);
    event AddUserCheckpoint(uint24 indexed trackId, uint80 timestamp);
    event AddTrackCheckpoint(uint24 indexed trackId, uint80 timestamp);
    event Stake(uint24 indexed trackId, address indexed user, uint104 amount);
    event Unstake(uint24 indexed trackId, address indexed user, uint104 amount);
    event EmergencyWithdraw(
        uint24 indexed trackId,
        address indexed sender,
        uint256 amount
    );
    event SyncUserWeight(
        address receiver,
        uint24 srcTrackId,
        uint80 timestamp,
        uint64 dstChainId,
        uint24 dstTrackId
    );
    event SyncTotalWeight(
        address receiver,
        uint24 srcTrackId,
        uint80 timestamp,
        uint64 dstChainId,
        uint24 dstTrackId
    );

    // CONSTRUCTOR
    constructor(address _messageBus) {
        messageBus = _messageBus;
    }

    // FUNCTIONS

    // number of tracks
    function trackCount() external view returns (uint24) {
        return uint24(tracks.length);
    }

    // adds a new track
    function addTrack(
        string calldata name,
        ERC20 stakeToken,
        uint24 _weightAccrualRate,
        uint64 _passiveRolloverRate,
        uint64 _activeRolloverRate,
        uint104 _maxTotalStake
    ) external onlyOwner {
        require(_weightAccrualRate != 0, 'accrual rate is 0');

        // add track
        tracks.push(
            TrackInfo({
                name: name, // name of track
                stakeToken: stakeToken, // token to stake (e.g., IDIA)
                weightAccrualRate: _weightAccrualRate, // rate of stake weight accrual
                passiveRolloverRate: _passiveRolloverRate, // passive rollover
                activeRolloverRate: _activeRolloverRate, // active rollover
                maxTotalStake: _maxTotalStake // max total stake
            })
        );

        // add first track checkpoint
        addTrackCheckpoint(
            uint24(tracks.length - 1), // latest track
            0, // initialize with 0 stake
            false, // add or sub does not matter
            false // do not bump finished sale counter
        );

        // emit
        emit AddTrack(name, address(stakeToken));
    }

    // bumps a track's finished sale counter
    function bumpSaleCounter(uint24 trackId) external onlyOwner {
        // get number of finished sales of this track
        uint24 nFinishedSales = trackCheckpoints[trackId][
            trackCheckpointCounts[trackId] - 1
        ].numFinishedSales;

        // update map that tracks timestamp numbers of finished sales
        trackFinishedSaleTimestamps[trackId][nFinishedSales] = uint80(
            block.timestamp
        );

        // add a new checkpoint with counter incremented by 1
        addTrackCheckpoint(trackId, 0, false, true);

        // `BumpSaleCounter` event emitted in function call above
    }

    // disables a track
    function disableTrack(uint24 trackId) external onlyOwner {
        // set disabled
        trackDisabled[trackId] = true;

        // emit
        emit DisableTrack(trackId);
    }

    // perform active rollover
    function activeRollOver(uint24 trackId) external {
        // add new user checkpoint
        addUserCheckpoint(trackId, 0, false);

        // get new user checkpoint
        UserCheckpoint memory userCp = userCheckpoints[trackId][_msgSender()][
            userCheckpointCounts[trackId][_msgSender()] - 1
        ];

        // current sale count
        uint24 saleCount = userCp.numFinishedSales;

        // subtract old user rollover amount from total
        trackTotalActiveRollOvers[trackId][saleCount] -= trackActiveRollOvers[
            trackId
        ][_msgSender()][saleCount];

        // update user rollover amount
        trackActiveRollOvers[trackId][_msgSender()][saleCount] = userCp
            .stakeWeight;

        // add new user rollover amount to total
        trackTotalActiveRollOvers[trackId][saleCount] += userCp.stakeWeight;

        // emit
        emit ActiveRollOver(trackId, _msgSender());
    }

    // get closest PRECEDING user checkpoint
    function getClosestUserCheckpoint(
        uint24 trackId,
        address user,
        uint80 timestamp
    ) private view returns (UserCheckpoint memory cp) {
        // get total checkpoint count for user
        uint32 nCheckpoints = userCheckpointCounts[trackId][user];

        if (
            userCheckpoints[trackId][user][nCheckpoints - 1].timestamp <=
            timestamp
        ) {
            // First check most recent checkpoint

            // return closest checkpoint
            return userCheckpoints[trackId][user][nCheckpoints - 1];
        } else if (userCheckpoints[trackId][user][0].timestamp > timestamp) {
            // Next check earliest checkpoint

            // If specified timestamp number is earlier than user's first checkpoint,
            // return null checkpoint
            return
                UserCheckpoint({
                    timestamp: 0,
                    staked: 0,
                    stakeWeight: 0,
                    numFinishedSales: 0
                });
        } else {
            // binary search on checkpoints
            uint32 lower = 0;
            uint32 upper = nCheckpoints - 1;
            while (upper > lower) {
                uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                UserCheckpoint memory tempCp = userCheckpoints[trackId][user][
                    center
                ];
                if (tempCp.timestamp == timestamp) {
                    return tempCp;
                } else if (tempCp.timestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            // return closest checkpoint
            return userCheckpoints[trackId][user][lower];
        }
    }

    // gets a user's stake weight within a track at a particular timestamp number
    // logic extended from Compound COMP token `getPriorVotes` function
    function getUserStakeWeight(
        uint24 trackId,
        address user,
        uint80 timestamp
    ) public view returns (uint192) {
        require(timestamp <= block.timestamp, 'timestamp # too high');

        // if track is disabled, stake weight is 0
        if (trackDisabled[trackId]) return 0;

        // check number of user checkpoints
        uint32 nUserCheckpoints = userCheckpointCounts[trackId][user];
        if (nUserCheckpoints == 0) {
            return 0;
        }

        // get closest preceding user checkpoint
        UserCheckpoint memory closestUserCheckpoint = getClosestUserCheckpoint(
            trackId,
            user,
            timestamp
        );

        // check if closest preceding checkpoint was null checkpoint
        if (closestUserCheckpoint.timestamp == 0) {
            return 0;
        }

        // get closest preceding track checkpoint

        TrackCheckpoint memory closestTrackCp = getClosestTrackCheckpoint(
            trackId,
            timestamp
        );

        // get number of finished sales between user's last checkpoint timestamp and provided timestamp
        uint24 numFinishedSalesDelta = closestTrackCp.numFinishedSales -
            closestUserCheckpoint.numFinishedSales;

        // get track info
        TrackInfo memory track = tracks[trackId];

        // calculate stake weight given above delta
        uint192 stakeWeight;
        if (numFinishedSalesDelta == 0) {
            // calculate normally without rollover decay

            uint80 elapsedTimestamps = timestamp -
                closestUserCheckpoint.timestamp;

            stakeWeight =
                closestUserCheckpoint.stakeWeight +
                (uint192(elapsedTimestamps) *
                    track.weightAccrualRate *
                    closestUserCheckpoint.staked) /
                10**18;

            return stakeWeight;
        } else {
            // calculate with rollover decay

            // starting stakeweight
            stakeWeight = closestUserCheckpoint.stakeWeight;
            // current timestamp for iteration
            uint80 currTimestamp = closestUserCheckpoint.timestamp;

            // for each finished sale in between, get stake weight of that period
            // and perform weighted sum
            for (uint24 i = 0; i < numFinishedSalesDelta; i++) {
                // get number of blocks passed at the current sale number
                uint80 elapsedTimestamps = trackFinishedSaleTimestamps[trackId][
                    closestUserCheckpoint.numFinishedSales + i
                ] - currTimestamp;

                // update stake weight
                stakeWeight =
                    stakeWeight +
                    (uint192(elapsedTimestamps) *
                        track.weightAccrualRate *
                        closestUserCheckpoint.staked) /
                    10**18;

                // get amount of stake weight actively rolled over for this sale number
                uint192 activeRolloverWeight = trackActiveRollOvers[trackId][
                    user
                ][closestUserCheckpoint.numFinishedSales + i];

                // factor in passive and active rollover decay
                stakeWeight =
                    // decay active weight
                    (activeRolloverWeight * track.activeRolloverRate) /
                    ROLLOVER_FACTOR_DECIMALS +
                    // decay passive weight
                    ((stakeWeight - activeRolloverWeight) *
                        track.passiveRolloverRate) /
                    ROLLOVER_FACTOR_DECIMALS;

                // update currTimestamp for next round
                currTimestamp = trackFinishedSaleTimestamps[trackId][
                    closestUserCheckpoint.numFinishedSales + i
                ];
            }

            // add any remaining accrued stake weight at current finished sale count
            uint80 remainingElapsed = timestamp -
                trackFinishedSaleTimestamps[trackId][
                    closestTrackCp.numFinishedSales - 1
                ];
            stakeWeight +=
                (uint192(remainingElapsed) *
                    track.weightAccrualRate *
                    closestUserCheckpoint.staked) /
                10**18;
        }

        // return
        return stakeWeight;
    }

    // get closest PRECEDING track checkpoint
    function getClosestTrackCheckpoint(uint24 trackId, uint80 timestamp)
        private
        view
        returns (TrackCheckpoint memory cp)
    {
        // get total checkpoint count for track
        uint32 nCheckpoints = trackCheckpointCounts[trackId];

        if (
            trackCheckpoints[trackId][nCheckpoints - 1].timestamp <= timestamp
        ) {
            // First check most recent checkpoint

            // return closest checkpoint
            return trackCheckpoints[trackId][nCheckpoints - 1];
        } else if (trackCheckpoints[trackId][0].timestamp > timestamp) {
            // Next check earliest checkpoint

            // If specified timestamp number is earlier than track's first checkpoint,
            // return null checkpoint
            return
                TrackCheckpoint({
                    timestamp: 0,
                    totalStaked: 0,
                    totalStakeWeight: 0,
                    numFinishedSales: 0
                });
        } else {
            // binary search on checkpoints
            uint32 lower = 0;
            uint32 upper = nCheckpoints - 1;
            while (upper > lower) {
                uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                TrackCheckpoint memory tempCp = trackCheckpoints[trackId][
                    center
                ];
                if (tempCp.timestamp == timestamp) {
                    return tempCp;
                } else if (tempCp.timestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            // return closest checkpoint
            return trackCheckpoints[trackId][lower];
        }
    }

    // gets total stake weight within a track at a particular timestamp number
    // logic extended from Compound COMP token `getPriorVotes` function
    function getTotalStakeWeight(uint24 trackId, uint80 timestamp)
        public
        view
        returns (uint192)
    {
        require(timestamp <= block.timestamp, 'timestamp # too high');

        // if track is disabled, stake weight is 0
        if (trackDisabled[trackId]) return 0;

        // get closest track checkpoint
        TrackCheckpoint memory closestCheckpoint = getClosestTrackCheckpoint(
            trackId,
            timestamp
        );

        // check if closest preceding checkpoint was null checkpoint
        if (closestCheckpoint.timestamp == 0) {
            return 0;
        }

        // calculate blocks elapsed since checkpoint
        uint80 additionalTimestamps = (timestamp - closestCheckpoint.timestamp);

        // get track info
        TrackInfo storage trackInfo = tracks[trackId];

        // calculate marginal accrued stake weight
        uint192 marginalAccruedStakeWeight = (uint192(additionalTimestamps) *
            trackInfo.weightAccrualRate *
            closestCheckpoint.totalStaked) / 10**18;

        // return
        return closestCheckpoint.totalStakeWeight + marginalAccruedStakeWeight;
    }

    function addUserCheckpoint(
        uint24 trackId,
        uint104 amount,
        bool addElseSub
    ) internal {
        // get track info
        TrackInfo storage track = tracks[trackId];

        // get user checkpoint count
        uint32 nCheckpointsUser = userCheckpointCounts[trackId][_msgSender()];

        // get track checkpoint count
        uint32 nCheckpointsTrack = trackCheckpointCounts[trackId];

        // get latest track checkpoint
        TrackCheckpoint memory trackCp = trackCheckpoints[trackId][
            nCheckpointsTrack - 1
        ];

        // if this is first checkpoint
        if (nCheckpointsUser == 0) {
            // check if amount exceeds maximum
            require(amount <= track.maxTotalStake, 'exceeds staking cap');

            // add user to stakers list of track
            trackStakers[trackId].push(_msgSender());

            // increment stakers count on track
            numTrackStakers[trackId]++;

            // add a first checkpoint for this user on this track
            userCheckpoints[trackId][_msgSender()][0] = UserCheckpoint({
                timestamp: uint80(block.timestamp),
                staked: amount,
                stakeWeight: 0,
                numFinishedSales: trackCp.numFinishedSales
            });

            // increment user's checkpoint count
            userCheckpointCounts[trackId][_msgSender()] = nCheckpointsUser + 1;
        } else {
            // get previous checkpoint
            UserCheckpoint storage prev = userCheckpoints[trackId][
                _msgSender()
            ][nCheckpointsUser - 1];

            // check if amount exceeds maximum
            require(
                (addElseSub ? prev.staked + amount : prev.staked - amount) <=
                    track.maxTotalStake,
                'exceeds staking cap'
            );

            // ensure timestamp number downcast to uint80 is monotonically increasing (prevent overflow)
            // this should never happen within the lifetime of the universe, but if it does, this prevents a catastrophe
            require(
                prev.timestamp <= uint80(block.timestamp),
                'timestamp # overflow'
            );

            // add a new checkpoint for user within this track
            // if no blocks elapsed, just update prev checkpoint (so checkpoints can be uniquely identified by timestamp number)
            if (prev.timestamp == uint80(block.timestamp)) {
                prev.staked = addElseSub
                    ? prev.staked + amount
                    : prev.staked - amount;
                prev.numFinishedSales = trackCp.numFinishedSales;
            } else {
                userCheckpoints[trackId][_msgSender()][
                    nCheckpointsUser
                ] = UserCheckpoint({
                    timestamp: uint80(block.timestamp),
                    staked: addElseSub
                        ? prev.staked + amount
                        : prev.staked - amount,
                    stakeWeight: getUserStakeWeight(
                        trackId,
                        _msgSender(),
                        uint80(block.timestamp)
                    ),
                    numFinishedSales: trackCp.numFinishedSales
                });

                // increment user's checkpoint count
                userCheckpointCounts[trackId][_msgSender()] =
                    nCheckpointsUser +
                    1;
            }
        }

        // emit
        emit AddUserCheckpoint(trackId, uint80(block.timestamp));
    }

    function addTrackCheckpoint(
        uint24 trackId, // track number
        uint104 amount, // delta on staked amount
        bool addElseSub, // true = adding; false = subtracting
        bool _bumpSaleCounter // whether to increase sale counter by 1
    ) internal {
        // get track info
        TrackInfo storage track = tracks[trackId];

        // get track checkpoint count
        uint32 nCheckpoints = trackCheckpointCounts[trackId];

        // if this is first checkpoint
        if (nCheckpoints == 0) {
            // add a first checkpoint for this track
            trackCheckpoints[trackId][0] = TrackCheckpoint({
                timestamp: uint80(block.timestamp),
                totalStaked: amount,
                totalStakeWeight: 0,
                numFinishedSales: _bumpSaleCounter ? 1 : 0
            });

            // increase new track's checkpoint count by 1
            trackCheckpointCounts[trackId]++;
        } else {
            // get previous checkpoint
            TrackCheckpoint storage prev = trackCheckpoints[trackId][
                nCheckpoints - 1
            ];

            // get whether track is disabled
            bool isDisabled = trackDisabled[trackId];

            if (isDisabled) {
                // if previous checkpoint was disabled, then cannot increase stake going forward
                require(!addElseSub, 'disabled: cannot add stake');
            }

            // ensure timestamp number downcast to uint80 is monotonically increasing (prevent overflow)
            // this should never happen within the lifetime of the universe, but if it does, this prevents a catastrophe
            require(
                prev.timestamp <= uint80(block.timestamp),
                'timestamp # overflow'
            );

            // calculate blocks elapsed since checkpoint
            uint80 additionalTimestamp = (uint80(block.timestamp) -
                prev.timestamp);

            // calculate marginal accrued stake weight
            uint192 marginalAccruedStakeWeight = (uint192(additionalTimestamp) *
                track.weightAccrualRate *
                prev.totalStaked) / 10**18;

            // calculate new stake weight
            uint192 newStakeWeight = prev.totalStakeWeight +
                marginalAccruedStakeWeight;

            // factor in passive and active rollover decay
            if (_bumpSaleCounter) {
                // get total active rollover amount
                uint192 activeRolloverWeight = trackTotalActiveRollOvers[
                    trackId
                ][prev.numFinishedSales];

                newStakeWeight =
                    // decay active weight
                    (activeRolloverWeight * track.activeRolloverRate) /
                    ROLLOVER_FACTOR_DECIMALS +
                    // decay passive weight
                    ((newStakeWeight - activeRolloverWeight) *
                        track.passiveRolloverRate) /
                    ROLLOVER_FACTOR_DECIMALS;

                // emit
                emit BumpSaleCounter(trackId, prev.numFinishedSales + 1);
            }

            // add a new checkpoint for this track
            // if no timestamp elapsed, just update prev checkpoint (so checkpoints can be uniquely identified by timestamp number)
            if (additionalTimestamp == 0) {
                prev.totalStaked = addElseSub
                    ? prev.totalStaked + amount
                    : prev.totalStaked - amount;
                prev.totalStakeWeight = isDisabled
                    ? (
                        prev.totalStakeWeight < newStakeWeight
                            ? prev.totalStakeWeight
                            : newStakeWeight
                    )
                    : newStakeWeight;
                prev.numFinishedSales = _bumpSaleCounter
                    ? prev.numFinishedSales + 1
                    : prev.numFinishedSales;
            } else {
                trackCheckpoints[trackId][nCheckpoints] = TrackCheckpoint({
                    timestamp: uint80(block.timestamp),
                    totalStaked: addElseSub
                        ? prev.totalStaked + amount
                        : prev.totalStaked - amount,
                    totalStakeWeight: isDisabled
                        ? (
                            prev.totalStakeWeight < newStakeWeight
                                ? prev.totalStakeWeight
                                : newStakeWeight
                        )
                        : newStakeWeight,
                    numFinishedSales: _bumpSaleCounter
                        ? prev.numFinishedSales + 1
                        : prev.numFinishedSales
                });

                // increase new track's checkpoint count by 1
                trackCheckpointCounts[trackId]++;
            }
        }

        // emit
        emit AddTrackCheckpoint(trackId, uint80(block.timestamp));
    }

    // stake
    function stake(uint24 trackId, uint104 amount) external nonReentrant {
        // stake amount must be greater than 0
        require(amount > 0, 'amount is 0');

        // get track info
        TrackInfo storage track = tracks[trackId];

        // get whether track is disabled
        bool isDisabled = trackDisabled[trackId];

        // cannot stake into disabled track
        require(!isDisabled, 'track is disabled');

        // transfer the specified amount of stake token from user to this contract
        track.stakeToken.safeTransferFrom(_msgSender(), address(this), amount);

        // add user checkpoint
        addUserCheckpoint(trackId, amount, true);

        // add track checkpoint
        addTrackCheckpoint(trackId, amount, true, false);

        // get latest track cp
        TrackCheckpoint memory trackCp = trackCheckpoints[trackId][
            trackCheckpointCounts[trackId] - 1
        ];

        // update track max staked
        if (trackMaxStakes[trackId] < trackCp.totalStaked) {
            trackMaxStakes[trackId] = trackCp.totalStaked;
        }

        // emit
        emit Stake(trackId, _msgSender(), amount);
    }

    // unstake
    function unstake(uint24 trackId, uint104 amount) external nonReentrant {
        // amount must be greater than 0
        require(amount > 0, 'amount is 0');

        // get track info
        TrackInfo storage track = tracks[trackId];

        // get number of user's checkpoints within this track
        uint32 userCheckpointCount = userCheckpointCounts[trackId][
            _msgSender()
        ];

        // get user's latest checkpoint
        UserCheckpoint storage checkpoint = userCheckpoints[trackId][
            _msgSender()
        ][userCheckpointCount - 1];

        // ensure amount <= user's current stake
        require(amount <= checkpoint.staked, 'amount > staked');

        // add user checkpoint
        addUserCheckpoint(trackId, amount, false);

        // add track checkpoint
        addTrackCheckpoint(trackId, amount, false, false);

        // transfer the specified amount of stake token from this contract to user
        track.stakeToken.safeTransfer(_msgSender(), amount);

        // emit
        emit Unstake(trackId, _msgSender(), amount);
    }

    // emergency withdraw
    function emergencyWithdraw(uint24 trackId) external nonReentrant {
        // require track is disabled
        require(trackDisabled[trackId], 'track !disabled');

        // require can only emergency withdraw once
        require(
            !hasEmergencyWithdrawn[trackId][_msgSender()],
            'already called'
        );

        // set emergency withdrawn status to true
        hasEmergencyWithdrawn[trackId][_msgSender()] = true;

        // get track info
        TrackInfo storage track = tracks[trackId];

        // get number of user's checkpoints within this track
        uint32 userCheckpointCount = userCheckpointCounts[trackId][
            _msgSender()
        ];

        // get user's latest checkpoint
        UserCheckpoint storage checkpoint = userCheckpoints[trackId][
            _msgSender()
        ][userCheckpointCount - 1];

        // update checkpoint before emergency withdrawal
        // add user checkpoint
        addUserCheckpoint(trackId, checkpoint.staked, false);
        // add track checkpoint
        addTrackCheckpoint(trackId, checkpoint.staked, false, false);

        // transfer the specified amount of stake token from this contract to user
        track.stakeToken.safeTransfer(_msgSender(), checkpoint.staked);

        // emit
        emit EmergencyWithdraw(trackId, _msgSender(), checkpoint.staked);
    }

    // Methods for bridging track weight information

    // Push
    function syncUserWeight(
        address receiver,
        address[] calldata users,
        uint24 trackId,
        uint80 timestamp,
        uint64 dstChainId
    ) external payable nonReentrant {
        // should be active track
        require(!trackDisabled[trackId], 'track !disabled');

        // get user stake weight on this contract
        uint192[] memory userStakeWeights = new uint192[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            userStakeWeights[i] = getUserStakeWeight(
                trackId,
                users[i],
                timestamp
            );
        }

        // construct message data to be sent to dest contract
        bytes memory message = abi.encode(
            MessageRequest({
                bridgeType: BridgeType.UserWeight,
                users: users,
                timestamp: timestamp,
                weights: userStakeWeights,
                trackId: trackId
            })
        );

        // calculate messageBus fee
        MessageBusSender messageBusSender = MessageBusSender(messageBus);
        uint256 fee = messageBusSender.calcFee(message);
        require(msg.value >= fee, "Not enough fee");

        // trigger the message bridge
        MessageSenderLib.sendMessage(
            receiver,
            dstChainId,
            message,
            messageBus,
            fee
        );

        // Refund mesasgeBus fee
        if ((msg.value - fee) != 0) {
            payable(_msgSender()).transfer(msg.value - fee);
        }


        emit SyncUserWeight(
            receiver,
            trackId,
            timestamp,
            dstChainId,
            trackId
        );
    }

    function syncTotalWeight(
        address receiver,
        uint24 trackId,
        uint80 timestamp,
        uint64 dstChainId
    ) external payable nonReentrant {
        // should be active track
        require(!trackDisabled[trackId], 'track disabled');

        address[] memory users = new address[](1);
        users[0] = _msgSender();

        // get total stake weight on this contract
        uint192[] memory weights = new uint192[](1);
        weights[0] = getTotalStakeWeight(trackId, timestamp);

        // construct message data to be sent to dest contract
        bytes memory message = abi.encode(
            MessageRequest({
                bridgeType: BridgeType.TotalWeight,
                users: users,
                timestamp: timestamp,
                weights: weights,
                trackId: trackId
            })
        );

        // calculate messageBus fee
        MessageBusSender messageBusSender = MessageBusSender(messageBus);
        uint256 fee = messageBusSender.calcFee(message);
        require(msg.value >= fee, "Not enough fee");

        // trigger the message bridge
        MessageSenderLib.sendMessage(
            receiver,
            dstChainId,
            message,
            messageBus,
            fee
        );

        // Refund mesasgeBus fee
        if ((msg.value - fee) != 0) {
            payable(_msgSender()).transfer(msg.value - fee);
        }

        emit SyncTotalWeight(receiver, trackId, timestamp, dstChainId, trackId);
    }
}