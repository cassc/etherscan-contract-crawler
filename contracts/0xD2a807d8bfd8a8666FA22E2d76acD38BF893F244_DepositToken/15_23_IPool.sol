// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IDepositToken.sol";
import "./IDebtToken.sol";
import "./ITreasury.sol";
import "./IRewardsDistributor.sol";
import "./IPoolRegistry.sol";

/**
 * @notice Pool interface
 */
interface IPool is IPauseable, IGovernable {
    function debtFloorInUsd() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function issueFee() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function repayFee() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function liquidationFees() external view returns (uint128 liquidatorIncentive, uint128 protocolFee);

    function feeCollector() external view returns (address);

    function maxLiquidable() external view returns (uint256);

    function doesSyntheticTokenExist(ISyntheticToken syntheticToken_) external view returns (bool);

    function doesDebtTokenExist(IDebtToken debtToken_) external view returns (bool);

    function doesDepositTokenExist(IDepositToken depositToken_) external view returns (bool);

    function depositTokenOf(IERC20 underlying_) external view returns (IDepositToken);

    function debtTokenOf(ISyntheticToken syntheticToken_) external view returns (IDebtToken);

    function getDepositTokens() external view returns (address[] memory);

    function getDebtTokens() external view returns (address[] memory);

    function getRewardsDistributors() external view returns (IRewardsDistributor[] memory);

    function debtOf(address account_) external view returns (uint256 _debtInUsd);

    function depositOf(address account_) external view returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd);

    function debtPositionOf(address account_)
        external
        view
        returns (
            bool _isHealthy,
            uint256 _depositInUsd,
            uint256 _debtInUsd,
            uint256 _issuableLimitInUsd,
            uint256 _issuableInUsd
        );

    function addDebtToken(IDebtToken debtToken_) external;

    function removeDebtToken(IDebtToken debtToken_) external;

    function addDepositToken(address depositToken_) external;

    function removeDepositToken(IDepositToken depositToken_) external;

    function liquidate(
        ISyntheticToken syntheticToken_,
        address account_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        external
        returns (
            uint256 _totalSeized,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteLiquidateIn(
        ISyntheticToken syntheticToken_,
        uint256 totalToSeized_,
        IDepositToken depositToken_
    )
        external
        view
        returns (
            uint256 _amountToRepay,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteLiquidateMax(
        ISyntheticToken syntheticToken_,
        address account_,
        IDepositToken depositToken_
    ) external view returns (uint256 _maxAmountToRepay);

    function quoteLiquidateOut(
        ISyntheticToken syntheticToken_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        external
        view
        returns (
            uint256 _totalSeized,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteSwapIn(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountOut_
    ) external view returns (uint256 _amountIn, uint256 _fee);

    function quoteSwapOut(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _fee);

    function swap(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, uint256 _fee);

    function updateSwapFee(uint256 newSwapFee_) external;

    function updateDebtFloor(uint256 newDebtFloorInUsd_) external;

    function updateDepositFee(uint256 newDepositFee_) external;

    function updateIssueFee(uint256 newIssueFee_) external;

    function updateWithdrawFee(uint256 newWithdrawFee_) external;

    function updateRepayFee(uint256 newRepayFee_) external;

    function updateLiquidatorIncentive(uint128 newLiquidatorIncentive_) external;

    function updateProtocolLiquidationFee(uint128 newProtocolLiquidationFee_) external;

    function updateMaxLiquidable(uint256 newMaxLiquidable_) external;

    function updateTreasury(ITreasury newTreasury_) external;

    function treasury() external view returns (ITreasury);

    function masterOracle() external view returns (IMasterOracle);

    function poolRegistry() external view returns (IPoolRegistry);

    function addToDepositTokensOfAccount(address account_) external;

    function removeFromDepositTokensOfAccount(address account_) external;

    function addToDebtTokensOfAccount(address account_) external;

    function removeFromDebtTokensOfAccount(address account_) external;

    function getDepositTokensOfAccount(address account_) external view returns (address[] memory);

    function getDebtTokensOfAccount(address account_) external view returns (address[] memory);

    function addRewardsDistributor(IRewardsDistributor distributor_) external;

    function removeRewardsDistributor(IRewardsDistributor distributor_) external;

    function toggleIsSwapActive() external;

    function isSwapActive() external view returns (bool);
}