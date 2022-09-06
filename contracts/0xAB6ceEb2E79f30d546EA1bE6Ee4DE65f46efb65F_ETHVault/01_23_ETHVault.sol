// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
/**
 * @title  Vault Contract
 * @notice The Vault contract defines the storage for the Vault contracts
 * @author BankOfChain Protocol Inc
 */

import "./ETHVaultStorage.sol";
import "../strategies/IETHStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ETHVault is ETHVaultStorage {
    using StableMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableIntMap for IterableIntMap.AddressToIntMap;

    function initialize(
        address _accessControlProxy,
        address _treasury,
        address _exchangeManager,
        address _priceProvider
    ) public initializer {
        _initAccessControl(_accessControlProxy);

        treasury = _treasury;
        exchangeManager = _exchangeManager;
        priceProvider = _priceProvider;
        // 1 / 1000e4
        rebaseThreshold = 1;
        // one week
        maxTimestampBetweenTwoReported = 604800;
        underlyingUnitsPerShare = 1e18;
        minCheckedStrategyTotalDebt = 1e17;
    }

    modifier whenNotEmergency() {
        require(!emergencyShutdown, "ES");
        _;
    }

    modifier whenNotAdjustPosition() {
        require(!adjustPositionPeriod, "AD");
        _;
    }

    /**
     * @dev Verifies that the rebasing is not paused.
     */
    modifier whenNotRebasePaused() {
        require(!rebasePaused, "RP");
        _;
    }

    modifier isActiveStrategy(address _strategy) {
        checkActiveStrategy(_strategy);
        _;
    }

    /// @notice Version of vault
    function getVersion() external pure returns (string memory) {
        return "1.1.0";
    }

    /// @notice Minting ETHi supported assets
    function getSupportAssets() external view returns (address[] memory) {
        return assetSet.values();
    }

    /// @notice Check '_asset' is supported or not
    function checkIsSupportAsset(address _asset) public view {
        require(assetSet.contains(_asset), "The asset not support");
    }

    /// @notice Assets held by Vault
    function getTrackedAssets() external view returns (address[] memory) {
        return _getTrackedAssets();
    }

    /// @notice Vault holds asset value directly in ETH (1e18)
    function valueOfTrackedTokens() external view returns (uint256) {
        return _totalAssetInVault();
    }

    /// @notice Vault and vault buffer holds asset value directly ETH (1e18)
    function valueOfTrackedTokensIncludeVaultBuffer() external view returns (uint256) {
        return _totalAssetInVaultAndVaultBuffer();
    }

    /// @notice Vault total asset in ETH(1e18)
    function totalAssets() external view returns (uint256) {
        return _getTotalAssets();
    }

    /// @notice Vault and vault buffer total asset in USD
    function totalAssetsIncludeVaultBuffer() external view returns (uint256) {
        return _totalAssetInVaultAndVaultBuffer() + totalDebt;
    }

    /// @notice Vault total value(by chainlink price) in USD(1e18)
    function totalValue() external view returns (uint256) {
        return totalValueInVault() + totalValueInStrategies();
    }

    /**
     * @dev Internal to calculate total value of all assets held in Vault.
     * @return _value Total value(by chainlink price) in USD (1e18)
     */
    function totalValueInVault() public view returns (uint256 _value) {
        address[] memory _trackedAssets = _getTrackedAssets();
        for (uint256 i = 0; i < _trackedAssets.length; i++) {
            address _trackedAsset = _trackedAssets[i];
            uint256 _balance = _balanceOfToken(_trackedAsset, address(this));
            if (_balance > 0) {
                _value =
                    _value +
                    IPriceOracleConsumer(priceProvider).valueInUsd(_trackedAsset, _balance);
            }
        }
    }

    /**
     * @dev Internal to calculate total value of all assets held in Strategies.
     * @return _value Total value(by chainlink price) in USD (1e18)
     */
    function totalValueInStrategies() public view returns (uint256 _value) {
        uint256 _strategyLength = strategySet.length();
        for (uint256 i = 0; i < _strategyLength; i++) {
            uint256 _estimatedTotalAssets = IETHStrategy(strategySet.at(i)).estimatedTotalAssets();
            if (_estimatedTotalAssets > 0) {
                _value =
                    _value +
                    IPriceOracleConsumer(priceProvider).valueInUsd(
                        NativeToken.NATIVE_TOKEN,
                        _estimatedTotalAssets
                    );
            }
        }
    }

    /// @notice All strategies
    function getStrategies() external view returns (address[] memory) {
        return strategySet.values();
    }

    /**
     * @notice Get pegToken price in USD
     * @return  price in USD (1e18)
     */
    function getPegTokenPrice() external view returns (uint256) {
        uint256 _totalSupply = IPegToken(pegTokenAddress).totalSupply();
        uint256 _pegTokenPrice = 1e18;
        if (_totalSupply > 0) {
            address[] memory _trackedAssets = _getTrackedAssets();
            uint256 _trackedAssetsLength = _trackedAssets.length;
            uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
            uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);
            uint256 _totalValueInVault = 0;
            uint256 _totalTransferValue = 0;
            for (uint256 i = 0; i < _trackedAssetsLength; i++) {
                address _trackedAsset = _trackedAssets[i];
                uint256 _balance = _balanceOfToken(_trackedAsset, address(this));
                if (_balance > 0) {
                    _totalValueInVault =
                    _totalValueInVault +
                    _calculateAssetValue(_assetPrices, _assetDecimals, i, _trackedAsset, _balance);
                }
                _balance = transferFromVaultBufferAssetsMap[_trackedAsset];
                if (_balance > 0) {
                    _totalTransferValue =
                    _totalTransferValue +
                    _calculateAssetValue(_assetPrices, _assetDecimals, i, _trackedAsset, _balance);
                }
            }
            _pegTokenPrice = ((_totalValueInVault + totalDebt - _totalTransferValue) * 1e18) / _totalSupply;
        }
        return _pegTokenPrice;
    }

    /// @notice Check '_strategy' is active or not
    function checkActiveStrategy(address _strategy) public view {
        require(strategySet.contains(_strategy), "strategy not exist");
    }

    /// @notice estimate Minting pending share
    /// @param _amount Amount of the asset being deposited
    /// @return _pending Share Amount
    function estimateMint(address _asset, uint256 _amount) external view returns (uint256) {
        return _estimateMint(_asset, _amount);
    }

    /// @param _asset Address of the asset being deposited
    /// @param _amount Amount of the asset being deposited
    /// @dev Support single asset
    /// @return The amount of share minted
    function mint(
        address _asset,
        uint256 _amount,
        uint256 _minimumAmount
    ) external payable whenNotEmergency whenNotAdjustPosition nonReentrant returns (uint256) {
        uint256 _shareAmount = _estimateMint(_asset, _amount);
        if (_minimumAmount > 0) {
            require(_shareAmount >= _minimumAmount, "Mint amount lt minimum");
        }
        if (_asset == NativeToken.NATIVE_TOKEN) {
            uint256 _ethAmount = msg.value;
            require(_ethAmount == _amount, "Amount must eq transfer value");
            IVaultBuffer(vaultBufferAddress).mint{value: _ethAmount}(msg.sender, _shareAmount);
        } else {
            IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, vaultBufferAddress, _amount);
            IVaultBuffer(vaultBufferAddress).mint(msg.sender, _shareAmount);
        }
        emit Mint(msg.sender, _asset, _amount, _shareAmount);
        return _shareAmount;
    }

    /// @notice burn ETHi,return stablecoins
    /// @param _amount Amount of ETHi to burn
    /// @param _minimumAmount Minimum stablecoin units to receive in return
    function burn(uint256 _amount, uint256 _minimumAmount)
        external
        whenNotEmergency
        whenNotAdjustPosition
        nonReentrant
        returns (address[] memory _assets, uint256[] memory _amounts)
    {
        uint256 _accountBalance = IPegToken(pegTokenAddress).balanceOf(msg.sender);
        require(_amount > 0 && _amount <= _accountBalance, "ETHi not enough");
        address[] memory _trackedAssets = _getTrackedAssets();
        uint256[] memory _assetPrices = new uint256[](_trackedAssets.length);
        uint256[] memory _assetDecimals = new uint256[](_trackedAssets.length);
        (uint256 _sharesAmount, uint256 _actualAsset) = _replayToVault(
            _amount,
            _accountBalance,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        uint256 _actuallyReceivedAmount = 0;
        (_assets, _amounts, _actuallyReceivedAmount) = _calculateAndTransfer(
            _actualAsset,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        if (_minimumAmount > 0) {
            require(_actuallyReceivedAmount >= _minimumAmount, "amount lower than minimum");
        }
        _burnRebaseAndEmit(
            _amount,
            _actuallyReceivedAmount,
            _sharesAmount,
            _assets,
            _amounts,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
    }

    /// @notice redeem the funds from specified strategy.
    function redeem(
        address _strategy,
        uint256 _amount,
        uint256 _outputCode
    ) external isKeeper isActiveStrategy(_strategy) nonReentrant {
        uint256 _strategyAssetValue = strategies[_strategy].totalDebt;
        require(_amount <= _strategyAssetValue);

        (address[] memory _assets, uint256[] memory _amounts) = IETHStrategy(_strategy).repay(
            _amount,
            _strategyAssetValue,
            _outputCode
        );
        if (adjustPositionPeriod) {
            uint256 _assetsLength = _assets.length;
            for (uint256 i = 0; i < _assetsLength; i++) {
                uint256 _amount = _amounts[i];
                if (_amount > 0) {
                    redeemAssetsMap[_assets[i]] += _amount;
                }
            }
        }
        uint256 _nowStrategyTotalDebt = strategies[_strategy].totalDebt;
        uint256 _thisWithdrawValue = (_nowStrategyTotalDebt * _amount) / _strategyAssetValue;
        strategies[_strategy].totalDebt = _nowStrategyTotalDebt - _thisWithdrawValue;
        totalDebt -= _thisWithdrawValue;

        emit Redeem(_strategy, _amount, _assets, _amounts);
    }

    /// @notice Allocate funds in Vault to strategies.
    function lend(address _strategy, IExchangeAggregator.ExchangeToken[] calldata _exchangeTokens)
        external
        isKeeper
        whenNotEmergency
        isActiveStrategy(_strategy)
        nonReentrant
    {
        (
            address[] memory _wants,
            uint256[] memory _ratios,
            uint256[] memory _toAmounts
        ) = _checkAndExchange(_strategy, _exchangeTokens);
        //Definition rule 0 means unconstrained, currencies that do not participate are not in the returned wants
        uint256 _minProductIndex = 0;
        bool _isWantRatioIgnorable = IETHStrategy(_strategy).isWantRatioIgnorable();
        if (!_isWantRatioIgnorable && _ratios.length > 1) {
            for (uint256 i = 1; i < _ratios.length; i++) {
                if (_ratios[i] == 0) {
                    //0 is free
                    continue;
                } else if (_ratios[_minProductIndex] == 0) {
                    //minProductIndex is assigned to the first index whose proportion is not 0
                    _minProductIndex = i;
                } else if (
                    _toAmounts[_minProductIndex] * _ratios[i] >
                    _toAmounts[i] * _ratios[_minProductIndex]
                ) {
                    _minProductIndex = i;
                }
            }
        }

        uint256 _minAmount = _toAmounts[_minProductIndex];
        uint256 _minAspect = _ratios[_minProductIndex];
        uint256 _lendValue;
        uint256 _ethAmount;
        for (uint256 i = 0; i < _toAmounts.length; i++) {
            uint256 _actualAmount = _toAmounts[i];
            if (_actualAmount > 0) {
                if (!_isWantRatioIgnorable && _ratios[i] > 0) {
                    _actualAmount = (_ratios[i] * _minAmount) / _minAspect;
                    _toAmounts[i] = _actualAmount;
                }
                if (_wants[i] == NativeToken.NATIVE_TOKEN) {
                    _lendValue += _actualAmount;
                    _ethAmount = _actualAmount;
                } else {
                    _lendValue += IPriceOracleConsumer(priceProvider).valueInEth(
                        _wants[i],
                        _actualAmount
                    );
                    IERC20Upgradeable(_wants[i]).safeTransfer(_strategy, _actualAmount);
                }
            }
        }
        IETHStrategy _ethStrategy = IETHStrategy(_strategy);
        if (_ethAmount > 0) {
            _ethStrategy.borrow{value: _ethAmount}(_wants, _toAmounts);
        } else {
            _ethStrategy.borrow(_wants, _toAmounts);
        }
        _report(_strategy, new address[](0), new uint256[](0), _lendValue);
        emit LendToStrategy(_strategy, _wants, _toAmounts, _lendValue);
    }

    function exchange(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        IExchangeAggregator.ExchangeParam memory _exchangeParam
    ) external isKeeper nonReentrant returns (uint256) {
        return _exchange(_fromToken, _toToken, _amount, _exchangeParam);
    }

    /// @notice Change ETHi supply with Vault total assets.
    function rebase()
        external
        whenNotEmergency
        whenNotAdjustPosition
        whenNotRebasePaused
        nonReentrant
    {
        uint256 _totalAssets = _totalAssetInVault() + totalDebt;
        _rebase(_totalAssets);
    }

    /**
     * @dev Report the current asset of strategy caller
     * @param _rewardTokens The reward token list
     * @param _claimAmounts The claim amount list
     * Emits a {StrategyReported} event.
     */
    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts)
        external
        isActiveStrategy(msg.sender)
    {
        _report(msg.sender, _rewardTokens, _claimAmounts, 0);
    }

    /// @notice start  Adjust  Position
    function startAdjustPosition()
        external
        isKeeper
        whenNotAdjustPosition
        whenNotEmergency
        nonReentrant
    {
        adjustPositionPeriod = true;
        address[] memory _trackedAssets = _getTrackedAssets();

        (
            uint256[] memory _vaultAmounts,
            uint256[] memory _transferAmounts,
            bool _vaultBufferAboveZero
        ) = _calculateVault(_trackedAssets, true);
        uint256 _totalDebt = totalDebt;
        if (_vaultBufferAboveZero) {
            uint256 _trackedAssetsLength = _trackedAssets.length;
            uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
            uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);
            uint256 _totalValueInVault = 0;
            for (uint256 i = 0; i < _trackedAssetsLength; i++) {
                address _trackedAsset = _trackedAssets[i];
                uint256 _amount = _vaultAmounts[i];
                if (_amount > 0) {
                    _totalValueInVault =
                        _totalValueInVault +
                        _calculateAssetValue(
                            _assetPrices,
                            _assetDecimals,
                            i,
                            _trackedAsset,
                            _amount
                        );
                }
            }
            uint256 _totalAssets = _totalValueInVault + _totalDebt;
            uint256 _totalShares = IPegToken(pegTokenAddress).totalShares();
            if (!rebasePaused) {
                _rebase(_totalAssets, _totalShares);
            }
            IVaultBuffer(vaultBufferAddress).transferCashToVault(_trackedAssets, _transferAmounts);
        }
        uint256 _totalDebtOfBeforeAdjustPosition = _totalDebt;
        totalDebtOfBeforeAdjustPosition = _totalDebtOfBeforeAdjustPosition;
        emit StartAdjustPosition(
            _totalDebtOfBeforeAdjustPosition,
            _trackedAssets,
            _vaultAmounts,
            _transferAmounts
        );
    }

    /// @notice end  Adjust Position
    function endAdjustPosition() external isKeeper nonReentrant {
        require(adjustPositionPeriod, "AD OVER");
        address[] memory _trackedAssets = _getTrackedAssets();
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
        uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);

        (uint256[] memory _vaultAmounts, , ) = _calculateVault(_trackedAssets, false);

        uint256 _transferValue = 0;
        uint256 _redeemValue = 0;
        uint256 _vaultValueOfNow = 0;
        uint256 _vaultValueOfBefore = 0;
        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            address _trackedAsset = _trackedAssets[i];
            _transferValue =
                _transferValue +
                _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    transferFromVaultBufferAssetsMap[_trackedAsset]
                );
            _redeemValue =
                _redeemValue +
                _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    redeemAssetsMap[_trackedAsset]
                );
            _vaultValueOfNow =
                _vaultValueOfNow +
                _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    _vaultAmounts[i]
                );
            _vaultValueOfBefore =
                _vaultValueOfBefore +
                _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    beforeAdjustPositionAssetsMap[_trackedAsset]
                );
        }

        uint256 _totalDebtOfBefore = totalDebtOfBeforeAdjustPosition;
        uint256 _totalDebtOfNow = totalDebt;

        uint256 _totalValueOfNow = _totalDebtOfNow + _vaultValueOfNow;
        uint256 _totalValueOfBefore = _totalDebtOfBefore + _vaultValueOfBefore;

        {
            uint256 _transferAssets = 0;
            uint256 _old2LendAssets = 0;
            if (_vaultValueOfNow + _transferValue < _vaultValueOfBefore) {
                _old2LendAssets = _vaultValueOfBefore - _vaultValueOfNow - _transferValue;
            }
            if (_redeemValue + _old2LendAssets > _totalValueOfBefore - _transferValue) {
                _redeemValue = _totalValueOfBefore - _transferValue - _old2LendAssets;
            }
            if (_totalValueOfNow > _totalValueOfBefore) {
                uint256 _gain = _totalValueOfNow - _totalValueOfBefore;
                if (_transferValue > 0) {
                    _transferAssets =
                        _transferValue +
                        (_gain * _transferValue) /
                        (_transferValue + _redeemValue + _old2LendAssets);
                }
            } else {
                uint256 _loss = _totalValueOfBefore - _totalValueOfNow;
                if (_transferValue > 0) {
                    _transferAssets =
                        _transferValue -
                        (_loss * _transferValue) /
                        (_transferValue + _redeemValue + _old2LendAssets);
                }
            }
            uint256 _totalShares = IPegToken(pegTokenAddress).totalShares();
            if (!rebasePaused && _totalShares > 0) {
                _totalShares = _rebase(_totalValueOfNow - _transferAssets, _totalShares);
            }
            if (_transferAssets > 0) {
                uint256 _sharesAmount = _calculateShare(
                    _transferAssets,
                    _totalValueOfNow - _transferAssets,
                    _totalShares
                );
                if (_sharesAmount > 0) {
                    IPegToken(pegTokenAddress).mintShares(vaultBufferAddress, _sharesAmount);
                }
            }
        }

        {
            totalDebtOfBeforeAdjustPosition = 0;
            for (uint256 i = 0; i < _trackedAssetsLength; i++) {
                address _trackedAsset = _trackedAssets[i];
                redeemAssetsMap[_trackedAsset] = 0;
                beforeAdjustPositionAssetsMap[_trackedAsset] = 0;
                transferFromVaultBufferAssetsMap[_trackedAsset] = 0;
            }
            if (!IVaultBuffer(vaultBufferAddress).isDistributing()) {
                IVaultBuffer(vaultBufferAddress).openDistribute();
            }
            adjustPositionPeriod = false;
        }

        emit EndAdjustPosition(
            _transferValue,
            _redeemValue,
            _totalDebtOfNow,
            _totalValueOfNow,
            _totalValueOfBefore
        );
    }

    function _calculateVault(address[] memory _trackedAssets, bool _dealVaultBuffer)
        internal
        returns (
            uint256[] memory,
            uint256[] memory,
            bool
        )
    {
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _transferAmounts = new uint256[](_trackedAssetsLength);
        uint256[] memory _vaultAmounts = new uint256[](_trackedAssetsLength);
        bool _vaultBufferAboveZero = false;
        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            address _trackedAsset = _trackedAssets[i];
            uint256 _balance = 0;
            if (_dealVaultBuffer && assetSet.contains(_trackedAsset)) {
                _balance = _balanceOfToken(_trackedAsset, vaultBufferAddress);
                if (_balance > 0) {
                    _transferAmounts[i] = _balance;
                    _vaultBufferAboveZero = true;
                    transferFromVaultBufferAssetsMap[_trackedAsset] = _balance;
                }
            }
            uint256 _vaultAmount = _balanceOfToken(_trackedAsset, address(this));
            if (_vaultAmount > 0) {
                _vaultAmounts[i] = _vaultAmount;
            }
            if (_dealVaultBuffer && _vaultAmount + _balance > 0) {
                beforeAdjustPositionAssetsMap[_trackedAsset] = _vaultAmount + _balance;
            }
        }
        return (_vaultAmounts, _transferAmounts, _vaultBufferAboveZero);
    }

    /// @notice Assets held by Vault
    function _getTrackedAssets() internal view returns (address[] memory) {
        return trackedAssetsMap._inner._keys.values();
    }

    /**
     * @dev Internal to calculate total value of all assets held in Vault.
     * @return Total value in ETH (1e18)
     */
    function _totalAssetInVault() internal view returns (uint256) {
        address[] memory _trackedAssets = _getTrackedAssets();
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
        uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);
        uint256 _totalAssetInVault = _totalAssetInVault(
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        return _totalAssetInVault;
    }

    function _totalAssetInVault(
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal view returns (uint256) {
        return _totalAssetInOwner(_trackedAssets, _assetPrices, _assetDecimals, address(this));
    }

    function _totalAssetInVaultAndVaultBuffer() internal view returns (uint256) {
        address[] memory _trackedAssets = _getTrackedAssets();
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
        uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);
        uint256 _totalAssetInVault = _totalAssetInOwner(
            _trackedAssets,
            _assetPrices,
            _assetDecimals,
            address(this)
        );
        uint256 _totalAssetInVaultBuffer = _totalAssetInOwner(
            _trackedAssets,
            _assetPrices,
            _assetDecimals,
            vaultBufferAddress
        );
        return _totalAssetInVault + _totalAssetInVaultBuffer;
    }

    function _estimateMint(address _asset, uint256 _amount) private view returns (uint256) {
        require(_amount > 0, "Amount must be gt 0");
        require(!(IVaultBuffer(vaultBufferAddress).isDistributing()), "is distributing");
        checkIsSupportAsset(_asset);
        uint256 _mintAmount = _amount;
        if (_asset != NativeToken.NATIVE_TOKEN) {
            _mintAmount = IPriceOracleConsumer(priceProvider).valueInEth(_asset, _amount);
        }
        uint256 _minimumInvestmentAmount = minimumInvestmentAmount;
        if (_minimumInvestmentAmount > 0) {
            require(
                _mintAmount >= _minimumInvestmentAmount,
                "Amount must be gt minimum Investment Amount"
            );
        }
        return _mintAmount;
    }

    /// @notice withdraw from strategy queue
    function _repayFromWithdrawQueue(uint256 _needWithdrawValue) internal {
        uint256 _totalWithdrawValue;
        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            address _strategy = withdrawQueue[i];
            if (_strategy == ZERO_ADDRESS) break;

            uint256 _strategyTotalValue = strategies[_strategy].totalDebt;
            if (_strategyTotalValue <= 0) {
                continue;
            }

            uint256 _strategyWithdrawValue;
            if (_needWithdrawValue > _strategyTotalValue) {
                _strategyWithdrawValue = _strategyTotalValue;
                _needWithdrawValue -= _strategyWithdrawValue;
            } else {
                //If there is less than 0.001 ETH left, then all redemption
                if (_needWithdrawValue + 1e15 >= _strategyTotalValue) {
                    _strategyWithdrawValue = _strategyTotalValue;
                } else {
                    _strategyWithdrawValue = _needWithdrawValue;
                }
                _needWithdrawValue = 0;
            }
            (address[] memory _assets, uint256[] memory _amounts) = IETHStrategy(_strategy).repay(
                _strategyWithdrawValue,
                _strategyTotalValue,
                0
            );
            emit RepayFromStrategy(
                _strategy,
                _strategyWithdrawValue,
                _strategyTotalValue,
                _assets,
                _amounts
            );

            uint256 _nowStrategyTotalDebt = strategies[_strategy].totalDebt;
            uint256 _thisWithdrawValue = (_nowStrategyTotalDebt * _strategyWithdrawValue) /
                _strategyTotalValue;
            strategies[_strategy].totalDebt = _nowStrategyTotalDebt - _thisWithdrawValue;
            _totalWithdrawValue += _thisWithdrawValue;

            if (_needWithdrawValue <= 0) {
                break;
            }
        }
        totalDebt -= _totalWithdrawValue;
    }

    /// @notice withdraw from vault buffer
    function _repayFromVaultBuffer(
        uint256 _needTransferValue,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals,
        uint256 _totalAssets,
        uint256 _totalShares
    ) internal returns (uint256) {
        address[] memory _transferAssets = _trackedAssets;
        uint256 _transferAssetsLength = _transferAssets.length;
        uint256[] memory _amounts = new uint256[](_transferAssetsLength);
        uint256 _totalTransferValue;
        //price in vault
        for (uint256 i = 0; i < _transferAssetsLength; i++) {
            address _trackedAsset = _transferAssets[i];
            if (assetSet.contains(_trackedAsset)) {
                uint256 _assetBalancesInVaultBuffer = _balanceOfToken(
                    _trackedAsset,
                    vaultBufferAddress
                );
                if (_assetBalancesInVaultBuffer > 0) {
                    uint256 _value = _calculateAssetValue(
                        _assetPrices,
                        _assetDecimals,
                        i,
                        _trackedAsset,
                        _assetBalancesInVaultBuffer
                    );

                    if (_needTransferValue > _value) {
                        _totalTransferValue = _totalTransferValue + _value;
                        _needTransferValue = _needTransferValue - _value;
                        _amounts[i] = _assetBalancesInVaultBuffer;
                    } else {
                        _totalTransferValue = _totalTransferValue + _needTransferValue;
                        _amounts[i] = (_assetBalancesInVaultBuffer * _needTransferValue) / _value;
                        _needTransferValue = 0;
                        break;
                    }
                }
            }
        }
        if (_totalTransferValue > 0) {
            IVaultBuffer(vaultBufferAddress).transferCashToVault(_transferAssets, _amounts);

            uint256 _totalTransferShares = _calculateShare(
                _totalTransferValue,
                _totalAssets,
                _totalShares
            );
            IPegToken(pegTokenAddress).mintShares(vaultBufferAddress, _totalTransferShares);

            emit PegTokenSwapCash(_totalTransferValue, _transferAssets, _amounts);
        }
        return _totalTransferValue;
    }

    function _calculateShare(
        uint256 _amount,
        uint256 _totalAssets,
        uint256 _totalShares
    ) internal view returns (uint256) {
        uint256 _shareAmount = 0;
        if (_totalAssets > 0 && _totalShares > 0) {
            _shareAmount = (_amount * _totalShares) / _totalAssets;
        }
        if (_shareAmount == 0) {
            uint256 _underlyingUnitsPerShare = underlyingUnitsPerShare;
            if (_underlyingUnitsPerShare > 0) {
                _shareAmount = _amount.divPreciselyScale(_underlyingUnitsPerShare, 1e27);
            } else {
                _shareAmount = _amount * 1e9;
            }
        }
        return _shareAmount;
    }

    /// @notice calculate need transfer amount from vault ,set to outputs
    function _calculateOutputs(
        uint256 _needTransferAmount,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal view returns (uint256[] memory) {
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _outputs = new uint256[](_trackedAssetsLength);

        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            address _trackedAsset = _trackedAssets[i];
            uint256 _balance = _balanceOfToken(_trackedAsset, address(this));
            if (_balance > 0) {
                uint256 _value = _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    _balance
                );
                if (_value >= _needTransferAmount) {
                    _outputs[i] = (_balance * _needTransferAmount) / _value;
                    break;
                } else {
                    _outputs[i] = _balance;
                    _needTransferAmount = _needTransferAmount - _value;
                }
            }
        }
        return _outputs;
    }

    /// @notice calculate Asset value in eth by oracle price
    /// @param _assetPrices array of asset price
    /// @param _assetDecimals array of asset decimal
    /// @param _assetIndex index of the asset in trackedAssets array
    /// @param _trackedAsset address of the asset
    /// @return shareAmount
    function _calculateAssetValue(
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals,
        uint256 _assetIndex,
        address _trackedAsset,
        uint256 _balance
    ) private view returns (uint256) {
        uint256 _assetPrice = _getAssetPrice(_assetPrices, _assetIndex, _trackedAsset);
        uint256 _assetDecimal = _getAssetDecimals(_assetDecimals, _assetIndex, _trackedAsset);

        uint256 _value = _balance.mulTruncateScale(_assetPrice, 10**_assetDecimal);
        return _value;
    }

    // @notice without exchange token and transfer form vault to user
    function _transfer(
        uint256[] memory _outputs,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal returns (uint256) {
        uint256 _actualAmount;
        uint256 _trackedAssetsLength = _trackedAssets.length;
        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            uint256 _amount = _outputs[i];
            if (_amount > 0) {
                address _trackedAsset = _trackedAssets[i];
                if (_trackedAsset == NativeToken.NATIVE_TOKEN) {
                    _actualAmount = _actualAmount + _amount;
                    payable(msg.sender).transfer(_amount);
                } else {
                    _actualAmount =
                        _actualAmount +
                        _calculateAssetValue(
                            _assetPrices,
                            _assetDecimals,
                            i,
                            _trackedAsset,
                            _amount
                        );
                    IERC20Upgradeable(_trackedAsset).safeTransfer(msg.sender, _amount);
                }
            }
        }
        return _actualAmount;
    }

    function _replayToVault(
        uint256 _amount,
        uint256 _accountBalance,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal returns (uint256 _sharesAmount, uint256 _actualAsset) {
        uint256 _totalAssetInVault = _totalAssetInVault(
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        uint256 _actualAmount = _amount;
        uint256 _currentTotalAssets = _totalAssetInVault + totalDebt;
        uint256 _currentTotalShares = IPegToken(pegTokenAddress).totalShares();
        {
            uint256 _underlyingUnitsPerShare = underlyingUnitsPerShare;
            if (_accountBalance == _actualAmount) {
                _sharesAmount = IPegToken(pegTokenAddress).sharesOf(msg.sender);
            } else {
                _sharesAmount = _actualAmount.divPreciselyScale(_underlyingUnitsPerShare, 1e27);
            }
            // Calculate redeem fee
            if (redeemFeeBps > 0) {
                _actualAmount = _actualAmount - (_actualAmount * redeemFeeBps) / MAX_BPS;
            }
            uint256 _currentTotalSupply = _currentTotalShares.mulTruncateScale(
                _underlyingUnitsPerShare,
                1e27
            );
            _actualAsset = (_actualAmount * _currentTotalAssets) / _currentTotalSupply;
        }

        // vault not enough,withdraw from vault buffer
        if (_totalAssetInVault < _actualAsset) {
            _totalAssetInVault =
                _totalAssetInVault +
                _repayFromVaultBuffer(
                    _actualAsset - _totalAssetInVault,
                    _trackedAssets,
                    _assetPrices,
                    _assetDecimals,
                    _currentTotalAssets,
                    _currentTotalShares
                );
        }

        // vault not enough,withdraw from withdraw queue strategy
        if (_totalAssetInVault < _actualAsset) {
            _repayFromWithdrawQueue(_actualAsset - _totalAssetInVault);
        }
    }

    function _calculateAndTransfer(
        uint256 _actualAsset,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    )
        internal
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        // calculate need transfer amount from vault ,set to outputs
        uint256[] memory _outputs = _calculateOutputs(
            _actualAsset,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );

        uint256 _actuallyReceivedAmount = _transfer(
            _outputs,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        return (_trackedAssets, _outputs, _actuallyReceivedAmount);
    }

    // @notice burn ETHi and check rebase
    function _burnRebaseAndEmit(
        uint256 _amount,
        uint256 _actualAmount,
        uint256 _shareAmount,
        address[] memory _assets,
        uint256[] memory _amounts,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal {
        IPegToken(pegTokenAddress).burnShares(msg.sender, _shareAmount);

        // Until we can prove that we won't affect the prices of our assets
        // by withdrawing them, this should be here.
        // It's possible that a strategy was off on its asset total, perhaps
        // a reward token sold for more or for less than anticipated.
        if (!rebasePaused) {
            uint256 _totalAssetInVault = _totalAssetInVault(
                _trackedAssets,
                _assetPrices,
                _assetDecimals
            );
            _rebase(_totalAssetInVault + totalDebt);
        }
        emit Burn(msg.sender, _amount, _actualAmount, _shareAmount, _assets, _amounts);
    }

    /**
     * @dev Calculate the total value of assets held by the Vault and all
     *      strategies and update the supply of ETHi, optionally sending a
     *      portion of the yield to the trustee.
     */
    function _rebase(uint256 _totalAssets) internal {
        uint256 _totalShares = IPegToken(pegTokenAddress).totalShares();
        _rebase(_totalAssets, _totalShares);
    }

    function _rebase(uint256 _totalAssets, uint256 _totalShares) internal returns (uint256) {
        if (_totalShares == 0) {
            return _totalShares;
        }

        uint256 _underlyingUnitsPerShare = underlyingUnitsPerShare;
        uint256 _totalSupply = _totalShares.mulTruncateScale(_underlyingUnitsPerShare, 1e27);

        // Final check should use latest value
        if (
            _totalAssets > _totalSupply &&
            (_totalAssets - _totalSupply) * TEN_MILLION_BPS > _totalSupply * rebaseThreshold
        ) {
            // Yield fee collection
            address _treasuryAddress = treasury;
            uint256 _trusteeFeeBps = trusteeFeeBps;
            if (_trusteeFeeBps > 0 && _treasuryAddress != address(0)) {
                uint256 _yield = _totalAssets - _totalSupply;
                uint256 _fee = (_yield * _trusteeFeeBps) / MAX_BPS;
                require(_yield > _fee, "Fee must not be greater than yield");
                if (_fee > 0) {
                    uint256 _sharesAmount = (_fee * _totalShares) / (_totalAssets - _fee);
                    if (_sharesAmount > 0) {
                        IPegToken(pegTokenAddress).mintShares(_treasuryAddress, _sharesAmount);
                        _totalShares = _totalShares + _sharesAmount;
                    }
                }
            }
            uint256 _newUnderlyingUnitsPerShare = _totalAssets.divPreciselyScale(
                _totalShares,
                1e27
            );
            if (_newUnderlyingUnitsPerShare != _underlyingUnitsPerShare) {
                underlyingUnitsPerShare = _newUnderlyingUnitsPerShare;
                emit Rebase(_totalShares, _totalAssets, _newUnderlyingUnitsPerShare);
            }
        }
        return _totalShares;
    }

    /// @notice check valid and exchange to want token
    function _checkAndExchange(
        address _strategy,
        IExchangeAggregator.ExchangeToken[] calldata _exchangeTokens
    )
        internal
        returns (
            address[] memory _wants,
            uint256[] memory _ratios,
            uint256[] memory toAmounts
        )
    {
        (_wants, _ratios) = IETHStrategy(_strategy).getWantsInfo();
        uint256 _wantsLength = _wants.length;
        toAmounts = new uint256[](_wantsLength);
        uint256 _exchangeTokensLength = _exchangeTokens.length;
        for (uint256 i = 0; i < _exchangeTokensLength; i++) {
            bool _findToToken = false;
            for (uint256 j = 0; j < _wantsLength; j++) {
                if (_exchangeTokens[i].toToken == _wants[j]) {
                    _findToToken = true;
                    break;
                }
            }
            require(_findToToken, "toToken invalid");
        }

        for (uint256 j = 0; j < _wantsLength; j++) {
            for (uint256 i = 0; i < _exchangeTokensLength; i++) {
                IExchangeAggregator.ExchangeToken memory _exchangeToken = _exchangeTokens[i];

                // not strategy need token,skip
                if (_wants[j] != _exchangeToken.toToken) continue;

                uint256 _toAmount;
                if (_exchangeToken.fromToken == _exchangeToken.toToken) {
                    _toAmount = _exchangeToken.fromAmount;
                } else {
                    if (_exchangeToken.fromAmount > 0) {
                        _toAmount = _exchange(
                            _exchangeToken.fromToken,
                            _exchangeToken.toToken,
                            _exchangeToken.fromAmount,
                            _exchangeToken.exchangeParam
                        );
                    }
                }

                toAmounts[j] = _toAmount;
                break;
            }
        }
    }

    function _exchange(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        IExchangeAggregator.ExchangeParam memory _exchangeParam
    ) internal returns (uint256 _exchangeAmount) {
        require(trackedAssetsMap.contains(_toToken), "!T");

        IExchangeAdapter.SwapDescription memory _swapDescription = IExchangeAdapter
            .SwapDescription({
                amount: _amount,
                srcToken: _fromToken,
                dstToken: _toToken,
                receiver: address(this)
            });
        if (_fromToken == NativeToken.NATIVE_TOKEN) {
            // payable(exchangeManager).transfer(_amount);
            _exchangeAmount = IExchangeAggregator(exchangeManager).swap{value: _amount}(
                _exchangeParam.platform,
                _exchangeParam.method,
                _exchangeParam.encodeExchangeArgs,
                _swapDescription
            );
        } else {
            IERC20Upgradeable(_fromToken).safeApprove(exchangeManager, 0);
            IERC20Upgradeable(_fromToken).safeApprove(exchangeManager, _amount);
            _exchangeAmount = IExchangeAggregator(exchangeManager).swap(
                _exchangeParam.platform,
                _exchangeParam.method,
                _exchangeParam.encodeExchangeArgs,
                _swapDescription
            );
        }

        uint256 _oracleExpectedAmount = IPriceOracleConsumer(priceProvider).valueInTargetToken(
            _fromToken,
            _amount,
            _toToken
        );
        require(
            _exchangeAmount >=
                (_oracleExpectedAmount *
                    (MAX_BPS -
                        _exchangeParam.slippage -
                        _exchangeParam.oracleAdditionalSlippage)) /
                    MAX_BPS,
            "OL"
        );
        emit Exchange(_exchangeParam.platform, _fromToken, _amount, _toToken, _exchangeAmount);
    }

    function _report(
        address _strategy,
        address[] memory _rewardTokens,
        uint256[] memory _claimAmounts,
        uint256 _lendValue
    ) private {
        StrategyParams memory _strategyParam = strategies[_strategy];
        uint256 _lastStrategyTotalDebt = _strategyParam.totalDebt + _lendValue;
        uint256 _nowStrategyTotalDebt = IETHStrategy(_strategy).estimatedTotalAssets();
        uint256 _gain = 0;
        uint256 _loss = 0;

        if (_nowStrategyTotalDebt > _lastStrategyTotalDebt) {
            _gain = _nowStrategyTotalDebt - _lastStrategyTotalDebt;
        } else if (_nowStrategyTotalDebt < _lastStrategyTotalDebt) {
            _loss = _lastStrategyTotalDebt - _nowStrategyTotalDebt;
        }

        if (_strategyParam.enforceChangeLimit) {
            if (
                block.timestamp - strategies[_strategy].lastReport <
                maxTimestampBetweenTwoReported &&
                (_lastStrategyTotalDebt > minCheckedStrategyTotalDebt ||
                    _nowStrategyTotalDebt > minCheckedStrategyTotalDebt)
            ) {
                if (_gain > 0) {
                    require(
                        _gain <=
                            ((_lastStrategyTotalDebt * _strategyParam.profitLimitRatio) / MAX_BPS),
                        "GL"
                    );
                } else if (_loss > 0) {
                    require(
                        _loss <=
                            ((_lastStrategyTotalDebt * _strategyParam.lossLimitRatio) / MAX_BPS),
                        "LL"
                    );
                }
            }
        } else {
            strategies[_strategy].enforceChangeLimit = true;
            // The check is turned off only once and turned back on.
        }
        strategies[_strategy].totalDebt = _nowStrategyTotalDebt;
        totalDebt = totalDebt + _nowStrategyTotalDebt + _lendValue - _lastStrategyTotalDebt;

        strategies[_strategy].lastReport = block.timestamp;
        uint256 _type = 0;
        if (_lendValue > 0) {
            _type = 1;
        }
        emit StrategyReported(
            _strategy,
            _gain,
            _loss,
            _lastStrategyTotalDebt,
            _nowStrategyTotalDebt,
            _rewardTokens,
            _claimAmounts,
            _type
        );
    }

    function _balanceOfToken(address _trackedAsset, address _owner)
        internal
        view
        returns (uint256)
    {
        uint256 _balance;
        if (_trackedAsset == NativeToken.NATIVE_TOKEN) {
            _balance = _owner.balance;
        } else {
            _balance = IERC20Upgradeable(_trackedAsset).balanceOf(_owner);
        }
        return _balance;
    }

    /**
     * @notice Get the supported asset Decimal
     * @return _assetDecimal asset Decimals
     */
    function _getAssetDecimals(
        uint256[] memory _assetDecimals,
        uint256 _assetIndex,
        address _asset
    ) internal view returns (uint256) {
        uint256 _decimal = _assetDecimals[_assetIndex];
        if (_decimal == 0) {
            if (_asset == NativeToken.NATIVE_TOKEN) {
                _decimal = 18;
            } else {
                _decimal = IERC20Metadata(_asset).decimals();
            }
            _assetDecimals[_assetIndex] = _decimal;
        }
        return _decimal;
    }

    /**
     * @notice Get an array of the supported asset prices in USD
     * @return  prices in USD (1e18)
     */
    function _getAssetPrice(
        uint256[] memory _assetPrices,
        uint256 _assetIndex,
        address _asset
    ) internal view returns (uint256) {
        uint256 _price = _assetPrices[_assetIndex];
        if (_price == 0) {
            if (_asset == NativeToken.NATIVE_TOKEN) {
                _price = 1e18;
            } else {
                _price = IPriceOracleConsumer(priceProvider).priceInEth(_asset);
            }
            _assetPrices[_assetIndex] = _price;
        }
        return _price;
    }

    function _totalAssetInOwner(
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals,
        address _owner
    ) internal view returns (uint256) {
        uint256 _totalAssetInOwne;
        uint256 _trackedAssetsLength = _trackedAssets.length;
        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            address _trackedAsset = _trackedAssets[i];
            uint256 _balance = _balanceOfToken(_trackedAsset, _owner);
            if (_balance > 0) {
                _totalAssetInOwne =
                    _totalAssetInOwne +
                    _calculateAssetValue(_assetPrices, _assetDecimals, i, _trackedAsset, _balance);
            }
        }
        return _totalAssetInOwne;
    }

    /// @notice Vault total asset in ETH(1e18)
    function _getTotalAssets() private view returns (uint256) {
        return _totalAssetInVault() + totalDebt;
    }

    /**
     * @notice Send funds to the pool
     * @dev Users are able to submit their funds by transacting to the fallback function.
     * Unlike vanilla Eth2.0 Deposit contract, accepting only 32-Ether transactions, Lido
     * accepts payments of any size. Submitted Ethers are stored in Buffer until someone calls
     * depositBufferedEther() and pushes them to the ETH2 Deposit contract.
     */
    receive() external payable {}

    /**
     * @dev Falldown to the admin implementation
     * @notice This is a catch all for all functions not declared in core
     */
    fallback() external payable {
        bytes32 slot = ADMIN_IMPL_POSITION;

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), sload(slot), 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}