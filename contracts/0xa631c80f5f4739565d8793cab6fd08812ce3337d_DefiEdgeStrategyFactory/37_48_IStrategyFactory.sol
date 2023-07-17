//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@chainlink/contracts/src/v0.7/interfaces/FeedRegistryInterface.sol";
import "./IOneInchRouter.sol";
import "./IStrategyBase.sol";
import "./IDefiEdgeStrategyDeployer.sol";

interface IStrategyFactory {
    struct CreateStrategyParams {
        // address of the strategy operator (manager)
        address operator;
        // address where all the strategy's fees should go
        address feeTo;
        // management fee rate, 1e8 is 100%
        uint256 managementFeeRate;
        // performance fee rate, 1e8 is 100%
        uint256 performanceFeeRate;
        // limit in the form of shares
        uint256 limit;
        // address of the pool
        IUniswapV3Pool pool;
        // Chainlink's pair with USD, if token0 has pair with USD it should be true and v.v. same for token1
        bool[2] usdAsBase;
        // initial ticks to setup
        IStrategyBase.Tick[] ticks;
    }

    function totalIndex() external view returns (uint256);

    function strategyCreationFee() external view returns (uint256); // fee for strategy creation in native token

    function defaultAllowedSlippage() external view returns (uint256); // 1e18 means 100%

    function defaultAllowedDeviation() external view returns (uint256); // 1e18 means 100%

    function defaultAllowedSwapDeviation() external view returns (uint256); // 1e18 means 100%

    function allowedDeviation(address _pool) external view returns (uint256); // 1e18 means 100%

    function allowedSwapDeviation(address _pool) external view returns (uint256); // 1e18 means 100%

    function allowedSlippage(address _pool) external view returns (uint256); // 1e18 means 100%

    function isValidStrategy(address) external view returns (bool);
    
    function isAllowedOneInchCaller(address) external view returns (bool);

    function strategyByIndex(uint256) external view returns (address);

    function strategyByManager(address) external view returns (address);

    function feeTo() external view returns (address);

    function denied(address) external view returns (bool);

    function protocolFeeRate() external view returns (uint256); // 1e8 means 100%

    function protocolPerformanceFeeRate() external view returns (uint256); // 1e8 means 100%

    function governance() external view returns (address);

    function pendingGovernance() external view returns (address);

    function deployerProxy() external view returns (IDefiEdgeStrategyDeployer);

    function uniswapV3Factory() external view returns (IUniswapV3Factory);

    function chainlinkRegistry() external view returns (FeedRegistryInterface);

    function oneInchRouter() external view returns (IOneInchRouter);

    function freezeEmergency() external view returns (bool);

    function getHeartBeat(address _base, address _quote) external view returns (uint256);

    function createStrategy(CreateStrategyParams calldata params) external payable;

    function freezeEmergencyFunctions() external;

    function changeAllowedSlippage(address, uint256) external;

    function changeAllowedDeviation(address, uint256) external;

    function changeAllowedSwapDeviation(address, uint256) external;

    function changeDefaultValues(
        uint256,
        uint256,
        uint256
    ) external;

    event NewStrategy(address indexed strategy, address indexed creater);
    event ChangeProtocolFee(uint256 fee);
    event ChangeProtocolPerformanceFee(uint256 fee);
    event StrategyStatusChanged(bool status);
    event ChangeStrategyCreationFee(uint256 amount);
    event ClaimFees(address to, uint256 amount);
    event ChangeAllowedSlippage(address pool, uint256 value);
    event ChangeAllowedDeviation(address pool, uint256 value);
    event ChangeAllowedSwapDeviation(address pool, uint256 value);
    event EmergencyFrozen();
}