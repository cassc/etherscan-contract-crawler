// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DefxInterfaces.sol";

uint256 constant MATCH_FEE = 25; // 25% (25 / 10000)
uint256 constant CANCEL_PENALTY = 300; // 3% (300 / 10000)
uint256 constant EXPIRY_BLOCKS = 2400; // expires in 2 weeks after bank details sent prod: 403200 test : 2400
uint256 constant SELLER_CANCEL_AFTER_BLOCKS = 1200; // seller can cancel deal in 1h after bank details've been sent
uint256 constant MIN_RATIO = 11000;

uint256 constant FIAT_DECIMALS = 10000;
uint256 constant CRYPTO_DECIMALS = 10**18;

library DefxHelpers {
    using SafeMath for uint256;

    event DealFinished(address indexed buyer, address indexed seller, uint256 amountCrypto, uint256 amountFiat, string status);

    event OfferUpdated(bool indexed isBuy, address indexed creator, uint256 available);

    modifier onlyParticipant(address buyer, address seller) {
        require(buyer == msg.sender || seller == msg.sender, "Defx: FORBIDDEN");
        _;
    }

    function createOffer(Offer storage offer, CreateOfferParams memory params) external {
        require(offer.collateral == 0, "Defx: OFFER_EXISTS");
        require(params._paymentMethods.length > 0, "Defx: !PAYMENT_METHODS");
        require(params._price > 0, "Defx: !PRICE");
        require(params._ratio >= MIN_RATIO, "Defx: RATIO_LIMIT");

        uint256 offerCollateral;
        if (!params._isBuy || params._max == 0) {
            offerCollateral = params._available.mul(params._ratio).div(FIAT_DECIMALS);
        } else {
            offerCollateral = params
                ._deposit
                // rounding collateral to ratio
                .div(params._ratio)
                .mul(params._ratio);
        }
        require(offerCollateral > 0, "Defx: INVALID_DEPOSIT");

        TransferHelper.safeTransferFrom(params._cryptoAddress, msg.sender, address(this), offerCollateral);

        offer.collateral = offerCollateral;
        offer.available = params._available;
        offer.min = params._min;
        offer.max = params._max;
        offer.price = params._price;
        offer.paymentMethods = params._paymentMethods;
        offer.desc = params._desc;
        offer.ratio = params._ratio;

        _renewOffer(offer, params._isBuy, msg.sender);
    }

    function matchOffer(
        Offer storage offer,
        Deal storage deal,
        DealLinks storage dealLinks,
        MatchParams memory params
    ) external {
        // fixed or limited offer
        uint256 amountCrypto = offer.max > 0 ? params.amountCrypto : offer.available;
        deal.amountCrypto = amountCrypto;

        require(amountCrypto <= offer.available, "Defx: INSUFFICIENT_OFFER_AVAILABLE");

        uint256 amountFiat = amountCrypto.mul(offer.price).div(CRYPTO_DECIMALS);
        deal.amountFiat = amountFiat;

        // for limit offer check min / max
        if (offer.max > 0) {
            require(amountFiat >= offer.min && amountFiat <= offer.max, "Defx: !MIN_MAX");
        }

        deal.isBuyerOwner = params.isBuy;
        deal.paymentMethod = params.paymentMethod;

        uint256 dealCollateral = amountCrypto.mul(offer.ratio).div(FIAT_DECIMALS);
        deal.collateral = dealCollateral;
        require(dealCollateral > 0 && offer.collateral >= dealCollateral, "Defx: INSUFFICIENT_OFFER_COLLATERAL");

        uint256 fee = amountCrypto.mul(MATCH_FEE).div(FIAT_DECIMALS);

        // taking collateral + fee from matcher
        TransferHelper.safeTransferFrom(params.cryptoAddress, msg.sender, address(this), deal.collateral);
        // taking fee and sending to factory
        TransferHelper.safeTransferFrom(params.cryptoAddress, msg.sender, params.factory, fee);

        offer.collateral = offer.collateral.sub(deal.collateral);
        offer.available = offer.available.sub(amountCrypto);

        _addLinks(dealLinks, params.isBuy, params.owner, msg.sender);
        _renewOffer(offer, params.isBuy, params.owner);
    }

    function withdraw(
        address cryptoAddress,
        Offer storage offer,
        bool isBuy,
        uint256 toWithdraw
    ) external {
        require(offer.collateral >= toWithdraw, "Defx: !BALANCE");
        if (offer.collateral == toWithdraw) {
            _deleteOffer(cryptoAddress, offer);
            return;
        }
        TransferHelper.safeTransfer(cryptoAddress, msg.sender, toWithdraw);
        offer.collateral = offer.collateral.sub(toWithdraw);
        if (!isBuy || offer.max == 0) {
            offer.available = offer.collateral.mul(FIAT_DECIMALS).div(offer.ratio);
        }
    }

    function editOfferAvailable(
        address cryptoAddress,
        Offer storage offer,
        bool _isBuy,
        uint256 _available,
        uint256 _price,
        uint256 _min,
        uint256 _max
    ) external {
        require(offer.collateral > 0, "Defx: INVALID_OFFER");
        // delete offer if available is 0
        if (_available == 0) {
            _deleteOffer(cryptoAddress, offer);
            return;
        }

        uint256 requiredOfferCollateral = _max == 0 || !_isBuy
            ? _available.mul(offer.ratio).div(FIAT_DECIMALS) // buy limited offer should have enough collateral for at least one max trade
            : _max.mul(10**14).mul(offer.ratio).div(_price);

        if (offer.collateral < requiredOfferCollateral) {
            // deposit
            TransferHelper.safeTransferFrom(cryptoAddress, msg.sender, address(this), requiredOfferCollateral.sub(offer.collateral));
            offer.collateral = requiredOfferCollateral;
        } else if ((_max == 0 || !_isBuy) && offer.collateral > requiredOfferCollateral) {
            // withdraw
            TransferHelper.safeTransfer(cryptoAddress, msg.sender, offer.collateral.sub(requiredOfferCollateral));
            offer.collateral = requiredOfferCollateral;
        }

        offer.available = _available;
        offer.price = _price;
        offer.min = _min;
        offer.max = _max;
        _renewOffer(offer, _isBuy, msg.sender);
    }

    function editOfferParams(
        Offer storage offer,
        bool _isBuy,
        string[] memory _paymentMethods,
        string memory _desc
    ) external {
        require(offer.collateral > 0, "Defx: INVALID_OFFER");
        offer.paymentMethods = _paymentMethods;
        offer.desc = _desc;
        emit OfferUpdated(_isBuy, msg.sender, offer.available);
    }

    function editOfferPrice(
        Offer storage offer,
        bool _isBuy,
        uint256 _price
    ) external {
        require(offer.collateral > 0, "Defx: INVALID_OFFER");
        offer.price = _price;
        emit OfferUpdated(_isBuy, msg.sender, offer.available);
    }

    function cancelDeal(
        address factory,
        address cryptoAddress,
        Offer storage offer,
        Deal storage deal,
        address buyer,
        address seller,
        DealLinks storage dealLinks
    ) public onlyParticipant(buyer, seller) {
        _validateDeal(deal);

        if (msg.sender == seller) {
            require(!deal.fiatSent, "Defx: FIAT_SENT");
            require(deal.bankSentAtBlock == 0 || deal.bankSentAtBlock + SELLER_CANCEL_AFTER_BLOCKS <= block.number, "Defx: DEAL_TIMEOUT");
        }

        // if fee
        if (msg.sender == buyer && deal.messages.length > 0) {
            uint256 cancellationFee = deal.amountCrypto.mul(CANCEL_PENALTY).div(FIAT_DECIMALS);
            // sending fee to factory
            TransferHelper.safeTransferFrom(cryptoAddress, msg.sender, factory, cancellationFee);
        }

        // return available to offer
        offer.available = offer.available.add(deal.amountCrypto);

        offer.collateral = offer.collateral.add(deal.collateral);
        TransferHelper.safeTransfer(cryptoAddress, deal.isBuyerOwner ? seller : buyer, deal.collateral);

        emit DealFinished(buyer, seller, deal.amountCrypto, deal.amountFiat, "cancelled");
        emit OfferUpdated(deal.isBuyerOwner, deal.isBuyerOwner ? buyer : seller, offer.available);
        _incrementFailedDeal(factory, buyer, seller);

        _deleteDeal(deal);

        _cleanLinks(dealLinks, buyer, seller);
    }

    function confirmFiatReceived(
        address factory,
        address cryptoAddress,
        Offer storage offer,
        Deal storage deal,
        address buyer,
        DealLinks storage dealLinks
    ) public {
        require(deal.messages.length > 0, "Defx: NO_BANK_ACC");
        _validateDeal(deal);

        // send crypto to buyer
        TransferHelper.safeTransfer(cryptoAddress, buyer, deal.amountCrypto);

        // send collateral back to buyer
        if (offer.max > 0 && deal.isBuyerOwner) {
            offer.collateral = offer.collateral.add(deal.collateral);
        } else {
            TransferHelper.safeTransfer(cryptoAddress, buyer, deal.collateral);
        }

        // send collateral to seller
        TransferHelper.safeTransfer(cryptoAddress, msg.sender, deal.collateral.sub(deal.amountCrypto));

        emit DealFinished(buyer, msg.sender, deal.amountCrypto, deal.amountFiat, "success");
        _incrementCompletedDeal(factory, buyer, msg.sender);
        _deleteDeal(deal);

        _cleanLinks(dealLinks, buyer, msg.sender);
    }

    function liquidateDeal(
        address factory,
        address cryptoAddress,
        Deal storage deal,
        address buyer,
        address seller,
        DealLinks storage dealLinks
    ) external {
        require(deal.bankSentAtBlock > 0 && deal.bankSentAtBlock + EXPIRY_BLOCKS < block.number, "Defx: VALID_DEAL");

        // send all collaterals to factory
        TransferHelper.safeTransfer(cryptoAddress, factory, deal.collateral.mul(2));

        emit DealFinished(buyer, seller, deal.amountCrypto, deal.amountFiat, "liquidated");
        _incrementFailedDeal(factory, buyer, seller);

        _cleanLinks(dealLinks, buyer, seller);

        _deleteDeal(deal);
    }

    function fiatSent(Deal storage deal) external {
        require(deal.collateral > 0, "Defx: INVALID_DEAL");
        require(deal.messages.length > 0, "Defx: NO_BANK_ACC");
        deal.fiatSent = true;
    }

    function sendMessage(
        Deal storage deal,
        address buyer,
        address seller,
        string memory encryptedForSeller,
        string memory encryptedForBuyer
    ) external onlyParticipant(buyer, seller) {
        _validateDeal(deal);
        require(deal.messages.length > 0 || msg.sender == seller, "Defx: FIRST_MESSAGE_ONLY_SELLER");

        if (deal.messages.length == 0) {
            deal.bankSentAtBlock = block.number;
        }

        deal.messages.push(Message({encryptedForSeller: encryptedForSeller, encryptedForBuyer: encryptedForBuyer, from: msg.sender}));
    }

    function submitFeedbackFrom(
        address factory,
        address buyer,
        bool isPositive,
        string calldata desc
    ) external {
        IDefxStat(IDefxFactory(factory).statAddress()).submitFeedbackFrom(msg.sender, buyer, isPositive, desc);
    }

    function _validateDeal(Deal memory deal) internal view {
        require(deal.collateral > 0, "Defx: NO_DEAL");
        require(deal.bankSentAtBlock == 0 || deal.bankSentAtBlock + EXPIRY_BLOCKS >= block.number, "Defx: DEAL_EXPIRED");
    }

    function _renewOffer(
        Offer storage offer,
        bool _isBuy,
        address owner
    ) internal {
        offer.lastUpdatedBlock = block.number;
        emit OfferUpdated(_isBuy, owner, offer.available);
    }

    function _incrementCompletedDeal(
        address factory,
        address buyer,
        address seller
    ) internal {
        IDefxStat stats = IDefxStat(IDefxFactory(factory).statAddress());
        stats.incrementCompletedDeal(buyer, seller);
        stats.setFeedbackAllowed(buyer, seller);
    }

    function _incrementFailedDeal(
        address factory,
        address buyer,
        address seller
    ) internal {
        IDefxStat stats = IDefxStat(IDefxFactory(factory).statAddress());
        stats.incrementFailedDeal(buyer, seller);
        stats.setFeedbackAllowed(buyer, seller);
    }

    function _addLinks(
        DealLinks storage dealLinks,
        bool isBuy,
        address owner,
        address matcher
    ) internal {
        if (isBuy) {
            dealLinks.buyers[matcher].push(owner);
            dealLinks.sellers[owner].push(matcher);
        } else {
            dealLinks.buyers[owner].push(matcher);
            dealLinks.sellers[matcher].push(owner);
        }
    }

    function _deleteOffer(address cryptoAddress, Offer storage offer) internal {
        TransferHelper.safeTransfer(cryptoAddress, msg.sender, offer.collateral);
        offer.collateral = 0;
        offer.available = 0;
    }

    function _deleteDeal(Deal storage deal) internal {
        deal.collateral = 0;
        deal.amountCrypto = 0;
        deal.bankSentAtBlock = 0;
        deal.fiatSent = false;
        delete deal.messages;
    }

    function _cleanLinks(
        DealLinks storage dealLinks,
        address buyer,
        address seller
    ) internal {
        _removeLink(dealLinks.buyers[seller], buyer);
        _removeLink(dealLinks.sellers[buyer], seller);
    }

    function _removeLink(address[] storage array, address addrToDelete) internal {
        bool deleted;
        for (uint256 i = 0; i < array.length - 1; i++) {
            if (deleted) {
                array[i] = array[i + 1];
            } else if (array[i] == addrToDelete) {
                deleted = true;
            }
        }
        array.pop();
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }
}