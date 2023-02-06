// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IERC721Collective} from "./IERC721Collective.sol";

/**
 * @title ERC165CheckerERC721Collective
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Utility allowing implementing factories, modules etc. to verify whether an
 * address implements IERC721Collective.
 */

abstract contract ERC165CheckerERC721Collective {
    /// Only proceed if collective implements IERC721Collective interface
    /// @param collective collective to check
    modifier onlyCollectiveInterface(address collective) {
        _checkCollectiveInterface(collective);
        _;
    }

    function _checkCollectiveInterface(address collective) internal view {
        require(
            ERC165Checker.supportsInterface(
                collective,
                type(IERC721Collective).interfaceId
            ),
            "ERC165CheckerERC721Collective: collective address does not implement proper interface"
        );
    }
}