// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IGauge.sol";
import "./libraries/Math.sol";

/**
 * @title Gauge Controller
 * @author LevX ([email protected])
 * @notice Controls liquidity gauges and the issuance of coins through the gauges
 * @dev Ported from vyper (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/GaugeController.vy)
 */
contract GaugeController is Ownable, IGaugeController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    uint256 internal constant MULTIPLIER = 1e18;

    uint256 public override interval;
    uint256 public override weightVoteDelay;
    address public override votingEscrow;

    // Gauge parameters
    // All numbers are "fixed point" on the basis of 1e18
    int128 public override gaugeTypesLength;
    int128 public override gaugesLength;
    mapping(int128 => string) public override gaugeTypeNames;

    // Needed for enumeration
    mapping(int128 => address) public override gauges;

    // we increment values by 1 prior to storing them here so we can rely on a value
    // of zero as meaning the gauge has not been set
    mapping(address => int128) internal _gaugeTypes;

    mapping(address => mapping(address => VotedSlope)) public override voteUserSlopes; // user -> addr -> VotedSlope
    mapping(address => uint256) public override voteUserPower; // Total vote power used by user
    mapping(address => mapping(address => uint256)) public override lastUserVote; // Last user vote's timestamp for each gauge address

    // Past and scheduled points for gauge weight, sum of weights per type, total weight
    // Point is for bias+slope
    // changes_* are for changes in slope
    // time_* are for the last change timestamp
    // timestamps are rounded to whole weeks

    mapping(address => mapping(uint256 => Point)) public override pointsWeight; // addr -> time -> Point
    mapping(address => mapping(uint256 => uint256)) internal _changesWeight; // addr -> time -> slope
    mapping(address => uint256) public override timeWeight; // addr -> last scheduled time (next week)

    mapping(int128 => mapping(uint256 => Point)) public override pointsSum; // gaugeType -> time -> Point
    mapping(int128 => mapping(uint256 => uint256)) internal _changesSum; // gaugeType -> time -> slope
    mapping(int128 => uint256) public override timeSum; // gaugeType -> last scheduled time (next week)

    mapping(uint256 => uint256) public override pointsTotal; // time -> total weight
    uint256 public override timeTotal; // last scheduled time

    mapping(int128 => mapping(uint256 => uint256)) public override pointsTypeWeight; // gaugeType -> time -> type weight
    mapping(int128 => uint256) public override timeTypeWeight; // gaugeType -> last scheduled time (next week)

    /**
     * @notice Contract constructor
     * @param _interval for how many seconds gauge weights will remain the same
     * @param _weightVoteDelay for how many seconds weight votes cannot be changed
     * @param _votingEscrow `VotingEscrow` contract address
     */
    constructor(
        uint256 _interval,
        uint256 _weightVoteDelay,
        address _votingEscrow
    ) {
        interval = _interval;
        weightVoteDelay = _weightVoteDelay;
        votingEscrow = _votingEscrow;
        timeTotal = (block.timestamp / _interval) * _interval;
    }

    /**
     * @notice Get gauge type for id
     * @param addr Gauge address
     * @return Gauge type id
     */
    function gaugeTypes(address addr) external view override returns (int128) {
        int128 gaugeType = _gaugeTypes[addr];
        require(gaugeType != 0, "GC: INVALID_GAUGE_TYPE");

        return gaugeType - 1;
    }

    /**
     * @notice Get current gauge weight
     * @param addr Gauge address
     * @return Gauge weight
     */
    function getGaugeWeight(address addr) external view override returns (uint256) {
        return pointsWeight[addr][timeWeight[addr]].bias;
    }

    /**
     * @notice Get current type weight
     * @param gaugeType Type id
     * @return Type weight
     */
    function getTypeWeight(int128 gaugeType) external view override returns (uint256) {
        return pointsTypeWeight[gaugeType][timeTypeWeight[gaugeType]];
    }

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view override returns (uint256) {
        return pointsTotal[timeTotal];
    }

    /**
     * @notice Get sum of gauge weights per type
     * @param gaugeType Type id
     * @return Sum of gauge weights
     */
    function getWeightsSumPerType(int128 gaugeType) external view override returns (uint256) {
        return pointsSum[gaugeType][timeSum[gaugeType]].bias;
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address addr) external view override returns (uint256) {
        return _gaugeRelativeWeight(addr, block.timestamp);
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address addr, uint256 time) public view override returns (uint256) {
        return _gaugeRelativeWeight(addr, time);
    }

    /**
     * @notice Add gauge type with name `name` and weight `weight`
     * @param name Name of gauge type
     */
    function addType(string memory name) external override {
        addType(name, 0);
    }

    /**
     * @notice Add gauge type with name `name` and weight `weight`
     * @param name Name of gauge type
     * @param weight Weight of gauge type
     */
    function addType(string memory name, uint256 weight) public override onlyOwner {
        int128 gaugeType = gaugeTypesLength;
        gaugeTypeNames[gaugeType] = name;
        gaugeTypesLength = gaugeType + 1;
        if (weight != 0) {
            _changeTypeWeight(gaugeType, weight);
        }
        emit AddType(name, gaugeType);
    }

    /**
     * @notice Change type weight
     * @param gaugeType Type id
     * @param weight New type weight
     */
    function changeTypeWeight(int128 gaugeType, uint256 weight) external override onlyOwner {
        _changeTypeWeight(gaugeType, weight);
    }

    /**
     * @notice Add gauge `addr` of type `gaugeType` with weight `weight`
     * @param addr Gauge address
     * @param gaugeType Gauge type
     */
    function addGauge(address addr, int128 gaugeType) external override {
        addGauge(addr, gaugeType, 0);
    }

    /**
     * @notice Add gauge `addr` of type `gaugeType` with weight `weight`
     * @param addr Gauge address
     * @param gaugeType Gauge type
     * @param weight Gauge weight
     */
    function addGauge(
        address addr,
        int128 gaugeType,
        uint256 weight
    ) public override onlyOwner {
        require((gaugeType >= 0) && (gaugeType < gaugeTypesLength), "GC: INVALID_GAUGE_TYPE");
        require(_gaugeTypes[addr] == 0, "GC: DUPLICATE_GAUGE");

        int128 n = gaugesLength;
        gaugesLength = n + 1;
        gauges[n] = addr;

        _gaugeTypes[addr] = gaugeType + 1;
        uint256 _interval = interval;
        uint256 nextTime = ((block.timestamp + _interval) / _interval) * _interval;

        if (weight > 0) {
            uint256 typeWeight = _getTypeWeight(gaugeType);
            uint256 oldSum = _getSum(gaugeType);
            uint256 oldTotal = _getTotal();

            pointsSum[gaugeType][nextTime].bias = weight + oldSum;
            timeSum[gaugeType] = nextTime;
            pointsTotal[nextTime] = oldTotal + typeWeight * weight;
            timeTotal = nextTime;

            pointsWeight[addr][nextTime].bias = weight;
        }

        if (timeSum[gaugeType] == 0) timeSum[gaugeType] = nextTime;
        timeWeight[addr] = nextTime;

        emit NewGauge(addr, gaugeType, weight);
    }

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param increment Gauge weight to be increased
     */
    function increaseGaugeWeight(uint256 increment) external override {
        _increaseGaugeWeight(increment);
    }

    /**
     * @notice Toggle the killed status of the gauge
     * @param addr Gauge address
     */
    function killGauge(address addr) external override onlyOwner {
        IGauge(addr).killMe();
    }

    /**
     * @notice Checkpoint to fill data common for all gauges
     */
    function checkpoint() external override {
        _getTotal();
    }

    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauges
     * @param addr Gauge address
     */
    function checkpointGauge(address addr) external override {
        _getWeight(addr);
        _getTotal();
    }

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
    values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param addr Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeightWrite(address addr) external override returns (uint256) {
        return gaugeRelativeWeightWrite(addr, block.timestamp);
    }

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
    values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param addr Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeightWrite(address addr, uint256 time) public override returns (uint256) {
        _getWeight(addr);
        _getTotal(); // Also calculates get_sum
        return gaugeRelativeWeight(addr, time);
    }

    /**
     * @notice Allocate voting power for changing pool weights on behalf of a user (only called by gauges)
     * @param user Actual user whose voting power will be utilized
     * @param userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
     */
    function voteForGaugeWeights(address user, uint256 userWeight) external override {
        address escrow = votingEscrow;
        uint256 slope = uint256(uint128(IVotingEscrow(escrow).getLastUserSlope(user)));
        uint256 lockEnd = IVotingEscrow(escrow).unlockTime(user);
        uint256 _interval = interval;
        uint256 nextTime = ((block.timestamp + _interval) / _interval) * _interval;
        require(lockEnd > nextTime, "GC: LOCK_EXPIRES_TOO_EARLY");
        require((userWeight >= 0) && (userWeight <= 10000), "GC: VOTING_POWER_ALL_USED");
        require(block.timestamp >= lastUserVote[user][msg.sender] + weightVoteDelay, "GC: VOTED_TOO_EARLY");

        // Avoid stack too deep error
        {
            int128 gaugeType = _gaugeTypes[msg.sender] - 1;
            require(gaugeType >= 0, "GC: GAUGE_NOT_ADDED");
            // Prepare slopes and biases in memory
            VotedSlope memory oldSlope = voteUserSlopes[user][msg.sender];
            uint256 oldDt;
            if (oldSlope.end > nextTime) oldDt = oldSlope.end - nextTime;
            VotedSlope memory newSlope = VotedSlope({
                slope: (slope * userWeight) / 10000,
                end: lockEnd,
                power: userWeight
            });

            // Check and update powers (weights) used
            uint256 powerUsed = voteUserPower[user];
            powerUsed = powerUsed + newSlope.power - oldSlope.power;
            voteUserPower[user] = powerUsed;
            require((powerUsed >= 0) && (powerUsed <= 10000), "GC: USED_TOO_MUCH_POWER");

            /// Remove old and schedule new slope changes
            _updateSlopeChanges(
                msg.sender,
                nextTime,
                gaugeType,
                oldSlope.slope * oldDt,
                newSlope.slope * (lockEnd - nextTime),
                oldSlope,
                newSlope
            );
        }

        // Record last action time
        lastUserVote[user][msg.sender] = block.timestamp;

        emit VoteForGauge(block.timestamp, user, msg.sender, userWeight);
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function _gaugeRelativeWeight(address addr, uint256 time) internal view returns (uint256) {
        uint256 _interval = interval;
        uint256 t = (time / _interval) * _interval;
        uint256 totalWeight = pointsTotal[t];

        if (totalWeight > 0) {
            int128 gaugeType = _gaugeTypes[addr] - 1;
            uint256 typeWeight = pointsTypeWeight[gaugeType][t];
            uint256 gaugeWeight = pointsWeight[addr][t].bias;
            return (MULTIPLIER * typeWeight * gaugeWeight) / totalWeight;
        } else return 0;
    }

    /**
     * @notice Change type weight
     * @param gaugeType Type id
     * @param weight New type weight
     */
    function _changeTypeWeight(int128 gaugeType, uint256 weight) internal {
        uint256 oldWeight = _getTypeWeight(gaugeType);
        uint256 oldSum = _getSum(gaugeType);
        uint256 totalWeight = _getTotal();
        uint256 _interval = interval;
        uint256 nextTime = ((block.timestamp + _interval) / _interval) * _interval;

        totalWeight = totalWeight + oldSum * weight - oldSum * oldWeight;
        pointsTotal[nextTime] = totalWeight;
        pointsTypeWeight[gaugeType][nextTime] = weight;
        timeTotal = nextTime;
        timeTypeWeight[gaugeType] = nextTime;

        emit NewTypeWeight(gaugeType, nextTime, weight, totalWeight);
    }

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param increment Gauge weight to be increased
     */
    function _increaseGaugeWeight(uint256 increment) internal {
        int128 gaugeType = _gaugeTypes[msg.sender] - 1;
        require(gaugeType >= 0, "GC: GAUGE_NOT_ADDED");

        uint256 oldGaugeWeight = _getWeight(msg.sender);
        uint256 typeWeight = _getTypeWeight(gaugeType);
        uint256 oldSum = _getSum(gaugeType);
        uint256 totalWeight = _getTotal();
        uint256 _interval = interval;
        uint256 nextTime = ((block.timestamp + _interval) / _interval) * _interval;

        pointsWeight[msg.sender][nextTime].bias = oldGaugeWeight + increment;
        timeWeight[msg.sender] = nextTime;

        uint256 newSum = oldSum + increment;
        pointsSum[gaugeType][nextTime].bias = newSum;
        timeSum[gaugeType] = nextTime;

        totalWeight = totalWeight + newSum * typeWeight - oldSum * typeWeight;
        pointsTotal[nextTime] = totalWeight;
        timeTotal = nextTime;

        emit NewGaugeWeight(msg.sender, block.timestamp, oldGaugeWeight + increment, totalWeight);
    }

    /**
     * @notice Fill historic total weights week-over-week for missed checkins
     * and return the total for the future week
     * @return Total weight
     */
    function _getTotal() internal returns (uint256) {
        uint256 _interval = interval;
        uint256 t = timeTotal;
        int128 nGaugeTypes = gaugeTypesLength;
        // If we have already checkpointed - still need to change the value
        if (t > block.timestamp) t -= _interval;
        uint256 pt = pointsTotal[t];

        for (int128 gaugeType; gaugeType < 100; ) {
            if (gaugeType == nGaugeTypes) break;
            _getSum(gaugeType);
            _getTypeWeight(gaugeType);

            unchecked {
                ++gaugeType;
            }
        }

        for (uint256 i; i < 500; ) {
            if (t > block.timestamp) break;
            t += _interval;
            pt = 0;
            // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for (int128 gaugeType; gaugeType < 100; ) {
                if (gaugeType == nGaugeTypes) break;
                uint256 typeSum = pointsSum[gaugeType][t].bias;
                uint256 typeWeight = pointsTypeWeight[gaugeType][t];
                pt += typeSum * typeWeight;

                unchecked {
                    ++gaugeType;
                }
            }
            pointsTotal[t] = pt;

            if (t > block.timestamp) timeTotal = t;

            unchecked {
                ++i;
            }
        }
        return pt;
    }

    /**
     * @notice Fill sum of gauge weights for the same type week-over-week for
     * missed checkins and return the sum for the future week
     * @param gaugeType Gauge type id
     * @return Sum of weights
     */
    function _getSum(int128 gaugeType) internal returns (uint256) {
        uint256 t = timeSum[gaugeType];
        if (t > 0) {
            Point memory pt = pointsSum[gaugeType][t];
            uint256 _interval = interval;
            for (uint256 i; i < 500; ) {
                if (t > block.timestamp) break;
                t += _interval;
                uint256 dBias = pt.slope * _interval;
                if (pt.bias > dBias) {
                    pt.bias -= dBias;
                    uint256 dSlope = _changesSum[gaugeType][t];
                    pt.slope -= dSlope;
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                pointsSum[gaugeType][t] = pt;
                if (t > block.timestamp) timeSum[gaugeType] = t;

                unchecked {
                    ++i;
                }
            }
            return pt.bias;
        } else return 0;
    }

    /**
     * @notice Fill historic type weights week-over-week for missed checkins
     * and return the type weight for the future week
     * @param gaugeType Gauge type id
     * @return Type weight
     */
    function _getTypeWeight(int128 gaugeType) internal returns (uint256) {
        uint256 t = timeTypeWeight[gaugeType];
        if (t > 0) {
            uint256 w = pointsTypeWeight[gaugeType][t];
            uint256 _interval = interval;
            for (uint256 i; i < 500; ) {
                if (t > block.timestamp) break;
                t += _interval;
                pointsTypeWeight[gaugeType][t] = w;
                if (t > block.timestamp) timeTypeWeight[gaugeType] = t;

                unchecked {
                    ++i;
                }
            }
            return w;
        } else return 0;
    }

    /**
     * @notice Fill historic gauge weights week-over-week for missed checkins
     * and return the total for the future week
     * @param addr Gauge address
     * @return Gauge weight
     */
    function _getWeight(address addr) internal returns (uint256) {
        uint256 t = timeWeight[addr];
        if (t > 0) {
            Point memory pt = pointsWeight[addr][t];
            uint256 _interval = interval;
            for (uint256 i; i < 500; ) {
                if (t > block.timestamp) break;
                t += _interval;
                uint256 dBias = pt.slope * _interval;
                if (pt.bias > dBias) {
                    pt.bias -= dBias;
                    uint256 dSlope = _changesWeight[addr][t];
                    pt.slope -= dSlope;
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                pointsWeight[addr][t] = pt;
                if (t > block.timestamp) timeWeight[addr] = t;

                unchecked {
                    ++i;
                }
            }
            return pt.bias;
        } else return 0;
    }

    function _updateSlopeChanges(
        address addr,
        uint256 nextTime,
        int128 gaugeType,
        uint256 oldBias,
        uint256 newBias,
        VotedSlope memory oldSlope,
        VotedSlope memory newSlope
    ) internal {
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for next_time
        pointsWeight[addr][nextTime].bias = Math.max(_getWeight(addr) + newBias, oldBias) - oldBias;
        pointsSum[gaugeType][nextTime].bias = Math.max(_getSum(gaugeType) + newBias, oldBias) - oldBias;
        if (oldSlope.end > nextTime) {
            pointsWeight[addr][nextTime].slope =
                Math.max(pointsWeight[addr][nextTime].slope + newSlope.slope, oldSlope.slope) -
                oldSlope.slope;
            pointsSum[gaugeType][nextTime].slope =
                Math.max(pointsSum[gaugeType][nextTime].slope + newSlope.slope, oldSlope.slope) -
                oldSlope.slope;
        } else {
            pointsWeight[addr][nextTime].slope += newSlope.slope;
            pointsSum[gaugeType][nextTime].slope += newSlope.slope;
        }
        if (oldSlope.end > block.timestamp) {
            // Cancel old slope changes if they still didn't happen
            _changesWeight[addr][oldSlope.end] -= oldSlope.slope;
            _changesSum[gaugeType][oldSlope.end] -= oldSlope.slope;
        }
        // Add slope changes for new slopes
        _changesWeight[addr][newSlope.end] += newSlope.slope;
        _changesSum[gaugeType][newSlope.end] += newSlope.slope;

        _getTotal();

        voteUserSlopes[msg.sender][addr] = newSlope;
    }
}