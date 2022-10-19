// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import "./IConvertibleBondBox.sol";

/**
 * @notice Interface for Convertible Bond Box factory contracts
 */

interface IStagingBoxFactory {
    event StagingBoxCreated(
        address msgSender,
        address stagingBox,
        address slipFactory
    );

    event StagingBoxReplaced(
        IConvertibleBondBox convertibleBondBox,
        address msgSender,
        address oldStagingBox,
        address newStagingBox,
        address slipFactory
    );

    /// @notice Some parameters are invalid
    error InvalidParams();
}