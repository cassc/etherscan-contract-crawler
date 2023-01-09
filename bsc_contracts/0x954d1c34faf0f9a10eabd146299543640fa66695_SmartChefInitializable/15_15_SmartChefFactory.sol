// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SmartChefInitializable.sol";

contract SmartChefFactory is Ownable {
    event NewSmartChefContract(address indexed smartChef);

    constructor() {
        //
    }

    /*
     * @notice Deploy the pool
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerSecond: reward per second (in rewardToken)
     * @param _startTime: start time
     * @param _endTime: end time
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _admin: admin address with ownership
     * @return address of new smart chef contract
     */
    function deployPool(
        IERC20 _stakedToken,
        IERC20Extended _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTime,
        uint256 _bonusEndTime,
        uint256 _poolLimitPerUser,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardToken.totalSupply() >= 0);
        require(_stakedToken != _rewardToken, "Tokens must be be different");

        bytes memory bytecode = type(SmartChefInitializable).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startTime));
        address smartChefAddress;

        assembly {
            smartChefAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        SmartChefInitializable(smartChefAddress).initialize(
            _stakedToken,
            _rewardToken,
            _rewardPerSecond,
            _startTime,
            _bonusEndTime,
            _poolLimitPerUser,
            _admin
        );

        emit NewSmartChefContract(smartChefAddress);
    }
}