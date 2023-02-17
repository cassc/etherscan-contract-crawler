// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import './IERC20Metadata.sol';
import './IERC20.sol';

interface IERC20Like is IERC20, IERC20Metadata {
    function mint(address receiver, uint256 shares) external;
}