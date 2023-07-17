// SPDX-License-Identifier: GNU GPLv3
pragma solidity >=0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ====================================== IAngle.sol ===============================
// This file contains the interfaces for the main contracts of Angle protocol.
// Some of these contracts need to be deployed several times across the protocol with different
// initializations. We only leave in the following interfaces the user-facing functions
// that anyone can call without having a role. There are some view functions and some
// state-changing functions.

/// @notice Interface for the `PoolManager` contract handling the collateral of the protocol
/// @dev There is one such contract per stablecoin/collateral pair
interface IPoolManager {
	/// @return apr Estimated Annual Percentage Rate for SLPs based on lending to other protocols
	function estimatedAPR() external view returns (uint256 apr);

	/// @return The amount of the underlying collateral that the contract currently owns
	function getBalance() external view returns (uint256);

	/// @return The amount of collateral owned by this contract plus the amount that has been lent to strategies
	function getTotalAsset() external view returns (uint256);
}

/// @notice Interface for `StableMaster`, the contract handling all the collateral types accepted for a given stablecoin
interface IStableMaster {
	// Struct to handle all the parameters to manage the fees
	// related to a given collateral pool (associated to the stablecoin)
	struct MintBurnData {
		// Values of the thresholds to compute the minting fees
		// depending on HA hedge (scaled by `BASE_PARAMS`)
		uint64[] xFeeMint;
		// Values of the fees at thresholds (scaled by `BASE_PARAMS`)
		uint64[] yFeeMint;
		// Values of the thresholds to compute the burning fees
		// depending on HA hedge (scaled by `BASE_PARAMS`)
		uint64[] xFeeBurn;
		// Values of the fees at thresholds (scaled by `BASE_PARAMS`)
		uint64[] yFeeBurn;
		// Max proportion of collateral from users that can be covered by HAs
		// It is exactly the same as the parameter of the same name in `PerpetualManager`, whenever one is updated
		// the other changes accordingly
		uint64 targetHAHedge;
		// Minting fees correction set by the `FeeManager` contract: they are going to be multiplied
		// to the value of the fees computed using the hedge curve
		// Scaled by `BASE_PARAMS`
		uint64 bonusMalusMint;
		// Burning fees correction set by the `FeeManager` contract: they are going to be multiplied
		// to the value of the fees computed using the hedge curve
		// Scaled by `BASE_PARAMS`
		uint64 bonusMalusBurn;
		// Parameter used to limit the number of stablecoins that can be issued using the concerned collateral
		uint256 capOnStableMinted;
	}

	// Struct to handle all the variables and parameters to handle SLPs in the protocol
	// including the fraction of interests they receive or the fees to be distributed to
	// them
	struct SLPData {
		// Last timestamp at which the `sanRate` has been updated for SLPs
		uint256 lastBlockUpdated;
		// Fees accumulated from previous blocks and to be distributed to SLPs
		uint256 lockedInterests;
		// Max interests used to update the `sanRate` in a single block
		// Should be in collateral token base
		uint256 maxInterestsDistributed;
		// Amount of fees left aside for SLPs and that will be distributed
		// when the protocol is collateralized back again
		uint256 feesAside;
		// Part of the fees normally going to SLPs that is left aside
		// before the protocol is collateralized back again (depends on collateral ratio)
		// Updated by keepers and scaled by `BASE_PARAMS`
		uint64 slippageFee;
		// Portion of the fees from users minting and burning
		// that goes to SLPs (the rest goes to surplus)
		uint64 feesForSLPs;
		// Slippage factor that's applied to SLPs exiting (depends on collateral ratio)
		// If `slippage = BASE_PARAMS`, SLPs can get nothing, if `slippage = 0` they get their full claim
		// Updated by keepers and scaled by `BASE_PARAMS`
		uint64 slippage;
		// Portion of the interests from lending
		// that goes to SLPs (the rest goes to surplus)
		uint64 interestsForSLPs;
	}
	struct Collateral {
		// Interface for the token accepted by the underlying `PoolManager` contract
		IERC20 token;
		// Reference to the `SanToken` for the pool
		ISanToken sanToken;
		// Reference to the `PerpetualManager` for the pool
		IPerpetualManager perpetualManager;
		// Adress of the oracle for the change rate between
		// collateral and the corresponding stablecoin
		IOracle oracle;
		// Amount of collateral in the reserves that comes from users
		// converted in stablecoin value. Updated at minting and burning.
		// A `stocksUsers` of 10 for a collateral type means that overall the balance of the collateral from users
		// that minted/burnt stablecoins using this collateral is worth 10 of stablecoins
		uint256 stocksUsers;
		// Exchange rate between sanToken and collateral
		uint256 sanRate;
		// Base used in the collateral implementation (ERC20 decimal)
		uint256 collatBase;
		// Parameters for SLPs and update of the `sanRate`
		SLPData slpData;
		// All the fees parameters
		MintBurnData feeData;
	}

	/// @notice Lets a user send collateral to the system to mint stablecoins
	/// @param amount Amount of collateral sent
	/// @param user Address of the contract or the person to give the minted tokens to
	/// @param poolManager Address of the `PoolManager` of the required collateral
	/// @param minStableAmount Minimum amount of stablecoins the user wants to get with this transaction
	/// @dev The `poolManager` refers to the collateral that the user wants to send
	/// @dev `minStableAmount` serves as a slippage protection for users
	function mint(
		uint256 amount,
		address user,
		IPoolManager poolManager,
		uint256 minStableAmount
	) external;

	/// @notice Lets a user burn agTokens (stablecoins) and receive the collateral specified by the `poolManager`
	/// in exchange
	/// @param amount Amount of stable asset burnt
	/// @param burner Address from which the agTokens will be burnt
	/// @param dest Address where collateral is going to be sent
	/// @param poolManager Collateral type requested by the user burning
	/// @param minCollatAmount Minimum amount of collateral that the user wants to get with this transaction
	function burn(
		uint256 amount,
		address burner,
		address dest,
		IPoolManager poolManager,
		uint256 minCollatAmount
	) external;

	/// @notice Lets a SLP enter the protocol by sending collateral to the system in exchange of sanTokens
	/// @param user Address of the SLP to send sanTokens to
	/// @param amount Amount of collateral sent
	/// @param poolManager Address of the `PoolManager` of the required collateral: the corresponding collateral
	/// type is the one that is going to be sent by the user
	function deposit(
		uint256 amount,
		address user,
		IPoolManager poolManager
	) external;

	/// @notice Lets a SLP burn of sanTokens and receive the corresponding collateral back in exchange at the
	/// current exchange rate between sanTokens and collateral
	/// @param amount Amount of sanTokens burnt by the SLP
	/// @param burner Address that will burn its sanTokens
	/// @param dest Address that will receive the collateral
	/// @param poolManager Address of the `PoolManager` of the required collateral
	function withdraw(
		uint256 amount,
		address burner,
		address dest,
		IPoolManager poolManager
	) external;

	/// @return Collateral ratio for this stablecoin
	function getCollateralRatio() external view returns (uint256);

	function collateralMap(IPoolManager poolManager)
		external
		view
		returns (
			IERC20 token,
			ISanToken sanToken,
			IPerpetualManager perpetualManager,
			IOracle oracle,
			uint256 stocksUsers,
			uint256 sanRate,
			uint256 collatBase,
			SLPData memory slpData,
			MintBurnData memory feeData
		);
}

/// @notice Interface for the contract managing perpetuals: there is one such contract per collateral/stablecoin
/// pair in the protocol
interface IPerpetualManager {
	/// @notice Lets a HA join the protocol and create a perpetual
	/// @param owner Address of the future owner of the perpetual
	/// @param margin Amount of collateral brought by the HA
	/// @param committedAmount Amount of collateral hedged by the HA
	/// @param maxOracleRate Maximum oracle value that the HA wants to see stored in the perpetual
	/// @param minNetMargin Minimum net margin that the HA is willing to see stored in the perpetual
	/// @return perpetualID The ID of the perpetual opened by this HA
	/// @dev The future owner of the perpetual cannot be the zero address
	/// @dev It is possible to open a perpetual on behalf of someone else
	/// @dev The `maxOracleRate` parameter serves as a protection against oracle manipulations for HAs opening perpetuals
	/// @dev `minNetMargin` is a protection against too big variations in the fees for HAs
	function openPerpetual(
		address owner,
		uint256 margin,
		uint256 committedAmount,
		uint256 maxOracleRate,
		uint256 minNetMargin
	) external returns (uint256 perpetualID);

	/// @notice Lets a HA close a perpetual owned or controlled for the stablecoin/collateral pair associated
	/// to this `PerpetualManager` contract
	/// @param perpetualID ID of the perpetual to close
	/// @param to Address which will receive the proceeds from this perpetual
	/// @param minCashOutAmount Minimum net cash out amount that the HA is willing to get for closing the
	/// perpetual
	/// @dev The HA gets the current amount of her position depending on the entry oracle value
	/// and current oracle value minus some transaction fees computed on the committed amount
	/// @dev `msg.sender` should be the owner of `perpetualID` or be approved for this perpetual
	/// @dev If the `PoolManager` does not have enough collateral, the perpetual owner will be converted to a SLP and
	/// receive sanTokens
	/// @dev The `minCashOutAmount` serves as a protection for HAs closing their perpetuals: it protects them both
	/// from fees that would have become too high and from a too big decrease in oracle value
	function closePerpetual(
		uint256 perpetualID,
		address to,
		uint256 minCashOutAmount
	) external;

	/// @notice Lets a HA increase the `margin` in a perpetual she controls for this
	/// stablecoin/collateral pair
	/// @param perpetualID ID of the perpetual to which amount should be added to `margin`
	/// @param amount Amount to add to the perpetual's `margin`
	function addToPerpetual(uint256 perpetualID, uint256 amount) external;

	/// @notice Lets a HA decrease the `margin` in a perpetual she controls for this
	/// stablecoin/collateral pair
	/// @param perpetualID ID of the perpetual from which collateral should be removed
	/// @param amount Amount to remove from the perpetual's `margin`
	/// @param to Address which will receive the collateral removed from this perpetual
	function removeFromPerpetual(
		uint256 perpetualID,
		uint256 amount,
		address to
	) external;

	// =========================== External View Function ==========================

	/// @notice Returns the `cashOutAmount` of the perpetual owned by someone at a given oracle value
	/// @param perpetualID ID of the perpetual
	/// @param rate Oracle value
	/// @return The `cashOutAmount` of the perpetual
	/// @return Whether the position of the perpetual is now too small compared with its initial position
	function getCashOutAmount(uint256 perpetualID, uint256 rate) external view returns (uint256, uint256);

	// =========================== Reward Distribution =============================

	/// @notice Allows to check the amount of reward tokens earned by a perpetual
	/// @param perpetualID ID of the perpetual to check
	/// @return The earned tokens by the perpetual that have not been claimed yet
	function earned(uint256 perpetualID) external view returns (uint256);

	/// @notice Allows a perpetual owner to withdraw rewards
	/// @param perpetualID ID of the perpetual which accumulated tokens
	/// @dev Only an approved caller can claim the rewards for the perpetual with perpetualID
	function getReward(uint256 perpetualID) external;

	// =============================== ERC721 logic ================================

	/// @notice Gets the balance of an owner
	/// @param owner Address of the owner
	/// @return Balance (ie the number of perpetuals) owned by a HA
	function balanceOf(address owner) external view returns (uint256);

	/// @notice Gets the owner of the perpetual with ID perpetualID
	/// @param perpetualID ID of the perpetual
	/// @return Owner address
	function ownerOf(uint256 perpetualID) external view returns (address);

	/// @notice Approves to an address specified by `to` a perpetual specified by `perpetualID`
	/// @param to Address to approve the perpetual to
	/// @param perpetualID ID of the perpetual
	function approve(address to, uint256 perpetualID) external;

	/// @param perpetualID ID of the concerned perpetual
	/// @return Approved address by a perpetual owner
	function getApproved(uint256 perpetualID) external view returns (address);

	/// @notice Sets approval on all perpetuals owned by the owner to an operator
	/// @param operator Address to approve (or block) on all perpetuals
	/// @param approved Whether the sender wants to approve or block the operator
	function setApprovalForAll(address operator, bool approved) external;

	/// @param owner Owner of perpetuals
	/// @param operator Address to check if approved
	/// @return If the operator address is approved on all perpetuals by the owner
	function isApprovedForAll(address owner, address operator) external view returns (bool);

	/// @param perpetualID ID of the perpetual
	/// @return If the sender address is approved for the perpetualId
	function isApprovedOrOwner(address spender, uint256 perpetualID) external view returns (bool);

	/// @notice Transfers the `perpetualID` from an address to another
	/// @param from Source address
	/// @param to Destination a address
	/// @param perpetualID ID of the perpetual to transfer
	function transferFrom(
		address from,
		address to,
		uint256 perpetualID
	) external;

	/// @notice Safely transfers the `perpetualID` from an address to another without data in it
	/// @param from Source address
	/// @param to Destination a address
	/// @param perpetualID ID of the perpetual to transfer
	function safeTransferFrom(
		address from,
		address to,
		uint256 perpetualID
	) external;

	/// @notice Safely transfers the `perpetualID` from an address to another with data in the transfer
	/// @param from Source address
	/// @param to Destination a address
	/// @param perpetualID ID of the perpetual to transfer
	function safeTransferFrom(
		address from,
		address to,
		uint256 perpetualID,
		bytes memory _data
	) external;
}

/// @notice Interface for the staking contract of the Angle protocol
interface IStakingRewards {
	/// @dev Used instead of having a public variable to respect the ERC20 standard
	/// @return Total supply
	function totalSupply() external view returns (uint256);

	/// @param account Account to query the balance of
	/// @return Number of token staked by an account
	function balanceOf(address account) external view returns (uint256);

	/// @return Current timestamp if a reward is being distributed and the end of the staking
	/// period if staking is done
	function lastTimeRewardApplicable() external view returns (uint256);

	/// @notice Returns how much unclaimed rewards an account has
	/// @param account Address for which the request is made
	/// @return How much a given account earned rewards
	function earned(address account) external view returns (uint256);

	/// @notice Lets someone stake a given amount of `stakingTokens`
	/// @param amount Amount of ERC20 staking token that the `msg.sender` wants to stake
	function stake(uint256 amount) external;

	/// @notice Allows to stake on behalf of another address
	/// @param amount Amount to stake
	/// @param onBehalf Address to stake onBehalf of
	function stakeOnBehalf(uint256 amount, address onBehalf) external;

	/// @notice Lets a user withdraw a given amount of collateral from the staking contract
	/// @param amount Amount of the ERC20 staking token that the `msg.sender` wants to withdraw
	function withdraw(uint256 amount) external;

	/// @notice Triggers a payment of the reward earned to the msg.sender
	function getReward() external;

	/// @notice Lets the caller withdraw its staking and claim rewards
	function exit() external;
}

/// @notice Interface for agToken, that is to say Angle's stablecoins
/// @dev This contract is used to create and handle the stablecoins of Angle protocol
/// @dev Only the `StableMaster` contract can mint or burn agTokens
/// @dev It is still possible for any address to burn its agTokens without redeeming collateral in exchange
/// @dev agTokens are classical ERC-20 tokens, so it is still possible to `approve` an address, `transfer` or
/// `transferFrom` the tokens
interface IAgToken {
	/// @notice Burns `amount` of agToken on behalf of another account without redeeming collateral back
	/// @param account Account to burn on behalf of
	/// @param amount Amount to burn
	/// @param poolManager Reference to the `PoolManager` contract for which the `stocksUsers` will
	/// need to be updated
	/// @dev When calling this function, people should specify the `poolManager` for which they want to decrease
	/// the `stocksUsers`: this a way for the protocol to maintain healthy accounting variables
	/// @dev This function is for instance to be used by governance to burn the tokens accumulated by the `BondingCurve`
	/// contract
	function burnFromNoRedeem(
		address account,
		uint256 amount,
		address poolManager
	) external;

	/// @notice Destroys `amount` token from the caller without giving collateral back
	/// @param amount Amount to burn
	/// @param poolManager Reference to the `PoolManager` contract for which the `stocksUsers` will need to be updated
	function burnNoRedeem(uint256 amount, address poolManager) external;
}

/// @notice Interface for sanTokens, these tokens are used to mark the debt the contract has to SLPs
/// @dev The exchange rate between sanTokens and collateral will automatically change as interests and transaction fees accrue to SLPs
/// @dev There is one `SanToken` contract per pair stablecoin/collateral
/// @dev Only the `StableMaster` contract can mint or burn sanTokens
/// @dev It is still possible for any address to burn its sanTokens without redeeming collateral in exchange
/// @dev Like `AgTokens`, sanTokens are classical ERC-20 tokens, so it is still possible to `approve` an address, `transfer` or
/// `transferFrom` the tokens
interface ISanToken {
	/// @notice Destroys `amount` token for the caller without giving collateral back
	/// @param amount Amount to burn
	function burnNoRedeem(uint256 amount) external;
}

/// @notice Interface for the `Core` contract
interface ICore {
	/// @return `_governorList` List of all the governor addresses of the protocol
	function governorList() external view returns (address[] memory);
}

/// @notice Interface for Angle's oracle contracts reading oracle rates from both UniswapV3 and Chainlink,
/// from just UniswapV3 or from just Chainlink
interface IOracle {
	/// @notice Reads one of the rates from the circuits given
	/// @return rate The current rate between the in-currency and out-currency
	/// @dev By default if the oracle involves a Uniswap price and a Chainlink price
	/// this function will return the Uniswap price
	/// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
	function read() external view returns (uint256 rate);

	/// @notice Read rates from the circuit of both Uniswap and Chainlink if there are both circuits
	/// else returns twice the same price
	/// @return Return all available rates (Chainlink and Uniswap) with the lowest rate returned first.
	/// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
	function readAll() external view returns (uint256, uint256);

	/// @notice Reads rates from the circuit of both Uniswap and Chainlink if there are both circuits
	/// and returns either the highest of both rates or the lowest
	/// @return rate The lower rate between Chainlink and Uniswap
	/// @dev If there is only one rate computed in an oracle contract, then the only rate is returned
	/// regardless of the value of the `lower` parameter
	/// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
	function readLower() external view returns (uint256 rate);

	/// @notice Reads rates from the circuit of both Uniswap and Chainlink if there are both circuits
	/// and returns either the highest of both rates or the lowest
	/// @return rate The upper rate between Chainlink and Uniswap
	/// @dev If there is only one rate computed in an oracle contract, then the only rate is returned
	/// regardless of the value of the `lower` parameter
	/// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
	function readUpper() external view returns (uint256 rate);

	/// @notice Converts an in-currency quote amount to out-currency using one of the rates available in the oracle
	/// contract
	/// @param quoteAmount Amount (in the input collateral) to be converted to be converted in out-currency
	/// @return Quote amount in out-currency from the base amount in in-currency
	/// @dev Like in the read function, if the oracle involves a Uniswap and a Chainlink price, this function
	/// will use the Uniswap price to compute the out quoteAmount
	/// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
	function readQuote(uint256 quoteAmount) external view returns (uint256);

	/// @notice Returns the lowest quote amount between Uniswap and Chainlink circuits (if possible). If the oracle
	/// contract only involves a single feed, then this returns the value of this feed
	/// @param quoteAmount Amount (in the input collateral) to be converted
	/// @return The lowest quote amount from the quote amount in in-currency
	/// @dev The rate returned is expressed with base `BASE` (and not the base of the out-currency)
	function readQuoteLower(uint256 quoteAmount) external view returns (uint256);
}

/// @notice Interface for the `BondingCurve` contract
/// @dev This contract allows people to buy ANGLE governance tokens using the protocol's stablecoins
/// @dev It is with high certainty not going to be distributed directly at launch
interface IBondingCurve {
	/// @notice Lets `msg.sender` buy tokens (ANGLE tokens normally) against an allowed token (a stablecoin normally)
	/// @param _agToken Reference to the agToken used, that is the stablecoin used to buy the token associated to this
	/// bonding curve
	/// @param maxAmountToPayInAgToken Maximum amount to pay in agTokens that the user is willing to pay to buy the
	/// `targetSoldTokenQuantity`
	function buySoldToken(
		IAgToken _agToken,
		uint256 targetSoldTokenQuantity,
		uint256 maxAmountToPayInAgToken
	) external;

	/// @dev More generally than the expression used, the value of the price is:
	/// `startPrice/(1-tokensSoldInTx/tokensToSellInTotal)^power` with `power = 2`
	/// @dev The precision of this function is not that important as it is a view function anyone can query
	/// @notice Returns the current price of the token (expressed in reference)
	function getCurrentPrice() external view returns (uint256);

	/// @return The quantity of governance tokens that are still to be sold
	function getQuantityLeftToSell() external view returns (uint256);

	/// @param targetQuantity Quantity of ANGLE tokens to buy
	/// @dev This is an utility function that can be queried before buying tokens
	/// @return The amount to pay for the desired amount of ANGLE to buy
	function computePriceFromQuantity(uint256 targetQuantity) external view returns (uint256);
}

/// @title ICollateralSettler
/// @notice Interface for the collateral settlement contracts that are used when a collateral is getting revoked
interface ICollateralSettler {
	/// @notice Allows a user to claim collateral for a `dest` address by sending agTokens and gov tokens (optional)
	/// @param dest Address of the user to claim collateral for
	/// @param amountAgToken Amount of agTokens sent
	/// @param amountGovToken Amount of governance sent
	/// @dev The more gov tokens a user sends, the more preferably it ends up being treated during the redeem period
	function claimUser(
		address dest,
		uint256 amountAgToken,
		uint256 amountGovToken
	) external;

	/// @notice Allows a HA to claim collateral by sending a `perpetualID` and gov tokens (optional)
	/// @param perpetualID Perpetual owned by the HA
	/// @param amountGovToken Amount of governance sent
	/// @dev The contract automatically recognizes the beneficiary of the perpetual
	function claimHA(uint256 perpetualID, uint256 amountGovToken) external;

	/// @notice Allows a SLP to claim collateral for an address `dest` by sending sanTokens and gov tokens (optional)
	/// @param dest Address to claim collateral for
	/// @param amountSanToken Amount of sanTokens sent
	/// @param amountGovToken Amount of governance tokens sent
	function claimSLP(
		address dest,
		uint256 amountSanToken,
		uint256 amountGovToken
	) external;

	/// @notice Computes the base amount each category of claim will get after the claim period has ended
	/// @dev This function can only be called once when claim period is over
	/// @dev It is at the level of this function that the waterfall between the different
	/// categories of stakeholders and of claims is executed
	function setAmountToRedistributeEach() external;

	/// @notice Lets a user or a LP redeem its corresponding share of collateral
	/// @param user Address of the user to redeem collateral to
	/// @dev This function can only be called after the `setAmountToRedistributeEach` function has been called
	/// @dev The entry point to redeem is the same for users, HAs and SLPs
	function redeemCollateral(address user) external;
}