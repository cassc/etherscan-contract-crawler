// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './PoolInstanceV2.sol';

contract PoolFactoryV2 is Ownable {
    event NewPoolInstance(address indexed pool);

    /*
     * @notice Deploy the pool
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _endBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _admin: admin address with ownership
     * @return address of new smart chef contract
     */
    function deployPool(
        IERC20 _stakedToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0 && _rewardToken.totalSupply() >= 0);

        bytes memory bytecode = type(PoolInstanceV2).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startBlock));
        address poolInstanceAddress;

        assembly {
            poolInstanceAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        PoolInstanceV2(poolInstanceAddress).initialize(
            _stakedToken,
            _rewardToken,
            _rewardPerBlock,
            _startBlock,
            _bonusEndBlock,
            _poolLimitPerUser,
            _admin
        );
        
        emit NewPoolInstance(poolInstanceAddress);
    }
}