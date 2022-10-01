// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IXtatuzReroll {

    function reroll(uint256 projectId_, uint256 tokenId_, address member_) external;

    function rerollFee() external returns(uint256);

    function getRerollData(uint256 projectId) external returns(string[] memory);

    function setRerollData(uint256 projectId_, string[] memory rerollData_) external;

}