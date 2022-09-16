// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./DefxHelpers.sol";

contract DefxPair is IDefxPair {
    address public factory;
    address public cryptoAddress;
    string public fiatCode;

    event DealFinished(address indexed buyer, address indexed seller, uint256 amountCrypto, uint256 amountFiat, string status);

    DealLinks private dealLinks;

    mapping(address => mapping(bool => Offer)) public offers; /* owner => isBuyOffer */

    mapping(address => mapping(address => Deal)) public deals; /* buyer */ /* seller */

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _tokenAddress, string memory _fiatCode) external {
        require(msg.sender == factory, "Defx: FORBIDDEN");
        cryptoAddress = _tokenAddress;
        fiatCode = _fiatCode;
    }

    modifier hasEncKey() {
        require(bytes(IDefxFactory(factory).encKeys(msg.sender)).length > 0, "Defx: NO_ENC_KEY");
        _;
    }

    function getBuyers(address seller) public view returns (address[] memory) {
        return dealLinks.buyers[seller];
    }

    function getSellers(address buyer) public view returns (address[] memory) {
        return dealLinks.sellers[buyer];
    }

    function createOffer(
        bool _isBuy,
        uint256 _deposit,
        uint256 _available,
        uint256 _min,
        uint256 _max,
        uint256 _price,
        uint256 _ratio,
        string[] memory _paymentMethods,
        string memory _desc
    ) external hasEncKey {
        // forbids creating offer with existing active deals
        require((_isBuy ? dealLinks.sellers[msg.sender] : dealLinks.buyers[msg.sender]).length == 0, "Defx: ACTIVE_DEAL");

        DefxHelpers.createOffer(
            offers[msg.sender][_isBuy],
            CreateOfferParams({
                _cryptoAddress: cryptoAddress,
                _isBuy: _isBuy,
                _deposit: _deposit,
                _available: _available,
                _min: _min,
                _max: _max,
                _price: _price,
                _ratio: _ratio,
                _paymentMethods: _paymentMethods,
                _desc: _desc
            })
        );
    }

    function matchOffer(
        address owner,
        bool isBuy,
        uint256 amountCrypto,
        string memory paymentMethod,
        string memory encryptedForSeller,
        string memory encryptedForBuyer
    ) external hasEncKey {
        (Offer storage offer, Deal storage deal) = _getOfferDeal(owner, isBuy);
        require(owner != msg.sender, "Defx: SELF_MATCH");
        require(deal.collateral == 0, "Defx: DEAL_EXISTS");

        DefxHelpers.matchOffer(
            offer,
            deal,
            dealLinks,
            MatchParams({
                factory: factory,
                cryptoAddress: cryptoAddress,
                owner: owner,
                isBuy: isBuy,
                amountCrypto: amountCrypto,
                paymentMethod: paymentMethod
            })
        );
        if (isBuy) {
            // require(bytes(encryptedForSeller).length > 0 && bytes(encryptedForBuyer).length > 0, "Defx: BANK_REQUIRED");
            deal.bankSentAtBlock = block.number;
            deal.messages.push(Message({encryptedForSeller: encryptedForSeller, encryptedForBuyer: encryptedForBuyer, from: msg.sender}));
        }
    }

    function getOffer(address owner, bool isBuy) external view returns (Offer memory) {
        return offers[owner][isBuy];
    }

    function getDeal(address buyer, address seller) external view returns (Deal memory) {
        return deals[buyer][seller];
    }

    function _getOfferDeal(address owner, bool isBuy) internal view returns (Offer storage off, Deal storage) {
        return (offers[owner][isBuy], isBuy ? deals[owner][msg.sender] : deals[msg.sender][owner]);
    }

    function sendMessage(
        address buyer,
        address seller,
        string memory encryptedForSeller,
        string memory encryptedForBuyer
    ) external {
        DefxHelpers.sendMessage(deals[buyer][seller], buyer, seller, encryptedForSeller, encryptedForBuyer);
    }

    function _getDealOfferByParticipants(address buyer, address seller) internal view returns (Deal storage deal, Offer storage offer) {
        deal = deals[buyer][seller];
        offer = deal.isBuyerOwner ? offers[buyer][true] : offers[seller][false];
    }

    function cancelDeal(address buyer, address seller) external {
        (Deal storage deal, Offer storage offer) = _getDealOfferByParticipants(buyer, seller);
        DefxHelpers.cancelDeal(factory, cryptoAddress, offer, deal, buyer, seller, dealLinks);
    }

    function confirmFiatReceived(address buyer) public {
        (Deal storage deal, Offer storage offer) = _getDealOfferByParticipants(buyer, msg.sender);
        DefxHelpers.confirmFiatReceived(factory, cryptoAddress, offer, deal, buyer, dealLinks);
    }

    function confirmFiatReceivedWithFeedback(
        address buyer,
        bool isPositive,
        string calldata desc
    ) external {
        confirmFiatReceived(buyer);
        DefxHelpers.submitFeedbackFrom(factory, buyer, isPositive, desc);
    }

    function fiatSent(address seller) external {
        DefxHelpers.fiatSent(deals[msg.sender][seller]);
    }

    function liquidateDeal(address buyer, address seller) external {
        DefxHelpers.liquidateDeal(factory, cryptoAddress, deals[buyer][seller], buyer, seller, dealLinks);
    }

    function withdraw(bool _isBuy, uint256 _toWithdraw) external {
        DefxHelpers.withdraw(cryptoAddress, offers[msg.sender][_isBuy], _isBuy, _toWithdraw);
    }

    function editOfferAvailable(
        bool _isBuy,
        uint256 _available,
        uint256 _price,
        uint256 _min,
        uint256 _max
    ) external {
        DefxHelpers.editOfferAvailable(cryptoAddress, offers[msg.sender][_isBuy], _isBuy, _available, _price, _min, _max);
    }

    function editOfferParams(
        bool _isBuy,
        string[] calldata _paymentMethods,
        string calldata _desc
    ) external {
        DefxHelpers.editOfferParams(offers[msg.sender][_isBuy], _isBuy, _paymentMethods, _desc);
    }

    function editOfferPrice(bool _isBuy, uint256 _price) public {
        DefxHelpers.editOfferPrice(offers[msg.sender][_isBuy], _isBuy, _price);
    }

    function renewOffer(bool _isBuy) public {
        DefxHelpers._renewOffer(offers[msg.sender][_isBuy], _isBuy, msg.sender);
    }
}