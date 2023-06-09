// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/INativePoolFactory.sol";
import "../interfaces/INativePool.sol";

/// @notice Provides validation for callbacks from Native Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Native Pool
    /// @param factory The contract address of the Native factory
    /// @param pool The contract address of a Pool
    /// @return verifiedPool The Native pool contract address
    function verifyCallback(address factory, address pool) internal view returns (INativePool) {
        require(INativePoolFactory(factory).verifyPool(pool), "Invalid pool address");
        return INativePool(pool);
    }
}