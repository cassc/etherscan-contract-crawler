// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/fallback/DiamondFallback.sol";
import "@solidstate/contracts/utils/AddressUtils.sol";

abstract contract D4ADiamondFallback is DiamondFallback {
    error DiamondFallback__InvalidInitializationParameters();
    error DiamondFallback__TargetHasNoCode();

    using AddressUtils for address;

    function setFallbackAddressAndCall(address fallbackAddress, address target, bytes memory data) external onlyOwner {
        _setFallbackAddress(fallbackAddress);

        if ((target == address(0)) != (data.length == 0)) {
            revert DiamondFallback__InvalidInitializationParameters();
        }

        if (target != address(0)) {
            if (target != address(this)) {
                if (!target.isContract()) {
                    revert DiamondFallback__TargetHasNoCode();
                }
            }

            (bool success,) = target.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }
}