// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IEligibilityConstraint} from "./IEligibilityConstraint.sol";
import {IMoonbirds} from "moonbirds/IMoonbirds.sol";

/**
 * @notice Eligibility if a moonbird is nested.
 */
contract Nested is IEligibilityConstraint {
    /**
     * @notice The moonbird token.
     */
    IMoonbirds private immutable _moonbirds;

    constructor(IMoonbirds moonbirds_) {
        _moonbirds = moonbirds_;
    }

    /**
     * @dev Returns true iff the moonbird is nested.
     */
    function isEligible(uint256 tokenId) public view virtual returns (bool) {
        (bool nesting,,) = _moonbirds.nestingPeriod(tokenId);
        return nesting;
    }
}

/**
 * @notice Eligibility if a moonbird is nested since a given time.
 */
contract NestedSince is IEligibilityConstraint {
    /**
     * @notice The moonbird token.
     */
    IMoonbirds private immutable _moonbirds;

    /**
     * @notice A moonbird has to be nested since this timestamp to be eligible.
     */
    uint256 private immutable _sinceTimestamp;

    constructor(IMoonbirds moonbirds_, uint256 sinceTimestamp_) {
        _moonbirds = moonbirds_;
        _sinceTimestamp = sinceTimestamp_;
    }

    /**
     * @dev Returns true iff the moonbird is nested since a given time.
     */
    function isEligible(uint256 tokenId) public view virtual returns (bool) {
        (bool nested, uint256 current,) = _moonbirds.nestingPeriod(tokenId);
        //solhint-disable-next-line not-rely-on-time
        return nested && block.timestamp - current <= _sinceTimestamp;
    }
}