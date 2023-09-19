// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./MainHelper.sol";

abstract contract WiseCore is MainHelper {

    /**
     * @dev Wrapper function combining pool
     * preparations for borrow and collaterals.
     * Bypassed when called by powerFarms
     * or aaveHub.
     */
    function _prepareAssociatedTokens(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        if (_byPassCase(msg.sender) == true) {
            return;
        }

        _preparationCollaterals(
            _nftId,
            _poolToken
        );

        _preparationBorrows(
            _nftId,
            _poolToken
        );
    }

    /**
     * @dev Core function combining withdraw
     * logic and security checks.
     */
    function _coreWithdrawToken(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        internal
    {
        _prepareAssociatedTokens(
            _nftId,
            _poolToken
        );

        WISE_SECURITY.checksWithdraw(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _coreWithdrawBare(
            _nftId,
            _poolToken,
            _amount,
            _shares
        );
    }

    /**
     * @dev Internal function combining payback
     * logic and emit of an event.
     */
    function _handlePayback(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        internal
    {
        _corePayback(
            _nftId,
            _poolToken,
            _amount,
            _shares
        );

        emit FundsReturned(
            _caller,
            _poolToken,
            _nftId,
            _amount,
            _shares,
            block.timestamp
        );
    }

    /**
     * @dev Internal function combining deposit
     * logic, security checks and event emit.
     */
    function _handleDeposit(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shareAmount
    )
        internal
    {
        _checkDeposit(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _increasePositionLendingDeposit(
            _nftId,
            _poolToken,
            _shareAmount
        );

        _updatePoolStorage(
            _poolToken,
            _amount,
            _shareAmount,
            _increaseTotalPool,
            _increasePseudoTotalPool,
            _increaseTotalDepositShares
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionLending,
            positionLendingTokenData
        );

        emit FundsDeposited(
            _caller,
            _nftId,
            _poolToken,
            _amount,
            _shareAmount,
            block.timestamp
        );
    }

    /**
     * @dev External wrapper for
     * {_checkPositionLocked}.
     */
    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        external
        view
    {
        _checkPositionLocked(
            _nftId,
            _caller
        );
    }

    /**
     * @dev Checks if a postion is locked
     * for powerFarms. Get skipped when
     * aaveHub or a powerFarm itself is
     * the {msg.sender}.
     */
    function _checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        internal
        view
    {
        if (_byPassCase(_caller) == true) {
            return;
        }

        if (positionLocked[_nftId] == false) {
            return;
        }

        revert PositionLocked();
    }

    /**
     * @dev External wrapper for
     * {_checkDeposit}.
     */
    function checkDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view
    {
        _checkDeposit(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );
    }

    /**
     * @dev Internal function including
     * security checks for deposit logic.
     */
    function _checkDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        internal
        view
    {
        _checkPositionLocked(
            _nftId,
            _caller
        );

        if (WISE_ORACLE.chainLinkIsDead(_poolToken) == true) {
            revert();
        }

        _checkMaxDepositValue(
            _poolToken,
            _amount
        );
    }

    /**
     * @dev Internal function checking
     * if the deposit amount for the
     * pool token is reached.
     */
    function _checkMaxDepositValue(
        address _poolToken,
        uint256 _amount
    )
        internal
        view
    {
        bool state = maxDepositValueToken[_poolToken]
            < getTotalBareToken(_poolToken)
            + getPseudoTotalPool(_poolToken)
            + _amount;

        if (state == true) {
            revert DepositCapReached();
        }
    }

    /**
     * @dev Core function combining
     * supply logic with security
     * checks for solely deposit.
     */
    function _handleSolelyDeposit(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        _checkDeposit(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _increaseMappingValue(
            positionPureCollateralAmount,
            _nftId,
            _poolToken,
            _amount
        );

        _increaseTotalBareToken(
            _poolToken,
            _amount
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionLending,
            positionLendingTokenData
        );
    }

    /**
     * @dev Low level core function combining
     * pure withdraw math (without security
     * checks).
     */
    function _coreWithdrawBare(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        internal
    {
        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _decreaseTotalPool,
            _decreasePseudoTotalPool,
            _decreaseTotalDepositShares
        );

        _decreaseLendingShares(
            _nftId,
            _poolToken,
            _shares
        );

        _removeEmptyLendingData(
            _nftId,
            _poolToken
        );
    }

    /**
     * @dev Core function combining borrow
     * logic with security checks.
     */
    function _coreBorrowTokens(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        internal
    {
        _prepareAssociatedTokens(
            _nftId,
            _poolToken
        );

        WISE_SECURITY.checksBorrow(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _increasePseudoTotalBorrowAmount,
            _decreaseTotalPool,
            _increaseTotalBorrowShares
        );

        _increaseMappingValue(
            userBorrowShares,
            _nftId,
            _poolToken,
            _shares
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionBorrow,
            positionBorrowTokenData
        );
    }

    /**
     * @dev Core function combining payback
     * logic with security checks.
     */
    function _corePayback(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        internal
    {
        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _increaseTotalPool,
            _decreasePseudoTotalBorrowAmount,
            _decreaseTotalBorrowShares
        );

        _decreasePositionMappingValue(
            userBorrowShares,
            _nftId,
            _poolToken,
            _shares
        );

        if (getPositionBorrowShares(_nftId, _poolToken) > 0) {
            return;
        }

        _removePositionData({
            _nftId: _nftId,
            _poolToken: _poolToken,
            _getPositionTokenLength: getPositionBorrowTokenLength,
            _getPositionTokenByIndex: getPositionBorrowTokenByIndex,
            _deleteLastPositionData: _deleteLastPositionBorrowData,
            isLending: false
        });
    }

    /**
     * @dev External wrapper for
     * {_corePayback} logic callable
     * by feeMananger.
     */
    function corePaybackFeeManager(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external
        onlyFeeManager
    {
        _corePayback(
            _nftId,
            _poolToken,
            _amount,
            _shares
        );
    }

    /**
     * @dev Core function combining
     * withdraw logic for solely
     * withdraw with security checks.
     */
    function _coreSolelyWithdraw(
        address _caller,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        WISE_SECURITY.checksSolelyWithdraw(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _solelyWithdrawBase(
            _poolToken,
            _nftId,
            _amount
        );
    }

    /**
     * @dev Low level core function with
     * withdraw logic for solely
     * withdraw. (Without security checks)
     */
    function _solelyWithdrawBase(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount
    )
        internal
    {
        _decreasePositionMappingValue(
            positionPureCollateralAmount,
            _nftId,
            _poolToken,
            _amount
        );

        _decreaseTotalBareToken(
            _poolToken,
            _amount
        );

        _removeEmptyLendingData(
            _nftId,
            _poolToken
        );
    }

    /**
     * @dev Core function combining payback
     * logic for paying back borrow with
     * lending shares of same asset type.
     */
    function _corePaybackLendingShares(
        address _poolToken,
        uint256 _tokenAmount,
        uint256 _lendingShares,
        uint256 _nftIdCaller,
        uint256 _nftIdReceiver
    )
        internal
    {
        uint256 borrowShareEquivalent = _borrowShareEquivalent(
            _poolToken,
            _lendingShares
        );

        _updatePoolStorage(
            _poolToken,
            _tokenAmount,
            _lendingShares,
            _decreasePseudoTotalPool,
            _decreasePseudoTotalBorrowAmount,
            _decreaseTotalDepositShares
        );

        _decreaseLendingShares(
            _nftIdCaller,
            _poolToken,
            _lendingShares
        );

        _decreaseTotalBorrowShares(
            _poolToken,
            borrowShareEquivalent
        );

        _decreasePositionMappingValue(
            userBorrowShares,
            _nftIdReceiver,
            _poolToken,
            borrowShareEquivalent
        );
    }

    /**
     * @dev Internal math function for liquidation logic
     * caluclating amount to withdraw from pure
     * collateral for liquidation.
     */
    function _withdrawPureCollateralLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _percentLiquidation
    )
        internal
        returns (uint256 transfereAmount)
    {
        transfereAmount = _percentLiquidation
            * positionPureCollateralAmount[_nftId][_poolToken]
            / PRECISION_FACTOR_E18;

        _decreasePositionMappingValue(
            positionPureCollateralAmount,
            _nftId,
            _poolToken,
            transfereAmount
        );

        _decreaseTotalBareToken(
            _poolToken,
            transfereAmount
        );
    }

    /**
     * @dev Internal math function for liquidation logic
     * which checks if pool has enough token to pay out
     * liquidator. If not, liquidator get corresponding
     * shares for later withdraw.
     */
    function _withdrawOrAllocateSharesLiquidation(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _poolToken,
        uint256 _percantageWishCollat
    )
        internal
        returns (uint256)
    {
        uint256 cashoutShares = _percantageWishCollat
            * getPositionLendingShares(
                _nftId,
                _poolToken
            ) / PRECISION_FACTOR_E18;

        uint256 cashoutAmount = cashoutAmount(
            _poolToken,
            cashoutShares
        );

        uint256 totalPoolToken = getTotalPool(
            _poolToken
        );

        if (cashoutAmount <= totalPoolToken) {

            _coreWithdrawBare(
                _nftId,
                _poolToken,
                cashoutAmount,
                cashoutShares
            );

            return cashoutAmount;
        }

        uint256 totalPoolInShares = calculateLendingShares(
            _poolToken,
            totalPoolToken
        );

        uint256 shareDifference = cashoutShares
            - totalPoolInShares;

        _coreWithdrawBare(
            _nftId,
            _poolToken,
            totalPoolToken,
            totalPoolInShares
        );

        _decreaseLendingShares(
            _nftId,
            _poolToken,
            shareDifference
        );

        _increasePositionLendingDeposit(
            _nftIdLiquidator,
            _poolToken,
            shareDifference
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionLending,
            positionLendingTokenData
        );

        return totalPoolToken;
    }

    /**
     * @dev Internal math function combining functionallity
     * of {_withdrawPureCollateralLiquidation} and
     * {_withdrawOrAllocateSharesLiquidation}.
     */
    function _calculateReceiveAmount(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _receiveTokens,
        uint256 _removePercentage
    )
        internal
        returns (uint256)
    {
        uint256 receiveAmount = _withdrawPureCollateralLiquidation(
            _nftId,
            _receiveTokens,
            _removePercentage
        );

        if (isDecollteralized(_nftId, _receiveTokens) == true) {
            return receiveAmount;
        }

        return _withdrawOrAllocateSharesLiquidation(
            _nftId,
            _nftIdLiquidator,
            _receiveTokens,
            _removePercentage
        ) + receiveAmount;
    }

    /**
     * @dev Core liquidation function for
     * security checks and liquidation math.
     */
    function _coreLiquidation(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _caller,
        address _receiver,
        address _tokenToPayback,
        address _tokenToRecieve,
        uint256 _paybackAmount,
        uint256 _shareAmountToPay,
        uint256 _maxFeeUSD,
        uint256 _baseRewardLiquidation
    )
        internal
        returns (uint256 receiveAmount)
    {
        uint256 paybackUSD = WISE_ORACLE.getTokensInUSD(
            _tokenToPayback,
            _paybackAmount
        );

        uint256 collateralPercenage = WISE_SECURITY.calculateWishPercentage(
            _nftId,
            _tokenToRecieve,
            paybackUSD,
            _maxFeeUSD,
            _baseRewardLiquidation
        );

        if (collateralPercenage > PRECISION_FACTOR_E18) {
            revert CollateralTooSmall();
        }

        _corePayback(
            _nftId,
            _tokenToPayback,
            _paybackAmount,
            _shareAmountToPay
        );

        receiveAmount = _calculateReceiveAmount(
            _nftId,
            _nftIdLiquidator,
            _tokenToRecieve,
            collateralPercenage
        );

        WISE_SECURITY.checkBadDebt(
            _nftId
        );

        _safeTransferFrom(
            _tokenToPayback,
            _caller,
            address(this),
            _paybackAmount
        );

        _safeTransfer(
            _tokenToRecieve,
            _receiver,
            receiveAmount
        );
    }
}