// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./StakingPool.sol";

contract StakingPoolFactory {
    /// The address supposed to get the protocol fee
    address public feeTo;

    /// address that can set the address
    address public feeToSetter;

    ///  mapping from Token => Pool address
    mapping(address => address) public getPool;
    address[] public allPools;

    event PoolCreated(address indexed token, address pool, uint256 timeStamp);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(address stoken, address rtoken)
        external
        returns (address)
    {
        require(stoken != address(0), "ZERO_ADDRESS");
        require(getPool[stoken] == address(0), "PAIR_EXISTS");

        StakingPool _pool = new StakingPool(stoken, rtoken);

        getPool[stoken] = address(_pool);
        allPools.push(address(_pool));
        emit PoolCreated(stoken, address(_pool), block.timestamp);
        return address(_pool);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}