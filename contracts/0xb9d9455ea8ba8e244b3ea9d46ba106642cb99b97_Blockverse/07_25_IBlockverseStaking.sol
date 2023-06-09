// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IBlockverseStaking {
    function stake(address from, uint256 tokenId) external;
    function claim(uint256 tokenId, bool unstake, uint256 nonce, uint256 amountV, bytes32 r, bytes32 s) external;
    function stakedByUser(address user) external view returns (uint256);

    event Claim(uint256 indexed _tokenId, uint256 indexed _amount, bool indexed _unstake);
}