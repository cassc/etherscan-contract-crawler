// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISwaprFee {
    function getFeeReceiver() external view returns (address);

    function getFinalOrderFee(uint256 subjectAmount, address token) external view returns (uint256 finalFee);

    function getFinalAuctionFee(uint subjectAmount, address token) external view returns (uint finalFee);

    function getFeePaid(address sender, address paymentToken) external view returns (uint256);

    function disposeFeeRecord(bytes calldata data) external;
}