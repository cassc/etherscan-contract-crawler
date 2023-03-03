// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721Mintable {
    function totalSupply() external view returns (uint256);

    function mint(address _to, uint256 _tokenId) external;
}