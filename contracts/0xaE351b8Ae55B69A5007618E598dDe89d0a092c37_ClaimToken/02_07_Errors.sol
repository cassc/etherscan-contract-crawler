// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.4 <0.9.0;

library Errors {
    error LinkError();
    error ArrayMismatch();
    error OutOfRange(uint256 value);
    error OutOfRangeSigned(int256 value);
    error UnsignedOverflow(uint256 value);
    error SignedOverflow(int256 value);
    error DuplicateCall();

    error NotAContract();
    error InterfaceNotSupported();
    error NotInitialized();
    error BadSender(address expected, address caller);
    error AddressTarget(address target);
    error UserPermissions();

    error MintingClosed();
    error AllocationSpent();
    error InsufficientBalance(uint256 available, uint256 required);
    error InsufficientSupply(uint256 supply, uint256 available, int256 requested);  // 0x5437b336
    error InsufficientAvailable(uint256 available, uint256 requested);
    error InvalidToken(uint256 tokenId);                                            // 0x925d6b18
    error TokenNotMintable(uint256 tokenId);

    error ERC1155Receiver();

    error ContractPaused();

    error PaymentFailed(uint256 amount);
    error IncorrectPayment(uint256 required, uint256 provided);                     // 0x0d35e921
	error TooManyForTransaction(uint256 mintLimit, uint256 amount);
}