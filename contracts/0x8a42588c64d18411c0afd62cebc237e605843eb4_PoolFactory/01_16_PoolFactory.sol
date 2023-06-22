/*
PoolFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IModuleFactory.sol";
import "./interfaces/IStakingModule.sol";
import "./interfaces/IRewardModule.sol";
import "./OwnerController.sol";
import "./Pool.sol";

/**
 * @title Pool factory
 *
 * @notice this implements the Pool factory contract which allows any user to
 * easily configure and deploy their own Pool
 *
 * @dev it relies on a system of sub-factories which are responsible for the
 * creation of underlying staking and reward modules. This primary factory
 * calls each module factory and assembles the overall Pool contract.
 *
 * this contract also manages the module factory whitelist.
 */
contract PoolFactory is IPoolFactory, OwnerController {
    // events
    event PoolCreated(address indexed user, address pool);
    event WhitelistUpdated(
        address indexed factory,
        uint256 previous,
        uint256 updated
    );

    // types
    enum ModuleFactoryType {
        Unknown,
        Staking,
        Reward
    }

    // fields
    mapping(address => bool) public override map;
    address[] public override list;
    address private immutable _gysr;
    address private immutable _config;
    mapping(address => ModuleFactoryType) public whitelist;

    /**
     * @param gysr_ address of GYSR token
     * @param config_ address of configuration contract
     */
    constructor(address gysr_, address config_) {
        _gysr = gysr_;
        _config = config_;
    }

    /**
     * @inheritdoc IPoolFactory
     */
    function create(
        address staking,
        address reward,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override returns (address) {
        // validate
        require(whitelist[staking] == ModuleFactoryType.Staking, "f1");
        require(whitelist[reward] == ModuleFactoryType.Reward, "f2");

        // create modules
        address stakingModule = IModuleFactory(staking).createModule(
            _config,
            stakingdata
        );
        address rewardModule = IModuleFactory(reward).createModule(
            _config,
            rewarddata
        );

        // create pool
        Pool pool = new Pool(stakingModule, rewardModule, _gysr, _config);

        // set access
        IStakingModule(stakingModule).transferOwnership(address(pool));
        IRewardModule(rewardModule).transferOwnership(address(pool));
        pool.transferControl(msg.sender);
        pool.transferControlStakingModule(msg.sender);
        pool.transferControlRewardModule(msg.sender);
        pool.transferOwnership(msg.sender);

        // bookkeeping
        map[address(pool)] = true;
        list.push(address(pool));

        // output
        emit PoolCreated(msg.sender, address(pool));
        return address(pool);
    }

    /**
     * @notice set the whitelist status of a module factory
     * @param factory_ address of module factory
     * @param type_ updated whitelist status for module
     */
    function setWhitelist(address factory_, uint256 type_) external {
        requireController();
        require(type_ <= uint256(ModuleFactoryType.Reward), "f4");
        require(factory_ != address(0), "f5");
        emit WhitelistUpdated(factory_, uint256(whitelist[factory_]), type_);
        whitelist[factory_] = ModuleFactoryType(type_);
    }

    /**
     * @return total number of Pools created by the factory
     */
    function count() public view returns (uint256) {
        return list.length;
    }
}