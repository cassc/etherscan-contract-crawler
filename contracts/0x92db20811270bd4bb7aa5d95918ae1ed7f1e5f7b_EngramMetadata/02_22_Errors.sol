// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error HashAlreadySet();
error TokenIdAlreadySet();
error IdentifierNotUnique();
error SenderDoesNotOwnToken();
error NameAlreadySet();
error NameNotUnique();
error CallerNotAdmin();
error UnrecognizableHash();
error ContractAlreadyInitialized();
error MintingExceedsSupply();
error UserHasMintedThisTokenAlready();
error TokenTransferDisabled();
error InvalidTokenId();
error TokenAlreadyMinted();
error NewNonceNeedsToBeLargerThanPreviousNonce();