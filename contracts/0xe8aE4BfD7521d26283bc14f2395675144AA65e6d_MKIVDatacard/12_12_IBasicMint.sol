// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IBasicMint {
    function mintPrice() external view returns (uint256);

    function mintLimit() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function mintData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function mintActive() external view returns (bool);

    function mintedByAccount(address) external view returns (uint256);

    function mint(uint256 quantity) external payable;
}