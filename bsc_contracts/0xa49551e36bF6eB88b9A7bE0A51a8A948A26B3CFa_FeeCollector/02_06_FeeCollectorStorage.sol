// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;


contract FeeCollectorStorage {

    address public trade;
    address public constant quoteToken = 0x55d398326f99059fF775485246999027B3197955;

    uint256 public feeRatio;
    uint256 public holderFeeRatio;
    uint256 public capitalPoolFeeRatio;
    uint256 public technicalSupportFeeRatio;
    uint256 public genesisFeeRatio;
    uint256 public jointFeeRatio;

    address public capitalPool;
    uint256 public capitalPoolFee;

    address public technicalSupport;
    uint256 public technicalSupportFee;

    address public constant genesis = 0x15b8054314A5a9D34728367327c40b72405c1Bc8;
    address public constant joint = 0x2C1Ca7068914B3cA2982955B354629506E8b2D2E;

    mapping(address => uint256) public totalNftFee;

    mapping(address => mapping(uint256 => uint256)) public receivedFee;

    uint256 public totalAmount;
}