// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IInfoCenter {
    function vaultPositionRouter(address _vault) external view returns (address);
    function vaultRouter(address _vault) external view returns (address);
    function vaultOrderbook(address _vault) external view returns (address);
    function routerApprovedContract(address _router, address _contract) external view returns (bool);
    function stableToken( ) external view returns (address);

    function getData(uint256 _sourceId, int256 _para) external view returns (bool, int256);
    // function getDataList(uint256 _sourceId, int256 _paraList) external view returns (int256[] memory);
}