// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../Types/NoteKeeper.sol";

import "../Libraries/SafeERC20.sol";

import "../Interfaces/IERC20Metadata.sol";
import "../Interfaces/IBondDepository.sol";
import "../Interfaces/ITreasury.sol";
import "../Interfaces/IBondCalculator.sol";

/**
 * @title Theopetra Bond Depository
 * @notice Originally based off of Olympus Bond Depository V2
 */

contract TheopetraBondDepository is IBondDepository, NoteKeeper {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /* ======== EVENTS ======== */

    event CreateMarket(uint256 indexed id, address indexed baseToken, address indexed quoteToken, uint256 initialPrice);
    event CloseMarket(uint256 indexed id);
    event Bond(uint256 indexed id, uint256 amount, uint256 price);
    event SetDYB(uint256 indexed id, int64 dYB);
    event SetDRB(uint256 indexed id, int64 dRB);

    /* ======== STATE VARIABLES ======== */

    // Storage
    Market[] public markets; // persistent market data
    Terms[] public terms; // deposit construction data
    Metadata[] public metadata; // extraneous market data

    // Queries
    mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token

    /* ======== STRUCTS ======== */

    struct PriceInfo {
        uint256 price;
        uint48 bondRateVariable;
    }

    /* ======== CONSTRUCTOR ======== */

    constructor(
        ITheopetraAuthority _authority,
        IERC20 _theo,
        IStakedTHEOToken _stheo,
        IStaking _staking,
        ITreasury _treasury
    ) NoteKeeper(_authority, _theo, _stheo, _staking, _treasury) {
        // save gas for users by bulk approving stake() transactions
        _theo.approve(address(_staking), 1e45);
    }

    /* ======== DEPOSIT ======== */

    /**
     * @notice             deposit quote tokens in exchange for a bond from a specified market
     * @param _id          the ID of the market
     * @param _amount      the amount of quote token to spend
     * @param _maxPrice    the maximum price at which to buy
     * @param _user        the recipient of the payout
     * @param _referral    the front end operator address
     * @return payout_     the amount of sTHEO due
     * @return expiry_     the timestamp at which payout is redeemable
     * @return index_      the user index of the Note (used to redeem or query information)
     */
    function deposit(
        uint256 _id,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral,
        bool _autoStake
    )
        external
        override
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        )
    {
        // prevent "stack too deep"
        DepositArgs memory depositInfo = DepositArgs(_id, _amount, _maxPrice, _user, _referral, _autoStake);

        Market storage market = markets[depositInfo.id];
        Terms memory term = terms[depositInfo.id];
        PriceInfo memory priceInfo;
        uint48 currentTime = uint48(block.timestamp);

        // Markets end at a defined timestamp
        // |-------------------------------------| t
        require(currentTime < term.conclusion, "Depository: market concluded");

        // Debt decays over time
        _decay(depositInfo.id, currentTime);

        // Users input a maximum price, which protects them from price changes after
        // entering the mempool. max price is a slippage mitigation measure
        priceInfo.price = marketPrice(depositInfo.id);
        require(priceInfo.price <= depositInfo.maxPrice, "Depository: more than max price");
        /**
         * payout for the deposit = amount / price
         *
         * where
         * payout = THEO out
         * amount = quote tokens in
         * price = quote tokens : theo (i.e. 42069 DAI : THEO)
         *
         * 1e18 = THEO decimals (9) + price decimals (9)
         */
        payout_ = ((depositInfo.amount * 1e18) / priceInfo.price) / (10**metadata[depositInfo.id].quoteDecimals);

        // markets have a max payout amount, capping size because deposits
        // do not experience slippage. max payout is recalculated upon tuning
        require(payout_ <= market.maxPayout, "Depository: max size exceeded");

        /*
         * each market is initialized with a capacity
         *
         * this is either the number of THEO that the market can sell
         * (if capacity in quote is false),
         *
         * or the number of quote tokens that the market can buy
         * (if capacity in quote is true)
         */
        market.capacity -= market.capacityInQuote ? depositInfo.amount : payout_;

        /**
         * bonds mature with a cliff at a set timestamp
         * prior to the expiry timestamp, no payout tokens are accessible to the user
         * after the expiry timestamp, the entire payout can be redeemed
         *
         * there are two types of bonds: fixed-term and fixed-expiration
         *
         * fixed-term bonds mature in a set amount of time from deposit
         * i.e. term = 1 week. when alice deposits on day 1, her bond
         * expires on day 8. when bob deposits on day 2, his bond expires day 9.
         *
         * fixed-expiration bonds mature at a set timestamp
         * i.e. expiration = day 10. when alice deposits on day 1, her term
         * is 9 days. when bob deposits on day 2, his term is 8 days.
         */
        expiry_ = term.fixedTerm ? term.vesting + currentTime : term.vesting;

        // markets keep track of how many quote tokens have been
        // purchased, and how much THEO has been sold
        market.purchased += depositInfo.amount;
        market.sold += payout_;

        // increment total debt, which is later compared to maxDebt (this can be a circuit-breaker)
        market.totalDebt += payout_;

        emit Bond(depositInfo.id, depositInfo.amount, priceInfo.price);

        /**
         * user data is stored as Notes. these are isolated array entries
         * storing the amount due, the time created, the time when payout
         * is redeemable, the time when payout was redeemed, the ID
         * of the market deposited into, and the Bond Rate Variable (Brv) discount on the bond
         */
        priceInfo.bondRateVariable = uint48(bondRateVariable(depositInfo.id));
        index_ = addNote(
            depositInfo.user,
            payout_,
            uint48(expiry_),
            uint48(depositInfo.id),
            depositInfo.referral,
            priceInfo.bondRateVariable,
            depositInfo.autoStake
        );

        // transfer payment to treasury
        market.quoteToken.safeTransferFrom(msg.sender, address(treasury), depositInfo.amount);

        // if max debt is breached, the market is closed
        // this a circuit breaker
        if (term.maxDebt < market.totalDebt) {
            market.capacity = 0;
            emit CloseMarket(depositInfo.id);
        } else {
            // if market will continue, the control variable is tuned to hit targets on time
            _tune(depositInfo.id, currentTime);
        }
    }

    /**
     * @notice             decay debt, and adjust control variable if there is an active change
     * @param _id          ID of market
     * @param _time        uint48 timestamp (saves gas when passed in)
     */
    function _decay(uint256 _id, uint48 _time) internal {
        // Debt decay

        /*
         * Debt is a time-decayed sum of tokens spent in a market
         * Debt is added when deposits occur and removed over time
         * |
         * |    debt falls with
         * |   / \  inactivity       / \
         * | /     \              /\/    \
         * |         \           /         \
         * |           \      /\/            \
         * |             \  /  and rises       \
         * |                with deposits
         * |
         * |------------------------------------| t
         */
        markets[_id].totalDebt -= debtDecay(_id);
        metadata[_id].lastDecay = _time;
    }

    /**
     * @notice          adjust the market's maxPayout
     * @dev             calculate the correct payout to complete on time assuming each bond
     *                  will be max size in the desired deposit interval for the remaining time
     *                  i.e. market has 10 days remaining. deposit interval is 1 day. capacity
     *                  is 10,000 THEO. max payout would be 1,000 THEO (10,000 * 1 / 10).
     * @param _id       ID of market
     * @param _time     uint48 timestamp (saves gas when passed in)
     */
    function _tune(uint256 _id, uint48 _time) internal {
        Metadata memory meta = metadata[_id];

        if (_time >= meta.lastTune + meta.tuneInterval) {
            Market memory market = markets[_id];

            // compute seconds remaining until market will conclude
            uint256 timeRemaining = terms[_id].conclusion - _time;
            uint256 price = marketPrice(_id);

            // standardize capacity into a base token amount
            // theo decimals (9) + price decimals (9)
            uint256 capacity = market.capacityInQuote
                ? ((market.capacity * 1e18) / price) / (10**meta.quoteDecimals)
                : market.capacity;

            markets[_id].maxPayout = uint256((capacity * meta.depositInterval) / timeRemaining);

            metadata[_id].lastTune = _time;
        }
    }

    /* ======== CREATE ======== */

    /**
     * @notice             creates a new market type
     * @dev                current price should be in 9 decimals.
     * @param _quoteToken  token used to deposit
     * @param _market      [capacity (in THEO or quote), initial price / THEO (9 decimals), debt buffer (3 decimals)]
     * @param _booleans    [capacity in quote, fixed term]
     * @param _terms       [vesting length (if fixed term) or vested timestamp, conclusion timestamp]
     * @param _rates       [bondRateFixed, maxBondRateVariable, initial discountRateBond (Drb), initial discountRateYield (Dyb)]
     * @param _intervals   [deposit interval (seconds), tune interval (seconds)]
     * @return id_         ID of new bond market
     */
    function create(
        IERC20 _quoteToken,
        uint256[3] memory _market,
        bool[2] memory _booleans,
        uint256[2] memory _terms,
        int64[4] memory _rates,
        uint64[2] memory _intervals
    ) external override onlyPolicy returns (uint256 id_) {
        // the length of the program, in seconds
        uint256 secondsToConclusion = _terms[1] - block.timestamp;

        // the decimal count of the quote token
        uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();

        /*
         * initial target debt is equal to capacity (this is the amount of debt
         * that will decay over in the length of the program if price remains the same).
         * it is converted into base token terms if passed in in quote token terms.
         *
         * 1e18 = theo decimals (9) + initial price decimals (9)
         */
        uint256 targetDebt = uint256(_booleans[0] ? ((_market[0] * 1e18) / _market[1]) / 10**decimals : _market[0]);

        /*
         * max payout is the amount of capacity that should be utilized in a deposit
         * interval. for example, if capacity is 1,000 THEO, there are 10 days to conclusion,
         * and the preferred deposit interval is 1 day, max payout would be 100 THEO.
         */
        uint256 maxPayout = (targetDebt * _intervals[0]) / secondsToConclusion;

        /*
         * max debt serves as a circuit breaker for the market. let's say the quote
         * token is a stablecoin, and that stablecoin depegs. without max debt, the
         * market would continue to buy until it runs out of capacity. this is
         * configurable with a 3 decimal buffer (1000 = 1% above initial price).
         * note that its likely advisable to keep this buffer wide.
         * note that the buffer is above 100%. i.e. 10% buffer = initial debt * 1.1
         */
        uint256 maxDebt = targetDebt + ((targetDebt * _market[2]) / 1e5); // 1e5 = 100,000. 10,000 / 100,000 = 10%.

        // depositing into, or getting info for, the created market uses this ID
        id_ = markets.length;

        markets.push(
            Market({
                quoteToken: _quoteToken,
                capacityInQuote: _booleans[0],
                capacity: _market[0],
                totalDebt: targetDebt,
                maxPayout: maxPayout,
                purchased: 0,
                sold: 0
            })
        );

        terms.push(
            Terms({
                fixedTerm: _booleans[1],
                vesting: uint48(_terms[0]),
                conclusion: uint48(_terms[1]),
                bondRateFixed: int64(_rates[0]),
                maxBondRateVariable: int64(_rates[1]),
                discountRateBond: int64(_rates[2]),
                discountRateYield: int64(_rates[3]),
                maxDebt: maxDebt
            })
        );

        metadata.push(
            Metadata({
                lastTune: uint48(block.timestamp),
                lastDecay: uint48(block.timestamp),
                length: uint48(secondsToConclusion),
                depositInterval: uint64(_intervals[0]),
                tuneInterval: uint64(_intervals[1]),
                quoteDecimals: uint8(decimals)
            })
        );

        marketsForQuote[address(_quoteToken)].push(id_);

        emit CreateMarket(id_, address(theo), address(_quoteToken), _market[1]);
    }

    /**
     * @notice             disable existing market
     * @param _id          ID of market to close
     */
    function close(uint256 _id) external override onlyPolicy {
        terms[_id].conclusion = uint48(block.timestamp);
        markets[_id].capacity = 0;
        emit CloseMarket(_id);
    }

    /* ======== BONDING RATES ======== */

    /**
     * @notice                      update the Discount Rate Return Bond (Drb) for a specified market
     * @param _id                   uint256 the ID of the bond market to update
     * @param _discountRateBond     uint64 the new Discount Rate Return Bond (Drb), 9 decimals
     */
    function setDiscountRateBond(uint256 _id, int64 _discountRateBond) external override onlyPolicy {
        terms[_id].discountRateBond = _discountRateBond;
        emit SetDRB(_id, _discountRateBond);
    }

    /**
     * @notice                      update the Discount Rate Return Yield (Dyb) for a specified market
     * @param _id                   uint256 the ID of the bond market to update
     * @param _discountRateYield    uint64 the new Discount Rate Return Yield (Dyb), 9 decimals
     */
    function setDiscountRateYield(uint256 _id, int64 _discountRateYield) external override onlyPolicy {
        terms[_id].discountRateYield = _discountRateYield;
        emit SetDYB(_id, _discountRateYield);
    }

    /**
     * @notice                  calculate bond rate variable (Brv)
     * @dev                     see marketPrice for calculation details.
     * @param _id               ID of market
     */
    function bondRateVariable(uint256 _id) public view override returns (uint256) {
        int256 bondRateVariable = int64(terms[_id].bondRateFixed) +
            ((int64(terms[_id].discountRateBond) * ITreasury(treasury).deltaTokenPrice()) / 10**9) + //deltaTokenPrice is 9 decimals
            ((int64(terms[_id].discountRateYield) * ITreasury(treasury).deltaTreasuryYield()) / 10**9); // deltaTreasuryYield is 9 decimals

        if (bondRateVariable <= 0) {
            return 0;
        } else if (bondRateVariable >= terms[_id].maxBondRateVariable) {
            return uint256(uint64(terms[_id].maxBondRateVariable));
        } else {
            return bondRateVariable.toUint256();
        }
    }

    /* ======== EXTERNAL VIEW ======== */

    /**
     * @notice             calculate current market price of quote token in base token (i.e. quote tokens per THEO)
     * @dev                uses the theoBondingCalculator.valuation method (using an amount of 1) to get the quote token value (Quote-Token per THEO).
     * @param _id          ID of market
     * @return             price for market in THEO decimals
     *
     * price is derived from the equation
     *
     * P = Cmv * (1 - Brv)
     *
     * where
     * p = price
     * cmv = current market value
     * Brv = bond rate, variable. This is a proportion (that is, a percentage in its decimal form), with 9 decimals
     *
     * Brv = Brf + Bcrb + Bcyb
     *
     * where
     * Brf = bond rate, fixed
     * Bcrb = Drb * deltaTokenPrice
     * Bcyb = Dyb * deltaTreasuryYield
     *
     *
     * where
     * Drb is a discount rate as a proportion (that is, a percentage in its decimal form) applied to the fluctuation in token price (deltaTokenPrice)
     * Dyb is a discount rate as a proportion (that is a percentage in its decimal form) applied to the fluctuation of the treasury yield (deltaTreasuryYield)
     * Drb, Dyb, deltaTokenPrice and deltaTreasuryYield are expressed as proportions (that is, they are a percentages in decimal form), with 9 decimals
     */
    function marketPrice(uint256 _id) public view override returns (uint256) {
        IBondCalculator theoBondingCalculator = ITreasury(NoteKeeper.treasury).getTheoBondingCalculator();
        if (address(theoBondingCalculator) == address(0)) {
            revert("No bonding calculator");
        }
        uint8 quoteTokenDecimals = IERC20Metadata(address(markets[_id].quoteToken)).decimals();
        return
            ((10**18 / (theoBondingCalculator.valuation(address(markets[_id].quoteToken), 10**quoteTokenDecimals))) *
                (10**9 - bondRateVariable(_id))) / 10**9;
    }

    /**
     * @notice             payout due for amount of quote tokens
     * @dev                accounts for debt and control variable decay so it is up to date
     * @param _amount      amount of quote tokens to spend
     * @param _id          ID of market
     * @return             amount of THEO to be paid in THEO decimals
     *
     * @dev 1e18 = theo decimals (9) + market price decimals (9)
     */
    function payoutFor(uint256 _amount, uint256 _id) external view override returns (uint256) {
        Metadata memory meta = metadata[_id];
        return (_amount * 1e18) / marketPrice(_id) / 10**meta.quoteDecimals;
    }

    /**
     * @notice             calculate debt factoring in decay
     * @dev                accounts for debt decay since last deposit
     * @param _id          ID of market
     * @return             current debt for market in THEO decimals
     */
    function currentDebt(uint256 _id) external view override returns (uint256) {
        return markets[_id].totalDebt - debtDecay(_id);
    }

    /**
     * @notice             amount of debt to decay from total debt for market ID
     * @param _id          ID of market
     * @return             amount of debt to decay
     */
    function debtDecay(uint256 _id) public view override returns (uint64) {
        Metadata memory meta = metadata[_id];

        uint256 secondsSince = block.timestamp - meta.lastDecay;

        return uint64((markets[_id].totalDebt * secondsSince) / meta.length);
    }

    /**
     * @notice             is a given market accepting deposits
     * @param _id          ID of market
     */
    function isLive(uint256 _id) public view override returns (bool) {
        return (markets[_id].capacity != 0 && terms[_id].conclusion > block.timestamp);
    }

    /**
     * @notice returns an array of all active market IDs
     */
    function liveMarkets() external view override returns (uint256[] memory) {
        uint256 num;
        for (uint256 i = 0; i < markets.length; i++) {
            if (isLive(i)) num++;
        }

        uint256[] memory ids = new uint256[](num);
        uint256 nonce;
        for (uint256 i = 0; i < markets.length; i++) {
            if (isLive(i)) {
                ids[nonce] = i;
                nonce++;
            }
        }
        return ids;
    }

    /**
     * @notice             returns an array of all active market IDs for a given quote token
     * @param _token       quote token to check for
     */
    function liveMarketsFor(address _token) external view override returns (uint256[] memory) {
        uint256[] memory mkts = marketsForQuote[_token];
        uint256 num;

        for (uint256 i = 0; i < mkts.length; i++) {
            if (isLive(mkts[i])) num++;
        }

        uint256[] memory ids = new uint256[](num);
        uint256 nonce;

        for (uint256 i = 0; i < mkts.length; i++) {
            if (isLive(mkts[i])) {
                ids[nonce] = mkts[i];
                nonce++;
            }
        }
        return ids;
    }

    /**
     * @notice returns an array of market IDs for historical analysis
     */
    function getMarkets() external view override returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
                ids[i] = i;
        }
        return ids;
    }

    /**
     * @notice             returns an array of all market IDs for a given quote token
     * @param _token       quote token to check for
     */
    function getMarketsFor(address _token) external view override returns (uint256[] memory) {
        uint256[] memory mkts = marketsForQuote[_token];
        uint256[] memory ids = new uint256[](mkts.length);

        for (uint256 i = 0; i < mkts.length; i++) {
            ids[i] = mkts[i];
        }
        return ids;
    }
}