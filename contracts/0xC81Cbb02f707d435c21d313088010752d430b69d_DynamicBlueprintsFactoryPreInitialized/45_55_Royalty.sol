//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IRoyalty.sol";

/**
 * @notice Shared royalty validation logic in Dynamic Blueprints system
 * @author Ohimire Labs
 */
abstract contract Royalty is IRoyalty {
    /**
     * @notice Validate a royalty object
     * @param royalty Royalty being validated
     */
    modifier royaltyValid(Royalty memory royalty) {
        require(royalty.recipients.length == royalty.royaltyCutsBPS.length, "Royalty arrays mismatched lengths");
        uint256 royaltyCutsSum = 0;
        for (uint i = 0; i < royalty.recipients.length; i++) {
            royaltyCutsSum += royalty.royaltyCutsBPS[i];
        }
        require(royaltyCutsSum <= 10000, "Royalty too large");
        _;
    }
}