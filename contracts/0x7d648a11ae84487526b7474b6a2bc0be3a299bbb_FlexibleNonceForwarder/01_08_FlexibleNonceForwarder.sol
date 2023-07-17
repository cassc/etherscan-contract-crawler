// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IForwarder} from "./interfaces/IForwarder.sol";

contract FlexibleNonceForwarder is IForwarder, EIP712, ReentrancyGuard {
    using ECDSA for bytes32;
    using Address for address payable;

    struct SigsForNonce {
        mapping(bytes => bool) sigs;
    }

    struct FlexibleNonce {
        uint256 currentNonce;
        uint256 block; // when this nonce was first used - used to age transactions
        mapping(uint256 => SigsForNonce) sigsForNonce;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => FlexibleNonce) private _nonces;

    uint256 private immutable _blockAgeTolerance;

    event ForwardResult(bool);

    /// The tx to be forwarded is not signed by the request sender.
    error FlexibleNonceForwarder__InvalidSigner(address signer, address expectedSigner);

    /// The tx to be forwarded has already been seen.
    error FlexibleNonceForwarder__TxAlreadySeen();

    /// The tx to be forwarded is too old.
    error FlexibleNonceForwarder__TxTooOld(uint256 blockNumber, uint256 blockAgeTolerance);

    constructor(uint256 blockAgeTolerance) EIP712("FlexibleNonceForwarder", "0.0.1") {
        _blockAgeTolerance = blockAgeTolerance;
    }

    function execute(
        ForwardRequest calldata req,
        bytes calldata signature
    ) external payable nonReentrant returns (bool, bytes memory) {
        _verifyFlexibleNonce(req, signature);
        _refundExcessValue(req);

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            // solhint-disable-next-line no-inline-assembly
            assembly {
                invalid()
            }
        }

        emit ForwardResult(success);

        return (success, returndata);
    }

    function getNonce(address from) external view returns (uint256) {
        return _nonces[from].currentNonce;
    }

    function _verifyFlexibleNonce(ForwardRequest calldata req, bytes calldata signature) internal {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);

        if (signer != req.from) {
            revert FlexibleNonceForwarder__InvalidSigner(signer, req.from);
        }

        if (_nonces[req.from].currentNonce == req.nonce) {
            // request nonce is expected next nonce - increment the nonce, and we are done
            _nonces[req.from].currentNonce = req.nonce + 1;
            _nonces[req.from].block = block.number;
        } else {
            // request nonce is not expected next nonce - check if we have seen this signature before
            if (_nonces[req.from].sigsForNonce[req.nonce].sigs[signature]) {
                revert FlexibleNonceForwarder__TxAlreadySeen();
            }

            // check if the nonce is too old
            if (_nonces[req.from].block + _blockAgeTolerance < block.number) {
                revert FlexibleNonceForwarder__TxTooOld(_nonces[req.from].block, _blockAgeTolerance);
            }
        }

        // store the signature for this nonce to ensure no replay attacks
        _nonces[req.from].sigsForNonce[req.nonce].sigs[signature] = true;
    }

    function _refundExcessValue(ForwardRequest calldata req) internal {
        // Refund the excess value sent to the forwarder if the value inside the request is less than the value sent.
        if (msg.value > req.value) {
            payable(msg.sender).sendValue(msg.value - req.value);
        }
    }
}