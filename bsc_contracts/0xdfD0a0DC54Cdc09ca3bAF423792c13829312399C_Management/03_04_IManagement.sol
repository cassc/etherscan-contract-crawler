// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IManagement {
    function feeNumerator() external returns (uint256);

    function referralFeeNumerator() external returns (uint256);

    function payoutDelay() external returns (uint256);

    function operator() external returns (address);

    function treasury() external returns (address);

    function verifier() external returns (address);

    function factory() external returns (address);

    function eip712() external returns (address);

    function paymentToken(address) external returns (bool);

    function admin() external returns (address);

    function setReferralFeeRatio(uint256 _feeNumerator) external;

    function setFeeRatio(uint256 _feeNumerator) external;

    function setPayoutDelay(uint256 _period) external;

    function setOperator(address _newManager) external;

    function setTreasury(address _newTreasury) external;

    function setVerifier(address _newVerifier) external;

    function setFactory(address _factory) external;

    function setEIP712(address _eip712) external;

    function addPayment(address _token) external;

    function removePayment(address _token) external;

    event NewFeeNumerator(uint256 feeNumerator);

    event NewReferralFeeNumerator(uint256 feeNumerator);

    event NewPayoutDelay(uint256 payoutDelay);

    event NewOperator(address indexed manager);

    event NewTreasury(address indexed treasury);

    event NewVerifier(address indexed verifier);

    event NewFactory(address indexed factory);

    event NewEIP712(address indexed eip712);

    event PaymentTokensAdd(address indexed token);

    event PaymentTokensRemove(address indexed token);
}