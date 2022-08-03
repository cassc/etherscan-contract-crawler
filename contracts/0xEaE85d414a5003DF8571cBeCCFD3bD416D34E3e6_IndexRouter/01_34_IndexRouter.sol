// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "./libraries/BP.sol";
import "./libraries/IndexLibrary.sol";

import "./interfaces/IIndex.sol";
import "./interfaces/IvToken.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IIndexRouter.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/external/IWETH.sol";
import "./interfaces/IPhuturePriceOracle.sol";

/// @title Index router
/// @notice Contains methods allowing to mint and redeem index tokens in exchange for various assets
contract IndexRouter is IIndexRouter, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using FullMath for uint;
    using SafeERC20 for IERC20;
    using IndexLibrary for uint;
    using ERC165Checker for address;

    struct MintDetails {
        uint minAmountInBase;
        uint[] amountsInBase;
        uint[] inputAmountInToken;
        IvTokenFactory vTokenFactory;
    }

    /// @notice Min amount in BASE to swap during burning
    uint internal constant MIN_SWAP_AMOUNT = 1_000_000;

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Asset role
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");
    /// @notice Exchange admin role
    bytes32 internal constant EXCHANGE_ADMIN_ROLE = keccak256("EXCHANGE_ADMIN_ROLE");
    /// @notice Skipped asset role
    bytes32 internal constant SKIPPED_ASSET_ROLE = keccak256("SKIPPED_ASSET_ROLE");
    /// @notice Exchange target role
    bytes32 internal constant EXCHANGE_TARGET_ROLE = keccak256("EXCHANGE_TARGET_ROLE");

    /// @inheritdoc IIndexRouter
    address public override WETH;
    /// @inheritdoc IIndexRouter
    address public override registry;

    /// @notice Checks if `_index` has INDEX_ROLE
    /// @param _index Index address
    modifier isValidIndex(address _index) {
        require(IAccessControl(registry).hasRole(INDEX_ROLE, _index), "IndexRouter: INVALID");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IIndexRouter
    function initialize(address _WETH, address _registry) external override initializer {
        require(_WETH != address(0), "IndexRouter: ZERO");

        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "IndexRouter: INTERFACE");

        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        WETH = _WETH;
        registry = _registry;
    }

    /// @inheritdoc IIndexRouter
    /// @dev only accept ETH via fallback from the WETH contract
    receive() external payable override {
        require(msg.sender == WETH);
    }

    /// @inheritdoc IIndexRouter
    function mintSwapIndexAmount(MintSwapParams calldata _params) external view override returns (uint _amount) {
        (address[] memory _assets, uint8[] memory _weights) = IIndex(_params.index).anatomy();

        uint assetBalanceInBase;
        uint minAmountInBase = type(uint).max;

        for (uint i; i < _weights.length; ) {
            if (_weights[i] != 0) {
                uint _amount = _params.quotes[i].buyAssetMinAmount;

                uint assetPerBaseInUQ = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle())
                    .lastAssetPerBaseInUQ(_assets[i]);
                {
                    uint _minAmountInBase = _amount.mulDiv(
                        FixedPoint112.Q112 * IndexLibrary.MAX_WEIGHT,
                        assetPerBaseInUQ * _weights[i]
                    );
                    if (_minAmountInBase < minAmountInBase) {
                        minAmountInBase = _minAmountInBase;
                    }
                }

                IvToken vToken = IvToken(IvTokenFactory(IIndex(_params.index).vTokenFactory()).vTokenOf(_assets[i]));
                if (address(vToken) != address(0)) {
                    assetBalanceInBase += vToken.lastAssetBalanceOf(_params.index).mulDiv(
                        FixedPoint112.Q112,
                        assetPerBaseInUQ
                    );
                }
            }

            unchecked {
                i = i + 1;
            }
        }

        IPhuturePriceOracle priceOracle = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle());
        {
            address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();

            uint inactiveAssetsCount = inactiveAssets.length;
            for (uint i; i < inactiveAssetsCount; ) {
                address inactiveAsset = inactiveAssets[i];
                if (!IAccessControl(registry).hasRole(SKIPPED_ASSET_ROLE, inactiveAsset)) {
                    uint balanceInAsset = IvToken(
                        IvTokenFactory((IIndex(_params.index).vTokenFactory())).vTokenOf(inactiveAsset)
                    ).lastAssetBalanceOf(_params.index);

                    assetBalanceInBase += balanceInAsset.mulDiv(
                        FixedPoint112.Q112,
                        priceOracle.lastAssetPerBaseInUQ(inactiveAsset)
                    );
                }
                unchecked {
                    i = i + 1;
                }
            }
        }

        assert(minAmountInBase != type(uint).max);

        uint8 _indexDecimals = IERC20Metadata(_params.index).decimals();
        if (IERC20(_params.index).totalSupply() != 0) {
            _amount =
                (priceOracle.convertToIndex(minAmountInBase, _indexDecimals) * IERC20(_params.index).totalSupply()) /
                priceOracle.convertToIndex(assetBalanceInBase, _indexDecimals);
        } else {
            _amount = priceOracle.convertToIndex(minAmountInBase, _indexDecimals) - IndexLibrary.INITIAL_QUANTITY;
        }

        uint256 fee = (_amount * IFeePool(IIndexRegistry(registry).feePool()).mintingFeeInBPOf(_params.index)) /
            BP.DECIMAL_FACTOR;
        _amount -= fee;
    }

    /// @inheritdoc IIndexRouter
    function burnTokensAmount(address _index, uint _amount) external view override returns (uint[] memory _amounts) {
        (address[] memory _assets, uint8[] memory _weights) = IIndex(_index).anatomy();
        address[] memory inactiveAssets = IIndex(_index).inactiveAnatomy();
        _amounts = new uint[](_weights.length + inactiveAssets.length);

        uint assetsCount = _assets.length;

        bool containsBlacklistedAssets;
        for (uint i; i < assetsCount; ) {
            if (!IAccessControl(registry).hasRole(ASSET_ROLE, _assets[i])) {
                containsBlacklistedAssets = true;
                break;
            }

            unchecked {
                i = i + 1;
            }
        }

        if (!containsBlacklistedAssets) {
            _amount -=
                (_amount * IFeePool(IIndexRegistry(registry).feePool()).burningFeeInBPOf(_index)) /
                BP.DECIMAL_FACTOR;
        }

        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        for (uint i; i < totalAssetsCount; ) {
            address asset = i < assetsCount ? _assets[i] : inactiveAssets[i - assetsCount];
            if (!(containsBlacklistedAssets && IAccessControl(registry).hasRole(SKIPPED_ASSET_ROLE, asset))) {
                uint indexAssetBalance = IvToken(IvTokenFactory(IIndex(_index).vTokenFactory()).vTokenOf(asset))
                    .balanceOf(_index);

                _amounts[i] = (_amount * indexAssetBalance) / IERC20(_index).totalSupply();
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IIndexRouter
    function mint(MintParams calldata _params)
        external
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint)
    {
        IIndex index = IIndex(_params.index);
        (address[] memory _assets, uint8[] memory _weights) = index.anatomy();

        IvTokenFactory vTokenFactory = IvTokenFactory(index.vTokenFactory());
        IPriceOracle oracle = IPriceOracle(IIndexRegistry(registry).priceOracle());

        uint assetsCount = _assets.length;
        for (uint i; i < assetsCount; ) {
            if (_weights[i] > 0) {
                address asset = _assets[i];
                IERC20(asset).safeTransferFrom(
                    msg.sender,
                    vTokenFactory.createdVTokenOf(_assets[i]),
                    oracle.refreshedAssetPerBaseInUQ(asset).amountInAsset(_weights[i], _params.amountInBase)
                );
            }

            unchecked {
                i = i + 1;
            }
        }

        uint balance = IERC20(_params.index).balanceOf(_params.recipient);
        index.mint(_params.recipient);

        return IERC20(_params.index).balanceOf(_params.recipient) - balance;
    }

    /// @inheritdoc IIndexRouter
    function mintSwap(MintSwapParams calldata _params)
        public
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint)
    {
        IERC20(_params.inputToken).safeTransferFrom(msg.sender, address(this), _params.amountInInputToken);
        _mint(_params.index, _params.inputToken, _params.amountInInputToken, _params.quotes);

        uint balance = IERC20(_params.index).balanceOf(_params.recipient);
        IIndex(_params.index).mint(_params.recipient);

        return IERC20(_params.index).balanceOf(_params.recipient) - balance;
    }

    /// @inheritdoc IIndexRouter
    function mintSwapWithPermit(
        MintSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint) {
        IERC20Permit(_params.inputToken).permit(
            msg.sender,
            address(this),
            _params.amountInInputToken,
            _deadline,
            _v,
            _r,
            _s
        );

        return mintSwap(_params);
    }

    /// @inheritdoc IIndexRouter
    function mintSwapValue(MintSwapValueParams calldata _params)
        external
        payable
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint)
    {
        IWETH(WETH).deposit{ value: msg.value }();
        _mint(_params.index, WETH, msg.value, _params.quotes);

        uint balance = IERC20(_params.index).balanceOf(_params.recipient);
        IIndex(_params.index).mint(_params.recipient);

        return IERC20(_params.index).balanceOf(_params.recipient) - balance;
    }

    /// @inheritdoc IIndexRouter
    function burn(BurnParams calldata _params) public override nonReentrant isValidIndex(_params.index) {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);
        IIndex(_params.index).burn(_params.recipient);
    }

    /// @inheritdoc IIndexRouter
    function burnWithAmounts(BurnParams calldata _params)
        external
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint[] memory _amounts)
    {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);

        (address[] memory _assets, ) = IIndex(_params.index).anatomy();
        uint assetsCount = _assets.length;
        address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();
        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        uint[] memory balancesBefore = new uint[](totalAssetsCount);
        for (uint i; i < totalAssetsCount; ++i) {
            address asset = i < assetsCount ? _assets[i] : inactiveAssets[i - assetsCount];
            balancesBefore[i] = IERC20(asset).balanceOf(_params.recipient);
        }

        IIndex(_params.index).burn(_params.recipient);

        _amounts = new uint[](totalAssetsCount);
        for (uint i; i < totalAssetsCount; ++i) {
            address asset = i < assetsCount ? _assets[i] : inactiveAssets[i - assetsCount];
            _amounts[i] = IERC20(asset).balanceOf(_params.recipient) - balancesBefore[i];
        }
    }

    /// @inheritdoc IIndexRouter
    function burnSwap(BurnSwapParams calldata _params)
        public
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint)
    {
        _burn(_params);

        uint balance = IERC20(_params.outputAsset).balanceOf(_params.recipient);
        IERC20(_params.outputAsset).safeTransfer(
            _params.recipient,
            IERC20(_params.outputAsset).balanceOf(address(this))
        );

        return IERC20(_params.outputAsset).balanceOf(_params.recipient) - balance;
    }

    /// @inheritdoc IIndexRouter
    function burnSwapValue(BurnSwapParams calldata _params)
        public
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint wethBalance)
    {
        require(_params.outputAsset == WETH, "IndexRouter: OUTPUT_ASSET");
        _burn(_params);
        wethBalance = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(wethBalance);
        TransferHelper.safeTransferETH(_params.recipient, wethBalance);
    }

    /// @inheritdoc IIndexRouter
    function burnWithPermit(
        BurnParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        burn(_params);
    }

    /// @inheritdoc IIndexRouter
    function burnSwapWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint) {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        return burnSwap(_params);
    }

    /// @inheritdoc IIndexRouter
    function burnSwapValueWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint) {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        return burnSwapValue(_params);
    }

    /// @notice Swaps and sends assets in certain proportions to vTokens to mint index
    /// @param _index Index token address
    /// @param _inputToken Input token address
    /// @param _amountInInputToken Amount in input token
    /// @param _quotes Quotes for each asset
    function _mint(
        address _index,
        address _inputToken,
        uint _amountInInputToken,
        MintQuoteParams[] calldata _quotes
    ) internal {
        uint quotesCount = _quotes.length;
        IvTokenFactory vTokenFactory = IvTokenFactory(IIndex(_index).vTokenFactory());
        uint _inputBalanceBefore = IERC20(_inputToken).balanceOf(address(this));
        for (uint i; i < quotesCount; i++) {
            address asset = _quotes[i].asset;

            // if one of the assets is inputToken we transfer it directly to the vault
            if (asset == _inputToken) {
                IERC20(_inputToken).safeTransfer(
                    vTokenFactory.createdVTokenOf(_inputToken),
                    _quotes[i].buyAssetMinAmount
                );
                continue;
            }
            address swapTarget = _quotes[i].swapTarget;
            require(IAccessControl(registry).hasRole(EXCHANGE_TARGET_ROLE, swapTarget), "IndexRouter: INVALID_TARGET");
            _safeApprove(_inputToken, swapTarget, _amountInInputToken);
            // execute the swap with the quote for the asset
            _fillQuote(swapTarget, _quotes[i].assetQuote);
            uint assetBalanceAfter = IERC20(asset).balanceOf(address(this));
            require(assetBalanceAfter >= _quotes[i].buyAssetMinAmount, "IndexRouter: UNDERBOUGHT_ASSET");
            IERC20(asset).safeTransfer(vTokenFactory.createdVTokenOf(asset), assetBalanceAfter);
        }
        require(
            _inputBalanceBefore - IERC20(_inputToken).balanceOf(address(this)) == _amountInInputToken,
            "IndexRouter: INVALID_INPUT_AMOUNT"
        );
    }

    /// @notice Burns index and swaps assets to the output asset
    /// @param _params Contains the quotes for each asset, output asset and other details
    function _burn(BurnSwapParams calldata _params) internal {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);
        IIndex(_params.index).burn(address(this));

        (address[] memory assets, ) = IIndex(_params.index).anatomy();
        address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();

        uint assetsCount = assets.length;
        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        IPriceOracle priceOracle = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle());
        for (uint i; i < totalAssetsCount; ) {
            IERC20 inputAsset = IERC20(i < assetsCount ? assets[i] : inactiveAssets[i - assetsCount]);
            uint inputAssetBalanceBefore = inputAsset.balanceOf(address(this));
            // if asset is input asset no need to swap => (address(inputAsset) != _params.outputAsset)
            if (inputAssetBalanceBefore > 0 && address(inputAsset) != _params.outputAsset) {
                // if the amount of asset is less than minimum directly transfer to the user
                if (
                    inputAssetBalanceBefore.mulDiv(
                        FixedPoint112.Q112,
                        priceOracle.refreshedAssetPerBaseInUQ(address(inputAsset))
                    ) < MIN_SWAP_AMOUNT
                ) {
                    inputAsset.safeTransfer(_params.recipient, inputAssetBalanceBefore);
                }
                // otherwise exchange the asset for the desired output asset
                else {
                    address swapTarget = _params.quotes[i].swapTarget;
                    require(
                        IAccessControl(registry).hasRole(EXCHANGE_TARGET_ROLE, swapTarget),
                        "IndexRouter: INVALID_TARGET"
                    );
                    uint outputAssetBalanceBefore = IERC20(_params.outputAsset).balanceOf(address(this));

                    _safeApprove(address(inputAsset), swapTarget, inputAssetBalanceBefore);
                    _fillQuote(swapTarget, _params.quotes[i].assetQuote);

                    // checks if all input asset was exchanged and output asset generated from the swap is greater than minOutputAmount desired.
                    // it is important to estimate correctly the inputAmount for each asset for the index amount to burn,
                    // otherwise the transaction will revert due to over or under estimation.
                    // this ensures if all swaps are successful there is no leftover assets in indexRouter's ownership.
                    require(
                        IERC20(_params.outputAsset).balanceOf(address(this)) - outputAssetBalanceBefore >=
                            _params.quotes[i].buyAssetMinAmount,
                        "IndexRouter: INVALID_SWAP"
                    );
                }
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Fills the quote for the `_swapTarget` with the `quote`
    /// @param _swapTarget Swap target address
    /// @param _quote Quote to fill
    function _fillQuote(address _swapTarget, bytes memory _quote) internal {
        (bool success, bytes memory returnData) = _swapTarget.call(_quote);
        if (!success) {
            if (returnData.length == 0) {
                revert("IndexRouter: INVALID_SWAP");
            } else {
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            }
        }
    }

    /// @notice Approves the `_spender` to spend `_requiredAllowance` of `_token`
    /// @param _token Token address
    /// @param _spender Spender address
    /// @param _requiredAllowance Required allowance
    function _safeApprove(
        address _token,
        address _spender,
        uint _requiredAllowance
    ) internal {
        uint allowance = IERC20(_token).allowance(address(this), _spender);
        if (allowance < _requiredAllowance) {
            IERC20(_token).safeIncreaseAllowance(_spender, type(uint256).max - allowance);
        }
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override {
        require(IAccessControl(registry).hasRole(EXCHANGE_ADMIN_ROLE, msg.sender), "IndexRouter: FORBIDDEN");
    }

    uint256[44] private __gap;
}