// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

struct Recipient {
    uint256 chainId;
    uint256 cycle;
    address wallet;
    uint256 amount;
}

interface ITokeReward {
    function getClaimableAmount(Recipient calldata recipient)
        external
        view
        returns (uint256);

    function claim(
        Recipient calldata recipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function claimedAmounts(address) external view returns (uint256);
}