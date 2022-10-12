// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for including owned NFT token address and token ID information.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterHolderV0 is IFilteredMinterV0 {
    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address, using owned ERC-721 NFT to claim right to purchase.
    function purchase(
        uint256 _projectId,
        address _ownedNftAddress,
        uint256 _ownedNftTokenId
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address, using owned ERC-721 NFT to claim right to purchase.
    function purchaseTo(
        address _to,
        uint256 _projectId,
        address _ownedNftAddress,
        uint256 _ownedNftTokenId
    ) external payable returns (uint256 tokenId);
}