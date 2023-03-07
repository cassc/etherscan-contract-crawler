// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { IEulerExec } from "../../../../interfaces/external/euler/IEuler.sol";
import "../../../../interfaces/external/euler/IEulerStakingRewards.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./GenericEuler.sol";

/// @title GenericEulerStaker
/// @author  Angle Core Team
/// @notice `GenericEuler` with staking to earn EUL incentives
contract GenericEulerStaker is GenericEuler {
    using SafeERC20 for IERC20;
    using Address for address;

    // ================================= CONSTANTS =================================
    uint32 internal constant _TWAP_PERIOD = 1 minutes;
    IEulerExec private constant _EXEC = IEulerExec(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);
    IERC20 private constant _EUL = IERC20(0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b);

    // ================================= VARIABLES =================================
    IEulerStakingRewards public eulerStakingContract;
    AggregatorV3Interface public chainlinkOracle;
    uint8 public isUniMultiplied;

    // ================================ CONSTRUCTOR ================================

    /// @notice Wrapper built on top of the `initializeEuler` method to initialize the contract
    function initialize(
        address _strategy,
        string memory _name,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList,
        address oneInch_,
        IEulerStakingRewards _eulerStakingContract,
        AggregatorV3Interface _chainlinkOracle
    ) external {
        initializeEuler(_strategy, _name, governorList, guardian, keeperList, oneInch_);
        eulerStakingContract = _eulerStakingContract;
        chainlinkOracle = _chainlinkOracle;
        IERC20(address(eToken)).safeApprove(address(_eulerStakingContract), type(uint256).max);
        IERC20(_EUL).safeApprove(oneInch_, type(uint256).max);
    }

    // ============================= EXTERNAL FUNCTION =============================

    /// @notice Claim earned EUL
    function claimRewards() external {
        eulerStakingContract.getReward();
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @inheritdoc GenericEuler
    function _stakeAll() internal override {
        eulerStakingContract.stake(eToken.balanceOf(address(this)));
    }

    /// @inheritdoc GenericEuler
    function _unstake(uint256 amount) internal override returns (uint256 eTokensUnstaked) {
        // Take an upper bound as when withdrawing from Euler there could be rounding issue
        eTokensUnstaked = eToken.convertUnderlyingToBalance(amount) + 1;
        eulerStakingContract.withdraw(eTokensUnstaked);
    }

    /// @inheritdoc GenericEuler
    function _stakedBalance() internal view override returns (uint256 amount) {
        uint256 amountInEToken = eulerStakingContract.balanceOf(address(this));
        amount = eToken.convertBalanceToUnderlying(amountInEToken);
    }

    /// @inheritdoc GenericEuler
    function _stakingApr(int256 amount) internal view override returns (uint256 apr) {
        uint256 periodFinish = eulerStakingContract.periodFinish();
        uint256 newTotalSupply = eToken.convertBalanceToUnderlying(eulerStakingContract.totalSupply());
        if (amount >= 0) newTotalSupply += uint256(amount);
        else newTotalSupply -= uint256(-amount);
        if (periodFinish <= block.timestamp || newTotalSupply == 0) return 0;
        // APRs are in 1e18 and a 5% penalty on the EUL price is taken to avoid overestimations
        // `_estimatedEulToWant()` and eTokens are in base 18
        apr =
            (_estimatedEulToWant(eulerStakingContract.rewardRate() * _SECONDS_IN_YEAR) * 9_500 * 10**6) /
            10_000 /
            newTotalSupply;
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @notice Estimates the amount of `want` we will get out by swapping it for EUL
    /// @param quoteAmount The amount to convert in the out-currency
    /// @return The value of the `quoteAmount` expressed in out-currency
    /// @dev Uses Euler TWAP and Chainlink spot price
    function _estimatedEulToWant(uint256 quoteAmount) internal view returns (uint256) {
        (uint256 twapEUL, ) = _EXEC.getPrice(address(_EUL));
        return _quoteOracleEUL((quoteAmount * twapEUL) / 10**18);
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice Return quote amount of the EUL amount
    function _quoteOracleEUL(uint256 amount) internal view virtual returns (uint256 quoteAmount) {
        // No stale checks are made as it is only used to estimate the staking APR
        (, int256 ethPriceUSD, , , ) = chainlinkOracle.latestRoundData();
        // ethPriceUSD is in base 8
        return (uint256(ethPriceUSD) * amount) / 1e8;
    }
}