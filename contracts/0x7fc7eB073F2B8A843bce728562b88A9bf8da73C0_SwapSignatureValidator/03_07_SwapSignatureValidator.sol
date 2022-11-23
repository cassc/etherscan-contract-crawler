// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {EIP712D} from "../../lib/draft-EIP712D.sol";
import {ECDSA} from "../../lib/ECDSA.sol";

import {ISwapSignatureValidator} from "./ISwapSignatureValidator.sol";
// prettier-ignore
import {
    TokenCheck,
    TokenUse,
    SwapStep,
    Swap,
    StealthSwap
} from "./Swap.sol";
// prettier-ignore
import {
    TOKEN_CHECK_TYPE_HASH,
    TOKEN_USE_TYPE_HASH,
    SWAP_STEP_TYPE_HASH,
    SWAP_TYPE_HASH,
    STEALTH_SWAP_TYPE_HASH
} from "./SwapTypeHash.sol";

contract SwapSignatureValidator is ISwapSignatureValidator, EIP712D {
    // prettier-ignore
    constructor()
        EIP712D("xSwap", "1")
    {} // solhint-disable-line no-empty-blocks

    /**
     * @dev Validates swap signature
     *
     * The function fails if swap signature is not valid for any reason
     */
    function validateSwapSignature(Swap calldata swap_, bytes calldata swapSignature_) public view {
        require(swap_.steps.length > 0, "SV: swap has no steps");

        bytes32 swapHash = _hashSwap(swap_);
        bytes32 hash = _hashTypedDataV4D(swapHash, swap_.steps[0].chain, swap_.steps[0].swapper);
        address signer = ECDSA.recover(hash, swapSignature_);
        require(signer == swap_.steps[0].account, "SV: invalid swap signature");
    }

    function validateStealthSwapStepSignature(
        SwapStep calldata swapStep_,
        StealthSwap calldata stealthSwap_,
        bytes calldata stealthSwapSignature_
    ) public view returns (uint256 stepIndex) {
        bytes32 swapHash = _hashStealthSwap(stealthSwap_);
        bytes32 hash = _hashTypedDataV4D(swapHash, stealthSwap_.chain, stealthSwap_.swapper);
        address signer = ECDSA.recover(hash, stealthSwapSignature_);
        require(signer == stealthSwap_.account, "SV: invalid s-swap signature");

        return findStealthSwapStepIndex(swapStep_, stealthSwap_);
    }

    function findStealthSwapStepIndex(
        SwapStep calldata swapStep_,
        StealthSwap calldata stealthSwap_
    ) public pure returns (uint256 stepIndex) {
        bytes32 stepHash = _hashSwapStep(swapStep_);
        for (uint256 i = 0; i < stealthSwap_.stepHashes.length; i++) {
            if (stealthSwap_.stepHashes[i] == stepHash) {
                return i;
            }
        }
        revert("SV: no step hash match in s-swap");
    }

    function _hashSwap(Swap calldata swap_) private pure returns (bytes32 swapHash) {
        // prettier-ignore
        swapHash = keccak256(abi.encode(
            SWAP_TYPE_HASH,
            _hashSwapSteps(swap_.steps)
        ));
    }

    function _hashSwapSteps(SwapStep[] calldata swapSteps_) private pure returns (bytes32 swapStepsHash) {
        bytes memory bytesToHash = new bytes(swapSteps_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < swapSteps_.length; i++) {
            bytes32 hash = _hashSwapStep(swapSteps_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        swapStepsHash = keccak256(bytesToHash);
    }

    function _hashSwapStep(SwapStep calldata swapStep_) private pure returns (bytes32 swapStepHash) {
        // prettier-ignore
        swapStepHash = keccak256(abi.encode(
            SWAP_STEP_TYPE_HASH,
            swapStep_.chain,
            swapStep_.swapper,
            swapStep_.account,
            swapStep_.useDelegate,
            swapStep_.nonce,
            swapStep_.deadline,
            _hashTokenChecks(swapStep_.ins),
            _hashTokenChecks(swapStep_.outs),
            _hashTokenUses(swapStep_.uses)
        ));
    }

    function _hashTokenChecks(TokenCheck[] calldata tokenChecks_) private pure returns (bytes32 tokenChecksHash) {
        bytes memory bytesToHash = new bytes(tokenChecks_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < tokenChecks_.length; i++) {
            bytes32 hash = _hashTokenCheck(tokenChecks_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        tokenChecksHash = keccak256(bytesToHash);
    }

    function _hashTokenCheck(TokenCheck calldata tokenCheck_) private pure returns (bytes32 tokenCheckHash) {
        // prettier-ignore
        tokenCheckHash = keccak256(abi.encode(
            TOKEN_CHECK_TYPE_HASH,
            tokenCheck_.token,
            tokenCheck_.minAmount,
            tokenCheck_.maxAmount
        ));
    }

    function _hashTokenUses(TokenUse[] calldata tokenUses_) private pure returns (bytes32 tokenUsesHash) {
        bytes memory bytesToHash = new bytes(tokenUses_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < tokenUses_.length; i++) {
            bytes32 hash = _hashTokenUse(tokenUses_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        tokenUsesHash = keccak256(bytesToHash);
    }

    function _hashTokenUse(TokenUse calldata tokenUse_) private pure returns (bytes32 tokenUseHash) {
        // prettier-ignore
        tokenUseHash = keccak256(abi.encode(
            TOKEN_USE_TYPE_HASH,
            tokenUse_.protocol,
            tokenUse_.chain,
            tokenUse_.account,
            _hashUint256Array(tokenUse_.inIndices),
            _hashTokenChecks(tokenUse_.outs),
            _hashBytes(tokenUse_.args)
        ));
    }

    function _hashStealthSwap(StealthSwap calldata stealthSwap_) private pure returns (bytes32 stealthSwapHash) {
        bytes32 stepsHash = _hashBytes32Array(stealthSwap_.stepHashes);

        stealthSwapHash = keccak256(
            abi.encode(
                STEALTH_SWAP_TYPE_HASH,
                stealthSwap_.chain,
                stealthSwap_.swapper,
                stealthSwap_.account,
                stepsHash
            )
        );
    }

    function _hashBytes(bytes calldata bytes_) private pure returns (bytes32 bytesHash) {
        bytesHash = keccak256(bytes_);
    }

    function _hashBytes32Array(bytes32[] calldata array_) private pure returns (bytes32 arrayHash) {
        arrayHash = keccak256(abi.encodePacked(array_));
    }

    function _hashUint256Array(uint256[] calldata array_) private pure returns (bytes32 arrayHash) {
        arrayHash = keccak256(abi.encodePacked(array_));
    }
}