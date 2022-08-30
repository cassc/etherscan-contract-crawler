// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeRuleRegistry {
    /* State Variables Getter */
    function rules(uint256) external view returns (address);
    function counter() external view returns (uint256);
    function basisFeeRate() external view returns (uint256);
    function feeCollector() external view returns (address);
    function BASE() external view returns (uint256);

    /* Restricted Functions */
    function setBasisFeeRate(uint256) external;
    function setFeeCollector(address) external;
    function registerRule(address rule) external;
    function unregisterRule(uint256 ruleIndex) external;

    /* View Functions */
    function calFeeRateMulti(address usr, uint256[] calldata ruleIndexes) external view returns (uint256 scaledRate);
    function calFeeRate(address usr, uint256 ruleIndex) external view returns (uint256 scaledRate);
    function calFeeRateMultiWithoutBasis(address usr, uint256[] calldata ruleIndexes) external view returns (uint256 scaledRate);
    function calFeeRateWithoutBasis(address usr, uint256 ruleIndex) external view returns (uint256 scaledRate);
}