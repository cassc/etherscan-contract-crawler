// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

interface IWPunkGateway {
    event EmergencyERC721TokenTransfer(
        address token,
        uint256 tokenId,
        address to
    );

    event EmergencyPunkTransfer(address to, uint256 punkIndex);

    function supplyPunk(
        DataTypes.ERC721SupplyParams[] calldata punkIndexes,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdrawPunk(uint256[] calldata punkIndexes, address to) external;

    function acceptBidWithCredit(
        bytes32 marketplaceId,
        bytes calldata payload,
        DataTypes.Credit calldata credit,
        uint256[] calldata punkIndexes,
        uint16 referralCode
    ) external;

    function batchAcceptBidWithCredit(
        bytes32[] calldata marketplaceIds,
        bytes[] calldata payloads,
        DataTypes.Credit[] calldata credits,
        uint256[] calldata punkIndexes,
        uint16 referralCode
    ) external;
}