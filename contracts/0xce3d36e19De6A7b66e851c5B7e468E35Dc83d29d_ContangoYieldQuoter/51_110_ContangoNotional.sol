//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ContangoBase.sol";
import "./ContangoVaultProxyDeployer.sol";
import "./Notional.sol";

/// @title ContangoNotional
/// @notice Contango extension to support notional specific features
contract ContangoNotional is ContangoVaultProxyDeployer, ContangoBase {
    using NotionalUtils for Symbol;
    using ProxyLib for PositionId;
    using SafeCast for uint256;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    error OnlyFromWETHOrProxy(address weth, address proxy, address sender);

    /// @dev this is ephemeral and must be set/clear within a tx via the context() modifier
    PositionId private contextPositionId;

    // solhint-disable-next-line no-empty-blocks
    constructor(WETH _weth) ContangoBase(_weth) {}

    function initialize(ContangoPositionNFT _positionNFT, address _treasury) public initializer {
        __ContangoBase_init(_positionNFT, _treasury);
    }

    // ============================================== Trading functions ==============================================

    /// @inheritdoc IContango
    // TODO alfredo - natspec about quantities adjusted to notional precision
    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        whenNotClosingOnly(quantity.toInt256())
        returns (PositionId positionId)
    {
        positionId = Notional.createPosition(
            Notional.CreatePositionParams(
                symbol, trader, quantity, limitCost, collateral, payer, lendingLiquidity, uniswapFee
            )
        );
    }

    /// @inheritdoc IContango
    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable override nonReentrant whenNotPaused context(positionId) {
        Notional.modifyCollateral(positionId, collateral, slippageTolerance, payerOrReceiver, lendingLiquidity);
    }

    /// @inheritdoc IContango
    // TODO alfredo - natspec about quantities adjusted to notional precision
    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external payable override nonReentrant whenNotPaused whenNotClosingOnly(quantity) context(positionId) {
        Notional.modifyPosition(
            positionId, quantity, limitCost, collateral, payerOrReceiver, lendingLiquidity, uniswapFee
        );
    }

    /// @inheritdoc IContango
    function deliver(PositionId positionId, address payer, address to)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        context(positionId)
    {
        Notional.deliver(positionId, payer, to);
    }

    // ============================================== Callback functions ==============================================

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        Notional.uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    function onVaultAccountDeleverage(PositionId positionId, uint256 size, uint256 cost) external {
        Notional.onVaultAccountDeleverage(positionId, size, cost);
    }

    // ============================================== Admin functions ==============================================

    function createNotionalInstrument(
        Symbol _symbol,
        uint16 _baseId,
        uint16 _quoteId,
        uint256 _marketIndex,
        IFeeModel _feeModel,
        ContangoVault _vault
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (Instrument memory, NotionalInstrument memory) {
        return NotionalStorageLib.createInstrument(
            _symbol, _baseId, _quoteId, _marketIndex, _feeModel, _vault, address(weth)
        );
    }

    function notionalInstrument(Symbol symbol)
        external
        view
        returns (Instrument memory instrument_, NotionalInstrument memory notionalInstrument_, ContangoVault vault_)
    {
        return symbol.loadInstrument();
    }

    function setProxyHash(bytes32 _proxyHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ConfigStorageLib.setProxyHash(_proxyHash);
    }

    function proxyHash() external view returns (bytes32) {
        return ConfigStorageLib.getProxyHash();
    }

    // TODO alfredo - should we implement proxy approve() for claiming other tokens when necessary? e.g. airdrops, accidental transfers
    // revisit testCanNotCollectProxyBalanceForTokenNotInInstrument() if that's the case

    /// @notice this will only allow for recovery of the tokens that are either base or quote of position instrument and/or native ETH,
    /// other tokens will be locked due to lack of approval (currently not exposed externally on ContangoNotional, but possible via PermissionedProxy.approve())
    function collectProxyBalance(PositionId positionId, address token, address payable to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        context(positionId)
    {
        address payable proxy = positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        if (token == address(0)) {
            PermissionedProxy(proxy).collectBalance(amount);
            to.safeTransferETH(amount);
        } else {
            ERC20(token).safeTransferFrom(proxy, to, amount);
        }
    }

    receive() external payable override {
        if (msg.sender != address(weth)) {
            // delays proxy resolution and check to stay under 2300 gas limit
            address proxy = PositionId.unwrap(contextPositionId) != 0
                ? contextPositionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash())
                : address(0);

            if (msg.sender != proxy) {
                revert OnlyFromWETHOrProxy(address(weth), proxy, msg.sender);
            }
        }
    }

    modifier context(PositionId positionId) {
        contextPositionId = positionId;
        _;
        contextPositionId = PositionId.wrap(0);
    }
}