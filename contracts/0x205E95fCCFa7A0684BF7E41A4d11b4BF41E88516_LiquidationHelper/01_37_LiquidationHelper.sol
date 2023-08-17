// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./magicians/interfaces/IMagician.sol";
import "../SiloLens.sol";
import "../interfaces/ISiloFactory.sol";
import "../interfaces/IPriceProviderV2.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/ISiloRepository.sol";
import "../interfaces/IPriceProvidersRepository.sol";
import "../interfaces/IWrappedNativeToken.sol";
import "../priceProviders/chainlinkV3/ChainlinkV3PriceProvider.sol";

import "../lib/Ping.sol";
import "../lib/RevertBytes.sol";
import "./ZeroExSwap.sol";
import "./lib/LiquidationScenarioDetector.sol";
import "./LiquidationRepay.sol";

/// @notice LiquidationHelper IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
/// see https://github.com/silo-finance/liquidation#readme for details how liquidation process should look like
contract LiquidationHelper is ILiquidationHelper, IFlashLiquidationReceiver, ZeroExSwap, LiquidationRepay {
    using RevertBytes for bytes;
    using SafeERC20 for IERC20;
    using Address for address payable;
    using LiquidationScenarioDetector for LiquidationScenario;

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

    error InvalidSiloLens();
    error InvalidSiloRepository();
    error LiquidationNotProfitable(uint256 inTheRed);
    error NotSilo();
    error PriceProviderNotFound();
    error FallbackPriceProviderNotSet();
    error SwapperNotFound();
    error MagicianNotFound();
    error SwapAmountInFailed();
    error SwapAmountOutFailed();
    error UsersMustMatchSilos();
    error InvalidChainlinkProviders();
    error InvalidMagicianConfig();
    error InvalidSwapperConfig();
    error InvalidTowardsAssetConvertion();
    error InvalidScenario();
    error Max0xSwapsIs2();

    event SwapperConfigured(IPriceProvider provider, ISwapper swapper);
    event MagicianConfigured(address asset, IMagician magician);
    
    /// @dev event emitted on user liquidation
    /// @param silo Silo where liquidation happen
    /// @param user User that been liquidated
    /// @param earned amount of ETH earned (excluding gas cost)
    /// @param estimatedEarnings for LiquidationScenario.Full0xWithChange `earned` amount is estimated,
    /// because tokens were not sold for ETH inside transaction
    event LiquidationExecuted(address indexed silo, address indexed user, uint256 earned, bool estimatedEarnings);

    constructor (
        address _repository,
        address _chainlinkPriceProvider,
        address _lens,
        address _exchangeProxy,
        MagicianConfig[] memory _magicians,
        SwapperConfig[] memory _swappers,
        uint256 _baseCost
    ) ZeroExSwap(_exchangeProxy) {
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

    receive() external payable {}

    function executeLiquidation(
        address _user,
        ISilo _silo,
        LiquidationScenario _scenario,
        SwapInput0x[] calldata _swapsInputs0x
    ) external {
        if (_swapsInputs0x.length > 2) revert Max0xSwapsIs2();

        uint256 gasStart = gasleft();
        address[] memory users = new address[](1);
        users[0] = _user;

        _silo.flashLiquidate(users, abi.encode(msg.sender, gasStart, _scenario, _swapsInputs0x));
    }

    function setSwappers(SwapperConfig[] calldata _swappers) external onlyOwner {
        _configureSwappers(_swappers);
    }

    function setMagicians(MagicianConfig[] calldata _magicians) external onlyOwner {
        _configureMagicians(_magicians);
    }

    /// @notice this is working example of how to perform liquidation, this method will be called by Silo
    /// Keep in mind, that this helper might NOT choose the best swap option.
    /// For best results (highest earnings) you probably want to implement your own callback and maybe use some
    /// dex aggregators.
    /// @dev after liquidation we always send remaining tokens so contract should never has any leftover
    function siloLiquidationCallback(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid,
        bytes calldata _flashReceiverData
    ) external override {
        if (!SILO_REPOSITORY.isSilo(msg.sender)) revert NotSilo();

        (
            address payable executor,
            uint256 gasStart,
            LiquidationScenario scenario,
            SwapInput0x[] memory swapInputs
        ) = abi.decode(_flashReceiverData, (address, uint256, LiquidationScenario, SwapInput0x[]));

        if (swapInputs.length != 0) {
            _execute0x(swapInputs);
        }

        uint256 earned = _siloLiquidationCallbackExecution(
            scenario,
            _user,
            _assets,
            _receivedCollaterals,
            _shareAmountsToRepaid
        );

        // I needed to move some part of execution from from `_siloLiquidationCallbackExecution`,
        // because of "stack too deep" error
        bool isFull0xWithChange = scenario.isFull0xWithChange();
        bool calculateEarnings = scenario.calculateEarnings();

        if (isFull0xWithChange) {
            earned = _estimateEarningsAndTransferChange(_assets, _shareAmountsToRepaid, executor, calculateEarnings);
        } else {
            _transferNative(executor, earned);
        }

        emit LiquidationExecuted(msg.sender, _user, earned, isFull0xWithChange);

        // do not check for profitability when forcing
        if (calculateEarnings) {
            ensureTxIsProfitable(gasStart, earned);
        }
    }

    /// @dev This method should be used to made decision about `Full0x` vs `Full0xWithChange` liquidation scenario.
    /// @return TRUE, if asset liquidation is supported internally, otherwise FALSE
    function liquidationSupported(address _asset) external view returns (bool) {
        if (_asset == address(QUOTE_TOKEN)) return true;
        if (address(magicians[_asset]) != address(0)) return true;

        try this.findPriceProvider(_asset) returns (IPriceProvider) {
            return true;
        } catch (bytes memory) {
            // we do not care about reason
        }

        return false;
    }

    function checkSolvency(address[] calldata _users, ISilo[] calldata _silos) external view returns (bool[] memory) {
        if (_users.length != _silos.length) revert UsersMustMatchSilos();

        bool[] memory solvency = new bool[](_users.length);

        for (uint256 i; i < _users.length;) {
            solvency[i] = _silos[i].isSolvent(_users[i]);
            // we will never have that many users to overflow
            unchecked { i++; }
        }

        return solvency;
    }

    function checkDebt(address[] calldata _users, ISilo[] calldata _silos) external view returns (bool[] memory) {
        bool[] memory hasDebt = new bool[](_users.length);

        for (uint256 i; i < _users.length;) {
            hasDebt[i] = LENS.inDebt(_silos[i], _users[i]);
            // we will never have that many users to overflow
            unchecked { i++; }
        }

        return hasDebt;
    }

    function ensureTxIsProfitable(uint256 _gasStart, uint256 _earnedEth) public view returns (uint256 txFee) {
        unchecked {
            // gas calculation will not overflow because values are never that high
            // `gasStart` is external value, but it value that we initiating and Silo contract passing it to us
            uint256 gasSpent = _gasStart - gasleft() + _BASE_TX_COST;
            txFee = tx.gasprice * gasSpent;

            if (txFee > _earnedEth) {
                // it will not underflow because we check above
                revert LiquidationNotProfitable(txFee - _earnedEth);
            }
        }
    }

    function findPriceProvider(address _asset) public view returns (IPriceProvider priceProvider) {
        priceProvider = PRICE_PROVIDERS_REPOSITORY.priceProviders(_asset);

        if (address(priceProvider) == address(0)) revert PriceProviderNotFound();

        // check for backwards compatibility with chainlink provider
        if (priceProvider == CHAINLINK_PRICE_PROVIDER) {
            priceProvider = CHAINLINK_PRICE_PROVIDER.getFallbackProvider(_asset);
            if (address(priceProvider) == address(0)) revert FallbackPriceProviderNotSet();
            return priceProvider;
        }

        // only IPriceProviderV2 has `IPriceProviderV2()`
        try IPriceProviderV2(address(priceProvider)).offChainProvider() returns (bool isOffChainProvider) {
            if (isOffChainProvider) {
                priceProvider = IPriceProviderV2(address(priceProvider)).getFallbackProvider(_asset);
                if (address(priceProvider) == address(0)) revert FallbackPriceProviderNotSet();
            }
        } catch (bytes memory) {}
    }

    function _execute0x(SwapInput0x[] memory _swapInputs) internal {
        for (uint256 i; i < _swapInputs.length;) {
            fillQuote(_swapInputs[i].sellToken, _swapInputs[i].allowanceTarget, _swapInputs[i].swapCallData);
            // we can not have that much data in array to overflow
            unchecked { i++; }
        }
    }

    function _siloLiquidationCallbackExecution(
        LiquidationScenario _scenario,
        address _user,
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid
    ) internal returns (uint256 earned) {
        if (_scenario.isFull0x()) {
            return _runFull0xScenario(
                _user,
                _assets,
                _shareAmountsToRepaid
            );
        }

        if (_scenario.isInternal()) {
            return _runInternalScenario(
                _user,
                _assets,
                _receivedCollaterals,
                _shareAmountsToRepaid
            );
        }

        if (_scenario.isFull0xWithChange()) {
            // we should have repay tokens ready to repay
            _repay(ISilo(msg.sender), _user, _assets, _shareAmountsToRepaid);
            // change that left after repay will be send to `_liquidator` by `_estimateEarningsAndTransferChange`
            return 0;
        }

        if (_scenario.isCollateral0x()) {
            return _runCollateral0xScenario(
                _user,
                _assets,
                _shareAmountsToRepaid
            );
        }

        revert InvalidScenario();
    }

    function _runFull0xScenario(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _shareAmountsToRepaid
    ) internal returns (uint256 earned) {
        // we should have repay tokens ready to repay
        _repay(ISilo(msg.sender), _user, _assets, _shareAmountsToRepaid);

        // we left with some change, let's try to swap to WETH
        earned = _swapAssetsForQuote(_assets, _shareAmountsToRepaid);
    }

    function _runCollateral0xScenario(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _shareAmountsToRepaid
    ) internal returns (uint256 earned) {
        // we have WETH, we need to deal with swap WETH -> repay asset internally
        _swapWrappedNativeForRepayAssets(_assets, _shareAmountsToRepaid);

        _repay(ISilo(msg.sender), _user, _assets, _shareAmountsToRepaid);

        earned = QUOTE_TOKEN.balanceOf(address(this));
    }

    function _runInternalScenario(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid
    ) internal returns (uint256 earned) {
        uint256 quoteAmountFromCollaterals = _swapAllForQuote(_assets, _receivedCollaterals);
        uint256 quoteSpentOnRepay = _swapWrappedNativeForRepayAssets(_assets, _shareAmountsToRepaid);

        _repay(ISilo(msg.sender), _user, _assets, _shareAmountsToRepaid);
        earned = quoteAmountFromCollaterals - quoteSpentOnRepay;
    }

    function _estimateEarningsAndTransferChange(
        address[] calldata _assets,
        uint256[] calldata _shareAmountsToRepaid,
        address payable _liquidator,
        bool _returnEarnedAmount
    ) internal returns (uint256 earned) {
        // change that left after repay will be send to `_liquidator`
        for (uint256 i = 0; i < _assets.length;) {
            if (_shareAmountsToRepaid[i] != 0) {
                uint256 amount = IERC20(_assets[i]).balanceOf(address(this));

                if (_assets[i] == address(QUOTE_TOKEN)) {
                    if (_returnEarnedAmount) {
                        // balance will not overflow
                        unchecked { earned += amount; }
                    }

                    _transferNative(_liquidator, amount);
                } else {
                    if (_returnEarnedAmount) {
                        // we processing numbers that Silo created, if Silo did not over/under flow, we will not as well
                        unchecked { earned += amount * PRICE_PROVIDERS_REPOSITORY.getPrice(_assets[i]) / 1e18; }
                    }

                    IERC20(_assets[i]).transfer(_liquidator, amount);
                }
            }

            // we will never have that many assets to overflow
            unchecked { i++; }
        }
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

    function _swapWrappedNativeForRepayAssets(
        address[] calldata _assets,
        uint256[] calldata _shareAmountsToRepaid
    ) internal returns (uint256 quoteSpendOnRepay) {
        for (uint256 i = 0; i < _assets.length;) {
            if (_shareAmountsToRepaid[i] != 0) {
                // if silo was able to handle solvency calculations, then we can handle amounts without safe math here
                unchecked {
                    quoteSpendOnRepay += _swapForAsset(_assets[i], _shareAmountsToRepaid[i]);
                }
            }

            // we will never have that many assets to overflow
            unchecked { i++; }
        }
    }

    /// @notice We assume that quoteToken is wrapped native token
    function _transferNative(address payable _to, uint256 _amount) internal {
        IWrappedNativeToken(address(QUOTE_TOKEN)).withdraw(_amount);
        _to.sendValue(_amount);
    }

    function _swapAssetsForQuote(
        address[] calldata _assets,
        uint256[] calldata _amounts
    ) internal returns (uint256 received) {
        for (uint256 i = 0; i < _assets.length;) {
            if (_amounts[i] != 0) {
                uint256 amount = IERC20(_assets[i]).balanceOf(address(this));
                received += _swapForQuote(_assets[i], amount);
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
            bytes memory result = _safeDelegateCall(
                magician,
                abi.encodeCall(IMagician.towardsNative, (_asset, _amount)),
                "towardsNativeFailed"
            );

            (address tokenOut, uint256 amountOut) = abi.decode(result, (address, uint256));

            return _swapForQuote(tokenOut, amountOut);
        }

        (IPriceProvider provider, ISwapper swapper) = _resolveProviderAndSwapper(_asset);

        // no need for safe approval, because we always using 100%
        // Low level call needed to support non-standard `ERC20.approve` eg like `USDT.approve`
        // solhint-disable-next-line avoid-low-level-calls
        _asset.call(abi.encodeCall(IERC20.approve, (swapper.spenderToApprove(), _amount)));

        bytes memory callData = abi.encodeCall(ISwapper.swapAmountIn, (
            _asset, quoteToken, _amount, address(provider), _asset
        ));

        bytes memory data = _safeDelegateCall(address(swapper), callData, "swapAmountIn");

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
            bytes memory result = _safeDelegateCall(
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

        IERC20(quoteToken).approve(spender, type(uint256).max);

        bytes memory callData = abi.encodeCall(ISwapper.swapAmountOut, (
            quoteToken, _asset, _amount, address(provider), _asset
        ));

        bytes memory data = _safeDelegateCall(address(swapper), callData, "SwapAmountOutFailed");

        IERC20(quoteToken).approve(spender, 0);

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

    function _safeDelegateCall(
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