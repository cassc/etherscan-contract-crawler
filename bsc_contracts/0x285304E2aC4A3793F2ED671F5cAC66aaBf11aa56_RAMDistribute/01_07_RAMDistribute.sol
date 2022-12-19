// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract RAMDistribute is Ownable {
    
    address public immutable ramTokenAddress;

    uint256 public distributeTimes;
    uint256 public distributeCounter;
    uint256 public secondPerBlock;
    uint256 public lastDistributeBlockNum;

    event DistributeTest(address account, uint256 amount);

    constructor(
        address _ramTokenAddress
    ) {
        secondPerBlock = 3;
        distributeTimes = 100;
        ramTokenAddress = _ramTokenAddress;
    }

    function setSecondPerBlock(uint256 _secondPerBlock) external onlyOwner {
        secondPerBlock = _secondPerBlock;
    }

    function setLastDistributeBlockNum(uint256 _lastDistributeBlockNum) external onlyOwner {
        lastDistributeBlockNum = _lastDistributeBlockNum;
    }

    function setDistributeTimes(uint256 _distributeTimes) external onlyOwner {
        distributeTimes = _distributeTimes;
    }

    function distribute(address[] memory tos, uint256[] memory amounts) external onlyOwner {
        require(block.number > (lastDistributeBlockNum + _blockPerDay()));
        lastDistributeBlockNum = block.number;

        uint256 length = tos.length;
        require(length == amounts.length, "length mismatch");

        distributeCounter++;
        for (uint256 index = 0; index < length; index++) {
           SafeERC20.safeTransferFrom(IERC20(ramTokenAddress), msg.sender, tos[index], amounts[index]);
        }
    }

    function distributeAble(uint256 _currentBlockNum) external view returns (bool) {
        return distributeTimes > distributeCounter && _currentBlockNum > lastDistributeBlockNum + _blockPerDay();
    }

    function blockPerDay() external view returns (uint256) {
        return _blockPerDay();
    }

    function _blockPerDay() private view returns (uint256) {
        return 1 days / secondPerBlock;
    }
}