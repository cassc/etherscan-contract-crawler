// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../SiloLens.sol";
import "../interfaces/ISiloFactory.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/ISiloRepository.sol";
import "../interfaces/IPriceProvidersRepository.sol";
import "../interfaces/IWrappedNativeToken.sol";

import "../lib/Ping.sol";


/// @notice LiquidationHelper IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
/// see https://github.com/silo-finance/liquidation#readme for details how liquidation process should look like
contract LiquidationHelper is IFlashLiquidationReceiver, Ownable {
    bytes4 constant private _SWAP_AMOUNT_IN_SELECTOR =
        bytes4(keccak256("swapAmountIn(address,address,uint256,address,address)"));

    bytes4 constant private _SWAP_AMOUNT_OUT_SELECTOR =
        bytes4(keccak256("swapAmountOut(address,address,uint256,address,address)"));

    uint256 immutable private _baseTxCost;
    ISiloRepository public immutable siloRepository;
    SiloLens public immutable lens;
    IERC20 public immutable quoteToken;

    mapping(address => uint256) public earnings;
    mapping(IPriceProvider => ISwapper) public swappers;

    IPriceProvider[] public priceProvidersWithSwapOption;

    event LiquidationBalance(address user, uint256 quoteAmountFromCollaterals, uint256 quoteLeftAfterRepay);

    error InvalidSiloLens();
    error InvalidSiloRepository();
    error LiquidationNotProfitable(uint256 inTheRed);
    error NotSilo();
    error PriceProviderNotFound();
    error RepayFailed();
    error SwapAmountInFailed();
    error SwapAmountOutFailed();
    error SwappersMustMatchProviders();
    error UsersMustMatchSilos();

    constructor (
        address _repository,
        address _lens,
        IPriceProvider[] memory _priceProvidersWithSwapOption,
        ISwapper[] memory _swappers,
        uint256 _baseCost
    ) {
        if (!Ping.pong(SiloLens(_lens).lensPing)) revert InvalidSiloLens();

        if (!Ping.pong(ISiloRepository(_repository).siloRepositoryPing)) {
            revert InvalidSiloRepository();
        }

        if (_swappers.length != _priceProvidersWithSwapOption.length) {
            revert SwappersMustMatchProviders();
        }

        siloRepository = ISiloRepository(_repository);
        lens = SiloLens(_lens);

        for (uint256 i = 0; i < _swappers.length; i++) {
            swappers[_priceProvidersWithSwapOption[i]] = _swappers[i];
        }

        priceProvidersWithSwapOption = _priceProvidersWithSwapOption;

        IPriceProvidersRepository priceProviderRepo = ISiloRepository(_repository).priceProvidersRepository();
        quoteToken = IERC20(priceProviderRepo.quoteToken());
        _baseTxCost = _baseCost;
    }

    receive() external payable {
        // we accepting ETH receive, so we can unwrap WETH
    }

    function withdraw() external {
        _withdraw(msg.sender);
    }

    function withdrawFor(address _account) external {
        _withdraw(_account);
    }

    function withdrawEth() external {
        _withdrawEth(msg.sender);
    }

    function withdrawEthFor(address _account) external {
        _withdrawEth(_account);
    }

    /// @param _swapper address of swapper contract, must follow ISwapper interface.
    /// If provided, it will be used for all users and all assets.
    /// If empty swapper will be chosen automatically for every asset based on registered swappers.
    function executeLiquidation(address[] calldata _users, ISilo _silo, address _swapper) external {
        uint256 gasStart = gasleft();
        _silo.flashLiquidate(_users, abi.encode(gasStart, _swapper));
    }

    function setSwapper(IPriceProvider _oracle, ISwapper _swapper) external onlyOwner {
        swappers[_oracle] = _swapper;
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
        (uint256 gasStart, address swapperAddr) = abi.decode(_flashReceiverData, (uint256, address));

        uint256 quoteAmountFromCollaterals = _swapAllForQuote(_assets, _receivedCollaterals, swapperAddr);
        uint256 quoteSpentOnRepay = _repay(ISilo(msg.sender), _user, _assets, _shareAmountsToRepaid, swapperAddr);
        uint256 gasSpend = gasStart - gasleft() - _baseTxCost;

        if (quoteSpentOnRepay + gasSpend > quoteAmountFromCollaterals) {
            revert LiquidationNotProfitable(quoteSpentOnRepay + gasSpend - quoteAmountFromCollaterals);
        }

        uint256 quoteLeftAfterRepay = quoteAmountFromCollaterals - quoteSpentOnRepay;

        // we do not subtract gas, because this is amount of tokens to withdraw
        // net earnings = earnings - gas used
        earnings[owner()] += quoteLeftAfterRepay;

        emit LiquidationBalance(_user, quoteAmountFromCollaterals, quoteLeftAfterRepay);
    }

    function priceProvidersWithSwapOptionCount() external view returns (uint256) {
        return priceProvidersWithSwapOption.length;
    }

    function checkSolvency(address[] memory _users, ISilo[] memory _silos) external view returns (bool[] memory) {
        if (_users.length != _silos.length) revert UsersMustMatchSilos();

        bool[] memory solvency = new bool[](_users.length);

        for (uint256 i; i < _users.length; i++) {
            solvency[i] = _silos[i].isSolvent(_users[i]);
        }

        return solvency;
    }

    function checkDebt(address[] memory _users, ISilo[] memory _silos) external view returns (bool[] memory) {
        bool[] memory hasDebt = new bool[](_users.length);

        for (uint256 i; i < _users.length; i++) {
            hasDebt[i] = lens.inDebt(_silos[i], _users[i]);
        }

        return hasDebt;
    }

    function findPriceProvider(address _asset) public view returns (IPriceProvider) {
        IPriceProvider[] memory providers = priceProvidersWithSwapOption;

        for (uint256 i = 0; i < providers.length; i++) {
            IPriceProvider provider = providers[i];
            if (provider.assetSupported(_asset)) return provider;
        }

        revert PriceProviderNotFound();
    }

    function _swapAllForQuote(
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        address swapperAddr
    ) internal returns (uint256 quoteAmount) {
        // swap all for quote token
        // if silo was able to handle solvency calculations, then we can handle them without safe math here
        unchecked {
            for (uint256 i = 0; i < _assets.length; i++) {
                quoteAmount += _swapForQuote(_assets[i], _receivedCollaterals[i], swapperAddr);
            }
        }
    }

    function _repay(
        ISilo silo,
        address _user,
        address[] calldata _assets,
        uint256[] calldata _shareAmountsToRepaid,
        address swapperAddr
    ) internal returns (uint256 quoteSpendOnRepay) {
        if (!siloRepository.isSilo(address(silo))) revert NotSilo();

        for (uint256 i = 0; i < _assets.length; i++) {
            if (_shareAmountsToRepaid[i] == 0) continue;

            // if silo was able to handle solvency calculations, then we can handle amounts without safe math here
            unchecked {
                quoteSpendOnRepay += _swapForAsset(_assets[i], _shareAmountsToRepaid[i], swapperAddr);
            }

            IERC20(_assets[i]).approve(address(silo), _shareAmountsToRepaid[i]);
            silo.repayFor(_assets[i], _user, _shareAmountsToRepaid[i]);

            // DEFLATIONARY TOKENS ARE NOT SUPPORTED
            // we are not using lower limits for swaps so we may not get enough tokens to do full repay
            // our assumption here is that `_shareAmountsToRepaid[i]` is total amount to repay the full debt
            // if after repay user has no debt in this asset, the swap is acceptable
            if (silo.assetStorage(_assets[i]).debtToken.balanceOf(_user) != 0) {
                revert RepayFailed();
            }
        }
    }

    /// @dev it swaps asset token for quote
    /// @param _asset address
    /// @param _amount exact amount of asset to swap
    /// @param _swapper contract that will be used for swapping asset for quote
    /// @return amount of quote token
    function _swapForQuote(address _asset, uint256 _amount, address _swapper) internal returns (uint256) {
        if (_amount == 0 || _asset == address(quoteToken)) return _amount;

        bytes memory callData = abi.encodeWithSelector(
            _SWAP_AMOUNT_IN_SELECTOR,
            _asset,
            quoteToken,
            _amount,
            findPriceProvider(_asset),
            _asset
        );

        ISwapper swapper = _resolveSwapper(_asset, _swapper);

        // no need for safe approval, because we always using 100%
        IERC20(_asset).approve(swapper.spenderToApprove(), _amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(swapper).delegatecall(callData);
        if (!success) revert SwapAmountInFailed();

        return abi.decode(data, (uint256));
    }

    /// @dev it swaps quote token for asset
    /// @param _asset address
    /// @param _amount exact amount OUT, what we want to receive
    /// @param _swapper contract that will be used for swapping quote for asset
    /// @return amount of quote token used for swap
    function _swapForAsset(address _asset, uint256 _amount, address _swapper) internal returns (uint256) {
        if (_amount == 0 || address(quoteToken) == _asset) return _amount;

        bytes memory callData = abi.encodeWithSelector(
            _SWAP_AMOUNT_OUT_SELECTOR,
            quoteToken,
            _asset,
            _amount,
            findPriceProvider(_asset),
            _asset
        );


        ISwapper swapper = _resolveSwapper(_asset, _swapper);
        address spender = swapper.spenderToApprove();
        IERC20(quoteToken).approve(spender, type(uint256).max);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(swapper).delegatecall(callData);
        if (!success) revert SwapAmountOutFailed();

        IERC20(quoteToken).approve(spender, 0);

        return abi.decode(data, (uint256));
    }

    function _resolveSwapper(address _asset, address _swapper) internal view returns (ISwapper) {
        if (address(_swapper) != address(0)) return ISwapper(_swapper);

        IPriceProvider priceProvider = findPriceProvider(_asset);
        return swappers[priceProvider];
    }

    function _withdraw(address _account) internal {
        uint256 amount = earnings[_account];
        if (amount == 0) return;

        earnings[_account] = 0;
        quoteToken.transfer(_account, amount);
    }

    function _withdrawEth(address _account) internal {
        uint256 amount = earnings[_account];
        if (amount == 0) return;

        earnings[_account] = 0;
        IWrappedNativeToken(address(quoteToken)).withdraw(amount);
        payable(_account).transfer(amount);
    }
}