// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract FlashswapStorage {
    bytes32 private constant FLASHSWAP_STORAGE_LOCATION = keccak256('folding.flashswap.storage');

    /**
     * expectedCaller:        address that is expected and authorized to execute a callback on the account
     */
    struct FlashswapStore {
        address expectedCaller;
    }

    function flashswapStore() internal pure returns (FlashswapStore storage s) {
        bytes32 position = FLASHSWAP_STORAGE_LOCATION;
        assembly {
            s_slot := position
        }
    }
}