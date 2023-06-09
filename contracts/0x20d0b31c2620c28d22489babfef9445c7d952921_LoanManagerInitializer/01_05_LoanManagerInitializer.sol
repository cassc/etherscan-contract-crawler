// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILoanManagerInitializer }                                from "./interfaces/ILoanManagerInitializer.sol";
import { IGlobalsLike, IMapleProxyFactoryLike, IPoolManagerLike } from "./interfaces/Interfaces.sol";

import { LoanManagerStorage } from "./LoanManagerStorage.sol";

contract LoanManagerInitializer is ILoanManagerInitializer, LoanManagerStorage {

    function decodeArguments(bytes calldata calldata_) public pure override returns (address poolManager_) {
        poolManager_ = abi.decode(calldata_, (address));
    }

    function encodeArguments(address poolManager_) external pure override returns (bytes memory calldata_) {
        calldata_ = abi.encode(poolManager_);
    }

    function _initialize(address poolManager_) internal {
        _locked = 1;

        address factory_ = IPoolManagerLike(poolManager_).factory();
        address globals_ = IMapleProxyFactoryLike(msg.sender).mapleGlobals();

        require(IGlobalsLike(globals_).isInstanceOf("POOL_MANAGER_FACTORY", factory_), "LMI:I:INVALID_PM_FACTORY");
        require(IMapleProxyFactoryLike(factory_).isInstance(poolManager_),             "LMI:I:INVALID_PM_INSTANCE");

        // Since `poolManager` is a valid instance, `fundsAsset` must also be valid due to the pool manager initializer.
        fundsAsset = IPoolManagerLike(
            poolManager = poolManager_
        ).asset();

        emit Initialized(poolManager);
    }

    fallback() external {
        _initialize(decodeArguments(msg.data));
    }

}