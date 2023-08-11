// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

bytes32 constant MINTPARAMETERS_TYPEHASH = keccak256(
    "MintParameters(MintToken[] mintTokens,"
    "BurnToken[] burnTokens,"
    "PaymentToken[] paymentTokens,"
    "uint256 startTime,"
    "uint256 endTime,"
    "uint256 signatureMaxUses,"
    "bytes32 merkleRoot,"
    "uint256 nonce,"
    "bool oracleSignatureRequired)"
    "BurnToken(address contractAddress,"
    "bool specificTokenId,"
    "uint8 tokenType,"
    "uint8 burnType,"
    "uint256 tokenId,"
    "uint256 burnAmount)"
    "MintToken(address contractAddress,"
    "bool specificTokenId,"
    "uint8 tokenType,"
    "uint256 tokenId,"
    "uint256 mintAmount,"
    "uint256 maxSupply,"
    "uint256 maxMintPerWallet)"
    "PaymentToken(address contractAddress,"
    "uint8 tokenType,"
    "address payTo,"
    "uint256 paymentAmount,"
    "uint256 referralBPS)"
);

bytes32 constant MINTTOKEN_TYPEHASH = keccak256(
    "MintToken(address contractAddress,bool specificTokenId,uint8 tokenType,uint256 tokenId,uint256 mintAmount,uint256 maxSupply,uint256 maxMintPerWallet)"
);

bytes32 constant BURNTOKEN_TYPEHASH = keccak256(
    "BurnToken(address contractAddress,bool specificTokenId,uint8 tokenType,uint8 burnType,uint256 tokenId,uint256 burnAmount)"
);

bytes32 constant PAYMENTTOKEN_TYPEHASH = keccak256(
    "PaymentToken(address contractAddress,uint8 tokenType,address payTo,uint256 paymentAmount,uint256 referralBPS)"
);