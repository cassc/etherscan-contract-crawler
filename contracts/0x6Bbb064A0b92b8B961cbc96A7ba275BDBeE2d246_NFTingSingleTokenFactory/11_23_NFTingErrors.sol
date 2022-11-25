// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Common Errors
error ZeroAddress();
error WithdrawalFailed();
error NoTrailingSlash(string _uri);
error InvalidArgumentsProvided();
error PriceMustBeAboveZero(uint256 _price);
error PermissionDenied();
error InvalidTokenId(uint256 _tokenId);

// NFTing Base Contract
error NotTokenOwnerOrInsufficientAmount();
error NotApprovedMarketplace();
error ZeroAmountTransfer();
error TransactionError();
error InvalidAddressProvided(address _invalidAddress);

// PreAuthorization Contract
error NoAuthorizedOperator();

// Auction Contract
error NotExistingAuction(uint256 _auctionId);
error NotExistingBidder(address _bidder);
error NotEnoughPriceToBid();
error SelfBid();
error ExpiredAuction(uint256 _auctionId);
error RunningAuction(uint256 _auctionId);
error NotAuctionCreatorOrOwner();
error InvalidAmountOfTokens(uint256 _amount);
error AlreadyWithdrawn(uint256 _auctionId, address _bidder);
error NotBidder(uint256 _auctionId, address _bidder);

// Offer Contract
error NotExistingOffer(uint256 _offerId);
error PriceMustBeDifferent(uint256 _price);
error InsufficientETHProvided(uint256 _value);
error InvalidOfferState();

// Marketplace Contract
error NotListed();
error NotEnoughEthProvided(uint256 providedEth, uint256 requiredEth);
error NotTokenOwner();
error NotTokenSeller();
error TokenSeller();
error InvalidBasisProvided(uint256 _newBasis);

// NFTing Single Token Contract
error MaxBatchMintLimitExceeded();
error AlreadyExistentToken();
error NotApprovedOrOwner();
error MaxMintLimitExceeded();

// NFTing Token Manager Contract
error AlreadyRegisteredAddress();

// NFTingSignature
error HashUsed(bytes32 _hash);
error SignatureFailed(address _signatureAddress, address _signer);