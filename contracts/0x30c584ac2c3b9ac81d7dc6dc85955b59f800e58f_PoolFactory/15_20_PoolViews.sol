// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

// Inheritance Contacts
import "./PoolHelper.sol";

contract PoolViews is PoolHelper {

    /**
     * @dev External view function to get the current auction price of a NFT when
     * passing the correct merkle price from merkle tree.
     */
    function getCurrentAuctionPrice(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        view
        returns (uint256)
    {
        return _getCurrentAuctionPrice(
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );
    }

    /**
     * @dev Merkleproof check if a claim for a tokenprice is correct
     */
    function checkCollateralValue(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        view
        returns (bool)
    {
        return _checkCollateralValue(
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );
    }

    /**
     * @dev View function for returning
     * the current apy of the system.
     */
    function getCurrentDepositAPY()
        external
        view
        returns (uint256)
    {
        return borrowRate
            * (PRECISION_FACTOR_E18 - fee)
            * totalTokensDue
            / pseudoTotalTokensHeld
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev View function for UI for returning
     * borrowApy after utilisation has been increased by borrowAmount
     */
    function getBorrowRateAfterBorrowAmount(
        uint256 _borrowAmount
    )
        external
        view
        returns (uint256)
    {
        if (_borrowAmount > totalPool) {
            revert("LiquidPool: AMOUNT_TOO_HIGH");
        }

        uint256 newUtilisation = PRECISION_FACTOR_E18 - (
            PRECISION_FACTOR_E18
            * (totalPool - _borrowAmount)
            / pseudoTotalTokensHeld
        );

        return multiplicativeFactor
            * newUtilisation
            * PRECISION_FACTOR_E18
            / ((pole - newUtilisation) * pole);
    }

    /**
     * @dev View function for UI for returning
     * the interest which would be payed back in case user triggers paybackFunds
     * deadline is the timestamp of when the transaction will be mined therefore
     * taking in delays between signing and mined transaction into account.
     */
    function getLoanInterest(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _deadline
    )
        external
        view
        returns (uint256)
    {
        Loan memory loanData = currentLoans[_nftAddress][_nftTokenId];

        uint256 currentLoanValue = getTokensFromBorrowShares(
            loanData.borrowShares
        );

        uint256 timeChange = _deadline
            - block.timestamp;

        uint256 marginInterest = timeChange
            * borrowRate
            * totalTokensDue
            / ONE_YEAR_PRECISION_E18;

        return currentLoanValue
            + marginInterest
            - loanData.principalTokens;
    }

    /**
     * @dev Calculating help function
     * to factor in future predicted value check
     */
    function getMarkovAdjust(
        uint256 _timeAdjusted
    )
        public
        view
        returns (uint256)
    {
        return markovMean
            * _timeAdjusted
            + ONE_YEAR_PRECISION_E18;
    }

    /**
     * @dev UI help function to display borrowMax factoring in delay between
     * signing and mined transaction aswell as markov apy for
     * predicted future loan value check
     */
    function getBorrowMaximum(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merklePrice,
        uint256 _deadline
    )
        external
        view
        returns (uint256)
    {
        uint256 maxBorrow = getMaximumBorrow(
            merklePriceInPoolToken(
                _merklePrice
            )
        );

        uint256 timeAdjusted = _deadline
            + TIME_BETWEEN_PAYMENTS
            - block.timestamp;

        address loanOwner = getLoanOwner(
            _nftAddress,
            _nftTokenId
        );

        if (loanOwner == EMPTY_ADDRESS) {
            return ONE_YEAR_PRECISION_E18
    	       * maxBorrow
    	       / getMarkovAdjust(timeAdjusted);
        }

        uint256 currentLoanValue = getTokensFromBorrowShares(
            getCurrentBorrowShares(
                _nftAddress,
                _nftTokenId
            )
        );

        if (currentLoanValue > maxBorrow) return 0;

        uint256 term1 = ONE_YEAR_PRECISION_E18
            * (maxBorrow - currentLoanValue);

        uint256 term2 = timeAdjusted
            * markovMean
            * currentLoanValue;

        if (term2 > term1) return 0;

        return (term1 - term2) / getMarkovAdjust(
            timeAdjusted
        );
    }


    /**
    * @dev UI help function to calculate min principal amount to be payed back
    * in order to extend loan factoring in delays in signing and mining aswell
    * as predictedFutureLoanValue and merkleprice
    */
    function getPrincipalPayBackMinimum(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merklePrice,
        uint256 _deadline
    )
        external
        view
        returns (uint256)
    {
        uint256 timeAdjusted = _deadline
            + TIME_BETWEEN_PAYMENTS
            - block.timestamp;

        uint256 currentPrincipal = getPrincipalAmount(
            _nftAddress,
            _nftTokenId
        );

        uint256 maxBorrow = getMaximumBorrow(
            merklePriceInPoolToken(
                _merklePrice
            )
        );

        uint256 reductionTerm = maxBorrow
            * ONE_YEAR_PRECISION_E18
            / getMarkovAdjust(timeAdjusted);

        return
            currentPrincipal > reductionTerm ?
            currentPrincipal - reductionTerm : 0;
    }

    /**
     * @dev this functions is for helping UI
     */
    function maxWithdrawAmount(
        address _user
    )
        external
        view
        returns (
            uint256 returnValue,
            uint256 withdrawAmount
        )
    {
        withdrawAmount = calculateWithdrawAmount(
            internalShares[_user]
        );

        returnValue = withdrawAmount >= totalPool
            ? totalPool
            : withdrawAmount;
    }
}
