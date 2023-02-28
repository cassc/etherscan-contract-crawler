// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.18;

import "./CollectorDeclaration.sol";

contract CollectorViews is CollectorDeclaration {

    /** @notice checks for callers investment amount on specific day (with bonus)
      * @return total amount invested across all investment days (with bonus)
      */
    function myInvestmentAmount(
        uint256 _investmentDay
    )
        external
        view
        returns (uint256)
    {
        return investorBalances[msg.sender][_investmentDay];
    }

    /** @notice checks for callers investment amount on each day (with bonus)
      * @return _myAllDays total amount invested across all days (with bonus)
      */
    function myInvestmentAmountAllDays()
        external
        view
        returns (uint256[51] memory _myAllDays)
    {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _myAllDays[i] = investorBalances[msg.sender][i];
        }
    }

    /** @notice checks for callers total investment amount (with bonus)
      * @return total amount invested across all investment days (with bonus)
      */
    function myTotalInvestmentAmount()
        external
        view
        returns (uint256)
    {
        return investorTotalBalance[msg.sender];
    }

    /** @notice checks for investors count on specific day
      * @return investors count for specific day
      */
    function investorsOnDay(
        uint256 _investmentDay
    )
        external
        view
        returns (uint256)
    {
        return dailyTotalInvestment[_investmentDay] > 0
            ? investorAccountCount[_investmentDay]
            : 0;
    }

    /** @notice checks for investors count on each day
      * @return _allInvestors array with investors count for each day
      */
    function investorsOnAllDays()
        external
        view
        returns (uint256[51] memory _allInvestors)
    {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestors[i] = dailyTotalInvestment[i] > 0
            ? investorAccountCount[i]
            : 0;
        }
    }

    /** @notice checks for investment amount on each day
      * @return _allInvestments array with investment amount for each day
      */
    function investmentsOnAllDays()
        external
        view
        returns (uint256[51] memory _allInvestments)
    {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestments[i] = dailyTotalInvestment[i];
        }
    }

    /** @notice checks for supply amount on each day
      * @return _allSupply array with supply amount for each day
      */
    function supplyOnAllDays()
        external
        view
        returns (uint256[51] memory _allSupply)
    {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allSupply[i] = dailyTotalSupply[i];
        }
    }

    /** @notice shows current investment day
      */
    function currentInvestmentDay()
        public
        view
        returns (uint256)
    {
        return block.timestamp > INCEPTION_TIME
            ? (block.timestamp - INCEPTION_TIME) / SECONDS_IN_DAY + 1
            : 0;
    }

    function isContract(
        address _walletAddress
    )
        public
        view
        returns (bool)
    {
        uint32 size;
        assembly {
            size := extcodesize(
                _walletAddress
            )
        }
        return (size > 0);
    }

    /** @notice prepares path variable for uniswap to exchange tokens
      * @dev used in reserveWiserWithToken() swapExactTokensForETH call
      */
    function preparePath(
        address _tokenAddress
    )
        public
        pure
        returns
    (
        address[] memory _path
    ) {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH;
    }

    /** @notice checks that provided days are valid for investemnt
      * @dev used in reserveWise() and reserveWiseWithToken()
      */
    function checkInvestmentDays(
        uint8[] memory _investmentDays,
        uint256 _investmentDay
    )
        public
        pure
    {
        for (uint8 _i = 0; _i < _investmentDays.length; _i++) {
            require(
                _investmentDays[_i] >= _investmentDay,
                "CollectorViews: DAY_ALREADY_PASSED"
            );
            require(
                _investmentDays[_i] > 0 &&
                _investmentDays[_i] <= INVESTMENT_DAYS,
                "CollectorViews: INVALID_INVESTMENT_DAY"
            );
        }
    }

    /** @notice checks for invesments on all days
      * @dev used in createTokenProfitContract()
      */
    function fundedDays()
        public
        view
        returns (uint8 $fundedDays)
    {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (dailyTotalInvestment[i] > 0) {
                $fundedDays++;
            }
        }
    }

    /** @notice WISER equivalent in ETH price calculation
      * @dev returned value has 100E18 precision point
      */
    function _calculateDailyRatio(
        uint256 _investmentDay
    )
        internal
        view
        returns (uint256)
    {
        uint256 dailyRatio = dailyTotalSupply[_investmentDay]
            * PRECISION_POINT
            / dailyTotalInvestment[_investmentDay];

        uint256 remainderCheck = dailyTotalSupply[_investmentDay]
            * PRECISION_POINT
            % dailyTotalInvestment[_investmentDay];

        return remainderCheck == 0
            ? dailyRatio
            : dailyRatio + 1;
    }

    /** @notice calculates referral bonus
      */
    function _getReferralAmount(
        uint256 _referralAmount,
        uint256 _ratio
    )
        internal
        pure
        returns (uint256)
    {
        return _referralAmount / REFERRAL_BONUS * _ratio;
    }
}