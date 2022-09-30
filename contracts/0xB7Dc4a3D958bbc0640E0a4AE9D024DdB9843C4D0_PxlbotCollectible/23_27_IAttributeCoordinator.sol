//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAttributeCoordinator {
    function attributeValues(uint256 botId, string[] memory attrIds) external returns(uint32[] memory);
    function setAttributeValues(uint256 botId, string[] memory attrIds, uint32[] memory values) external;
    function totalPossible() external returns(uint32);
    function getAttrIds() external returns (string[] memory);
}