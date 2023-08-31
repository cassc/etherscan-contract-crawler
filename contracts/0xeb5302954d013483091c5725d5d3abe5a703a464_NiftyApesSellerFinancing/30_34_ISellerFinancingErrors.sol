//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../seaport/ISeaport.sol";

/// @title The SellerFinancing interface defining custom errors
interface ISellerFinancingErrors {
    error ZeroAddress();

    error SignatureNotAvailable(bytes signature);

    error OfferExpired();

    error SanctionedAddress(address account);

    error NotNftOwner(address nftContractAddress, uint256 nftId, address account);

    error InvalidSigner(address signer, address expected);

    error LoanAlreadyClosed();

    error InvalidCaller(address caller, address expected);

    error CannotBuySellerFinancingTicket();

    error NftIdsMustMatch();

    error CollectionOfferLimitReached();

    error InvalidOffer0ItemType(ISeaport.ItemType given, ISeaport.ItemType expected);

    error InvalidOffer0Token(address given, address expected);

    error InvalidOfferLength(uint256 given, uint256 expected);

    error InvalidConsideration0Identifier(uint256 given, uint256 expected);

    error InvalidConsiderationItemType(
        uint256 index,
        ISeaport.ItemType given,
        ISeaport.ItemType expected
    );

    error InvalidConsiderationToken(uint256 index, address given, address expected);

    error InvalidPeriodDuration();

    error InsufficientMsgValue(uint256 msgValueSent, uint256 minMsgValueExpected);

    error DownPaymentGreaterThanOrEqualToOfferPrice(uint256 downPaymentAmount, uint256 offerPrice);

    error InvalidMinimumPrincipalPerPeriod(
        uint256 givenMinPrincipalPerPeriod,
        uint256 maxMinPrincipalPerPeriod
    );

    error SoftGracePeriodEnded();

    error AmountReceivedLessThanRequiredMinimumPayment(
        uint256 amountReceived,
        uint256 minExpectedAmount
    );

    error LoanNotInDefault();

    error ExecuteOperationFailed();

    error SeaportOrderNotFulfilled();

    error WethConversionFailed();

    error InsufficientAmountReceivedFromSale(
        uint256 saleAmountReceived,
        uint256 minSaleAmountRequired
    );

    error InvalidIndex(uint256 index, uint256 ownerTokenBalance);

    error InsufficientBalance(uint256 amountRequested, uint256 contractBalance);

    error ConditionSendValueFailed(address from, address to, uint256 amount);
}