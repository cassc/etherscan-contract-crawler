// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function balanceOf(address user) external returns (uint256);
}