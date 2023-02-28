// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.18;

import "./ClaimerContract.sol";
import "./CollectorViews.sol";

error InvestmentTooLow();
error SelfReferralDetected();
error InvalidReferralAddress();

contract CollectorETH is CollectorViews {

    address public tokenDefiner;
    address public tokenAddress;
    address public bonusAddress;

    ClaimerContract public claimer;

    uint256 constant VESTING_TIME = 540 days;

    modifier onlyTokenDefiner() {
        require(
            msg.sender == tokenDefiner,
            "CollectorETH: INVALID_SENDER"
        );
        _;
    }

    modifier afterInvestmentPhase() {
        require(
            currentInvestmentDay() > INVESTMENT_DAYS,
            "CollectorETH: COLLECTOR_IN_PROGRESS"
        );
        _;
    }

    modifier afterSupplyGenerated() {
        require(
            g.generatedDays == fundedDays(),
            "CollectorETH: SUPPLY_NOT_GENERATED"
        );
        _;
    }

    modifier afterTokenProfitCreated() {
        require (
            g.generatedDays > 0 &&
            g.totalWeiContributed == 0,
            "CollectorETH: CREATE_TOKEN_PROFIT"
        );
        _;
    }

    constructor() {
        tokenDefiner = msg.sender;
        bonusAddress = msg.sender;
    }

    /** @dev Allows to define WISER token
      */
    function defineToken(
        address _tokenAddress
    )
        external
        onlyTokenDefiner
    {
        tokenAddress = _tokenAddress;
    }

    function defineBonus(
        address _bonusAddress
    )
        external
        onlyTokenDefiner
    {
        bonusAddress = _bonusAddress;
    }

    /** @dev Revokes access to define configs
      */
    function revokeAccess()
        external
        onlyTokenDefiner
    {
        tokenDefiner = address(0x0);
    }

    /** @dev Performs reservation of WISER tokens with ETH
      */
    function reserveWiser(
        uint8[] calldata _investmentDays,
        address _referralAddress
    )
        external
        payable
    {
        checkInvestmentDays(
            _investmentDays,
            currentInvestmentDay()
        );

        _reserveWiser(
            _investmentDays,
            _referralAddress,
            msg.sender,
            msg.value
        );
    }

    /** @notice Allows reservation of WISER tokens with other ERC20 tokens
      * @dev this will require this contract to be approved as spender
      */
    function reserveWiserWithToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _minExpected,
        uint8[] calldata _investmentDays,
        address _referralAddress
    )
        external
    {
        TokenERC20 _token = TokenERC20(
            _tokenAddress
        );

        _token.transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        _token.approve(
            address(UNISWAP_ROUTER),
            _tokenAmount
        );

        address[] memory _path = preparePath(
            _tokenAddress
        );

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapExactTokensForETH(
            _tokenAmount,
            _minExpected,
            _path,
            address(this),
            block.timestamp + 2 hours
        );

        checkInvestmentDays(
            _investmentDays,
            currentInvestmentDay()
        );

        _reserveWiser(
            _investmentDays,
            _referralAddress,
            msg.sender,
            amounts[1]
        );
    }

    function _reserveWiser(
        uint8[] memory _investmentDays,
        address _referralAddress,
        address _senderAddress,
        uint256 _senderValue
    )
        internal
    {
        if (_senderAddress == _referralAddress) {
            revert SelfReferralDetected();
        }

        if (isContract(_referralAddress) == true) {
            revert InvalidReferralAddress();
        }

        if (_senderValue < MIN_INVEST * _investmentDays.length) {
            revert InvestmentTooLow();
        }

        uint256 _investmentBalance = _referralAddress == address(0x0)
            ? _senderValue // no referral bonus
            : _senderValue * 1100 / 1000;

        uint256 _totalDays = _investmentDays.length;
        uint256 _dailyAmount = _investmentBalance / _totalDays;
        uint256 _leftOver = _investmentBalance % _totalDays;

        _addBalance(
            _senderAddress,
            _investmentDays[0],
            _dailyAmount + _leftOver
        );

        for (uint8 _i = 1; _i < _totalDays; _i++) {
            _addBalance(
                _senderAddress,
                _investmentDays[_i],
                _dailyAmount
            );
        }

        _trackInvestors(
            _senderAddress,
            _investmentBalance
        );

        originalInvestment[_senderAddress] += _senderValue;
        g.totalWeiContributed += _senderValue;

        if (_referralAddress == address(0x0)) {
            return;
        }

        _trackReferrals(
            _referralAddress,
            _senderValue
        );

        emit ReferralAdded(
            _referralAddress,
            _senderAddress,
            _senderValue
        );
    }

    /** @notice Allocates investors balance to specific day
      */
    function _addBalance(
        address _senderAddress,
        uint256 _investmentDay,
        uint256 _investmentBalance
    )
        internal
    {
        if (investorBalances[_senderAddress][_investmentDay] == 0) {
            investorAccounts[_investmentDay][investorAccountCount[_investmentDay]] = _senderAddress;
            investorAccountCount[_investmentDay]++;
        }

        investorBalances[_senderAddress][_investmentDay] += _investmentBalance;
        dailyTotalInvestment[_investmentDay] += _investmentBalance;

        emit WiseReservation(
            _senderAddress,
            _investmentDay,
            _investmentBalance
        );
    }

    /** @notice Tracks investorTotalBalance and uniqueInvestors
      * @dev used in _reserveWiser() internal function
      */
    function _trackInvestors(
        address _investorAddress,
        uint256 _value
    )
        internal
    {
        if (investorTotalBalance[_investorAddress] == 0) {
            uniqueInvestors[uniqueInvestorCount] = _investorAddress;
            uniqueInvestorCount++;
        }

        investorTotalBalance[_investorAddress] += _value;
    }

    /** @notice Tracks referralAmount and referralAccounts
      * @dev used in _reserveWiser() internal function
      */
    function _trackReferrals(
        address _referralAddress,
        uint256 _value
    )
        internal
    {
        if (referralAmount[_referralAddress] == 0) {
            referralAccounts[referralAccountCount] = _referralAddress;
            referralAccountCount++;
        }

        referralAmount[_referralAddress] += _value;
    }

    /** @notice Allows to generate supply for past funded days
      */
    function generateSupply()
        external
        afterInvestmentPhase
    {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {

            if (dailyTotalSupply[i] > 0) continue;
            if (dailyTotalInvestment[i] == 0) continue;

            dailyTotalSupply[i] = DAILY_SUPPLY;
            g.totalTransferTokens += DAILY_SUPPLY;

            g.generatedDays++;

            emit GeneratedStaticSupply(
                i,
                DAILY_SUPPLY
            );
        }
    }

    /** @notice Pre-calculates amount of tokens each referrer will get
      * @dev must run this for all referrer addresses in batches
      * converts _referralAmount to _referralTokens based on dailyRatio
      */
    function prepareReferralBonuses(
        uint256 _referralBatchFrom,
        uint256 _referralBatchTo
    )
        external
        afterInvestmentPhase
        afterSupplyGenerated
    {
        require(
            _referralBatchFrom < _referralBatchTo,
            "CollectorETH: INVALID_REFERRAL_BATCH"
        );

        require(
            g.preparedReferrals < referralAccountCount,
            "CollectorETH: REFERRALS_ALREADY_PREPARED"
        );

        uint256 _totalRatio = g.totalTransferTokens / g.totalWeiContributed;

        for (uint256 i = _referralBatchFrom; i < _referralBatchTo; i++) {

            address _referralAddress = referralAccounts[i];
            uint256 _referralAmount = referralAmount[_referralAddress];

            if (_referralAmount == 0) continue;

            g.preparedReferrals++;
            referralAmount[_referralAddress] = 0;

            if (_referralAmount < MINIMUM_REFERRAL) continue;

            uint256 referralBonus = _getReferralAmount(
                _referralAmount,
                _totalRatio
            );

            g.totalReferralTokens += referralBonus;
            referralTokens[_referralAddress] = referralBonus;
        }
    }

    /** @notice Creates tokenProfit contract aka WISER contract
      * and forwards all collected funds for the governance
      * also mints all the supply and locks in vesting contract
      */
    function createTokenProfitContract(/*🦉*/)
        external
        afterInvestmentPhase
        afterSupplyGenerated
    {
        require(
            g.preparedReferrals == referralAccountCount,
            "CollectorETH: REFERRALS_NOT_READY"
        );

        require(
            address(claimer) == address(0x0),
            "CollectorETH: ALREADY_CREATED"
        );

        claimer = new ClaimerContract(
            address(this),
            VESTING_TIME,
            tokenAddress
        );

        uint256 tokensForRef = g.totalReferralTokens;
        uint256 collectedETH = g.totalWeiContributed;
        uint256 tokensToMint = g.totalTransferTokens + tokensForRef;

        uint256 tokensToGift = LIMIT_REFERRALS > tokensForRef
            ? LIMIT_REFERRALS - tokensForRef
            : 0;

        payable(tokenAddress).transfer(
            collectedETH
        );

        WiserToken(tokenAddress).mintSupply(
            address(claimer),
            tokensToMint
        );

        WiserToken(tokenAddress).mintSupply(
            bonusAddress,
            tokensToGift
        );

        WiserToken(tokenAddress).mintSupply(
            bonusAddress,
            WISER_FUNDRAISE
        );

        g.totalWeiContributed = 0;
        g.totalTransferTokens = 0;
        g.totalReferralTokens = 0;
    }

    /** @notice Allows to start vesting of purchased tokens
      * from investor and referrer perspectives address
      * @dev can be called after createTokenProfitContract()
      */
    function startMyVesting(/*⏳*/)
        external
        afterTokenProfitCreated
    {
        uint256 locked = _payoutInvestorAddress(
            msg.sender
        );

        uint256 opened = _payoutReferralAddress(
            msg.sender
        );

        if (locked + opened == 0) return;

        claimer.enrollAndScrape(
            msg.sender,
            locked,
            opened,
            VESTING_TIME
        );
    }

    /** @notice Returns minting amount for specific investor address
      * @dev aggregades investors tokens across all investment days
      */
    function _payoutInvestorAddress(
        address _investorAddress
    )
        internal
        returns (uint256 payoutAmount)
    {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {

            uint256 balance = investorBalances[_investorAddress][i];

            if (balance == 0) continue;

            payoutAmount += balance
                * _calculateDailyRatio(i)
                / PRECISION_POINT;

            investorBalances[_investorAddress][i] = 0;
        }
    }

    /** @notice Returns minting amount for specific referrer address
      * @dev must be pre-calculated in prepareReferralBonuses()
      */
    function _payoutReferralAddress(
        address _referralAddress
    )
        internal
        returns (uint256)
    {
        uint256 payoutAmount = referralTokens[_referralAddress];

        if (referralTokens[_referralAddress] > 0) {
            referralTokens[_referralAddress] = 0;
        }

        return payoutAmount;
    }

    function requestRefund()
        external
        returns (uint256 _amount)
    {
        address investor = msg.sender;

        require(
            g.totalWeiContributed > 0  &&
            originalInvestment[investor] > 0 &&
            currentInvestmentDay() > INVESTMENT_DAYS + 15,
           "CollectorETH: REFUND_NOT_POSSIBLE"
        );

        _amount = originalInvestment[investor];
        originalInvestment[investor] = 0;
        g.totalTransferTokens = 0;

        payable(investor).transfer(
            _amount
        );
    }
}