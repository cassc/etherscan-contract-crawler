// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface InstaFlashAggregatorInterface {
    event LogFlashloan(address indexed account, uint256 indexed route, address[] tokens, uint256[] amounts);

    function flashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 route,
        bytes calldata data,
        bytes calldata instaData
    ) external;

    function getRoutes() external pure returns (uint16[] memory routes);
}