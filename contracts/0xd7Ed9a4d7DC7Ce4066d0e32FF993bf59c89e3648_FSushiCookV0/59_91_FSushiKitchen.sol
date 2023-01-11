// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFSushiKitchen.sol";
import "./interfaces/IFlashStrategySushiSwapFactory.sol";
import "./libraries/Snapshots.sol";

contract FSushiKitchen is Ownable, IFSushiKitchen {
    using Snapshots for Snapshots.Snapshot[];

    uint256 internal constant BASE = 1e18;

    address public immutable override flashStrategyFactory;

    Snapshots.Snapshot[] internal _totalWeightPoints;
    mapping(uint256 => Snapshots.Snapshot[]) internal _weightPoints; // pid -> snapshots

    constructor(address _flashStrategyFactory) {
        flashStrategyFactory = _flashStrategyFactory;
    }

    function totalWeightPointsLength() external view override returns (uint256) {
        return _totalWeightPoints.size();
    }

    function weightPointsLength(uint256 pid) external view override returns (uint256) {
        return _weightPoints[pid].size();
    }

    function totalWeightPoints() external view override returns (uint256) {
        return _totalWeightPoints.lastValue();
    }

    function weightPoints(uint256 pid) external view override returns (uint256) {
        return _weightPoints[pid].lastValue();
    }

    function totalWeightPointsAt(uint256 timestamp) external view override returns (uint256) {
        return _totalWeightPoints.valueAt(timestamp);
    }

    function weightPointsAt(uint256 pid, uint256 timestamp) external view override returns (uint256) {
        return _weightPoints[pid].valueAt(timestamp);
    }

    function relativeWeight(uint256 pid) external view override returns (uint256) {
        uint256 totalPoints = _totalWeightPoints.lastValue();
        if (totalPoints == 0) return 0;

        uint256 points = _weightPoints[pid].lastValue();
        return (points * BASE) / totalPoints;
    }

    function relativeWeightAt(uint256 pid, uint256 timestamp) external view override returns (uint256) {
        uint256 totalPoints = _totalWeightPoints.valueAt(timestamp);
        if (totalPoints == 0) return 0;

        uint256 points = _weightPoints[pid].valueAt(timestamp);
        return (points * BASE) / totalPoints;
    }

    function addPool(uint256 pid) external override {
        address strategy = IFlashStrategySushiSwapFactory(flashStrategyFactory).getFlashStrategySushiSwap(pid);
        if (strategy == address(0)) revert InvalidPid();

        emit AddPool(pid);

        _updateWeight(pid, 100e18);
    }

    function updateWeight(uint256 pid, uint256 points) external override onlyOwner {
        if (_weightPoints[pid].size() == 0) revert InvalidPid();

        _updateWeight(pid, points);
    }

    function _updateWeight(uint256 pid, uint256 points) internal {
        uint256 prev = _weightPoints[pid].lastValue();
        _weightPoints[pid].append(points);
        uint256 totalPoints = _totalWeightPoints.lastValue() + points - prev;
        _totalWeightPoints.append(totalPoints);

        emit UpdateWeight(pid, points, totalPoints);
    }

    function checkpoint(uint256) external override {
        // Empty: for future compatibility
    }
}