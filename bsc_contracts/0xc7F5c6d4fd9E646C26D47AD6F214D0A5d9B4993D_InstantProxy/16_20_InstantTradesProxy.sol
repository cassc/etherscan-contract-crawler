pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import 'rubic-bridge-base/contracts/errors/Errors.sol';
import 'rubic-bridge-base/contracts/BridgeBase.sol';
import 'rubic-whitelist-contract/contracts/interfaces/IRubicWhitelist.sol';

error DexNotAvailable();
error DifferentAmountSpent();
error TooFewReceived();
error ZeroToken();
error NotANativeToken();

contract InstantProxy is BridgeBase {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IRubicWhitelist public whitelistRegistry;

    struct InstantTradesParams {
        address inputToken;
        uint256 inputAmount;
        address outputToken;
        uint256 minOutputAmount;
        address recipient;
        address integrator;
        address dex;
    }

    event DexSwap(InstantTradesParams parameters);

    modifier onlyAvailableDex(address _dex) {
        checkDex(_dex);
        _;
    }

    function checkDex(address _dex) private view {
        if (!whitelistRegistry.isWhitelistedDEX(_dex)) revert DexNotAvailable();
    }

    constructor(
        uint256 _fixedCryptoFee,
        uint256 _RubicPlatformFee,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts,
        address _admin,
        IRubicWhitelist _whitelistRegistry
    ) {
        if (address(_whitelistRegistry) == address(0)) {
            revert ZeroAddress();
        }

        whitelistRegistry = _whitelistRegistry;

        initialize(_fixedCryptoFee, _RubicPlatformFee, _tokens, _minTokenAmounts, _maxTokenAmounts, _admin);
    }

    function initialize(
        uint256 _fixedCryptoFee,
        uint256 _RubicPlatformFee,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts,
        address _admin
    ) private initializer {
        __BridgeBaseInit(_fixedCryptoFee, _RubicPlatformFee, _tokens, _minTokenAmounts, _maxTokenAmounts, _admin);
    }

    // MAIN FUNCTIONALITY //

    /**
     * @dev Performs an instant trade from users ERC-20 tokens
     * @param _params Info about the trade
     * @param _data The data passed to the DEX
     */
    function instantTrade(
        InstantTradesParams memory _params,
        bytes calldata _data
    ) external payable nonReentrant whenNotPaused onlyAvailableDex(_params.dex) {
        _params.inputAmount = _receiveTokens(_params.inputToken, _params.inputAmount);

        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.inputAmount = accrueTokenFees(_params.integrator, _info, _params.inputAmount, 0, _params.inputToken);

        accrueFixedCryptoFee(_params.integrator, _info);

        _callDexWithChecksTokenInput(_params, _data);

        emit DexSwap(_params);
    }

    /**
     * @dev Performs an instant trade from users native tokens
     * @param _params Info about the trade
     * @param _data The data passed to the DEX
     */
    function instantTradeNative(
        InstantTradesParams memory _params,
        bytes calldata _data
    ) external payable nonReentrant whenNotPaused onlyAvailableDex(_params.dex) {
        if (_params.inputToken != address(0)) revert NotANativeToken();

        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.inputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            accrueFixedCryptoFee(_params.integrator, _info),
            0,
            _params.inputToken
        );

        _callDexWithChecksNativeInput(_params, _data);

        emit DexSwap(_params);
    }

    function _callDexWithChecksNativeInput(InstantTradesParams memory _params, bytes calldata _data) private {
        uint256 balanceOutBefore = _getBalance(_params.recipient, _params.outputToken);

        AddressUpgradeable.functionCallWithValue(_params.dex, _data, _params.inputAmount);

        uint256 balanceOutAfter = _getBalance(_params.recipient, _params.outputToken);

        if (balanceOutAfter - balanceOutBefore < _params.minOutputAmount) revert TooFewReceived();
    }

    function _callDexWithChecksTokenInput(InstantTradesParams memory _params, bytes calldata _data) private {
        IERC20Upgradeable(_params.inputToken).safeApprove(_params.dex, _params.inputAmount);

        uint256 balanceOutBefore = _getBalance(_params.recipient, _params.outputToken);
        uint256 balanceInBefore = IERC20Upgradeable(_params.inputToken).balanceOf(address(this));

        AddressUpgradeable.functionCall(_params.dex, _data);

        uint256 balanceOutAfter = _getBalance(_params.recipient, _params.outputToken);
        uint256 balanceInAfter = IERC20Upgradeable(_params.inputToken).balanceOf(address(this));

        if (balanceInBefore - balanceInAfter != _params.inputAmount) revert DifferentAmountSpent();
        if (balanceOutAfter - balanceOutBefore < _params.minOutputAmount) revert TooFewReceived();
    }

    function _receiveTokens(address _tokenIn, uint256 _amountIn) private returns (uint256) {
        if (_tokenIn == address(0)) revert ZeroToken();

        uint256 balanceBeforeTransfer = IERC20Upgradeable(_tokenIn).balanceOf(address(this));

        IERC20Upgradeable(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);

        uint256 balanceAfterTransfer = IERC20Upgradeable(_tokenIn).balanceOf(address(this));

        _amountIn = balanceAfterTransfer - balanceBeforeTransfer;

        return _amountIn;
    }

    function _getBalance(address _wallet, address _token) private view returns (uint256) {
        return _token == address(0) ? address(_wallet).balance : IERC20Upgradeable(_token).balanceOf(_wallet);
    }

    // MANAGEMENT FUNCTIONS //

    /**
     * @dev Sets the address of a new whitelist registry contract
     * @param _newWhitelistRegistry The address of the registry
     */
    function setWhitelistRegistry(IRubicWhitelist _newWhitelistRegistry) external onlyAdmin {
        if (address(_newWhitelistRegistry) == address(0)) {
            revert ZeroAddress();
        }

        whitelistRegistry = _newWhitelistRegistry;
    }
}