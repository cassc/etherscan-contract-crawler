// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAnnotated} from "./IAnnotated.sol";
import {IControllable} from "./IControllable.sol";
import {CustomRoyalty, RoyaltySchedule} from "../structs/Royalty.sol";

interface IRoyalties is IControllable, IAnnotated {
    error InvalidReceiver();
    error InvalidRoyalty();

    event SetReceiver(address oldReceiver, address newReceiver);
    event SetRoyaltySchedule(RoyaltySchedule oldRoyaltySchedule, RoyaltySchedule newRoyaltySchedule);
    event SetCustomRoyalty(uint256 indexed tokenId, CustomRoyalty customRoyalty);

    /// @notice Returns how much royalty is owed and to whom, based on a sale
    /// price that may be denominated in any unit of exchange. The royalty
    /// amount is denominated and should be paid in the same unit of exchange.
    /// @param tokenId uint256 Token ID.
    /// @param salePrice uint256 Sale price (in any unit of exchange).[]
    /// @return receiver address of royalty recipient.
    /// @return royaltyAmount amount of royalty.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    /// @notice Set a custom royalty by tokenId. May only be called by controller.
    /// @param tokenId uint256 Token ID.
    /// @param customRoyalty CustomRoyalty struct including recipient address and
    /// royalty amount in basis points.
    function setCustomRoyalty(uint256 tokenId, CustomRoyalty calldata customRoyalty) external;

    /// @notice Set the default royalty schedule for tokens that do not have a
    /// custom royalty. May only be called by controller.
    /// @param newRoyaltySchedule RoyaltySchedule struct including fan token and
    /// brand token royalties in basis points.
    function setRoyaltySchedule(RoyaltySchedule calldata newRoyaltySchedule) external;
}