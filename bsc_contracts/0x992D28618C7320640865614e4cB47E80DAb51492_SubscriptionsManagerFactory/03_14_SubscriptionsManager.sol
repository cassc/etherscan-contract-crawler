// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./BillingDate.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SubscriptionsManager is ERC721, Ownable, BillingDate {
    struct Subscription {
        uint256 price;
        uint256 expiration;
        uint16 paymentTokenIndex;
        uint8 billingDay;
        bool isAutoRenewable;
    }
    struct PaymentToken {
        uint256 price;
        address _address;
        bool isActive;
    }

    uint256 public totalSupply;
    address public admin;
    uint16 public adminFee;

    PaymentToken[] public paymentTokens;

    mapping(uint256 => Subscription) public subscriptions;
    mapping(uint8 => uint256[]) public subscriptionsByBillingDay;
    mapping(address => uint256) public ownedTokens;

    event Subscribed(
        address indexed user,
        uint256 indexed tokenId,
        uint8 indexed billingDay,
        uint256 price,
        uint256 expiration,
        address erc20Token
    );
    event SubscriptionRenewed(
        address indexed user,
        uint256 indexed tokenId,
        uint256 price,
        uint256 expiration,
        address erc20Token
    );
    event SubscriptionBurned(
        address indexed user,
        uint256 indexed tokenId,
        uint8 indexed billingDay,
        uint256 price,
        address erc20Token
    );
    event AddPaymentToken(uint256 indexed price, address indexed _address);
    event SetPaymentToken(
        uint16 indexed index,
        uint256 price,
        bool indexed isActive
    );
    event Erc20TokenClaimed(address indexed erc20Token, uint256 indexed amount);
    event SetAdminFee(uint16 adminFee);

    error SubscriptionNotExpired();
    error AlreadySubscribed();
    error InvalidPaymentToken();
    error InactivePaymentToken();

    constructor(
        string memory name,
        string memory symbol,
        address owner_,
        address admin_,
        uint16 adminFee_
    ) ERC721(name, symbol) {
        _transferOwnership(owner_);
        admin = admin_;
        adminFee = adminFee_;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Forbidden, caller is not the admin");
        _;
    }

    function getUserSubscription(address user)
        external
        view
        returns (Subscription memory)
    {
        return subscriptions[ownedTokens[user]];
    }

    function getSubscriptionsByBillingDay(uint8 billingDay)
        public
        view
        returns (uint256[] memory ids)
    {
        ids = subscriptionsByBillingDay[billingDay];
    }

    function subscribe(uint16 paymentTokenIndex) external {
        if (ownedTokens[msg.sender] != 0) revert AlreadySubscribed();

        (
            uint8 billingDay,
            uint256 nextBillingTimestamp
        ) = parseBillingTimestamp(block.timestamp);

        PaymentToken memory paymentToken = paymentTokens[paymentTokenIndex];

        uint256 tokenId = ++totalSupply;
        subscriptions[tokenId] = Subscription({
            price: paymentToken.price,
            expiration: nextBillingTimestamp,
            billingDay: billingDay,
            paymentTokenIndex: paymentTokenIndex,
            isAutoRenewable: true
        });
        ownedTokens[msg.sender] = tokenId;
        subscriptionsByBillingDay[billingDay].push(tokenId);

        _mint(msg.sender, tokenId);

        address erc20Token = paymentTokens[paymentTokenIndex]._address;
        IERC20(erc20Token).transferFrom(
            msg.sender,
            owner(),
            paymentToken.price
        );

        emit Subscribed(
            msg.sender,
            tokenId,
            billingDay,
            paymentToken.price,
            nextBillingTimestamp,
            erc20Token
        );
    }

    function renewByBillingDay(
        uint8 billingDay,
        uint256 _start,
        uint256 _limit
    ) external {
        uint256[] memory ids = subscriptionsByBillingDay[billingDay];
        if (_limit == 0) _limit = ids.length;
        require(
            ids.length >= _limit && _start < _limit,
            "Invalid pagination params"
        );

        uint256 lastIndex = ids.length - 1;
        uint256[] storage storageIds = subscriptionsByBillingDay[billingDay];

        for (uint256 index = _start; index < _limit; ) {
            uint256 id = ids[index];
            if (id == 0) break;

            bool success = _renewSubscription(id);

            if (success) index++;
            else {
                subscriptions[id].isAutoRenewable = false;
                storageIds[index] = storageIds[lastIndex];
                storageIds.pop();

                ids[index] = ids[lastIndex];
                delete ids[lastIndex];

                if (lastIndex > 0) lastIndex--;
            }
        }
    }

    function renewSubscriptions(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 id = ids[index];

            bool success = _renewSubscription(id);

            Subscription memory subscription = subscriptions[id];
            if (success && !subscription.isAutoRenewable) {
                subscriptions[id].isAutoRenewable = true;
                subscriptionsByBillingDay[subscription.billingDay].push(id);
            }
        }
    }

    function renewSubscription(uint256 id) external {
        Subscription memory subscription = subscriptions[id];

        bool success = _renewSubscription(id);

        if (success && !subscription.isAutoRenewable) {
            subscriptions[id].isAutoRenewable = true;
            subscriptionsByBillingDay[subscription.billingDay].push(id);
        }
    }

    function burn() external {
        uint256 tokenId = ownedTokens[msg.sender];
        Subscription memory subscription = subscriptions[tokenId];

        _burn(tokenId);
        emit SubscriptionBurned(
            msg.sender,
            tokenId,
            subscription.billingDay,
            subscription.price,
            paymentTokens[subscription.paymentTokenIndex]._address
        );
    }

    function addPaymentToken(address _address, uint256 price)
        external
        onlyOwner
    {
        if (price == 0 || _address == address(0)) revert InvalidPaymentToken();

        paymentTokens.push(
            PaymentToken({price: price, _address: _address, isActive: true})
        );
        emit AddPaymentToken(price, _address);
    }

    function setPaymentToken(
        uint16 index,
        uint256 price,
        bool isActive
    ) external onlyOwner {
        if (price == 0 || index >= paymentTokens.length)
            revert InvalidPaymentToken();

        paymentTokens[index].price = price;
        paymentTokens[index].isActive = isActive;

        emit SetPaymentToken(index, price, isActive);
    }

    function claimErc20Tokens(address erc20Token_, uint256 amount) external {
        address owner_ = owner();
        address admin_ = admin;
        require(msg.sender == owner_ || msg.sender == admin_, "Forbidden");

        IERC20 erc20Token = IERC20(erc20Token_);
        require(
            erc20Token.balanceOf(address(this)) >= amount,
            "Claim amount exceeds balance"
        );

        uint256 adminAmount = (amount * uint256(adminFee)) /
            uint256(DENOMINATOR);

        erc20Token.transfer(owner_, amount - adminAmount);
        erc20Token.transfer(admin_, adminAmount);

        emit Erc20TokenClaimed(erc20Token_, amount);
    }

    function setAdminFee(uint16 newAdminFee) external onlyAdmin {
        adminFee = newAdminFee;

        emit SetAdminFee(newAdminFee);
    }

    function transferOwnershipToAdmin() external onlyAdmin {
        _transferOwnership(admin);
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function _renewSubscription(uint256 id) internal returns (bool success) {
        Subscription memory subscription = subscriptions[id];

        uint256 _expiration = subscription.expiration;
        if (_expiration > block.timestamp || _expiration == 0)
            revert SubscriptionNotExpired();

        PaymentToken memory paymentToken = paymentTokens[
            subscription.paymentTokenIndex
        ];
        if (!paymentToken.isActive) revert InactivePaymentToken();

        address subscriber = ownerOf(id);
        success = _paySubscription(
            paymentToken._address,
            subscriber,
            subscription.price
        );
        if (!success) return false;

        (uint8 billingDay, uint256 expiration) = parseBillingTimestamp(
            block.timestamp
        );
        subscriptions[id].expiration = expiration;

        if (subscription.billingDay != billingDay)
            subscriptions[id].billingDay = billingDay;

        emit SubscriptionRenewed(
            subscriber,
            id,
            subscription.price,
            expiration,
            paymentToken._address
        );
    }

    function _paySubscription(
        address erc20Token,
        address subscriber,
        uint256 price
    ) internal returns (bool) {
        bytes memory payload = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            subscriber,
            address(this),
            price
        );

        (bool success, bytes memory data) = erc20Token.call(payload);

        if (!success) return false;

        if (data.length > 0) {
            return abi.decode(data, (bool));
        }

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0)) return;
        if (ownedTokens[to] != 0) revert AlreadySubscribed();

        delete ownedTokens[from];

        if (to == address(0)) {
            delete subscriptions[tokenId];
            return;
        }

        ownedTokens[to] = tokenId;
    }
}