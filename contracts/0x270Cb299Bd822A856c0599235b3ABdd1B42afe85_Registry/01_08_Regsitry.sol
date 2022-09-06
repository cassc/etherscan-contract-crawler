// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";

contract Registry is AccessControl, IRegistry {
    address public override maha;
    address public override locker;
    address public override gaugeVoter;
    address public override governor;
    address public override staker;

    bool public paused;

    bool internal initialized;

    bytes32 public constant EMERGENCY_STOP_ROLE =
        keccak256("EMERGENCY_STOP_ROLE");

    function initialize(
        address _maha,
        address _gaugeVoter,
        address _locker,
        address _governor,
        address _staker,
        address _governance
    ) external {
        require(!initialized, "already initialized");

        maha = _maha;
        gaugeVoter = _gaugeVoter;
        locker = _locker;
        governor = _governor;
        staker = _staker;

        _setupRole(DEFAULT_ADMIN_ROLE, _governance);
        _setupRole(EMERGENCY_STOP_ROLE, _governance);

        initialized = true;
    }

    modifier onlyGovernance() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not governance");
        _;
    }

    function toggleProtocol() external {
        require(
            hasRole(EMERGENCY_STOP_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "not governance or emergency"
        );
        paused = !paused;
    }

    function ensureNotPaused() external view override {
        require(!paused, "protocol is paused");
    }

    function setMAHA(address _new) external override onlyGovernance {
        emit MahaChanged(msg.sender, maha, _new);
        maha = _new;
    }

    function setVoter(address _new) external override onlyGovernance {
        emit VoterChanged(msg.sender, gaugeVoter, _new);
        gaugeVoter = _new;
    }

    function setLocker(address _new) external override onlyGovernance {
        emit LockerChanged(msg.sender, locker, _new);
        locker = _new;
    }

    function setGovernor(address _new) external override onlyGovernance {
        emit GovernorChanged(msg.sender, governor, _new);
        governor = _new;
    }

    function setStaker(address _new) external override onlyGovernance {
        emit GovernorChanged(msg.sender, governor, _new);
        staker = _new;
    }
}