// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICedarSplitPaymentV0 {
    function getTotalReleased() external view returns (uint256);

    function getTotalReleased(IERC20Upgradeable token) external view returns (uint256);

    function getReleased(address account) external view returns (uint256);

    function getReleased(IERC20Upgradeable token, address account) external view returns (uint256);

    function releasePayment(address payable account) external;

    function releasePayment(IERC20Upgradeable token, address account) external;
}

interface IAspenSplitPaymentV1 is ICedarSplitPaymentV0 {
    function getPendingPayment(address account) external view returns (uint256);

    function getPendingPayment(IERC20Upgradeable token, address account) external view returns (uint256);
}

interface IAspenSplitPaymentV2 is IAspenSplitPaymentV1 {
    /// @dev Getter for the total shares held by payees.
    function getTotalShares() external view returns (uint256);

    /// @dev Getter for the amount of shares held by an account.
    function getShares(address account) external view returns (uint256);

    /// @dev Getter for the address of the payee number `index`.
    function getPayee(uint256 index) external view returns (address);
}