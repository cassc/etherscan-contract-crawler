// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IWhitelistBondDepository {
    /**
     * @notice      Info about each type of market
     * @dev         Market::capacity is capacity remaining
     *              Market::quoteToken is token to accept as payment
     *              Market::priceFeed is address of the price consumer, to return the USD value for the quote token when deposits are made
     *              Market::capacityInQuote is in payment token (true) or in THEO (false, default)
     *              Market::sold is base tokens out
     *              Market::purchased quote tokens in
     *              Market::usdPricePerTHEO is 9 decimal USD value for each THEO bond
     */
    struct Market {
        uint256 capacity;
        IERC20 quoteToken;
        address priceFeed;
        bool capacityInQuote;
        uint64 sold;
        uint256 purchased;
        uint256 usdPricePerTHEO;
    }

    /**
     * @notice      Info for creating new markets
     * @dev         Terms::fixedTerm is fixed term or fixed expiration
     *              Terms::vesting is length of time from deposit to maturity if fixed-term
     *              Terms::conclusion is timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
     */
    struct Terms {
        bool fixedTerm;
        uint48 vesting;
        uint48 conclusion;
    }

    /**
     * @notice      Additional info about market
     * @dev         Metadata::quoteDecimals is decimals of quote token
     */
    struct Metadata {
        uint8 quoteDecimals;
    }

    struct DepositInfo {
        uint256 payout_;
        uint256 expiry_;
        uint256 index_;
    }

    /**
     * @notice deposit market
     * @param _bid uint256
     * @param _amount uint256
     * @param _maxPrice uint256
     * @param _user address
     * @param _referral address
     * @param signature bytes
     * @return depositInfo DepositInfo
     */
    function deposit(
        uint256 _bid,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral,
        bytes calldata signature
    ) external returns (DepositInfo memory depositInfo);

    /**
     * @notice create market
     * @param _quoteToken IERC20 is the token used to deposit
     * @param _priceFeed address is address of the price consumer, to return the USD value for the quote token when deposits are made
     * @param _market uint256[2] is [capacity, fixed bond price (9 decimals) USD per THEO]
     * @param _booleans bool[2] is [capacity in quote, fixed term]
     * @param _terms uint256[2] is [vesting, conclusion]
     * @return id_ uint256 is ID of the market
     */
    function create(
        IERC20 _quoteToken,
        address _priceFeed,
        uint256[2] memory _market,
        bool[2] memory _booleans,
        uint256[2] memory _terms
    ) external returns (uint256 id_);

    function close(uint256 _id) external;

    function isLive(uint256 _bid) external view returns (bool);

    function liveMarkets() external view returns (uint256[] memory);

    function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);

    function getMarkets() external view returns (uint256[] memory);

    function getMarketsFor(address _quoteToken) external view returns (uint256[] memory);

    function calculatePrice(uint256 _bid) external view returns (uint256);

    function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
}