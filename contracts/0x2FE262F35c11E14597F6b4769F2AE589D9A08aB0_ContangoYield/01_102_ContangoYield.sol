//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import {IContangoLadle} from "@yield-protocol/vault-v2/contracts/other/contango/interfaces/IContangoLadle.sol";
import {IContangoWitchListener} from
    "@yield-protocol/vault-v2/contracts/other/contango/interfaces/IContangoWitchListener.sol";
import {Yield} from "./Yield.sol";
import {YieldUtils} from "./YieldUtils.sol";

import {ContangoPositionNFT} from "../../ContangoPositionNFT.sol";
import {IWETH9, WethHandler} from "../../batchable/WethHandler.sol";
import {IContango} from "../../interfaces/IContango.sol";
import {IFeeModel} from "../../interfaces/IFeeModel.sol";
import {Instrument, PositionId, Symbol, YieldInstrument} from "../../libraries/DataTypes.sol";
import {YieldStorageLib} from "../../libraries/StorageLib.sol";

import {ContangoBase} from "../ContangoBase.sol";

/// @title ContangoYield
/// @notice Contract that acts as the main entry point to the protocol with yield-protocol as the underlying
/// @author Bruno Bonanno
/// @dev This is the main entry point to the system when using yield-protocol as the underlying,
/// any UI/contract should be just interacting with this contract children's + the NFT for ownership management
contract ContangoYield is ContangoBase, IContangoWitchListener {
    using SafeCast for uint256;
    using YieldUtils for Symbol;

    bytes32 public constant WITCH = keccak256("WITCH");

    // solhint-disable-next-line no-empty-blocks
    constructor(IWETH9 _weth) ContangoBase(_weth) {}

    function initialize(ContangoPositionNFT _positionNFT, address _treasury, IContangoLadle _ladle)
        public
        initializer
    {
        __ContangoBase_init(_positionNFT, _treasury);

        YieldStorageLib.setLadle(_ladle);
        YieldStorageLib.setCauldron(_ladle.cauldron());
    }

    // ============================================== Trading functions ==============================================

    /// @inheritdoc IContango
    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        whenNotClosingOnly(quantity.toInt256())
        returns (PositionId)
    {
        return Yield.createPosition(symbol, trader, quantity, limitCost, collateral, payer, lendingLiquidity);
    }

    /// @inheritdoc IContango
    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable override nonReentrant whenNotPaused {
        Yield.modifyCollateral(positionId, collateral, slippageTolerance, payerOrReceiver, lendingLiquidity);
    }

    /// @inheritdoc IContango
    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable override nonReentrant whenNotPaused whenNotClosingOnly(quantity) {
        Yield.modifyPosition(positionId, quantity, limitCost, collateral, payerOrReceiver, lendingLiquidity);
    }

    /// @inheritdoc IContango
    function deliver(PositionId positionId, address payer, address to)
        external
        payable
        override
        nonReentrant
        whenNotPaused
    {
        Yield.deliver(positionId, payer, to);
    }

    // solhint-disable-next-line no-empty-blocks
    function auctionStarted(bytes12 vaultId) external override {}

    function collateralBought(bytes12 vaultId, address, uint256 ink, uint256 art)
        external
        override
        nonReentrant
        onlyRole(WITCH)
    {
        Yield.collateralBought(vaultId, ink, art);
    }

    // solhint-disable-next-line no-empty-blocks
    function auctionEnded(bytes12 vaultId, address owner) external override {}

    // ============================================== Callback functions ==============================================

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        Yield.uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    // ============================================== Admin functions ==============================================

    function createYieldInstrument(
        Symbol _symbol,
        bytes6 _baseId,
        bytes6 _quoteId,
        uint24 _uniswapFee,
        IFeeModel _feeModel
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (Instrument memory, YieldInstrument memory) {
        return YieldStorageLib.createInstrument(_symbol, _baseId, _quoteId, _uniswapFee, _feeModel);
    }

    function yieldInstrument(Symbol symbol) external view returns (Instrument memory, YieldInstrument memory) {
        return symbol.loadInstrument();
    }
}