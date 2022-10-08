// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../pool/IPool.sol';

interface IClient is INameVersion {

    function broker() external view returns (address);

    function addLiquidity(
        address pool,
        address asset,
        uint256 amount,
        IPool.OracleSignature[] memory oracleSignatures
    ) external payable;

    function removeLiquidity(
        address pool,
        address asset,
        uint256 amount,
        IPool.OracleSignature[] memory oracleSignatures
    ) external;

    function addMargin(
        address pool,
        address asset,
        uint256 amount,
        IPool.OracleSignature[] memory oracleSignatures
    ) external payable;

    function removeMargin(
        address pool,
        address asset,
        uint256 amount,
        IPool.OracleSignature[] memory oracleSignatures
    ) external;

    function trade(
        address pool,
        string memory symbolName,
        int256 tradeVolume,
        int256 priceLimit,
        IPool.OracleSignature[] memory oracleSignatures
    ) external;

    function transfer(address asset, address to, uint256 amount) external;

    function claimRewardAsLpVenus(address pool) external;

    function claimRewardAsTraderVenus(address pool) external;

    function claimRewardAsLpAave(address pool) external;

    function claimRewardAsTraderAave(address pool) external;

}