// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DefxInterfaces.sol";


// service vars
uint256 constant FOUR_DECIMALS = 10000;
uint256 constant CRYPTO_DECIMALS = 10**18;

// fees
uint256 constant MATCH_FEE = 25; // 0.25% (25 / 10000)
uint256 constant CANCEL_PENALTY = 300; // 3% (300 / 10000)

// restrictions
uint256 constant MIN_RATIO = 1500; // 15%

// timeouts
uint256 constant SELLER_CANCEL_TIMEOUT = 1200; // 1200 seller can cancel deal in 1h after bank details've been sent
uint256 constant CASH_SELLER_CANCEL_TIMEOUT = 28800 * 5; // 28800 * 5; // 1 day = 28800
uint256 constant DISPUTE_TIMEOUT = 28800 * 2; // 5 mins

library DefxHelpers {
    using SafeMath for uint256;

    event DealFinished(address indexed buyer, address indexed seller, uint256 amountCrypto, uint256 amountFiat, string status);

    event OfferUpdated(bool indexed isBuy, address indexed creator, uint256 available);

    modifier onlyParticipant(address buyer, address seller) {
        require(buyer == msg.sender || seller == msg.sender, "Defx: FORBIDDEN");
        _;
    }

    function createOffer(
        Offer storage offer,
        CreateOfferParams memory params,
        DealLinks storage dealLinks
    ) external {
        require(offer.collateral == 0, "Defx: OFFER_EXISTS");
        require(params._paymentMethods.length > 0, "Defx: !PAYMENT_METHODS");
        require(params._price > 0, "Defx: !PRICE");
        require(params._ratio >= MIN_RATIO, "Defx: RATIO_LIMIT");
        // forbids creating offer with existing active deals
        require((params._isBuy ? dealLinks.sellers[msg.sender] : dealLinks.buyers[msg.sender]).length == 0, "Defx: ACTIVE_DEAL");

        uint256 offerCollateral;

        // sell offer
        if (!params._isBuy) {
            offerCollateral = params._available.mul(params._ratio).div(FOUR_DECIMALS).add(params._available);
        }
        // fixed buy offer
        else if (params._isBuy && params._max == 0) {
            offerCollateral = params._available.mul(params._ratio).div(FOUR_DECIMALS);
        }
        // partial buy offer
        else {
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
        require(deal.collateral == 0, "Defx: DEAL_EXISTS");
        require(params.owner != msg.sender, "Defx: SELF_MATCH");

        // fixed or limited offer
        uint256 amountCrypto = offer.max > 0 ? params.amountCrypto : offer.available;
        require(amountCrypto <= offer.available, "Defx: INSUFFICIENT_OFFER_AVAILABLE");
        deal.amountCrypto = amountCrypto;

        uint256 amountFiat = amountCrypto.mul(offer.price).div(CRYPTO_DECIMALS);
        deal.amountFiat = amountFiat;

        // for limit offer check min / max
        if (offer.max > 0) {
            require(amountFiat >= offer.min && amountFiat <= offer.max, "Defx: !MIN_MAX");
        }

        deal.isBuyerOwner = params.isBuy;
        deal.paymentMethod = params.paymentMethod;

        uint256 dealCollateral = amountCrypto.mul(offer.ratio).div(FOUR_DECIMALS);
        require(dealCollateral > 0 && offer.collateral >= dealCollateral, "Defx: INSUFFICIENT_OFFER_COLLATERAL");
        deal.collateral = dealCollateral;

        uint256 fee = amountCrypto.mul(MATCH_FEE).div(FOUR_DECIMALS);

        // seller should lock tradingAmount + collateral
        uint256 matcherDeposit = params.isBuy ? dealCollateral.add(amountCrypto) : dealCollateral;
        // taking collateral + fee from matcher
        TransferHelper.safeTransferFrom(params.cryptoAddress, msg.sender, address(this), matcherDeposit);
        // taking fee and sending to factory
        TransferHelper.safeTransferFrom(params.cryptoAddress, msg.sender, params.factory, fee);

        offer.collateral = offer.collateral.sub(deal.collateral);
        if (!params.isBuy) {
            // for sell offers take trading amount from offer collateral
            offer.collateral = offer.collateral.sub(deal.amountCrypto);
        }
        offer.available = offer.available.sub(amountCrypto);

        _addLinks(dealLinks, params.isBuy, params.owner, msg.sender);
        _renewOffer(offer, params.isBuy, params.owner);

        bool isCash = bytes(params.paymentMethod).length == 0;
        if (isCash) {
            deal.startAtBlock = block.number;
        } else if (params.isBuy) {
            deal.startAtBlock = block.number;
            // sending bank details only for non-cash buy offers
            deal.messages.push(Message({data: params.messageData, isFromBuyer: !params.isBuy}));
        }
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

        if (!isBuy) {
            // example sell offer:
            // ratio: 0.3
            // collateral: 130
            // available = collateral / (1 + ratio) = 100
            offer.available = offer.collateral.mul(FOUR_DECIMALS).div(FOUR_DECIMALS.add(offer.ratio));
        } else if (offer.max == 0) {
            // example fixed buy offer:
            // ratio: 0.3
            // collateral: 30
            // available = collateral / ratio = 100
            offer.available = offer.collateral.mul(FOUR_DECIMALS).div(offer.ratio);
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
            ? _available.mul(offer.ratio).div(FOUR_DECIMALS) // buy limited offer should have enough collateral for at least one max trade
            : _max.mul(10**14).mul(offer.ratio).div(_price);

        if (!_isBuy) {
            // for sell offers trading amount should be staked too
            requiredOfferCollateral = requiredOfferCollateral.add(_available);
        }

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
    ) external onlyParticipant(buyer, seller) {
        _validateDeal(deal);
        bool isCash = bytes(deal.paymentMethod).length == 0;

        if (isCash) {
            // seller can cancel deal only afer timeout
            require(msg.sender == buyer || deal.startAtBlock + CASH_SELLER_CANCEL_TIMEOUT <= block.number, "Defx: FORBIDDEN");
        } else if (msg.sender == seller) {
            require(!deal.fiatSent, "Defx: FIAT_SENT");
            require(deal.startAtBlock == 0 || deal.startAtBlock + SELLER_CANCEL_TIMEOUT <= block.number, "Defx: DEAL_TIMEOUT");
        }

        // charging fee; no cancellation fee for cash deals
        if (!isCash && msg.sender == buyer && deal.messages.length > 0) {
            uint256 cancellationFee = deal.amountCrypto.mul(CANCEL_PENALTY).div(FOUR_DECIMALS);
            // sending fee to factory
            TransferHelper.safeTransferFrom(cryptoAddress, msg.sender, factory, cancellationFee);
        }

        // return available to offer
        offer.available = offer.available.add(deal.amountCrypto);
        address matcher = deal.isBuyerOwner ? seller : buyer;
        (uint256 toOffer, uint256 toMatcher) = deal.isBuyerOwner
            ? (deal.collateral, deal.collateral.add(deal.amountCrypto))
            : (deal.collateral.add(deal.amountCrypto), deal.collateral);
        offer.collateral = offer.collateral.add(toOffer);
        TransferHelper.safeTransfer(cryptoAddress, matcher, toMatcher);

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
        TransferHelper.safeTransfer(cryptoAddress, msg.sender, deal.collateral);

        emit DealFinished(buyer, msg.sender, deal.amountCrypto, deal.amountFiat, "success");
        _incrementCompletedDeal(factory, buyer, msg.sender);
        _deleteDeal(deal);

        _cleanLinks(dealLinks, buyer, msg.sender);
    }

    function fiatSent(Deal storage deal) external {
        _validateDeal(deal);
        require(deal.messages.length > 0, "Defx: NO_BANK_ACC");
        deal.fiatSent = true;
    }

    function sendMessage(
        Deal storage deal,
        address buyer,
        address seller,
        string memory data
    ) external onlyParticipant(buyer, seller) {
        _validateDeal(deal);
        bool isCash = bytes(deal.paymentMethod).length == 0;
        if (!isCash) {
            require(deal.messages.length > 0 || msg.sender == seller, "Defx: FIRST_MESSAGE_ONLY_SELLER");

            if (deal.messages.length == 0) {
                deal.startAtBlock = block.number;
            }
        }

        deal.messages.push(Message({data: data, isFromBuyer: msg.sender == buyer}));
    }

    function openDispute(
        address buyer,
        address seller,
        Deal storage deal
    ) external onlyParticipant(buyer, seller) {
        require(deal.collateral > 0 && deal.disputeFromBlock == 0, "Defx: INVALID");
        deal.disputeFromBlock = block.number;
    }

    function closeDispute(
        address cryptoAddress,
        address factory,
        address buyer,
        address seller,
        Deal storage deal,
        DealLinks storage dealLinks
    ) external {
        address disputeContract = IDefxFactory(factory).disputeContract();
        require(msg.sender == disputeContract, "Defx: ONLY_DISPUTE_CONTRACT");
        require(deal.disputeFromBlock > 0, "Defx: NO_DISPUTE");
        require(deal.disputeFromBlock + DISPUTE_TIMEOUT < block.number, "Defx: DISPUTE_FREEZE");
        TransferHelper.safeTransfer(cryptoAddress, disputeContract, deal.collateral.mul(2).add(deal.amountCrypto));
        _deleteDeal(deal);
        _cleanLinks(dealLinks, buyer, seller);
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
        require(deal.collateral > 0, "Defx: INVALID_DEAL");
        require(deal.disputeFromBlock == 0 || deal.disputeFromBlock + DISPUTE_TIMEOUT > block.number, "Defx: UNDER_DISPUTE");
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
        deal.startAtBlock = 0;
        deal.fiatSent = false;
        deal.disputeFromBlock = 0;
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