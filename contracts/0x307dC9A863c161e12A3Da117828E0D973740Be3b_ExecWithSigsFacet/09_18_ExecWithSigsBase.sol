// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {GelatoString} from "../../libraries/GelatoString.sol";
import {
    _wasSignatureUsedAlready,
    _setWasSignatureUsedAlready
} from "../storage/ExecWithSigsStorage.sol";
import {
    _isExecutorSigner,
    _isCheckerSigner
} from "../storage/SignerStorage.sol";
import {
    ExecWithSigs,
    Message,
    ExecWithSigsFeeCollector,
    MessageFeeCollector,
    ExecWithSigsRelayContext,
    MessageRelayContext
} from "../../types/CallTypes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract ExecWithSigsBase {
    using GelatoString for string;

    bytes32 public constant MESSAGE_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "Message(address service,bytes data,uint256 salt,uint256 deadline)"
            )
        );

    bytes32 public constant MESSAGE_FEE_COLLECTOR_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "MessageFeeCollector(address service,bytes data,uint256 salt,uint256 deadline,address feeToken)"
            )
        );

    bytes32 public constant MESSAGE_RELAY_CONTEXT_TYPEHASH =
        keccak256(
            bytes(
                // solhint-disable-next-line max-line-length
                "MessageRelayContext(address service,bytes data,uint256 salt,uint256 deadline,address feeToken,uint256 fee)"
            )
        );

    function _requireSignerDeadline(
        uint256 _signerDeadline,
        string memory _errorTrace
    ) internal view {
        require(
            // solhint-disable-next-line not-rely-on-time
            _signerDeadline == 0 || _signerDeadline >= block.timestamp,
            _errorTrace.suffix("deadline")
        );
    }

    function _requireExecutorSignerSignature(
        bytes32 _digest,
        bytes calldata _executorSignerSig,
        string memory _errorTrace
    ) internal returns (address executorSigner) {
        require(
            !_wasSignatureUsedAlready(_executorSignerSig),
            _errorTrace.suffix("replay")
        );

        ECDSA.RecoverError error;
        (executorSigner, error) = ECDSA.tryRecover(_digest, _executorSignerSig);

        require(
            error == ECDSA.RecoverError.NoError &&
                _isExecutorSigner(executorSigner),
            _errorTrace.suffix("ECDSA.RecoverError.NoError && isExecutorSigner")
        );

        _setWasSignatureUsedAlready(_executorSignerSig);
    }

    function _requireCheckerSignerSignature(
        bytes32 _digest,
        bytes calldata _checkerSignerSig,
        string memory _errorTrace
    ) internal returns (address checkerSigner) {
        require(
            !_wasSignatureUsedAlready(_checkerSignerSig),
            _errorTrace.suffix("replay")
        );

        ECDSA.RecoverError error;
        (checkerSigner, error) = ECDSA.tryRecover(_digest, _checkerSignerSig);

        require(
            error == ECDSA.RecoverError.NoError &&
                _isCheckerSigner(checkerSigner),
            _errorTrace.suffix("ECDSA.RecoverError.NoError && isCheckerSigner")
        );

        _setWasSignatureUsedAlready(_checkerSignerSig);
    }

    function _getDigest(bytes32 _domainSeparator, Message calldata _msg)
        internal
        pure
        returns (bytes32 digest)
    {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeExecWithSigs(_msg))
            )
        );
    }

    function _getDigestFeeCollector(
        bytes32 _domainSeparator,
        MessageFeeCollector calldata _msg
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeExecWithSigsFeeCollector(_msg))
            )
        );
    }

    function _getDigestRelayContext(
        bytes32 _domainSeparator,
        MessageRelayContext calldata _msg
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(_abiEncodeExecWithSigsRelayContext(_msg))
            )
        );
    }

    function _abiEncodeExecWithSigs(Message calldata _msg)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                MESSAGE_TYPEHASH,
                _msg.service,
                keccak256(_msg.data),
                _msg.salt,
                _msg.deadline
            );
    }

    function _abiEncodeExecWithSigsFeeCollector(
        MessageFeeCollector calldata _msg
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                MESSAGE_FEE_COLLECTOR_TYPEHASH,
                _msg.service,
                keccak256(_msg.data),
                _msg.salt,
                _msg.deadline,
                _msg.feeToken
            );
    }

    function _abiEncodeExecWithSigsRelayContext(
        MessageRelayContext calldata _msg
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                MESSAGE_RELAY_CONTEXT_TYPEHASH,
                _msg.service,
                keccak256(_msg.data),
                _msg.salt,
                _msg.deadline,
                _msg.feeToken,
                _msg.fee
            );
    }
}