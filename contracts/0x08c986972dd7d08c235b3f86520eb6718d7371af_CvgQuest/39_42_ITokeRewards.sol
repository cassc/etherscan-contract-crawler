// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokeRewards {
    struct Recipient {
        uint256 chainId;
        uint256 cycle;
        address wallet;
        uint256 amount;
    }
    struct ClaimData {
        Recipient recipient;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function getClaimableAmount(Recipient calldata recipient) external view returns (uint256);

    function claim(Recipient calldata recipient, uint8 v, bytes32 r, bytes32 s) external;
}