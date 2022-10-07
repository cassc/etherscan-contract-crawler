// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error CallerIsAnotherContract();
error UnrecognizableHash();
error ExceedsMaxSupply();
error WalletHasAlreadyPublicMinted();
error WalletHasAlreadyAllowListMinted();
error NotEnoughEthSent();
error IsNotCalledFromFCTokenContract();
error AddressAlreadySet();
error UserDoesNotHoldGateKey();
error UserIsNotAllowListedForThisToken();
error InvalidTokenId();
error IncorrectMintState();