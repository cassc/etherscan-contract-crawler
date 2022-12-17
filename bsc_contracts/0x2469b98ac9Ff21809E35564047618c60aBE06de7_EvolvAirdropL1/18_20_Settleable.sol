// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./RollupTypes.sol";
import "./BridgeStore.sol";

/// @notice Contract module that allows children to implement
/// state settlement mechanisms.
///
/// A settleable is a contract that has {settle} function
/// and makes state changes to destination resource.
///
/// @dev This module is supposed to be used in layer 1 (settlement layer).

abstract contract Settleable is BridgeStore {
    mapping(uint72 => uint256) private _executedBatches;

    constructor(address bridgeAddress) {
        setBridge(bridgeAddress);
    }

    /// @notice Returns the number of successfully executed batches.
    function executedBatches(uint8 originDomainID, uint64 nonce)
        external
        view
        returns (uint256)
    {
        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);
        return _executedBatches[nonceAndID];
    }

    /// @notice Settles state changes.
    ///
    /// @notice Requirements:
    /// - {_settleable} must be true.
    /// - It must be called only by the bridge.
    /// - Batch index must be valid.
    /// - Merkle proof must be verified.
    function settle(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32[] calldata proof,
        bytes32 rootHash,
        bytes calldata data
    ) external {
        require(msg.sender == getBridge(), "Settleable: not from bridge");

        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);

        (uint64 batchIndex, KeyValuePair[] memory pairs) = abi.decode(
            data,
            (uint64, KeyValuePair[])
        );

        require(
            _executedBatches[nonceAndID] == batchIndex,
            "Settleable: invalid batch index"
        );
        require(
            MerkleProof.verifyCalldata(proof, rootHash, keccak256(data)),
            "Settleable: failed to verify"
        );
        _executedBatches[nonceAndID]++;

        _settle(pairs, resourceID);
    }

    /// @dev It is implemented in the following:
    /// - ERC20Settleable
    /// - ERC721Settleable
    /// - ERC20HandlerSettleable
    /// - NativeHandlerSettleable
    function _settle(KeyValuePair[] memory, bytes32) internal virtual;
}