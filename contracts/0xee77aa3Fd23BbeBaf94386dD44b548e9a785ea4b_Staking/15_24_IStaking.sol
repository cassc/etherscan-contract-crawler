// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

struct Claim {
    uint256 amount;
    uint256 gons;
    uint256 expiry;
}

interface IStaking {
    function unstake(uint256 amount_, bool trigger) external;

    function claimWithdraw(address _recipient) external;

    function coolDownInfo(address) external view returns (Claim memory);
}