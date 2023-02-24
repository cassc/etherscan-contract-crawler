// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./SwitchboardBase.sol";

contract OptimisticSwitchboard is SwitchboardBase {
    uint256 public immutable timeoutInSeconds;

    // sourceChain => isPaused
    mapping(uint256 => bool) public tripSingleFuse;

    event PacketTripped(uint256 packetId, bool tripSingleFuse);
    error WatcherNotFound();

    constructor(
        address owner_,
        address oracle_,
        uint256 timeoutInSeconds_
    ) AccessControl(owner_) {
        oracle__ = IOracle(oracle_);
        timeoutInSeconds = timeoutInSeconds_;
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId_ packet id
     * @param proposeTime_ time at which packet was proposed
     */
    function allowPacket(
        bytes32,
        uint256 packetId_,
        uint256,
        uint256 proposeTime_
    ) external view override returns (bool) {
        if (tripGlobalFuse || tripSingleFuse[packetId_]) return false;
        if (block.timestamp - proposeTime_ < timeoutInSeconds) return false;
        return true;
    }

    /**
     * @notice pause execution
     */
    function tripGlobal(
        uint256 srcChainSlug_
    ) external onlyRole(_watcherRole(srcChainSlug_)) {
        tripGlobalFuse = false;
        emit SwitchboardTripped(false);
    }

    /**
     * @notice pause a packet
     */
    function tripPath(
        uint256 packetId_,
        uint256 srcChainSlug_
    ) external onlyRole(_watcherRole(srcChainSlug_)) {
        //source chain based tripping

        tripSingleFuse[packetId_] = false;
        emit PacketTripped(packetId_, false);
    }

    /**
     * @notice pause/unpause execution
     */
    function tripGlobal(bool trip_) external onlyOwner {
        tripGlobalFuse = trip_;
        emit SwitchboardTripped(trip_);
    }

    /**
     * @notice pause/unpause a packet
     */
    function tripSingle(uint256 packetId_, bool trip_) external onlyOwner {
        tripSingleFuse[packetId_] = trip_;
        emit PacketTripped(packetId_, trip_);
    }

    /**
     * @notice adds an watcher for `remoteChainSlug_` chain
     * @param remoteChainSlug_ remote chain slug
     * @param watcher_ watcher address
     */
    function grantWatcherRole(
        uint256 remoteChainSlug_,
        address watcher_
    ) external onlyOwner {
        _grantRole(_watcherRole(remoteChainSlug_), watcher_);
    }

    /**
     * @notice removes an watcher from `remoteChainSlug_` chain list
     * @param remoteChainSlug_ remote chain slug
     * @param watcher_ watcher address
     */
    function revokeWatcherRole(
        uint256 remoteChainSlug_,
        address watcher_
    ) external onlyOwner {
        _revokeRole(_watcherRole(remoteChainSlug_), watcher_);
    }

    function _watcherRole(uint256 chainSlug_) internal pure returns (bytes32) {
        return bytes32(chainSlug_);
    }
}