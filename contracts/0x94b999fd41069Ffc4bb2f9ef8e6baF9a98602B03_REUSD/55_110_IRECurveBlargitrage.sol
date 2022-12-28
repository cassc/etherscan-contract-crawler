// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREUSD.sol";
import "./Base/IUpgradeableBase.sol";
import "./Curve/ICurveStableSwap.sol";
import "./IRECustodian.sol";

interface IRECurveBlargitrage is IUpgradeableBase
{
    error MissingDesiredToken();
    
    function isRECurveBlargitrage() external view returns (bool);
    function pool() external view returns (ICurveStableSwap);
    function basePool() external view returns (ICurvePool);
    function desiredToken() external view returns (IERC20);
    function REUSD() external view returns (IREUSD);
    function custodian() external view returns (IRECustodian);

    function balance() external;
}