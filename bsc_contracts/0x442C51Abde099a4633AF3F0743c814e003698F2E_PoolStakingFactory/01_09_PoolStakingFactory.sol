// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./imports/IBEP20.sol";
import "./PoolStakingLock.sol";

contract PoolStakingFactory is Ownable {
    event NewPoolStakingLockContract(address indexed poolstaking);

    constructor() {
        //
    }

    /*
     * @notice Deploy the pool
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _endBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _poolLimitGlobal: pool limit global in stakedToken (if any, else 0)
     * @param _poolMinDeposit: pool minimal limit for deposited amount
     * @param _poolHarvestLock: pool Harvest is locked (if true is enable, else false is disable)
     * @param _poolWithdrawLock: pool Withdraw is locked (if true is enable, else false is disable)
     * @param _admin: admin address with ownership
     * @return address of new smart chef contract
     */
    function deployPool(
        IBEP20 _stakedToken,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        uint256 _poolLimitGlobal,
        uint256 _poolMinDeposit,
        bool _poolHarvestLock,
        bool _poolWithdrawLock,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardToken.totalSupply() >= 0);

        bytes memory bytecode = type(PoolStakingLock).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(
                _stakedToken,
                _rewardToken,
                _startBlock,
                block.number
            )
        );
        address poolstakingAddress;

        assembly {
            poolstakingAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        PoolStakingLock(poolstakingAddress).initialize(
            _stakedToken,
            _rewardToken,
            _rewardPerBlock,
            _startBlock,
            _bonusEndBlock,
            _poolLimitPerUser,
            _poolLimitGlobal,
            _poolMinDeposit,
            _poolHarvestLock,
            _poolWithdrawLock,
            _admin
        );

        emit NewPoolStakingLockContract(poolstakingAddress);
    }
}