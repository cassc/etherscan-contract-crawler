// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IInsurancePool {
    function depositCollateral(address token, uint256 amount) external;

    function withdrawCollateral(address token, uint256 amount) external;

    function receivePortfolio(address token, uint256 amount) external;

    function sendPortfolio(address token, address receiver, uint256 amount) external;

    function GUARDIAN_ROLE() external view returns (bytes32);

    function WITHDRAWER_ROLE() external view returns (bytes32);

    function getCollateral(address token) external view returns (uint256);

    function getPortfolio(address token) external view returns (uint256);
}