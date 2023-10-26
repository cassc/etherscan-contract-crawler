// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../interfaces/IGyroConfig.sol";
import "./GyroConfigKeys.sol";

library GyroConfigHelpers {
    function getSwapFeePercForPool(
        IGyroConfig gyroConfig,
        address poolAddress,
        bytes32 poolType
    ) internal view returns (uint256) {
        return _getPoolSetting(gyroConfig, GyroConfigKeys.PROTOCOL_SWAP_FEE_PERC_KEY, poolType, poolAddress);
    }

    function getProtocolFeeGyroPortionForPool(
        IGyroConfig gyroConfig,
        address poolAddress,
        bytes32 poolType
    ) internal view returns (uint256) {
        return _getPoolSetting(gyroConfig, GyroConfigKeys.PROTOCOL_FEE_GYRO_PORTION_KEY, poolType, poolAddress);
    }

    function _getPoolSetting(
        IGyroConfig gyroConfig,
        bytes32 globalKey,
        bytes32 poolType,
        address poolAddress
    ) internal view returns (uint256) {
        bytes32 poolSpecificKey = keccak256(abi.encode(globalKey, poolAddress));

        // Fetch the key. To do this we first check for a pool-specific fee,
        // and if not present, use the pool-type key.
        // Failing that we fall back to the global setting.
        if (gyroConfig.hasKey(poolSpecificKey)) {
            return gyroConfig.getUint(poolSpecificKey);
        }

        bytes32 poolTypeKey = keccak256(abi.encodePacked(globalKey, poolType));
        if (gyroConfig.hasKey(poolTypeKey)) {
            return gyroConfig.getUint(poolTypeKey);
        }

        return gyroConfig.getUint(globalKey);
    }
}