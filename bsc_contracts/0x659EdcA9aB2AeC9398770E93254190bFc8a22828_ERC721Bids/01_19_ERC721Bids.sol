// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../library/CollectionReader.sol";
import "../royalty/ICollectionRoyaltyReader.sol";
import "../payment-token/IPaymentTokenCheck.sol";
import "../market-settings/IMarketSettings.sol";
import "./IERC721Bids.sol";
import "./OperatorDelegation.sol";

contract ERC721Bids is IERC721Bids, OperatorDelegation, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    constructor(address marketSettings_) {
        _marketSettings = IMarketSettings(marketSettings_);
    }

    IMarketSettings private _marketSettings;

    mapping(address => ERC721Bids) private _erc721Bids;

    /**
     * @dev See {IERC721Bids-enterBidForToken}.
     */
    function enterBidForToken(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp,
        address paymentToken,
        address bidder
    ) external {
        require(
            bidder == _msgSender() || isApprovedOperator(bidder, _msgSender()),
            "sender not bidder or approved operator"
        );

        (bool isValid, string memory message) = _checkEnterBidAction(
            erc721Address,
            tokenId,
            value,
            expireTimestamp,
            paymentToken,
            bidder
        );

        require(isValid, message);

        _enterBidForToken(
            erc721Address,
            tokenId,
            value,
            expireTimestamp,
            paymentToken,
            bidder
        );
    }

    /**
     * @dev See {IERC721Bids-enterBidForTokens}.
     */
    function enterBidForTokens(EnterBidInput[] calldata newBids, address bidder)
        external
    {
        require(
            bidder == _msgSender() || isApprovedOperator(bidder, _msgSender()),
            "sender not bidder or approved operator"
        );

        for (uint256 i = 0; i < newBids.length; i++) {
            address erc721Address = newBids[i].erc721Address;
            uint256 tokenId = newBids[i].tokenId;
            uint256 value = newBids[i].value;
            uint256 expireTimestamp = newBids[i].expireTimestamp;
            address paymentToken = newBids[i].paymentToken;

            (bool isValid, string memory message) = _checkEnterBidAction(
                erc721Address,
                tokenId,
                value,
                expireTimestamp,
                paymentToken,
                bidder
            );

            if (isValid) {
                _enterBidForToken(
                    erc721Address,
                    tokenId,
                    value,
                    expireTimestamp,
                    paymentToken,
                    bidder
                );
            } else {
                emit EnterBidFailed(
                    erc721Address,
                    tokenId,
                    message,
                    _msgSender()
                );
            }
        }
    }

    /**
     * @dev See {IERC721Bids-withdrawBidForToken}.
     */
    function withdrawBidForToken(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) external {
        Bid memory bid = _erc721Bids[erc721Address].bids[tokenId].bids[bidder];

        (bool isValid, string memory message) = _checkWithdrawBidAction(bid);

        require(isValid, message);

        _withdrawBidForToken(erc721Address, bid);
    }

    /**
     * @dev See {IERC721Bids-withdrawBidForTokens}.
     */
    function withdrawBidForTokens(WithdrawBidInput[] calldata bids) external {
        for (uint256 i = 0; i < bids.length; i++) {
            address erc721Address = bids[i].erc721Address;
            uint256 tokenId = bids[i].tokenId;
            address bidder = bids[i].bidder;
            Bid memory bid = _erc721Bids[erc721Address].bids[tokenId].bids[
                bidder
            ];

            (bool isValid, string memory message) = _checkWithdrawBidAction(
                bid
            );

            if (isValid) {
                _withdrawBidForToken(erc721Address, bid);
            } else {
                emit WithdrawBidFailed(
                    erc721Address,
                    tokenId,
                    message,
                    _msgSender()
                );
            }
        }
    }

    /**
     * @dev See {IERC721Bids-acceptBidForToken}.
     */
    function acceptBidForToken(
        address erc721Address,
        uint256 tokenId,
        address bidder,
        uint256 value
    ) external {
        Bid memory bid = _erc721Bids[erc721Address].bids[tokenId].bids[bidder];
        address tokenOwner = CollectionReader.tokenOwner(
            erc721Address,
            tokenId
        );

        (bool isValid, string memory message) = _checkAcceptBidAction(
            erc721Address,
            bid,
            value,
            tokenOwner
        );

        require(isValid, message);

        _acceptBidForToken(erc721Address, bid, tokenOwner);
    }

    /**
     * @dev See {IERC721Bids-acceptBidForTokens}.
     */
    function acceptBidForTokens(AcceptBidInput[] calldata bids) external {
        for (uint256 i = 0; i < bids.length; i++) {
            address erc721Address = bids[i].erc721Address;
            uint256 tokenId = bids[i].tokenId;
            address bidder = bids[i].bidder;
            uint256 value = bids[i].value;
            Bid memory bid = _erc721Bids[erc721Address].bids[tokenId].bids[
                bidder
            ];
            address tokenOwner = CollectionReader.tokenOwner(
                erc721Address,
                tokenId
            );

            (bool isValid, string memory message) = _checkAcceptBidAction(
                erc721Address,
                bid,
                value,
                tokenOwner
            );

            if (isValid) {
                _acceptBidForToken(erc721Address, bid, tokenOwner);
            } else {
                emit AcceptBidFailed(
                    erc721Address,
                    tokenId,
                    message,
                    _msgSender()
                );
            }
        }
    }

    /**
     * @dev See {IERC721Bids-removeExpiredBids}.
     */
    function removeExpiredBids(RemoveExpiredBidInput[] calldata bids) external {
        for (uint256 i = 0; i < bids.length; i++) {
            address erc721Address = bids[i].erc721Address;
            uint256 tokenId = bids[i].tokenId;
            address bidder = bids[i].bidder;
            Bid memory bid = _erc721Bids[erc721Address].bids[tokenId].bids[
                bidder
            ];

            if (
                bid.expireTimestamp != 0 &&
                bid.expireTimestamp <= block.timestamp
            ) {
                _removeBid(erc721Address, tokenId, bidder);
            }
        }
    }

    /**
     * @dev check if enter bid action is valid
     * if not valid, return the reason
     */
    function _checkEnterBidAction(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp,
        address paymentToken,
        address bidder
    ) private view returns (bool isValid, string memory message) {
        isValid = false;

        if (!_marketSettings.isCollectionTradingEnabled(erc721Address)) {
            message = "trading is not open";
            return (isValid, message);
        }
        if (value == 0) {
            message = "value cannot be 0";
            return (isValid, message);
        }
        if (
            expireTimestamp - block.timestamp <
            _marketSettings.actionTimeOutRangeMin()
        ) {
            message = "expire time below minimum";
            return (isValid, message);
        }
        if (
            expireTimestamp - block.timestamp >
            _marketSettings.actionTimeOutRangeMax()
        ) {
            message = "expire time above maximum";
            return (isValid, message);
        }
        if (!_isAllowedPaymentToken(erc721Address, paymentToken)) {
            message = "payment token not enabled";
            return (isValid, message);
        }
        address _paymentToken = _getPaymentTokenAddress(paymentToken);
        if (IERC20(_paymentToken).balanceOf(bidder) < value) {
            message = "insufficient balance";
            return (isValid, message);
        }
        if (IERC20(_paymentToken).allowance(bidder, address(this)) < value) {
            message = "insufficient allowance";
            return (isValid, message);
        }
        address tokenOwner = CollectionReader.tokenOwner(
            erc721Address,
            tokenId
        );
        if (tokenOwner == bidder) {
            message = "token owner cannot bid";
            return (isValid, message);
        }

        isValid = true;
    }

    /**
     * @dev enter a bid
     */
    function _enterBidForToken(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp,
        address paymentToken,
        address bidder
    ) private {
        Bid memory bid = Bid(
            tokenId,
            value,
            bidder,
            expireTimestamp,
            paymentToken
        );

        _erc721Bids[erc721Address].tokenIds.add(tokenId);
        _erc721Bids[erc721Address].bids[tokenId].bidders.add(bidder);
        _erc721Bids[erc721Address].bids[tokenId].bids[bidder] = bid;

        emit TokenBidEntered(erc721Address, bidder, tokenId, bid, _msgSender());
    }

    /**
     * @dev check if withdraw bid action is valid
     * if not valid, return the reason
     */
    function _checkWithdrawBidAction(Bid memory bid)
        private
        view
        returns (bool isValid, string memory message)
    {
        isValid = false;

        if (bid.bidder == address(0)) {
            message = "bid does not exist";
            return (isValid, message);
        }

        if (
            bid.bidder != _msgSender() &&
            !isApprovedOperator(bid.bidder, _msgSender())
        ) {
            message = "sender not bidder or approved operator";
            return (isValid, message);
        }

        isValid = true;
    }

    /**
     * @dev withdraw a bid
     */
    function _withdrawBidForToken(address erc721Address, Bid memory bid)
        private
    {
        _removeBid(erc721Address, bid.tokenId, bid.bidder);

        emit TokenBidWithdrawn(
            erc721Address,
            bid.bidder,
            bid.tokenId,
            bid,
            _msgSender()
        );
    }

    /**
     * @dev check if accept bid action is valid
     * if not valid, return the reason
     */
    function _checkAcceptBidAction(
        address erc721Address,
        Bid memory bid,
        uint256 value,
        address tokenOwner
    ) private view returns (bool isValid, string memory message) {
        isValid = false;

        Status status = _getBidStatus(erc721Address, bid);
        if (status != Status.ACTIVE) {
            message = "bid is not valid";
            return (isValid, message);
        }
        if (value != bid.value) {
            message = "accepting value differ from bid";
            return (isValid, message);
        }
        if (
            tokenOwner != _msgSender() &&
            !isApprovedOperator(tokenOwner, _msgSender())
        ) {
            message = "sender not owner or approved operator";
            return (isValid, message);
        }
        if (
            !_isApprovedToTransferToken(erc721Address, bid.tokenId, tokenOwner)
        ) {
            message = "transferred not approved";
            return (isValid, message);
        }
        isValid = true;
    }

    /**
     * @dev accept a bid
     */
    function _acceptBidForToken(
        address erc721Address,
        Bid memory bid,
        address tokenOwner
    ) private nonReentrant {
        (
            FundReceiver[] memory fundReceivers,
            ICollectionRoyaltyReader.RoyaltyAmount[] memory royaltyInfo,
            uint256 serviceFee
        ) = _getFundReceiversOfBid(erc721Address, bid, tokenOwner);

        _sendFundToReceivers(bid.bidder, fundReceivers);

        // Send token to bidder
        IERC721(erc721Address).safeTransferFrom(
            tokenOwner,
            bid.bidder,
            bid.tokenId
        );

        _removeBid(erc721Address, bid.tokenId, bid.bidder);

        emit TokenBidAccepted({
            erc721Address: erc721Address,
            seller: tokenOwner,
            tokenId: bid.tokenId,
            bid: bid,
            serviceFee: serviceFee,
            royaltyInfo: royaltyInfo,
            sender: _msgSender()
        });
    }

    /**
     * @dev remove bid from storage
     */
    function _removeBid(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) private {
        if (_erc721Bids[erc721Address].bids[tokenId].bidders.contains(bidder)) {
            // Step 1: delete the bid and the address
            delete _erc721Bids[erc721Address].bids[tokenId].bids[bidder];
            _erc721Bids[erc721Address].bids[tokenId].bidders.remove(bidder);

            // Step 2: if no bid left
            if (
                _erc721Bids[erc721Address].bids[tokenId].bidders.length() == 0
            ) {
                _erc721Bids[erc721Address].tokenIds.remove(tokenId);
            }
        }
    }

    /**
     * @dev get list of fund receivers, amount, and payment token
     * Note:
     * List of receivers
     * - Seller of token
     * - Service fee receiver
     * - royalty receivers
     */
    function _getFundReceiversOfBid(
        address erc721Address,
        Bid memory bid,
        address tokenOwner
    )
        private
        view
        returns (
            FundReceiver[] memory fundReceivers,
            ICollectionRoyaltyReader.RoyaltyAmount[] memory royaltyInfo,
            uint256 serviceFee
        )
    {
        address paymentToken = _getPaymentTokenAddress(bid.paymentToken);

        royaltyInfo = ICollectionRoyaltyReader(
            _marketSettings.royaltyRegsitry()
        ).royaltyInfo(erc721Address, bid.tokenId, bid.value);

        fundReceivers = new FundReceiver[](royaltyInfo.length + 2);

        uint256 amountToSeller = bid.value;
        for (uint256 i = 0; i < royaltyInfo.length; i++) {
            address royaltyReceiver = royaltyInfo[i].receiver;
            uint256 royaltyAmount = royaltyInfo[i].royaltyAmount;

            fundReceivers[i + 2] = FundReceiver({
                account: royaltyReceiver,
                amount: royaltyAmount,
                paymentToken: paymentToken
            });

            amountToSeller -= royaltyAmount;
        }

        (address feeReceiver, uint256 feeAmount) = _marketSettings
            .serviceFeeInfo(bid.value);
        serviceFee = feeAmount;

        fundReceivers[1] = FundReceiver({
            account: feeReceiver,
            amount: serviceFee,
            paymentToken: paymentToken
        });

        amountToSeller -= serviceFee;

        fundReceivers[0] = FundReceiver({
            account: tokenOwner,
            amount: amountToSeller,
            paymentToken: paymentToken
        });
    }

    /**
     * @dev map payment token address
     * Address 0 is mapped to wrapped ether address.
     * For a given chain, wrapped ether represent it's
     * corresponding wrapped coin. e.g. WBNB for BSC, WFTM for FTM
     */
    function _getPaymentTokenAddress(address _paymentToken)
        private
        view
        returns (address paymentToken)
    {
        paymentToken = _paymentToken;

        if (_paymentToken == address(0)) {
            paymentToken = _marketSettings.wrappedEther();
        }
    }

    /**
     * @dev send payment token
     */
    function _sendFund(
        address paymentToken,
        address from,
        address to,
        uint256 value
    ) private {
        require(paymentToken != address(0), "payment token can't be 0 address");
        IERC20(paymentToken).safeTransferFrom(from, to, value);
    }

    /**
     * @dev send funds to a list of receivers
     */
    function _sendFundToReceivers(
        address from,
        FundReceiver[] memory fundReceivers
    ) private {
        for (uint256 i; i < fundReceivers.length; i++) {
            _sendFund(
                fundReceivers[i].paymentToken,
                from,
                fundReceivers[i].account,
                fundReceivers[i].amount
            );
        }
    }

    /**
     * @dev See {IERC721Bids-getBidderTokenBid}.
     */
    function getBidderTokenBid(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) public view returns (BidStatus memory) {
        Bid memory bid = _erc721Bids[erc721Address].bids[tokenId].bids[bidder];
        Status status = _getBidStatus(erc721Address, bid);

        return
            BidStatus({
                tokenId: bid.tokenId,
                value: bid.value,
                bidder: bid.bidder,
                expireTimestamp: bid.expireTimestamp,
                paymentToken: bid.paymentToken,
                status: status
            });
    }

    /**
     * @dev See {IERC721Bids-getTokenBids}.
     */
    function getTokenBids(address erc721Address, uint256 tokenId)
        public
        view
        returns (BidStatus[] memory bids)
    {
        uint256 bidderCount = _erc721Bids[erc721Address]
            .bids[tokenId]
            .bidders
            .length();

        bids = new BidStatus[](bidderCount);
        for (uint256 i; i < bidderCount; i++) {
            address bidder = _erc721Bids[erc721Address]
                .bids[tokenId]
                .bidders
                .at(i);
            bids[i] = getBidderTokenBid(erc721Address, tokenId, bidder);
        }
    }

    /**
     * @dev See {IERC721Bids-getTokenHighestBid}.
     */
    function getTokenHighestBid(address erc721Address, uint256 tokenId)
        public
        view
        returns (BidStatus memory highestBid)
    {
        uint256 bidderCount = _erc721Bids[erc721Address]
            .bids[tokenId]
            .bidders
            .length();
        for (uint256 i; i < bidderCount; i++) {
            address bidder = _erc721Bids[erc721Address]
                .bids[tokenId]
                .bidders
                .at(i);
            BidStatus memory bid = getBidderTokenBid(
                erc721Address,
                tokenId,
                bidder
            );
            if (bid.status == Status.ACTIVE && bid.value > highestBid.value) {
                highestBid = bid;
            }
        }
    }

    /**
     * @dev See {IERC721Bids-numTokenWithBidsOfCollection}.
     */
    function numTokenWithBidsOfCollection(address erc721Address)
        public
        view
        returns (uint256)
    {
        return _erc721Bids[erc721Address].tokenIds.length();
    }

    /**
     * @dev See {IERC721Bids-getHighestBidsOfCollection}.
     */
    function getHighestBidsOfCollection(
        address erc721Address,
        uint256 from,
        uint256 size
    ) external view returns (BidStatus[] memory highestBids) {
        uint256 tokenCount = numTokenWithBidsOfCollection(erc721Address);

        if (from < tokenCount && size > 0) {
            uint256 querySize = size;
            if ((from + size) > tokenCount) {
                querySize = tokenCount - from;
            }
            highestBids = new BidStatus[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                highestBids[i] = getTokenHighestBid({
                    erc721Address: erc721Address,
                    tokenId: _erc721Bids[erc721Address].tokenIds.at(i + from)
                });
            }
        }
    }

    /**
     * @dev See {IERC721Bids-getBidderBidsOfCollection}.
     */
    function getBidderBidsOfCollection(
        address erc721Address,
        address bidder,
        uint256 from,
        uint256 size
    ) external view returns (BidStatus[] memory bidderBids) {
        uint256 tokenCount = numTokenWithBidsOfCollection(erc721Address);

        if (from < tokenCount && size > 0) {
            uint256 querySize = size;
            if ((from + size) > tokenCount) {
                querySize = tokenCount - from;
            }
            bidderBids = new BidStatus[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                bidderBids[i] = getBidderTokenBid({
                    erc721Address: erc721Address,
                    tokenId: _erc721Bids[erc721Address].tokenIds.at(i + from),
                    bidder: bidder
                });
            }
        }
    }

    /**
     * @dev address of market settings contract
     */
    function marketSettingsContract() external view returns (address) {
        return address(_marketSettings);
    }

    /**
     * @dev update market settings contract
     */
    function updateMarketSettingsContract(address newMarketSettingsContract)
        external
        onlyOwner
    {
        address oldMarketSettingsContract = address(_marketSettings);
        _marketSettings = IMarketSettings(newMarketSettingsContract);

        emit MarketSettingsContractUpdated(
            oldMarketSettingsContract,
            newMarketSettingsContract
        );
    }

    /**
     * @dev check if payment token is allowed for a collection
     */
    function _isAllowedPaymentToken(address erc721Address, address paymentToken)
        private
        view
        returns (bool)
    {
        return
            paymentToken == address(0) ||
            IPaymentTokenCheck(_marketSettings.paymentTokenRegistry())
                .isAllowedPaymentToken(erc721Address, paymentToken);
    }

    /**
     * @dev check if a token or a collection if approved
     *  to be transferred by this contract
     */
    function _isApprovedToTransferToken(
        address erc721Address,
        uint256 tokenId,
        address account
    ) private view returns (bool) {
        return
            CollectionReader.isTokenApproved(erc721Address, tokenId) ||
            CollectionReader.isAllTokenApproved(
                erc721Address,
                account,
                address(this)
            );
    }

    /**
     * @dev get current status of a bid
     */
    function _getBidStatus(address erc721Address, Bid memory bid)
        private
        view
        returns (Status)
    {
        if (bid.bidder == address(0)) {
            return Status.NOT_EXIST;
        }
        if (!_marketSettings.isCollectionTradingEnabled(erc721Address)) {
            return Status.TRADE_NOT_OPEN;
        }
        if (bid.expireTimestamp < block.timestamp) {
            return Status.EXPIRED;
        }
        if (
            CollectionReader.tokenOwner(erc721Address, bid.tokenId) ==
            bid.bidder
        ) {
            return Status.ALREADY_TOKEN_OWNER;
        }
        if (!_isAllowedPaymentToken(erc721Address, bid.paymentToken)) {
            return Status.INVALID_PAYMENT_TOKEN;
        }

        address paymentToken = _getPaymentTokenAddress(bid.paymentToken);
        if (IERC20(paymentToken).balanceOf(bid.bidder) < bid.value) {
            return Status.INSUFFICIENT_BALANCE;
        }
        if (
            IERC20(paymentToken).allowance(bid.bidder, address(this)) <
            bid.value
        ) {
            return Status.INSUFFICIENT_ALLOWANCE;
        }

        return Status.ACTIVE;
    }
}