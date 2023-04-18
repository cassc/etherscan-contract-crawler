// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ILevelReferralRegistry {
    function referredBy(address) external view returns (address);

    function referredCount(address) external view returns (uint256);

    function setReferrer(address _trader, address _referrer) external;
}