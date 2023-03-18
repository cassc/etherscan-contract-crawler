/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../lib/Facts.sol";

interface IReliquary {
    event NewProver(address prover, uint64 version);
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);
    event ProverRevoked(address prover, uint64 version);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct ProverInfo {
        uint64 version;
        FeeInfo feeInfo;
        bool revoked;
    }

    enum FeeFlags {
        FeeNone,
        FeeNative,
        FeeCredits,
        FeeExternalDelegate,
        FeeExternalToken
    }

    struct FeeInfo {
        uint8 flags;
        uint16 feeCredits;
        // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
        uint8 feeWeiMantissa;
        uint8 feeWeiExponent;
        uint32 feeExternalId;
    }

    function ADD_PROVER_ROLE() external view returns (bytes32);

    function CREDITS_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DELAY() external view returns (uint64);

    function GOVERNANCE_ROLE() external view returns (bytes32);

    function SUBSCRIPTION_ROLE() external view returns (bytes32);

    function activateProver(address prover) external;

    function addCredits(address user, uint192 amount) external;

    function addProver(address prover, uint64 version) external;

    function addSubscriber(address user, uint64 ts) external;

    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable;

    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view;

    function checkProveFactFee(address sender) external payable;

    function checkProver(ProverInfo memory prover) external pure;

    function credits(address user) external view returns (uint192);

    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function factFees(uint8)
        external
        view
        returns (
            uint8 flags,
            uint16 feeCredits,
            uint8 feeWeiMantissa,
            uint8 feeWeiExponent,
            uint32 feeExternalId
        );

    function feeAccounts(address)
        external
        view
        returns (uint64 subscriberUntilTime, uint192 credits);

    function feeExternals(uint256) external view returns (address);

    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function getProveFactNativeFee(address prover) external view returns (uint256);

    function getProveFactTokenFee(address prover) external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256);

    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function initialized() external view returns (bool);

    function isSubscriber(address user) external view returns (bool);

    function pendingProvers(address) external view returns (uint64 timestamp, uint64 version);

    function provers(address) external view returns (ProverInfo memory);

    function removeCredits(address user, uint192 amount) external;

    function removeSubscriber(address user) external;

    function renounceRole(bytes32 role, address account) external;

    function resetFact(address account, FactSignature factSig) external;

    function revokeProver(address prover) external;

    function revokeRole(bytes32 role, address account) external;

    function setCredits(address user, uint192 amount) external;

    function setFact(
        address account,
        FactSignature factSig,
        bytes memory data
    ) external;

    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    function setInitialized() external;

    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable returns (bool);

    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    function verifyBlockFeeInfo()
        external
        view
        returns (
            uint8 flags,
            uint16 feeCredits,
            uint8 feeWeiMantissa,
            uint8 feeWeiExponent,
            uint32 feeExternalId
        );

    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version);

    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version);

    function versions(uint64) external view returns (address);

    function withdrawFees(address token, address dest) external;
}