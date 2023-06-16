// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ITBDPasses {
    function MAX_MINT() external view returns (uint256);

    function price() external view returns (uint256);

    function mint(uint256 qt) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}