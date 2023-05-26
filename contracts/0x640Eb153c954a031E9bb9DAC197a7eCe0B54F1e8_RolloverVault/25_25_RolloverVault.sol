// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IERC20Upgradeable, IPerpetualTranche, IBondIssuer, IBondController, ITranche } from "../_interfaces/IPerpetualTranche.sol";
import { IVault, UnexpectedAsset, UnauthorizedTransferOut, InsufficientDeployment, DeployedCountOverLimit } from "../_interfaces/IVault.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { BondTranches, TrancheHelpers, BondHelpers } from "../_utils/BondHelpers.sol";

/// @notice Storage array access out of bounds.
error OutOfBounds();

/*
 *  @title RolloverVault
 *
 *  @notice A vault which generates yield (from fees) by performing rollovers on PerpetualTranche (or perp).
 *          The vault takes in AMPL or any other rebasing collateral as the "underlying" asset.
 *
 *          Vault strategy:
 *              1) deploy: The vault deposits the underlying asset into perp's current deposit bond
 *                 to get tranche tokens in return, it then swaps these fresh tranche tokens for
 *                 older tranche tokens (ones mature or approaching maturity) from perp.
 *                 system through a rollover operation and earns an income in perp tokens.
 *              2) recover: The vault redeems tranches for the underlying asset.
 *                 NOTE: It performs both mature and immature redemption. Read more: https://bit.ly/3tuN6OC
 *
 *
 */
contract RolloverVault is
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IVault
{
    // data handling
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using BondHelpers for IBondController;
    using TrancheHelpers for ITranche;

    // ERC20 operations
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // math
    using MathUpgradeable for uint256;

    //-------------------------------------------------------------------------
    // Events

    /// @notice Emits the vault asset's token balance that's recorded after a change.
    /// @param token Address of token.
    /// @param balance The recorded ERC-20 balance of the token.
    event AssetSynced(IERC20Upgradeable token, uint256 balance);

    //-------------------------------------------------------------------------
    // Constants
    uint8 public constant PERC_DECIMALS = 6;
    uint256 public constant UNIT_PERC = 10**PERC_DECIMALS;
    uint256 public constant HUNDRED_PERC = 100 * UNIT_PERC;

    /// @dev Initial exchange rate between the underlying asset and notes.
    uint256 private constant INITIAL_RATE = 10**6;

    /// @dev Values should line up as is in the perp contract.
    uint8 private constant PERP_PRICE_DECIMALS = 8;
    uint256 private constant PERP_UNIT_PRICE = (10**PERP_PRICE_DECIMALS);

    /// @dev The maximum number of deployed assets that can be held in this vault at any given time.
    uint256 public constant MAX_DEPLOYED_COUNT = 47;

    //--------------------------------------------------------------------------
    // ASSETS
    //
    // The vault's assets are represented by a master list of ERC-20 tokens
    //      => { [underlying] U _deployed U _earned }
    //
    // In the case of this vault, the "earned" assets are the perp tokens themselves.
    // The reward (or yield) for performing rollovers is paid out in perp tokens.

    /// @notice The ERC20 token that can be deposited into this vault.
    IERC20Upgradeable public underlying;

    /// @dev The set of the intermediate ERC-20 tokens when the underlying asset has been put to use.
    ///      In the case of this vault, they represent the tranche tokens held before maturity.
    EnumerableSetUpgradeable.AddressSet private _deployed;

    //-------------------------------------------------------------------------
    // Storage

    /// @notice Minimum amount of underlying assets that must be deployed, for a deploy operation to succeed.
    /// @dev The deployment transaction reverts, if the vaults does not have sufficient underlying tokens
    ///      to cover the minimum deployment amount.
    uint256 public minDeploymentAmt;

    /// @notice The perpetual token on which rollovers are performed.
    IPerpetualTranche public perp;

    //--------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Contract state initialization.
    /// @param name ERC-20 Name of the vault token.
    /// @param symbol ERC-20 Symbol of the vault token.
    /// @param perp_ ERC-20 address of the perpetual tranche rolled over.
    function init(
        string memory name,
        string memory symbol,
        IPerpetualTranche perp_
    ) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        underlying = perp_.collateral();
        _syncAsset(underlying);

        perp = perp_;
    }

    //--------------------------------------------------------------------------
    // ADMIN only methods

    /// @notice Pauses deposits, withdrawals and vault operations.
    /// @dev NOTE: ERC-20 functions, like transfers will always remain operational.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses deposits, withdrawals and vault operations.
    /// @dev NOTE: ERC-20 functions, like transfers will always remain operational.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Updates the minimum deployment amount.
    /// @param minDeploymentAmt_ The new minimum deployment amount, denominated in underlying tokens.
    function updateMinDeploymentAmt(uint256 minDeploymentAmt_) external onlyOwner {
        minDeploymentAmt = minDeploymentAmt_;
    }

    /// @notice Transfers a non-vault token out of the contract, which may have been added accidentally.
    /// @param token The token address.
    /// @param to The destination address.
    /// @param amount The amount of tokens to be transferred.
    function transferERC20(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (isVaultAsset(token)) {
            revert UnauthorizedTransferOut(token);
        }
        token.safeTransfer(to, amount);
    }

    //--------------------------------------------------------------------------
    // External & Public write methods

    /// @inheritdoc IVault
    /// @dev Simply batches the `recover` and `deploy` functions. Reverts if there are no funds to deploy.
    function recoverAndRedeploy() external override {
        recover();
        deploy();
    }

    /// @inheritdoc IVault
    /// @dev Its safer to call `recover` before `deploy` so the full available balance can be deployed.
    ///      Reverts if no funds are rolled over or if the minimum deployment threshold is not reached.
    function deploy() public override nonReentrant whenNotPaused {
        (uint256 deployedAmt, BondTranches memory bt) = _tranche(perp.getDepositBond());
        uint256 perpsRolledOver = _rollover(perp, bt);
        // NOTE: The following enforces that we only tranche the underlying if it can immediately be used for rotations.
        if (deployedAmt <= minDeploymentAmt || perpsRolledOver <= 0) {
            revert InsufficientDeployment();
        }
    }

    /// @inheritdoc IVault
    function recover() public override nonReentrant whenNotPaused {
        uint256 deployedCount_ = _deployed.length();
        if (deployedCount_ <= 0) {
            return;
        }

        // execute redemption on each deployed asset
        for (uint256 i = 0; i < deployedCount_; i++) {
            ITranche tranche = ITranche(_deployed.at(i));
            uint256 trancheBalance = tranche.balanceOf(address(this));

            // if the vault has no tranche balance,
            // we update our internal book-keeping and continue to the next one.
            if (trancheBalance <= 0) {
                continue;
            }

            // get the parent bond
            IBondController bond = IBondController(tranche.bond());

            // if bond has matured, redeem the tranche token
            if (bond.secondsToMaturity() <= 0) {
                // execute redemption
                _execMatureTrancheRedemption(bond, tranche, trancheBalance);
            }
            // if not redeem using proportional balances
            // redeems this tranche and it's siblings if the vault holds balances.
            // NOTE: For gas optimization, we perform this operation only once
            // ie) when we encounter the most-senior tranche.
            else if (tranche == bond.trancheAt(0)) {
                // execute redemption
                _execImmatureTrancheRedemption(bond);
            }
        }

        // sync deployed tranches
        // NOTE: We traverse the deployed set in the reverse order
        //       as deletions involve swapping the deleted element to the
        //       end of the set and removing the last element.
        for (uint256 i = deployedCount_; i > 0; i--) {
            _syncAndRemoveDeployedAsset(IERC20Upgradeable(_deployed.at(i - 1)));
        }

        // sync underlying
        _syncAsset(underlying);
    }

    /// @inheritdoc IVault
    /// @dev Reverts when attempting to recover a tranche which is not part of the deployed list.
    ///      In the case of immature redemption, this method will recover other sibling tranches as well.
    function recover(IERC20Upgradeable token) external override nonReentrant whenNotPaused {
        if (!_deployed.contains(address(token))) {
            revert UnexpectedAsset(token);
        }

        ITranche tranche = ITranche(address(token));
        uint256 trancheBalance = tranche.balanceOf(address(this));

        // if the vault has no tranche balance,
        // we update our internal book-keeping and return.
        if (trancheBalance <= 0) {
            _syncAndRemoveDeployedAsset(tranche);
            return;
        }

        // get the parent bond
        IBondController bond = IBondController(tranche.bond());

        // if bond has matured, redeem the tranche token
        if (bond.secondsToMaturity() <= 0) {
            // execute redemption
            _execMatureTrancheRedemption(bond, tranche, trancheBalance);

            // sync deployed asset
            _syncAndRemoveDeployedAsset(tranche);
        }
        // if not redeem using proportional balances
        // redeems this tranche and it's siblings if the vault holds balances.
        else {
            // execute redemption
            BondTranches memory bt = _execImmatureTrancheRedemption(bond);

            // sync deployed asset, ie current tranche and all its siblings.
            for (uint8 j = 0; j < bt.tranches.length; j++) {
                _syncAndRemoveDeployedAsset(bt.tranches[j]);
            }
        }

        // sync underlying
        _syncAsset(underlying);
    }

    /// @inheritdoc IVault
    function deposit(uint256 amount) external override nonReentrant whenNotPaused returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 notes = (totalSupply_ > 0) ? totalSupply_.mulDiv(amount, getTVL()) : (amount * INITIAL_RATE);

        underlying.safeTransferFrom(_msgSender(), address(this), amount);
        _syncAsset(underlying);

        _mint(_msgSender(), notes);
        return notes;
    }

    /// @inheritdoc IVault
    function redeem(uint256 notes) external override nonReentrant whenNotPaused returns (IVault.TokenAmount[] memory) {
        uint256 totalNotes = totalSupply();
        uint256 deployedCount_ = _deployed.length();
        uint256 assetCount = 2 + deployedCount_;

        // aggregating vault assets to be redeemed
        IVault.TokenAmount[] memory redemptions = new IVault.TokenAmount[](assetCount);
        redemptions[0].token = underlying;
        for (uint256 i = 0; i < deployedCount_; i++) {
            redemptions[i + 1].token = IERC20Upgradeable(_deployed.at(i));
        }
        redemptions[deployedCount_ + 1].token = IERC20Upgradeable(perp);

        // burn notes
        _burn(_msgSender(), notes);

        // calculating amounts and transferring assets out proportionally
        for (uint256 i = 0; i < assetCount; i++) {
            redemptions[i].amount = redemptions[i].token.balanceOf(address(this)).mulDiv(notes, totalNotes);
            redemptions[i].token.safeTransfer(_msgSender(), redemptions[i].amount);
            _syncAsset(redemptions[i].token);
        }

        return redemptions;
    }

    /// @inheritdoc IVault
    /// @dev The total value is denominated in the underlying asset.
    function getTVL() public override returns (uint256) {
        uint256 totalValue = 0;

        // The underlying balance
        totalValue += underlying.balanceOf(address(this));

        // The deployed asset value denominated in the underlying
        for (uint256 i = 0; i < _deployed.length(); i++) {
            ITranche tranche = ITranche(_deployed.at(i));
            uint256 trancheBalance = tranche.balanceOf(address(this));
            if (trancheBalance > 0) {
                (uint256 collateralBalance, uint256 trancheSupply) = tranche.getTrancheCollateralization();
                totalValue += collateralBalance.mulDiv(trancheBalance, trancheSupply);
            }
        }

        // The earned asset (perp token) value denominated in the underlying
        uint256 perpBalance = perp.balanceOf(address(this));
        if (perpBalance > 0) {
            // The "earned" asset is assumed to be the perp token.
            // Perp tokens are assumed to have the same denomination as the underlying
            totalValue += perpBalance.mulDiv(IPerpetualTranche(address(perp)).getAvgPrice(), PERP_UNIT_PRICE);
        }

        return totalValue;
    }

    /// @inheritdoc IVault
    /// @dev The asset value is denominated in the underlying asset.
    function getVaultAssetValue(IERC20Upgradeable token) external override returns (uint256) {
        // Underlying asset
        if (token == underlying) {
            return token.balanceOf(address(this));
        }
        // Deployed asset
        else if (_deployed.contains(address(token))) {
            (uint256 collateralBalance, uint256 trancheSupply) = ITranche(address(token)).getTrancheCollateralization();
            return collateralBalance.mulDiv(token.balanceOf(address(this)), trancheSupply);
        }
        // Earned asset
        else if (address(token) == address(perp)) {
            return (
                token.balanceOf(address(this)).mulDiv(IPerpetualTranche(address(perp)).getAvgPrice(), PERP_UNIT_PRICE)
            );
        }

        // Not a vault asset, so returning zero
        return 0;
    }

    //--------------------------------------------------------------------------
    // External & Public read methods

    /// @inheritdoc IVault
    function vaultAssetBalance(IERC20Upgradeable token) external view override returns (uint256) {
        return isVaultAsset(token) ? token.balanceOf(address(this)) : 0;
    }

    /// @inheritdoc IVault
    function deployedCount() external view override returns (uint256) {
        return _deployed.length();
    }

    /// @inheritdoc IVault
    function deployedAt(uint256 i) external view override returns (IERC20Upgradeable) {
        return IERC20Upgradeable(_deployed.at(i));
    }

    /// @inheritdoc IVault
    function earnedCount() external pure returns (uint256) {
        return 1;
    }

    /// @inheritdoc IVault
    function earnedAt(uint256 i) external view override returns (IERC20Upgradeable) {
        if (i > 0) {
            revert OutOfBounds();
        }
        return IERC20Upgradeable(perp);
    }

    /// @inheritdoc IVault
    function isVaultAsset(IERC20Upgradeable token) public view override returns (bool) {
        return (token == underlying) || _deployed.contains(address(token)) || (address(token) == address(perp));
    }

    //--------------------------------------------------------------------------
    // Private write methods

    /// @dev Deposits underlying balance into the provided bond and receives tranche tokens in return.
    ///      And performs some book-keeping to keep track of the vault's assets.
    /// @return balance The amount of underlying assets tranched.
    /// @return bt The given bonds tranche data.
    function _tranche(IBondController bond) private returns (uint256, BondTranches memory) {
        // Get bond's tranche data
        BondTranches memory bt = bond.getTranches();

        // Get underlying balance
        uint256 balance = underlying.balanceOf(address(this));

        // Skip if balance is zero
        if (balance <= 0) {
            return (0, bt);
        }

        // balance is tranched
        _checkAndApproveMax(underlying, address(bond), balance);
        bond.deposit(balance);

        // sync holdings
        for (uint8 i = 0; i < bt.tranches.length; i++) {
            _syncAndAddDeployedAsset(bt.tranches[i]);
        }
        _syncAsset(underlying);

        return (balance, bt);
    }

    /// @dev Rolls over freshly tranched tokens from the given bond for older tranches (close to maturity) from perp.
    ///      And performs some book-keeping to keep track of the vault's assets.
    /// @return The amount of perps rolled over.
    function _rollover(IPerpetualTranche perp_, BondTranches memory bt) private returns (uint256) {
        // NOTE: The first element of the list is the mature tranche,
        //       there after the list is NOT ordered by maturity.
        IERC20Upgradeable[] memory rolloverTokens = perp_.getReserveTokensUpForRollover();

        // Batch rollover
        uint256 totalPerpRolledOver = 0;
        uint8 vaultTrancheIdx = 0;
        uint256 perpTokenIdx = 0;

        // We pair tranche tokens held by the vault with tranche tokens held by perp,
        // And execute the rollover and continue to the next token with a usable balance.
        while (vaultTrancheIdx < bt.tranches.length && perpTokenIdx < rolloverTokens.length) {
            // trancheIntoPerp refers to the tranche going into perp from the vault
            ITranche trancheIntoPerp = bt.tranches[vaultTrancheIdx];

            // tokenOutOfPerp is the reserve token coming out of perp into the vault
            IERC20Upgradeable tokenOutOfPerp = rolloverTokens[perpTokenIdx];

            // compute available token out
            uint256 tokenOutAmtAvailable = address(tokenOutOfPerp) != address(0)
                ? tokenOutOfPerp.balanceOf(perp_.reserve())
                : 0;

            // trancheIntoPerp tokens are NOT exhausted but tokenOutOfPerp is exhausted
            if (tokenOutAmtAvailable <= 0) {
                // Rollover is a no-op, so skipping to next tokenOutOfPerp
                ++perpTokenIdx;
                continue;
            }

            // Compute available tranche in
            uint256 trancheInAmtAvailable = trancheIntoPerp.balanceOf(address(this));

            // trancheInAmtAvailable is exhausted
            if (trancheInAmtAvailable <= 0) {
                // Rollover is a no-op, so skipping to next trancheIntoPerp
                ++vaultTrancheIdx;
                continue;
            }

            // Preview rollover
            IPerpetualTranche.RolloverPreview memory rd = perp_.computeRolloverAmt(
                trancheIntoPerp,
                tokenOutOfPerp,
                trancheInAmtAvailable,
                tokenOutAmtAvailable
            );

            // trancheIntoPerp isn't accepted by perp, likely because it's yield=0, refer perp docs for more info
            if (rd.perpRolloverAmt <= 0) {
                // Rollover is a no-op, so skipping to next trancheIntoPerp
                ++vaultTrancheIdx;
                continue;
            }

            // Perform rollover
            _checkAndApproveMax(trancheIntoPerp, address(perp_), trancheInAmtAvailable);
            perp_.rollover(trancheIntoPerp, tokenOutOfPerp, trancheInAmtAvailable);

            // sync deployed asset sent to perp
            _syncAndRemoveDeployedAsset(trancheIntoPerp);

            // skip insertion into the deployed list the case of the mature tranche, ie underlying
            if (tokenOutOfPerp != underlying) {
                // sync deployed asset retrieved from perp
                _syncAndAddDeployedAsset(tokenOutOfPerp);
            }

            // keep track of total amount rolled over
            totalPerpRolledOver += rd.perpRolloverAmt;
        }

        // sync underlying and earned (ie perp)
        _syncAsset(underlying);
        _syncAsset(perp_);

        return totalPerpRolledOver;
    }

    /// @dev Low level method that redeems the given mature tranche for the underlying asset.
    ///      It interacts with the button-wood bond contract.
    ///      This function should NOT be called directly, use `recover()` or `recover(tranche)`
    ///      which wrap this function with the internal book-keeping necessary,
    ///      to keep track of the vault's assets.
    function _execMatureTrancheRedemption(
        IBondController bond,
        ITranche tranche,
        uint256 amount
    ) private {
        if (!bond.isMature()) {
            bond.mature();
        }
        bond.redeemMature(address(tranche), amount);
    }

    /// @dev Low level method that redeems the given tranche for the underlying asset, before maturity.
    ///      If the vault holds sibling tranches with proportional balances, those will also get redeemed.
    ///      It interacts with the button-wood bond contract.
    ///      This function should NOT be called directly, use `recover()` or `recover(tranche)`
    ///      which wrap this function with the internal book-keeping necessary,
    ///      to keep track of the vault's assets.
    function _execImmatureTrancheRedemption(IBondController bond) private returns (BondTranches memory bt) {
        uint256[] memory trancheAmts;
        (bt, trancheAmts) = bond.computeRedeemableTrancheAmounts(address(this));

        // NOTE: It is guaranteed that if one tranche amount is zero, all amounts are zeros.
        if (trancheAmts[0] > 0) {
            bond.redeem(trancheAmts);
        }

        return bt;
    }

    /// @dev Syncs balance and adds the given asset into the deployed list if the vault has a balance.
    function _syncAndAddDeployedAsset(IERC20Upgradeable token) private {
        uint256 balance = token.balanceOf(address(this));
        emit AssetSynced(token, balance);

        if (balance > 0 && !_deployed.contains(address(token))) {
            // Inserts new token into the deployed assets list.
            _deployed.add(address(token));
            if (_deployed.length() > MAX_DEPLOYED_COUNT) {
                revert DeployedCountOverLimit();
            }
        }
    }

    /// @dev Syncs balance and removes the given asset from the deployed list if the vault has no balance.
    function _syncAndRemoveDeployedAsset(IERC20Upgradeable token) private {
        uint256 balance = token.balanceOf(address(this));
        emit AssetSynced(token, balance);

        if (balance <= 0 && _deployed.contains(address(token))) {
            // Removes token into the deployed assets list.
            _deployed.remove(address(token));
        }
    }

    /// @dev Logs the token balance held by the vault.
    function _syncAsset(IERC20Upgradeable token) private {
        uint256 balance = token.balanceOf(address(this));
        emit AssetSynced(token, balance);
    }

    /// @dev Checks if the spender has sufficient allowance. If not, approves the maximum possible amount.
    function _checkAndApproveMax(
        IERC20Upgradeable token,
        address spender,
        uint256 amount
    ) private {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            token.safeApprove(spender, 0);
            token.safeApprove(spender, type(uint256).max);
        }
    }
}