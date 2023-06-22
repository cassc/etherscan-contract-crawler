/*
PoolMetadata

https://github.com/gysr-io/aux

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@gysr/core/contracts/interfaces/IPoolFactory.sol";
import "@gysr/core/contracts/OwnerController.sol";

/**
 * @title PoolMetadata
 *
 * @notice this contract manages metadata definition for GYSR pools. It allows
 * the pool controller to set metadata for that pool, which is then emitted as
 * an event and indexed by the GYSR subgraph.
 */
contract PoolMetadata is OwnerController {
    using SafeERC20 for IERC20;

    // events
    event Metadata(address indexed pool, string data);
    event FeeUpdated(uint256 previous, uint256 updated);
    event TreasuryUpdated(address previous, address updated);
    event FactoryUpdated(address factory, bool added);
    event FactoryV1Updated(address factory);
    event Banned(address indexed pool, bool banned);

    // fields
    IERC20 private immutable _gysr;
    address public treasury;
    uint256 public fee;
    mapping(address => bool) public banned;
    address[] public factories;
    address public factoryV1;

    /**
     * @param factories_ addresses for initial pool factories
     * @param gysr_ address of GYSR token
     * @param treasury_ initial address of treasury
     */
    constructor(
        address[] memory factories_,
        address gysr_,
        address treasury_
    ) {
        for (uint256 i; i < factories_.length; ++i) {
            factories.push(factories_[i]);
            emit FactoryUpdated(factories_[i], true);
        }
        _gysr = IERC20(gysr_);
        treasury = treasury_;
        fee = 0;
    }

    /**
     * @notice define Pool metadata and emit associated event
     * @param pool address of Pool contract
     * @param data encoded metadata
     */
    function metadata(address pool, string calldata data) external {
        // check banned
        require(!banned[pool], "Pool is banned");

        // check each pool factory
        OwnerController p = OwnerController(pool);
        bool ok;
        for (uint256 i; i < factories.length; ++i) {
            // verify pool address created by factory
            if (!IPoolFactory(factories[i]).map(pool)) continue;

            // verify sender access
            if (factories[i] == factoryV1) {
                // v1 did not have controller role
                require(msg.sender == p.owner(), "Sender is not owner");
            } else {
                require(
                    msg.sender == p.controller(),
                    "Sender is not controller"
                );
            }
            ok = true;
            break;
        }
        require(ok, "Pool address is invalid");

        // pay fee
        if (fee > 0) {
            _gysr.safeTransferFrom(msg.sender, treasury, fee);
        }

        // emit event
        emit Metadata(pool, data);
    }

    /**
     * @notice privileged method to clear pool metadata
     * @param pool address of Pool contract
     */
    function clear(address pool) external {
        requireController();
        emit Metadata(pool, "{}");
    }

    /**
     * @notice privileged method to ban pool from submitting metadata.
     * This does NOT affect the ability to manage the core Pool contract.
     * @param pool address of pool to ban
     */
    function ban(address pool) external {
        requireController();
        banned[pool] = true;
        emit Banned(pool, true);
    }

    /**
     * @notice privileged method to unban pool and allow them to submit metadata
     * @param pool address of pool to unban
     */
    function unban(address pool) external {
        requireController();
        banned[pool] = false;
        emit Banned(pool, false);
    }

    /**
     * @notice add new pool factory address for pool verification
     * @param factory address of new pool factory
     */
    function addFactory(address factory) external {
        requireController();
        for (uint256 i; i < factories.length; ++i)
            require(factory != factories[i], "Pool factory already registered");
        factories.push(factory);
        emit FactoryUpdated(factory, true);
    }

    /**
     * @notice remove pool factory address
     * @param index list index of pool factory to remove
     */
    function removeFactory(uint256 index) external {
        requireController();
        require(index < factories.length, "Pool factory index out of bounds");
        address factory = factories[index];
        if (index < factories.length - 1)
            factories[index] = factories[factories.length - 1];
        factories.pop();
        emit FactoryUpdated(factory, false);
    }

    /**
     * @notice set the factory v1 address for legacy access check
     * @param factory_ new value for factory v1 address
     */
    function setFactoryV1(address factory_) external {
        requireController();
        factoryV1 = factory_;
        emit FactoryV1Updated(factory_);
    }

    /**
     * @notice get count of factories registered for pool verification
     */
    function factoryCount() external view returns (uint256) {
        return factories.length;
    }

    /**
     * @notice update the treasury address to receive fees
     * @param treasury_ new value for treasury address
     */
    function setTreasury(address treasury_) external {
        requireController();
        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    /**
     * @notice update the GYSR fee to submit Pool metadata
     * @param fee_ new value for fee
     */
    function setFee(uint256 fee_) external {
        requireController();
        emit FeeUpdated(fee, fee_);
        fee = fee_;
    }
}