// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IGauge {
    function getReward(address account, bool claimExtras) external;

    function balanceOf(address) external view returns (uint);

    function withdrawAndUnwrap(uint amount, bool claim) external;

    function earned(address account) external view returns (uint);

    function extraRewards(uint index) external view returns (address);
}