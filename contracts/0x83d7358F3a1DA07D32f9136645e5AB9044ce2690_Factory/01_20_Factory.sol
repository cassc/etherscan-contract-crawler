// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./Pool.sol";
import "./interfaces/IPool.sol";

contract Factory is Initializable, OwnableUpgradeable {
    //---------------------------------VARIABLES------------------------------------------

    mapping(uint256 => IPool) public pools; // poolId -> PoolInfo
    address[] public allPools;
    address public router;
    address internal zkAdmin;

    function initialize(address router_, address zkAdmin_) public initializer {
        __Ownable_init();

        require(router_ != address(0), "Factory: router cannot be zero address");

        require(zkAdmin_ != address(0), "Factory: zkAdmin cannot be zero address");

        router = router_;
        zkAdmin = zkAdmin_;
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(uint256 poolId_, address token_, uint8 sharedDecimals_, uint8 localDecimals_)
        public
        onlyOwner
        returns (address poolAddress)
    {
        require(address(pools[poolId_]) == address(0x0), "Factory: Pool already created");

        Pool impl = new Pool();
        bytes memory payload = abi.encodeWithSignature(
            "initialize(uint256,address,address,uint8,uint8)", poolId_, router, token_, sharedDecimals_, localDecimals_
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), zkAdmin, payload);
        poolAddress = address(proxy);

        pools[poolId_] = IPool(poolAddress);
        allPools.push(poolAddress);
    }
}