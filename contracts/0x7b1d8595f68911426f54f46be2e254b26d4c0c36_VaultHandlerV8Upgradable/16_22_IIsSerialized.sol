// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
interface IIsSerialized {
    function isSerialized() external view returns (bool);
    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256);
    function getFirstSerialByOwner(address owner, uint256 tokenId) external view returns (uint256);
    function getOwnerOfSerial(uint256 serialNumber) external view returns (address);
    function getSerialByOwnerAtIndex(address _owner, uint256 tokenId, uint256 index) external view returns (uint256);
    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256);
    function isOverloadSerial() external view returns (bool);
}