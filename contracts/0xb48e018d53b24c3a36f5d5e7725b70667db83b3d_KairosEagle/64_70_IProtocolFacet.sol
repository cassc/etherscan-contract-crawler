// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Ray} from "../DataStructure/Objects.sol";
import {Loan} from "../DataStructure/Storage.sol";

interface IProtocolFacet {
    function getRateOfTranche(uint256 id) external view returns (Ray rate);

    function getParameters()
        external
        view
        returns (Ray auctionPriceFactor, uint256 auctionDuration, uint256 nbOfLoans, uint256 nbOfTranches);

    function getLoan(uint256 id) external view returns (Loan memory);

    function getMinOfferCostAndBorrowableAmount(
        IERC20 currency
    ) external view returns (uint256 minOfferCost, uint256 offerBorrowAmountLowerBound);
}