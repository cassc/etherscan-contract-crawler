// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Handler is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address self;

    uint256 private constant WORKER_MAX_TASK_COUNT = 10;

    struct DepositInfo {
        // Sender address on source chain
        address sender;
        // Deposit token
        address token;
        // Recipient address on dest chain
        bytes recipient;
        // Deposit amount
        uint256 amount;
    }

    struct Call {
        // The call metadata
        address target;
        bytes callData;
        uint256 value;

        // The settlement metadata
        bool needSettle;
        uint256 updateOffset;
        uint256 updateLen;
        address spender;
        address spendAsset;
        uint256 spendAmount;
        address receiveAsset;
        // The call index that whose result will be the input of call
        uint256 inputCall;
        // Current call index
        uint256 callIndex;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    // taskId => DepositInfo
    mapping(bytes32 => DepositInfo) public _depositRecords;
    // workerAddress => taskId[]
    mapping(address => bytes32[]) public _activedTasks;
    // workerAddress => activedTaskIndex
    mapping(address => uint) public _activedTaskIndexs;
    // workerAddress => isWorker
    mapping(address => bool) public _workers;
    // Address to represent the native asset, default is address(0)
    address public nativeAsset = address(0);

    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        bytes recipient
    );

    event Claimed(address indexed worker, bytes32 indexed taskId);
    event ClaimedAndExecuted(address indexed worker, bytes32 indexed taskId);
    event Dropped(address indexed worker, bytes32 indexed taskId);

    modifier onlyWorker() {
        require(_workers[_msgSender()], 'Not worker');
        _;
    }

    constructor() {
        self = address(this);
    }

    receive() external payable  {}

    function setMultiWorkers(address[] memory workers) external onlyOwner {
        require(workers.length < 100, 'Too many workers');
        for (uint i = 0; i < workers.length; i++) {
            _workers[workers[i]] = true;
        }
    }

    function setWorker(address worker) external onlyOwner {
        _workers[worker] = true;
    }

    function removeWorker(address worker) external onlyOwner {
        _workers[worker] = false;
    }

    function setNative(address native) external onlyOwner {
        nativeAsset = native;
    }

    // Temporary transfer asset to contract and save the corresponding task data
    function deposit(
        address token,
        uint256 amount,
        bytes memory recipient,
        address worker,
        bytes32 taskId
    ) external payable whenNotPaused nonReentrant {
        require(amount > 0, 'Zero transfer');
        require(recipient.length > 0, 'Illegal recipient data');
        require(worker != address(0), 'Illegal worker address');
        require(
            _depositRecords[taskId].amount == 0,
            'Duplicate task'
        );
        require(
            (activedTaskCount(worker)) < WORKER_MAX_TASK_COUNT,
            'Too many tasks'
        );

        if (token == nativeAsset) {
            require(msg.value == amount, 'Mismatch in transfer amount');
        } else {
            uint256 preBalance = IERC20(token).balanceOf(self);
            // Transfer from sender to contract
            IERC20(token).safeTransferFrom(msg.sender, self, amount);
            uint256 postBalance = IERC20(token).balanceOf(self);
            require(postBalance.sub(preBalance) == amount, 'Transfer failed');
        }

        // Put task id to actived task list
        bytes32[] storage tasks = _activedTasks[worker];
        tasks.push(taskId);
        // Save task details
        _depositRecords[taskId] = DepositInfo({
            sender: msg.sender,
            token: token,
            recipient: recipient,
            amount: amount
        });
        emit Deposited(msg.sender, token, amount, recipient);
    }

    // Drop task data and trigger asset beeing transfered back to task depositor
    function drop(bytes32 taskId) external whenNotPaused onlyWorker nonReentrant {
        DepositInfo memory depositInfo = this.findActivedTask(msg.sender, taskId);
        // Check if task is exist
        require(depositInfo.sender != address(0), "Task does not exist");

        // Remove task
        removeTask(msg.sender, taskId);

        // Transfer asset back to task depositor account
        if (depositInfo.token == nativeAsset) {
            (bool sent, bytes memory _data) = depositInfo.sender.call{value: depositInfo.amount}("");
            require(sent, "Failed to send Ether");
        } else {
            require(
                IERC20(depositInfo.token).balanceOf(self) >=
                    depositInfo.amount,
                'Insufficient balance'
            );
            IERC20(depositInfo.token).safeTransfer(depositInfo.sender, depositInfo.amount);
        }

        emit Dropped(msg.sender, taskId);
    }

    // Worker claim last actived task that belong to this worker
    function claim(bytes32 taskId) external whenNotPaused onlyWorker nonReentrant {
        DepositInfo memory depositInfo = this.findActivedTask(msg.sender, taskId);
        // Check if task is exist
        require(depositInfo.sender != address(0), "Task does not exist");

        // Remove task
        removeTask(msg.sender, taskId);

        // Transfer asset to worker account
        if (depositInfo.token == nativeAsset) {
            (bool sent, bytes memory _data) = msg.sender.call{value: depositInfo.amount}("");
            require(sent, "Failed to send Ether");
        } else {
            require(
                IERC20(depositInfo.token).balanceOf(self) >=
                    depositInfo.amount,
                'Insufficient balance'
            );
            IERC20(depositInfo.token).safeTransfer(msg.sender, depositInfo.amount);
        }

        emit Claimed(msg.sender, taskId);
    }

    function claimAndBatchCall(bytes32 taskId, Call[] calldata calls) external payable whenNotPaused onlyWorker nonReentrant {
        DepositInfo memory depositInfo = this.findActivedTask(msg.sender, taskId);
        // Check if task is exist
        require(depositInfo.sender != address(0), "Task does not exist");
        require(calls.length >= 1, 'Too few calls');

        // Check first call
        require(calls[0].spendAsset == address(depositInfo.token), "spendAsset mismatch");
        require(calls[0].spendAmount == depositInfo.amount, "spendAmount mismatch");

        _batchCall(calls);

        // Remove task
        removeTask(msg.sender, taskId);

        emit Claimed(msg.sender, taskId);
    }

    // Worker execute a bunch of calls, make sure handler already hodld enough spendAsset of first call
    function batchCall(Call[] calldata calls) external payable whenNotPaused onlyWorker nonReentrant {
        _batchCall(calls);
    }

    function _batchCall(Call[] calldata calls) internal returns (Result[] memory returnData) {
        uint256 length = calls.length;
        require(length >= 1, 'Too few calls');
        returnData = new Result[](length);
        uint256 [] memory settleAmounts = new uint256[](calls.length);

        for (uint256 i = 0; i < length;) {
            Result memory result = returnData[i];
            Call memory calli = calls[i];

            // update calldata from second call
            if (i > 0) {
                Call memory inputCall = calls[calli.inputCall];

                if (inputCall.needSettle && calli.spendAsset == inputCall.receiveAsset) {
                    // Update settleAmount to calldata from offset
                    uint256 settleAmount = settleAmounts[inputCall.callIndex];
                    require(settleAmount > 0, 'Settle amount must be greater than 0');
                    if (calli.spendAsset == nativeAsset) {
                        calli.value = settleAmount;
                    } else {
                        require(calli.updateLen == 32, 'Unsupported update length');
                        bytes memory settleAmountBytes = abi.encodePacked(settleAmount);

                        for(uint j = 0; j < calli.updateLen; j++) {
                            calli.callData[j + calli.updateOffset] = settleAmountBytes[j];
                        }
                        calli.spendAmount = settleAmount;
                    }
                }
            }

            uint256 preBalance;
            uint256 postBalance;
            // Read balance before execution
            if (calli.needSettle) {
                if (calli.receiveAsset == nativeAsset) {
                    preBalance = self.balance;
                } else {
                    preBalance = IERC20(calli.receiveAsset).balanceOf(self);
                }
            }

            // Approve if necessary
            if (calli.spendAsset != nativeAsset && calli.spender != address(0) && calli.spendAsset != address(0)) {
                require(IERC20(calli.spendAsset).approve(calli.spender, calli.spendAmount), "Approve failed");
            }
            // Execute exact call
            (result.success, result.returnData) = calli.target.call{value: calli.value}(calli.callData);
            require(result.success, string(abi.encodePacked(string("Call failed: "), string(result.returnData))));
            unchecked {
                ++i;
            }

            // Settle balance after execution
            if (calli.needSettle) {
                if (calli.receiveAsset == nativeAsset) {
                    postBalance = self.balance;
                } else {
                    postBalance = IERC20(calli.receiveAsset).balanceOf(self);
                }
                settleAmounts[calli.callIndex] = postBalance.sub(preBalance);
            }
        }
    }

    function findActivedTask(address worker, bytes32 taskId) public view returns (DepositInfo memory depositInfo) {
        bytes32[] memory tasks = _activedTasks[worker];
        uint checkIndex = 0;
        for (; checkIndex < tasks.length; checkIndex++) {
            if (taskId == tasks[checkIndex]) return _depositRecords[taskId];
        }
        return depositInfo;
    }

    function getNextActivedTask(address worker)
        public
        view
        returns (bytes32)
    {
        return nextActivedTask(worker);
    }

    function getActivedTasks(address worker)
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory tasks = _activedTasks[worker];
        bytes32[] memory activedTasks = new bytes32[](activedTaskCount(worker));
        uint currentIndex = _activedTaskIndexs[worker];
        for (uint i = currentIndex; i < tasks.length; i++) {
            activedTasks[i - currentIndex] = tasks[i];
        }
        return activedTasks;
    }

    function getTaskData(bytes32 taskId)
        public
        view
        returns (DepositInfo memory)
    {
        return _depositRecords[taskId];
    }

    function removeTask(address worker, bytes32 taskId) internal {
        require(nextActivedTask(worker) == taskId, "Task not actived");

        // Simplly increase the index
        _activedTaskIndexs[worker] += 1;
    }

    function nextActivedTask(address worker) internal view returns (bytes32) {
        bytes32[] memory task = _activedTasks[worker];
        uint nextIndex = _activedTaskIndexs[worker];
        if (task.length > nextIndex) {
            return task[nextIndex];
        } else {
            return bytes32(0);
        }
    }

    function activedTaskCount(address worker) internal view returns (uint) {
        return _activedTasks[worker].length.sub(_activedTaskIndexs[worker]);
    }
}