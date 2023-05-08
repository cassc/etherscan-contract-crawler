pragma solidity >=0.8.4;

struct ReferralInfo {
    address referrerAddress;
    bytes32 referrerNodehash;
    uint256 referralAmount;
    uint256 signedAt;
    bytes signature;
}

struct RegInfo {
    address owner;
    uint duration;
    bytes32 secret;
    address resolver;
    bool isUsePoints;
    uint256 paidFee;
}