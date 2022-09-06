// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../Types/NoteKeeper.sol";
import "../Types/Signed.sol";
import "../Types/PriceConsumerV3.sol";

import "../Libraries/SafeERC20.sol";

import "../Interfaces/IERC20Metadata.sol";
import "../Interfaces/IWhitelistBondDepository.sol";

/**
 * @title Theopetra Whitelist Bond Depository
 */

contract WhitelistTheopetraBondDepository is IWhitelistBondDepository, NoteKeeper, Signed, PriceConsumerV3 {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    event CreateMarket(
        uint256 indexed id,
        address indexed baseToken,
        address indexed quoteToken,
        uint256 fixedBondPrice
    );
    event CloseMarket(uint256 indexed id);
    event Bond(uint256 indexed id, uint256 amount, uint256 price);

    /* ======== STATE VARIABLES ======== */

    // Storage
    Market[] public markets; // persistent market data
    Terms[] public terms; // deposit construction data
    Metadata[] public metadata; // extraneous market data
    address private wethHelper;

    // Queries
    mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token

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
     * @return depositInfo DepositInfo
     */
    function deposit(
        uint256 _id,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral,
        bytes calldata signature
    ) external override returns (DepositInfo memory depositInfo) {
        if (msg.sender != wethHelper) {
            verifySignature("", signature);
        }
        Market storage market = markets[_id];
        Terms memory term = terms[_id];
        uint48 currentTime = uint48(block.timestamp);

        // Markets end at a defined timestamp
        // |-------------------------------------| t
        require(currentTime < term.conclusion, "Depository: market concluded");

        // Get the price of THEO in quote token terms
        // i.e. the number of quote tokens per THEO
        // With 9 decimal places
        uint256 price = calculatePrice(_id);

        // Users input a maximum price, which protects them from price changes after
        // entering the mempool. max price is a slippage mitigation measure
        require(price <= _maxPrice, "Depository: more than max price");

        /**
         * payout for the deposit = amount / price
         *
         * where
         * payout = THEO out, in THEO decimals (9)
         * amount = quote tokens in
         * price = quote tokens per THEO, in THEO decimals (9)
         *
         * 1e18 = THEO decimals (9) + price decimals (9)
         */
        depositInfo.payout_ = ((_amount * 1e18) / price) / (10**metadata[_id].quoteDecimals);

        /*
         * each market is initialized with a capacity
         *
         * this is either the number of THEO that the market can sell
         * (if capacity in quote is false),
         *
         * or the number of quote tokens that the market can buy
         * (if capacity in quote is true)
         */

        require(
            market.capacity >= (market.capacityInQuote ? _amount : depositInfo.payout_),
            "Depository: capacity exceeded"
        );

        market.capacity -= market.capacityInQuote ? _amount : depositInfo.payout_;

        if (market.capacity == 0) {
            emit CloseMarket(_id);
        }

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
        depositInfo.expiry_ = term.fixedTerm ? term.vesting + currentTime : term.vesting;

        // markets keep track of how many quote tokens have been
        // purchased, and how much THEO has been sold
        market.purchased += _amount;
        market.sold += uint64(depositInfo.payout_);

        emit Bond(_id, _amount, price);

        /**
         * user data is stored as Notes. these are isolated array entries
         * storing the amount due, the time created, the time when payout
         * is redeemable, the time when payout was redeemed, and the ID
         * of the market deposited into
         */
        depositInfo.index_ = addNote(
            _user,
            depositInfo.payout_,
            uint48(depositInfo.expiry_),
            uint48(_id),
            _referral,
            0,
            false
        );

        // transfer payment to treasury
        market.quoteToken.safeTransferFrom(msg.sender, address(treasury), _amount);
    }

    /* ======== CREATE ======== */

    /**
     * @notice             creates a new market type
     * @dev                current price should be in 9 decimals.
     * @param _quoteToken  token used to deposit
     * @param _market      [capacity (in THEO or quote), fixed bond price (9 decimals) USD per THEO]
     * @param _booleans    [capacity in quote, fixed term]
     * @param _terms       [vesting length (if fixed term) or vested timestamp, conclusion timestamp]
     * @param _priceFeed   address of the price consumer, to return the USD value for the quote token when deposits are made
     * @return id_         ID of new bond market
     */
    function create(
        IERC20 _quoteToken,
        address _priceFeed,
        uint256[2] memory _market,
        bool[2] memory _booleans,
        uint256[2] memory _terms
    ) external override onlyPolicy returns (uint256 id_) {
        // the decimal count of the quote token
        uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();

        // depositing into, or getting info for, the created market uses this ID
        id_ = markets.length;

        markets.push(
            Market({
                quoteToken: _quoteToken,
                priceFeed: _priceFeed,
                capacityInQuote: _booleans[0],
                capacity: _market[0],
                purchased: 0,
                sold: 0,
                usdPricePerTHEO: _market[1]
            })
        );

        terms.push(Terms({ fixedTerm: _booleans[1], vesting: uint48(_terms[0]), conclusion: uint48(_terms[1]) }));

        metadata.push(Metadata({ quoteDecimals: uint8(decimals) }));

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

    /* ======== EXTERNAL VIEW ======== */

    /**
     * @notice             payout due for amount of quote tokens
     * @param _amount      amount of quote tokens to spend
     * @param _id          ID of market
     * @return             amount of THEO to be paid in THEO decimals
     *
     * @dev 1e18 = theo decimals (9) + fixed bond price decimals (9)
     */
    function payoutFor(uint256 _amount, uint256 _id) external view override returns (uint256) {
        Metadata memory meta = metadata[_id];
        return (_amount * 1e18) / calculatePrice(_id) / 10**meta.quoteDecimals;
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

    /**
     * @notice                  calculate the price of THEO in quote token terms; i.e. the number of quote tokens per THEO
     * @dev                     get the latest price for the market's quote token in USD
     *                          (`priceConsumerPrice`, with decimals `priceConsumerDecimals`)
     *                          then `scalePrice` to scale the fixed bond price to THEO decimals when calculating `price`.
     *                          finally, calculate `price` as quote tokens per THEO, in THEO decimals (9)
     * @param _id               market ID
     * @return                  uint256 price of THEO in quote token terms, in THEO decimals (9)
     */
    function calculatePrice(uint256 _id) public view override returns (uint256) {
        (int256 priceConsumerPrice, uint8 priceConsumerDecimals) = getLatestPrice(markets[_id].priceFeed);

        int256 scaledPrice = scalePrice(int256(markets[_id].usdPricePerTHEO), 9, 9 + priceConsumerDecimals);

        uint256 price = uint256(scaledPrice / priceConsumerPrice);
        return price;
    }

    /* ======== INTERNAL PURE ======== */

    /**
     * @param _price            fixed bond price (USD per THEO), 9 decimals
     * @param _priceDecimals    decimals (9) used for the fixed bond price
     * @param _decimals         sum of decimals for THEO token (9) + decimals for the price feed
     */
    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    /* ====== POLICY FUNCTIONS ====== */

    function setWethHelper(address _wethHelper) external onlyGovernor {
        require(_wethHelper != address(0), "Zero address");
        wethHelper = _wethHelper;
    }
}