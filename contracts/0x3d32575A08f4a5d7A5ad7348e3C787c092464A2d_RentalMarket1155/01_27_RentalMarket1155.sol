// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {LendOrder, RentOffer} from "../constant/RentalStructs.sol";
import "./BaseRentalMarket.sol";
import "./IRentalMarket1155.sol";
import "../bank/IBank1155.sol";

contract RentalMarket1155 is BaseRentalMarket, IRentalMarket1155 {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address admin_,
        address bank_
    ) public initializer {
        require(IBank(bank_).supportsInterface(type(IBank1155).interfaceId));
        _initialize(owner_, admin_, bank_);
    }

    function registerBank(address oNFT, address bank) external onlyAdmin {
        require(IBank(bank).supportsInterface(type(IBank1155).interfaceId));
        _registerBank(oNFT, bank);
    }

    function fulfillLendOrder1155(
        LendOrder calldata lendOrder,
        Signature calldata signature,
        uint64 tokenAmount,
        uint256 cycleAmount,
        IBank1155.RentingRecord[] calldata toDeletes
    ) external payable whenNotPaused nonReentrant {
        require(cycleAmount >= lendOrder.minCycleAmount, "invalid cycleAmount");
        bytes32 orderHash = _hashStruct_LendOrder(lendOrder);
        _validateOrder(
            lendOrder.maker,
            lendOrder.taker,
            lendOrder.nonce,
            orderHash
        );
        _validateSignature(lendOrder.maker, orderHash, signature);
        uint256 duration = lendOrder.price.cycle * cycleAmount;
        uint256 rentExpiry = block.timestamp + duration;
        require(duration <= maxDuration, "The duration is too long");
        require(
            rentExpiry <= lendOrder.maxRentExpiry,
            "The duration is too long"
        );
        _handleFrozen(lendOrder, tokenAmount, toDeletes);
        IBank1155.RecordParam memory param = IBank1155.RecordParam(
            0,
            lendOrder.nft.tokenType,
            lendOrder.nft.token,
            lendOrder.nft.tokenId,
            tokenAmount,
            lendOrder.maker,
            msg.sender,
            rentExpiry
        );
        IBank1155(bankOf(lendOrder.nft.token)).createUserRecord(param);

        _distributePayment(
            lendOrder.price,
            cycleAmount,
            tokenAmount,
            lendOrder.fees,
            lendOrder.maker,
            msg.sender
        );

        emit LendOrderFulfilled(
            orderHash,
            lendOrder.nft,
            lendOrder.price,
            tokenAmount,
            cycleAmount,
            lendOrder.maker,
            msg.sender
        );
    }

    function fulfillRentOffer1155(
        RentOffer calldata rentOffer,
        Signature calldata signature,
        IBank1155.RentingRecord[] calldata toDeletes
    ) public whenNotPaused nonReentrant {
        bytes32 offerHash = _hashStruct_RentOffer(rentOffer);
        _validateOrder(
            rentOffer.maker,
            rentOffer.taker,
            rentOffer.nonce,
            offerHash
        );
        require(
            block.timestamp <= rentOffer.offerExpiry,
            "The offer has expired"
        );
        _validateSignature(rentOffer.maker, offerHash, signature);
        IBank1155 bank = IBank1155(bankOf(rentOffer.nft.token));
        bank.deleteUserRecords(toDeletes);
        uint256 duration = rentOffer.price.cycle * rentOffer.cycleAmount;
        require(duration <= maxDuration, "The duration is too long");
        uint256 rentExpiry = block.timestamp + duration;
        IBank1155.RecordParam memory param = IBank1155.RecordParam(
            0,
            rentOffer.nft.tokenType,
            rentOffer.nft.token,
            rentOffer.nft.tokenId,
            rentOffer.nft.amount,
            msg.sender,
            rentOffer.maker,
            rentExpiry
        );
        bank.createUserRecord(param);

        _distributePayment(
            rentOffer.price,
            rentOffer.cycleAmount,
            rentOffer.nft.amount,
            rentOffer.fees,
            msg.sender,
            rentOffer.maker
        );
        cancelledOrFulfilled[offerHash] = true;

        emit RentOfferFulfilled(
            offerHash,
            rentOffer.nft,
            rentOffer.price,
            rentOffer.nft.amount,
            rentOffer.cycleAmount,
            msg.sender,
            rentOffer.maker
        );
    }

    function _handleFrozen(
        LendOrder calldata lendOrder,
        uint64 tokenAmount,
        IBank1155.RentingRecord[] calldata toDeletes
    ) internal {
        IBank1155 bank = IBank1155(bankOf(lendOrder.nft.token));
        bank.deleteUserRecords(toDeletes);
        uint256 frozenAmount = bank.frozenAmountOf(
            lendOrder.nft.token,
            lendOrder.nft.tokenId,
            lendOrder.maker
        );
        require(
            frozenAmount + tokenAmount <= lendOrder.nft.amount,
            "insufficient remaining amount"
        );
    }
}