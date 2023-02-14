//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface ICommunityVaultEvents {

    event DXBLRedeemed(address holder, uint dxblAmount, address rewardToken, uint rewardAmount);
}