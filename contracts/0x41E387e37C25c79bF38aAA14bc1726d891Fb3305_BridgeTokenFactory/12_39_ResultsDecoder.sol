// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "rainbow-bridge-sol/nearbridge/contracts/Borsh.sol";

library ResultsDecoder {
    using Borsh for Borsh.Data;
    bytes32 public constant RESULT_PREFIX_LOCK =
        0x0a9eb877458579dbce83ea57d556be50d1c3160bb5f1719fb172bd3300ac8623;
    bytes32 public constant RESULT_PREFIX_METADATA =
        0xb315d4d6e8f235f5fabb0b1a0f118507f6c8542fae8e1a9566abe60762047c16;

    struct LockResult {
        string token;
        uint128 amount;
        address recipient;
    }
    struct MetadataResult {
        string token;
        string name;
        string symbol;
        uint8 decimals;
        uint64 blockHeight;
    }

    function decodeLockResult(bytes memory data)
        internal
        pure
        returns (LockResult memory result)
    {
        Borsh.Data memory borshData = Borsh.from(data);
        bytes32 prefix = borshData.decodeBytes32();
        require(prefix == RESULT_PREFIX_LOCK, "ERR_INVALID_LOCK_PREFIX");
        result.token = string(borshData.decodeBytes());
        result.amount = borshData.decodeU128();
        bytes20 recipient = borshData.decodeBytes20();
        result.recipient = address(uint160(recipient));
        borshData.done();
    }

    function decodeMetadataResult(bytes memory data)
        internal
        pure
        returns (MetadataResult memory result)
    {
        Borsh.Data memory borshData = Borsh.from(data);
        bytes32 prefix = borshData.decodeBytes32();
        require(
            prefix == RESULT_PREFIX_METADATA,
            "ERR_INVALID_METADATA_PREFIX"
        );
        result.token = string(borshData.decodeBytes());
        result.name = string(borshData.decodeBytes());
        result.symbol = string(borshData.decodeBytes());
        result.decimals = borshData.decodeU8();
        result.blockHeight = borshData.decodeU64();
        borshData.done();
    }
}