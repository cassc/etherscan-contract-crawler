// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IXENCrypto is IERC20 {
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    mapping(address => MintInfo) public userMints;

    function claimRank(uint256 term) external virtual;

    function claimMintReward() external virtual;

    function claimMintRewardAndShare(address other, uint256 pct)
        external
        virtual;

    function getUserMint() external view virtual returns (MintInfo memory);
}