// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./LiquidPool.sol";

contract TesterPool is LiquidPool {

    constructor()
        LiquidPool()
    {}

    function setMarkovMean(
        uint256 _value
    )
        external
    {
        markovMean = _value;
    }

    function setTotalBorrowShares(
        uint256 _value
    )
        external
    {
        totalBorrowShares = _value;
    }

    function setUtilisation(
        uint256 _value
    )
        external
    {
        utilisationRate = _value;
    }

    function setPole(
        uint256 _value
    )
        external
    {
        pole = _value;
    }

    function setFee(
        uint256 _value
    )
        external
    {
        fee = _value;
    }

    function newBorrowRate()
        external
    {
        _newBorrowRate();
    }

    function setTotalTokensDue(
        uint256 _value
    )
        external
    {
        totalTokensDue = _value;
    }

    function setPseudoTotalTokensHeld(
        uint256 _value
    )
        external
    {
        pseudoTotalTokensHeld = _value;
    }

    function simulateBadDebt(
        address _liquidator,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _badDebtAmount
    )
        external
    {
        Loan memory loanData = currentLoans[_nftAddress][_nftTokenId];

        uint256 openBorrowAmount = getTokensFromBorrowShares(
            loanData.borrowShares
        );

        _decreaseTotalBorrowShares(
            loanData.borrowShares
        );

        _decreaseTotalTokensDue(
            openBorrowAmount
        );

        _increaseTotalPool(
            openBorrowAmount - _badDebtAmount
        );

        badDebt += _badDebtAmount;

        _deleteLoanData(
            _nftAddress,
            _nftTokenId
        );

        _safeTransferFrom(
            poolToken,
            _liquidator,
            address(this),
            openBorrowAmount - _badDebtAmount
        );

        _transferNFT(
            address(this),
            _liquidator,
            _nftAddress,
            _nftTokenId
        );
    }

    function getTimeStamp()
        external
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    function differencePseudo()
        external
        view
        returns (uint256)
    {
        uint256 tokenSums = totalPool
            + totalTokensDue;

        if (pseudoTotalTokensHeld < tokenSums){
            revert("badDebt_ACCOUNTING_WRONG");
        }
        return pseudoTotalTokensHeld-(totalPool+totalTokensDue);
    }

    function bytesIntoNumber(bytes32 _bytesInput)
        external
        pure
        returns (uint256)
    {
         return uint256(_bytesInput);
    }


}
