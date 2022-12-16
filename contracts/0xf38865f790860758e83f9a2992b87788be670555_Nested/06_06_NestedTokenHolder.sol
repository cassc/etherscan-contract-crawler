// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IEligibilityConstraint} from "./IEligibilityConstraint.sol";
import {IMoonbirds} from "moonbirds/IMoonbirds.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

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
        (bool nesting, , ) = _moonbirds.nestingPeriod(tokenId);
        return nesting;
    }
}

/**
 * @notice Eligibility if the moonbird owner holds a token from another ERC721
 * collection.
 */
contract TokenHolder is IEligibilityConstraint {
    /**
     * @notice The moonbird token.
     */
    IMoonbirds private immutable _moonbirds;

    /**
     * @notice The collection of interest.
     */
    IERC721 private immutable _token;

    constructor(IERC721 token_, IMoonbirds moonbirds_) {
        _token = token_;
        _moonbirds = moonbirds_;
    }

    /**
     * @dev Returns true iff the moonbird holder also owns a token from a
     * pre-defined collection.
     */
    function isEligible(uint256 tokenId) public view virtual returns (bool) {
        return _token.balanceOf(_moonbirds.ownerOf(tokenId)) > 0;
    }
}

/**
 * @notice Eligibility if the moonbird is nested and its owner also holds a
 * token from another ERC721 collection.
 */
contract NestedTokenHolder is Nested, TokenHolder {
    constructor(IERC721 token_, IMoonbirds moonbirds_)
        Nested(moonbirds_)
        TokenHolder(token_, moonbirds_)
    {}

    /**
     * @dev Returns true iff the moonbird is nested and its holder also owns a
     * token from a pre-defined collection.
     */
    function isEligible(uint256 tokenId)
        public
        view
        virtual
        override(Nested, TokenHolder)
        returns (bool)
    {
        return Nested.isEligible(tokenId) && TokenHolder.isEligible(tokenId);
    }
}