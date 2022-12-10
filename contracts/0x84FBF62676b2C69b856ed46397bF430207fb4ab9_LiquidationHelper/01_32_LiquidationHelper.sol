// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./magicians/interfaces/IMagician.sol";
import "../SiloLens.sol";
import "../interfaces/ISiloFactory.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/ISiloRepository.sol";
import "../interfaces/IPriceProvidersRepository.sol";
import "../interfaces/IWrappedNativeToken.sol";
import "../priceProviders/chainlinkV3/ChainlinkV3PriceProvider.sol";

import "../lib/Ping.sol";
import "../lib/RevertBytes.sol";


/// @notice LiquidationHelper IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
/// see https://github.com/silo-finance/liquidation#readme for details how liquidation process should look like
contract LiquidationHelper is IFlashLiquidationReceiver, Ownable {
    using RevertBytes for bytes;
    using SafeERC20 for IERC20;
    using Address for address payable;

    struct MagicianConfig {
        address asset;
        IMagician magician;
    }

    struct SwapperConfig {
        IPriceProvider provider;
        ISwapper swapper;
    }

    uint256 immutable private _BASE_TX_COST; // solhint-disable-line var-name-mixedcase
    ISiloRepository public immutable SILO_REPOSITORY; // solhint-disable-line var-name-mixedcase
    IPriceProvidersRepository public immutable PRICE_PROVIDERS_REPOSITORY; // solhint-disable-line var-name-mixedcase
    SiloLens public immutable LENS; // solhint-disable-line var-name-mixedcase
    IERC20 public immutable QUOTE_TOKEN; // solhint-disable-line var-name-mixedcase

    ChainlinkV3PriceProvider public immutable CHAINLINK_PRICE_PROVIDER; // solhint-disable-line var-name-mixedcase

    mapping(IPriceProvider => ISwapper) public swappers;
    // asset => magician
    mapping(address => IMagician) public magicians;

    event LiquidationBalance(address user, uint256 quoteAmountFromCollaterals, uint256 quoteLeftAfterRepay);

    error InvalidSiloLens();
    error InvalidSiloRepository();
    error LiquidationNotProfitable(uint256 inTheRed);
    error NotSilo();
    error PriceProviderNotFound();
    error SwapperNotFound();
    error MagicianNotFound();
    error RepayFailed();
    error SwapAmountInFailed();
    error SwapAmountOutFailed();
    error UsersMustMatchSilos();
    error ApprovalFailed();
    error InvalidChainlinkProviders();
    error InvalidMagicianConfig();
    error InvalidSwapperConfig();
    error InvalidTowardsAssetConvertion();

    event SwapperConfigured(IPriceProvider provider, ISwapper swapper);
    event MagicianConfigured(address asset, IMagician magician);

    constructor (
        address _repository,
        address _chainlinkPriceProvider,
        address _lens,
        MagicianConfig[] memory _magicians,
        SwapperConfig[] memory _swappers,
        uint256 _baseCost
    ) {
        if (!Ping.pong(SiloLens(_lens).lensPing)) revert InvalidSiloLens();

        if (!Ping.pong(ISiloRepository(_repository).siloRepositoryPing)) {
            revert InvalidSiloRepository();
        }

        SILO_REPOSITORY = ISiloRepository(_repository);
        LENS = SiloLens(_lens);

        // configure swappers
        _configureSwappers(_swappers);
        // configure magicians
        _configureMagicians(_magicians);

        PRICE_PROVIDERS_REPOSITORY = ISiloRepository(_repository).priceProvidersRepository();

        CHAINLINK_PRICE_PROVIDER = ChainlinkV3PriceProvider(_chainlinkPriceProvider);

        QUOTE_TOKEN = IERC20(PRICE_PROVIDERS_REPOSITORY.quoteToken());
        _BASE_TX_COST = _baseCost;
    }

    receive() external payable {
        // we accept ETH so we can unwrap WETH
    }

    function executeLiquidation(address[] calldata _users, ISilo _silo, address /* _swapper */) external {
        _silo.flashLiquidate(_users, abi.encode(gasleft()));
    }

    function setSwappers(SwapperConfig[] memory _swappers) external onlyOwner {
        _configureSwappers(_swappers);
    }

    function setMagicians(MagicianConfig[] memory _magicians) external onlyOwner {
        _configureMagicians(_magicians);
    }

    /// @dev this is working example of how to perform liquidation, this method will be called by Silo
    ///         Keep in mind, that this helper might NOT choose the best swap option.
    ///         For best results (highest earnings) you probably want to implement your own callback and maybe use some
    ///         dex aggregators.
    function siloLiquidationCallback(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid,
        bytes memory _flashReceiverData
    ) external override {
        (uint256 gasStart) = abi.decode(_flashReceiverData, (uint256));

        uint256 quoteAmountFromCollaterals = _swapAllForQuote(_assets, _receivedCollaterals);
        uint256 quoteSpentOnRepay = _repay(ISilo(msg.sender), _user, _assets, _shareAmountsToRepaid);
        uint256 quoteLeftAfterRepay = quoteAmountFromCollaterals - quoteSpentOnRepay;

        unchecked {
            // gas calculation will not overflow because values are never that high
            // `gasStart` is external value, but it value that we initiating and Silo contract passing it to us
            uint256 gasSpent = gasStart - gasleft() + _BASE_TX_COST;
            uint256 txFee = tx.gasprice * gasSpent;

            if (quoteSpentOnRepay + txFee > quoteAmountFromCollaterals) {
                revert LiquidationNotProfitable(quoteSpentOnRepay + txFee - quoteAmountFromCollaterals);
            }
        }

        // We assume that quoteToken is wrapped native token
        IWrappedNativeToken(address(QUOTE_TOKEN)).withdraw(quoteLeftAfterRepay);

        payable(owner()).sendValue(quoteLeftAfterRepay);

        emit LiquidationBalance(_user, quoteAmountFromCollaterals, quoteLeftAfterRepay);
    }

    function checkSolvency(address[] memory _users, ISilo[] memory _silos) external view returns (bool[] memory) {
        if (_users.length != _silos.length) revert UsersMustMatchSilos();

        bool[] memory solvency = new bool[](_users.length);

        for (uint256 i; i < _users.length;) {
            solvency[i] = _silos[i].isSolvent(_users[i]);
            // we will never have that many users to overflow
            unchecked { i++; }
        }

        return solvency;
    }

    function checkDebt(address[] memory _users, ISilo[] memory _silos) external view returns (bool[] memory) {
        bool[] memory hasDebt = new bool[](_users.length);

        for (uint256 i; i < _users.length;) {
            hasDebt[i] = LENS.inDebt(_silos[i], _users[i]);
            // we will never have that many users to overflow
            unchecked { i++; }
        }

        return hasDebt;
    }

    function findPriceProvider(address _asset) public view returns (IPriceProvider) {
        IPriceProvider priceProvider = PRICE_PROVIDERS_REPOSITORY.priceProviders(_asset);

        if (priceProvider == CHAINLINK_PRICE_PROVIDER) {
            priceProvider = CHAINLINK_PRICE_PROVIDER.getFallbackProvider(_asset);
        }

        if (address(priceProvider) == address(0)) {
            revert PriceProviderNotFound();
        }

        return priceProvider;
    }

    function _swapAllForQuote(
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals
    ) internal returns (uint256 quoteAmount) {
        // swap all for quote token

        unchecked {
            // we will not overflow with `i` in a lifetime
            for (uint256 i = 0; i < _assets.length; i++) {
                // if silo was able to handle solvency calculations, then we can handle quoteAmount without safe math
                quoteAmount += _swapForQuote(_assets[i], _receivedCollaterals[i]);
            }
        }
    }

    function _repay(
        ISilo silo,
        address _user,
        address[] calldata _assets,
        uint256[] calldata _shareAmountsToRepaid
    ) internal returns (uint256 quoteSpendOnRepay) {
        if (!SILO_REPOSITORY.isSilo(address(silo))) revert NotSilo();

        for (uint256 i = 0; i < _assets.length;) {
            if (_shareAmountsToRepaid[i] == 0) {
                // we will never have that many assets to overflow
                unchecked { i++; }
                continue;
            }

            // if silo was able to handle solvency calculations, then we can handle amounts without safe math here
            unchecked {
                quoteSpendOnRepay += _swapForAsset(_assets[i], _shareAmountsToRepaid[i]);
            }

            _approve(_assets[i], address(silo), _shareAmountsToRepaid[i]);

            silo.repayFor(_assets[i], _user, _shareAmountsToRepaid[i]);

            // DEFLATIONARY TOKENS ARE NOT SUPPORTED
            // we are not using lower limits for swaps so we may not get enough tokens to do full repay
            // our assumption here is that `_shareAmountsToRepaid[i]` is total amount to repay the full debt
            // if after repay user has no debt in this asset, the swap is acceptable
            if (silo.assetStorage(_assets[i]).debtToken.balanceOf(_user) != 0) {
                revert RepayFailed();
            }

            // we will never have that many assets to overflow
            unchecked { i++; }
        }
    }

    /// @dev it swaps asset token for quote
    /// @param _asset address
    /// @param _amount exact amount of asset to swap
    /// @return amount of quote token
    function _swapForQuote(address _asset, uint256 _amount) internal returns (uint256) {
        address quoteToken = address(QUOTE_TOKEN);

        if (_amount == 0 || _asset == quoteToken) return _amount;

        address magician = address(magicians[_asset]);

        if (magician != address(0)) {
            bytes memory result = _sefeDelegateCall(
                magician,
                abi.encodeCall(IMagician.towardsNative, (_asset, _amount)),
                "towardsNativeFailed"
            );

            (address tokenOut, uint256 amountOut) = abi.decode(result, (address, uint256));

            return _swapForQuote(tokenOut, amountOut);
        }

        (IPriceProvider provider, ISwapper swapper) = _resolveProviderAndSwapper(_asset);

        // no need for safe approval, because we always using 100%
        _approve(_asset, swapper.spenderToApprove(), _amount);

        bytes memory callData = abi.encodeCall(ISwapper.swapAmountIn, (
            _asset, quoteToken, _amount, address(provider), _asset
        ));

        bytes memory data = _sefeDelegateCall(address(swapper), callData, "swapAmountIn");

        return abi.decode(data, (uint256));
    }

    /// @dev it swaps quote token for asset
    /// @param _asset address
    /// @param _amount exact amount OUT, what we want to receive
    /// @return amount of quote token used for swap
    function _swapForAsset(address _asset, uint256 _amount) internal returns (uint256) {
        address quoteToken = address(QUOTE_TOKEN);

        if (_amount == 0 || quoteToken == _asset) return _amount;

        address magician = address(magicians[_asset]);

        if (magician != address(0)) {
            bytes memory result = _sefeDelegateCall(
                magician,
                abi.encodeCall(IMagician.towardsAsset, (_asset, _amount)),
                "towardsAssetFailed"
            );

            (address tokenOut, uint256 amountOut) = abi.decode(result, (address, uint256));

            // towardsAsset should convert to `_asset`
            if (tokenOut != _asset) revert InvalidTowardsAssetConvertion();

            return amountOut;
        }

        (IPriceProvider provider, ISwapper swapper) = _resolveProviderAndSwapper(_asset);

        address spender = swapper.spenderToApprove();

        _approve(quoteToken, spender, type(uint256).max);

        bytes memory callData = abi.encodeCall(ISwapper.swapAmountOut, (
            quoteToken, _asset, _amount, address(provider), _asset
        ));

        bytes memory data = _sefeDelegateCall(address(swapper), callData, "SwapAmountOutFailed");

        _approve(quoteToken, spender, 0);

        return abi.decode(data, (uint256));
    }

    function _resolveProviderAndSwapper(address _asset) internal view returns (IPriceProvider, ISwapper) {
        IPriceProvider priceProvider = findPriceProvider(_asset);

        ISwapper swapper = _resolveSwapper(priceProvider);

        return (priceProvider, swapper);
    }

    function _resolveSwapper(IPriceProvider priceProvider) internal view returns (ISwapper) {
        ISwapper swapper = swappers[priceProvider];

        if (address(swapper) == address(0)) {
            revert SwapperNotFound();
        }

        return swapper;
    }

    function _approve(address _asset, address _to, uint256 _amount) internal {
        if (!IERC20(_asset).approve(_to, _amount)) {
            revert ApprovalFailed();
        }
    }

    function _sefeDelegateCall(
        address _target,
        bytes memory _callData,
        string memory _mgs
    )
        internal
        returns (bytes memory data)
    {
        bool success;
        // solhint-disable-next-line avoid-low-level-calls
        (success, data) = address(_target).delegatecall(_callData);
        if (!success || data.length == 0) data.revertBytes(_mgs);
    }

    function _configureSwappers(SwapperConfig[] memory _swappers) internal {
        for (uint256 i = 0; i < _swappers.length; i++) {
            IPriceProvider provider = _swappers[i].provider;
            ISwapper swapper = _swappers[i].swapper;

            if (address(provider) == address(0) || address(swapper) == address(0)) {
                revert InvalidSwapperConfig();
            }

            swappers[provider] = swapper;

            emit SwapperConfigured(provider, swapper);
        }
    }

    function _configureMagicians(MagicianConfig[] memory _magicians) internal {
        for (uint256 i = 0; i < _magicians.length; i++) {
            address asset = _magicians[i].asset;
            IMagician magician = _magicians[i].magician;

            if (asset == address(0) || address(magician) == address(0)) {
                revert InvalidMagicianConfig();
            }

            magicians[asset] = magician;

            emit MagicianConfigured(asset, magician);
        }
    }
}