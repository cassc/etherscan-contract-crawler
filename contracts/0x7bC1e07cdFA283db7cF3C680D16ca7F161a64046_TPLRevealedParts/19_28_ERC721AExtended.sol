// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC721A, ERC721A, ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {ERC721AMintable} from "./ERC721AMintable.sol";
import {ERC721AMeta} from "./ERC721AMeta.sol";

/// @title ERC721AExtended
/// @author dev by @dievardump
/// @notice puts together the extensions to ERC721A
abstract contract ERC721AExtended is ERC721ABurnable, ERC721AMintable, ERC721AMeta {
    /////////////////////////////////////////////////////////
    // Internal                                            //
    /////////////////////////////////////////////////////////

    /// @dev erc721A internal function used when minting or transfering an item
    /// @inheritdoc ERC721A
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override(ERC721A, ERC721AMintable) returns (uint24) {
        return super._extraData(from, to, previousExtraData);
    }
}