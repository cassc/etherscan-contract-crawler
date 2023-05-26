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
    mapping(uint72 => uint256) private _executeBatchNonce;

    /// @notice Emitted when state settlement is diabled by `account`.
    event SettlementDisabled(address account);

    constructor(address bridgeAddress) {
        bridgeAddressSettleable = bridgeAddress;
        _settleable = true;
    }

    /// @notice Settles state changes.
    ///
    /// @notice Requirements:
    /// - {_settleable} must be true.
    /// - It must be called only by the bridge.
    /// - Batch index must be valid.
    /// - Merkle proof must be verified.
    function settle(
        RollupInfo memory rollupInfo,
        bytes calldata data,
        bytes32[] calldata proof
    ) external {
        require(
            msg.sender == bridgeAddressSettleable,
            "Settleable: not from bridge"
        );

        require(_settleable, "Settleable: not settleable");

        uint72 nonceAndID = (uint72(rollupInfo.nonce) << 8) |
            uint72(rollupInfo.originDomainID);

        (uint64 batchIndex, bytes memory batchedStateChanges) = abi.decode(
            data,
            (uint64, bytes)
        );

        require(
            _executeBatchNonce[nonceAndID] == batchIndex,
            "Settleable: invalid batch index"
        );
        require(
            MerkleProof.verifyCalldata(
                proof,
                rollupInfo.rootHash,
                keccak256(data)
            ),
            "Settleable: failed to verify"
        );
        _executeBatchNonce[nonceAndID]++;

        KeyValuePair[] memory entries = abi.decode(
            batchedStateChanges,
            (KeyValuePair[])
        );

        _settle(rollupInfo.destAddress, entries);
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
    function _settle(address, KeyValuePair[] memory) internal virtual;

    /// @notice Returns true if the contract is Settleable, and false otherwise.
    ///
    /// @return true if Settleable. otherwise, false.
    function _isSettleable() internal view virtual returns (bool) {
        return _settleable;
    }
}