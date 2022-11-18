// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IERC721Collective} from "./IERC721Collective.sol";

/// Mixin can be used by any module using an address that should be an
/// ERC721Collective and needs to check if it indeed is one.
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