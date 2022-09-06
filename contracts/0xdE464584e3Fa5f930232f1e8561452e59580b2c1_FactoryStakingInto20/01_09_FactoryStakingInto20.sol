// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./Staking20Into20.sol";
import "./Staking20Plus20Into20.sol";

contract FactoryStakingInto20 {
    using SafeERC20 for IERC20;

    IAccessControl public immutable FACTORY;

    modifier onlyAdmin() {
        require(FACTORY.hasRole(0x0, msg.sender));
        _;
    }

    event NewContract(address indexed instance, uint8 instanceType);

    constructor(IAccessControl _factory) {
        FACTORY = _factory;
    }

    function createStaking20Into20(IERC20 _stakeToken, IERC20Metadata _rewardToken, uint256 _startTime, uint256 _endTime, uint256 _rewardPerSecond, uint256 _penaltyPeriod, uint16 _feePercentage) external onlyAdmin {
        Staking20Into20 instance = new Staking20Into20(_stakeToken, _rewardToken, _startTime, _endTime, _rewardPerSecond, _penaltyPeriod, _feePercentage);
        instance.setFeeReceiver(msg.sender);
        IERC20(_rewardToken).safeTransferFrom(msg.sender, address(instance), (_endTime - _startTime) * _rewardPerSecond);
        emit NewContract(address(instance), 0);
    }

    function createStaking20Plus20Into20(IERC20Metadata[2] memory _stakeToken, IERC20Metadata _rewardToken, uint256[2] memory _proportion, uint256 _startTime, uint256 _endTime, uint256 _rewardPerSecond, uint256 _penaltyPeriod, uint16 _feePercentage) external onlyAdmin {
        Staking20Plus20Into20 instance = new Staking20Plus20Into20(_stakeToken, _rewardToken, _proportion, _startTime, _endTime, _rewardPerSecond, _penaltyPeriod, _feePercentage);
        instance.setFeeReceiver(msg.sender);
        IERC20(_rewardToken).safeTransferFrom(msg.sender, address(instance), (_endTime - _startTime) * _rewardPerSecond);
        emit NewContract(address(instance), 1);
    }
}