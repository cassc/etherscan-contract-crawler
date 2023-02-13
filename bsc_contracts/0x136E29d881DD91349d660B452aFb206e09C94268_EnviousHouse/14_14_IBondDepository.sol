// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC20/IERC20.sol";

interface IBondDepository {
	event CreateMarket(
		uint256 indexed id,
		address indexed baseToken,
		address indexed quoteToken,
		uint256 initialPrice
	);
	
	event CloseMarket(uint256 indexed id);
	
	event Bond(
		uint256 indexed id,
		uint256 amount,
		uint256 price
	);
	
	event Tuned(
		uint256 indexed id,
		uint64 oldControlVariable,
		uint64 newControlVariable
	);
	
	// Info about each type of market
	struct Market {
		uint256 capacity;           // capacity remaining
		IERC20 quoteToken;          // token to accept as payment
		bool capacityInQuote;       // capacity limit is in payment token (true) or in STRL (false, default)
		uint64 totalDebt;           // total debt from market
		uint64 maxPayout;           // max tokens in/out (determined by capacityInQuote false/true)
		uint64 sold;                // base tokens out
		uint256 purchased;          // quote tokens in
	}
	
	// Info for creating new markets
	struct Terms {
		bool fixedTerm;             // fixed term or fixed expiration
		uint64 controlVariable;     // scaling variable for price
		uint48 vesting;             // length of time from deposit to maturity if fixed-term
		uint48 conclusion;          // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
		uint64 maxDebt;             // 9 decimal debt maximum in STRL
	}
	
	// Additional info about market.
	struct Metadata {
		uint48 lastTune;            // last timestamp when control variable was tuned
		uint48 lastDecay;           // last timestamp when market was created and debt was decayed
		uint48 length;              // time from creation to conclusion. used as speed to decay debt.
		uint48 depositInterval;     // target frequency of deposits
		uint48 tuneInterval;        // frequency of tuning
		uint8 quoteDecimals;        // decimals of quote token
	}
	
	// Control variable adjustment data
	struct Adjustment {
		uint64 change;              // adjustment for price scaling variable 
		uint48 lastAdjustment;      // time of last adjustment
		uint48 timeToAdjusted;      // time after which adjustment should happen
		bool active;                // if adjustment is available
	}
	
	function deposit(
		uint256 _bid,               // the ID of the market
		uint256 _amount,            // the amount of quote token to spend
		uint256 _maxPrice,          // the maximum price at which to buy
		address _user,              // the recipient of the payout
		address _referral           // the operator address
	) external returns (uint256 payout_, uint256 expiry_, uint256 index_);
	
	function create (
		IERC20 _quoteToken,         // token used to deposit
		uint256[3] memory _market,  // [capacity, initial price]
		bool[2] memory _booleans,   // [capacity in quote, fixed term]
		uint256[2] memory _terms,   // [vesting, conclusion]
		uint32[2] memory _intervals // [deposit interval, tune interval]
	) external returns (uint256 id_);
	
	function close(uint256 _id) external;
	function isLive(uint256 _bid) external view returns (bool);
	function liveMarkets() external view returns (uint256[] memory);
	function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);
	function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
	function marketPrice(uint256 _bid) external view returns (uint256);
	function currentDebt(uint256 _bid) external view returns (uint256);
	function debtRatio(uint256 _bid) external view returns (uint256);
	function debtDecay(uint256 _bid) external view returns (uint64);
}