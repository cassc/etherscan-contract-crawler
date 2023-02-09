// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "../../interfaces/ICodex.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IMoneta} from "../../interfaces/IMoneta.sol";
import {IFIAT} from "../../interfaces/IFIAT.sol";
import {IFlash, ICreditFlashBorrower, IERC3156FlashBorrower} from "../../interfaces/IFlash.sol";
import {IPublican} from "../../interfaces/IPublican.sol";
import {WAD, toInt256, add, sub, wmul, wdiv, sub} from "../../core/utils/Math.sol";

import {IBalancerVault, IAsset} from "../helper/ConvergentCurvePoolHelper.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title LeverActions
/// @notice Base lever actions contract which meant to be inherited from from protocol specific implementations.
/// This contract is only compatible with FIAT pairings on Balancer and supports swapping between FIAT and any other
/// asset that's available through the Balancer Router.
abstract contract LeverActions {
    /// ======== Custom Errors ======== ///

    error LeverActions__exitMoneta_zeroUserAddress();
    error LeverActions__buyFIATExactOut_pathLengthMismatch();
    error LeverActions__buyFIATExactOut_wrongFIATAddress();
    error LeverActions__sellFIATExactIn_pathLengthMismatch();
    error LeverActions__sellFIATExactIn_wrongFIATAddress();
    error LeverActions__underlierToFIAT_pathLengthMismatch();
    error LeverActions__getBuyFIATSwapParams_pathLengthMismatch();
    error LeverActions__getSellFIATSwapParams_pathLengthMismatch();

    /// ======== Storage ======== ///

    struct FlashLoanData {
        // Action to perform in the flash loan callback [1 - buy, 2 - sell, 3 - redeem]
        uint256 action;
        // Data corresponding to the action
        bytes data;
    }

    struct SellFIATSwapParams {
        // Balancer BatchSwapStep array (see Balancer docs for more info)
        // Items have to be in swap order (e.g. [FIAT -> DAI, DAI -> USDT])
        // E.g. [(FIAT -> DAI: assetInIndex: 0, assetOutIndex: 1), (DAI -> USDT: assetIndexIn: 1, assetIndexOut: 2)]
        IBalancerVault.BatchSwapStep[] swaps;
        // Balancer IAssets array (see Balancer docs for more info)
        // Items have to be in swap order (e.g. [FIAT, DAI, USDT])
        IAsset[] assets;
        // Balancer Limits array (see Balancer docs for more info)
        // Items have to be in swap order (e.g. [1 FIAT, 0 DAI, -1 USDT])
        // Input amount limits have to be positive, output amount limits have to be negative
        int256[] limits;
        // Timestamp at which the swap order expires [seconds]
        uint256 deadline;
    }

    struct BuyFIATSwapParams {
        // Balancer BatchSwapStep array (see Balancer docs for more info)
        // Items have to be in swap order following Balancer docs (e.g. [DAI -> FIAT, USDT -> DAI])
        // E.g. [(DAI -> FIAT: assetInIndex: 1, assetOutIndex: 2), (USDT -> DAI: assetIndexIn: 0, assetIndexOut: 1)]
        IBalancerVault.BatchSwapStep[] swaps;
        // Balancer IAssets array (see Balancer docs for more info)
        // Items have to be in swap order (e.g. [USDT, DAI, FIAT])
        IAsset[] assets;
        // Balancer Limits array (see Balancer docs for more info)
        // Items have to be in swap order (e.g. [1 USDT, 0 DAI, -1 FIAT])
        // Input amount limits have to be positive, output amount limits have to be negative
        int256[] limits;
        // Timestamp at which the swap order expires [seconds]
        uint256 deadline;
    }

    /// @notice Codex
    ICodex public immutable codex;
    /// @notice FIAT token
    IFIAT public immutable fiat;
    /// @notice Flash
    IFlash public immutable flash;
    /// @notice Moneta
    IMoneta public immutable moneta;
    /// @notice Publican
    IPublican public immutable publican;

    address internal immutable self = address(this);

    // FIAT Balancer Pool
    bytes32 public immutable fiatPoolId;
    address public immutable fiatBalancerVault;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    bytes32 public constant CALLBACK_SUCCESS_CREDIT = keccak256("CreditFlashBorrower.onCreditFlashLoan");

    constructor(
        address codex_,
        address fiat_,
        address flash_,
        address moneta_,
        address publican_,
        bytes32 fiatPoolId_,
        address fiatBalancerVault_
    ) {
        codex = ICodex(codex_);
        fiat = IFIAT(fiat_);
        flash = IFlash(flash_);
        moneta = IMoneta(moneta_);
        publican = IPublican(publican_);
        fiatPoolId = fiatPoolId_;
        fiatBalancerVault = fiatBalancerVault_;

        (address[] memory tokens, , ) = IBalancerVault(fiatBalancerVault_).getPoolTokens(fiatPoolId);
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(fiatBalancerVault_, type(uint256).max);
        }

        fiat.approve(moneta_, type(uint256).max);
    }

    /// @notice Sets `amount` as the allowance of `spender` over the UserProxy's FIAT
    /// @param spender Address of the spender
    /// @param amount Amount of tokens to approve [wad]
    function approveFIAT(address spender, uint256 amount) external {
        fiat.approve(spender, amount);
    }

    /// @dev Redeems FIAT for internal credit
    /// @param to Address of the recipient
    /// @param amount Amount of FIAT to exit [wad]
    function exitMoneta(address to, uint256 amount) public {
        if (to == address(0)) revert LeverActions__exitMoneta_zeroUserAddress();

        // proxy needs to delegate ability to transfer internal credit on its behalf to Moneta first
        if (codex.delegates(address(this), address(moneta)) != 1) codex.grantDelegate(address(moneta));

        moneta.exit(to, amount);
    }

    /// @dev The user needs to previously call approveFIAT with the address of Moneta as the spender
    /// @param from Address of the account which provides FIAT
    /// @param amount Amount of FIAT to enter [wad]
    function enterMoneta(address from, uint256 amount) public {
        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) fiat.transferFrom(from, address(this), amount);

        moneta.enter(address(this), amount);
    }

    /// @notice Deposits `amount` of `token` with `tokenId` from `from` into the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function enterVault(
        address vault,
        address token,
        uint256 tokenId,
        address from,
        uint256 amount
    ) public virtual;

    /// @notice Withdraws `amount` of `token` with `tokenId` to `to` from the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function exitVault(
        address vault,
        address token,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual;

    function addCollateralAndDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        address creditor,
        uint256 addCollateral,
        uint256 addDebt
    ) public {
        // update the interest rate accumulator in Codex for the vault
        if (addDebt != 0) publican.collect(vault);

        // transfer tokens to be used as collateral into Vault
        enterVault(vault, token, tokenId, collateralizer, wmul(uint256(addCollateral), IVault(vault).tokenScale()));

        // compute normal debt and compensate for precision error caused by wdiv
        (, uint256 rate, , ) = codex.vaults(vault);
        uint256 deltaNormalDebt = wdiv(addDebt, rate);
        if (wmul(deltaNormalDebt, rate) < addDebt) deltaNormalDebt = add(deltaNormalDebt, uint256(1));

        // update collateral and debt balances
        codex.modifyCollateralAndDebt(
            vault,
            tokenId,
            position,
            address(this),
            address(this),
            toInt256(addCollateral),
            toInt256(deltaNormalDebt)
        );

        // redeem newly generated internal credit for FIAT
        exitMoneta(creditor, addDebt);
    }

    function subCollateralAndDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        uint256 subCollateral,
        uint256 subNormalDebt
    ) public {
        // update collateral and debt balances
        codex.modifyCollateralAndDebt(
            vault,
            tokenId,
            position,
            address(this),
            address(this),
            -toInt256(subCollateral),
            -toInt256(subNormalDebt)
        );

        // withdraw tokens not used as collateral anymore from Vault
        exitVault(vault, token, tokenId, collateralizer, wmul(subCollateral, IVault(vault).tokenScale()));
    }

    // @notice Use `buildSellFIATSwapParams` to populate `SellFIATSwapParams`
    function _sellFIATExactIn(SellFIATSwapParams memory params, uint256 exactAmountIn) internal returns (uint256) {
        if (params.swaps.length != sub(params.assets.length, uint256(1)))
            revert LeverActions__sellFIATExactIn_pathLengthMismatch();
        if (address(params.assets[0]) != address(fiat))
            revert LeverActions__sellFIATExactIn_wrongFIATAddress();

        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
            address(this), false, payable(address(this)), false
        );
       
        // set the exact amount of FIAT to swap
        params.swaps[0].amount = exactAmountIn;
        params.limits[0] = toInt256(exactAmountIn);

        // return the absolute of the last swap delta for the underlier
        return abs(IBalancerVault(fiatBalancerVault).batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, params.swaps, params.assets, funds, params.limits, params.deadline
        )[sub(params.assets.length, uint256(1))]);
    }

    // @notice Use `buildBuyFIATSwapParams` to populate `BuyFIATSwapParams`
    function _buyFIATExactOut(BuyFIATSwapParams memory params, uint256 exactAmountOut) internal returns (uint256) {
        if (params.swaps.length != sub(params.assets.length, uint256(1)))
            revert LeverActions__buyFIATExactOut_pathLengthMismatch();
        if (address(params.assets[sub(params.assets.length, uint256(1))]) != address(fiat))
            revert LeverActions__buyFIATExactOut_wrongFIATAddress();

        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
            address(this), false, payable(address(this)), false
        );
       
        // set the exact amount of FIAT to receive
        params.swaps[0].amount = exactAmountOut;
    
        // return the absolute of the first swap delta for the underlier
        return abs(IBalancerVault(fiatBalancerVault).batchSwap(
            IBalancerVault.SwapKind.GIVEN_OUT, params.swaps, params.assets, funds, params.limits, params.deadline
        )[0]);
    }

    /// ======== FIAT / Underlier Swap Off-Chain Helpers ======== ///

    /// @notice Returns an amount of underliers for a given amount of FIAT
    /// @dev This method should be exclusively called off-chain for estimation.
    ///      `pathPoolIds` and `pathAssetsOut` must have the same length and must be ordered from FIAT to the underlier.
    /// @param pathPoolIds Balancer PoolIds for every step of the swap from FIAT to the underlier
    /// @param pathAssetsOut Assets to be swapped at every step from FIAT to the underlier (excluding FIAT)
    /// @param fiatAmount Amount of FIAT [wad]
    /// @return underlierAmount Amount of underlier [underlierScale]
    function fiatToUnderlier(
        bytes32[] calldata pathPoolIds, address[] calldata pathAssetsOut, uint256 fiatAmount
    ) external returns (uint256) {
        SellFIATSwapParams memory params = buildSellFIATSwapParams(
            pathPoolIds, pathAssetsOut, 0, type(uint256).max
        );
        params.swaps[0].amount = fiatAmount;
        IBalancerVault.FundManagement memory funds;
        return abs(IBalancerVault(fiatBalancerVault).queryBatchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, params.swaps, params.assets, funds
        )[sub(params.assets.length, uint256(1))]);
    }
    
    /// @notice Returns the required input amount of underliers for a given amount of FIAT to receive in exchange
    /// @dev This method should be exclusively called off-chain for estimation.
    ///      `pathPoolIds` and `pathAssetsIn` must have the same length and be ordered from underlier to FIAT.
    /// @param pathPoolIds Balancer PoolIds for every step of the swap from underlier to FIAT
    /// @param pathAssetsIn Assets to be swapped at every step from underlier to FIAT (excluding FIAT)
    /// @param fiatAmount Amount of FIAT to swap [wad]
    /// @return underlierAmount Amount of underlier [underlierScale]
    function fiatForUnderlier(
        bytes32[] calldata pathPoolIds, address[] calldata pathAssetsIn, uint256 fiatAmount
    ) external returns (uint256) {
        BuyFIATSwapParams memory params = buildBuyFIATSwapParams(
            pathPoolIds, pathAssetsIn, uint256(type(int256).max), type(uint256).max
        );
        params.swaps[0].amount = fiatAmount;
        IBalancerVault.FundManagement memory funds;
        return abs(IBalancerVault(fiatBalancerVault).queryBatchSwap(
            IBalancerVault.SwapKind.GIVEN_OUT, params.swaps, params.assets, funds
        )[0]);
    }

    /// @notice Returns an amount of FIAT for a given amount of underlier
    /// @dev This method should be exclusively called off-chain for estimation.
    ///      `pathPoolIds` and `pathAssetsIn` must have the same length and be ordered from underlier to FIAT.
    /// @param pathPoolIds Balancer PoolIds for every step of the swap from the underlier to FIAT
    /// @param pathAssetsIn Assets to be swapped at every step from the underlier to FIAT (excluding FIAT)
    /// @param underlierAmount Amount of underlier [underlierScale]
    /// @return fiatAmount Amount of FIAT [wad]
    function underlierToFIAT(
        bytes32[] calldata pathPoolIds, address[] calldata pathAssetsIn, uint256 underlierAmount
    ) external returns (uint256) {
        if (pathPoolIds.length != pathAssetsIn.length) revert LeverActions__underlierToFIAT_pathLengthMismatch();
        uint256 pathLength = pathPoolIds.length;
        
        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](pathLength);
        IAsset[] memory assets = new IAsset[](add(pathLength, uint256(1))); // number of assets = number of swaps + 1
        assets[sub(assets.length, uint256(1))] = IAsset(address(fiat));

        for (uint256 i = 0; i < pathLength;) {
            uint256 nextAssetIndex;
            unchecked { nextAssetIndex = i + 1; }
            IBalancerVault.BatchSwapStep memory swap = IBalancerVault.BatchSwapStep(
                pathPoolIds[i], i, nextAssetIndex, 0, new bytes(0)
            );
            swaps[i] = swap;
            assets[i] = IAsset(address(pathAssetsIn[i]));
            i = nextAssetIndex;
        }

        swaps[0].amount = underlierAmount;
        IBalancerVault.FundManagement memory funds;
        return abs(IBalancerVault(fiatBalancerVault).queryBatchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, swaps, assets, funds
        )[sub(assets.length, uint256(1))]);
    }

    /// @notice Populates the SellFIATSwapParams struct used in the `_sellFIATExactIn` method
    /// @dev This method should be exclusively called off-chain for estimation.
    ///      `pathPoolIds` and `pathAssetsOut` must have the same length and be ordered from FIAT to underlier.
    /// @param pathPoolIds Balancer PoolIds for every step of the swap from FIAT to underlier
    /// @param pathAssetsOut Assets to be swapped at every step from FIAT to underlier (excluding FIAT)
    /// @param minUnderliersOut Min. amount of underlier to receive [underlierScale]
    /// @param deadline Timestamp after which the trade is no more valid [s]
    /// @return sellFIATSwapParams SellFIATSwapParams struct
    function buildSellFIATSwapParams(
        bytes32[] calldata pathPoolIds, address[] calldata pathAssetsOut, uint256 minUnderliersOut, uint256 deadline
    ) public view returns(SellFIATSwapParams memory) {
        if (pathPoolIds.length != pathAssetsOut.length) revert LeverActions__getSellFIATSwapParams_pathLengthMismatch();
        uint256 pathLength = pathPoolIds.length;
        
        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](pathLength);
        IAsset[] memory assets = new IAsset[](add(pathLength, uint256(1))); // number of assets = number of swaps + 1
        int256[] memory limits = new int256[](add(pathLength, uint256(1))); // for each asset has an associated limit
        assets[0] = IAsset(address(fiat));
        limits[pathLength] = -toInt256(minUnderliersOut);

        for (uint256 i = 0; i < pathLength;) {
            uint256 nextAssetIndex;
            unchecked { nextAssetIndex = i + 1; }
            IBalancerVault.BatchSwapStep memory swap = IBalancerVault.BatchSwapStep(
                pathPoolIds[i], i, nextAssetIndex, 0, new bytes(0)
            );
            swaps[i] = swap;
            assets[nextAssetIndex] = IAsset(address(pathAssetsOut[i]));
            i = nextAssetIndex;
        }

        return SellFIATSwapParams(swaps, assets, limits, deadline);
    }

    /// @notice Populates the BuyFIATSwapParams struct used in the `_buyFIATExactOut` method
    /// @dev This method should be exclusively called off-chain for estimation.
    ///      `pathPoolIds` and `pathAssetsIn` must have the same length and be ordered from underlier to FIAT.
    /// @param pathPoolIds Balancer PoolIds for every step of the swap from underlier to FIAT
    /// @param pathAssetsIn Assets to be swapped at every step from underlier to FIAT (excluding FIAT)
    /// @param maxUnderliersIn Max. amount of underlier to swap [underlierScale]
    /// @param deadline Timestamp after which the trade is no more valid [s]
    /// @return buyFIATSwapParams BuyFIATSwapParams struct
    function buildBuyFIATSwapParams(
        bytes32[] calldata pathPoolIds, address[] calldata pathAssetsIn, uint256 maxUnderliersIn, uint256 deadline
    ) public view returns(BuyFIATSwapParams memory) {
        if (pathPoolIds.length != pathAssetsIn.length) revert LeverActions__getBuyFIATSwapParams_pathLengthMismatch();
        uint256 pathLength = pathPoolIds.length;

        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](pathLength);
        IAsset[] memory assets = new IAsset[](add(pathLength, uint256(1))); // number of assets = number of swaps + 1
        int256[] memory limits = new int256[](add(pathLength, uint256(1))); // for each asset has an associated limit

        assets[pathLength] = IAsset(address(fiat));
        limits[0] = toInt256(maxUnderliersIn);

        for (uint256 i = 0; i < pathLength;) {
            IBalancerVault.BatchSwapStep memory swap;
            unchecked {
                swap = IBalancerVault.BatchSwapStep(
                    // reverse the order such that last asset (FIAT) becomes assetIndexOut for the first swap
                    // and the first asset (underlier) becomes the assetIndexIn for the last swap
                    pathPoolIds[pathLength - i - 1], pathLength - i - 1, pathLength - i, 0, new bytes(0)
                );
            }
            swaps[i] = swap;
            assets[i] = IAsset(address(pathAssetsIn[i]));
            unchecked { i += 1; }
        }

        return BuyFIATSwapParams(swaps, assets, limits, deadline);
    }

    /// ======== Utility ======== ///
           
    /// @notice Returns the absolute value for a signed integer
    function abs(int256 a) private pure returns (uint256 result) {
        result = a > 0 ? uint256(a) : uint256(-a);
    }
}