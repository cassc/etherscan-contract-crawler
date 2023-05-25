// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IOptimisticOracle {
    event Propose(bytes32 indexed rateId, bytes32 nonce);

    event Dispute(
        bytes32 indexed rateId,
        address indexed proposer,
        address indexed disputer,
        uint256 proposedValue,
        uint256 validValue
    );

    event Validate(
        bytes32 indexed token,
        address indexed proposer,
        uint256 result
    );
    event Push(bytes32 indexed rateId, bytes32 nonce, uint256 value);
    event Bond(address indexed proposer, bytes32[] rateIds);
    event Unbond(address indexed proposer, bytes32 rateId, address receiver);
    event ClaimBond(address indexed proposer, bytes32 rateId, address receiver);
    event Lock();

    function target() external view returns (address);

    function bondToken() external view returns (IERC20);

    function bondSize() external view returns (uint256);

    function oracleType() external view returns (bytes32);

    function disputeWindow() external view returns (uint256);

    function proposals(bytes32 rateId) external view returns (bytes32);

    function activeRateIds(bytes32 rateId) external view returns (bool);

    function bonds(address, bytes32) external view returns (bool);

    function bond(address proposer, bytes32[] calldata rateIds) external;

    function bond(bytes32[] calldata rateIds) external;

    function unbond(
        bytes32 rateId,
        address proposer,
        uint256 value,
        bytes32 nonce,
        address receiver
    ) external;

    function isBonded(address proposer, bytes32 rateId)
        external
        view
        returns (bool);

    function shift(
        bytes32 rateId,
        address prevProposer,
        uint256 prevValue,
        bytes32 prevNonce,
        uint256 value,
        bytes memory data
    ) external;

    function dispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value_,
        bytes32 nonce,
        bytes memory data
    ) external;

    function validate(
        uint256 proposedValue,
        bytes32 rateId,
        bytes32 nonce,
        bytes memory data
    )
        external
        returns (
            uint256,
            uint256,
            bytes memory
        );

    function push(bytes32 rateId) external;

    function encodeNonce(bytes32 prevNonce, bytes memory data)
        external
        view
        returns (bytes32);

    function decodeNonce(bytes32 nonce)
        external
        view
        returns (bytes32 dataHash, uint64 proposeTimestamp);

    function canDispute(bytes32 nonce) external view returns (bool);

    function allowProposer(address proposer) external;

    function lock(bytes32[] calldata rateIds_) external;

    function recover(bytes32 rateId, address receiver) external;
}