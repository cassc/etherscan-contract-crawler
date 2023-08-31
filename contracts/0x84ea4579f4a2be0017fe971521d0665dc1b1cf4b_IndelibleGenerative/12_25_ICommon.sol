// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct FactorySettings {
    address indelibleSecurity;
    address collectorFeeRecipient;
    uint256 collectorFee;
    address deployer;
    address operatorFilter;
    uint256 signatureLifespan;
}

struct WithdrawRecipient {
    address recipientAddress;
    uint256 percentage;
}

struct RoyaltySettings {
    address royaltyAddress;
    uint96 royaltyAmount;
}

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

error NotAvailable();
error NotAuthorized();
error InvalidInput();