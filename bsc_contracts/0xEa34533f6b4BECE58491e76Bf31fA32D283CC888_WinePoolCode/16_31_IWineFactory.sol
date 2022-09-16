// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineFactory {

    function winePoolCode() external view returns (address);
    function baseUri() external view returns (string memory);
    function baseSymbol() external view returns (string memory);

    function initialize(
        address proxyAdmin_,
        address winePoolCode_,
        address manager_,
        string memory baseUri_,
        string memory baseSymbol_
    ) external;

    function getPool(uint256 poolId) external view returns (address);

    function allPoolsLength() external view returns (uint);

    function createWinePool(
        string memory name_,

        uint256 maxTotalSupply_,
        uint256 winePrice_
    ) external returns (uint256 poolId, address winePoolAddress);

    function disablePool(uint256 poolId) external;
}