// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../utils/TokenHolder.sol";
import "../interfaces/IGovernable.sol";
import "../interfaces/IManageable.sol";

/**
 * @title Reusable contract that handles accesses
 */
abstract contract Manageable is IManageable, TokenHolder, Initializable {
    /**
     * @notice Pool contract
     */
    IPool public pool;

    /**
     * @notice Requires that the caller is the Pool contract
     */
    modifier onlyPool() {
        require(msg.sender == address(pool), "not-pool");
        _;
    }

    /**
     * @notice Requires that the caller is the Pool contract
     */
    modifier onlyGovernor() {
        require(msg.sender == governor(), "not-governor");
        _;
    }

    modifier whenNotPaused() {
        require(!pool.paused(), "paused");
        _;
    }

    modifier whenNotShutdown() {
        require(!pool.everythingStopped(), "shutdown");
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Manageable_init(IPool pool_) internal initializer {
        require(address(pool_) != address(0), "pool-address-is-zero");
        pool = pool_;
    }

    function governor() public view returns (address _governor) {
        _governor = IGovernable(address(pool)).governor();
    }

    function _requireCanSweep() internal view override onlyGovernor {}

    uint256[49] private __gap;
}