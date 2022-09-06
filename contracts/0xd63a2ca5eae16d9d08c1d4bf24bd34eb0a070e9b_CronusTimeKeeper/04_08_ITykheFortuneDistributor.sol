// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ITykheFortuneDistributor {
    function setExcludedFromFee(address account, bool val) external;

    function isExcludedFromRewards(address account)
        external
        view
        returns (bool);

    function isExcludedFromFee(address account) external view returns (bool);

    function sendFortune() external;
}