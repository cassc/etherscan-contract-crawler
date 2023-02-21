// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { MembersOnlyExtraData } from "./CietyZoneStructs.sol";
import "../interfaces/CietyZoneErrors.sol";

contract CietyZoneSignatureUtils is CietyZoneErrors {
    string internal constant _NAME = "CIETY-MEMBERS-ONLY-ZONE";
    string internal constant _VERSION = "1.0";
    uint8 internal constant _EXTRA_DATA_LEN = 0x44;

    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 internal immutable _MEMBERS_ONLY_TYPEHASH;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    constructor() {
        (
            _NAME_HASH,
            _VERSION_HASH,
            _EIP_712_DOMAIN_TYPEHASH,
            _MEMBERS_ONLY_TYPEHASH,
            _DOMAIN_SEPARATOR
        ) = _deriveTypeHashes();
        _CHAIN_ID = block.chainid;
    }

    function information()
        external
        view
        returns (
            string memory name,
            string memory version,
            bytes32 domainSeparator
        )
    {
        name = _NAME;
        version = _VERSION;
        domainSeparator = _DOMAIN_SEPARATOR;
    }

    function _splitExtraData(
        bytes memory extraData
    ) internal pure returns (bytes32 r, bytes32 vs, uint32 deadline) {
        if (extraData.length != _EXTRA_DATA_LEN) {
            revert InvalidExtraDataLength();
        }
        bytes4 timeLimit;
        assembly {
            r := mload(add(extraData, 0x20))
            vs := mload(add(extraData, 0x40))
            timeLimit := mload(add(extraData, 0x60))
        }
        deadline = uint32(timeLimit);
    }

    function _recoverSignature(
        bytes32 digest,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Invalid Signature S"
        );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return ecrecover(digest, v, r, s);
    }

    function _deriveTypeHashes()
        internal
        view
        returns (
            bytes32 nameHash,
            bytes32 versionHash,
            bytes32 eip712DomainTypeHash,
            bytes32 membersOnlyTypeHash,
            bytes32 domainSeparator
        )
    {
        nameHash = keccak256(bytes(_NAME));
        versionHash = keccak256(bytes(_VERSION));
        eip712DomainTypeHash = keccak256(
            abi.encodePacked(
                "EIP712Domain",
                "(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );
        membersOnlyTypeHash = keccak256(
            abi.encodePacked(
                "MembersOnlyExtraData",
                "(",
                "address member,",
                "bytes32 orderHash,",
                "uint32 deadline",
                ")"
            )
        );
        domainSeparator = _deriveDomainSeparator(
            eip712DomainTypeHash,
            nameHash,
            versionHash
        );
    }

    function _deriveDomainSeparator(
        bytes32 eip712DomainTypeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    eip712DomainTypeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return
            block.chainid == _CHAIN_ID
                ? _DOMAIN_SEPARATOR
                : _deriveDomainSeparator(
                    _EIP_712_DOMAIN_TYPEHASH,
                    _NAME_HASH,
                    _VERSION_HASH
                );
    }

    function _deriveMembersOnlyHash(
        bytes32 membersOnlyTypeHash,
        MembersOnlyExtraData memory data
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    membersOnlyTypeHash,
                    data.member,
                    data.orderHash,
                    data.deadline
                )
            );
    }

    function _deriveEIP712Digest(
        bytes32 domainSeparator,
        bytes32 membersOnlyHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint16(0x1901),
                    domainSeparator,
                    membersOnlyHash
                )
            );
    }
}