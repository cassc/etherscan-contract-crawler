//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "../../utils/ICBBImmutableArgs.sol";

/**
 * @dev Convertible Bond Box for a ButtonTranche bond
 */

interface IConvertibleBondBox is ICBBImmutableArgs {
    event Lend(
        address caller,
        address borrower,
        address lender,
        uint256 stableAmount,
        uint256 price
    );
    event Borrow(
        address caller,
        address borrower,
        address lender,
        uint256 stableAmount,
        uint256 price
    );
    event RedeemStable(address caller, uint256 safeSlipAmount, uint256 price);
    event RedeemSafeTranche(address caller, uint256 safeSlipAmount);
    event RedeemRiskTranche(address caller, uint256 riskSlipAmount);
    event Repay(
        address caller,
        uint256 stablesPaid,
        uint256 riskTranchePayout,
        uint256 price
    );
    event Initialized(address owner);
    event ReInitialized(uint256 initialPrice, uint256 timestamp);
    event FeeUpdate(uint256 newFee);

    error PenaltyTooHigh(uint256 given, uint256 maxPenalty);
    error BondIsMature(uint256 currentTime, uint256 maturity);
    error InitialPriceTooHigh(uint256 given, uint256 maxPrice);
    error InitialPriceIsZero(uint256 given, uint256 maxPrice);
    error ConvertibleBondBoxNotStarted(uint256 given, uint256 minStartDate);
    error BondNotMatureYet(uint256 maturityDate, uint256 currentTime);
    error MinimumInput(uint256 input, uint256 reqInput);
    error FeeTooLarge(uint256 input, uint256 maximum);

    //Need to add getters for state variables

    /**
     * @dev Sets startdate to be block.timestamp, sets initialPrice, and takes initial atomic deposit
     * @param _initialPrice the initialPrice for the CBB
     * Requirements:
     *  - `msg.sender` is owner
     */

    function reinitialize(uint256 _initialPrice) external;

    /**
     * @dev Lends StableTokens for SafeSlips when provided with matching borrow collateral
     * @param _borrower The address to send the RiskSlip and StableTokens to 
     * @param _lender The address to send the SafeSlips to 
     * @param _stableAmount The amount of StableTokens to lend
     * Requirements:
     *  - `msg.sender` must have `approved` `_stableAmount` stable tokens to this contract
        - CBB must be reinitialized
     */

    function lend(
        address _borrower,
        address _lender,
        uint256 _stableAmount
    ) external;

    /**
     * @dev Borrows with tranches of CollateralTokens when provided with a matching amount of StableTokens
     * Collateral tokens get tranched and any non-convertible bond box tranches get sent back to borrower 
     * @param _borrower The address to send the RiskSlip and StableTokens to 
     * @param _lender The address to send the SafeSlips to 
     * @param _safeTrancheAmount The amount of SafeTranche being borrowed against
     * Requirements:
     *  - `msg.sender` must have `approved` appropriate amount of tranches of tokens to this contract
        - CBB must be reinitialized
        - must be enough stable tokens inside convertible bond box to borrow 
     */

    function borrow(
        address _borrower,
        address _lender,
        uint256 _safeTrancheAmount
    ) external;

    /**
     * @dev returns time-weighted current price for SafeSlip, with final price as $1.00 at maturity
     */

    function currentPrice() external view returns (uint256);

    /**
     * @dev allows repayment of loan in exchange for proportional amount of SafeTranche and Z-tranche
     * @param _stableAmount The amount of stable-Tokens to repay with
     * Requirements:
     *  - `msg.sender` must have `approved` `stableAmount` of stable tokens to this contract
     */

    function repay(uint256 _stableAmount) external;

    /**
     * @dev allows repayment of loan in exchange for proportional amount of SafeTranche and Z-tranche
     * @param _riskSlipAmount The amount of riskSlips to be repaid
     * Requirements:
     *  - `msg.sender` must have `approved` appropriate amount of stable tokens to this contract
     */

    function repayMax(uint256 _riskSlipAmount) external;

    /**
     * @dev allows lender to redeem SafeSlips for SafeTranches
     * @param _safeSlipAmount The amount of safe-slips to redeem
     * Requirements:
     *  - can only be called after Bond is Mature
     *  - `msg.sender` must have `approved` `safeSlipAmount` of SafeSlip tokens to this contract
     */

    function redeemSafeTranche(uint256 _safeSlipAmount) external;

    /**
     * @dev allows borrower to redeem RiskSlips for tranches (i.e. default)
     * @param _riskSlipAmount The amount of RiskSlips to redeem
     * Requirements:
     *  - can only be called after Bond is Mature
     *  - `msg.sender` must have `approved` `_riskSlipAmount` of RiskSlip tokens to this contract
     */

    function redeemRiskTranche(uint256 _riskSlipAmount) external;

    /**
     * @dev allows lender to redeem SafeSlips for StableTokens
     * @param _safeSlipAmount The amount of SafeSlips to redeem
     * Requirements:
     *  - `msg.sender` must have `approved` `safeSlipAmount` of safe-Slip tokens to this contract
     *  - can only be called when StableTokens are present inside CBB
     */

    function redeemStable(uint256 _safeSlipAmount) external;

    /**
     * @dev Updates the fee taken on redeem/repay to the given new fee
     *
     * Requirements
     * - `msg.sender` has admin role
     * - `newFeeBps` is in range [0, 50]
     */

    function setFee(uint256 newFeeBps) external;

    /**
     * @dev Gets the start date
     */
    function s_startDate() external view returns (uint256);

    /**
     * @dev Gets the total repaid safe slips to date
     */
    function s_repaidSafeSlips() external view returns (uint256);

    /**
     * @dev Gets the tranche granularity constant
     */
    function s_trancheGranularity() external view returns (uint256);

    /**
     * @dev Gets the penalty granularity constant
     */
    function s_penaltyGranularity() external view returns (uint256);

    /**
     * @dev Gets the price granularity constant
     */
    function s_priceGranularity() external view returns (uint256);

    /**
     * @dev Gets the fee basis points
     */
    function feeBps() external view returns (uint256);

    /**
     * @dev Gets the basis points denominator constant. AKA a fee granularity constant
     */
    function BPS() external view returns (uint256);

    /**
     * @dev Gets the max fee basis points constant.
     */
    function maxFeeBPS() external view returns (uint256);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Gets the initialPrice of SafeSlip.
     */
    function s_initialPrice() external view returns (uint256);
}