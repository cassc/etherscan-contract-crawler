// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Ray} from "../DataStructure/Objects.sol";

interface IAdminFacet {
    /// @notice duration of future auctions has been updated
    /// @param newAuctionDuration duration of liquidation for new loans
    event NewAuctionDuration(uint256 indexed newAuctionDuration);

    /// @notice initial price factor of future auctions has been updated
    /// @param newAuctionPriceFactor factor of loan to value setting initial price of auctions
    event NewAuctionPriceFactor(Ray indexed newAuctionPriceFactor);

    /// @notice a new interest rate tranche has been created
    /// @param tranche the interest rate of the new tranche, in multiplier per second
    /// @param newTrancheId identifier of the new tranche
    event NewTranche(Ray indexed tranche, uint256 indexed newTrancheId);

    /// @notice the minimum cost to repay per used loan offer
    ///     when borrowing a certain currency has been updated
    /// @param currency the erc20 on which a new minimum borrow cost is taking effect
    /// @param newMinOfferCost the new minimum amount that will need to be repaid per loan offer used
    event NewMininimumOfferCost(IERC20 indexed currency, uint256 indexed newMinOfferCost);

    /// @notice the borrow amount lower bound per offer has been updated
    /// @param currency the erc20 on which a new borrow amount lower bound is taking effect
    /// @param newLowerBound the new lower bound
    event NewBorrowAmountPerOfferLowerBound(IERC20 indexed currency, uint256 indexed newLowerBound);

    /// @notice the key of the api co-signing offers for validation has been updated
    /// @param apiAddress the new address (corresponding to the new key) of the api
    event NewApiAddress(address apiAddress);

    function setAuctionDuration(uint256 newAuctionDuration) external;

    function setAuctionPriceFactor(Ray newAuctionPriceFactor) external;

    function createTranche(Ray newTranche) external returns (uint256 newTrancheId);

    function setMinOfferCost(IERC20 currency, uint256 newMinOfferCost) external;

    function setBorrowAmountPerOfferLowerBound(IERC20 currency, uint256 newLowerBound) external;

    function setBaseMetadataUri(string calldata baseMetadataUri) external;

    function setApiAddress(address apiAddress) external;
}