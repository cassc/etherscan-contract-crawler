// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ITokenMinter {
    function totalWeight() external view returns (uint256);

    function veAssetWeights(address) external view returns (uint256);

    function earned(uint256 _amount) external view returns (uint256);

    function mint(address, uint256) external;

    function mint(address) external;

    function distribute(address) external;

    function burn(address, uint256) external;
}