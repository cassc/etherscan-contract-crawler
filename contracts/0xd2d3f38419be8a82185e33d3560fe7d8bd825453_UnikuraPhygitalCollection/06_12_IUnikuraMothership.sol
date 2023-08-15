// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUnikuraMothership {
    event FeePercentage(uint8 feePercentage);
    event VelvettFeeRecipient(address payable velvettFeeRecipient);
    event UnikuraMembership(address unikuraMembership);

    function feePercentage() external view returns (uint8);

    function setFeePercentage(uint8 feePercentage_) external;

    function velvettFeeRecipient() external view returns (address payable);

    function setVelvettFeeRecipient(
        address payable velvettFeeRecipient_
    ) external;

    function unikuraMembershipContract() external view returns (address);

    function setUnikuraMembershipContract(
        address unikuraMembershipContract_
    ) external;

    function isAllowed(address wallet) external view returns (bool);

    function renounceOwnership() external view;
}