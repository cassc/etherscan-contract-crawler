// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IPoolGauge.sol";

contract GaugeFactory is Ownable2Step {
    event PoolGaugeCreated(address indexed lpAddr, address indexed poolGauge, uint);
    event SetPermit2Address(address oldAddress, address newAddress);
    event SetGaugeOwner(address);
    event SetOperator(address);
    event SetPoolGaugeImplementation(address);

    address public immutable miner;
    address public poolGaugeImplementation;
    address public permit2;
    address public gaugeOwner;
    address public operator;

    // lpToken => poolGauge
    mapping(address => address) public getPool;
    address[] public allPools;

    constructor(address _poolGaugeImplementation, address _minter, address _permit2Address) {
        require(_poolGaugeImplementation != address(0), "CE000");
        require(_minter != address(0), "CE000");
        gaugeOwner = _msgSender();
        operator = _msgSender();
        poolGaugeImplementation = _poolGaugeImplementation;
        miner = _minter;
        permit2 = _permit2Address;
    }

    function createPool(address _lpAddr) external returns (address pool) {
        require(_msgSender() == operator || _msgSender() == owner(), "GF000");
        bytes32 salt = keccak256(abi.encodePacked(_lpAddr));
        pool = Clones.cloneDeterministic(poolGaugeImplementation, salt);
        IPoolGauge(pool).initialize(_lpAddr, miner, permit2, gaugeOwner);
        getPool[_lpAddr] = pool;
        allPools.push(pool);
        emit PoolGaugeCreated(_lpAddr, pool, allPools.length);
    }

    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2;
        permit2 = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    function setGaugeOwner(address _gaugeOwner) external onlyOwner {
        require(_gaugeOwner != address(0), "CE000");
        gaugeOwner = _gaugeOwner;
        emit SetGaugeOwner(_gaugeOwner);
    }

    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "CE000");
        operator = _operator;
        emit SetOperator(_operator);
    }

    function setPoolGaugeImplementation(address _gaugeAddress) external onlyOwner {
        require(_gaugeAddress != address(0), "CE000");
        poolGaugeImplementation = _gaugeAddress;
        emit SetPoolGaugeImplementation(_gaugeAddress);
    }
}