// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;


/// @notice An insufficient payment has been provided
error InsufficientPayment();

/// @notice Not enough tokens available
error NotEnoughTokens();

/// @notice The limit of mintable tokens for the address has been exceeded
error TokenLimitPerAddressExceeded();

/// @notice Hardcoded limit of number of tokens that can be minted at once.
error InternalMintPerCallLimitExceeded(uint256 limit);

/// @notice The nftContract must not be zero address.
error NFTContractIsAddressZero();

/// @notice Basis points must be between 0 and 9999. 100% Royalties are not allowed.
error BasisPointsMustBeLessThan10000();

/// @notice The contract address must not be the zero address.
error ContractAddressIsZero();

/// @notice The signature is invalid. Check chain id and contract address.
error InvalidSignature();

/// @notice The invoker of this method must have been granted the BaseURIExtensionSetter
error AuthorizationFailedBaseURIExtensionSetterRoleMissing();