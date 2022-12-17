// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IChainlinkFredRelease {

    function depositLink(uint256 amount) external;

    function makeMultipleRequest(string memory requestURL) external;

    function getLastReleaseDate() external view returns(uint16 year, uint8 month, uint8 day);

    function hasPaidFee(address) external returns(bool);
}