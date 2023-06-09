// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./EndPoint.sol";
import "./interfaces/IGateKeeper.sol";
import "./interfaces/IRouterV2.sol";
import "./interfaces/IAddressBook.sol";
import "./utils/RequestIdLib.sol";


abstract contract BaseRouter is Pausable, EIP712, EndPoint, AccessControlEnumerable {
    using Counters for Counters.Counter;

    enum ExecutionResult { Failed, Succeeded, Interrupted }

    struct ComplexOp {
        string operation;
        bool registered;
    }

    struct MaskedParams {
        uint256 amountOut;
        address to;
        address emergencyTo;
    }

    /// @dev accountant role id
    bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");
    /// @dev operator role id
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    /// @dev registered operations
    mapping(bytes32 => bool) public ops;

    /// @dev nonces
    mapping(address => Counters.Counter) private _nonces;
    
    /// @dev started crocss-chain ops, requestId => serialized op params
    mapping(bytes32 => bytes) public startedOps;

    /// @dev used to check is function called from resume\onlyBridge handler, otherwise not set 
    bytes32 internal currentRequestId;

    /// @dev should be set between receiveValidatedData and resume call
    uint64 internal currentChainIdFrom;
    
    event FeePaid(address indexed payer, address accountant, uint256 executionPrice);
    event ComplexOpProcessed(
        uint64 currentChainId,
        bytes32 currentRequestId,
        uint64 nextChainId,
        bytes32 nextRequestId,
        ExecutionResult result,
        uint8 lastOp
    );
    event ComplexOpSet(string oop, bytes32 hash, bool registered);

    modifier crosschainHandling(bytes32 requestId) {
        currentRequestId = requestId;
        _;
        currentRequestId = 0;
        currentChainIdFrom = 0;
    }

    constructor(
        address addressBook_
    ) EIP712("EYWA", "1") EndPoint(addressBook_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function nonces(address whose) public view returns (uint256) {
        return _nonces[whose].current();
    }

    /**
     * @dev Registers set of complex operation.
     *
     * @param complexOps_ array of complex operations and registered flags.
     */
    function registerComplexOp(ComplexOp[] memory complexOps_) external onlyRole(OPERATOR_ROLE) {
        uint256 length = complexOps_.length;
        for (uint256 i; i < length; ++i) {
            bytes32 oop = keccak256(bytes(complexOps_[i].operation));
            ops[oop] = complexOps_[i].registered;
            emit ComplexOpSet(complexOps_[i].operation, oop, complexOps_[i].registered);
        }
    }

    /**
     * @dev Sets address book.
     *
     * Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
     *
     * @param addressBook_ address book contract address.
     */
    function setAddressBook(address addressBook_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setAddressBook(addressBook_);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Token synthesize request to another EVM chain via native payment.
     *
     * A: Lock(X) -> B: Mint(sX_A) = sX_A
     *
     * @param operations operation types;
     * @param params operation params;
     * @param receipt clp invoice.
     */
    function _start(
        string[] calldata operations,
        bytes[] memory params,
        IRouterParams.Invoice calldata receipt
    ) internal virtual {
        require(operations.length < 2**8, "BaseRouter: wrong params count");
        require(operations.length == params.length, "BaseRouter: wrong params");
        {
            (bytes32 hash, bytes memory data) = _getRawData(operations, params);
            require(ops[hash] == true, "BaseRouter: complex op not registered");
            address accountant = _checkSignature(msg.sender, hash, data, receipt);
            _proceedFees(receipt.executionPrice, accountant);
        }

        (
            bytes32 nextRequestId,
            uint64 chainIdTo,
            ExecutionResult result,
            uint8 lastOp
        ) = _execute(0, operations, params);

        emit ComplexOpProcessed(uint64(block.chainid), 0, chainIdTo, nextRequestId, result, lastOp);
    }

    function _resume(
        bytes32 requestId,
        uint8 cPos,
        string[] calldata operations,
        bytes[] memory params
    ) internal virtual {
        require(operations.length < 2**8, "BaseRouter: wrong params count");
        require(operations.length == params.length, "BaseRouter: wrong params");
        require(cPos < params.length, "BaseRouter: wrong params");

        (
            bytes32 nextRequestId,
            uint64 chainIdTo,
            ExecutionResult result,
            uint8 lastOp
        ) = _execute(cPos, operations, params);

        emit ComplexOpProcessed(uint64(block.chainid), requestId, chainIdTo, nextRequestId, result, lastOp);
    }

    function _execute(uint256 cPos, string[] calldata operations, bytes[] memory params) internal virtual whenNotPaused returns (
        bytes32 nextRequestId,
        uint64 chainIdTo,
        ExecutionResult result,
        uint8 lastOp
    ) {
        MaskedParams memory maskedParams;
        bytes memory updatedParams;
        for (uint256 i = cPos; i < operations.length; ++i) {
            (chainIdTo, updatedParams, maskedParams, result) = _executeOp(
                (currentRequestId != 0 && i == cPos),
                keccak256(bytes(operations[i])),
                i < (operations.length - 1) ? keccak256(bytes(operations[i + 1])) : bytes32(0),
                params[i],
                maskedParams
            );
            require(result != ExecutionResult.Failed, string(abi.encodePacked("Router: op ", operations[i], " is not supported")));
            lastOp = uint8(i);
            if (result == ExecutionResult.Interrupted) {
                break;
            } else if (chainIdTo != 0) {
                address router = IAddressBook(addressBook).router(chainIdTo);
                nextRequestId = _getRequestId(router, chainIdTo);
                if (updatedParams.length != 0) {
                    params[i] = updatedParams;
                }
                bytes memory out = abi.encodeWithSelector(
                    IRouter.resume.selector,
                    nextRequestId,
                    uint8(i),
                    operations,
                    params
                );
                address gateKeeper = IAddressBook(addressBook).gateKeeper();
                IGateKeeper(gateKeeper).sendData(out, router, chainIdTo, address(0));
                startedOps[nextRequestId] = params[i];
                break;
            }
        }
    }

    /**
     * @dev Returns current nonce and increment it.
     *
     * @param whose whose nonce.
     */
    function _getAndUpdateNonce(address whose) internal returns (uint256 nonce) {
        Counters.Counter storage counter = _nonces[whose];
        nonce = counter.current();
        counter.increment();
    }

    function _checkSignature(
        address from,
        bytes32 operationHash,
        bytes memory data,
        IRouterParams.Invoice calldata receipt
    ) internal returns (address accountant) {
        uint256 nonce = _getAndUpdateNonce(from);
        bytes32 accountantHash = keccak256(
            abi.encodePacked(
                keccak256(
                    "AccountantPermit(address from,uint256 nonce,bytes32 operationHash,bytes data,uint256 executionPrice,uint256 deadline)"
                ),
                from,
                nonce,
                operationHash,
                data,
                receipt.executionPrice,
                receipt.deadline
            )
        );

        bytes32 hash = ECDSA.toEthSignedMessageHash(_hashTypedDataV4(accountantHash));
        accountant = ECDSA.recover(hash, receipt.v, receipt.r, receipt.s);

        require(block.timestamp <= receipt.deadline, "BaseRouter: deadline");
        require(hasRole(ACCOUNTANT_ROLE, accountant), "BaseRouter: invalid signature from worker");
    }

    function _getRawData(
        string[] calldata operations,
        bytes[] memory params
    ) internal pure returns (bytes32 hash, bytes memory data) {
        bytes memory op;
        for (uint256 i = 0; i < operations.length; ++i) {
            op = bytes.concat(op, bytes(operations[i]));
            data = bytes.concat(data, params[i]);
        }
        hash = keccak256(op);
    }

    function _getRequestId(address receiver, uint64 chainIdTo) internal view returns (bytes32 requestId) {
        address gateKeeper = IAddressBook(addressBook).gateKeeper();
        uint256 nonce = IGateKeeper(gateKeeper).getNonce();
        requestId = RequestIdLib.prepareRequestId(
            castToBytes32(receiver),
            chainIdTo,
            castToBytes32(address(this)),
            block.chainid,
            nonce
        );
    }

    function _proceedFees(uint256 executionPrice, address accountant) internal virtual;

    function _executeOp(
        bool isOpHalfDone,
        bytes32 op,
        bytes32 nextOp,
        bytes memory params,
        MaskedParams memory prevMaskedParams
    ) internal virtual returns (
        uint64 chainIdTo,
        bytes memory updatedParams,
        MaskedParams memory maskedParams,
        ExecutionResult result
    );
}