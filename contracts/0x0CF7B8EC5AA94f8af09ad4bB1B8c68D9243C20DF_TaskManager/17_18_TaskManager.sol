// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IProject.sol";
import "./interfaces/IReward.sol";
import "./interfaces/IClaimPool.sol";
import "./interfaces/ITaskManager.sol";
import "./Validatable.sol";

/**
 *  @title  Dev Non-fungible token
 *
 *  @author IHeart Team
 *
 *  @notice This smart contract TaskManager.
 */

contract TaskManager is Validatable, ITaskManager, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     *  @notice _taskCounter uint256 (counter). This is the counter for store
     *          current task ID value in storage.
     */
    CountersUpgradeable.Counter private _taskCounter;

    /**
     *  @notice project is address of project manager
     */
    IProject public project;

    /**
     *  @notice address verify message of function approveReward
     */
    address public verifier;

    /**
     *  @notice mapping from task ID to TaskInfo
     */
    mapping(uint256 => TaskInfo) public tasks;

    /**
     *  @notice mapping address to list task ID
     */
    mapping(address => EnumerableSetUpgradeable.UintSet) private _taskOfCollection;

    /**
     *  @notice mapping task Id to user address to complete task
     */
    mapping(uint256 => mapping(address => bool)) public isPay;

    event SetVerifier(address indexed oldValue, address indexed newValue);
    event CreatedTask(uint256 indexed taskId, string idOffChain, TaskInfo taskInfo);
    event UpdatedTask(
        uint256 indexed taskId,
        uint256 indexed projectId,
        address indexed collection,
        uint256 budget,
        uint256 startTime,
        uint256 endTime
    );
    event ApprovedReward(
        uint256 indexed taskId,
        uint256 indexed projectId,
        address indexed collection,
        address[] users,
        uint256[] rewards
    );
    event CancelledTask(uint256 indexed taskId, address indexed collection, uint256 remainingBudget);
    event CompletedTask(uint256 indexed taskId, address indexed collection, uint256 remainingBudget);

    /**
     * Throw an exception if task id is not valid
     */
    modifier validTaskId(uint256 taskId) {
        require(taskId > 0 && taskId <= _taskCounter.current(), "Invalid taskId");
        _;
    }

    /**
     * @notice Initialize new logic contract.
     * @dev Replace for constructor function
     * @param _admin Address of admin contract
     * @param _project Address of project contract
     * @param _verifier Address of user verify
     */
    function initialize(
        IAdmin _admin,
        IProject _project,
        address _verifier
    ) public initializer notZeroAddress(address(_admin)) notZeroAddress(address(_project)) {
        __ReentrancyGuard_init();
        __Validatable_init(_admin);
        project = _project;
        verifier = _verifier;

        if (project.taskManager() == address(0)) {
            project.registerTaskManager();
        }
    }

    /**
     * @notice Set address verify
     *
     * @dev    Only owner or admin can call this function.
     *
     * @param  _verifier   Address of verify message.
     *
     * emit {SetVerifier} events
     */
    function setVerifier(address _verifier) external onlyAdmin notZeroAddress(_verifier) {
        require(_verifier != verifier, "Verifier already exists");

        address _oldValue = verifier;
        verifier = _verifier;
        emit SetVerifier(_oldValue, verifier);
    }

    /**
     * @notice Create task.
     * @dev    Only project owner can call this function.
     * @param idOffChain Chain id
     * @param projectId Id of project
     * @param collection Address of collection
     * @param startTime Time to start task
     * @param endTime Time to end task
     * @param budget Budget of task
     *
     * emit {CreatedTask} events
     */
    function createTask(
        string memory idOffChain,
        uint256 projectId,
        address collection,
        uint256 startTime,
        uint256 endTime,
        uint256 budget
    ) external notZero(budget) {
        require(bytes(idOffChain).length > 0, "Invalid idOffChain");
        require(startTime > block.timestamp, "Invalid startTime");
        require(startTime < endTime, "Invalid endTime");

        ProjectInfo memory projectInfo = checkValidProject(projectId, collection);
        require(projectInfo.projectOwner == _msgSender(), "Caller is not project owner");
        require(budget <= IClaimPool(projectInfo.claimPool).getFreeBudget(collection), "Over collection budget");

        _taskCounter.increment();
        tasks[_taskCounter.current()] = TaskInfo({
            idOffChain: idOffChain,
            projectId: projectId,
            collection: collection,
            budget: budget,
            totalSpent: 0,
            status: StatusTask.ACTIVE,
            startTime: startTime,
            endTime: endTime
        });
        //slither-disable-next-line unused-return
        _taskOfCollection[collection].add(_taskCounter.current());
        IClaimPool(projectInfo.claimPool).addBudgetUse(collection, budget);
        emit CreatedTask(_taskCounter.current(), idOffChain, tasks[_taskCounter.current()]);
    }

    /**
     * @notice Update task while task is active.
     * @dev    Only project owner can call this function.
     * @param taskId Id of task
     * @param projectId Id of project
     * @param collection Addresss of collection
     * @param startTime Time to start task
     * @param endTime Time to end task
     * @param budget Budget of task
     *
     * emit {UpdatedTask} events
     */
    //slither-disable-next-line reentrancy-no-eth
    function updateTask(
        uint256 taskId,
        uint256 projectId,
        address collection,
        uint256 startTime,
        uint256 endTime,
        uint256 budget
    ) external validTaskId(taskId) notZero(budget) {
        require(startTime > 0 && startTime < endTime, "Invalid Time");
        TaskInfo storage taskInfo = tasks[taskId];
        require(taskInfo.status == StatusTask.ACTIVE, "Task was done or cancel");

        ProjectInfo memory projectInfo = checkValidProject(projectId, collection);
        require(projectInfo.projectOwner == _msgSender(), "Caller is not project owner");

        if (taskInfo.collection != collection) {
            //slither-disable-next-line unused-return
            _taskOfCollection[taskInfo.collection].remove(taskId);
            //slither-disable-next-line unused-return
            _taskOfCollection[collection].add(taskId);

            require(budget <= IClaimPool(projectInfo.claimPool).getFreeBudget(collection), "Over collection budget");
            IClaimPool(projectInfo.claimPool).reduceBudgetUse(
                taskInfo.collection,
                taskInfo.budget - taskInfo.totalSpent
            );
            IClaimPool(projectInfo.claimPool).addBudgetUse(collection, budget);
        } else {
            if (budget > taskInfo.budget) {
                require(
                    budget - taskInfo.budget <= IClaimPool(projectInfo.claimPool).getFreeBudget(collection),
                    "Over collection budget"
                );
                IClaimPool(projectInfo.claimPool).addBudgetUse(collection, budget - taskInfo.budget);
            } else if (budget < taskInfo.budget) {
                require(budget >= taskInfo.totalSpent, "Under collection spent");
                IClaimPool(projectInfo.claimPool).reduceBudgetUse(collection, taskInfo.budget - budget);
            }
        }

        taskInfo.projectId = projectId;
        taskInfo.collection = collection;
        taskInfo.budget = budget;
        taskInfo.startTime = startTime;
        taskInfo.endTime = endTime;

        emit UpdatedTask(taskId, projectId, collection, budget, startTime, endTime);
    }

    /**
     * @notice Change task status while task is active.
     * @dev    Only project owner or contract owner can call this function.
     * @param taskId Id of the task
     *
     * emit {CancelledTask} events
     */
    function cancelTask(uint256 taskId) external validTaskId(taskId) {
        TaskInfo storage taskInfo = tasks[taskId];
        uint256 remainingBudget = _changeStatus(taskId, taskInfo, StatusTask.CANCEL);

        emit CancelledTask(taskId, taskInfo.collection, remainingBudget);
    }

    /**
     * @notice Change status to completed
     * @dev    Only project owner or contract owner can call this function
     * @param taskId Id of task
     *
     * emit {CompletedTask} events
     */
    function completeTask(uint256 taskId) external validTaskId(taskId) {
        TaskInfo storage taskInfo = tasks[taskId];
        uint256 remainingBudget = _changeStatus(taskId, taskInfo, StatusTask.DONE);

        emit CompletedTask(taskId, taskInfo.collection, remainingBudget);
    }

    /**
     * @notice Approve reward to user
     * @dev    Only project owner or contract owner can call this function
     * @param taskId Id of task
     * @param users List of users completed this task
     * @param rewards List rewards for users
     *
     * emit {ApprovedReward} events
     */
    function approveReward(
        uint256 taskId,
        address[] memory users,
        uint256[] memory rewards,
        uint256 nonce,
        bytes memory signature
    ) external nonReentrant validTaskId(taskId) {
        require(users.length > 0 && users.length == rewards.length, "Invalid length");
        require(verifyMessage(taskId, users, rewards, nonce, signature), "Invalid signature");

        TaskInfo storage taskInfo = tasks[taskId];
        require(taskInfo.status == StatusTask.ACTIVE, "Task was done or cancel");

        ProjectInfo memory projectInfo = checkValidProject(taskInfo.projectId, tasks[taskId].collection);
        require(
            projectInfo.projectOwner == _msgSender() || admin.owner() == _msgSender(),
            "Caller is not owner or project owner"
        );

        uint256 spentBudget;
        for (uint256 i = 0; i < users.length; ++i) {
            require(users[i] != address(0), "Invalid address");
            require(!isPay[taskId][users[i]], "Already paid");
            require(rewards[i] > 0, "Invalid reward");
            isPay[taskId][users[i]] = true;
            spentBudget = spentBudget + rewards[i];
        }

        taskInfo.totalSpent = taskInfo.totalSpent + spentBudget;
        require(taskInfo.totalSpent <= taskInfo.budget, "Overflow budget");

        // Create pool for reward
        IReward(project.rewardAddress()).releaseReward(projectInfo.paymentToken, users, rewards);

        // Transfer token to reward pool
        IClaimPool(projectInfo.claimPool).transferToReward(taskInfo.collection, spentBudget);

        emit ApprovedReward(taskId, projectInfo.projectId, taskInfo.collection, users, rewards);
    }

    /**
     * @notice Check valid project
     * @param projectId Id of project
     * @param collection address of collection
     *
     */
    function checkValidProject(uint256 projectId, address collection) private view returns (ProjectInfo memory) {
        uint256 _projectId = project.collectionToProjects(collection);
        require(projectId == _projectId, "Invalid collection");
        ProjectInfo memory projectInfo = project.getProjectById(_projectId);
        require(projectInfo.status, "Invalid project");
        return projectInfo;
    }

    /**
     * @notice change status of task
     * @param taskId id of task
     * @param taskInfo info of task
     *
     */
    function _changeStatus(uint256 taskId, TaskInfo storage taskInfo, StatusTask status) private returns (uint256) {
        require(taskInfo.status == StatusTask.ACTIVE, "Task was done or cancel");

        ProjectInfo memory projectInfo = checkValidProject(taskInfo.projectId, taskInfo.collection);
        require(
            projectInfo.projectOwner == _msgSender() || admin.owner() == _msgSender(),
            "Caller is not owner or project owner"
        );

        taskInfo.status = status;
        //slither-disable-next-line unused-return
        _taskOfCollection[taskInfo.collection].remove(taskId);

        uint256 remainingBudget = 0;
        if (taskInfo.totalSpent < taskInfo.budget) {
            remainingBudget = taskInfo.budget - taskInfo.totalSpent;
            IClaimPool(projectInfo.claimPool).reduceBudgetUse(taskInfo.collection, remainingBudget);
        }

        return remainingBudget;
    }

    /**
     * @notice Verify message
     * @dev    Everyone can call this function
     * @param taskId Id of task
     * @param users List of users completed this task
     * @param rewards List rewards for users
     * @param nonce nonce of transaction
     * @param signature signature of transaction
     */
    function verifyMessage(
        uint256 taskId,
        address[] memory users,
        uint256[] memory rewards,
        uint256 nonce,
        bytes memory signature
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        bytes32 dataHash = encodeData(taskId, users, rewards, nonce);
        bytes32 signHash = ECDSA.toEthSignedMessageHash(dataHash);
        address recovered = ECDSA.recover(signHash, signature);
        return recovered == verifier;
    }

    /**
     * @notice EncodeData
     * @dev    Everyone can call this function
     * @param taskId Id of task
     * @param users List of users completed this task
     * @param rewards List rewards for users
     * @param nonce nonce of transaction
     */
    function encodeData(
        uint256 taskId,
        address[] memory users,
        uint256[] memory rewards,
        uint256 nonce
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return keccak256(abi.encode(id, taskId, users, rewards, nonce));
    }

    // Get function
    /**
     *
     *  @notice Get task counter
     *
     *  @dev    All caller can call this function.
     */
    function getTaskCounter() external view returns (uint256) {
        return _taskCounter.current();
    }

    /**
     *  @notice Check valid task for mint nft
     *
     *  @dev    All caller can call this function.
     */
    function checkValidTaskId(uint256 taskId) external view returns (bool) {
        return taskId > 0 && taskId <= _taskCounter.current() && tasks[taskId].status == StatusTask.ACTIVE;
    }

    /**
     *  @notice Check valist task of collection
     *
     *  @dev    All caller can call this function.
     */
    function isValidTaskOf(address collection) public view returns (bool) {
        return _taskOfCollection[collection].length() > 0;
    }
}