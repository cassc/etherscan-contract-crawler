// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IStrategy {
    function canExecuteTakerAsk(
        OrderTypes.MakerOrder calldata makerBid,
        OrderTypes.TakerOrder calldata takerAsk
    )
        external
        view
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        );

    function canExecuteTakerBid(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid
    )
        external
        view
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        );
}