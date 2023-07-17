// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IGovernable.sol";
import "./IPausable.sol";

interface IVesperPool is IGovernable, IPausable, IERC20Metadata {
    function calculateUniversalFee(uint256 profit_) external view returns (uint256 _fee);

    function deposit(uint256 collateralAmount_) external;

    function excessDebt(address strategy_) external view returns (uint256);

    function poolAccountant() external view returns (address);

    function poolRewards() external view returns (address);

    function reportEarning(uint256 profit_, uint256 loss_, uint256 payback_) external;

    function reportLoss(uint256 loss_) external;

    function sweepERC20(address fromToken_) external;

    function withdraw(uint256 share_) external;

    function keepers() external view returns (address[] memory);

    function isKeeper(address address_) external view returns (bool);

    function maintainers() external view returns (address[] memory);

    function isMaintainer(address address_) external view returns (bool);

    function pricePerShare() external view returns (uint256);

    function strategy(
        address strategy_
    )
        external
        view
        returns (
            bool _active,
            uint256 _interestFee, // Obsolete
            uint256 _debtRate, // Obsolete
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio,
            uint256 _externalDepositFee
        );

    function token() external view returns (IERC20);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address strategy_) external view returns (uint256);

    function totalValue() external view returns (uint256);

    function totalDebt() external view returns (uint256);
}