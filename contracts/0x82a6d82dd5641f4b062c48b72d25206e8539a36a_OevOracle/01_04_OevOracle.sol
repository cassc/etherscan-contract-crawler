// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/AggregatorV3Interface.sol";

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract OevOracle is AggregatorV3Interface, Ownable {
    int256 public override latestAnswer;
    uint256 public override latestTimestamp;
    uint256 public override latestRound;

    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping(uint256 => RoundData) roundData;

    AggregatorV3Interface public baseAggregator;

    address public updater;

    uint256 public permissionWindow = 10 minutes;

    constructor(AggregatorV3Interface _baseAggregator, address _updater) {
        baseAggregator = _baseAggregator;
        updater = _updater;

        updateAnswer();
    }

    function updateAnswer() public {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            baseAggregator.latestRoundData();

        require(latestRound != roundId, "No update needed");
        if (msg.sender != updater && msg.sender != owner()) {
            require(block.timestamp - updatedAt >= permissionWindow, "In permissioned window");
        }

        latestRound = roundId;
        latestAnswer = answer;
        latestTimestamp = updatedAt;
        roundData[roundId] = RoundData(roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function canUpdateAnswer() public view returns (bool) {
        (uint256 roundId,,,,) = baseAggregator.latestRoundData();
        return latestRound != roundId;
    }

    function setUpdater(address _updater) public onlyOwner {
        updater = _updater;
    }

    function setPermissionWindow(uint256 _permissionWindow) public onlyOwner {
        permissionWindow = _permissionWindow;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            roundData[_roundId].roundId,
            roundData[_roundId].answer,
            roundData[_roundId].startedAt,
            roundData[_roundId].updatedAt,
            roundData[_roundId].answeredInRound
        );
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            roundData[latestRound].roundId,
            roundData[latestRound].answer,
            roundData[latestRound].startedAt,
            roundData[latestRound].updatedAt,
            roundData[latestRound].answeredInRound
        );
    }

    function getAnswer(uint256 roundId) public view override returns (int256) {
        return roundData[roundId].answer;
    }

    function getTimestamp(uint256 roundId) public view override returns (uint256) {
        return roundData[roundId].updatedAt;
    }

    function decimals() public view override returns (uint8) {
        return baseAggregator.decimals();
    }

    function description() public view override returns (string memory) {
        return baseAggregator.description();
    }

    function version() public view override returns (uint256) {
        return baseAggregator.version();
    }

    // TODO: we have no notion of phase or phase ID at this point. Should be pulled from Aggregator.
}