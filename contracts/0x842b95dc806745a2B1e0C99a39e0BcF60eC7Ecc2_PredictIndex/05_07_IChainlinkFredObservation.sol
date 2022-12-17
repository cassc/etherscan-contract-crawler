// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IChainlinkFredObservation {

    function linkTokenBalance(address) external returns(uint256);

    function depositLink(uint256 amount) external;

    function makeMultipleRequest(string memory requestURL) external;

    function getLastObservation() external view returns(uint16 year, uint8 month, uint256 observation);

    function hasPaidFee(address) external returns(bool);
}