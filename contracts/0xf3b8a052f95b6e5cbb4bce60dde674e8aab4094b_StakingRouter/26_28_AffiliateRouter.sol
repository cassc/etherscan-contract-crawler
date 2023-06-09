// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "../../library/KContract.sol";

import "../../core/Referral/IReferral.sol";

abstract contract AffiliateRouter is KContract {

    bytes4 private constant REFERRER_KEY = bytes4(keccak256('REFERRER_KEY'));

    function _assignReferrer(address referral) internal {
        uint256 size;
        assembly {
            size := calldatasize()
        }

        if (size < 36) return;
        address referrer;
        bytes4 key;

        // The assembly code is more direct than the Solidity version using `abi.decode`.
        assembly {
            key := calldataload(sub(calldatasize(), 36))
            referrer := calldataload(sub(calldatasize(), 32))
        }

        if (key == REFERRER_KEY) {
            IReferral(referral).assign(_msgSender(), referrer);
        }
    }
}