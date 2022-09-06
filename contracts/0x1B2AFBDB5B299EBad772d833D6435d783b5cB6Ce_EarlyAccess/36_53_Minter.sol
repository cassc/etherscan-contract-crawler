// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/IMinter.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/INFTGauge.sol";

interface IToken {
    function mint(address account, uint256 value) external;
}

contract Minter is IMinter {
    uint256 constant RATE_DENOMINATOR = 1e18;
    uint256 constant INFLATION_DELAY = 86400;

    address public immutable override token;
    address public immutable override controller;
    uint256 public immutable override initialSupply;
    uint256 public immutable override initialRate;
    uint256 public immutable override rateReductionTime;
    uint256 public immutable override rateReductionCoefficient;

    int128 public override miningEpoch;
    uint256 public override startEpochTime;
    uint256 public override rate;

    mapping(address => mapping(uint256 => mapping(address => uint256))) public override minted; // gauge -> tokenId -> user -> amount

    uint256 internal startEpochSupply;

    constructor(
        address _token,
        address _controller,
        uint256 _initialSupply,
        uint256 _initialRate,
        uint256 _rateReductionTime,
        uint256 _rateReductionCoefficient
    ) {
        token = _token;
        controller = _controller;
        initialSupply = _initialSupply;
        initialRate = _initialRate;
        rateReductionTime = _rateReductionTime;
        rateReductionCoefficient = _rateReductionCoefficient;

        startEpochTime = block.timestamp + INFLATION_DELAY - rateReductionTime;
        miningEpoch = -1;
        rate = 0;
        startEpochSupply = initialSupply;
    }

    /**
     * @notice Current number of tokens in existence (claimed or unclaimed)
     */
    function availableSupply() external view override returns (uint256) {
        return _availableSupply();
    }

    /**
     * @notice How much supply is mintable from start timestamp till end timestamp
     * @param start Start of the time interval (timestamp)
     * @param end End of the time interval (timestamp)
     * @return Tokens mintable from `start` till `end`
     */
    function mintableInTimeframe(uint256 start, uint256 end) external view returns (uint256) {
        require(start <= end, "MT: INVALID_TIME_RANGE");
        uint256 toMint = 0;
        uint256 currentEpochTime = startEpochTime;
        uint256 currentRate = rate;

        // Special case if end is in future (not yet minted) epoch
        if (end > currentEpochTime + rateReductionTime) {
            currentEpochTime += rateReductionTime;
            currentRate = (currentRate * RATE_DENOMINATOR) / rateReductionCoefficient;
        }

        require(end <= currentEpochTime + rateReductionTime, "MT: TOO_FAR_IN_FUTURE");

        for (uint256 i; i < 1000; ) {
            if (end >= currentEpochTime) {
                uint256 currentEnd = end;
                if (currentEnd > currentEpochTime + rateReductionTime)
                    currentEnd = currentEpochTime + rateReductionTime;

                uint256 currentStart = start;
                if (currentStart >= currentEpochTime + rateReductionTime) break;
                else if (currentStart < currentEpochTime) currentStart = currentEpochTime;

                toMint += currentRate * (currentEnd - currentStart);

                if (start >= currentEpochTime) break;
            }

            currentEpochTime -= rateReductionTime;
            currentRate = (currentRate * rateReductionCoefficient) / RATE_DENOMINATOR; // double-division with rounding made rate a bit less => good
            require(currentRate <= initialRate, "MT: THIS_SHOULD_NEVER_HAPPEN");

            unchecked {
                ++i;
            }
        }

        return toMint;
    }

    /**
     * @notice Update mining rate and supply at the start of the epoch
     * @dev Callable by any address, but only once per epoch
     *      Total supply becomes slightly larger if this function is called late
     */
    function updateMiningParameters() external override {
        require(block.timestamp >= startEpochTime + rateReductionTime, "MT: TOO_SOON");
        _updateMiningParameters();
    }

    /**
     * @notice Get timestamp of the current mining epoch start
     *         while simultaneously updating mining parameters
     * @return Timestamp of the epoch
     */
    function startEpochTimeWrite() external override returns (uint256) {
        uint256 _startEpochTime = startEpochTime;
        if (block.timestamp >= _startEpochTime + rateReductionTime) {
            _updateMiningParameters();
            return startEpochTime;
        } else return _startEpochTime;
    }

    /**
     * @notice Get timestamp of the next mining epoch start
     *         while simultaneously updating mining parameters
     * @return Timestamp of the next epoch
     */
    function futureEpochTimeWrite() external override returns (uint256) {
        uint256 _startEpochTime = startEpochTime;
        if (block.timestamp >= _startEpochTime + rateReductionTime) {
            _updateMiningParameters();
            return startEpochTime + rateReductionTime;
        } else return _startEpochTime + rateReductionTime;
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gaugeAddr `NFTGauge` address to get mintable amount from
     * @param tokenId tokenId
     */
    function mint(address gaugeAddr, uint256 tokenId) external override {
        require(IGaugeController(controller).gaugeTypes(gaugeAddr) >= 0, "MT: GAUGE_NOT_ADDED");

        INFTGauge(gaugeAddr).userCheckpoint(tokenId, msg.sender);
        uint256 total = INFTGauge(gaugeAddr).integrateFraction(tokenId, msg.sender);

        uint256 _minted = minted[gaugeAddr][tokenId][msg.sender];
        if (total > _minted) {
            minted[gaugeAddr][tokenId][msg.sender] = total;

            emit Minted(msg.sender, gaugeAddr, tokenId, total - _minted);
            IToken(token).mint(msg.sender, total - _minted);
        }
    }

    function _availableSupply() internal view returns (uint256) {
        return startEpochSupply + (block.timestamp - startEpochTime) * rate;
    }

    /**
     * @dev Update mining rate and supply at the start of the epoch
     *      Any modifying mining call must also call this
     */
    function _updateMiningParameters() internal {
        uint256 _rate = rate;
        uint256 _startEpochSupply = startEpochSupply;

        startEpochTime += rateReductionTime;
        miningEpoch += 1;

        if (_rate == 0) _rate = initialRate;
        else {
            _startEpochSupply += _rate * rateReductionTime;
            startEpochSupply = _startEpochSupply;
            _rate = (_rate * RATE_DENOMINATOR) / rateReductionCoefficient;
        }

        rate = _rate;

        emit UpdateMiningParameters(block.timestamp, _rate, _startEpochSupply);
    }
}