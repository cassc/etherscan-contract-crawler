// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Request Board Reporter interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardReporter {
    /// Reports the Witnet-provided result to a previously posted request. 
    /// @dev Will assume `block.timestamp` as the timestamp at which the request was solved.
    /// @dev Fails if:
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique identifier of the data request.
    /// @param _drTxHash The hash of the corresponding data request transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(
            uint256 _queryId,
            bytes32 _drTxHash,
            bytes calldata _result
        ) external;

    /// Reports the Witnet-provided result to a previously posted request.
    /// @dev Fails if:
    /// @dev - called from unauthorized address;
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique query identifier
    /// @param _timestamp The timestamp of the solving tally transaction in Witnet.
    /// @param _drTxHash The hash of the corresponding data request transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(
            uint256 _queryId,
            uint256 _timestamp,
            bytes32 _drTxHash,
            bytes calldata _result
        ) external;

    /// Reports Witnet-provided results to multiple requests within a single EVM tx.
    /// @dev Must emit a PostedResult event for every succesfully reported result.
    /// @param _batchResults Array of BatchResult structs, every one containing:
    ///         - unique query identifier;
    ///         - timestamp of the solving tally txs in Witnet. If zero is provided, EVM-timestamp will be used instead;
    ///         - hash of the corresponding data request tx at the Witnet side-chain level;
    ///         - data request result in raw bytes.
    /// @param _verbose If true, must emit a BatchReportError event for every failing report, if any. 
    function reportResultBatch(BatchResult[] calldata _batchResults, bool _verbose) external;
        
        struct BatchResult {
            uint256 queryId;
            uint256 timestamp;
            bytes32 drTxHash;
            bytes   cborBytes;
        }

        event BatchReportError(uint256 queryId, string reason);
}