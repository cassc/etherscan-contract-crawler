// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ILoanManagerInitializer {

    /**
     *  @dev   Emitted when the loan manager is initialized.
     *  @param poolManager_ Address of the associated pool manager.
     */
    event Initialized(address indexed poolManager_);

    /**
     *  @dev    Decodes the initialization arguments of a loan manager.
     *  @param  calldata_    ABI encoded address of the pool manager.
     *  @return poolManager_ Address of the pool manager.
     */
    function decodeArguments(bytes calldata calldata_) external pure returns (address poolManager_);

    /**
     *  @dev    Encodes the initialization arguments of a loan manager.
     *  @param  poolManager_ Address of the pool manager.
     *  @return calldata_    ABI encoded address of the pool manager.
     */
    function encodeArguments(address poolManager_) external pure returns (bytes memory calldata_);

}