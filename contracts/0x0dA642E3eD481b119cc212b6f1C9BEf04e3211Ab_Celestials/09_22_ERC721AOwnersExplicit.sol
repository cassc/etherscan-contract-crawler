// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../ERC721A.sol";

error AllOwnershipsHaveBeenSet();
error QuantityMustBeNonZero();
error NoTokensMintedYet();

abstract contract ERC721AOwnersExplicit is ERC721A {
    uint256 public nextOwnerToExplicitlySet;

    function _setOwnersExplicit(uint256 quantity) internal {
        if (quantity == 0) revert QuantityMustBeNonZero();
        if (_currentIndex == 0) revert NoTokensMintedYet();
        uint256 _nextOwnerToExplicitlySet = nextOwnerToExplicitlySet;
        if (_nextOwnerToExplicitlySet >= _currentIndex) revert AllOwnershipsHaveBeenSet();

        unchecked {
            uint256 endIndex = _nextOwnerToExplicitlySet + quantity - 1;

            if (endIndex + 1 > _currentIndex) {
                endIndex = _currentIndex - 1;
            }

            for (uint256 i = _nextOwnerToExplicitlySet; i <= endIndex; i++) {
                if (_ownerships[i].addr == address(0) && !_ownerships[i].burned) {
                    TokenOwnership memory ownership = ownershipOf(i);
                    _ownerships[i].addr = ownership.addr;
                    _ownerships[i].startTimestamp = ownership.startTimestamp;
                }
            }

            nextOwnerToExplicitlySet = endIndex + 1;
        }
    }
}