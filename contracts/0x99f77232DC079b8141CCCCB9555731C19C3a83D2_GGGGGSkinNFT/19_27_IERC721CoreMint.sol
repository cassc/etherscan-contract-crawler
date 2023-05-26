// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC721CoreMint {
    function mint(address to, uint256 amount) external;

    function remainSupply() external view returns (uint256);

    function supplies()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}