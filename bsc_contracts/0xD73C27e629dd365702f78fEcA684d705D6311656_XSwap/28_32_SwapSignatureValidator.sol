// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TokenCheck, TokenUse, SwapStep, Swap, StealthSwap} from "./Swap.sol";

contract SwapSignatureValidator {
    function validateSwapSignature(Swap calldata swap_, bytes calldata swapSignature_) public pure {
        require(swap_.steps.length > 0, "SV: swap has no steps");
        address signer = ECDSA.recover(_hashTypedDataV4(_hashSwap(swap_), swap_.steps[0].chain, swap_.steps[0].swapper), swapSignature_);
        require(signer == swap_.account, "SV: invalid swap signature");
    }

    function validateStealthSwapStepSignature(SwapStep calldata swapStep_, StealthSwap calldata stealthSwap_, bytes calldata stealthSwapSignature_) public pure returns (uint256 stepIndex) {
        address signer = ECDSA.recover(_hashTypedDataV4(_hashStealthSwap(stealthSwap_), stealthSwap_.chain, stealthSwap_.swapper), stealthSwapSignature_);
        require(signer == stealthSwap_.account, "SV: invalid s-swap signature");
        return findStealthSwapStepIndex(swapStep_, stealthSwap_);
    }

    function findStealthSwapStepIndex(SwapStep calldata swapStep_, StealthSwap calldata stealthSwap_) public pure returns (uint256 stepIndex) {
        bytes32 stepHash = _hashSwapStep(swapStep_);
        for (uint256 i = 0; i < stealthSwap_.stepHashes.length; i++)
            if (stealthSwap_.stepHashes[i] == stepHash) return i;
        revert("SV: no step hash match in s-swap");
    }

    function _hashTypedDataV4(bytes32 structHash_, uint256 chainId_, address verifyingContract_) private pure returns (bytes32) {
        bytes32 domainSeparator = keccak256(abi.encode(0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, 0x759f8d0a6b014b7601ff701e703719d70a717971c25deb97628336c51d9e7d86, 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, chainId_, verifyingContract_));
        return ECDSA.toTypedDataHash(domainSeparator, structHash_);
    }

    function _hashSwap(Swap calldata swap_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x09b148e744e0e1801943dd449b1fa4d29b7172ff190d22f95b1bb7e5df52e37d, swap_.account, _hashSwapSteps(swap_.steps)));
    }

    function _hashSwapSteps(SwapStep[] calldata swapSteps_) private pure returns (bytes32) {
        bytes memory bytesToHash = new bytes(swapSteps_.length << 5); // * 0x20
        uint256 offset; assembly { offset := add(bytesToHash, 0x20) }
        for (uint256 i = 0; i < swapSteps_.length; i++) {
            bytes32 hash = _hashSwapStep(swapSteps_[i]);
            assembly { mstore(offset, hash) offset := add(offset, 0x20) }
        }
        return keccak256(bytesToHash);
    }

    function _hashSwapStep(SwapStep calldata swapStep_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x5302e49a52f1122ff531999c0f7afcb4d2bfefa7562dfefbdb7ed114d495ea6a, swapStep_.chain, swapStep_.swapper, swapStep_.sponsor, swapStep_.nonce, swapStep_.deadline, _hashTokenChecks(swapStep_.ins), _hashTokenChecks(swapStep_.outs), _hashTokenUses(swapStep_.uses)));
    }

    function _hashTokenChecks(TokenCheck[] calldata tokenChecks_) private pure returns (bytes32) {
        bytes memory bytesToHash = new bytes(tokenChecks_.length << 5); // * 0x20
        uint256 offset; assembly { offset := add(bytesToHash, 0x20) }
        for (uint256 i = 0; i < tokenChecks_.length; i++) {
            bytes32 hash = _hashTokenCheck(tokenChecks_[i]);
            assembly { mstore(offset, hash) offset := add(offset, 0x20) }
        }
        return keccak256(bytesToHash);
    }

    function _hashTokenCheck(TokenCheck calldata tokenCheck_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x382391664c9ae06333b02668b6d763ab547bd70c71636e236fdafaacf1e55bdd, tokenCheck_.token, tokenCheck_.minAmount, tokenCheck_.maxAmount));
    }

    function _hashTokenUses(TokenUse[] calldata tokenUses_) private pure returns (bytes32) {
        bytes memory bytesToHash = new bytes(tokenUses_.length << 5); // * 0x20
        uint256 offset; assembly { offset := add(bytesToHash, 0x20) }
        for (uint256 i = 0; i < tokenUses_.length; i++) {
            bytes32 hash = _hashTokenUse(tokenUses_[i]);
            assembly { mstore(offset, hash) offset := add(offset, 0x20) }
        }
        return keccak256(bytesToHash);
    }

    function _hashTokenUse(TokenUse calldata tokenUse_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x192f17c5e66907915b200bca0d866184770ff7faf25a0b4ccd2ef26ebd21725a, tokenUse_.protocol, tokenUse_.chain, tokenUse_.account, keccak256(abi.encodePacked(tokenUse_.inIndices)), _hashTokenChecks(tokenUse_.outs), keccak256(tokenUse_.args)));
    }

    function _hashStealthSwap(StealthSwap calldata stealthSwap_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x0f2b1c8dae54aa1b96d626d678ec60a7c6d113b80ccaf635737a6f003d1cbaf5, stealthSwap_.chain, stealthSwap_.swapper, stealthSwap_.account, keccak256(abi.encodePacked(stealthSwap_.stepHashes))));
    }
}