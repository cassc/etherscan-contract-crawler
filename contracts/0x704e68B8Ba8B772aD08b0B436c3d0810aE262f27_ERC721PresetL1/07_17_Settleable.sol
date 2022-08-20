// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./RollupTypes.sol";

/// @notice Contract module that allows children to implement
/// state settlement mechanisms.
///
/// A settleable is a contract that has {settle} function
/// and makes state changes to destination resource.
///
/// @dev This module is supposed to be used in layer 1 (settlement layer).

abstract contract Settleable {
    address public immutable bridgeAddressSettleable;

    bool private _settleable;
    mapping(uint72 => uint256) private _executedBatches;

    /// @notice Emitted when state settlement is diabled by `account`.
    event SettlementDisabled(address account);

    constructor(address bridgeAddress) {
        bridgeAddressSettleable = bridgeAddress;
        _settleable = true;
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
        require(
            msg.sender == bridgeAddressSettleable,
            "Settleable: not from bridge"
        );

        require(_settleable, "Settleable: not settleable");

        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);

        (uint64 batchIndex, bytes memory batchedStateChanges) = abi.decode(
            data,
            (uint64, bytes)
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

        KeyValuePair[] memory pairs = abi.decode(
            batchedStateChanges,
            (KeyValuePair[])
        );

        _settle(pairs, resourceID);
    }

    function _disableSettlement() internal {
        _settleable = false;
        emit SettlementDisabled(msg.sender);
    }

    /// @dev It is implemented in the following:
    /// - ERC20Settleable
    /// - ERC721Settleable
    /// - ERC20HandlerSettleable
    /// - NativeHandlerSettleable
    function _settle(KeyValuePair[] memory, bytes32) internal virtual;

    /// @notice Returns true if the contract is Settleable, and false otherwise.
    ///
    /// @return true if Settleable. otherwise, false.
    function _isSettleable() internal view virtual returns (bool) {
        return _settleable;
    }
}