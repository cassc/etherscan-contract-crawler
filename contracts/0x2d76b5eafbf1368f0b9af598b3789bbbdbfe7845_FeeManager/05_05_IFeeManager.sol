// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFeeManager {
    function setCollectionFee(address collection, uint16 fee) external;

    function removeCollectionFee(address collection) external;

    function setDefaultFee(uint16 fee) external;

    function getRoyaltiesEnabled() external returns (bool);

    function setRoyaltiesEnabled(bool enabled) external;

    function setRoyaltyPercentage(uint16 percentage) external;

    function setFeeReceiver(address receiver) external;

    function getReceiver() external view returns (address);

    function getFee(address collection) external view returns (uint16);

    function getRoyaltyPercentage() external view returns (uint16);

    function divider() external view returns (uint16);

    function getFeeAmount(address collection, uint256 amount) external view returns (uint256);
}