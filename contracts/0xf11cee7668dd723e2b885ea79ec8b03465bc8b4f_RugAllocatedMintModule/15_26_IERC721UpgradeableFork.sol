// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @title IERC721UpgradeableFork
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for functions defined in ERC721UpgradeableFork, a fork of
 * OpenZeppelin's ERC721Upgradeable with additional tokenId-tracking and
 * royalty functionality.
 */
interface IERC721UpgradeableFork is IERC721MetadataUpgradeable {
    /**
     * @return ID of the first token that will be minted.
     */
    // solhint-disable-next-line func-name-mixedcase
    function STARTING_TOKEN_ID() external view returns (uint256);

    /**
     * @return Max consecutive tokenIds of bulk-minted tokens whose owner can
     * be stored as address(0). This number is capped to reduce the cost of
     * owner lookup.
     */
    // solhint-disable-next-line func-name-mixedcase
    function OWNER_ID_STAGGER() external view returns (uint256);

    /**
     * @return ID of the next token that will be minted. Existing tokens are
     * limited to IDs between `STARTING_TOKEN_ID` and `_nextTokenId` (including
     * `STARTING_TOKEN_ID` and excluding `_nextTokenId`, though not all of these
     * IDs may be in use if tokens have been burned).
     */
    function nextTokenId() external view returns (uint256);

    /**
     * @return receiver Address that should receive royalties from sales.
     * @return royaltyAmount How much royalty that should be sent to `receiver`,
     * denominated in the same unit of exchange as `salePrice`.
     * @param tokenId The token being sold.
     * @param salePrice The sale price of the token, denominated in any unit of
     * exchange. The royalty amount will be denominated and should be paid in
     * that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}