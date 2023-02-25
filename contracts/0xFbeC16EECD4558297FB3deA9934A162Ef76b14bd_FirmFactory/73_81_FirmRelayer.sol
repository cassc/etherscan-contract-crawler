// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {EIP712} from "openzeppelin/utils/cryptography/draft-EIP712.sol";

/**
 * @title FirmRelayer
 * @author Firm ([email protected])
 * @notice Relayer for gas-less transactions
 * @dev Custom ERC2771 forwarding relayer tailor made for Firm's UX needs and return value assertions
 * Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/metatx/MinimalForwarder.sol (MIT licensed)
 */
contract FirmRelayer is EIP712 {
    using ECDSA for bytes32;

    // NOTE: Assertions are its own separate array since it results in smaller calldata
    // than if the Call struct had an assertions array member for common cases
    // in which there will be one assertion per call and many calls will not
    // have assertions, resulting in more expensive encoding (1 more word for each empty array)
    struct RelayRequest {
        address from;
        uint256 nonce;
        Call[] calls;
        Assertion[] assertions;
    }

    struct Call {
        address to;
        uint256 value;
        uint256 gas;
        bytes data;
        uint256 assertionIndex; // one-indexed, 0 signals no assertions
    }

    struct Assertion {
        uint256 position;
        bytes32 expectedValue;
    }

    // See https://eips.ethereum.org/EIPS/eip-712#definition-of-typed-structured-data-%F0%9D%95%8A
    // string internal constant ASSERTION_TYPE = "Assertion(uint256 position,bytes32 expectedValue)";
    // string internal constant CALL_TYPE = "Call(address to,uint256 value,uint256 gas,bytes data,uint256 assertionIndex)";
    // bytes32 internal constant REQUEST_TYPEHASH = keccak256(
    //    abi.encodePacked(
    //        "RelayRequest(address from,uint256 nonce,Call[] calls,Assertion[] assertions)", ASSERTION_TYPE, CALL_TYPE
    //    )
    //);
    // bytes32 internal constant ASSERTION_TYPEHASH = keccak256(abi.encodePacked(ASSERTION_TYPE));
    // bytes32 internal constant CALL_TYPEHASH = keccak256(abi.encodePacked(CALL_TYPE));
    // bytes32 internal constant ZERO_HASH = keccak256("");
    // All hashes are hardcoded as an optimization
    bytes32 internal constant REQUEST_TYPEHASH = 0x4e408063141dd503cd4ffb41da06a207a002e1632bbb7a1c2058bb5100bbdd68;
    bytes32 internal constant ASSERTION_TYPEHASH = 0xb8e6765a43e49f2a6e73bf063f697a2d4a289bc2c471f51c126f382b1370ecde;
    bytes32 internal constant CALL_TYPEHASH = 0xe1f11d512d9db71c9cfb8c40837bacb6c300df10de574e99f55b8fe640ecb2f3;
    bytes32 internal constant ZERO_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    uint256 internal constant ASSERTION_WORD_SIZE = 32;
    uint256 internal constant RELAY_GAS_BUFFER = 10000;
    uint256 internal constant MAX_REVERT_DATA = 320;

    mapping(address => uint256) public getNonce;

    error BadSignature();
    error BadNonce(uint256 expectedNonce);
    error CallExecutionFailed(uint256 callIndex, address to, bytes revertData);
    error BadAssertionIndex(uint256 callIndex);
    error AssertionPositionOutOfBounds(uint256 callIndex, uint256 returnDataLenght);
    error UnexpectedReturnValue(uint256 callIndex, bytes32 actualValue, bytes32 expectedValue);
    error UnauthorizedSenderNotFrom();
    error InsufficientGas();
    error BadExecutionContext();

    event Relayed(address indexed relayer, address indexed signer, uint256 nonce, uint256 numCalls);
    event SelfRelayed(address indexed sender, uint256 numCalls);
    event RelayExecutionFailed(address indexed relayer, address indexed signer, uint256 nonce, bytes revertData);

    constructor() EIP712("Firm Relayer", "0.0.1") {}

    /**
     * @notice Verify whether a request has been signed properly
     * @param request RelayRequest containing the calls to be performed and assertions
     * @param signature signature of the EIP712 typed data hash of the request
     * @return true if the signature is a valid signature for the request
     */
    function verify(RelayRequest calldata request, bytes calldata signature) public view returns (bool) {
        (address signer, ECDSA.RecoverError error) = requestTypedDataHash(request).tryRecover(signature);

        return error == ECDSA.RecoverError.NoError && signer == request.from;
    }

    /**
     * @notice Relay a batch of calls checking assertions on behalf of a signer (ERC2771)
     * @param request RelayRequest containing the calls to be performed and assertions
     * @param signature signature of the EIP712 typed data hash of the request
     */
    function relay(RelayRequest calldata request, bytes calldata signature) external payable {
        if (!verify(request, signature)) {
            revert BadSignature();
        }

        address signer = request.from;
        if (getNonce[signer] != request.nonce) {
            revert BadNonce(getNonce[signer]);
        }
        getNonce[signer] = request.nonce + 1;

        // We check how much gas all calls are going to use and make sure we have enough
        // This is to ensure that the external execute call will not fail due to OOG
        // which would allow to block the request by forcing it to fail
        uint256 callsGas = 0;
        uint256 callsLength = request.calls.length;
        for (uint256 i = 0; i < callsLength;) {
            callsGas += request.calls[i].gas;
            unchecked {
                i++;
            }
        }

        if (gasleft() < callsGas + RELAY_GAS_BUFFER) {
            revert InsufficientGas();
        }

        // We perform the execution as an external call so if the execution fails,
        // everything that happened in that sub-call is reverted, but not this
        // top-level call. This is important because we don't want to revert the
        // nonce increase if the execution fails.
        (bool ok, bytes memory returnData) = address(this).call(
            abi.encodeWithSelector(this.__externalSelfCall_execute.selector, signer, request.calls, request.assertions)
        );

        if (ok) {
            emit Relayed(msg.sender, signer, request.nonce, request.calls.length);
        } else {
            emit RelayExecutionFailed(msg.sender, signer, request.nonce, returnData);
        }
    }

    /**
     * @notice Relay a batch of calls checking assertions for the sender
     * @dev The reason why someone may want to use this is both being able to
     * batch calls using the same mechanism as relayed requests plus checking
     * assertions.
     * NOTE: selfRelay doesn't increase an account's nonce (native account nonces are relied on)
     * @param calls Array of calls to be made
     * @param assertions Array of assertions that calls can use
     */
    function selfRelay(Call[] calldata calls, Assertion[] calldata assertions) external payable {
        _execute(msg.sender, calls, assertions);

        emit SelfRelayed(msg.sender, calls.length);
    }

    function __externalSelfCall_execute(address asSender, Call[] calldata calls, Assertion[] calldata assertions) external {
        if (msg.sender != address(this)) {
            revert BadExecutionContext();
        }

        _execute(asSender, calls, assertions);
    }

    function _execute(address asSender, Call[] calldata calls, Assertion[] calldata assertions) internal {
        for (uint256 i = 0; i < calls.length;) {
            Call calldata call = calls[i];

            address to = call.to;
            uint256 value = call.value;
            uint256 callGas = call.gas;
            bytes memory payload = abi.encodePacked(call.data, asSender);
            uint256 returnDataSize;
            bool success;

            /// @solidity memory-safe-assembly
            assembly {
                success := call(callGas, to, value, add(payload, 0x20), mload(payload), 0, 0)
                returnDataSize := returndatasize()
            }

            if (!success) {
                // Prevent revert data from being too large
                uint256 revertDataSize = returnDataSize > MAX_REVERT_DATA ? MAX_REVERT_DATA : returnDataSize;
                bytes memory revertData = new bytes(revertDataSize);
                /// @solidity memory-safe-assembly
                assembly {
                    returndatacopy(add(revertData, 0x20), 0, revertDataSize)
                }
                revert CallExecutionFailed(i, call.to, revertData);
            }

            uint256 assertionIndex = call.assertionIndex;
            if (assertionIndex != 0) {
                if (assertionIndex > assertions.length) {
                    revert BadAssertionIndex(i);
                }

                Assertion calldata assertion = assertions[assertionIndex - 1];
                uint256 assertionPosition = assertion.position;
                if (assertion.position + ASSERTION_WORD_SIZE > returnDataSize) {
                    revert AssertionPositionOutOfBounds(i, returnDataSize);
                }

                // Only copy the return data word we need to check
                bytes32 returnValue;
                /// @solidity memory-safe-assembly
                assembly {
                    let copyPosition := mload(0x40)
                    returndatacopy(copyPosition, assertionPosition, ASSERTION_WORD_SIZE)
                    returnValue := mload(copyPosition)
                }
                if (returnValue != assertion.expectedValue) {
                    revert UnexpectedReturnValue(i, returnValue, assertion.expectedValue);
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function requestTypedDataHash(RelayRequest calldata request) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(REQUEST_TYPEHASH, request.from, request.nonce, hash(request.calls), hash(request.assertions))
            )
        );
    }

    function hash(Call[] calldata calls) internal pure returns (bytes32) {
        uint256 length = calls.length;
        if (length == 0) {
            return ZERO_HASH;
        }
        bytes32[] memory hashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            Call calldata call = calls[i];
            hashes[i] = keccak256(
                abi.encode(CALL_TYPEHASH, call.to, call.value, call.gas, keccak256(call.data), call.assertionIndex)
            );
            unchecked {
                i++;
            }
        }
        return keccak256(abi.encodePacked(hashes));
    }

    function hash(Assertion[] calldata assertions) internal pure returns (bytes32) {
        uint256 length = assertions.length;
        if (length == 0) {
            return ZERO_HASH;
        }
        bytes32[] memory hashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            Assertion calldata assertion = assertions[i];
            hashes[i] = keccak256(abi.encode(ASSERTION_TYPEHASH, assertion.position, assertion.expectedValue));
            unchecked {
                i++;
            }
        }
        return keccak256(abi.encodePacked(hashes));
    }
}