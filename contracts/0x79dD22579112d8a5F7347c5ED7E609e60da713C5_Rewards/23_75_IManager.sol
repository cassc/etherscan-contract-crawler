// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IManager {

    // bytes can take on the form of deploying or recovering liquidity
    struct ControllerTransferData {
        bytes32 controllerId; // controller to target
        bytes data; // data the controller will pass
    }

    struct PoolTransferData {
        address pool; // pool to target
        uint256 amount; // amount to transfer
    }

    struct MaintenanceExecution {
         ControllerTransferData[] cycleSteps;
    }

    struct RolloverExecution {
        PoolTransferData[] poolData;
        ControllerTransferData[] cycleSteps;
        address[] poolsForWithdraw; //Pools to target for manager -> pool transfer
        bool complete; //Whether to mark the rollover complete
        string rewardsIpfsHash;
    }

    event ControllerRegistered(bytes32 id, address controller);
    event ControllerUnregistered(bytes32 id, address controller);
    event PoolRegistered(address pool);
    event PoolUnregistered(address pool);
    event CycleDurationSet(uint256 duration);
    event LiquidityMovedToManager(address pool, uint256 amount);
    event DeploymentStepExecuted(bytes32 controller, address adapaterAddress, bytes data);
    event LiquidityMovedToPool(address pool, uint256 amount);
    event CycleRolloverStarted(uint256 blockNumber);
    event CycleRolloverComplete(uint256 blockNumber);

    function registerController(bytes32 id, address controller) external;

    function registerPool(address pool) external;

    function unRegisterController(bytes32 id) external;

    function unRegisterPool(address pool) external;

    function getPools() external view returns (address[] memory);

    function getControllers() external view returns (bytes32[] memory);

    function setCycleDuration(uint256 duration) external;

    function startCycleRollover() external;

    function executeMaintenance(MaintenanceExecution calldata params) external;

    function executeRollover(RolloverExecution calldata params) external;

    function completeRollover(string calldata rewardsIpfsHash) external;

    function cycleRewardsHashes(uint256 index) external view returns (string memory);

    function getCurrentCycle() external view returns (uint256);

    function getCurrentCycleIndex() external view returns (uint256);

    function getCycleDuration() external view returns (uint256);

    function getRolloverStatus() external view returns (bool);
}