// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "./storage/FeeProviderStorage.sol";
import "./lib/WadRayMath.sol";

error SenderIsNotGovernor();
error PoolRegistryIsNull();
error NewValueIsSameAsCurrent();
error FeeIsGreaterThanTheMax();
error TierDiscountTooHigh();
error TiersNotOrderedByMin();

/**
 * @title FeeProvider contract
 */
contract FeeProvider is Initializable, FeeProviderStorageV1 {
    using WadRayMath for uint256;

    string public constant VERSION = "1.3.0";

    uint256 internal constant MAX_FEE_VALUE = 0.25e18; // 25%
    uint256 internal constant MAX_FEE_DISCOUNT = 1e18; // 100%

    /// @notice Emitted when deposit fee is updated
    event DepositFeeUpdated(uint256 oldDepositFee, uint256 newDepositFee);

    /// @notice Emitted when issue fee is updated
    event IssueFeeUpdated(uint256 oldIssueFee, uint256 newIssueFee);

    /// @notice Emitted when liquidator incentive is updated
    event LiquidatorIncentiveUpdated(uint256 oldLiquidatorIncentive, uint256 newLiquidatorIncentive);

    /// @notice Emitted when protocol liquidation fee is updated
    event ProtocolLiquidationFeeUpdated(uint256 oldProtocolLiquidationFee, uint256 newProtocolLiquidationFee);

    /// @notice Emitted when repay fee is updated
    event RepayFeeUpdated(uint256 oldRepayFee, uint256 newRepayFee);

    /// @notice Emitted when swap fee is updated
    event SwapDefaultFeeUpdated(uint256 oldSwapFee, uint256 newSwapFee);

    /// @notice Emitted when tiers are updated
    event TiersUpdated(Tier[] oldTiers, Tier[] newTiers);

    /// @notice Emitted when withdraw fee is updated
    event WithdrawFeeUpdated(uint256 oldWithdrawFee, uint256 newWithdrawFee);

    /**
     * @notice Throws if caller isn't the governor
     */
    modifier onlyGovernor() {
        if (msg.sender != poolRegistry.governor()) revert SenderIsNotGovernor();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(IPoolRegistry poolRegistry_, IESMET esMET_) public initializer {
        if (address(poolRegistry_) == address(0)) revert PoolRegistryIsNull();

        poolRegistry = poolRegistry_;
        esMET = esMET_;

        liquidationFees = LiquidationFees({
            liquidatorIncentive: 1e17, // 10%
            protocolFee: 8e16 // 8%
        });
        defaultSwapFee = 25e14; // 0.25%
    }

    /**
     * @notice Get fee discount tiers
     */
    function getTiers() external view returns (Tier[] memory _tiers) {
        return tiers;
    }

    /**
     * @notice Get the swap fee for a given account
     * Fee discount are applied on top of the default swap fee depending on user's esMET balance
     * @param account_ The account address
     * @return _swapFee The account's swap fee
     */
    function swapFeeFor(address account_) external view override returns (uint256 _swapFee) {
        uint256 _len = tiers.length;

        if (_len == 0) {
            return defaultSwapFee;
        }

        uint256 _balance = esMET.balanceOf(account_);

        if (_balance < tiers[0].min) {
            return defaultSwapFee;
        }

        uint256 i = 1;
        while (i < _len) {
            if (_balance < tiers[i].min) {
                unchecked {
                    // Note: `discount` is always <= `1e18`
                    return defaultSwapFee.wadMul(1e18 - tiers[i - 1].discount);
                }
            }

            unchecked {
                ++i;
            }
        }

        unchecked {
            // Note: `discount` is always <= `1e18`
            return defaultSwapFee.wadMul(1e18 - tiers[_len - 1].discount);
        }
    }

    /**
     * @notice Update deposit fee
     */
    function updateDepositFee(uint256 newDepositFee_) external onlyGovernor {
        if (newDepositFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentDepositFee = depositFee;
        if (newDepositFee_ == _currentDepositFee) revert NewValueIsSameAsCurrent();
        emit DepositFeeUpdated(_currentDepositFee, newDepositFee_);
        depositFee = newDepositFee_;
    }

    /**
     * @notice Update issue fee
     */
    function updateIssueFee(uint256 newIssueFee_) external onlyGovernor {
        if (newIssueFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentIssueFee = issueFee;
        if (newIssueFee_ == _currentIssueFee) revert NewValueIsSameAsCurrent();
        emit IssueFeeUpdated(_currentIssueFee, newIssueFee_);
        issueFee = newIssueFee_;
    }

    /**
     * @notice Update liquidator incentive
     * @dev liquidatorIncentive + protocolFee can't surpass max
     */
    function updateLiquidatorIncentive(uint128 newLiquidatorIncentive_) external onlyGovernor {
        LiquidationFees memory _current = liquidationFees;
        if (newLiquidatorIncentive_ + _current.protocolFee > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        if (newLiquidatorIncentive_ == _current.liquidatorIncentive) revert NewValueIsSameAsCurrent();
        emit LiquidatorIncentiveUpdated(_current.liquidatorIncentive, newLiquidatorIncentive_);
        liquidationFees.liquidatorIncentive = newLiquidatorIncentive_;
    }

    /**
     * @notice Update protocol liquidation fee
     * @dev liquidatorIncentive + protocolFee can't surpass max
     */
    function updateProtocolLiquidationFee(uint128 newProtocolLiquidationFee_) external onlyGovernor {
        LiquidationFees memory _current = liquidationFees;
        if (newProtocolLiquidationFee_ + _current.liquidatorIncentive > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        if (newProtocolLiquidationFee_ == _current.protocolFee) revert NewValueIsSameAsCurrent();
        emit ProtocolLiquidationFeeUpdated(_current.protocolFee, newProtocolLiquidationFee_);
        liquidationFees.protocolFee = newProtocolLiquidationFee_;
    }

    /**
     * @notice Update repay fee
     */
    function updateRepayFee(uint256 newRepayFee_) external onlyGovernor {
        if (newRepayFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentRepayFee = repayFee;
        if (newRepayFee_ == _currentRepayFee) revert NewValueIsSameAsCurrent();
        emit RepayFeeUpdated(_currentRepayFee, newRepayFee_);
        repayFee = newRepayFee_;
    }

    /**
     * @notice Update swap fee
     */
    function updateDefaultSwapFee(uint256 newDefaultSwapFee_) external onlyGovernor {
        if (newDefaultSwapFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _current = defaultSwapFee;
        if (newDefaultSwapFee_ == _current) revert NewValueIsSameAsCurrent();
        emit SwapDefaultFeeUpdated(_current, newDefaultSwapFee_);
        defaultSwapFee = newDefaultSwapFee_;
    }

    /**
     * @notice Update fee discount tiers
     */
    function updateTiers(Tier[] memory tiers_) external onlyGovernor {
        emit TiersUpdated(tiers, tiers_);
        delete tiers;

        uint256 _len = tiers_.length;
        for (uint256 i; i < _len; ++i) {
            Tier memory _tier = tiers_[i];
            if (_tier.discount > MAX_FEE_DISCOUNT) revert TierDiscountTooHigh();
            if (i > 0 && tiers_[i - 1].min > _tier.min) revert TiersNotOrderedByMin();
            tiers.push(_tier);
        }
    }

    /**
     * @notice Update withdraw fee
     */
    function updateWithdrawFee(uint256 newWithdrawFee_) external onlyGovernor {
        if (newWithdrawFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentWithdrawFee = withdrawFee;
        if (newWithdrawFee_ == _currentWithdrawFee) revert NewValueIsSameAsCurrent();
        emit WithdrawFeeUpdated(_currentWithdrawFee, newWithdrawFee_);
        withdrawFee = newWithdrawFee_;
    }
}