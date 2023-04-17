// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IBabyWonderlandMintable.sol";
import "../core/SafeOwnable.sol";
import 'hardhat/console.sol';

contract BabyWonderlandReserve is SafeOwnable {
    using SafeMath for uint256;

    event NewTask(uint taskId, uint totalNum, uint startNftId, uint endNftId, address receiver);
    event DisableTask(uint taskId);
    event OperaterChanged(address operater, bool available);
    event BatchNumChanged(uint oldValue, uint newValue);
    event ProcessTask(uint taskId, uint mintNum, uint startNftId, uint endNftId, uint remain);

    struct Task {
        uint totalNum; 
        uint startNftId;
        uint endNftId;
        uint currentNum;
        address receiver;
        bool available;
    }

    
    IBabyWonderlandMintable immutable babyWonderlandToken;
    Task[] public tasks;
    mapping(address => bool) public operaters;
    uint public batchNum = 300;

    constructor(IBabyWonderlandMintable _nft) {
        babyWonderlandToken = _nft;
    }

    function createTask(uint _totalNum, address _receiver) external onlyOwner returns (uint) {
        require(_totalNum > 0 && _receiver != address(0), "illegal parameter");
        uint currentTotalSupply = babyWonderlandToken.totalSupply();
        uint taskId = tasks.length;
        tasks.push(Task({
            totalNum: _totalNum,
            startNftId: currentTotalSupply + 1,
            endNftId: currentTotalSupply + 1 + _totalNum - 1,
            currentNum: 0,
            receiver: _receiver,
            available: true
        }));
        emit NewTask(taskId, tasks[taskId].totalNum, tasks[taskId].startNftId, tasks[taskId].endNftId, tasks[taskId].receiver);
    }

    function disableTask(uint _taskId) external onlyOwner {
        require(_taskId < tasks.length && tasks[_taskId].available, "illegal taskId");
        tasks[_taskId].available = false;
        emit DisableTask(_taskId);
    }

    function processTask(uint _taskId) external {
        require(operaters[msg.sender] || msg.sender == owner(), "illegal caller");
        require(_taskId < tasks.length, "illegal taskId");
        Task memory task = tasks[_taskId];
        require(task.available && task.currentNum < task.totalNum, "illegal task");
        uint mintNum = task.totalNum - task.currentNum;
        if (mintNum > batchNum) {
            mintNum = batchNum;
        }
        uint expectStartNftId = task.startNftId + task.currentNum - 1;
        require(babyWonderlandToken.totalSupply() == expectStartNftId, "illegal expectStartNftId");
        babyWonderlandToken.batchMint(task.receiver, mintNum);
        uint expectEndNftId = expectStartNftId + mintNum;
        require(babyWonderlandToken.totalSupply() == expectEndNftId, "illegal expectEndNftId");
        tasks[_taskId].currentNum += mintNum;
        require(tasks[_taskId].currentNum <= tasks[_taskId].totalNum && expectEndNftId <= task.endNftId, "illegal process");
        emit ProcessTask(_taskId, mintNum, expectStartNftId + 1, expectEndNftId, tasks[_taskId].totalNum - tasks[_taskId].currentNum);
    }

    function addOperater(address _operater) external onlyOwner {
        operaters[_operater] = true;
        emit OperaterChanged(_operater, true);
    }

    function delOperater(address _operater) external onlyOwner {
        operaters[_operater] = false;
        emit OperaterChanged(_operater, false);
    }

    function setBatchNum(uint _batchNum) external onlyOwner {
        require(_batchNum > 0, "illegal batchNum");
        emit BatchNumChanged(batchNum, _batchNum);
        batchNum = _batchNum;
    }

}