// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ISuperRareV1 {
    function balanceOf(address _owner) external view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function transfer(address _to, uint256 _tokenId) external;

    function approve(address _to, uint256 _tokenId) external;

    function takeOwnership(uint256 _tokenId) external;
}