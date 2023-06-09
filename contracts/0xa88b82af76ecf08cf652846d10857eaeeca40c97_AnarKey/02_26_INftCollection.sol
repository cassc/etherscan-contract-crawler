// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftCollection {
     /**
     * @dev Stake Token
     */
    function stakeToken(uint256 tokenId) external;

    /**
     * @dev Unstake Token
     */
    function unstakeToken(uint256 tokenId) external;

    /**
     * @dev return Token stake status
     */
    function isTokenStaked(uint256 tokenId) external view returns (bool);
}