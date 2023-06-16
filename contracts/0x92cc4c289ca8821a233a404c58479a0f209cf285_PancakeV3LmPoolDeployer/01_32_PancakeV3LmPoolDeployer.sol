// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Factory.sol';
import '@pancakeswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

import './PancakeV3LmPool.sol';
import './interfaces/IMasterChefV3.sol';
import './interfaces/IPancakeV3PoolWithLMPool.sol';

/// @dev This contract is for Master Chef to create a corresponding LmPool when
/// adding a new farming pool. As for why not just create LmPool inside the
/// Master Chef contract is merely due to the imcompatibility of the solidity
/// versions.
contract PancakeV3LmPoolDeployer {
    struct Parameters {
        address pool;
        address masterChef;
        // The old version LMPool.
        address oldLMPool;
    }

    Parameters public parameters;

    address public immutable masterChef;

    address public owner;

    // Avoid Duplicate Deployment Contracts.
    mapping(address => bool) public LMPoolUpdateFlag;

    // Add whiteList, double check , avoid set wrong V3 pool.
    mapping(address => bool) public whiteList;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event UpdateWhiteList(address indexed pool, bool status);
    event NewLMPool(address indexed pool, address indexed LMPool);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Not Owner');
        _;
    }

    constructor(address _masterChef) {
        masterChef = _masterChef;
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), 'Zero address');
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function addWhiteList(uint256[] calldata pids) external onlyOwner {
        for (uint256 i = 0; i < pids.length; i++) {
            (, address v3Pool, , , , , ) = IMasterChefV3(masterChef).poolInfo(pids[i]);
            require(v3Pool != address(0), 'Zero address');
            whiteList[v3Pool] = true;
            emit UpdateWhiteList(v3Pool, true);
        }
    }

    function removeWhiteList(address v3Pool) external onlyOwner {
        require(v3Pool != address(0), 'Zero address');
        whiteList[v3Pool] = false;
        emit UpdateWhiteList(v3Pool, false);
    }

    /// @dev Deploys a LmPool
    /// @param pool The contract address of the PancakeSwap V3 pool
    function deploy(IPancakeV3PoolWithLMPool pool) external onlyOwner returns (IPancakeV3LmPool lmPool) {
        require(whiteList[address(pool)], 'Not in whiteList');

        require(!LMPoolUpdateFlag[address(pool)], 'Already Updated');
        LMPoolUpdateFlag[address(pool)] = true;

        address oldLMPool = pool.lmPool();
        parameters = Parameters({pool: address(pool), masterChef: masterChef, oldLMPool: oldLMPool});

        lmPool = new PancakeV3LmPool{salt: keccak256(abi.encode(address(pool), masterChef, block.timestamp))}();

        delete parameters;

        // Set new LMPool for pancake v3 pool.
        IPancakeV3Factory(INonfungiblePositionManager(IMasterChefV3(masterChef).nonfungiblePositionManager()).factory())
            .setLmPool(address(pool), address(lmPool));

        // Initialize the new LMPool.
        lmPool.initialize();

        emit NewLMPool(address(pool), address(lmPool));
    }
}