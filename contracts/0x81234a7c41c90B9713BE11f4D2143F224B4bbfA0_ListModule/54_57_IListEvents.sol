// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {Order} from "seaport/lib/ConsiderationStructs.sol";

// Actions that the ship can take
interface IListEvents {
    event NFTListed(
        uint256 timestamp,
        address nftContract,
        uint256 tokenID,
        uint256 price,
        uint256 expiration
    );
    event ListingCanceled(
        uint256 timestamp,
        address nftContract,
        uint256 tokenID
    );
}