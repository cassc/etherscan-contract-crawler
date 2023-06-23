// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBaseRewardPool {
    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    function balanceOf(address) external view returns (uint256);

    function earned(address) external view returns (uint256);
}