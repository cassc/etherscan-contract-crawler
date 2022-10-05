pragma solidity 0.8.4;




struct Signature {
    uint256 nonce;
    uint256 expiry;
    address signer;
    bytes signature;
}


struct LoanDetail {
    uint256 borrowAmount;
    uint256 repayAmount;
    uint256 nftTokenId;
    address borrowAsset;
    uint32 loanDuration;
    uint16 adminShare;
    uint64 loanStart;
    address nftAsset;
    address borrower;
    bool isCollection;
}


struct Offer {
    uint256 borrowAmount;
    uint256 repayAmount;
    address nftAsset;
    uint32 borrowDuration;
    uint16 adminShare;
    address borrowAsset;
    uint256 timestamp;
}