// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH9 is IERC20Metadata {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    // Only valid for Arbitrum
    function depositTo(address account) external payable;

    function withdrawTo(address account, uint256 amount) external;
}