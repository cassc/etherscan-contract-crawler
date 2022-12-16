// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../utils/TokenHolder.sol";
import "../interfaces/IGovernable.sol";
import "../interfaces/IManageable.sol";

error SenderIsNotPool();
error SenderIsNotGovernor();
error IsPaused();
error IsShutdown();
error PoolAddressIsNull();

/**
 * @title Reusable contract that handles accesses
 */
abstract contract Manageable is IManageable, TokenHolder, Initializable {
    /**
     * @notice Pool contract
     */
    IPool public pool;

    /**
     * @dev Throws if `msg.sender` isn't the pool
     */
    modifier onlyPool() {
        if (msg.sender != address(pool)) revert SenderIsNotPool();
        _;
    }

    /**
     * @dev Throws if `msg.sender` isn't the governor
     */
    modifier onlyGovernor() {
        if (msg.sender != governor()) revert SenderIsNotGovernor();
        _;
    }

    /**
     * @dev Throws if contract is paused
     */
    modifier whenNotPaused() {
        if (pool.paused()) revert IsPaused();
        _;
    }

    /**
     * @dev Throws if contract is shutdown
     */
    modifier whenNotShutdown() {
        if (pool.everythingStopped()) revert IsShutdown();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Manageable_init(IPool pool_) internal initializer {
        if (address(pool_) == address(0)) revert PoolAddressIsNull();
        pool = pool_;
    }

    /**
     * @notice Get the governor
     * @return _governor The governor
     */
    function governor() public view returns (address _governor) {
        _governor = IGovernable(address(pool)).governor();
    }

    /// @inheritdoc TokenHolder
    function _requireCanSweep() internal view override onlyGovernor {}

    uint256[49] private __gap;
}