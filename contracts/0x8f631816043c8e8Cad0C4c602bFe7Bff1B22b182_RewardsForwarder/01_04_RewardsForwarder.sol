// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";
import { Owners } from "./Owners.sol";

contract RewardsForwarder is Owners, ReentrancyGuard {
    using SafeTransferLib for address;

    event LastBlockSet(uint256 lastBlock);
    event RewardPerBlockSet(uint256 rewardPerBlock);
    event AddressesSet(address token, address target, address operator);

    uint256 public lastBlock;
    uint256 public rewardPerBlock;
    address public token;
    address public target;
    address public operator;

    constructor(uint256 _rewardPerBlock, address _token, address _target, address _operator, address _initialOwner) {
        _setOwner(_initialOwner, true);
        lastBlock = block.number;
        rewardPerBlock = _rewardPerBlock;
        token = _token;
        target = _target;
        operator = _operator;
    }

    modifier isOperator() {
        require(operator == msg.sender, "Not operator");
        _;
    }

    function sendRewards() external isOperator nonReentrant {
        uint256 amount = (block.number - lastBlock) * rewardPerBlock;
        lastBlock = block.number;
        token.safeTransfer(target, amount);
    }

    function setLastBlock(uint256 _lastBlock) external isOwner {
        lastBlock = _lastBlock;
        emit LastBlockSet(_lastBlock);
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external isOwner {
        rewardPerBlock = _rewardPerBlock;
        emit RewardPerBlockSet(_rewardPerBlock);
    }

    function setAddresses(address _token, address _target, address _operator) external isOwner {
        token = _token;
        target = _target;
        operator = _operator;
        emit AddressesSet(_token, _target, _operator);
    }

    function withdrawTokens(uint256 amount) external isOwner nonReentrant {
        token.safeTransfer(msg.sender, amount);
    }
}