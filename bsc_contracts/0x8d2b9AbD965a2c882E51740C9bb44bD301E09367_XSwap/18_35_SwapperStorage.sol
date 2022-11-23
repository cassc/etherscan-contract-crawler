// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../../lib/StorageSlot.sol";

import {IDelegateManager} from "../delegate/IDelegateManager.sol";

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {ISwapSignatureValidator} from "./ISwapSignatureValidator.sol";

abstract contract SwapperStorage {
    // prettier-ignore
    // bytes32 private constant _SWAP_SIGNATURE_VALIDATOR_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._swapSignatureValidator")) - 1);
    bytes32 private constant _SWAP_SIGNATURE_VALIDATOR_SLOT = 0x572889db8ac91f4b1f7f11b2b1ed6b16c6eeea367a78b3975c5d6ec0ae5187b4;

    function _swapSignatureValidatorStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_SWAP_SIGNATURE_VALIDATOR_SLOT);
    }

    function _swapSignatureValidator() internal view returns (ISwapSignatureValidator) {
        return ISwapSignatureValidator(_swapSignatureValidatorStorage().value);
    }

    function _setSwapSignatureValidator(address swapSignatureValidator_) internal {
        _swapSignatureValidatorStorage().value = swapSignatureValidator_;
    }

    // prettier-ignore
    // bytes32 private constant _PERMIT_RESOLVER_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._permitResolverWhitelist")) - 1);
    bytes32 private constant _PERMIT_RESOLVER_WHITELIST_SLOT = 0x927ff1d8cfc45c529c885de54239c33280cdded1681dc287ec13e0c279fab4fd;

    function _permitResolverWhitelistStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_PERMIT_RESOLVER_WHITELIST_SLOT);
    }

    function _permitResolverWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_permitResolverWhitelistStorage().value);
    }

    function _setPermitResolverWhitelist(address permitResolverWhitelist_) internal {
        _permitResolverWhitelistStorage().value = permitResolverWhitelist_;
    }

    // prettier-ignore
    // bytes32 private constant _USE_PROTOCOL_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._useProtocolWhitelist")) - 1);
    bytes32 private constant _USE_PROTOCOL_WHITELIST_SLOT = 0xd4123124af6bd6de635253002be397fccc55549d14ec64e12254e1dc473a8989;

    function _useProtocolWhitelistStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_USE_PROTOCOL_WHITELIST_SLOT);
    }

    function _useProtocolWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_useProtocolWhitelistStorage().value);
    }

    function _setUseProtocolWhitelist(address useProtocolWhitelist_) internal {
        _useProtocolWhitelistStorage().value = useProtocolWhitelist_;
    }

    // prettier-ignore
    // bytes32 private constant _DELEGATE_MANAGER_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._delegateManager")) - 1);
    bytes32 private constant _DELEGATE_MANAGER_SLOT = 0xb9ce0614dc8c6b0ba4f1c391d809ad23817a3153e0effd15d0c78e880ecdbbb2;

    function _delegateManagerStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_DELEGATE_MANAGER_SLOT);
    }

    function _delegateManager() internal view returns (IDelegateManager) {
        return IDelegateManager(_delegateManagerStorage().value);
    }

    function _setDelegateManager(address delegateManager_) internal {
        _delegateManagerStorage().value = delegateManager_;
    }

    // bytes32 private constant _NONCES_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._nonces")) - 1);
    bytes32 private constant _NONCES_SLOT = 0x791d4fc0c3c60e2f2f4fc8a10cb89d9841dbac52dccccc663ba39d8dccd7113e;

    function _nonceUsedStorage(
        address account_,
        uint256 nonce_
    ) private pure returns (StorageSlot.BooleanSlot storage) {
        bytes32 slot = _NONCES_SLOT ^ keccak256(abi.encode(nonce_, account_));
        return StorageSlot.getBooleanSlot(slot);
    }

    function _nonceUsed(address account_, uint256 nonce_) internal view returns (bool) {
        return _nonceUsedStorage(account_, nonce_).value;
    }

    function _setNonceUsed(address account_, uint256 nonce_, bool used_) internal {
        _nonceUsedStorage(account_, nonce_).value = used_;
    }
}