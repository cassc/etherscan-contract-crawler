// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SignedMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SignedMathUpgradeable.sol";

import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { BondHelpers } from "./_utils/BondHelpers.sol";

import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { IERC20Upgradeable, IPerpetualTranche, IBondIssuer, IFeeStrategy, IPricingStrategy, IDiscountStrategy, IBondController, ITranche } from "./_interfaces/IPerpetualTranche.sol";

/// @notice Expected contract call to be triggered by authorized caller.
/// @param caller The address which triggered the call.
/// @param authorizedCaller The address which is authorized to trigger the call.
error UnauthorizedCall(address caller, address authorizedCaller);

/// @notice Expected a valid percentage value from 0-100 as a fixed point number with {PERC_DECIMALS}.
/// @param value Invalid value.
error InvalidPerc(uint256 value);

/// @notice Expected contract reference to not be `address(0)`.
error UnacceptableReference();

/// @notice Expected strategy to return a fixed point with exactly expected decimals.
error InvalidStrategyDecimals(uint256 decimals, uint256 expectDecimals);

/// @notice Expected bond issuer's collateral token to match underlying collateral token.
/// @param  invalidCollateral Address of the input bond issuer's collateral token.
/// @param underlyingCollateral Address of underlying system collateral token.
error InvalidCollateral(address invalidCollateral, address underlyingCollateral);

/// @notice Expected minTrancheMaturity be less than or equal to maxTrancheMaturity.
/// @param minTrancheMaturitySec Minimum tranche maturity time in seconds.
/// @param minTrancheMaturitySec Maximum tranche maturity time in seconds.
error InvalidTrancheMaturityBounds(uint256 minTrancheMaturitySec, uint256 maxTrancheMaturitySec);

/// @notice Expected deposited tranche to be of current deposit bond.
/// @param trancheIn Address of the deposit tranche.
/// @param depositBond Address of the currently accepted deposit bond.
error UnacceptableDepositTranche(ITranche trancheIn, IBondController depositBond);

/// @notice Expected to mint a non-zero amount of tokens.
/// @param trancheInAmt The amount of tranche tokens deposited.
/// @param perpAmtMint The amount of tranche tokens mint.
error UnacceptableMintAmt(uint256 trancheInAmt, uint256 perpAmtMint);

/// @notice Expected to burn a non-zero amount of tokens.
/// @param requestedBurnAmt The amount of tranche tokens requested to be burnt.
/// @param perpSupply The current supply of perp tokens.
error UnacceptableBurnAmt(uint256 requestedBurnAmt, uint256 perpSupply);

/// @notice Expected redemption to result in supply reduction.
/// @param newSupply The new total supply after redemption.
/// @param perpSupply The current supply of perp tokens.
error ExpectedSupplyReduction(uint256 newSupply, uint256 perpSupply);

/// @notice Expected rollover to be acceptable.
/// @param trancheIn Address of the tranche token transferred in.
/// @param tokenOut Address of the reserve token transferred out.
error UnacceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut);

/// @notice Expected to rollover a non-zero amount of tokens.
/// @param trancheInAmt The amount of tranche tokens deposited.
/// @param trancheOutAmt The amount of tranche tokens withdrawn.
/// @param rolloverAmt The perp denominated value of tokens rolled over.
error UnacceptableRolloverAmt(uint256 trancheInAmt, uint256 trancheOutAmt, uint256 rolloverAmt);

/// @notice Expected supply to be lower than the defined max supply.
/// @param newSupply The new total supply after minting.
/// @param currentMaxSupply The current max supply.
error ExceededMaxSupply(uint256 newSupply, uint256 currentMaxSupply);

/// @notice Expected the total mint amount per tranche to be lower than the limit.
/// @param trancheIn Address of the deposit tranche.
/// @param mintAmtForCurrentTranche The amount of perps that have been minted using the tranche.
/// @param maxMintAmtPerTranche The amount of perps that can be minted per tranche.
error ExceededMaxMintPerTranche(ITranche trancheIn, uint256 mintAmtForCurrentTranche, uint256 maxMintAmtPerTranche);

/// @notice Expected the percentage of reserve value held as mature tranches to be at least
///         as much as the target percentage.
/// @param matureValuePerc The current percentage of reserve value held as mature tranches.
/// @param matureValueTargetPerc The target percentage.
error BelowMatureValueTargetPerc(uint256 matureValuePerc, uint256 matureValueTargetPerc);

/// @notice Expected transfer out asset to not be a reserve asset.
/// @param token Address of the token transferred.
error UnauthorizedTransferOut(IERC20Upgradeable token);

/**
 *  @title PerpetualTranche
 *
 *  @notice An opinionated implementation of a perpetual note ERC-20 token contract, backed by buttonwood tranches.
 *
 *          Perpetual note tokens (or perps for short) are backed by tranche tokens held in this contract's reserve.
 *          Users can mint perps by depositing tranche tokens into the reserve.
 *          They can redeem tokens from the reserve by burning their perps.
 *
 *          The whitelisted bond issuer issues new deposit bonds periodically based on a predefined frequency.
 *          Users can ONLY mint perps for tranche tokens belonging to the active "deposit" bond.
 *          Users can burn perps, and redeem a proportional share of tokens held in the reserve.
 *
 *          Once tranche tokens held in the reserve mature the underlying collateral is extracted
 *          into the reserve. The system keeps track of total mature tranches held by the reserve.
 *          This acts as a "virtual" tranche balance for all collateral extracted from the mature tranches.
 *
 *          At any time, the reserve holds at most 2 classes of tokens
 *          ie) the normal tranche tokens and mature tranche (which is essentially the underlying collateral token).
 *
 *          Incentivized parties can "rollover" tranches approaching maturity or the mature tranche,
 *          for newer tranche tokens that belong to the current "depositBond".
 *
 *          The time dependent system state is updated "lazily" without a need for an explicit poke
 *          from the outside world. Every external function that deals with the reserve
 *          invokes the `afterStateUpdate` modifier at the entry-point.
 *          This brings the system storage state up to date.
 *
 */
contract PerpetualTranche is
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPerpetualTranche
{
    // data handling
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using BondHelpers for IBondController;

    // ERC20 operations
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //-------------------------------------------------------------------------
    // Perp Math Basics:
    //
    // System holds tokens in the reserve {t1, t2 ... tn}
    // with balances {b1, b2 ... bn}.
    //
    // Internally reserve token denominations (amounts/balances) are
    // standardized using a discount factor.
    // Standard denomination: b'i = bi . discount(ti)
    //
    // Discount are typically expected to be ~1.0 for safe tranches,
    // but could be less for riskier junior tranches.
    //
    //
    // System reserve value:
    // RV => t'1 . price(t1) + t'2 . price(t2) + .... + t'n . price(tn)
    //    => Σ t'i . price(ti)
    //
    //
    // When `ai` tokens of type `ti` are deposited into the system:
    // Mint: mintAmt (perps) => (a'i * price(ti) / RV) * supply(perps)
    //
    // This ensures that if 10% of the collateral value is deposited,
    // the minter receives 10% of the perp token supply.
    // This removes any race conditions for minters based on reserve state.
    //
    //
    // When `p` perp tokens are redeemed:
    // Redeem: ForEach ti => (p / supply(perps)) * bi
    //
    //
    // When `ai` tokens of type `ti` are rotated in for tokens of type `tj`
    //  => ai * discount(ti) * price(ti) =  aj * discount(tj) * price(tj)
    // Rotation: aj => ai * discount(ti) * price(ti) / (discount(tj) * price(tj))
    //
    //
    //-------------------------------------------------------------------------
    // Constants & Immutables
    uint8 public constant DISCOUNT_DECIMALS = 18;
    uint256 public constant UNIT_DISCOUNT = (10**DISCOUNT_DECIMALS);

    uint8 public constant PRICE_DECIMALS = 8;
    uint256 public constant UNIT_PRICE = (10**PRICE_DECIMALS);

    uint8 public constant PERC_DECIMALS = 6;
    uint256 public constant UNIT_PERC = 10**PERC_DECIMALS;
    uint256 public constant HUNDRED_PERC = 100 * UNIT_PERC;

    //-------------------------------------------------------------------------
    // Storage

    /// @dev The perp token balances are represented as a fixed point unsigned integer with these many decimals.
    uint8 private _decimals;

    //--------------------------------------------------------------------------
    // CONFIG

    /// @inheritdoc IPerpetualTranche
    address public override keeper;

    /// @notice External contract points controls fees & incentives.
    IFeeStrategy public override feeStrategy;

    /// @notice External contract that computes a given reserve token's price.
    /// @dev The computed price is expected to be a fixed point unsigned integer with {PRICE_DECIMALS} decimals.
    IPricingStrategy public pricingStrategy;

    /// @notice External contract that computes a given reserve token's discount factor.
    /// @dev It is a multiplier, applied to every asset when added to the reserve.
    ///      This accounts for things like tranche seniority and underlying collateral volatility.
    ///      It also allows for standardizing denominations when comparing two different reserve tokens.
    ///      For example, a factor of 0.95 on a particular tranche results in a 5% discount.
    ///      The discount factor is expected to be a fixed point unsigned integer with {DISCOUNT_DECIMALS} decimals.
    IDiscountStrategy public discountStrategy;

    /// @notice External contract that stores a predefined bond config and frequency,
    ///         and issues new bonds when poked.
    /// @dev Only tranches of bonds issued by this whitelisted issuer are accepted into the reserve.
    IBondIssuer public bondIssuer;

    /// @notice The active deposit bond of whose tranches are currently being accepted to mint perps.
    IBondController private _depositBond;

    /// @notice The minimum maturity time in seconds for a tranche below which
    ///         it can be rolled over.
    uint256 public minTrancheMaturitySec;

    /// @notice The maximum maturity time in seconds for a tranche above which
    ///         it can NOT get added into the reserve.
    uint256 public maxTrancheMaturitySec;

    /// @notice The percentage of the reserve value to be held as mature tranches.
    uint256 public matureValueTargetPerc;

    /// @notice The maximum supply of perps that can exist at any given time.
    uint256 public maxSupply;

    /// @notice The max number of perps that can be minted for each tranche in the minting bond.
    uint256 public maxMintAmtPerTranche;

    /// @notice The total number of perps that have been minted using a given tranche.
    mapping(ITranche => uint256) public mintedSupplyPerTranche;

    /// @notice Discount factor actually "applied" on each reserve token. It is computed and recorded when
    ///         a token is deposited into the system for the first time.
    /// @dev For all calculations thereafter, the token's applied discount will be used.
    ///      The discount is stored as a fixed point unsigned integer with {DISCOUNT_DECIMALS} decimals.
    mapping(IERC20Upgradeable => uint256) private _appliedDiscounts;

    //--------------------------------------------------------------------------
    // RESERVE

    /// @notice A record of all tokens in the reserve which back the perps.
    EnumerableSetUpgradeable.AddressSet private _reserves;

    /// @notice The amount of all the mature tranches extracted and held as the collateral token,
    ///         i.e) the reserve's "virtual" mature tranche balance.
    /// @dev The mature tranche is assumed to have {UNIT_DISCOUNT}. So we do NOT have to
    ///      scale using the discount factor when dealing with the mature tranche balance.
    uint256 private _matureTrancheBalance;

    //--------------------------------------------------------------------------
    // Modifiers

    /// @dev Updates time-dependent reserve state.
    modifier afterStateUpdate() {
        updateState();
        _;
    }

    /// @dev Throws if called by any account other than the keeper.
    modifier onlyKeeper() {
        if (keeper != _msgSender()) {
            revert UnauthorizedCall(_msgSender(), keeper);
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Contract state initialization.
    /// @param name ERC-20 Name of the Perp token.
    /// @param symbol ERC-20 Symbol of the Perp token.
    /// @param collateral_ Address of the underlying collateral token.
    /// @param bondIssuer_ Address of the bond issuer contract.
    /// @param feeStrategy_ Address of the fee strategy contract.
    /// @param pricingStrategy_ Address of the pricing strategy contract.
    /// @param discountStrategy_ Address of the discount strategy contract.
    function init(
        string memory name,
        string memory symbol,
        IERC20Upgradeable collateral_,
        IBondIssuer bondIssuer_,
        IFeeStrategy feeStrategy_,
        IPricingStrategy pricingStrategy_,
        IDiscountStrategy discountStrategy_
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        _decimals = IERC20MetadataUpgradeable(address(collateral_)).decimals();

        // NOTE: `_reserveAt(0)` always points to the underling collateral token
        // and is to be never updated.
        _reserves.add(address(collateral_));
        _syncReserve(collateral_);
        _applyDiscount(collateral_, UNIT_DISCOUNT);

        updateBondIssuer(bondIssuer_);
        updateFeeStrategy(feeStrategy_);
        updatePricingStrategy(pricingStrategy_);
        updateDiscountStrategy(discountStrategy_);

        updateTolerableTrancheMaturity(1, type(uint256).max);
        updateMintingLimits(type(uint256).max, type(uint256).max);
        updateMatureValueTargetPerc(0);
    }

    //--------------------------------------------------------------------------
    // ADMIN only methods

    /// @notice Pauses deposits, withdrawals and rollovers.
    /// @dev NOTE: ERC-20 functions, like transfers will always remain operational.
    function pause() public onlyKeeper {
        _pause();
    }

    /// @notice Unpauses deposits, withdrawals and rollovers.
    /// @dev NOTE: ERC-20 functions, like transfers will always remain operational.
    function unpause() public onlyKeeper {
        _unpause();
    }

    /// @notice Updates the reference to the keeper.
    /// @param newKeeper The address of the new keeper.
    function updateKeeper(address newKeeper) public virtual onlyOwner {
        if (newKeeper == address(0)) {
            revert UnacceptableReference();
        }
        address prevKeeper = keeper;
        keeper = newKeeper;
        emit UpdatedKeeper(prevKeeper, newKeeper);
    }

    /// @notice Update the reference to the bond issuer contract.
    /// @param bondIssuer_ New bond issuer address.
    function updateBondIssuer(IBondIssuer bondIssuer_) public onlyOwner {
        if (address(bondIssuer_) == address(0)) {
            revert UnacceptableReference();
        }
        if (address(_reserveAt(0)) != bondIssuer_.collateral()) {
            revert InvalidCollateral(bondIssuer_.collateral(), address(_reserveAt(0)));
        }
        bondIssuer = bondIssuer_;
        emit UpdatedBondIssuer(bondIssuer_);
    }

    /// @notice Update the reference to the fee strategy contract.
    /// @param feeStrategy_ New strategy address.
    function updateFeeStrategy(IFeeStrategy feeStrategy_) public onlyOwner {
        if (address(feeStrategy_) == address(0)) {
            revert UnacceptableReference();
        }
        feeStrategy = feeStrategy_;
        emit UpdatedFeeStrategy(feeStrategy_);
    }

    /// @notice Update the reference to the pricing strategy contract.
    /// @param pricingStrategy_ New strategy address.
    function updatePricingStrategy(IPricingStrategy pricingStrategy_) public onlyOwner {
        if (address(pricingStrategy_) == address(0)) {
            revert UnacceptableReference();
        }
        if (pricingStrategy_.decimals() != PRICE_DECIMALS) {
            revert InvalidStrategyDecimals(pricingStrategy_.decimals(), PRICE_DECIMALS);
        }
        pricingStrategy = pricingStrategy_;
        emit UpdatedPricingStrategy(pricingStrategy_);
    }

    /// @notice Update the reference to the discount strategy contract.
    /// @param discountStrategy_ New strategy address.
    function updateDiscountStrategy(IDiscountStrategy discountStrategy_) public onlyOwner {
        if (address(discountStrategy_) == address(0)) {
            revert UnacceptableReference();
        }
        if (discountStrategy_.decimals() != DISCOUNT_DECIMALS) {
            revert InvalidStrategyDecimals(discountStrategy_.decimals(), DISCOUNT_DECIMALS);
        }
        discountStrategy = discountStrategy_;
        emit UpdatedDiscountStrategy(discountStrategy_);
    }

    /// @notice Update the maturity tolerance parameters.
    /// @param minTrancheMaturitySec_ New minimum maturity time.
    /// @param maxTrancheMaturitySec_ New maximum maturity time.
    function updateTolerableTrancheMaturity(uint256 minTrancheMaturitySec_, uint256 maxTrancheMaturitySec_)
        public
        onlyOwner
    {
        if (minTrancheMaturitySec_ > maxTrancheMaturitySec_) {
            revert InvalidTrancheMaturityBounds(minTrancheMaturitySec_, maxTrancheMaturitySec_);
        }
        minTrancheMaturitySec = minTrancheMaturitySec_;
        maxTrancheMaturitySec = maxTrancheMaturitySec_;
        emit UpdatedTolerableTrancheMaturity(minTrancheMaturitySec_, maxTrancheMaturitySec_);
    }

    /// @notice Update parameters controlling the perp token mint limits.
    /// @param maxSupply_ New max total supply.
    /// @param maxMintAmtPerTranche_ New max total for per tranche in minting bond.
    function updateMintingLimits(uint256 maxSupply_, uint256 maxMintAmtPerTranche_) public onlyOwner {
        maxSupply = maxSupply_;
        maxMintAmtPerTranche = maxMintAmtPerTranche_;
        emit UpdatedMintingLimits(maxSupply_, maxMintAmtPerTranche_);
    }

    /// @notice Update the mature value target percentage parameter.
    /// @param matureValueTargetPerc_ The new target percentage.
    function updateMatureValueTargetPerc(uint256 matureValueTargetPerc_) public onlyOwner {
        if (matureValueTargetPerc_ > HUNDRED_PERC) {
            revert InvalidPerc(matureValueTargetPerc_);
        }
        matureValueTargetPerc = matureValueTargetPerc_;
        emit UpdatedMatureValueTargetPerc(matureValueTargetPerc);
    }

    /// @notice Allows the owner to transfer non-critical assets out of the system if required.
    /// @param token The token address.
    /// @param to The destination address.
    /// @param amount The amount of tokens to be transferred.
    function transferERC20(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) external afterStateUpdate onlyOwner {
        if (_inReserve(token) || feeToken() == token) {
            revert UnauthorizedTransferOut(token);
        }
        token.safeTransfer(to, amount);
    }

    //--------------------------------------------------------------------------
    // External methods

    /// @inheritdoc IPerpetualTranche
    function deposit(ITranche trancheIn, uint256 trancheInAmt)
        external
        override
        nonReentrant
        whenNotPaused
        afterStateUpdate
    {
        if (!_isBondTranche(trancheIn, _depositBond)) {
            revert UnacceptableDepositTranche(trancheIn, _depositBond);
        }

        // calculates the amount of perp tokens when depositing `trancheInAmt` of tranche tokens
        uint256 perpAmtMint = _computeMintAmt(trancheIn, trancheInAmt);
        if (trancheInAmt == 0 || perpAmtMint == 0) {
            revert UnacceptableMintAmt(trancheInAmt, perpAmtMint);
        }

        // calculates the fees to mint `perpAmtMint` of perp token
        (int256 reserveFee, uint256 protocolFee) = feeStrategy.computeMintFees(perpAmtMint);

        // transfers tranche tokens from the sender to the reserve
        _transferIntoReserve(msg.sender, trancheIn, trancheInAmt);

        // mints perp tokens to the sender
        _mint(msg.sender, perpAmtMint);

        // settles fees
        _settleFee(msg.sender, reserveFee, protocolFee);

        // post-deposit checks
        mintedSupplyPerTranche[trancheIn] += perpAmtMint;
        _enforcePerTrancheSupplyCap(trancheIn);
        _enforceTotalSupplyCap();
    }

    /// @inheritdoc IPerpetualTranche
    function redeem(uint256 perpAmtBurnt) external override nonReentrant whenNotPaused afterStateUpdate {
        // gets the current perp supply
        uint256 perpSupply = totalSupply();

        // verifies if burn amount is acceptable
        if (perpAmtBurnt == 0 || perpAmtBurnt > perpSupply) {
            revert UnacceptableBurnAmt(perpAmtBurnt, perpSupply);
        }

        // calculates share of reserve tokens to be redeemed
        (IERC20Upgradeable[] memory tokensOuts, uint256[] memory tokenOutAmts) = _computeRedemptionAmts(perpAmtBurnt);

        // calculates the fees to burn `perpAmtBurnt` of perp token
        (int256 reserveFee, uint256 protocolFee) = feeStrategy.computeBurnFees(perpAmtBurnt);

        // updates the mature tranche balance
        _updateMatureTrancheBalance((_matureTrancheBalance * (perpSupply - perpAmtBurnt)) / perpSupply);

        // settles fees
        _settleFee(msg.sender, reserveFee, protocolFee);

        // burns perp tokens from the sender
        _burn(msg.sender, perpAmtBurnt);

        // transfers reserve tokens out
        for (uint256 i = 0; i < tokensOuts.length; i++) {
            if (tokenOutAmts[i] > 0) {
                _transferOutOfReserve(msg.sender, tokensOuts[i], tokenOutAmts[i]);
            }
        }

        // post-redeem checks
        _enforceSupplyReduction(perpSupply);
    }

    /// @inheritdoc IPerpetualTranche
    function rollover(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtAvailable
    ) external override nonReentrant whenNotPaused afterStateUpdate {
        // verifies if rollover is acceptable
        if (!_isAcceptableRollover(trancheIn, tokenOut)) {
            revert UnacceptableRollover(trancheIn, tokenOut);
        }

        // calculates the perp denominated amount rolled over and the tokenOutAmt
        IPerpetualTranche.RolloverPreview memory r = _computeRolloverAmt(
            trancheIn,
            tokenOut,
            trancheInAmtAvailable,
            type(uint256).max
        );

        // verifies if rollover amount is acceptable
        if (r.trancheInAmt == 0 || r.tokenOutAmt == 0 || r.perpRolloverAmt == 0) {
            revert UnacceptableRolloverAmt(r.trancheInAmt, r.tokenOutAmt, r.perpRolloverAmt);
        }

        // calculates the fees to rollover `r.perpRolloverAmt` of perp token
        (int256 reserveFee, uint256 protocolFee) = feeStrategy.computeRolloverFees(r.perpRolloverAmt);

        // transfers tranche tokens from the sender to the reserve
        _transferIntoReserve(msg.sender, trancheIn, r.trancheInAmt);

        // settles fees
        _settleFee(msg.sender, reserveFee, protocolFee);

        // updates the mature tranche balance
        if (_isMatureTranche(tokenOut)) {
            _updateMatureTrancheBalance(_matureTrancheBalance - r.trancheOutAmt);
        }

        // transfers tranche from the reserve to the sender
        _transferOutOfReserve(msg.sender, tokenOut, r.tokenOutAmt);

        // post-rollover checks
        _enforceMatureValueTarget();
        _enforceTotalSupplyCap();
    }

    /// @inheritdoc IPerpetualTranche
    function getMatureTrancheBalance() external override afterStateUpdate returns (uint256) {
        return _matureTrancheBalance;
    }

    /// @inheritdoc IPerpetualTranche
    function getDepositBond() external override afterStateUpdate returns (IBondController) {
        return _depositBond;
    }

    /// @inheritdoc IPerpetualTranche
    function isAcceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut)
        external
        override
        afterStateUpdate
        returns (bool)
    {
        return _isAcceptableRollover(trancheIn, tokenOut);
    }

    /// @inheritdoc IPerpetualTranche
    function getReserveCount() external override afterStateUpdate returns (uint256) {
        return _reserveCount();
    }

    /// @inheritdoc IPerpetualTranche
    function getReserveAt(uint256 i) external override afterStateUpdate returns (IERC20Upgradeable) {
        return _reserveAt(i);
    }

    /// @inheritdoc IPerpetualTranche
    function inReserve(IERC20Upgradeable token) external override afterStateUpdate returns (bool) {
        return _inReserve(token);
    }

    /// @inheritdoc IPerpetualTranche
    function getReserveTrancheBalance(IERC20Upgradeable tranche) external override afterStateUpdate returns (uint256) {
        if (!_inReserve(tranche)) {
            return 0;
        }
        return _isMatureTranche(tranche) ? _matureTrancheBalance : _reserveBalance(tranche);
    }

    /// @inheritdoc IPerpetualTranche
    /// @dev Reserve tokens which are not up for rollover are marked by `address(0)`.
    function getReserveTokensUpForRollover() external override afterStateUpdate returns (IERC20Upgradeable[] memory) {
        uint256 reserveCount = _reserveCount();
        IERC20Upgradeable[] memory rolloverTokens = new IERC20Upgradeable[](reserveCount);

        if (_matureTrancheBalance > 0) {
            rolloverTokens[0] = _reserveAt(0);
        }

        // Iterating through the reserve to find tranches that are no longer "acceptable"
        for (uint256 i = 1; i < reserveCount; i++) {
            IERC20Upgradeable token = _reserveAt(i);
            IBondController bond = IBondController(ITranche(address(token)).bond());
            if (!_isAcceptableForReserve(bond)) {
                rolloverTokens[i] = token;
            }
        }

        return rolloverTokens;
    }

    /// @inheritdoc IPerpetualTranche
    /// @dev Returns a fixed point with {PRICE_DECIMALS} decimals.
    function getAvgPrice() external override afterStateUpdate returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        return totalSupply_ > 0 ? _reserveValue() / totalSupply_ : 0;
    }

    /// @inheritdoc IPerpetualTranche
    function computeMintAmt(ITranche trancheIn, uint256 trancheInAmt)
        external
        override
        afterStateUpdate
        returns (uint256)
    {
        return _computeMintAmt(trancheIn, trancheInAmt);
    }

    /// @inheritdoc IPerpetualTranche
    function computeRedemptionAmts(uint256 perpAmtBurnt)
        external
        override
        afterStateUpdate
        returns (IERC20Upgradeable[] memory, uint256[] memory)
    {
        return _computeRedemptionAmts(perpAmtBurnt);
    }

    /// @inheritdoc IPerpetualTranche
    /// @dev Set `tokenOutAmtRequested` to max(uint256) to use the reserve balance.
    function computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtAvailable,
        uint256 tokenOutAmtRequested
    ) external override afterStateUpdate returns (IPerpetualTranche.RolloverPreview memory) {
        return _computeRolloverAmt(trancheIn, tokenOut, trancheInAmtAvailable, tokenOutAmtRequested);
    }

    //--------------------------------------------------------------------------
    // Public methods

    /// @inheritdoc IPerpetualTranche
    /// @dev Lazily updates time-dependent reserve storage state.
    ///      This function is to be invoked on all external function entry points which are
    ///      read the reserve storage. This function is intended to be idempotent.
    function updateState() public override {
        // Lazily queries the bond issuer to get the most recently issued bond
        // and updates with the new deposit bond if it's "acceptable".
        IBondController newBond = bondIssuer.getLatestBond();

        // If the new bond has been issued by the issuer and is "acceptable"
        if (_depositBond != newBond && _isAcceptableForReserve(newBond)) {
            // updates `_depositBond` with the new bond
            _depositBond = newBond;
            emit UpdatedDepositBond(newBond);
        }

        // Lazily checks if every reserve tranche has reached maturity.
        // If so redeems the tranche balance for the underlying collateral and
        // removes the tranche from the reserve list.
        // NOTE: We traverse the reserve list in the reverse order
        //       as deletions involve swapping the deleted element to the
        //       end of the list and removing the last element.
        //       We also skip the `reserveAt(0)`, i.e) the mature tranche,
        //       which is never removed.
        uint256 reserveCount = _reserveCount();
        for (uint256 i = reserveCount - 1; i > 0; i--) {
            ITranche tranche = ITranche(address(_reserveAt(i)));
            IBondController bond = IBondController(tranche.bond());

            // If bond is not mature yet, move to the next tranche
            if (bond.timeToMaturity() > 0) {
                continue;
            }

            // If bond has reached maturity but hasn't been poked
            if (!bond.isMature()) {
                bond.mature();
            }

            // Redeeming the underlying collateral token
            uint256 trancheBalance = _reserveBalance(tranche);
            bond.redeemMature(address(tranche), trancheBalance);
            _syncReserve(tranche);

            // Keeps track of the total tranches redeemed
            _updateMatureTrancheBalance(
                _matureTrancheBalance + _toStdTrancheAmt(trancheBalance, computeDiscount(tranche))
            );
        }

        // Keeps track of the mature tranche's underlying balance
        // ie) the rebasing collateral token
        _syncReserve(_reserveAt(0));
    }

    //--------------------------------------------------------------------------
    // External view methods

    /// @inheritdoc IPerpetualTranche
    function collateral() external view override returns (IERC20Upgradeable) {
        return _reserveAt(0);
    }

    //--------------------------------------------------------------------------
    // Public view methods

    /// @inheritdoc IPerpetualTranche
    function perpERC20() public view override returns (IERC20Upgradeable) {
        return IERC20Upgradeable(address(this));
    }

    /// @inheritdoc IPerpetualTranche
    function reserve() public view override returns (address) {
        return address(this);
    }

    /// @inheritdoc IPerpetualTranche
    function protocolFeeCollector() public view override returns (address) {
        return owner();
    }

    /// @inheritdoc IPerpetualTranche
    function feeToken() public view override returns (IERC20Upgradeable) {
        return feeStrategy.feeToken();
    }

    /// @inheritdoc IPerpetualTranche
    /// @dev Gets the applied discount for the given tranche if it's set,
    ///      if NOT computes the discount.
    function computeDiscount(IERC20Upgradeable token) public view override returns (uint256) {
        uint256 discount = _appliedDiscounts[token];
        return (discount > 0) ? discount : discountStrategy.computeTrancheDiscount(token);
    }

    /// @inheritdoc IPerpetualTranche
    function computePrice(IERC20Upgradeable token) public view override returns (uint256) {
        return
            _isMatureTranche(token)
                ? pricingStrategy.computeMatureTranchePrice(token, _reserveBalance(token), _matureTrancheBalance)
                : pricingStrategy.computeTranchePrice(ITranche(address(token)));
    }

    /// @notice Returns the number of decimals used to get its user representation.
    /// @dev For example, if `decimals` equals `2`, a balance of `505` tokens should
    ///      be displayed to a user as `5.05` (`505 / 10 ** 2`).
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    //--------------------------------------------------------------------------
    // Private methods

    /// @dev Computes the perp mint amount for given amount of tranche tokens deposited into the reserve.
    function _computeMintAmt(ITranche trancheIn, uint256 trancheInAmt) private view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 stdTrancheInAmt = _toStdTrancheAmt(trancheInAmt, computeDiscount(trancheIn));
        uint256 trancheInPrice = computePrice(trancheIn);
        uint256 perpAmtMint = (totalSupply_ > 0)
            ? (stdTrancheInAmt * trancheInPrice * totalSupply_) / _reserveValue()
            : (stdTrancheInAmt * trancheInPrice) / UNIT_PRICE;
        return (perpAmtMint);
    }

    /// @dev Computes the reserve token amounts redeemed when a given number of perps are burnt.
    function _computeRedemptionAmts(uint256 perpAmtBurnt)
        private
        view
        returns (IERC20Upgradeable[] memory, uint256[] memory)
    {
        uint256 totalSupply_ = totalSupply();
        uint256 reserveCount = _reserveCount();
        IERC20Upgradeable[] memory reserveTokens = new IERC20Upgradeable[](reserveCount);
        uint256[] memory redemptionAmts = new uint256[](reserveCount);
        for (uint256 i = 0; i < reserveCount; i++) {
            reserveTokens[i] = _reserveAt(i);
            redemptionAmts[i] = (totalSupply_ > 0)
                ? (_reserveBalance(reserveTokens[i]) * perpAmtBurnt) / totalSupply_
                : 0;
        }
        return (reserveTokens, redemptionAmts);
    }

    /// @dev Computes the amount of reserve tokens that can be rolled out for the given amount of tranches deposited.
    function _computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtAvailable,
        uint256 tokenOutAmtRequested
    ) private view returns (IPerpetualTranche.RolloverPreview memory) {
        IPerpetualTranche.RolloverPreview memory r;

        uint256 trancheInDiscount = computeDiscount(trancheIn);
        uint256 trancheOutDiscount = computeDiscount(tokenOut);
        uint256 trancheInPrice = computePrice(trancheIn);
        uint256 trancheOutPrice = computePrice(tokenOut);
        uint256 tokenOutBalance = _reserveBalance(tokenOut);
        tokenOutAmtRequested = MathUpgradeable.min(tokenOutAmtRequested, tokenOutBalance);

        if (trancheInDiscount == 0 || trancheOutDiscount == 0 || trancheInPrice == 0 || trancheOutPrice == 0) {
            r.remainingTrancheInAmt = trancheInAmtAvailable;
            return r;
        }

        r.trancheInAmt = trancheInAmtAvailable;
        uint256 stdTrancheInAmt = _toStdTrancheAmt(trancheInAmtAvailable, trancheInDiscount);

        // Basic rollover:
        // (stdTrancheInAmt . trancheInPrice) = (stdTrancheOutAmt . trancheOutPrice)
        uint256 stdTrancheOutAmt = (stdTrancheInAmt * trancheInPrice) / trancheOutPrice;
        r.trancheOutAmt = _fromStdTrancheAmt(stdTrancheOutAmt, trancheOutDiscount);

        // However, if the tokenOut is the mature tranche (held as naked collateral),
        // we infer the tokenOut amount from the tranche denomination.
        // (tokenOutAmt = collateralBalance * trancheOutAmt / matureTrancheBalance)
        bool isMatureTrancheOut = _isMatureTranche(tokenOut);
        r.tokenOutAmt = isMatureTrancheOut
            ? ((tokenOutBalance * r.trancheOutAmt) / _matureTrancheBalance)
            : r.trancheOutAmt;

        // When the token out balance is NOT covered:
        // we fix tokenOutAmt = tokenOutAmtRequested and back calculate other values
        if (r.tokenOutAmt > tokenOutAmtRequested) {
            r.tokenOutAmt = tokenOutAmtRequested;
            r.trancheOutAmt = isMatureTrancheOut
                ? (_matureTrancheBalance * r.tokenOutAmt) / tokenOutBalance
                : r.tokenOutAmt;
            stdTrancheOutAmt = _toStdTrancheAmt(r.trancheOutAmt, trancheOutDiscount);
            stdTrancheInAmt = (stdTrancheOutAmt * trancheOutPrice) / trancheInPrice;
            r.trancheInAmt = _fromStdTrancheAmt(stdTrancheInAmt, trancheInDiscount);
        }

        r.perpRolloverAmt = (stdTrancheOutAmt * trancheOutPrice * totalSupply()) / _reserveValue();
        r.remainingTrancheInAmt = trancheInAmtAvailable - r.trancheInAmt;
        return r;
    }

    /// @dev Transfers tokens from the given address to self and updates the reserve list.
    /// @return Reserve's token balance after transfer in.
    function _transferIntoReserve(
        address from,
        IERC20Upgradeable token,
        uint256 trancheAmt
    ) private returns (uint256) {
        token.safeTransferFrom(from, reserve(), trancheAmt);
        return _syncReserve(token);
    }

    /// @dev Transfers tokens from self into the given address and updates the reserve list.
    /// @return Reserve's token balance after transfer out.
    function _transferOutOfReserve(
        address to,
        IERC20Upgradeable token,
        uint256 tokenAmt
    ) private returns (uint256) {
        token.safeTransfer(to, tokenAmt);
        return _syncReserve(token);
    }

    /// @dev Keeps the reserve storage up to date. Logs the token balance held by the reserve.
    /// @return The Reserve's token balance.
    function _syncReserve(IERC20Upgradeable token) private returns (uint256) {
        uint256 balance = _reserveBalance(token);
        emit ReserveSynced(token, balance);

        // If token is the mature tranche,
        // it NEVER gets removed from the `_reserves` list.
        if (_isMatureTranche(token)) {
            return balance;
        }

        // Otherwise `_reserves` list gets updated.
        bool inReserve_ = _inReserve(token);
        if (balance > 0 && !inReserve_) {
            // Inserts new tranche into reserve list.
            _reserves.add(address(token));

            // Stores the discount for future usage.
            _applyDiscount(token, computeDiscount(token));
        }

        if (balance == 0 && inReserve_) {
            // Removes tranche from reserve list.
            _reserves.remove(address(token));

            // Frees up stored discount.
            _applyDiscount(token, 0);

            // Frees up minted supply.
            delete mintedSupplyPerTranche[ITranche(address(token))];
        }

        return balance;
    }

    /// @dev Handles fee transfer between the payer, the reserve and the protocol fee collector.
    function _settleFee(
        address payer,
        int256 reserveFee,
        uint256 protocolFee
    ) private {
        // Handling reserve fees
        uint256 reserveFeeAbs = SignedMathUpgradeable.abs(reserveFee);
        if (reserveFee > 0) {
            _handleFeeTransferIn(payer, reserve(), reserveFeeAbs);
        } else if (reserveFee < 0) {
            _handleFeeTransferOut(payer, reserveFeeAbs);
        }
        // Handling protocol fees
        if (protocolFee > 0) {
            _handleFeeTransferIn(payer, protocolFeeCollector(), protocolFee);
        }
    }

    /// @dev Transfers fee tokens from the payer to the destination.
    function _handleFeeTransferIn(
        address payer,
        address destination,
        uint256 feeAmt
    ) private {
        IERC20Upgradeable feeToken_ = feeToken();
        bool isNativeFeeToken = (feeToken_ == perpERC20());
        // Funds are coming in
        if (isNativeFeeToken) {
            // Handling a special case, when the fee is to be charged as the perp token itself
            // In this case we don't need to make an external call to the token ERC-20 to "transferFrom"
            // the payer, since this is still an internal call {msg.sender} will still point to the payer
            // and we can just "transfer" from the payer's wallet.
            transfer(destination, feeAmt);
        } else {
            feeToken_.safeTransferFrom(payer, destination, feeAmt);
        }
    }

    /// @dev Transfers fee from the reserve to the destination.
    function _handleFeeTransferOut(address destination, uint256 feeAmt) private {
        IERC20Upgradeable feeToken_ = feeToken();
        bool isNativeFeeToken = (feeToken_ == perpERC20());
        // Funds are going out
        if (isNativeFeeToken) {
            uint256 balance = _reserveBalance(feeToken_);
            feeToken_.safeTransfer(destination, MathUpgradeable.min(feeAmt, balance));

            // In case that the reserve's balance doesn't cover the entire fee amount,
            // we mint perps to cover the difference.
            if (balance < feeAmt) {
                _mint(destination, feeAmt - balance);
            }
        } else {
            feeToken_.safeTransfer(destination, feeAmt);
        }
    }

    /// @dev Updates contract store with provided discount.
    function _applyDiscount(IERC20Upgradeable token, uint256 discount) private {
        if (discount > 0) {
            _appliedDiscounts[token] = discount;
        } else {
            delete _appliedDiscounts[token];
        }
        emit DiscountApplied(token, discount);
    }

    /// @dev Updates the mature tranche balance in storage.
    function _updateMatureTrancheBalance(uint256 matureTrancheBalance) private {
        _matureTrancheBalance = matureTrancheBalance;
        emit UpdatedMatureTrancheBalance(matureTrancheBalance);
    }

    /// @dev Checks if the given token pair is a valid rollover.
    ///      * When rolling out mature tranche,
    ///          - expects incoming tranche to be part of the deposit bond
    ///      * When rolling out immature tranches,
    ///          - expects incoming tranche to be part of the deposit bond
    ///          - expects outgoing tranche to NOT be part of the deposit bond, (ie bondIn != bondOut)
    ///          - expects outgoing tranche to be in the reserve
    ///          - expects outgoing bond to NOT be "acceptable" any more
    function _isAcceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut) private view returns (bool) {
        // when rolling out the mature tranche
        if (_isMatureTranche(tokenOut)) {
            return _isBondTranche(trancheIn, _depositBond);
        }

        // when rolling out a normal tranche
        ITranche trancheOut = ITranche(address(tokenOut));
        IBondController bondOut = IBondController(trancheOut.bond());
        return (_isBondTranche(trancheIn, _depositBond) &&
            !_isBondTranche(trancheOut, _depositBond) &&
            _inReserve(trancheOut) &&
            !_isAcceptableForReserve(bondOut));
    }

    /// @dev Checks if the bond's tranches can be accepted into the reserve.
    ///      * Expects the bond to to have the same collateral token as perp.
    ///      * Expects the bond's maturity to be within expected bounds.
    /// @return True if the bond is "acceptable".
    function _isAcceptableForReserve(IBondController bond) private view returns (bool) {
        // NOTE: `timeToMaturity` will be 0 if the bond is past maturity.
        uint256 timeToMaturity = bond.timeToMaturity();
        return (address(_reserveAt(0)) == bond.collateralToken() &&
            timeToMaturity >= minTrancheMaturitySec &&
            timeToMaturity < maxTrancheMaturitySec);
    }

    /// @dev Checks if the given tranche is a valid child of the given parent bond.
    /// @return True if the bond is the tranche's parent.
    function _isBondTranche(ITranche tranche, IBondController bond) private view returns (bool) {
        return (bond.trancheTokenAddresses(tranche) && address(bond) == tranche.bond());
    }

    /// @dev Enforces the total supply cap. To be invoked AFTER the mint operation.
    function _enforceTotalSupplyCap() private view {
        // checks if new total supply is within the max supply cap
        uint256 newSupply = totalSupply();
        if (newSupply > maxSupply) {
            revert ExceededMaxSupply(newSupply, maxSupply);
        }
    }

    /// @dev Enforces the per tranche supply cap. To be invoked AFTER the mint operation.
    function _enforcePerTrancheSupplyCap(ITranche trancheIn) private view {
        // checks if supply minted using the given tranche is within the cap
        if (mintedSupplyPerTranche[trancheIn] > maxMintAmtPerTranche) {
            revert ExceededMaxMintPerTranche(trancheIn, mintedSupplyPerTranche[trancheIn], maxMintAmtPerTranche);
        }
    }

    /// @dev Enforces that supply strictly reduces after the redemption.
    function _enforceSupplyReduction(uint256 prevSupply) private view {
        uint256 newSupply = totalSupply();
        if (newSupply >= prevSupply) {
            revert ExpectedSupplyReduction(newSupply, prevSupply);
        }
    }

    /// @dev Enforces that the percentage of the reserve value is within the target percentage.
    ///      To be invoked AFTER the rollover operation.
    function _enforceMatureValueTarget() private view {
        uint256 matureValue = (_matureTrancheBalance * computePrice(_reserveAt(0)));
        uint256 matureValuePerc = (matureValue * HUNDRED_PERC) / _reserveValue();
        if (matureValuePerc < matureValueTargetPerc) {
            revert BelowMatureValueTargetPerc(matureValuePerc, matureValueTargetPerc);
        }
    }

    /// @dev Counts the number of tokens currently in the reserve.
    function _reserveCount() private view returns (uint256) {
        return _reserves.length();
    }

    /// @dev Fetches the reserve token by index.
    function _reserveAt(uint256 i) private view returns (IERC20Upgradeable) {
        return IERC20Upgradeable(_reserves.at(i));
    }

    /// @dev Checks if the given token is in the reserve.
    function _inReserve(IERC20Upgradeable token) private view returns (bool) {
        return _reserves.contains(address(token));
    }

    /// @dev Calculates the total value of all the tranches in the reserve.
    ///      Value of each reserve tranche is calculated as = (trancheDiscount . trancheBalance) . tranchePrice.
    function _reserveValue() private view returns (uint256) {
        // For the mature tranche we use the "virtual" tranche balance
        uint256 totalVal = (_matureTrancheBalance * computePrice(_reserveAt(0)));

        // For normal tranches we use the tranche token balance
        for (uint256 i = 1; i < _reserveCount(); i++) {
            IERC20Upgradeable token = _reserveAt(i);
            uint256 stdTrancheBalance = _toStdTrancheAmt(_reserveBalance(token), computeDiscount(token));
            totalVal += (stdTrancheBalance * computePrice(token));
        }

        return totalVal;
    }

    /// @dev Checks if the given token is the mature tranche, ie) the underlying collateral token.
    function _isMatureTranche(IERC20Upgradeable token) private view returns (bool) {
        return (token == _reserveAt(0));
    }

    /// @dev Fetches the reserve's token balance.
    function _reserveBalance(IERC20Upgradeable token) private view returns (uint256) {
        return token.balanceOf(reserve());
    }

    /// @dev Calculates the standardized tranche amount for internal book keeping.
    ///      stdTrancheAmt = (trancheAmt * discount).
    function _toStdTrancheAmt(uint256 trancheAmt, uint256 discount) private pure returns (uint256) {
        return ((trancheAmt * discount) / UNIT_DISCOUNT);
    }

    /// @dev Calculates the external tranche amount from the internal standardized tranche amount.
    ///      trancheAmt = stdTrancheAmt / discount.
    function _fromStdTrancheAmt(uint256 stdTrancheAmt, uint256 discount) private pure returns (uint256) {
        return ((stdTrancheAmt * UNIT_DISCOUNT) / discount);
    }
}