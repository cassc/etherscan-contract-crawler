// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Base/IERC20Full.sol";
import "./Base/IREUSDMinterBase.sol";
import "./Curve/ICurveStableSwap.sol";
import "./Curve/ICurvePool.sol";
import "./Curve/ICurveGauge.sol";

interface IRECurveZapper is IREUSDMinterBase, IUpgradeableBase
{
    error UnsupportedToken();
    error ZeroAmount();
    error PoolMismatch();
    error TooManyPoolCoins();
    error TooManyBasePoolCoins();
    error MissingREUSD();
    error BasePoolWithREUSD();

    function isRECurveZapper() external view returns (bool);
    function basePoolCoinCount() external view returns (uint256);
    function pool() external view returns (ICurveStableSwap);
    function basePool() external view returns (ICurvePool);
    function basePoolToken() external view returns (IERC20);
    function gauge() external view returns (ICurveGauge);

    function zap(IERC20 token, uint256 tokenAmount, bool mintREUSD) external;
    function zapPermit(IERC20Full token, uint256 tokenAmount, bool mintREUSD, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function unzap(IERC20 token, uint256 tokenAmount) external;    

    struct TokenAmount
    {        
        IERC20 token;
        uint256 amount;
    }
    struct PermitData
    {
        IERC20Full token;
        uint32 deadline;
        uint8 v;
        uint256 permitAmount;
        bytes32 r;
        bytes32 s;
    }

    function multiZap(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts) external;
    function multiZapPermit(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts, PermitData[] calldata permits) external;
}