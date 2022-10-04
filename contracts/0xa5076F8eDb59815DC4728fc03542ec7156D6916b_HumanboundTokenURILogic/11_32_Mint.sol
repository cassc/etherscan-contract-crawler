//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721State, ERC721Storage } from "../../../storage/ERC721Storage.sol";
import "../getter/IGetterLogic.sol";
import "../receiver/IOnReceiveLogic.sol";
import "../hooks/IERC721Hooks.sol";
import "../Events.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

// This contract should be inherited by your own custom `mint` logic which makes a call to `_mint` or `_safeMint`
abstract contract Mint is Events {
    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract,
     *      it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            IOnReceiveLogic(address(this))._checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!IGetterLogic(address(this))._exists(tokenId), "ERC721: token already minted");

        IERC721Hooks(address(this))._beforeTokenTransfer(address(0), to, tokenId);

        ERC721State storage erc721State = ERC721Storage._getState();
        erc721State._balances[to] += 1;
        erc721State._owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        IERC721Hooks(address(this))._afterTokenTransfer(address(0), to, tokenId);
    }
}