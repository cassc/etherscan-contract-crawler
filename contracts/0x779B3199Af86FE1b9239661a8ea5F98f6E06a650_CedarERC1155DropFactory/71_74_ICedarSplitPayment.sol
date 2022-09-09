// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICedarSplitPaymentV0 {
    function getTotalReleased() external view returns (uint256);
    function getTotalReleased(IERC20Upgradeable token) external view returns (uint256);
    function getReleased(address account) external view returns (uint256);
    function getReleased(IERC20Upgradeable token, address account) external view returns (uint256);
    function releasePayment(address payable account) external;
    function releasePayment(IERC20Upgradeable token, address account) external;
}