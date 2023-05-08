// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMadMemberPass {
    function mint(address _address, uint256 _amount) external;
    function burn(uint256 _tokenId) external;
    function isTokenOwner(address _owner, uint256 _tokenId) view external returns (bool);
    function getTotalSupply() external view returns (uint256);
}