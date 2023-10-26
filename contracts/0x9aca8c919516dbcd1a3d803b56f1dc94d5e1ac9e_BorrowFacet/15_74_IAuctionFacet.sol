// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {BuyArg} from "../DataStructure/Objects.sol";

interface IAuctionFacet {
    /// @notice a NFT collateral has been sold as part of a liquidation
    /// @param loanId identifier of the loan previously backed by the sold collateral
    /// @param args arguments NFT sold
    event Buy(uint256 indexed loanId, bytes args);

    function buy(BuyArg[] memory args) external;

    function price(uint256 loanId) external view returns (uint256);
}