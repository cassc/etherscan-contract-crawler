// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error AddressDoesNotHaveIdentity(address to);
error AlreadyAdded();
error AuthorityNotExists(address authority);
error CallerNotOwner(address caller);
error CallerNotReader(address caller);
error CreditScoreAlreadyCreated(address to);
error IdentityAlreadyCreated(address to);
error IdentityOwnerIsReader(uint256 readerIdentityId);
error InsufficientEthAmount(uint256 amount);
error IdentityOwnerNotTokenOwner(uint256 tokenId, uint256 ownerIdentityId);
error InvalidPaymentMethod(address paymentMethod);
error InvalidSignature();
error InvalidSignatureDate(uint256 signatureDate);
error InvalidToken(address token);
error InvalidTokenURI(string tokenURI);
error LinkAlreadyExists(
    address token,
    uint256 tokenId,
    uint256 readerIdentityId,
    uint256 signatureDate
);
error LinkAlreadyRevoked();
error LinkDoesNotExist();
error NameAlreadyExists(string name);
error NameNotFound(string name);
error NameRegisteredByOtherAccount(string name, uint256 tokenId);
error NotAuthorized(address signer);
error NonExistingErc20Token(address erc20token);
error NotLinkedToAnIdentitySBT();
error RefundFailed();
error SameValue();
error SBTAlreadyLinked(address token);
error SoulNameContractNotSet();
error TokenNotFound(uint256 tokenId);
error TransferFailed();
error URIAlreadyExists(string tokenURI);
error ValidPeriodExpired(uint256 expirationDate);
error ZeroAddress();
error ZeroLengthName(string name);
error ZeroYearsPeriod(uint256 yearsPeriod);