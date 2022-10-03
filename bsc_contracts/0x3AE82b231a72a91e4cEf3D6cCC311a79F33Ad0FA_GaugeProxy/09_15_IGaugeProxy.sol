// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface IGaugeProxy {
    function bribes(address gauge) external returns (address);

    function baseReferralsContract() external returns (address);

    function baseReferralFee() external returns (uint256);

    function governance() external returns (address);

    function admin() external returns (address);
}