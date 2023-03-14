// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IFeeHandler {
    function payFees(
        IERC20 underlying,
        uint256 profit,
        address riskProvider,
        address vaultOwner,
        uint16 vaultFee
    ) external returns (uint256 feesPaid);

    function setRiskProviderFee(address riskProvider, uint16 fee) external;

    /* ========== EVENTS ========== */

    event FeesPaid(address indexed vault, uint profit, uint ecosystemCollected, uint treasuryCollected, uint riskProviderColected, uint vaultFeeCollected);
    event RiskProviderFeeUpdated(address indexed riskProvider, uint indexed fee);
    event EcosystemFeeUpdated(uint indexed fee);
    event TreasuryFeeUpdated(uint indexed fee);
    event EcosystemCollectorUpdated(address indexed collector);
    event TreasuryCollectorUpdated(address indexed collector);
    event FeeCollected(address indexed collector, IERC20 indexed underlying, uint amount);
    event EcosystemFeeCollected(IERC20 indexed underlying, uint amount);
    event TreasuryFeeCollected(IERC20 indexed underlying, uint amount);
}