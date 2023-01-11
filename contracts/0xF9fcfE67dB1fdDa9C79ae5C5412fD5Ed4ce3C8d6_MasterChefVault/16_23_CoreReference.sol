// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import { Initializable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import { ICore } from "../core/ICore.sol";

/// @notice Stores a reference to the core contract
/// @author Recursive Research Inc
abstract contract CoreReference is Initializable {
    ICore public core;
    bool private _paused;

    /// initialize logic contract
    /// This tag here tells OZ to not throw an error on this constructor
    /// Recommended here:
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Emitted when the pause is triggered
    event Paused();

    /// @dev Emitted when the pause is lifted
    event Unpaused();

    function __CoreReference_init(address coreAddress) internal onlyInitializing {
        __CoreReference_init_unchained(coreAddress);
    }

    function __CoreReference_init_unchained(address coreAddress) internal onlyInitializing {
        core = ICore(coreAddress);
    }

    modifier whenNotPaused() {
        require(!paused(), "PAUSED");
        _;
    }

    modifier whenPaused() {
        require(paused(), "NOT_PAUSED");
        _;
    }

    modifier onlyPauser() {
        require(core.hasRole(core.PAUSE_ROLE(), msg.sender), "NOT_PAUSER");
        _;
    }

    modifier onlyGovernor() {
        require(core.hasRole(core.GOVERN_ROLE(), msg.sender), "NOT_GOVERNOR");
        _;
    }

    modifier onlyGuardian() {
        require(core.hasRole(core.GUARDIAN_ROLE(), msg.sender), "NOT_GUARDIAN");
        _;
    }

    modifier onlyStrategist() {
        require(_isStrategist(msg.sender), "NOT_STRATEGIST");
        _;
    }

    /// @notice view function to see whether or not the contract is paused
    /// @return true if the contract is paused either by the core or independently
    function paused() public view returns (bool) {
        return (core.paused() || _paused);
    }

    function pause() external onlyPauser whenNotPaused {
        _paused = true;
        emit Paused();
    }

    function unpause() external onlyPauser whenPaused {
        _paused = false;
        emit Unpaused();
    }

    function _isStrategist(address _user) internal view returns (bool) {
        return core.hasRole(core.STRATEGIST_ROLE(), _user);
    }
}