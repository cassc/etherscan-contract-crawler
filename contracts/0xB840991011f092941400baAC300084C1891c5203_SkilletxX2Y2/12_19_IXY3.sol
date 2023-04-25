// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

/**
 * Skillet <> X2Y2
 * XY3 Interface
 * https://etherscan.io/address/0xFa4D5258804D7723eb6A934c11b1bd423bC31623#code
 */
interface IXY3 {

  struct Signature {
    uint256 nonce;
    uint256 expiry;
    address signer;
    bytes signature;
  }

  struct Offer {
    uint256 borrowAmount;
    uint256 repayAmount;
    address nftAsset;
    uint32 borrowDuration;
    address borrowAsset;
    uint256 timestamp;
    bytes extra;
  }

  struct CallData {
    address target;
    bytes4 selector;
    bytes data;
    uint256 referral;
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
    bool isCollection;
  }

  function borrow(
    Offer calldata _offer,
    uint256 _nftId,
    bool _isCollectionOffer,
    Signature calldata _lenderSignature,
    Signature calldata _brokerSignature,
    CallData calldata _extraDeal
  ) external returns (uint32);

  function repay(uint32 loanId) external;

  function loanDetails(uint32 loanId) external view returns (LoanDetail memory);
}