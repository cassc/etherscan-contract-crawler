// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

// External
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// libs
import { AbstractSlippage } from "../AbstractSlippage.sol";
import { AbstractVault, IERC20 } from "../../AbstractVault.sol";
import { Convex3CrvAbstractVault } from "./Convex3CrvAbstractVault.sol";
import { LiquidatorAbstractVault } from "../../liquidator/LiquidatorAbstractVault.sol";
import { LiquidatorStreamAbstractVault } from "../../liquidator/LiquidatorStreamAbstractVault.sol";
import { LiquidatorStreamFeeAbstractVault } from "../../liquidator/LiquidatorStreamFeeAbstractVault.sol";
import { VaultManagerRole } from "../../../shared/VaultManagerRole.sol";
import { InitializableToken } from "../../../tokens/InitializableToken.sol";
import { ICurve3Pool } from "../../../peripheral/Curve/ICurve3Pool.sol";
import { ICurveMetapool } from "../../../peripheral/Curve/ICurveMetapool.sol";
import { Curve3CrvMetapoolCalculatorLibrary } from "../../../peripheral/Curve/Curve3CrvMetapoolCalculatorLibrary.sol";

/**
 * @title   Convex Vault for #Pool (3Crv) based Curve Metapools that liquidates CRV and CVX rewards.
 * @notice  ERC-4626 vault that deposits Curve 3Pool LP tokens (3Crv) in a Curve Metapool, eg musd3Crv;
 * deposits the Metapool LP token in Convex; and stakes the Convex LP token, eg cvxmusd3Crv,
 * in Convex for CRV and CVX rewards. The Convex rewards are swapped for a Curve 3Pool token,
 * eg DAI, USDC or USDT, using the Liquidator module and donated back to the vault.
 * On donation back to the vault, the DAI, USDC or USDT is deposited into the underlying Curve Metapool;
 * the Curve Metapool LP token is deposited into the corresponding Convex pool and the Convex LP token staked.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-04-29
 */

contract Convex3CrvLiquidatorVault is
    Convex3CrvAbstractVault,
    LiquidatorStreamFeeAbstractVault,
    Initializable
{
    using SafeERC20 for IERC20;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @notice Token that the liquidator sells CRV and CVX rewards for. This must be a 3Pool asset. ie DAI, USDC or USDT.
    address internal donateToken_;

    event DonateTokenUpdated(address token);

    /**
     * @param _nexus               Address of the Nexus contract that resolves protocol modules and roles..
     * @param _asset               Address of the vault's asset which is Curve's 3Pool LP token (3Crv).
     * @param _data                Initial data for `Convex3CrvAbstractVault` constructor of type `ConstructorData`.
     * @param _streamDuration      Number of seconds the increased asssets per share will be streamed after liquidated rewards are donated back.
     */
    constructor(
        address _nexus,
        address _asset,
        ConstructorData memory _data,
        uint256 _streamDuration
    )
        VaultManagerRole(_nexus)
        AbstractVault(_asset)
        Convex3CrvAbstractVault(_data)
        LiquidatorStreamAbstractVault(_streamDuration)
    {}

    /**
     * @param _name            Name of vault.
     * @param _symbol          Symbol of vault.
     * @param _vaultManager    Trusted account that can perform vault operations. eg rebalance.
     * @param _slippageData    Initial slippage limits.
     * @param _rewardTokens    Address of the reward tokens.
     * @param __donateToken    3Pool token (DAI, USDC or USDT) that CVX and CRV rewards are swapped to by the Liquidator.
     * @param _feeReceiver     Account that receives the performance fee as shares.
     * @param _donationFee     Donation fee scaled to `FEE_SCALE`.
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _vaultManager,
        SlippageData memory _slippageData,
        address[] memory _rewardTokens,
        address __donateToken,
        address _feeReceiver,
        uint256 _donationFee
    ) external initializer {
        // Vault initialization
        VaultManagerRole._initialize(_vaultManager);
        AbstractSlippage._initialize(_slippageData);
        LiquidatorAbstractVault._initialize(_rewardTokens);
        Convex3CrvAbstractVault._initialize();
        LiquidatorStreamFeeAbstractVault._initialize(_feeReceiver, _donationFee);

        // Set the vault's decimals to the same as the metapool's LP token, eg musd3CRV
        uint8 decimals_ = InitializableToken(address(metapoolToken)).decimals();
        InitializableToken._initialize(_name, _symbol, decimals_);

        _setDonateToken(__donateToken);

        // Approve the Curve.fi 3Pool (3Crv) to transfer the 3Pool token
        IERC20(DAI).safeApprove(address(basePool), type(uint256).max);
        IERC20(USDC).safeApprove(address(basePool), type(uint256).max);
        IERC20(USDT).safeApprove(address(basePool), type(uint256).max);
    }

    /**
     * @notice The number of shares after any liquidated shares are burnt.
     * @return shares The vault's total number of shares.
     * @dev If shares are being burnt, the `totalSupply` will decrease in every block.
     * Uses the `LiquidatorStreamAbstractVault` implementation.
     */
    function totalSupply()
        public
        view
        virtual
        override(ERC20, IERC20, LiquidatorStreamAbstractVault)
        returns (uint256 shares)
    {
        shares = LiquidatorStreamAbstractVault.totalSupply();
    }

    /***************************************
                Liquidator Hooks
    ****************************************/

    /**
     * @return token Token that the liquidator needs to swap reward tokens to which must be either DAI, USDC or USDT.
     */
    function _donateToken(address) internal view override returns (address token) {
        token = donateToken_;
    }

    function _beforeCollectRewards() internal virtual override {
        // claim CRV and CVX from Convex
        // also claim any additional rewards if any.
        baseRewardPool.getReward(address(this), true);
    }

    /**
     * @dev Converts donated tokens (DAI, USDC or USDT) to vault assets (3Crv) and shares.
     * Transfers token from donor to vault.
     * Adds the token to the Curve 3Pool to receive the vault asset (3Crv) in exchange.
     * The resulting asset (3Crv) is added to the Curve Metapool.
     * The Curve Metapool LP token, eg mUSD3Crv, is added to the Convex pool and staked.
     */
    function _convertTokens(address token, uint256 amount)
        internal
        virtual
        override
        returns (uint256 shares_, uint256 assets_)
    {
        // Validate token is in 3Pool and scale all amounts up to 18 decimals
        uint256[3] memory basePoolAmounts;
        uint256 scaledUsdAmount;
        if (token == DAI) {
            scaledUsdAmount = amount;
            basePoolAmounts[0] = amount;
        } else if (token == USDC) {
            scaledUsdAmount = amount * 1e12;
            basePoolAmounts[1] = amount;
        } else if (token == USDT) {
            scaledUsdAmount = amount * 1e12;
            basePoolAmounts[2] = amount;
        } else {
            revert("token not in 3Pool");
        }

        // Transfer DAI, USDC or USDT from donor
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Deposit DAI, USDC or USDT and receive Curve.fi 3Pool LP tokens (3Crv).
        ICurve3Pool(basePool).add_liquidity(
            basePoolAmounts,
            0 // slippage protection will be done on the second deposit into the Metapool
        );

        // Slippage and flash loan protection
        // Convert DAI, USDC or USDT to Metapool LP tokens, eg musd3CRV.
        // This method uses the Metapool's virtual price which can not be manipulated with a flash loan.
        uint256 minMetapoolTokens = Curve3CrvMetapoolCalculatorLibrary.convertUsdToMetaLp(
            metapool,
            scaledUsdAmount
        );
        // Then reduce the metapol LP tokens amount by the slippage. eg 10 basis points = 0.1%
        minMetapoolTokens = (minMetapoolTokens * (BASIS_SCALE - depositSlippage)) / BASIS_SCALE;

        // Get vault's asset (3Crv) balance after adding token to Curve's 3Pool.
        assets_ = _asset.balanceOf(address(this));
        // Add asset (3Crv) to metapool with slippage protection.
        uint256 metapoolTokens = ICurveMetapool(metapool).add_liquidity([0, assets_], minMetapoolTokens);

        // Calculate share value of the new assets before depositing the metapool tokens to the Convex pool.
        shares_ = _getSharesFromMetapoolTokens(
            metapoolTokens,
            baseRewardPool.balanceOf(address(this)),
            totalSupply()
        );

        // Deposit Curve.fi Metapool LP token, eg musd3CRV, in Convex pool, eg cvxmusd3CRV, and stake.
        booster.deposit(convexPoolId, metapoolTokens, true);
    }

    /***************************************
     Vault overrides with streamRewards modifier
    ****************************************/

    // As two vaults (Convex3CrvAbstractVault and LiquidatorStreamFeeAbstractVault) are being inheriterd, Solidity needs to know which functions to override.

    /**
     * @notice Mint vault shares to receiver by transferring exact amount of underlying asset tokens (3Crv) from the caller.
     * @param assets The amount of underlying assets (3Crv) to be transferred to the vault.
     * @param receiver The account that the vault shares will be minted to.
     * @return shares The amount of vault shares that were minted.
     * @dev Burns any streamed shares from the last liquidation before depositing.
     */
    function deposit(uint256 assets, address receiver)
        external
        virtual
        override(AbstractVault, LiquidatorStreamAbstractVault)
        whenNotPaused
        streamRewards
        returns (uint256 shares)
    {
        shares = _deposit(assets, receiver);
    }

    /**
     * @notice Mint exact amount of vault shares to the receiver by transferring enough underlying asset tokens (3Crv) from the caller.
     * @param shares The amount of vault shares to be minted.
     * @param receiver The account the vault shares will be minted to.
     * @return assets The amount of underlying assets (3Crv) that were transferred from the caller.
     * @dev Burns any streamed shares from the last liquidation before minting.
     */
    function mint(uint256 shares, address receiver)
        external
        virtual
        override(AbstractVault, LiquidatorStreamAbstractVault)
        whenNotPaused
        streamRewards
        returns (uint256 assets)
    {
        assets = _mint(shares, receiver);
    }

    /**
     * @notice Burns exact amount of vault shares from owner and transfers the underlying asset tokens (3Crv) to the receiver.
     * @param shares The amount of vault shares to be burnt.
     * @param receiver The account the underlying assets will be transferred to.
     * @param owner The account that owns the vault shares to be burnt.
     * @return assets The amount of underlying assets (3Crv) that were transferred to the receiver.
     * @dev Burns any streamed shares from the last liquidation before redeeming.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        external
        virtual
        override(AbstractVault, LiquidatorStreamAbstractVault)
        whenNotPaused
        streamRewards
        returns (uint256 assets)
    {
        assets = _redeem(shares, receiver, owner);
    }

    /**
     * @notice Burns enough vault shares from owner and transfers the exact amount of underlying asset tokens (3Crv) to the receiver.
     * @param assets The amount of underlying assets (3Crv) to be withdrawn from the vault.
     * @param receiver The account that the underlying assets will be transferred to.
     * @param owner Account that owns the vault shares to be burnt.
     * @return shares The amount of vault shares that were burnt.
     * @dev Burns any streamed shares from the last liquidation before withdrawing.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        external
        virtual
        override(AbstractVault, LiquidatorStreamAbstractVault)
        whenNotPaused
        streamRewards
        returns (uint256 shares)
    {
        shares = _withdraw(assets, receiver, owner);
    }

    /***************************************
            Vault preview functions
    ****************************************/

    /// @dev use Convex3CrvAbstractVault implementation.
    function _previewDeposit(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 shares)
    {
        shares = Convex3CrvAbstractVault._previewDeposit(assets);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _previewMint(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 assets)
    {
        assets = Convex3CrvAbstractVault._previewMint(shares);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _previewRedeem(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 assets)
    {
        assets = Convex3CrvAbstractVault._previewRedeem(shares);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _previewWithdraw(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 shares)
    {
        shares = Convex3CrvAbstractVault._previewWithdraw(assets);
    }

    /***************************************
            Internal vault operations
    ****************************************/

    /// @dev use Convex3CrvAbstractVault implementation.
    function _deposit(uint256 assets, address receiver)
        internal
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 shares)
    {
        shares = Convex3CrvAbstractVault._deposit(assets, receiver);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _mint(uint256 shares, address receiver)
        internal
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 assets)
    {
        assets = Convex3CrvAbstractVault._mint(shares, receiver);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual override(AbstractVault, Convex3CrvAbstractVault) returns (uint256 assets) {
        assets = Convex3CrvAbstractVault._redeem(shares, receiver, owner);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal virtual override(AbstractVault, Convex3CrvAbstractVault) returns (uint256 shares) {
        shares = Convex3CrvAbstractVault._withdraw(assets, receiver, owner);
    }

    /***************************************
            Internal vault convertions
    ****************************************/

    /// @dev use Convex3CrvAbstractVault implementation.
    function _convertToAssets(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 assets)
    {
        assets = Convex3CrvAbstractVault._convertToAssets(shares);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _convertToShares(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 shares)
    {
        shares = Convex3CrvAbstractVault._convertToShares(assets);
    }

    /***************************************
                    Vault Admin
    ****************************************/

    /// @dev Sets the token the rewards are swapped for and donated back to the vault.
    function _setDonateToken(address __donateToken) internal {
        require(
            __donateToken == DAI || __donateToken == USDC || __donateToken == USDT,
            "donate token not in 3Pool"
        );
        donateToken_ = __donateToken;

        emit DonateTokenUpdated(__donateToken);
    }

    /**
     * @notice  Vault manager or governor sets the token the rewards are swapped for and donated back to the vault.
     * @param __donateToken a token in the 3Pool (DAI, USDC or USDT).
     */
    function setDonateToken(address __donateToken) external onlyKeeperOrGovernor {
        _setDonateToken(__donateToken);
    }
}