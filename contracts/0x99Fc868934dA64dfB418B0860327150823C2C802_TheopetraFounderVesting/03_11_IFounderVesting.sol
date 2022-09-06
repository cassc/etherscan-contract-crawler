// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IFounderVesting {
    event PayeeAdded(address account, uint256 shares);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event InitialMint(uint256 amount);

    function getTotalShares() external view returns (uint256);

    function getTotalReleased(IERC20 token) external view returns (uint256);

    function getShares(address account) external view returns (uint256);

    function getReleased(IERC20 token, address account) external view returns (uint256);

    function release(IERC20 token) external;

    function releaseAmount(IERC20 token, uint256 amount) external;

    function getReleasable(IERC20 token, address account) external view returns (uint256);
}