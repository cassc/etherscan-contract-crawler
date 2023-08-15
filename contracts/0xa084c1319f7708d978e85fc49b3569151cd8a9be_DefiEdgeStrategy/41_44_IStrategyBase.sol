//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStrategyFactory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./IOneInchRouter.sol";
import "./IStrategyManager.sol";

interface IStrategyBase {
    struct Tick {
        int24 tickLower;
        int24 tickUpper;
    }

    event ClaimFee(uint256 managerFee, uint256 protocolFee);

    function onHold() external view returns (bool);

    function accManagementFeeShares() external view returns (uint256);

    function accPerformanceFeeShares() external view returns (uint256);

    function accProtocolPerformanceFeeShares() external view returns (uint256);

    function factory() external view returns (IStrategyFactory);

    function pool() external view returns (IUniswapV3Pool);

    function oneInchRouter() external view returns (IOneInchRouter);

    function manager() external view returns (IStrategyManager);

    function usdAsBase(uint256 index) external view returns (bool);

    function claimFee() external;
}