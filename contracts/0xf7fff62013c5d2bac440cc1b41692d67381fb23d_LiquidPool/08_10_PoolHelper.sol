// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

// Interfaces
import "./IChainLink.sol";

// Inheritance Contacts
import "./PoolBase.sol";
import "./PoolShareToken.sol";
import "./LiquidTransfer.sol";

contract PoolHelper is PoolBase, PoolShareToken, LiquidTransfer {

    /**
     * @dev Pure function that calculates how many borrow shares a specified amount of tokens are worth
     * Given the current number of shares and tokens in the pool.
     */
    function calculateDepositShares(
        uint256 _amount,
        uint256 _currentPoolTokens,
        uint256 _currentPoolShares
    )
        public
        pure
        returns (uint256)
    {
        return _amount
            * _currentPoolShares
            / _currentPoolTokens;
    }

    /**
     * @dev calculates the sum of tokenised and internal shares
     *
     */
    function getCurrentPoolShares()
        public
        view
        returns (uint256)
    {
        return totalInternalShares + totalSupply();
    }

    /**
     * @dev Function to calculate how many tokens a specified amount of deposits shares is worth
     * Considers both internal and token shares in this calculation.
     */
    function calculateWithdrawAmount(
        uint256 _shares
    )
        public
        view
        returns (uint256)
    {
        return _shares
            * pseudoTotalTokensHeld
            / getCurrentPoolShares();
    }

    /**
     * @dev Calculates the usage of the pool depending on the totalPool amount of token
     * inside the pool compared to the pseudoTotal amount
     */
    function _updateUtilisation()
        internal
    {
        utilisationRate = PRECISION_FACTOR_E18 - (totalPool
            * PRECISION_FACTOR_E18
            / pseudoTotalTokensHeld
        );
    }

    /**
     * @dev Calculates new markovMean (recursive formula)
     */
    function _newMarkovMean(
        uint256 _amount
    )
        internal
    {
        uint256 newValue = _amount
            * (PRECISION_FACTOR_E18 - MARKOV_FRACTION)
            + (markovMean * MARKOV_FRACTION);

        markovMean = newValue
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev sets and calculates the new borrow rate
     */
    function _newBorrowRate()
        internal
    {
        uint256 baseMultipicator = pole
            * (pole - utilisationRate);

        borrowRate = multiplicativeFactor
            * utilisationRate
            * PRECISION_FACTOR_E18
            / baseMultipicator;

        _newMarkovMean(
            borrowRate
        );
    }

    /**
     * @dev checking time threshold for scaling algorithm. Time between to iterations >= 3 hours
     */
    function _aboveThreshold()
        internal
        view
        returns (bool)
    {
        return block.timestamp - timeStampLastAlgorithm >= THREE_HOURS;
    }

    /**
     * @dev increases the pseudo total amounts for loaned and deposited token
     * interest generated is the same for both pools. borrower have to pay back the
     * new interest amount and lender get this same amount as rewards
     */
    function _updatePseudoTotalAmounts()
        internal
    {
        uint256 timeChange = block.timestamp
            - timeStampLastInteraction;

        uint256 amountInterest = timeChange
            * borrowRate
            * totalTokensDue
            / ONE_YEAR_PRECISION_E18;

        uint256 feeAmount = amountInterest
            * fee
            / PRECISION_FACTOR_E18;

        _increaseTotalTokensDue(
            amountInterest
        );

        if (badDebt > 0) {

            uint256 decreaseBadDebtAmount = badDebt < feeAmount
                ? badDebt
                : feeAmount;

            _decreaseBadDebt(
                decreaseBadDebtAmount
            );

            feeAmount -= decreaseBadDebtAmount;
            amountInterest -= decreaseBadDebtAmount;
        }

        _increasePseudoTotalTokens(
            amountInterest
        );

        timeStampLastInteraction = block.timestamp;

        if (feeAmount == 0) return;

        uint256 feeShares = feeAmount
            * getCurrentPoolShares()
            / (pseudoTotalTokensHeld - feeAmount);

        _increaseInternalShares(
            feeShares,
            feeDestinationAddress
        );

        _increaseTotalInternalShares(
            feeShares
        );
    }

    /**
     * @dev function that tries to maximise totalDepositShares of the pool. Reacting to negative and positive
     * feedback by changing the pole of the pool. Method similar to one parameter monte carlo methods
     */
    function _scalingAlgorithm()
        internal
    {
        uint256 totalShares = getCurrentPoolShares();

        if (maxPoolShares <= totalShares) {

            _newMaxPoolShares(
                totalShares
            );

            _saveUp(
                totalShares
            );

            return;
        }

        _poleOutcome(totalShares) == true
            ? _resetPole(totalShares)
            : _updatePole(totalShares);

        _saveUp(
            totalShares
        );
    }

    function _saveUp(
        uint256 _totalShares
    )
        internal
    {
        previousValue = _totalShares;
        timeStampLastAlgorithm = block.timestamp;
    }

    /**
     * @dev sets the new max value in shares and saves the corresponding pole.
     */
    function _newMaxPoolShares(
        uint256 _amount
    )
        internal
    {
        maxPoolShares = _amount;
        bestPole = pole;
    }

    /**
     * @dev returns bool to determine if pole needs to be reset to last best value.
     */
    function _poleOutcome(
        uint256 _shareValue
    )
        internal
        view
        returns (bool)
    {
        return _shareValue < maxPoolShares
            * THRESHOLD_RESET_POLE
            / ONE_HUNDRED;
    }

    /**
     * @dev resets pole to old best value when system evolves into too bad state.
     * sets current totalDepositShares amount to new maxPoolShares to exclude eternal loops and that
     * inorganic peaks do not set maxPoolShares forever
     */
    function _resetPole(
        uint256 _value
    )
        internal
    {
        maxPoolShares = _value;
        pole = bestPole;

        _revertDirectionSteppingState();
    }

    /**
     * @dev reverts the flag for stepping direction from scaling algorithm
     */
    function _revertDirectionSteppingState()
        internal
    {
        increasePole = !increasePole;
    }

    /**
     * @dev stepping function decreasing the pole depending on the time past in the last
     * time interval. Checks if current pole undergoes the min value. If this is the case
     * sets current value to minimal value
     */
    function _decreasePole()
        internal
    {
        uint256 delta = deltaPole
            * (block.timestamp - timeStampLastAlgorithm);

        uint256 sub = pole > delta
            ? pole - delta
            : 0;

        pole = sub < minPole
            ? minPole
            : sub;
    }

    /**
     * @dev Stepping function increasing the pole
     * depending on the time past in the last time interval.
     * Checks if current pole is bigger than max value.
     */
    function _increasePole()
        internal
    {
        uint256 delta = deltaPole
            * (block.timestamp - timeStampLastAlgorithm);

        uint256 sum = pole
            + delta;

        pole = sum > maxPole
            ? maxPole
            : sum;
    }

    /**
     * @dev Does a revert stepping and swaps stepping state in opposite flag
     */
    function _reversedChangingPole()
        internal
    {
        increasePole
            ? _decreasePole()
            : _increasePole();

        _revertDirectionSteppingState();
    }

    /**
     * @dev Increasing or decresing pole depending on flag value.
     */
    function _changingPole()
        internal
    {
        increasePole
            ? _increasePole()
            : _decreasePole();
    }

    /**
     * @dev Function combining all possible stepping scenarios.
     * Depending how share values has changed compared to last time
     */
    function _updatePole(
        uint256 _shareValues
    )
        internal
    {
        _shareValues < previousValue * THRESHOLD_SWITCH_DIRECTION / ONE_HUNDRED
            ? _reversedChangingPole()
            : _changingPole();
    }

    /**
     * @dev converts token amount to borrow share amount
     */
    function getBorrowShareAmount(
        uint256 _numTokensForLoan
    )
        public
        view
        returns (uint256)
    {
        return totalTokensDue == 0
            ? _numTokensForLoan
            : _numTokensForLoan * totalBorrowShares / totalTokensDue;
    }

    /**
     * @dev Math to convert borrow shares to tokens
     */
    function getTokensFromBorrowShares(
        uint256 _numBorrowShares
    )
        public
        view
        returns (uint256)
    {
        return _numBorrowShares
            * totalTokensDue
            / totalBorrowShares;
    }

    /**
     * @dev Adjust statevariables like shares and calls _deleteLoanData
     * to account for the fact that a loan has ended
     */
    function _endLoan(
        uint256 _borrowShares,
        address _tokenOwner,
        uint256 _nftTokenId,
        address _nftAddress
    )
        internal
    {
        uint256 tokenPaymentAmount = getTokensFromBorrowShares(
            _borrowShares
        );

        _decreaseTotalBorrowShares(
            _borrowShares
        );

        _decreaseTotalTokensDue(
            tokenPaymentAmount
        );

        _increaseTotalPool(
            tokenPaymentAmount
        );

        _deleteLoanData(
            _nftAddress,
            _nftTokenId
        );

        _transferNFT(
            address(this),
            _tokenOwner,
            _nftAddress,
            _nftTokenId
        );
    }

    /**
     * @dev Calculate what we expect a loan's future value to be using our markovMean as the average interest rate
     * For more information look up markov chains
     */
    function predictFutureLoanValue(
        uint256 _tokenValue
    )
        public
        view
        returns (uint256)
    {
        return _tokenValue
            * TIME_BETWEEN_PAYMENTS
            * markovMean
            / ONE_YEAR_PRECISION_E18
            + _tokenValue;
    }

    /**
     * @dev Compute hashes to verify merkle proof for input price
     */
    function _verifyMerkleProof(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {

            bytes32 proofElement = _proof[i];

            computedHash = computedHash <= proofElement
                ? keccak256(abi.encodePacked(computedHash, proofElement))
                : keccak256(abi.encodePacked(proofElement, computedHash));
        }

        return computedHash == _root;
    }

    /**
     * @dev Verifies claimed price of an NFT through merkleProof
     */
    function _checkCollateralValue(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] memory _merkleProof
    )
        internal
        view
        returns (bool)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _merkleIndex,
                _nftTokenId,
                _merklePrice
            )
        );

        return _verifyMerkleProof(
            _merkleProof,
            _getMerkleRoot(
                _nftAddress
            ),
            node
        );
    }

    /**
     * @dev Reads merkle root from the router
     * based on specific collection address
     */
    function _getMerkleRoot(
        address _nftAddress
    )
        internal
        view
        returns (bytes32)
    {
        return ROUTER.merkleRoot(
            _nftAddress
        );
    }

    /**
     * @dev Calculates maximum amount to borrow based on collateral factor and
     * merkleprice in ETH
     */
    function getMaximumBorrow(
        uint256 _merklePrice
    )
        public
        view
        returns (uint256)
    {
        return _merklePrice
            * maxCollateralFactor
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev Determines if duration since last payment exceeds allowed timeframe
     */
    function missedDeadline(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (bool)
    {
        uint256 nextDueTime = getNextPaymentDueTime(
            _nftAddress,
            _nftTokenId
        );

        return
            nextDueTime > 0 &&
            nextDueTime < block.timestamp;
    }

    /**
     * @dev Removes any token discrepancies
     * or if tokens accidentally sent to pool.
     */
    function _cleanUp()
        internal
    {
        uint256 totalBalance = _safeBalance(
            poolToken,
            address(this)
        );

        if (totalBalance > totalPool) {
            _safeTransfer(
                poolToken,
                feeDestinationAddress,
                totalBalance - totalPool
            );
        }
    }

    /**
     * @dev Calculates the current NFT auction price from merkle data and checks for proof.
     */
    function _getCurrentAuctionPrice(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        internal
        view
        returns (uint256)
    {
        require(
            _checkCollateralValue(
                _nftAddress,
                _nftTokenId,
                _merkleIndex,
                _merklePrice,
                _merkleProof
            ),
            "LiquidPool: INVALID_PROOF"
        );

        if (missedDeadline(_nftAddress, _nftTokenId) == false) {
            return merklePriceInPoolToken(
                _merklePrice
            );
        }

        return _dutchAuctionPrice(
            getLastPaidTime(
                _nftAddress,
                _nftTokenId
            ),
            merklePriceInPoolToken(
                _merklePrice
            )
        );
    }

    /**
     * @dev Returns the current auction price of an NFT depending on the time and current merkle price
     */
    function _dutchAuctionPrice(
        uint256 _lastPaidTime,
        uint256 _merklePrice
    )
        internal
        view
        returns (uint256)
    {
        return _merklePrice
            * _getCurrentPercentage(
                _lastPaidTime
            )
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev Calculates current percentage from the merkle price of the NFT.
     * Decreasement is a linear function of time
     * and has the minimum of 50% after 42 hours.
     * Takes lastPaidTime plus TIME_BETWEEN_PAYMENTS as starting value
     */
    function _getCurrentPercentage(
        uint256 _lastPaidTime
    )
        internal
        view
        returns (uint256)
    {
        uint256 blockTime = block.timestamp;

        if (blockTime > _lastPaidTime + MAX_AUCTION_TIMEFRAME) {
            return FIFTY_PERCENT;
        }

        uint256 secondsPassed = blockTime
            - _lastPaidTime
            - TIME_BETWEEN_PAYMENTS;

        return PRECISION_FACTOR_E18 - secondsPassed
            * FIFTY_PERCENT
            / AUCTION_TIMEFRAME;
    }

    /**
     * @dev Helper function that updates necessary parts
     * of the mapping to struct of a loan for a user
     */
    function _updateLoanBorrowMore(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _additionalShares,
        uint256 _additionalTokens
    )
        internal
    {
        currentLoans[_nftAddress][_nftTokenId].borrowShares += _additionalShares;
        currentLoans[_nftAddress][_nftTokenId].principalTokens += _additionalTokens;
    }

    /**
     * @dev Deals with state variables in case of badDebt occurring
     * during liquidation
     */
    function _checkBadDebt(
        uint256 _auctionPrice,
        uint256 _openBorrowAmount
    )
        internal
    {
        if (_auctionPrice < _openBorrowAmount) {

            _increaseTotalPool(
                _auctionPrice
            );

            _increaseBadDebt(
                _openBorrowAmount - _auctionPrice
            );

            return;
        }

        _increaseTotalPool(
            _openBorrowAmount
        );

        if (badDebt > 0) {

            uint256 extraFunds = _auctionPrice
                - _openBorrowAmount;

            uint256 decreaseBadDebtAmount = badDebt < extraFunds
                ? badDebt
                : extraFunds;

            _increaseTotalPool(
                decreaseBadDebtAmount
            );

            _decreaseBadDebt(
                decreaseBadDebtAmount
            );
        }
    }

    /**
     * @dev Helper function that updates the mapping to struct of a loan for a user.
     * Since a few operations happen here, this is a useful obfuscation for readability and reuse.
     */
    function _updateLoanBorrow(
        address _nftAddress,
        uint256 _nftTokenId,
        address _nftBorrower,
        uint256 _newBorrowShares,
        uint256 _newPrincipalTokens
    )
        internal
    {
        currentLoans[_nftAddress][_nftTokenId] = Loan({
            tokenOwner: _nftBorrower,
            borrowShares: _newBorrowShares,
            principalTokens: _newPrincipalTokens,
            lastPaidTime: uint48(block.timestamp)
        });
    }

    /**
     * @dev Updates variables in the loanstruct during paybackfunds
     */
    function _updateLoanPayback(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _borrowSharesToDestroy,
        uint256 _principalPayoff
    )
        internal
    {
        Loan memory loanData = currentLoans[_nftAddress][_nftTokenId];

        currentLoans[_nftAddress][_nftTokenId] = Loan({
            tokenOwner: loanData.tokenOwner,
            borrowShares: loanData.borrowShares - _borrowSharesToDestroy,
            principalTokens: loanData.principalTokens - _principalPayoff,
            lastPaidTime: uint48(block.timestamp)
        });
    }

    /**
     * Converts merkle price of NFTs
     * into corresponding pool token amount
     */
    function merklePriceInPoolToken(
        uint256 _merklePriceETH
    )
        public
        view
        returns (uint256)
    {
        if (chainLinkFeedAddress == chainLinkETH) {
            return _merklePriceETH;
        }

        if (chainLinkIsDead(chainLinkETH) == true) {
            revert("PoolHelper: DEAD_LINK_ETH");
        }

        if (chainLinkIsDead(chainLinkFeedAddress) == true) {
            revert("PoolHelper: DEAD_LINK_TOKEN");
        }

        uint256 valueETHinUSD = _merklePriceETH
            * IChainLink(chainLinkETH).latestAnswer()
            / 10 ** IChainLink(chainLinkETH).decimals();

        return valueETHinUSD
            * 10 ** IChainLink(chainLinkFeedAddress).decimals()
            / IChainLink(chainLinkFeedAddress).latestAnswer()
            / 10 ** (DECIMALS_ETH - poolTokenDecimals);
    }

    /**
     * @dev Check if chainLink feed was
     * updated within expected timeframe
     */
    function chainLinkIsDead(
        address _feed
    )
        public
        view
        returns (bool)
    {
        (   ,
            ,
            ,
            uint256 upd
            ,
        ) = IChainLink(_feed).latestRoundData();

        upd = block.timestamp > upd
            ? block.timestamp - upd
            : block.timestamp;

        return upd > ROUTER.chainLinkHeartBeat(
            _feed
        );
    }
}
