// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { ZeroCurveWrapper } from "./ZeroCurveWrapper.sol";
import { ICurveInt128 } from "../interfaces/CurvePools/ICurveInt128.sol";
import { ICurveInt256 } from "../interfaces/CurvePools/ICurveInt256.sol";
import { ICurveUInt128 } from "../interfaces/CurvePools/ICurveUInt128.sol";
import { ICurveUInt256 } from "../interfaces/CurvePools/ICurveUInt256.sol";
import { ICurveUnderlyingInt128 } from "../interfaces/CurvePools/ICurveUnderlyingInt128.sol";
import { ICurveUnderlyingInt256 } from "../interfaces/CurvePools/ICurveUnderlyingInt256.sol";
import { ICurveUnderlyingUInt128 } from "../interfaces/CurvePools/ICurveUnderlyingUInt128.sol";
import { ICurveUnderlyingUInt256 } from "../interfaces/CurvePools/ICurveUnderlyingUInt256.sol";
import { CurveLib } from "../libraries/CurveLib.sol";

contract ZeroCurveFactory {
  event CreateWrapper(address _wrapper);

  function createWrapper(
    bool _underlying,
    uint256 _tokenInIndex,
    uint256 _tokenOutIndex,
    address _pool
  ) public payable {
    emit CreateWrapper(address(new ZeroCurveWrapper(_tokenInIndex, _tokenOutIndex, _pool, _underlying)));
  }

  fallback() external payable {
    /* no op */
  }
}