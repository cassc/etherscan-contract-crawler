// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IExecutor, ExecutorIntegration, ExecutorAction } from '../executors/IExecutor.sol';
import { Registry } from '../registry/Registry.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';

import { IGmxVault } from '../interfaces/IGmxVault.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { GmxStoredData } from '../lib/GmxStoredData.sol';

import { Constants } from '../lib/Constants.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract GmxExecutor is IExecutor, IGmxPositionRouterCallbackReceiver {
    using SafeERC20 for IERC20;

    error NotEqual(uint256 desired, uint256 given);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice
    ) external payable {
        // We don't support swaps on the way in so path should just be [collateralToken]
        // For longs this needs to the collateralToken must == indexToken
        // For shorts the collateralToken must be a stable coin
        // The reason for this is that the gmxCallback doesn't provide the inputToken only the collateralToken
        // And if the orderFails we need to update the active assets so inputToken must == collateralToken
        // It just means the manager must swap to the collateralToken before calling this function
        require(_path.length == 1, 'no in swaps supported');

        Registry registry = VaultBaseExternal(address(this)).registry();

        // For longs, proceeds are paid out in the indexToken, we must supported it
        require(
            !_isLong || registry.accountant().isSupportedAsset(_indexToken),
            'index asset is unsupported'
        );

        checkAcceptablePrice(
            registry.gmxConfig().vault(),
            true,
            _indexToken,
            _isLong,
            _acceptablePrice,
            registry.gmxConfig().acceptablePriceDeviationBasisPoints()
        );

        address inputToken = _path[0];
        address collateralToken = _path[_path.length - 1];

        GmxStoredData.updatePositions(
            _indexToken,
            collateralToken,
            _isLong,
            registry.gmxConfig().maxPositions()
        );

        uint256 fee = registry.gmxConfig().positionRouter().minExecutionFee();
        require(address(this).balance >= fee, 'not enough eth to pay fee');

        IERC20(inputToken).approve(
            address(registry.gmxConfig().router()),
            _amountIn
        );

        registry.gmxConfig().router().approvePlugin(
            address(registry.gmxConfig().positionRouter())
        );

        bytes32 key = registry
            .gmxConfig()
            .positionRouter()
            .createIncreasePosition{ value: fee }(
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            fee,
            registry.gmxConfig().referralCode(),
            address(this) // callack target (the vault)
        );

        GmxStoredData.pushRequest(
            key,
            GmxStoredData.GMXRequestData({
                _inputToken: inputToken,
                _outputToken: address(0),
                _indexToken: _indexToken,
                _collateralToken: collateralToken,
                _isLong: _isLong
            }),
            registry.gmxConfig().maxOpenRequests()
        );

        // This works because the gmx valuer includes value locked in unexcuted orders

        VaultBaseExternal(address(this)).addActiveAsset(
            address(registry.gmxConfig().vault())
        );

        // We don't update this here because we do it in the callback
        // If the request fails to execute the inputToken will be returned to us
        // But we don't have any guarantee that the callback will succeed.
        // VaultBaseExternal(address(this)).updateActiveAsset(inputToken);

        registry.emitEvent();
        emit ExecutedManagerAction(
            ExecutorIntegration.GMX,
            _isLong
                ? ExecutorAction.PerpLongDecrease
                : ExecutorAction.PerpShortDecrease,
            inputToken,
            _amountIn,
            _indexToken,
            _sizeDelta
        );
    }

    function createDecreasePosition(
        address[] memory _path, // This needs to be [collateralToken]
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint _minOut
    ) external payable {
        // We don't support swaps on the way out so path should just be [collateralToken]
        // These parameters are not used but we need to keep the interface the same as Gmx
        // I we support these later on it means less fe changes and forward compatibility
        require(_path.length == 1, 'no out swaps supported');
        require(_minOut == 0, 'minOut not supported');

        ///
        /// We need to validate _acceptablePrice is within a range of the chainlink price of the indexToken
        /// This should actually be within a reasonalbe delta the current minPrice of Gmx
        ///

        Registry registry = VaultBaseExternal(address(this)).registry();

        checkAcceptablePrice(
            registry.gmxConfig().vault(),
            false,
            _indexToken,
            _isLong,
            _acceptablePrice,
            registry.gmxConfig().acceptablePriceDeviationBasisPoints()
        );

        uint256 fee = registry.gmxConfig().positionRouter().minExecutionFee();

        require(address(this).balance >= fee, 'not enough eth to pay fee');

        registry.gmxConfig().router().approvePlugin(
            address(registry.gmxConfig().positionRouter())
        );

        bytes32 key = registry
            .gmxConfig()
            .positionRouter()
            .createDecreasePosition{ value: fee }(
            _path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            address(this), // receiver - the vault
            _acceptablePrice,
            0, // minOut - we don't support swaps on the way out
            fee,
            false, // withdrawEth - we don't support this
            address(this) // callack target (the vault)
        );
        address outputToken = _isLong ? _indexToken : _path[0];
        GmxStoredData.pushRequest(
            key,
            GmxStoredData.GMXRequestData({
                _inputToken: address(0),
                _outputToken: outputToken,
                _indexToken: _indexToken,
                _collateralToken: _path[0],
                _isLong: _isLong
            }),
            registry.gmxConfig().maxOpenRequests()
        );

        VaultBaseExternal(address(this)).addActiveAsset(outputToken);
        registry.emitEvent();
        emit ExecutedManagerAction(
            ExecutorIntegration.GMX,
            _isLong
                ? ExecutorAction.PerpLongDecrease
                : ExecutorAction.PerpShortDecrease,
            _indexToken,
            _sizeDelta,
            outputToken,
            0
        );
    }

    // Executed as the Vault
    function gmxPositionCallback(
        bytes32 _requestKey,
        bool wasExecuted,
        bool isIncrease
    ) external {
        // executeIncreasePosition -> wasExecuted: true, isIncrease: true
        // executeDecreasePosition -> wasExecuted: true, isIncrease: false
        // cancelIncreasePosition -> wasExecuted: false, isIncrease: true
        // ^^(this is what we get if a increasePosition fails)
        // cancelDecreasePosition -> wasExecuted: false, isIncrease: false
        Registry registry = VaultBaseExternal(address(this)).registry();

        (
            GmxStoredData.GMXRequestData memory requestData,
            int index
        ) = GmxStoredData.findRequest(address(this), _requestKey);

        GmxStoredData.removeRequest(registry, index);

        // If the request was exec

        // If it's a decrease position we need to update the collateralAsset for shorts, indexToken for longs aka outputToken
        // Or If the increasePosition executed or canclled we need to update the collateralAsset aka inputToken
        if (isIncrease) {
            VaultBaseExternal(address(this)).updateActiveAsset(
                requestData._inputToken
            );
        } else {
            if (wasExecuted) {
                VaultBaseExternal(address(this)).addActiveAsset(
                    requestData._outputToken
                );
                GmxStoredData.removePositionIfEmpty(
                    GmxStoredData.GMXPositionData({
                        _indexToken: requestData._indexToken,
                        _collateralToken: requestData._collateralToken,
                        _isLong: requestData._isLong
                    })
                );
                // This will be VERY gas intensive, could fail if we have too many positions
                // GMX allows us to set a custom gasLimit for this callBack,
                // but doesn't assert it will be provided with enough gas
                VaultBaseExternal(address(this)).updateActiveAsset(
                    address(registry.gmxConfig().vault())
                );
            }
        }

        registry.emitEvent();
        emit ExecutedCallback(
            ExecutorIntegration.ZeroX,
            isIncrease
                ? requestData._isLong
                    ? ExecutorAction.PerpLongIncrease
                    : ExecutorAction.PerpShortIncrease
                : requestData._isLong
                ? ExecutorAction.PerpLongDecrease
                : ExecutorAction.PerpShortDecrease,
            isIncrease ? requestData._inputToken : requestData._indexToken,
            isIncrease ? requestData._indexToken : requestData._outputToken,
            wasExecuted
        );

        // console.log('gmxPositionCallback gas used', gasStart - gasleft());
    }

    function checkAcceptablePrice(
        IGmxVault gmxVault,
        bool isIncrease,
        address indexToken,
        bool isLong,
        uint acceptablePrice,
        uint acceptableDeviationBasisPoints
    ) public view {
        uint256 gmxPrice;

        // When opening a position GMX uses the most favourable price for the LP's (maker) not the order taker
        if (isIncrease) {
            gmxPrice = isLong
                ? gmxVault.getMaxPrice(indexToken)
                : gmxVault.getMinPrice(indexToken);
            // When closing a position GMX uses the most favourable price for the LP's (taker) not the order maker
        } else {
            gmxPrice = isLong
                ? gmxVault.getMinPrice(indexToken)
                : gmxVault.getMaxPrice(indexToken);
        }

        uint256 diffBasisPoints = gmxPrice > acceptablePrice
            ? gmxPrice - (acceptablePrice)
            : acceptablePrice - (gmxPrice);
        diffBasisPoints =
            (diffBasisPoints * Constants.BASIS_POINTS_DIVISOR) /
            gmxPrice;

        require(
            diffBasisPoints <= acceptableDeviationBasisPoints,
            'acceptable price out of range'
        );
    }
}