// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";
import "./libraries/FullMath.sol";
import "./libraries/FixedPoint112.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IIndex.sol";
import "./interfaces/IOrderer.sol";
import "./interfaces/IOrdererV2.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IReweightableIndex.sol";
import "./interfaces/IPhuturePriceOracle.sol";

/// @title Orderer
/// @notice Contains logic for reweigh execution, order creation and execution
contract Orderer is IOrderer, IOrdererV2, UUPSUpgradeable, ERC165Upgradeable {
    using FullMath for uint;
    using ERC165CheckerUpgradeable for address;
    using SafeERC20 for IERC20;

    /// @notice Order details structure containing assets list, creator address, creation timestamp and assetDetails
    struct OrderDetails {
        uint creationTimestamp;
        address creator;
        address[] assets;
        mapping(address => AssetDetails) assetDetails;
    }

    /// @notice Asset details structure containing order side (buy/sell) and order shares amount
    struct AssetDetails {
        OrderSide side;
        uint248 shares;
    }

    struct SwapDetails {
        address sellAsset;
        address buyAsset;
        IvToken sellVToken;
        IvToken buyVToken;
        IPhuturePriceOracle priceOracle;
    }

    struct InternalSwapVaultsInfo {
        address sellAccount;
        address buyAccount;
        uint maxSellShares;
        IvToken buyVTokenSellAccount;
        IvToken buyVTokenBuyAccount;
        SwapDetails details;
    }

    /// @notice Min amount in BASE to swap during burning
    uint internal constant MIN_SWAP_AMOUNT = 1_000_000;

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Keeper job role
    bytes32 internal constant KEEPER_JOB_ROLE = keccak256("KEEPER_JOB_ROLE");
    /// @notice Exchange factory role
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

    /// @notice Last placed order id
    uint internal _lastOrderId;

    /// @notice Index registry address
    address internal registry;

    /// @inheritdoc IOrderer
    uint64 public override orderLifetime;

    /// @inheritdoc IOrderer
    uint16 public override maxAllowedPriceImpactInBP;

    /// @inheritdoc IOrdererV2
    uint16 public override maxSlippageInBP;

    /// @inheritdoc IOrderer
    mapping(address => uint) public override lastOrderIdOf;

    /// @notice Mapping of order id to order details
    mapping(uint => OrderDetails) internal orderDetailsOf;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "Orderer: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IOrdererV2
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxSlippageInBP
    ) external override(IOrderer, IOrdererV2) initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "Orderer: INTERFACE");

        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        orderLifetime = _orderLifetime;
        maxSlippageInBP = _maxSlippageInBP;
    }

    /// @inheritdoc IOrderer
    function setMaxAllowedPriceImpactInBP(uint16 _maxAllowedPriceImpactInBP) external {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrdererV2
    function setMaxSlippageInBP(uint16 _maxSlippageInBP) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_maxSlippageInBP != 0 && _maxSlippageInBP <= BP.DECIMAL_FACTOR, "Orderer: INVALID");

        maxSlippageInBP = _maxSlippageInBP;
    }

    /// @inheritdoc IOrderer
    function setOrderLifetime(uint64 _orderLifetime) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_orderLifetime != 0, "Orderer: INVALID");

        orderLifetime = _orderLifetime;
    }

    /// @inheritdoc IOrderer
    function placeOrder() external override onlyRole(INDEX_ROLE) returns (uint _orderId) {
        delete orderDetailsOf[lastOrderIdOf[msg.sender]];
        unchecked {
            ++_lastOrderId;
        }
        _orderId = _lastOrderId;
        OrderDetails storage order = orderDetailsOf[_orderId];
        order.creationTimestamp = block.timestamp;
        order.creator = msg.sender;
        lastOrderIdOf[msg.sender] = _orderId;
        emit PlaceOrder(msg.sender, _orderId);
    }

    /// @inheritdoc IOrderer
    function addOrderDetails(
        uint _orderId,
        address _asset,
        uint _shares,
        OrderSide _side
    ) external override onlyRole(INDEX_ROLE) {
        if (_asset != address(0) && _shares != 0) {
            OrderDetails storage order = orderDetailsOf[_orderId];
            order.assets.push(_asset);
            order.assetDetails[_asset] = AssetDetails({ side: _side, shares: uint248(_shares) });
            emit UpdateOrder(_orderId, _asset, _shares, _side == OrderSide.Sell);
        }
    }

    function updateOrderDetails(address _asset, uint _shares) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0 && _asset != address(0)) {
            uint248 shares = uint248(_shares);
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            order.assetDetails[_asset].shares = shares;
            emit UpdateOrder(lastOrderId, _asset, shares, order.assetDetails[_asset].side == OrderSide.Sell);
        }
    }

    /// @inheritdoc IOrderer
    function reduceOrderAsset(
        address _asset,
        uint _newTotalSupply,
        uint _oldTotalSupply
    ) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0) {
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            uint shares = order.assetDetails[_asset].shares;
            if (shares != 0) {
                uint248 newShares = uint248((shares * _newTotalSupply) / _oldTotalSupply);
                order.assetDetails[_asset].shares = newShares;
                emit UpdateOrder(lastOrderId, _asset, newShares, order.assetDetails[_asset].side == OrderSide.Sell);
            }
        }
    }

    /// @inheritdoc IOrderer
    function reweight(address _index) external override onlyRole(KEEPER_JOB_ROLE) {
        IReweightableIndex(_index).reweight();
    }

    /// @inheritdoc IOrderer
    function internalSwap(InternalSwap calldata _info) external override {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrderer
    function externalSwap(ExternalSwap calldata _info) external override {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrdererV2
    function internalSwap(InternalSwapV2 calldata _info) external override onlyRole(KEEPER_JOB_ROLE) {
        require(_info.maxSellShares != 0 && _info.buyAccount != _info.sellAccount, "Orderer: INVALID");
        require(
            IAccessControl(registry).hasRole(INDEX_ROLE, _info.buyAccount) &&
                IAccessControl(registry).hasRole(INDEX_ROLE, _info.sellAccount),
            "Orderer: INDEX"
        );

        address sellVTokenFactory = IIndex(_info.sellAccount).vTokenFactory();
        address buyVTokenFactory = IIndex(_info.buyAccount).vTokenFactory();
        SwapDetails memory _details = _swapDetails(
            sellVTokenFactory,
            buyVTokenFactory,
            _info.sellAsset,
            _info.buyAsset
        );

        if (sellVTokenFactory == buyVTokenFactory) {
            _internalWithinVaultSwap(_info, _details);
        } else {
            _internalBetweenVaultsSwap(
                InternalSwapVaultsInfo(
                    _info.sellAccount,
                    _info.buyAccount,
                    _info.maxSellShares,
                    IvToken(IvTokenFactory(sellVTokenFactory).vTokenOf(_details.buyAsset)),
                    IvToken(IvTokenFactory(buyVTokenFactory).vTokenOf(_details.sellAsset)),
                    _details
                )
            );
        }
    }

    /// @inheritdoc IOrdererV2
    function externalSwap(ExternalSwapV2 calldata _info) external override onlyRole(KEEPER_JOB_ROLE) {
        require(_info.swapTarget != address(0) && _info.swapData.length > 0, "Orderer: INVALID");
        require(IAccessControl(registry).hasRole(INDEX_ROLE, _info.account), "Orderer: INVALID");

        SwapDetails memory _details = _swapDetails(
            IIndex(_info.account).vTokenFactory(),
            address(0),
            _info.sellAsset,
            _info.buyAsset
        );

        (uint lastOrderId, AssetDetails storage orderSellAsset, AssetDetails storage orderBuyAsset) = _validatedOrder(
            _info.account,
            _details.sellAsset,
            _details.buyAsset
        );

        require(orderSellAsset.shares >= _info.sellShares, "Orderer: MAX");

        uint sellAssetPerBase = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);

        if (
            orderSellAsset.shares == _details.sellVToken.balanceOf(_info.account) &&
            _details.sellVToken.assetDataOf(_info.account, orderSellAsset.shares).amountInAsset.mulDiv(
                FixedPoint112.Q112,
                sellAssetPerBase
            ) <
            MIN_SWAP_AMOUNT
        ) {
            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), orderSellAsset.shares);
            _details.sellVToken.burnFor(address(_details.sellVToken));

            emit CompleteOrder(lastOrderId, _details.sellAsset, orderSellAsset.shares, _details.buyAsset, 0);

            orderSellAsset.shares = 0;
        } else {
            uint sellAmount = _details.sellVToken.assetDataOf(_info.account, _info.sellShares).amountInAsset;

            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), _info.sellShares);
            _details.sellVToken.burnFor(address(this));

            uint sellBalanceBefore = IERC20(_details.sellAsset).balanceOf(address(this));

            {
                uint allowance = IERC20(_details.sellAsset).allowance(address(this), _info.swapTarget);
                IERC20(_details.sellAsset).safeIncreaseAllowance(_info.swapTarget, type(uint256).max - allowance);
            }

            {
                (bool success, bytes memory data) = _info.swapTarget.call(_info.swapData);
                if (!success) {
                    if (data.length == 0) {
                        revert("Orderer: SWAP_FAILED");
                    } else {
                        assembly {
                            revert(add(32, data), mload(data))
                        }
                    }
                }
            }

            {
                uint sellAmountInBase = sellAmount.mulDiv(FixedPoint112.Q112, sellAssetPerBase);

                uint soldAmount = sellBalanceBefore - IERC20(_details.sellAsset).balanceOf(address(this));
                uint soldAmountInBase = soldAmount.mulDiv(FixedPoint112.Q112, sellAssetPerBase);

                // checks diff between input and swap amounts
                require(sellAmountInBase - soldAmountInBase <= MIN_SWAP_AMOUNT, "Orderer: AMOUNT");

                uint boughtAmount = IERC20(_details.buyAsset).balanceOf(address(this));
                uint boughtAmountInBase = boughtAmount.mulDiv(
                    FixedPoint112.Q112,
                    _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset)
                );
                uint ratio = (boughtAmountInBase * BP.DECIMAL_FACTOR) / (soldAmountInBase);

                require(
                    ratio >= BP.DECIMAL_FACTOR - maxSlippageInBP && ratio <= BP.DECIMAL_FACTOR + maxSlippageInBP,
                    "Orderer: SLIPPAGE"
                );

                IERC20(_details.buyAsset).safeTransfer(address(_details.buyVToken), boughtAmount);
            }

            uint248 _buyShares = uint248(Math.min(_details.buyVToken.mintFor(_info.account), orderBuyAsset.shares));

            orderSellAsset.shares -= uint248(_info.sellShares);
            orderBuyAsset.shares -= _buyShares;

            emit CompleteOrder(lastOrderId, _details.sellAsset, _info.sellShares, _details.buyAsset, _buyShares);

            uint change = IERC20(_details.sellAsset).balanceOf(address(this));
            if (change > 0) {
                IERC20(_details.sellAsset).safeTransfer(address(_details.sellVToken), change);
                _details.sellVToken.sync();
            }

            IERC20(_details.sellAsset).safeApprove(_info.swapTarget, 0);
        }
    }

    /// @inheritdoc IOrderer
    function orderOf(address _account) external view override returns (Order memory order) {
        OrderDetails storage _order = orderDetailsOf[lastOrderIdOf[_account]];
        order = Order({ creationTimestamp: _order.creationTimestamp, assets: new OrderAsset[](_order.assets.length) });

        uint assetsCount = _order.assets.length;
        for (uint i; i < assetsCount; ) {
            address asset = _order.assets[i];
            order.assets[i] = OrderAsset({
                asset: asset,
                side: _order.assetDetails[asset].side,
                shares: _order.assetDetails[asset].shares
            });

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IOrdererV2).interfaceId ||
            _interfaceId == type(IOrderer).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Executes internal swap within single vault
    function _internalWithinVaultSwap(InternalSwapV2 calldata _info, SwapDetails memory _details) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _details.sellAsset, _details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _details.buyAsset, _details.sellAsset);

        uint248 sellShares;
        uint248 buyShares;
        {
            uint _sellShares = Math.min(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares
            );
            uint _buyShares = Math.min(sellOrderBuyAsset.shares, buyOrderSellAsset.shares);
            (sellShares, buyShares) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _details,
                _sellShares,
                _buyShares
            );
        }

        if (sellShares != 0 && buyShares != 0) {
            _details.sellVToken.transferFrom(_info.sellAccount, _info.buyAccount, sellShares);
            _details.buyVToken.transferFrom(_info.buyAccount, _info.sellAccount, buyShares);

            sellOrderSellAsset.shares -= sellShares;
            sellOrderBuyAsset.shares -= buyShares;
            buyOrderSellAsset.shares -= buyShares;
            buyOrderBuyAsset.shares -= sellShares;

            emit CompleteOrder(lastSellOrderId, _details.sellAsset, sellShares, _details.buyAsset, buyShares);
            emit CompleteOrder(lastBuyOrderId, _details.buyAsset, buyShares, _details.sellAsset, sellShares);
        }
    }

    /// @notice Executes internal swap between different vaults
    function _internalBetweenVaultsSwap(InternalSwapVaultsInfo memory _info) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _info.details.sellAsset, _info.details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _info.details.buyAsset, _info.details.sellAsset);

        uint248 sellSharesSellAccount;
        uint248 sellSharesBuyAccount;
        {
            uint _sellSharesSellAccount = _scaleShares(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares,
                _info.sellAccount,
                _info.details.sellVToken,
                _info.buyVTokenBuyAccount
            );
            uint _buySharesBuyAccount = _scaleShares(
                buyOrderSellAsset.shares,
                sellOrderBuyAsset.shares,
                _info.buyAccount,
                _info.details.buyVToken,
                _info.buyVTokenSellAccount
            );

            (sellSharesSellAccount, sellSharesBuyAccount) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _info.details,
                _sellSharesSellAccount,
                _buySharesBuyAccount
            );
        }

        _info.details.sellVToken.transferFrom(
            _info.sellAccount,
            address(_info.details.sellVToken),
            sellSharesSellAccount
        );
        _info.details.sellVToken.burnFor(address(_info.buyVTokenBuyAccount));
        uint248 buySharesBuyAccount = uint248(_info.buyVTokenBuyAccount.mintFor(_info.buyAccount));

        _info.details.buyVToken.transferFrom(_info.buyAccount, address(_info.details.buyVToken), sellSharesBuyAccount);
        _info.details.buyVToken.burnFor(address(_info.buyVTokenSellAccount));
        uint248 buySharesSellAccount = uint248(_info.buyVTokenSellAccount.mintFor(_info.sellAccount));

        sellOrderSellAsset.shares -= sellSharesSellAccount;
        sellOrderBuyAsset.shares -= buySharesSellAccount;
        buyOrderSellAsset.shares -= sellSharesBuyAccount;
        buyOrderBuyAsset.shares -= buySharesBuyAccount;

        emit CompleteOrder(
            lastSellOrderId,
            _info.details.sellAsset,
            sellSharesSellAccount,
            _info.details.buyAsset,
            buySharesSellAccount
        );
        emit CompleteOrder(
            lastBuyOrderId,
            _info.details.buyAsset,
            sellSharesBuyAccount,
            _info.details.sellAsset,
            buySharesBuyAccount
        );
    }

    /// @notice Returns validated order's info
    /// @param _index Index address
    /// @param _sellAsset Sell asset address
    /// @param _buyAsset Buy asset address
    /// @return lastOrderId Id of last order
    /// @return orderSellAsset Order's details for sell asset
    /// @return orderBuyAsset Order's details for buy asset
    function _validatedOrder(
        address _index,
        address _sellAsset,
        address _buyAsset
    )
        internal
        view
        returns (
            uint lastOrderId,
            AssetDetails storage orderSellAsset,
            AssetDetails storage orderBuyAsset
        )
    {
        lastOrderId = lastOrderIdOf[_index];
        OrderDetails storage order = orderDetailsOf[lastOrderId];

        orderSellAsset = order.assetDetails[_sellAsset];
        orderBuyAsset = order.assetDetails[_buyAsset];

        require(order.creationTimestamp + orderLifetime > block.timestamp, "Orderer: EXPIRED");
        require(orderSellAsset.side == OrderSide.Sell && orderBuyAsset.side == OrderSide.Buy, "Orderer: SIDE");
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IOrderer).interfaceId), "Orderer: INTERFACE");
    }

    /// @notice Scales down shares
    function _scaleShares(
        uint _sellShares,
        uint _buyShares,
        address _sellAccount,
        IvToken _sellVToken,
        IvToken _buyVToken
    ) internal view returns (uint) {
        uint sharesInAsset = _sellVToken.assetDataOf(_sellAccount, _sellShares).amountInAsset;
        uint mintableShares = _buyVToken.mintableShares(sharesInAsset);
        return Math.min(_sellShares, (_sellShares * _buyShares) / mintableShares);
    }

    /// @notice Calculates internal swap shares (buy and sell) for the given swap details
    function _calculateInternalSwapShares(
        address sellAccount,
        address buyAccount,
        SwapDetails memory _details,
        uint _sellOrderShares,
        uint _buyOrderShares
    ) internal returns (uint248 _sellShares, uint248 _buyShares) {
        uint sellAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);
        uint buyAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset);
        {
            uint buyAmountInBuyAsset = _details.buyVToken.assetBalanceForShares(_buyOrderShares);
            uint buyAmountInSellAsset = buyAmountInBuyAsset.mulDiv(sellAssetPerBaseInUQ, buyAssetPerBaseInUQ);
            _sellOrderShares = Math.min(_sellOrderShares, _details.sellVToken.mintableShares(buyAmountInSellAsset));
        }
        {
            uint sellAmountInSellAsset = _details.sellVToken.assetDataOf(sellAccount, _sellOrderShares).amountInAsset;
            uint sellAmountInBuyAsset = sellAmountInSellAsset.mulDiv(buyAssetPerBaseInUQ, sellAssetPerBaseInUQ);
            _buyOrderShares = Math.min(_buyOrderShares, _details.buyVToken.mintableShares(sellAmountInBuyAsset));
        }
        _sellShares = uint248(_sellOrderShares);
        _buyShares = uint248(_buyOrderShares);
    }

    /// @notice Returns swap details for the provided buy path
    /// @param _sellVTokenFactory vTokenFactory address of sell account
    /// @param _buyVTokenFactory vTokenFactory address of buy account
    /// @param _sellAsset Address of sell asset
    /// @param _buyAsset Address address of buy asset
    /// @return Swap details
    function _swapDetails(
        address _sellVTokenFactory,
        address _buyVTokenFactory,
        address _sellAsset,
        address _buyAsset
    ) internal view returns (SwapDetails memory) {
        require(_sellAsset != address(0) && _buyAsset != address(0), "Orderer: ZERO");
        require(_sellAsset != _buyAsset, "Orderer: INVALID");

        address buyVToken = IvTokenFactory(
            (_sellVTokenFactory == _buyVTokenFactory || _buyVTokenFactory == address(0))
                ? _sellVTokenFactory
                : _buyVTokenFactory
        ).vTokenOf(_buyAsset);

        return
            SwapDetails({
                sellAsset: _sellAsset,
                buyAsset: _buyAsset,
                sellVToken: IvToken(IvTokenFactory(_sellVTokenFactory).vTokenOf(_sellAsset)),
                buyVToken: IvToken(buyVToken),
                priceOracle: IPhuturePriceOracle(IIndexRegistry(registry).priceOracle())
            });
    }

    uint256[46] private __gap;
}