// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IToken {
    function addPair(address pair, address token) external;
    function depositLPFee(uint amount, address token) external;
    // function isExcludedFromFee(address account) external view returns (bool);
    function getTotalFee(address _feeCheck) external view returns (uint);
    function handleFee(uint amount, address token) external;
}