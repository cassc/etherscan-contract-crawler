// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./WiseLowLevelHelper.sol";
import "./TransferHub/TransferHelper.sol";

abstract contract MainHelper is WiseLowLevelHelper, TransferHelper {

    /**
     * @dev Internal helper function for reservating a
     * position NFT id.
     */
    function _reservePosition()
        internal
        returns (uint256)
    {
        return POSITION_NFT.reservePositionForUser(
            msg.sender
        );
    }

    /**
     * @dev Helper function to convert {_amount}
     * of a certain pool with {_poolToken}
     * into lending shares. Includes devison
     * by zero and share security checks.
     * Needs latest pseudo amount for accurate
     * result.
     */
    function calculateLendingShares(
        address _poolToken,
        uint256 _amount
    )
        public
        view
        returns (uint256)
    {
        uint256 shares = getTotalDepositShares(
            _poolToken
        );

        if (shares <= 1) {
            return _amount;
        }

        uint256 pseudo = getPseudoTotalPool(
            _poolToken
        );

        if (pseudo == 0) {
            return _amount;
        }

        return _amount
            * shares
            / pseudo;
    }

    /**
     * @dev Helper function to convert {_amount}
     * of a certain pool with {_poolToken}
     * into borrow shares. Includes devison
     * by zero and share security checks.
     * Needs latest pseudo amount for accurate
     * result.
     */
    function calculateBorrowShares(
        address _poolToken,
        uint256 _amount
    )
        public
        view
        returns (uint256)
    {
        uint256 shares = getTotalBorrowShares(
            _poolToken
        );

        uint256 pseudo = getPseudoTotalBorrowAmount(
            _poolToken
        );

        if (shares <= 1) {
            return _amount;
        }

        if (pseudo == 0) {
            return _amount;
        }

        return _amount
            * shares
            / pseudo;
    }

    /**
     * @dev Helper function to convert {_shares}
     * of a certain pool with {_poolToken}
     * into lending token. Includes devison
     * by zero and share security checks.
     * Needs latest pseudo amount for accurate
     * result.
     */
    function cashoutAmount(
        address _poolToken,
        uint256 _shares
    )
        public
        view
        returns (uint256)
    {
        return _shares
            * getPseudoTotalPool(_poolToken)
            / getTotalDepositShares(_poolToken);
    }

    /**
     * @dev Helper function to convert {_shares}
     * of a certain pool with {_poolToken}
     * into borrow token. Includes devison
     * by zero and share security checks.
     * Needs latest pseudo amount for accurate
     * result.
     */
    function paybackAmount(
        address _poolToken,
        uint256 _shares
    )
        public
        view
        returns (uint256)
    {
        return _shares
            * getPseudoTotalBorrowAmount(_poolToken)
            / getTotalBorrowShares(_poolToken);
    }

    /**
     * @dev Internal helper combining one
     * security check with lending share
     * calculation for withdraw.
     */
    function _preparationsWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            _caller
        );

        return calculateLendingShares(
            _poolToken,
            _amount
        );
    }

    /**
     * @dev Internal helper calculating utilization
     * of pool with {_poolToken}. Includes math underflow
     * check.
     */
    function _getValueUtilization(
        address _poolToken
    )
        private
        view
        returns (uint256)
    {
        if (getTotalPool(_poolToken) >= getPseudoTotalPool(_poolToken)) {
            return 0;
        }

        return PRECISION_FACTOR_E18 - (PRECISION_FACTOR_E18
            * getTotalPool(_poolToken)
            / getPseudoTotalPool(_poolToken)
        );
    }

    /**
     * @dev Internal helper function setting new pool
     * utilization by calling {_getValueUtilization}.
     */
    function _updateUtilization(
        address _poolToken
    )
        private
    {
        globalPoolData[_poolToken].utilization = _getValueUtilization(
            _poolToken
        );
    }

    /**
     * @dev Internal helper function checking if
     * cleanup gathered new token to save into
     * pool variables.
     */
    function _checkCleanUp(
        uint256 _amountContract,
        uint256 _totalPool,
        uint256 _bareAmount
    )
        private
        pure
        returns (bool)
    {
        return _bareAmount + _totalPool >= _amountContract;
    }

    /**
     * @dev Internal helper function checking if falsely
     * sent token are inside the contract for the pool with
     * {_poolToken}. If this is the case it adds those token
     * to the pool by increasing pseudo and total amount.
     * In context of aToken from aave pools it gathers the
     * rebase amount from supply APY of aave pools.
     */
    function _cleanUp(
        address _poolToken
    )
        internal
    {
        uint256 amountContract = IERC20(_poolToken).balanceOf(
            address(this)
        );

        uint256 totalPool = getTotalPool(
            _poolToken
        );

        uint256 bareToken = getTotalBareToken(
            _poolToken
        );

        if (_checkCleanUp(amountContract, totalPool, bareToken)) {
            return;
        }

        uint256 diff = amountContract - (
            totalPool + bareToken
        );

        _increaseTotalAndPseudoTotalPool(
            _poolToken,
            diff
        );
    }

    /**
     * @dev External wrapper for {_preparePole}
     * Only callable by powerFarms, feeManager
     * and aaveHub.
     */
    function preparePool(
        address _poolToken
    )
        external
        onlyAllowedContracts
    {
        _preparePool(
            _poolToken
        );
    }

    /**
     * @dev External wrapper for {_newBorrowRate}
     * Only callable by powerFarms, feeManager
     * and aaveHub.
     */
    function newBorrowRate(
        address _poolToken
    )
        external
        onlyAllowedContracts
    {
        _newBorrowRate(
            _poolToken
        );
    }

    /**
     * @dev Internal helper function for
     * updating pools and calling {_cleanUp}.
     * Also includes re-entrancy guard for
     * curve pools security checks.
     */
    function _preparePool(
        address _poolToken
    )
        internal
    {
        WISE_SECURITY.curveSecurityCheck(
            _poolToken
        );

        _cleanUp(
            _poolToken
        );

        _updatePseudoTotalAmounts(
            _poolToken
        );
    }

    /**
     * @dev Internal helper function for
     * updating all borrow tokens of a
     * position.
     */
    function _preparationBorrows(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        _prepareTokens(
            _poolToken,
            positionBorrowTokenData[_nftId]
        );
    }

    /**
     * @dev Internal helper function for
     * updating all lending tokens of a
     * position.
     */
    function _preparationCollaterals(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        _prepareTokens(
            _poolToken,
            positionLendingTokenData[_nftId]
        );
    }

    /**
     * @dev Internal helper function for
     * updating pseudo amounts of a pool
     * inside {tokens} array and sets new
     * borrow rates.
     */
    function _prepareTokens(
        address _poolToken,
        address[] memory tokens
    )
        private
    {
        address currentAddress;

        for (uint8 i = 0; i < tokens.length; ++i) {

            currentAddress = tokens[i];

            if (currentAddress == _poolToken) {
                continue;
            }

            _preparePool(
                currentAddress
            );

            _newBorrowRate(
                currentAddress
            );
        }
    }

    /**
     * @dev Internal helper function
     * updating pseudo amounts and
     * printing fee shares for the
     * feeManager proportional to the
     * fee percentage of the pool.
     */
    function _updatePseudoTotalAmounts(
        address _poolToken
    )
        internal
    {
        uint256 currentTime = block.timestamp;

        uint256 bareIncrease = borrowPoolData[_poolToken].borrowRate
            * (currentTime - getTimeStamp(_poolToken))
            * getPseudoTotalBorrowAmount(_poolToken)
            + bufferIncrease[_poolToken];

        if (bareIncrease < PRECISION_FACTOR_E18_YEAR) {
            bufferIncrease[_poolToken] = bareIncrease;

            _setTimeStamp(
                _poolToken,
                currentTime
            );

            return;
        }

        delete bufferIncrease[_poolToken];

        uint256 amountInterest = bareIncrease
            / PRECISION_FACTOR_E18_YEAR;

        uint256 feeAmount = amountInterest
            * globalPoolData[_poolToken].poolFee
            / PRECISION_FACTOR_E18;

        _increasePseudoTotalBorrowAmount(
            _poolToken,
            amountInterest
        );

        _increasePseudoTotalPool(
            _poolToken,
            amountInterest
        );

        if (feeAmount == 0) {
            return;
        }

        uint256 feeShares = feeAmount
            * getTotalDepositShares(_poolToken)
            / (getPseudoTotalPool(_poolToken) - feeAmount);

        _increasePositionLendingDeposit(
            FEE_MANAGER_NFT,
            _poolToken,
            feeShares
        );

        _increaseTotalDepositShares(
            _poolToken,
            feeShares
        );

        _setTimeStamp(
            _poolToken,
            currentTime
        );
    }

    /**
     * @dev Internal increas function for
     * lending shares of a postion {_nftId}
     * and {_poolToken}.
     */
    function _increasePositionLendingDeposit(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        internal
    {
        userLendingData[_nftId][_poolToken].shares += _shares;
    }

    /**
     * @dev Internal decrease function for
     * lending shares of a postion {_nftId}
     * and {_poolToken}.
     */
    function _decreaseLendingShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        internal
    {
        userLendingData[_nftId][_poolToken].shares -= _shares;
    }

    /**
     * @dev Internal helper function adding a new
     * {_poolToken} token to {userTokenData} if needed.
     * Check is done by using hash maps.
     */
    function _addPositionTokenData(
        uint256 _nftId,
        address _poolToken,
        mapping(bytes32 => bool) storage hashMap,
        mapping(uint256 => address[]) storage userTokenData
    )
        internal
    {
        bytes32 hashData = _getHash(
            _nftId,
            _poolToken
        );

        if (hashMap[hashData] == true) {
            return;
        }

        hashMap[hashData] = true;

        userTokenData[_nftId].push(
            _poolToken
        );
    }

    /**
     * @dev Internal helper calculating
     * a hash out of {_nftId} and {_poolToken}
     * using keccak256.
     */
    function _getHash(
        uint256 _nftId,
        address _poolToken
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _nftId,
                _poolToken
            )
        );
    }

    /**
     * @dev Internal helper function deleting an
     * entry in {_deleteLastPositionData}.
     */
    function _removePositionData(
        uint256 _nftId,
        address _poolToken,
        function(uint256) view returns (uint256) _getPositionTokenLength,
        function(uint256, uint256) view returns (address) _getPositionTokenByIndex,
        function(uint256, address) internal _deleteLastPositionData,
        bool isLending
    )
        internal
    {
        uint256 length = _getPositionTokenLength(
            _nftId
        );

        if (length == 1) {
            _deleteLastPositionData(
                _nftId,
                _poolToken
            );

            return;
        }

        uint8 index;
        uint256 endPosition = length - 1;

        while (index < length) {

            if (_getPositionTokenByIndex(_nftId, index) != _poolToken) {
                index += 1;
                continue;
            }

            address poolToken = _getPositionTokenByIndex(
                _nftId,
                endPosition
            );

            isLending
                ? positionLendingTokenData[_nftId][index] = poolToken
                : positionBorrowTokenData[_nftId][index] = poolToken;

            _deleteLastPositionData(
                _nftId,
                _poolToken
            );

            break;
        }
    }

    /**
     * @dev Internal helper deleting last entry
     * of postion lending data.
     */
    function _deleteLastPositionLendingData(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        positionLendingTokenData[_nftId].pop();
        hashMapPositionLending[
            _getHash(
                _nftId,
                _poolToken
            )
        ] = false;
    }

    /**
     * @dev Internal helper deleting last entry
     * of postion borrow data.
     */
    function _deleteLastPositionBorrowData(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        positionBorrowTokenData[_nftId].pop();
        hashMapPositionBorrow[
            _getHash(
                _nftId,
                _poolToken
            )
        ] = false;
    }

    /**
     * @dev Internal helper function calculating
     * returning if a {_poolToken} of a {_nftId}
     * is decollateralized.
     */
    function isDecollteralized(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (bool)
    {
        return userLendingData[_nftId][_poolToken].deCollteralized;
    }

    /**
     * @dev Internal helper function calculating
     * the borrow share amount corresponding to
     * certain {_lendingShares}.
     */
    function _borrowShareEquivalent(
        address _poolToken,
        uint256 _lendingShares
    )
        internal
        view
        returns (uint256)
    {
        return _lendingShares
            * getPseudoTotalPool(_poolToken)
            * getTotalBorrowShares(_poolToken)
            / getTotalDepositShares(_poolToken)
            / getPseudoTotalBorrowAmount(_poolToken);
    }

    /**
     * @dev Internal helper function
     * checking if {_nftId} as no
     * {_poolToken} left.
     */
    function checkLendingDataEmpty(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (bool)
    {
        return userLendingData[_nftId][_poolToken].shares == 0
            && positionPureCollateralAmount[_nftId][_poolToken] == 0;
    }

    /**
     * @dev Internal helper function
     * calculating new borrow rates
     * for {_poolToken}. Uses smooth
     * functions of the form
     * f(x) = a * x /(p(p-x)) with
     * p > 1E18 the {pole} and
     * a the {mulFactor}.
     */

    function _calculateNewBorrowRate(
        address _poolToken
    )
        internal
    {
        uint256 pole = borrowRatesData[_poolToken].pole;
        uint256 utilization = globalPoolData[_poolToken].utilization;

        uint256 baseDivider = pole
            * (pole - utilization);

        _setBorrowRate(
            _poolToken,
            borrowRatesData[_poolToken].multiplicativeFactor
                * PRECISION_FACTOR_E18
                * utilization
                / baseDivider
        );
    }

    /**
     * @dev Internal helper function
     * updating utilization of the pool
     * with {_poolToken}, calculating the
     * new borrow rate and running LASA if
     * the time intervall of three hours has
     * passed.
     */
    function _newBorrowRate(
        address _poolToken
    )
        internal
    {
        _updateUtilization(
            _poolToken
        );

        _calculateNewBorrowRate(
            _poolToken
        );

        if (_aboveThreshold(_poolToken) == false) {
            return;
        }

        _scalingAlgorithm(
            _poolToken
        );
    }

    /**
     * @dev Internal helper function
     * checking if time interval for
     * next LASA call has passed.
     */
    function _aboveThreshold(
        address _poolToken
    )
        private
        view
        returns (bool)
    {
        return block.timestamp - _getTimeStampScaling(_poolToken) >= THREE_HOURS;
    }

    /**
     * @dev function that tries to maximise totalDepositShares of the pool.
     * Reacting to negative and positive feedback by changing the resonance
     * factor of the pool. Method similar to one parameter monte-carlo methods
     */
    function _scalingAlgorithm(
        address _poolToken
    )
        private
    {
        uint256 totalShares = getTotalDepositShares(
            _poolToken
        );

        if (algorithmData[_poolToken].maxValue <= totalShares) {

            _newMaxPoolShares(
                _poolToken,
                totalShares
            );

            _saveUp(
                _poolToken,
                totalShares
            );

            return;
        }

        _resonanceOutcome(_poolToken, totalShares) == true
            ? _resetResonanceFactor(_poolToken, totalShares)
            : _updateResonanceFactor(_poolToken, totalShares);

        _saveUp(
            _poolToken,
            totalShares
        );
    }

    /**
     * @dev Sets the new max value in shares
     * and saves the corresponding resonance factor.
     */
    function _newMaxPoolShares(
        address _poolToken,
        uint256 _shareValue
    )
        private
    {
        _setMaxValue(
            _poolToken,
            _shareValue
        );

        _setBestPole(
            _poolToken,
            borrowRatesData[_poolToken].pole
        );
    }

    /**
     * @dev Internal function setting {previousValue}
     * and {timestampScaling} for LASA of pool with
     * {_poolToken}.
     */
    function _saveUp(
        address _poolToken,
        uint256 _shareValue
    )
        private
    {
        _setPreviousValue(
            _poolToken,
            _shareValue
        );

        _setTimeStampScaling(
            _poolToken,
            block.timestamp
        );
    }

    /**
     * @dev Returns bool to determine if resonance
     * factor needs to be reset to last best value.
     */
    function _resonanceOutcome(
        address _poolToken,
        uint256 _shareValue
    )
        private
        view
        returns (bool)
    {
        return _shareValue < THRESHOLD_RESET_RESONANCE_FACTOR
            * algorithmData[_poolToken].maxValue
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev Resets resonance factor to old best value when system
     * evolves into too bad state and sets current totalDepositShares
     * amount to new maxPoolShares to exclude eternal loops and that
     * unorganic peaks do not set maxPoolShares forever.
     */
    function _resetResonanceFactor(
        address _poolToken,
        uint256 _shareValue
    )
        private
    {
        _setPole(
            _poolToken,
            algorithmData[_poolToken].bestPole
        );

        _setMaxValue(
            _poolToken,
            _shareValue
        );

        _revertDirectionSteppingState(
            _poolToken
        );
    }

    /**
     * @dev Reverts the flag for stepping direction from LASA.
     */
    function _revertDirectionSteppingState(
        address _poolToken
    )
        private
    {
        _setIncreasePole(
            _poolToken,
            !algorithmData[_poolToken].increasePole
        );
    }

    /**
     * @dev Function combining all possible stepping scenarios.
     * Depending how share values has changed compared to last time.
     */
    function _updateResonanceFactor(
        address _poolToken,
        uint256 _shareValues
    )
        private
    {
        _shareValues < THRESHOLD_SWITCH_DIRECTION * algorithmData[_poolToken].previousValue / PRECISION_FACTOR_E18
            ? _reversedChangingResonanceFactor(_poolToken)
            : _changingResonanceFactor(_poolToken);
    }

    /**
     * @dev Does a revert stepping and swaps stepping state in opposite flag.
     */
    function _reversedChangingResonanceFactor(
        address _poolToken
    )
        private
    {
        algorithmData[_poolToken].increasePole
            ? _decreaseResonanceFactor(_poolToken)
            : _increaseResonanceFactor(_poolToken);

        _revertDirectionSteppingState(
            _poolToken
        );
    }

    /**
     * @dev Increasing or decresing resonance factor depending on flag value.
     */
    function _changingResonanceFactor(
        address _poolToken
    )
        private
    {
        algorithmData[_poolToken].increasePole
            ? _increaseResonanceFactor(_poolToken)
            : _decreaseResonanceFactor(_poolToken);
    }

    /**
     * @dev stepping function increasing the resonance factor
     * depending on the time past in the last time interval.
     * Checks if current resonance factor is bigger than max value.
     * If this is the case sets current value to maximal value
     */
    function _increaseResonanceFactor(
        address _poolToken
    )
        private
    {
        BorrowRatesEntry memory borrowData = borrowRatesData[
            _poolToken
        ];

        uint256 delta = borrowData.deltaPole
            * (block.timestamp - _getTimeStampScaling(_poolToken));

        uint256 sum = delta
            + borrowData.pole;

        uint256 setValue = sum > borrowData.maxPole
            ? borrowData.maxPole
            : sum;

        _setPole(
            _poolToken,
            setValue
        );
    }

    /**
     * @dev Stepping function decresing the resonance factor
     * depending on the time past in the last time interval.
     * Checks if current resonance factor undergoes the min value,
     * if this is the case sets current value to minimal value.
     */
    function _decreaseResonanceFactor(
        address _poolToken
    )
        private
    {
        uint256 minValue = borrowRatesData[_poolToken].minPole;

        uint256 delta = borrowRatesData[_poolToken].deltaPole
            * (block.timestamp - _getTimeStampScaling(_poolToken));

        uint256 sub = borrowRatesData[_poolToken].pole > delta
            ? borrowRatesData[_poolToken].pole - delta
            : 0;

        uint256 setValue = sub < minValue
            ? minValue
            : sub;

        _setPole(
            _poolToken,
            setValue
        );
    }

    /**
     * @dev Internal helper function for removing token address
     * from lending data array if all shares are removed. When
     * feeManager (nftId = 0) is calling this function is skipped
     * to save gase for continues fee accounting.
     */
    function _removeEmptyLendingData(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        if (_nftId == 0) {
            return;
        }

        if (checkLendingDataEmpty(_nftId, _poolToken) == false) {
            return;
        }

        _removePositionData({
            _nftId: _nftId,
            _poolToken: _poolToken,
            _getPositionTokenLength: getPositionLendingTokenLength,
            _getPositionTokenByIndex: getPositionLendingTokenByIndex,
            _deleteLastPositionData: _deleteLastPositionLendingData,
            isLending: true
        });
    }

    /**
     * @dev Internal helper function grouping several function
     * calls into one function for refactoring and code size
     * reduction.
     */
    function _updatePoolStorage(
        address _poolToken,
        uint256 _amount,
        uint256 _shares,
        function(address, uint256) functionAmountA,
        function(address, uint256) functionAmountB,
        function(address, uint256) functionSharesA
    )
        internal
    {
        functionAmountA(
            _poolToken,
            _amount
        );

        functionAmountB(
            _poolToken,
            _amount
        );

        functionSharesA(
            _poolToken,
            _shares
        );
    }
}