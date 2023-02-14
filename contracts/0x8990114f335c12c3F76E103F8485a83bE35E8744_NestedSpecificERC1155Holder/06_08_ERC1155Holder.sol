// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IEligibilityConstraint} from "./IEligibilityConstraint.sol";
import {IMoonbirds} from "moonbirds/IMoonbirds.sol";
import {IERC1155} from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";
import {Nested} from "./Nested.sol";

/**
 * @notice Eligibility if the moonbird owner holds a token from another ERC721
 * collection.
 */
contract SpecificERC1155Holder is IEligibilityConstraint {
    /**
     * @notice The moonbird token.
     */
    IMoonbirds private immutable _moonbirds;

    /**
     * @notice The collection of interest.
     */
    IERC1155 private immutable _token;

    /**
     * @notice The ERC1155 token-type (i.e. id) of interest within the
     * collection.
     */
    uint256 private immutable _id;

    constructor(IMoonbirds moonbirds_, IERC1155 token_, uint256 id_) {
        _moonbirds = moonbirds_;
        _token = token_;
        _id = id_;
    }

    /**
     * @dev Returns true iff the moonbird holder also owns a token from a
     * pre-defined collection.
     */
    function isEligible(uint256 tokenId) public view virtual returns (bool) {
        return _token.balanceOf(_moonbirds.ownerOf(tokenId), _id) > 0;
    }
}

contract NestedSpecificERC1155Holder is Nested, SpecificERC1155Holder {
    constructor(IMoonbirds moonbirds_, IERC1155 token_, uint256 id_)
        Nested(moonbirds_)
        SpecificERC1155Holder(moonbirds_, token_, id_)
    {} //solhint-disable-line no-empty-blocks

    /**
     * @dev Returns true iff the moonbird is nested and its holder also owns a
     * token from a pre-defined collection.
     */
    function isEligible(uint256 tokenId)
        public
        view
        virtual
        override(Nested, SpecificERC1155Holder)
        returns (bool)
    {
        return Nested.isEligible(tokenId)
            && SpecificERC1155Holder.isEligible(tokenId);
    }
}