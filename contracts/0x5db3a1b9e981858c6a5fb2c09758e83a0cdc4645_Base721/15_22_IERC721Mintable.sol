// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// @author: NFT Studios - Buildtree

interface IERC721Mintable {
    function mint(address _to, uint256[] memory _ids) external;

    function totalSupply() external returns (uint256);
}