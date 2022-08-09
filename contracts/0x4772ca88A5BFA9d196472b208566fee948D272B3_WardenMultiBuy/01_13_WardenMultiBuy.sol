// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./oz/utils/Ownable.sol";
import "./Warden.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IBoostV2.sol";
import "./utils/Errors.sol";

/** @title WardenMultiBuy contract  */
/**
    This contract's purpose is to allow easier purchase of multiple Boosts at once
    Can either:
        - Buy blindly from the Offers list, without sorting,
            with the parameters : maximum Price, and clearExpired (if false: will skip Delegators that could be available 
            after canceling their expired Boosts => less gas used)
        - Buy using a presorted array of Offers index (with the same parameters available)
        - Buy by performing a quickSort over the Offers, to start with the cheapest ones (with the same parameters available)
 */
/// @author Paladin
contract WardenMultiBuy is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant UNIT = 1e18;
    uint256 public constant MAX_PCT = 10000;
    uint256 public constant WEEK = 7 * 86400;

    /** @notice ERC20 used to pay for DelegationBoost */
    IERC20 public feeToken;
    /** @notice Address of the votingToken */
    IVotingEscrow public votingEscrow;
    /** @notice Address of the Delegation Boost contract */
    IBoostV2 public delegationBoost;
    /** @notice Address of the Warden contract */
    Warden public warden;


    // Constructor :
    /**
     * @dev Creates the contract, set the given base parameters
     * @param _feeToken address of the token used to pay fees
     * @param _votingEscrow address of the voting token to delegate
     * @param _delegationBoost address of the veBoost contract
     * @param _warden address of Warden
     */
    constructor(
        address _feeToken,
        address _votingEscrow,
        address _delegationBoost,
        address _warden
    ) {
        feeToken = IERC20(_feeToken);
        votingEscrow = IVotingEscrow(_votingEscrow);
        delegationBoost = IBoostV2(_delegationBoost);
        warden = Warden(_warden);
    }


    struct MultiBuyVars {
        // Duration of the Boosts in seconds
        uint256 boostDuration;
        // Total count of Offers in the Warden Offer List
        uint256 totalNbOffers;
        // Timestamp of the end of Boosts
        uint256 boostEndTime;
        // Expiry Timestamp for the veBoost
        uint256 expiryTime;
        // Balance of this contract before the execution
        uint256 previousBalance;
        // Balance of this contract after the execution
        uint256 endBalance;
        // Amount of veToken still needed to buy to fill the Order
        uint256 missingAmount;
        // Amount of veToken Boosts bought
        uint256 boughtAmount;
        // Minimum Percent of veBoost given by the Warden contract
        uint256 wardenMinRequiredPercent;
    }

    // Variables used in the For looping over the Offers
    struct OfferVars {
        // Total amount of Delegator's veCRV available for veBoost creation
        uint256 availableUserBalance;
        // Amount to buy from the current Offer
        uint256 toBuyAmount;
        // Address of the Delegator issuing the Boost
        address delegator;
        // Price listed in the Offer
        uint256 offerPrice;
        // Maximum duration for veBoost on this Offer
        uint256 offerMaxDuration;
        // Minimum required percent for veBoost on this Offer
        uint256 offerminPercent;
        // Amount of fees to pay for the veBoost creation
        uint256 boostFeeAmount;
        // Size in percent of the veBoost to create
        uint256 boostPercent;
        // ID of the newly created veBoost token
        uint256 newTokenId;
    }

    /**
     * @notice Loops over Warden Offers to purchase veBoosts depending on given parameters
     * @dev Using given parameters, loops over Offers given from the basic Warden order, to purchased Boosts that fit the given parameters
     * @param receiver Address of the veBoosts receiver
     * @param duration Duration (in weeks) for the veBoosts to purchase
     * @param boostAmount Total Amount of veCRV boost to purchase
     * @param maxPrice Maximum price for veBoost purchase (price is in feeToken/second, in wei), any Offer with a higher price will be skipped
     * @param minRequiredAmount Minimum size of the Boost to buy, smaller will be skipped
     * @param totalFeesAmount Maximum total amount of feeToken available to pay to for veBoost purchases (in wei)
     * @param acceptableSlippage Maximum acceptable slippage for the total Boost amount purchased (in BPS)
     */
    function simpleMultiBuy(
        address receiver,
        uint256 duration, //in number of weeks
        uint256 boostAmount,
        uint256 maxPrice,
        uint256 minRequiredAmount,
        uint256 totalFeesAmount,
        uint256 acceptableSlippage //BPS
    ) external returns (bool) {
        // Checks over parameters
        if(receiver == address(0)) revert Errors.ZeroAddress();
        if(boostAmount == 0 || totalFeesAmount == 0 || acceptableSlippage == 0) revert Errors.NullValue();
        if(maxPrice == 0) revert Errors.NullPrice();

        MultiBuyVars memory vars;

        // Calculate the duration of veBoosts to purchase
        vars.boostDuration = duration * 1 weeks;
        if(vars.boostDuration < warden.minDelegationTime()) revert Errors.DurationTooShort();

        // Fetch the total number of Offers to loop over
        vars.totalNbOffers = warden.offersIndex();

        // Calculate the expiryTime of veBoosts to create (used for later check over Seller veCRV lock__end)
        // For detailed explanation, see Warden _buyDelegationBoost() comments
        vars.boostEndTime = block.timestamp + vars.boostDuration;
        vars.expiryTime = (vars.boostEndTime / WEEK) * WEEK;
        vars.expiryTime = (vars.expiryTime < vars.boostEndTime)
            ? ((vars.boostEndTime + WEEK) / WEEK) * WEEK
            : vars.expiryTime;
        // Check the max total amount of fees to pay (using the maxPrice given as argument, Buyer should pay this amount or less in the end)
        if(((boostAmount * maxPrice * (vars.expiryTime - block.timestamp)) / UNIT) > totalFeesAmount) revert Errors.NotEnoughFees();

        // Get the current fee token balance of this contract
        vars.previousBalance = feeToken.balanceOf(address(this));

        // Pull the given token amount ot this contract (must be approved beforehand)
        feeToken.safeTransferFrom(msg.sender, address(this), totalFeesAmount);

        //Set the approval to 0, then set it to totalFeesAmount (CRV : race condition)
        if(feeToken.allowance(address(this), address(warden)) != 0) feeToken.safeApprove(address(warden), 0);
        feeToken.safeApprove(address(warden), totalFeesAmount);

        // The amount of veCRV to purchase through veBoosts
        // & the amount currently purchased, updated at every purchase
        vars.missingAmount = boostAmount;
        vars.boughtAmount = 0;

        vars.wardenMinRequiredPercent = warden.minPercRequired();

        // Loop over all the Offers
        for (uint256 i = 1; i < vars.totalNbOffers;) { //since the offer at index 0 is useless

            // Break the loop if the target veCRV amount is purchased
            if(vars.missingAmount == 0) break;

            OfferVars memory varsOffer;

            // Get the available amount of veCRV for the Delegator
            varsOffer.availableUserBalance = _availableAmount(i, maxPrice, vars.expiryTime);
            //Offer is not available or not in the required parameters
            if (varsOffer.availableUserBalance == 0) {
                unchecked{ ++i; }
                continue;
            }
            //Offer has an available amount smaller than the required minimum
            if (varsOffer.availableUserBalance < minRequiredAmount) {
                unchecked{ ++i; }
                continue;
            }

            // If the available amount if larger than the missing amount, buy only the missing amount
            varsOffer.toBuyAmount = varsOffer.availableUserBalance > vars.missingAmount ? vars.missingAmount : varsOffer.availableUserBalance;

            // Fetch the Offer data
            (varsOffer.delegator, varsOffer.offerPrice, varsOffer.offerMaxDuration,, varsOffer.offerminPercent,) = warden.getOffer(i);

            //If the asked duration is over the max duration for this offer, we skip
            if(duration > varsOffer.offerMaxDuration) {
                unchecked{ ++i; }
                continue;
            }

            // Calculate the amount of fees to pay for that Boost purchase
            varsOffer.boostFeeAmount = (varsOffer.toBuyAmount * varsOffer.offerPrice * (vars.expiryTime - block.timestamp)) / UNIT;

            // Calculate the size of the Boost to buy in percent (BPS)
            varsOffer.boostPercent = (varsOffer.toBuyAmount * MAX_PCT) / votingEscrow.balanceOf(varsOffer.delegator);
            // Offer available percent is under Warden's minimum required percent
            if(varsOffer.boostPercent < vars.wardenMinRequiredPercent || varsOffer.boostPercent < varsOffer.offerminPercent) {
                unchecked{ ++i; }
                continue;
            }

            // Purchase the Boost, retrieve the tokenId
            varsOffer.newTokenId = warden.buyDelegationBoost(varsOffer.delegator, receiver, varsOffer.toBuyAmount, duration, varsOffer.boostFeeAmount);

            // New tokenId should never be 0, if we receive a null ID, purchase failed
            if(varsOffer.newTokenId == 0) revert Errors.FailBoostPurchase();

            // Update the missingAmount, and the total amount purchased, with the last purchased executed
            vars.missingAmount -= varsOffer.toBuyAmount;
            vars.boughtAmount += varsOffer.toBuyAmount;

            unchecked{ ++i; }
        }

        // Compare the total purchased amount (sum of all veBoost amounts) with the given target amount
        // If the purchased amount does not fall in the acceptable slippage, revert the transaction
        if(vars.boughtAmount < ((boostAmount * (MAX_PCT - acceptableSlippage)) / MAX_PCT)) 
            revert Errors.CannotMatchOrder();

        //Return all unused feeTokens to the Buyer
        vars.endBalance = feeToken.balanceOf(address(this));
        feeToken.safeTransfer(msg.sender, (vars.endBalance - vars.previousBalance));

        return true;
    }

    /**
     * @notice Loops over a given Array of Warden Offers (pre-sorted if possible) to purchase veBoosts depending on given parameters
     * @dev Using given parameters, loops over Offers using the given Index array, to purchased Boosts that fit the given parameters
     * @param receiver Address of the veBoosts receiver
     * @param duration Duration (in weeks) for the veBoosts to purchase
     * @param boostAmount Total Amount of veCRV boost to purchase
     * @param maxPrice Maximum price for veBoost purchase (price is in feeToken/second, in wei), any Offer with a higher price will be skipped
     * @param minRequiredAmount Minimum size of the Boost to buy, smaller will be skipped
     * @param totalFeesAmount Maximum total amount of feeToken available to pay to for veBoost purchases (in wei)
     * @param acceptableSlippage Maximum acceptable slippage for the total Boost amount purchased (in BPS)
     * @param sortedOfferIndexes Array of Warden Offer indexes (that can be sorted/only containing a given set or Orders)
     */
    function preSortedMultiBuy(
        address receiver,
        uint256 duration,
        uint256 boostAmount,
        uint256 maxPrice,
        uint256 minRequiredAmount,
        uint256 totalFeesAmount,
        uint256 acceptableSlippage, //BPS
        uint256[] memory sortedOfferIndexes
    ) external returns (bool) {
        return _sortedMultiBuy(
        receiver,
        duration,
        boostAmount,
        maxPrice,
        minRequiredAmount,
        totalFeesAmount,
        acceptableSlippage,
        sortedOfferIndexes
        );
    }

    /**
     * @notice Loops over Warden Offers sorted through the Quicksort method, sorted by price, to purchase veBoosts depending on given parameters
     * @dev Using given parameters, loops over Offers using the order given through the Quicksort method, to purchased Boosts that fit the given parameters
     * @param receiver Address of the veBoosts receiver
     * @param duration Duration (in weeks) for the veBoosts to purchase
     * @param boostAmount Total Amount of veCRV boost to purchase
     * @param maxPrice Maximum price for veBoost purchase (price is in feeToken/second, in wei), any Offer with a higher price will be skipped
     * @param minRequiredAmount Minimum size of the Boost to buy, smaller will be skipped
     * @param totalFeesAmount Maximum total amount of feeToken available to pay to for veBoost purchases (in wei)
     * @param acceptableSlippage Maximum acceptable slippage for the total Boost amount purchased (in BPS)
     */
    function sortingMultiBuy(
        address receiver,
        uint256 duration,
        uint256 boostAmount,
        uint256 maxPrice,
        uint256 minRequiredAmount,
        uint256 totalFeesAmount,
        uint256 acceptableSlippage //BPS
    ) external returns (bool) {
        // Get the sorted Offers through Quicksort 
        uint256[] memory sortedOfferIndexes = _quickSortOffers();

        return _sortedMultiBuy(
        receiver,
        duration,
        boostAmount,
        maxPrice,
        minRequiredAmount,
        totalFeesAmount,
        acceptableSlippage,
        sortedOfferIndexes
        );
    }



    function _sortedMultiBuy(
        address receiver,
        uint256 duration,
        uint256 boostAmount,
        uint256 maxPrice,
        uint256 minRequiredAmount, //minimum size of the Boost to buy, smaller will be skipped
        uint256 totalFeesAmount,
        uint256 acceptableSlippage, //BPS
        uint256[] memory sortedOfferIndexes
    ) internal returns(bool) {
        // Checks over parameters
        if(receiver == address(0)) revert Errors.ZeroAddress();
        if(boostAmount == 0 || totalFeesAmount == 0 || acceptableSlippage == 0) revert Errors.NullValue();
        if(maxPrice == 0) revert Errors.NullPrice();


        MultiBuyVars memory vars;

        // Calculate the duration of veBoosts to purchase
        vars.boostDuration = duration * 1 weeks;
        if(vars.boostDuration < warden.minDelegationTime()) revert Errors.DurationTooShort();

        // Fetch the total number of Offers to loop over
        if(sortedOfferIndexes.length == 0) revert Errors.EmptyArray();

        // Calculate the expiryTime of veBoosts to create (used for later check over Seller veCRV lock__end)
        // For detailed explanation, see Warden _buyDelegationBoost() comments
        vars.boostEndTime = block.timestamp + vars.boostDuration;
        vars.expiryTime = (vars.boostEndTime / WEEK) * WEEK;
        vars.expiryTime = (vars.expiryTime < vars.boostEndTime)
            ? ((vars.boostEndTime + WEEK) / WEEK) * WEEK
            : vars.expiryTime;
        // Check the max total amount of fees to pay (using the maxPrice given as argument, Buyer should pay this amount or less in the end)
        if(((boostAmount * maxPrice * (vars.expiryTime - block.timestamp)) / UNIT) > totalFeesAmount) revert Errors.NotEnoughFees();

        // Get the current fee token balance of this contract
        vars.previousBalance = feeToken.balanceOf(address(this));

        // Pull the given token amount ot this contract (must be approved beforehand)
        feeToken.safeTransferFrom(msg.sender, address(this), totalFeesAmount);

        //Set the approval to 0, then set it to totalFeesAmount (CRV : race condition)
        if(feeToken.allowance(address(this), address(warden)) != 0) feeToken.safeApprove(address(warden), 0);
        feeToken.safeApprove(address(warden), totalFeesAmount);

        // The amount of veCRV to purchase through veBoosts
        // & the amount currently purchased, updated at every purchase
        vars.missingAmount = boostAmount;
        vars.boughtAmount = 0;

        vars.wardenMinRequiredPercent = warden.minPercRequired();

        // Loop over all the sorted Offers
        for (uint256 i = 0; i < sortedOfferIndexes.length;) {

            // Check that the given Offer Index is valid & listed in Warden
            if(sortedOfferIndexes[i] == 0 || sortedOfferIndexes[i] >= warden.offersIndex()) revert Errors.InvalidBoostOffer();

            // Break the loop if the target veCRV amount is purchased
            if(vars.missingAmount == 0) break;

            OfferVars memory varsOffer;

            // Get the available amount of veCRV for the Delegator
            varsOffer.availableUserBalance = _availableAmount(sortedOfferIndexes[i], maxPrice, vars.expiryTime);
            //Offer is not available or not in the required parameters
            if (varsOffer.availableUserBalance == 0) {
                unchecked{ ++i; }
                continue;
            }
            //Offer has an available amount smaller than the required minimum
            if (varsOffer.availableUserBalance < minRequiredAmount) {
                unchecked{ ++i; }
                continue;
            }

            // If the available amount if larger than the missing amount, buy only the missing amount
            varsOffer.toBuyAmount = varsOffer.availableUserBalance > vars.missingAmount ? vars.missingAmount : varsOffer.availableUserBalance;

            // Fetch the Offer data
            (varsOffer.delegator, varsOffer.offerPrice, varsOffer.offerMaxDuration,, varsOffer.offerminPercent,) = warden.getOffer(sortedOfferIndexes[i]);

            //If the asked duration is over the max duration for this offer, we skip
            if(duration > varsOffer.offerMaxDuration) {
                unchecked{ ++i; }
                continue;
            }

            // Calculate the amount of fees to pay for that Boost purchase
            varsOffer.boostFeeAmount = (varsOffer.toBuyAmount * varsOffer.offerPrice * (vars.expiryTime - block.timestamp)) / UNIT;

            // Calculate the size of the Boost to buy in percent (BPS)
            varsOffer.boostPercent = (varsOffer.toBuyAmount * MAX_PCT) / votingEscrow.balanceOf(varsOffer.delegator);
            // Offer available percent is under Warden's minimum required percent
            if(varsOffer.boostPercent < vars.wardenMinRequiredPercent || varsOffer.boostPercent < varsOffer.offerminPercent) {
                unchecked{ ++i; }
                continue;
            } 

            // Purchase the Boost, retrieve the tokenId
            varsOffer.newTokenId = warden.buyDelegationBoost(varsOffer.delegator, receiver, varsOffer.toBuyAmount, duration, varsOffer.boostFeeAmount);

            // New tokenId should never be 0, if we receive a null ID, purchase failed
            if(varsOffer.newTokenId == 0) revert Errors.FailBoostPurchase();

            // Update the missingAmount, and the total amount purchased, with the last purchased executed
            vars.missingAmount -= varsOffer.toBuyAmount;
            vars.boughtAmount += varsOffer.toBuyAmount;

            unchecked{ ++i; }
        }

        // Compare the total purchased amount (sum of all veBoost amounts) with the given target amount
        // If the purchased amount does not fall in the acceptable slippage, revert the transaction
        if(vars.boughtAmount < ((boostAmount * (MAX_PCT - acceptableSlippage)) / MAX_PCT)) 
            revert Errors.CannotMatchOrder();

        //Return all unused feeTokens to the Buyer
        vars.endBalance = feeToken.balanceOf(address(this));
        feeToken.safeTransfer(msg.sender, (vars.endBalance - vars.previousBalance));

        return true;
    }

    // Method used for Tests to get the sorted array of Offers
    function getSortedOffers() external view returns(uint[] memory) {
        return _quickSortOffers();
    }

    struct OfferInfos {
        address user;
        uint256 price;
    }

    function _quickSortOffers() internal view returns(uint[] memory){
        //Need to build up an array with values from 1 to OfferIndex => Need to find a better way to do it
        //To then sort the offers by price
        uint256 totalNbOffers = warden.offersIndex();

        // Fetch all the Offers listed in Warden, in memory using the OfferInfos struct
        OfferInfos[] memory offersList = new OfferInfos[](totalNbOffers - 1);
        uint256 length = offersList.length;
        for(uint256 i = 0; i < length;){ //Because the 0 index is an empty Offer
            (offersList[i].user, offersList[i].price,,,,) = warden.getOffer(i + 1);

            unchecked{ ++i; }
        }

        // Sort the list using the recursive method
        _quickSort(offersList, int(0), int(offersList.length - 1));

        // Build up the OfferIndex array used buy the MultiBuy method
        uint256[] memory sortedOffers = new uint256[](totalNbOffers - 1);
        uint256 length2 = offersList.length;
        for(uint256 i = 0; i < length2;){
            sortedOffers[i] = warden.userIndex(offersList[i].user);

            unchecked{ ++i; }
        }

        return sortedOffers;
    }

    // Quicksort logic => sorting the Offers based on price
    function _quickSort(OfferInfos[] memory offersList, int left, int right) internal view {
        int i = left;
        int j = right;
        if(i==j) return;
        OfferInfos memory pivot = offersList[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (offersList[uint(i)].price < pivot.price) i++;
            while (pivot.price < offersList[uint(j)].price) j--;
            if (i <= j) {
                (offersList[uint(i)], offersList[uint(j)]) = (offersList[uint(j)], offersList[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            _quickSort(offersList, left, j);
        if (i < right)
            _quickSort(offersList, i, right);
    }

    function _availableAmount(
        uint256 offerIndex,
        uint256 maxPrice,
        uint256 expiryTime
    ) internal view returns (uint256) {
        (
            address delegator,
            uint256 offerPrice,
            ,
            uint256 offerExpiryTime,
            uint256 minPerc,
            uint256 maxPerc
        ) = warden.getOffer(offerIndex);

        // Price of the Offer is over the maxPrice given
        if (offerPrice > maxPrice) return 0;

        // The Offer is expired
        if (block.timestamp > offerExpiryTime) return 0;

        // veCRV locks ends before wanted duration
        if (expiryTime >= votingEscrow.locked__end(delegator)) return 0;

        uint256 userBalance = votingEscrow.balanceOf(delegator);
        uint256 delegableBalance = delegationBoost.delegable_balance(delegator);

        // Percent of delegator balance not allowed to delegate (as set by maxPerc in the BoostOffer)
        uint256 blockedBalance = (userBalance * (MAX_PCT - maxPerc)) / MAX_PCT;
        // If the current delegableBalance is the the part of the balance not allowed for this market
        if(delegableBalance < blockedBalance) return 0;

        // Available Balance to delegate = Current Undelegated Balance - Blocked Balance
        uint256 availableBalance = delegableBalance - blockedBalance;

        // Minmum amount of veCRV for the boost for this Offer
        uint256 minBoostAmount = (userBalance * minPerc) / MAX_PCT;

        if(delegableBalance >= minBoostAmount) {
            // Warden cannot create the Boost
            if (delegationBoost.allowance(delegator, address(warden)) < availableBalance) return 0;

            return availableBalance;
        }

        return 0; //fallback => not enough availableBalance to propose the minimum Boost Amount allowed

    }

    function recoverERC20(address token, uint256 amount) external onlyOwner returns(bool) {
        IERC20(token).safeTransfer(owner(), amount);

        return true;
    }

}