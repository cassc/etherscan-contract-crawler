// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVault {

    function getVaultLiquidity() external view  returns (uint256);

    function getAssetBalance(address market) external view returns (uint256);

    function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance);

}