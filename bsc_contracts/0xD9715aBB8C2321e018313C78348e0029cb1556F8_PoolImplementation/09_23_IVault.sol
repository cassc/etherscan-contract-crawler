// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';

interface IVault is INameVersion {

    function pool() external view returns (address);

    function comptroller() external view returns (address);

    function vTokenETH() external view returns (address);

    function tokenXVS() external view returns (address);

    function vaultLiquidityMultiplier() external view returns (uint256);

    function getVaultLiquidity() external view  returns (uint256);

    function getHypotheticalVaultLiquidity(address vTokenModify, uint256 redeemVTokens) external view returns (uint256);

    function isInMarket(address vToken) external view returns (bool);

    function getMarketsIn() external view returns (address[] memory);

    function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance);

    function enterMarket(address vToken) external;

    function exitMarket(address vToken) external;

    function mint() external payable;

    function mint(address vToken, uint256 amount) external;

    function redeem(address vToken, uint256 amount) external;

    function redeemAll(address vToken) external;

    function redeemUnderlying(address vToken, uint256 amount) external;

    function transfer(address underlying, address to, uint256 amount) external;

    function transferAll(address underlying, address to) external returns (uint256);

    function claimVenus(address account) external;

}