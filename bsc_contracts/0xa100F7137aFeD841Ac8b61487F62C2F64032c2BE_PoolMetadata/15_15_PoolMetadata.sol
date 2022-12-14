/*
PoolMetadata

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PoolFactory.sol";
import "./OwnerController.sol";

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
    event Banned(address indexed pool, bool banned);

    // fields
    PoolFactory private immutable _factory;
    PoolFactory private immutable _factoryV1;
    IERC20 private immutable _gysr;
    address public treasury;
    uint256 public fee;
    mapping(address => bool) public banned;

    /**
     * @param factory_ address for pool factory
     * @param factoryV1_ address for v1 pool factory
     * @param gysr_ address of GYSR token
     * @param treasury_ initial address of treasury
     */
    constructor(
        address factory_,
        address factoryV1_,
        address gysr_,
        address treasury_
    ) {
        _factory = PoolFactory(factory_);
        _factoryV1 = PoolFactory(factoryV1_);
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

        // verify pool address and sender access
        OwnerController p = OwnerController(pool);
        if (_factory.map(pool)) {
            require(msg.sender == p.controller(), "Sender is not controller");
        } else if (_factoryV1.map(pool)) {
            // v1 did not have controller role
            require(msg.sender == p.owner(), "Sender is not owner");
        } else {
            revert("Pool address is invalid");
        }

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