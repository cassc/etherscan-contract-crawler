// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IVotingEscrow.sol";
import "light-lib/contracts/LibTime.sol";

contract GaugeController is Ownable2Step, IGaugeController {
    // 7 * 86400 seconds - all future times are rounded by week
    uint256 private constant _DAY = 86400;
    uint256 private constant _WEEK = _DAY * 7;
    // Cannot change weight votes more often than once in 10 days
    uint256 private constant _WEIGHT_VOTE_DELAY = 10 * _DAY;

    uint256 private constant _MULTIPLIER = 10 ** 18;

    // lt token
    address public immutable token;
    // veLT token
    address public immutable override votingEscrow;

    // Gauge parameters
    // All numbers are "fixed point" on the basis of 1e18
    int128 public nGaugeTypes;
    int128 public nGauge;
    mapping(int128 => string) public gaugeTypeNames;

    // Needed for enumeration
    mapping(uint256 => address) public gauges;

    // we increment values by 1 prior to storing them here so we can rely on a value
    // of zero as meaning the gauge has not been set
    mapping(address => int128) private _gaugeTypes;

    // user -> gaugeAddr -> VotedSlope
    mapping(address => mapping(address => VotedSlope)) public voteUserSlopes;
    // Total vote power used by user
    mapping(address => uint256) public voteUserPower;
    // Last user vote's timestamp for each gauge address
    mapping(address => mapping(address => uint256)) public lastUserVote;

    // user -> gaugeAddr -> epoch -> Point
    mapping(address => mapping(address => mapping(uint256 => UserPoint))) public voteVeLtPointHistory;
    // user -> gaugeAddr -> lastEpoch
    mapping(address => mapping(address => uint256)) public lastVoteVeLtPointEpoch;

    // Past and scheduled points for gauge weight, sum of weights per type, total weight
    // Point is for bias+slope
    // changes_* are for changes in slope
    // time_* are for the last change timestamp
    // timestamps are rounded to whole weeks

    // gaugeAddr -> time -> Point
    mapping(address => mapping(uint256 => Point)) public pointsWeight;
    // gaugeAddr -> time -> slope
    mapping(address => mapping(uint256 => uint256)) private _changesWeight;
    // gaugeAddr -> last scheduled time (next week)
    mapping(address => uint256) public timeWeight;

    //typeId -> time -> Point
    mapping(int128 => mapping(uint256 => Point)) public pointsSum;
    // typeId -> time -> slope
    mapping(int128 => mapping(uint256 => uint256)) public changesSum;
    //typeId -> last scheduled time (next week)
    mapping(uint256 => uint256) public timeSum;

    // time -> total weight
    mapping(uint256 => uint256) public pointsTotal;
    // last scheduled time
    uint256 public timeTotal;

    // typeId -> time -> type weight
    mapping(int128 => mapping(uint256 => uint256)) public pointsTypeWeight;
    // typeId -> last scheduled time (next week)
    mapping(uint256 => uint256) public timeTypeWeight;

    /**
     * @notice Contract constructor
     * @param tokenAddress  LT contract address
     * @param votingEscrowAddress veLT contract address
     */
    constructor(address tokenAddress, address votingEscrowAddress) {
        require(tokenAddress != address(0), "CE000");
        require(votingEscrowAddress != address(0), "CE000");

        token = tokenAddress;
        votingEscrow = votingEscrowAddress;
        timeTotal = LibTime.timesRoundedByWeek(block.timestamp);
    }

    /**
     * @notice Get gauge type for address
     *  @param _addr Gauge address
     * @return Gauge type id
     */
    function gaugeTypes(address _addr) external view override returns (int128) {
        int128 gaugeType = _gaugeTypes[_addr];
        require(gaugeType != 0, "CE000");
        return gaugeType - 1;
    }

    /**
     * @notice Add gauge `addr` of type `gaugeType` with weight `weight`
     * @param addr Gauge address
     * @param gaugeType Gauge type
     * @param weight Gauge weight
     */
    function addGauge(address addr, int128 gaugeType, uint256 weight) external override onlyOwner {
        require(gaugeType >= 0 && gaugeType < nGaugeTypes, "GC001");
        require(_gaugeTypes[addr] == 0, "GC002");

        int128 n = nGauge;
        nGauge = n + 1;
        gauges[_int128ToUint256(n)] = addr;

        _gaugeTypes[addr] = gaugeType + 1;
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        if (weight > 0) {
            uint256 _typeWeight = _getTypeWeight(gaugeType);
            uint256 _oldSum = _getSum(gaugeType);
            uint256 _oldTotal = _getTotal();

            pointsSum[gaugeType][nextTime].bias = weight + _oldSum;
            timeSum[_int128ToUint256(gaugeType)] = nextTime;
            pointsTotal[nextTime] = _oldTotal + _typeWeight * weight;
            timeTotal = nextTime;

            pointsWeight[addr][nextTime].bias = weight;
        }

        if (timeSum[_int128ToUint256(gaugeType)] == 0) {
            timeSum[_int128ToUint256(gaugeType)] = nextTime;
        }
        timeWeight[addr] = nextTime;

        emit NewGauge(addr, gaugeType, weight);
    }

    /**
     * @notice Checkpoint to fill data common for all gauges
     */
    function checkpoint() external override {
        _getTotal();
    }

    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauge
     * @param addr Gauge address
     */
    function checkpointGauge(address addr) external override {
        _getWeight(addr);
        _getTotal();
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18(e.g. 1.0 == 1e18). Inflation which will be received by
     * it is inflation_rate * relative_weight / 1e18
     * @param gaugeAddress Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address gaugeAddress, uint256 time) external view override returns (uint256) {
        return _gaugeRelativeWeight(gaugeAddress, time);
    }

    /**
     *  @notice Get gauge weight normalized to 1e18 and also fill all the unfilled values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param gaugeAddress Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeightWrite(address gaugeAddress, uint256 time) external override returns (uint256) {
        _getWeight(gaugeAddress);
        // Also calculates get_sum;
        _getTotal();
        return _gaugeRelativeWeight(gaugeAddress, time);
    }

    /**
     * @notice Add gauge type with name `_name` and weight `weight`
     * @dev only owner call
     * @param _name Name of gauge type
     * @param weight Weight of gauge type
     */
    function addType(string memory _name, uint256 weight) external override onlyOwner {
        int128 typeId = nGaugeTypes;
        gaugeTypeNames[typeId] = _name;
        nGaugeTypes = typeId + 1;
        if (weight != 0) {
            _changeTypeWeight(typeId, weight);
        }
        emit AddType(_name, typeId);
    }

    /**
     * @notice Change gauge type `typeId` weight to `weight`
     * @dev only owner call
     * @param typeId Gauge type id
     * @param weight New Gauge weight
     */
    function changeTypeWeight(int128 typeId, uint256 weight) external override onlyOwner {
        _changeTypeWeight(typeId, weight);
    }

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param gaugeAddress `Gauge` contract address
     * @param weight New Gauge weight
     */
    function changeGaugeWeight(address gaugeAddress, uint256 weight) external override onlyOwner {
        int128 gaugeType = _gaugeTypes[gaugeAddress] - 1;
        require(gaugeType >= 0, "GC000");
        _changeGaugeWeight(gaugeAddress, weight);
    }

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gaugeAddressList Gauge of list which `msg.sender` votes for
     * @param userWeightList Weight of list for a gauge in bps (units of 0.01%). Minimal is zero.
     */
    function batchVoteForGaugeWeights(address[] memory gaugeAddressList, uint256[] memory userWeightList) public {
        require(gaugeAddressList.length == userWeightList.length, "GC007");
        for (uint256 i = 0; i < gaugeAddressList.length && i < 128; i++) {
            voteForGaugeWeights(gaugeAddressList[i], userWeightList[i]);
        }
    }

    //avoid Stack too deep
    struct VoteForGaugeWeightsParam {
        VotedSlope oldSlope;
        VotedSlope newSlope;
        uint256 oldDt;
        uint256 oldBias;
        uint256 newDt;
        uint256 newBias;
        UserPoint newUserPoint;
    }

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gaugeAddress Gauge which `msg.sender` votes for
     * @param userWeight Weight for a gauge in bps (units of 0.01%). Minimal is zero.
     *        example: 10%=1000,3%=300,0.01%=1,100%=10000
     */
    function voteForGaugeWeights(address gaugeAddress, uint256 userWeight) public override {
        int128 gaugeType = _gaugeTypes[gaugeAddress] - 1;
        require(gaugeType >= 0, "GC000");

        uint256 slope = uint256(IVotingEscrow(votingEscrow).getLastUserSlope(msg.sender));
        uint256 lockEnd = IVotingEscrow(votingEscrow).lockedEnd(msg.sender);
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);
        require(lockEnd > nextTime, "GC003");
        require(userWeight >= 0 && userWeight <= 10000, "GC004");
        require(block.timestamp >= lastUserVote[msg.sender][gaugeAddress] + _WEIGHT_VOTE_DELAY, "GC005");

        VoteForGaugeWeightsParam memory param;

        // Prepare slopes and biases in memory
        param.oldSlope = voteUserSlopes[msg.sender][gaugeAddress];
        param.oldDt = 0;
        if (param.oldSlope.end > nextTime) {
            param.oldDt = param.oldSlope.end - nextTime;
        }
        param.oldBias = param.oldSlope.slope * param.oldDt;

        param.newSlope = VotedSlope({slope: (slope * userWeight) / 10000, end: lockEnd, power: userWeight});

        // dev: raises when expired
        param.newDt = lockEnd - nextTime;
        param.newBias = param.newSlope.slope * param.newDt;
        param.newUserPoint = UserPoint({bias: param.newBias, slope: param.newSlope.slope, ts: nextTime, blk: block.number});

        // Check and update powers (weights) used
        uint256 powerUsed = voteUserPower[msg.sender];
        powerUsed = powerUsed + param.newSlope.power - param.oldSlope.power;
        voteUserPower[msg.sender] = powerUsed;
        require((powerUsed >= 0) && (powerUsed <= 10000), "GC006");

        //// Remove old and schedule new slope changes
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for nextTime
        uint256 oldWeightBias = _getWeight(gaugeAddress);
        uint256 oldWeightSlope = pointsWeight[gaugeAddress][nextTime].slope;
        uint256 oldSumBias = _getSum(gaugeType);
        uint256 oldSumSlope = pointsSum[gaugeType][nextTime].slope;

        pointsWeight[gaugeAddress][nextTime].bias = Math.max(oldWeightBias + param.newBias, param.oldBias) - param.oldBias;
        pointsSum[gaugeType][nextTime].bias = Math.max(oldSumBias + param.newBias, param.oldBias) - param.oldBias;

        if (param.oldSlope.end > nextTime) {
            pointsWeight[gaugeAddress][nextTime].slope =
                Math.max(oldWeightSlope + param.newSlope.slope, param.oldSlope.slope) -
                param.oldSlope.slope;
            pointsSum[gaugeType][nextTime].slope =
                Math.max(oldSumSlope + param.newSlope.slope, param.oldSlope.slope) -
                param.oldSlope.slope;
        } else {
            pointsWeight[gaugeAddress][nextTime].slope += param.newSlope.slope;
            pointsSum[gaugeType][nextTime].slope += param.newSlope.slope;
        }

        if (param.oldSlope.end > block.timestamp) {
            // Cancel old slope changes if they still didn't happen
            _changesWeight[gaugeAddress][param.oldSlope.end] -= param.oldSlope.slope;
            changesSum[gaugeType][param.oldSlope.end] -= param.oldSlope.slope;
        }

        //Add slope changes for new slopes
        _changesWeight[gaugeAddress][param.newSlope.end] += param.newSlope.slope;
        changesSum[gaugeType][param.newSlope.end] += param.newSlope.slope;

        _getTotal();

        voteUserSlopes[msg.sender][gaugeAddress] = param.newSlope;

        // Record last action time
        lastUserVote[msg.sender][gaugeAddress] = block.timestamp;

        //record user point history
        uint256 voteVeLtPointEpoch = lastVoteVeLtPointEpoch[msg.sender][gaugeAddress] + 1;
        voteVeLtPointHistory[msg.sender][gaugeAddress][voteVeLtPointEpoch] = param.newUserPoint;
        lastVoteVeLtPointEpoch[msg.sender][gaugeAddress] = voteVeLtPointEpoch;

        emit VoteForGauge(msg.sender, gaugeAddress, block.timestamp, userWeight);
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
     * @param typeId Type id
     * @return Type weight
     */
    function getTypeWeight(int128 typeId) external view override returns (uint256) {
        return pointsTypeWeight[typeId][timeTypeWeight[_int128ToUint256(typeId)]];
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
     * @param typeId Type id
     * @return Sum of gauge weights
     */
    function getWeightsSumPreType(int128 typeId) external view override returns (uint256) {
        return pointsSum[typeId][timeSum[_int128ToUint256(typeId)]].bias;
    }

    /**
     * @notice Fill historic type weights week-over-week for missed checkins and return the type weight for the future week
     * @param gaugeType Gauge type id
     * @return Type weight
     */
    function _getTypeWeight(int128 gaugeType) internal returns (uint256) {
        uint256 t = timeTypeWeight[_int128ToUint256(gaugeType)];
        if (t <= 0) {
            return 0;
        }

        uint256 w = pointsTypeWeight[gaugeType][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            pointsTypeWeight[gaugeType][t] = w;
            if (t > block.timestamp) {
                timeTypeWeight[_int128ToUint256(gaugeType)] = t;
            }
        }
        return w;
    }

    /**
     * @notice Fill sum of gauge weights for the same type week-over-week for missed checkins and return the sum for the future week
     * @param gaugeType Gauge type id
     * @return Sum of weights
     */
    function _getSum(int128 gaugeType) internal returns (uint256) {
        uint256 ttype = _int128ToUint256(gaugeType);
        uint256 t = timeSum[ttype];
        if (t <= 0) {
            return 0;
        }

        Point memory pt = pointsSum[gaugeType][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            uint256 dBias = pt.slope * _WEEK;
            if (pt.bias > dBias) {
                pt.bias -= dBias;
                uint256 dSlope = changesSum[gaugeType][t];
                pt.slope -= dSlope;
            } else {
                pt.bias = 0;
                pt.slope = 0;
            }
            pointsSum[gaugeType][t] = pt;
            if (t > block.timestamp) {
                timeSum[ttype] = t;
            }
        }
        return pt.bias;
    }

    /**
     * @notice Fill historic total weights week-over-week for missed checkins and return the total for the future week
     * @return Total weight
     */
    function _getTotal() internal returns (uint256) {
        uint256 t = timeTotal;
        int128 _nGaugeTypes = nGaugeTypes;
        if (t > block.timestamp) {
            // If we have already checkpointed - still need to change the value
            t -= _WEEK;
        }
        uint256 pt = pointsTotal[t];

        for (int128 gaugeType = 0; gaugeType < 100; gaugeType++) {
            if (gaugeType == _nGaugeTypes) {
                break;
            }
            _getSum(gaugeType);
            _getTypeWeight(gaugeType);
        }

        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            pt = 0;
            // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for (int128 gaugeType = 0; gaugeType < 100; gaugeType++) {
                if (gaugeType == _nGaugeTypes) {
                    break;
                }
                uint256 typeSum = pointsSum[gaugeType][t].bias;
                uint256 typeWeight = pointsTypeWeight[gaugeType][t];
                pt += typeSum * typeWeight;
            }

            pointsTotal[t] = pt;
            if (t > block.timestamp) {
                timeTotal = t;
            }
        }

        return pt;
    }

    /**
     * @notice Fill historic gauge weights week-over-week for missed checkins and return the total for the future week
     * @param gaugeAddr Address of the gauge
     * @return Gauge weight
     */
    function _getWeight(address gaugeAddr) internal returns (uint256) {
        uint256 t = timeWeight[gaugeAddr];

        if (t <= 0) {
            return 0;
        }
        Point memory pt = pointsWeight[gaugeAddr][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            uint256 dBias = pt.slope * _WEEK;
            if (pt.bias > dBias) {
                pt.bias -= dBias;
                uint256 dSlope = _changesWeight[gaugeAddr][t];
                pt.slope -= dSlope;
            } else {
                pt.bias = 0;
                pt.slope = 0;
            }
            pointsWeight[gaugeAddr][t] = pt;
            if (t > block.timestamp) {
                timeWeight[gaugeAddr] = t;
            }
        }
        return pt.bias;
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18 (e.g. 1.0 == 1e18).
     * Inflation which will be received by it is inflation_rate * relative_weight / 1e18
     * @param addr Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function _gaugeRelativeWeight(address addr, uint256 time) internal view returns (uint256) {
        uint256 t = LibTime.timesRoundedByWeek(time);
        uint256 _totalWeight = pointsTotal[t];
        if (_totalWeight <= 0) {
            return 0;
        }

        int128 gaugeType = _gaugeTypes[addr] - 1;
        uint256 _typeWeight = pointsTypeWeight[gaugeType][t];
        uint256 _gaugeWeight = pointsWeight[addr][t].bias;
        return (_MULTIPLIER * _typeWeight * _gaugeWeight) / _totalWeight;
    }

    function _changeGaugeWeight(address addr, uint256 weight) internal {
        // Change gauge weight
        //Only needed when testing in reality
        int128 gaugeType = _gaugeTypes[addr] - 1;
        uint256 oldGaugeWeight = _getWeight(addr);
        uint256 typeWeight = _getTypeWeight(gaugeType);
        uint256 oldSum = _getSum(gaugeType);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        pointsWeight[addr][nextTime].bias = weight;
        timeWeight[addr] = nextTime;

        uint256 newSum = oldSum + weight - oldGaugeWeight;
        pointsSum[gaugeType][nextTime].bias = newSum;
        timeSum[_int128ToUint256(gaugeType)] = nextTime;

        _totalWeight = _totalWeight + newSum * typeWeight - oldSum * typeWeight;
        pointsTotal[nextTime] = _totalWeight;
        timeTotal = nextTime;

        emit NewGaugeWeight(addr, block.timestamp, weight, _totalWeight);
    }

    /**
     *  @notice Change type weight
     * @param typeId Type id
     * @param weight New type weight
     */
    function _changeTypeWeight(int128 typeId, uint256 weight) internal {
        uint256 oldWeight = _getTypeWeight(typeId);
        uint256 oldSum = _getSum(typeId);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        _totalWeight = _totalWeight + oldSum * weight - oldSum * oldWeight;
        pointsTotal[nextTime] = _totalWeight;
        pointsTypeWeight[typeId][nextTime] = weight;
        timeTotal = nextTime;
        timeTypeWeight[_int128ToUint256(typeId)] = nextTime;

        emit NewTypeWeight(typeId, nextTime, weight, _totalWeight);
    }

    function _int128ToUint256(int128 from) internal pure returns (uint256) {
        return uint256(uint128(from));
    }
}