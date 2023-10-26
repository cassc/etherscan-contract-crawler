// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOwnershipFacet} from "./interface/IOwnershipFacet.sol";
import {IAdminFacet} from "./interface/IAdminFacet.sol";
import {Ray} from "./DataStructure/Objects.sol";
import {Protocol} from "./DataStructure/Storage.sol";
import {protocolStorage, supplyPositionMetadataStorage, ONE, apiCoSignerStorage} from "./DataStructure/Global.sol";
import {CallerIsNotOwner} from "./DataStructure/Errors.sol";
import {RayMath} from "./utils/RayMath.sol";

/// @notice admin-only setters for global protocol parameters
contract AdminFacet is IAdminFacet {
    using RayMath for Ray;

    /// @notice restrict a method access to the protocol owner only
    modifier onlyOwner() {
        // the admin/owner is the same account that can upgrade the protocol.
        address admin = IOwnershipFacet(address(this)).owner();
        if (msg.sender != admin) {
            revert CallerIsNotOwner(admin);
        }
        _;
    }

    /// @notice sets the time it takes to auction prices to fall to 0 for future loans
    /// @param newAuctionDuration number of seconds of the duration
    function setAuctionDuration(uint256 newAuctionDuration) external onlyOwner {
        protocolStorage().auction.duration = newAuctionDuration;
        emit NewAuctionDuration(newAuctionDuration);
    }

    /// @notice sets the factor applied to the loan to value setting initial price of auction for future loans
    /// @param newAuctionPriceFactor the new factor multiplied to the loan to value
    function setAuctionPriceFactor(Ray newAuctionPriceFactor) external onlyOwner {
        // see auction facet for the rationale of this check
        require(newAuctionPriceFactor.gte(ONE.mul(5).div(2)), "");
        protocolStorage().auction.priceFactor = newAuctionPriceFactor;
        emit NewAuctionPriceFactor(newAuctionPriceFactor);
    }

    /// @notice creates a new tranche at a new identifier for lenders to provide offers for
    /// @param newTranche the interest rate of the new tranche
    function createTranche(Ray newTranche) external onlyOwner returns (uint256 newTrancheId) {
        Protocol storage proto = protocolStorage();

        newTrancheId = proto.nbOfTranches++;
        proto.tranche[newTrancheId] = newTranche;

        emit NewTranche(newTranche, newTrancheId);
    }

    /* Both minimal offer cost and lower amount per offer lower bound are anti ddos mechanisms used to prevent the
    borrowers to spam the minting of supply positions that lenders would have no incentive to claim the corresponding
    dust funds from due to gas costs. The minimal offer cost mainly prevents this for claims after repayment, the amount
    per offer lower bound mainly prevents this for claims after liquidation. The governance setting those parameters
    effectively makes new erc20 available to use on the platform (they are disallowed otherwise). This should not
    be done for any fee-on-transfer token. */

    /// @notice updates the minimum amount to repay per used loan offer when borrowing a certain currency
    /// @param currency the erc20 on which a new minimum borrow cost will take effect
    /// @param newMinOfferCost the new minimum amount that will need to be repaid per loan offer used
    function setMinOfferCost(IERC20 currency, uint256 newMinOfferCost) external onlyOwner {
        protocolStorage().minOfferCost[currency] = newMinOfferCost;
        emit NewMininimumOfferCost(currency, newMinOfferCost);
    }

    /// @notice updates the borrow amount lower bound per offer for one currency
    /// @param currency the erc20 on which a new borrow amount lower bound is taking effect
    /// @param newLowerBound the new lower bound
    function setBorrowAmountPerOfferLowerBound(IERC20 currency, uint256 newLowerBound) external onlyOwner {
        protocolStorage().offerBorrowAmountLowerBound[currency] = newLowerBound;
        emit NewBorrowAmountPerOfferLowerBound(currency, newLowerBound);
    }

    /// @notice updates the base metadata uri to which the token id will be appended to get the metadata uri
    /// @param baseMetadataUri the new base metadata uri
    function setBaseMetadataUri(string calldata baseMetadataUri) external onlyOwner {
        supplyPositionMetadataStorage().baseUri = baseMetadataUri;
    }

    /// @notice updates the address of the api co-signer
    /// @param apiAddress the new address of the api co-signer
    function setApiAddress(address apiAddress) external onlyOwner {
        apiCoSignerStorage().apiAddress = apiAddress;
        emit NewApiAddress(apiAddress);
    }
}