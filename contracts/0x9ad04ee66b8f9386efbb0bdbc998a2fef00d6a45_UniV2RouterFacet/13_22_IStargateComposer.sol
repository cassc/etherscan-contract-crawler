// SPDX-License-Identifier: BUSL-1.1
import {IStargateRouter} from './IStargateRouter.sol';

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IStargateComposer is IStargateRouter {
  function stargateRouter() external view returns (address);
}