// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ITokenMinter {
    function totalWeight() external returns (uint256);

    function veAssetWeights(address) external returns (uint256);

    function mint(address, uint256) external;

    function mint(address) external;

    function distribute(address) external;

    function burn(address, uint256) external;
}