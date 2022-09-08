// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface INormalLotto {
    function getPriceFeeds() external view returns (string[] memory);

    function asset2USD(string calldata symbol) external view returns (uint256);

    function asset2USD(string calldata symbol, uint256 amount) external view returns (uint256);

    function expiredPeriod() external view returns (uint256);

    function carryOver() external view returns (address payable);
}