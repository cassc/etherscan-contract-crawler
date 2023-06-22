// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../access/PermitControl.sol";
import "../interfaces/IByteContract.sol";
import "../interfaces/IGenericGetter.sol";
import "../interfaces/INTStakedToken.sol";

/**
	Thrown when attempting to operate on a non-existent Citizen (S1 or S2).

	@param citizenId The ID of the caller's specified Citizen.
*/
error CitizenDoesNotExist (
	uint256 citizenId
);

/**
	Thrown when attempting to get a staker's position of an unknowable asset type.

	@param assetType The caller's specified asset type.
*/
error UnknowablePosition (
	uint256 assetType
);

/**
	Thrown when an S1 Citizen with a component Vault attempts to stake while 
	attaching an optional non-component Vault.

	@param componentVaultId The ID of the S1 Citizen's component Vault.
	@param noncomponentVaultId The ID of the Vault the caller attempted to stake.
*/
error CitizenAlreadyHasVault (
	uint256 componentVaultId,
	uint256 noncomponentVaultId
);

/**
	Thrown when an S1 Citizen attempts to wrongfully claim the Hand bonus.

	@param citizenId The ID of the caller's specified S1 Citizen.
*/
error CitizenIsNotHand (
	uint256 citizenId
);

/**
	Thrown when a BYTES stake would exceed the cap of its corresponding Citizen.

	@param attemptedAmount The amount that the user is attempting to stake to.
	@param cap The staking cap of the Citizen.
*/
error AmountExceedsCap (
	uint256 attemptedAmount,
	uint256 cap
);

/**
	Thrown when attempting to stake BYTES into an unowned Citizen.

	@param citizenId The token ID of the Citizen involved in the attempted stake.
	@param seasonId The season ID of the Citizen, whether S1 or S2.
*/
error CannotStakeIntoUnownedCitizen (
	uint256 citizenId,
	uint256 seasonId
);

/**
	Thrown when attempting to stake BYTES into an invalid Citizen season.

	@param seasonId The ID of the Citizen season to try staking BYTES into.
*/
error InvalidSeasonId (
	uint256 seasonId
);

/**
	Thrown when attempting to increase a stake in an asset without matching the 
	existing timelock of the asset.
*/
error MismatchedTimelock ();

/**
	Thrown during staking or unstaking if an invalid AssetType is specified.

	@param assetType The caller's specified asset type.
*/
error InvalidAssetType (
	uint256 assetType
);

/**
	Thrown during staking if attempting to stake into an unconfigured asset pool.

	@param assetType The caller's specified asset type.
*/
error UnconfiguredPool (
	uint256 assetType
);

/**
	Thrown during staking if attempting to stake into an asset pool whose rewards 
	are not yet active.

	@param assetType The caller's specified asset type.
*/
error InactivePool (
	uint256 assetType
);

/**
	Thrown during staking if an invalid timelock option is specified. Each 
	AssetType being staked may have independently-configured timelock options.

	@param assetType The caller's specified asset type.
	@param timelockId The caller's specified timelock ID against `assetType`.
*/
error InvalidTimelockOption (
	uint256 assetType,
	uint256 timelockId
);

/// Thrown if the caller of a function is not the BYTES contract.
error CallerIsNotBYTES ();

/**
	Thrown when withdrawing an asset fails to clear a timelock.
	
	@param endTime The time that the staked asset timelock ends.
*/
error TimelockNotCleared (
	uint256 endTime
);

/**
	Thrown when attempting to withdraw an unowned S1 Citizen.

	@param citizenId The ID of the S1 Citizen attempted to be withdrawn.
*/
error CannotWithdrawUnownedS1 (
	uint256 citizenId
);

/**
	Thrown when attempting to withdraw an unowned S2 Citizen.

	@param citizenId The ID of the S2 Citizen attempted to be withdrawn.
*/
error CannotWithdrawUnownedS2 (
	uint256 citizenId
);

/**
	Thrown if a caller tries to withdraw more LP tokens than they had staked.

	@param attemptedWithdraw The amount of LP tokens that the caller attempted to 
		withdraw.
	@param position The amount of LP tokens that the caller has actually staked.
*/
error NotEnoughLPTokens (
	uint256 attemptedWithdraw,
	uint256 position
);

/// Thrown if attempting to configure the LP token address post-lock.
error LockedConfigurationOfLP ();

/// Thrown when specifying invalid reward windows for a pool.
error RewardWindowTimesMustIncrease ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A pool-based staking contract for the Neo Tokyo ecosystem.
	@author Tim Clancy <tim-clancy.eth>
	@author Rostislav Khlebnikov <catpic5buck.eth>

	This contract allows callers to stake their Neo Tokyo Citizens (both S1 and 
	S2) and BYTES for	time-locked emission rewards. The staker operates on a 
	point-based, competitive system where stakers compete for a finite amount of 
	daily emissions. It allows permissioned managers to configure various 
	emission details for the Neo Tokyo ecosystem.

	@custom:date February 14th, 2023.
*/
contract NeoTokyoStaker is PermitControl, ReentrancyGuard {

	/// The `transferFrom` selector for ERC-20 and ERC-721 tokens.
	bytes4 constant private _TRANSFER_FROM_SELECTOR = 0x23b872dd;

	/// The `transfer` selector for ERC-20 tokens.
	bytes4 constant private _TRANSFER_SELECTOR = 0xa9059cbb;

	/// A constant multiplier to reduce overflow in staking calculations.
	uint256 constant private _PRECISION = 1e12;

	/// A constant divisor to calculate points and multipliers as basis points.
	uint256 constant private _DIVISOR = 100;

	/// The number of BYTES needed to get one point in BYTES staking calculations.
	uint256 constant private _BYTES_PER_POINT = 200 * 1e18;

	/// The identifier for the right to configure the LP token address.
	bytes32 public constant CONFIGURE_LP = keccak256("CONFIGURE_LP");

	/// The identifier for the right to configure timelock options.
	bytes32 public constant CONFIGURE_TIMELOCKS = keccak256(
		"CONFIGURE_TIMELOCKS"
	);

	/// The identifier for the right to configure Identity and Vault points.
	bytes32 public constant CONFIGURE_CREDITS = keccak256("CONFIGURE_CREDITS");

	/// The identifier for the right to configure emission rates and the DAO tax.
	bytes32 public constant CONFIGURE_POOLS = keccak256("CONFIGURE_POOLS");

	/// The identifier for the right to configure BYTES staking caps.
	bytes32 public constant CONFIGURE_CAPS = keccak256("CONFIGURE_CAPS");

	/// The address of the new BYTES 2.0 token contract.
	address immutable public BYTES;

	/// The address of the assembled Neo Tokyo S1 Citizen contract.
	address immutable public S1_CITIZEN;

	/// The address of the assembled Neo Tokyo S2 Citizen contract.
	address immutable public S2_CITIZEN;

	/// The address of the LP token contract.
	address public LP;

	/**
		The address of the Neo Tokyo S1 Identity contract. This specific contract 
		address is stored to check an assembled S1 Citizen's specific component 
		identity in order to check for Hands of the Citadel.
	*/
	address immutable public IDENTITY;

	/// The address of the Neo Tokyo S1 Vault contract.
	address immutable public VAULT;


	// The address of the soulbound token that is given to wallets upon staking a citizen
	// and burned upon unstaking.    
	address public NT_STAKED_CITIZEN;

	/**
		The limit on the number of BYTES that may be staked per S1 Citizen 
		assembled with a component Vault or per Vault-less S1 Citizen staked 
		alongside a Vault.
	*/
	uint256 public VAULT_CAP;

	/**
		The limit on the number of BYTES that may be staked per S2 Citizen or S1 
		Citizen without Vault.
	*/
	uint256 public NO_VAULT_CAP;

	/**
		This enum tracks each type of asset that may be operated on with this 
		staker.

		@param S1_CITIZEN A staked Neo Tokyo S1 Citizen.
		@param S2_CITIZEN A staked Neo Tokyo S2 Citizen.
		@param BYTES A set of staked BYTES ERC-20 token.
		@param LP Staked BYTES-ETH LP ERC-20 token.
	*/
	enum AssetType {
		S1_CITIZEN,
		S2_CITIZEN,
		BYTES,
		LP
	}

	/**
		This mapping contains the per-asset configuration of different timelock 
		periods with their associated multipliers. For each asset, the interior 
		mapping correlates a particular timelock option to a uint256 which encodes 
		the duration of the timelock in its upper 128 bits and the multiplier 
		offered by that timelock, as basis points, in its lower 128 bits.
	*/
	mapping ( AssetType => mapping ( uint256 => uint256 )) public	timelockOptions;

	/**
		This struct defines a specific time window in reward emission history. For 
		a particular asset staking pool, it represents that beginning from 
		`startTime`, the pool had a per-second reward emission rate of `reward`.

		@param startTime The time at which the daily reward activated.
		@param reward The reward emission rate beginning at `startTime`.
	*/
	struct RewardWindow {
		uint128 startTime;
		uint128 reward;
	}

	/**
		This struct is used to define both the configuration details for a 
		particular asset staking pool and the state of that pool as callers begin 
		interacting with it.

		@param totalPoints The total number of points in the pool.
		@param daoTax The percent, in basis points, of the reward emissions sent to 
			the DAO.
		@param rewardPerPoint The cumulative rewards earned for each point in the pool.
		@param lastUpdated The time at which this pool's points were last updated.
		@param rewardCount A count of the number of reward windows in the 
			`rewardWindows` mapping, used for iterating.
		@param rewardWindows A mapping of the historic amount of BYTES token 	
			rewarded per-second across all stakers in this particular pool.
	*/
	struct PoolData {
		uint256 totalPoints;
		uint256 daoTax;
		uint256 rewardPerPoint;
		uint256 lastUpdated;
		uint256 rewardCount;
		mapping ( uint256 => RewardWindow ) rewardWindows;
		mapping ( address => uint256 ) rewardsMissed;
	}

	/// Map an asset type to its corresponding pool data. 
	mapping ( AssetType => PoolData ) private _pools;
	
	/// Track the last time a caller was granted their rewards for each asset.
	mapping ( address => mapping ( AssetType => uint256 )) public lastRewardTime;

	/// Track the total reward amount earnings accrued to a particular caller.
	mapping ( address => mapping ( AssetType => uint256 )) public rewardAccrued;

	/** 
		This admin-configurable double-mapping allows us to deduce the Identity 
		"Credit Yield" string of a Neo Tokyo S1 Citizen given the Citizen's reward 
		rate and the reward rate of the Citizen's Vault.
	*/
	mapping ( uint256 => mapping ( string => string )) public identityCreditYield;

	/// Assign a configurable multiplier to each S1 Citizen's Identity credit. 
	mapping ( string => uint256 ) public identityCreditPoints;

	/// Assign a configurable multiplier to each S1 Citizen's Vault credit. 
	mapping ( string => uint256 ) public vaultCreditMultiplier;

	/**
		This struct records the state of each staked S1 Citizen.

		@param stakedBytes The number of BYTES that have been staked into this S1 
			Citizen. Depending on the value of `hasVault`, this S1 Citizen  will be 
			bound to either the `VAULT_CAP` limit or `NO_VAULT_CAP` limit on the 
			number of BYTES that may be staked.
		@param timelockEndTime The time at which the forced, timelocked staking of 
			this S1 Citizen ends. After this time the S1 Citizen may be withdrawn 
			from the staker.
		@param points The number of base points that this staked S1 Citizen is 
			worth, thus determining its share of emissions. An S1 Citizen's base 
			points are a function of the S1 Citizen's component Identity and any 
			associated Vault multiplier. The base points are also multiplied by the 
			timelock option chosen at the time of staking. The base points are 
			supplemented in points calculations by the value of `stakedBytes`.
		@param stakedVaultId The optional ID of the Vault, if there is one, that 
			has been staked alongside this S1 Citizen. If `hasVault` is true, this 
			value may be non-zero to indicate a staked but non-component Vault. If 
			`hasVault` is true and this value is zero, that is indicative of an S1 
			Citizen with a component Vault.
		@param hasVault A boolean indicating whether or not this S1 Citizen has an 
			associated Vault, whether that Vault is a component Vault assembled into 
			the S1 Citizen or one that has been staked alongside the S1 Citizen.
	*/
	struct StakedS1Citizen {
		uint256 stakedBytes;
		uint256 timelockEndTime;
		uint256 points;
		uint256 stakedVaultId;
		bool hasVault;
	}

	/**
		A double mapping from a caller address to a specific S1 Citizen token ID to 
		the staking status of each S1 Citizen. This records the unique per-user 
		staking status of each S1 citizen.
	*/
	mapping ( address => mapping( uint256 => StakedS1Citizen )) public stakedS1;

	/**
		This mapping correlates a caller address to a list of their 
		currently-staked S1 Citizen token IDs.
	*/
	mapping ( address => uint256[] ) private _stakerS1Position;

	/**
		This struct records the state of each staked S2 Citizen.

		@param stakedBytes The number of BYTES that have been staked into this S2 
			Citizen.
		@param timelockEndTime The time at which the forced, timelocked staking of 
			this S2 Citizen ends. After this time the S2 Citizen may be withdrawn 
			from the staker.
		@param points The number of base points that this staked S2 Citizen is 
			worth, thus determining its share of emissions. An S2 Citizen's base 
			points are a function of the timelock option chosen at the time of 
			staking. The base points are supplemented in points calculations by the 
			value of `stakedBytes`.
	*/
	struct StakedS2Citizen {
		uint256 stakedBytes;
		uint256 timelockEndTime;
		uint256 points;
	}

	/**
		A double mapping from a caller address to a specific S2 Citizen token ID to 
		the staking status of each S2 Citizen. This records the unique per-user 
		staking status of each S2 citizen.
	*/
	mapping ( address => mapping( uint256 => StakedS2Citizen )) public stakedS2;

	/**
		This mapping correlates a caller address to a list of their 
		currently-staked S2 Citizen token IDs.
	*/
	mapping ( address => uint256[] ) private _stakerS2Position;

	/**
		This struct defines the LP token staking position of a particular staker.

		@param amount The amount of LP tokens staked by the staker.
		@param timelockEndTime The tiume at which the forced, timelocked staking of 
			these LP tokens ends. After this the LP tokens may be withdrawn.
		@param points The number of points that this LP position accrues.
		@param multiplier The multiplier portion of the timelock option recorded so 
			as to enforce later stakes to use the same point rate.
	*/
	struct LPPosition {
		uint256 amount;
		uint256 timelockEndTime;
		uint256 points;
		uint256 multiplier;
	}

	/**
		This mapping correlates each caller address to details regarding the LP 
		token stake of that caller.
	*/
	mapping ( address => LPPosition ) public stakerLPPosition;

	/**
		This struct supplies the position output state of each staked S1 Citizen.

		@param citizenId The token ID of this S1 Citizen.
		@param stakedBytes The number of BYTES that have been staked into this S1 
			Citizen. Depending on the value of `hasVault`, this S1 Citizen  will be 
			bound to either the `VAULT_CAP` limit or `NO_VAULT_CAP` limit on the 
			number of BYTES that may be staked.
		@param timelockEndTime The time at which the forced, timelocked staking of 
			this S1 Citizen ends. After this time the S1 Citizen may be withdrawn 
			from the staker.
		@param points The number of base points that this staked S1 Citizen is 
			worth, thus determining its share of emissions. An S1 Citizen's base 
			points are a function of the S1 Citizen's component Identity and any 
			associated Vault multiplier. The base points are also multiplied by the 
			timelock option chosen at the time of staking. The base points are 
			supplemented in points calculations by the value of `stakedBytes`.
		@param stakedVaultId The optional ID of the Vault, if there is one, that 
			has been staked alongside this S1 Citizen. If `hasVault` is true, this 
			value may be non-zero to indicate a staked but non-component Vault. If 
			`hasVault` is true and this value is zero, that is indicative of an S1 
			Citizen with a component Vault.
		@param hasVault A boolean indicating whether or not this S1 Citizen has an 
			associated Vault, whether that Vault is a component Vault assembled into 
			the S1 Citizen or one that has been staked alongside the S1 Citizen.
	*/
	struct StakedS1CitizenOutput {
		uint256 citizenId;
		uint256 stakedBytes;
		uint256 timelockEndTime;
		uint256 points;
		uint256 stakedVaultId;
		bool hasVault;
	}

	/**
		This struct supplies the position output state of each staked S2 Citizen.

		@param citizenId The token ID of this S1 Citizen.
		@param stakedBytes The number of BYTES that have been staked into this S2 
			Citizen.
		@param timelockEndTime The time at which the forced, timelocked staking of 
			this S2 Citizen ends. After this time the S2 Citizen may be withdrawn 
			from the staker.
		@param points The number of base points that this staked S2 Citizen is 
			worth, thus determining its share of emissions. An S2 Citizen's base 
			points are a function of the timelock option chosen at the time of 
			staking. The base points are supplemented in points calculations by the 
			value of `stakedBytes`.
	*/
	struct StakedS2CitizenOutput {
		uint256 citizenId;
		uint256 stakedBytes;
		uint256 timelockEndTime;
		uint256 points;
	}

	/**
		This struct records the state of all assets staked by a particular staker 
		address in this staker.

		@param stakedS1Citizens An array containing information about each S1 
			Citizen staked by a particular staker address.
		@param stakedS2Citizens An array containing information about each S2 
			Citizen staked by a particular staker address.
		@param stakedLPPosition Details regarding the LP token stake of a particular
			staker address.
	*/
	struct StakerPosition {
		StakedS1CitizenOutput[] stakedS1Citizens;
		StakedS2CitizenOutput[] stakedS2Citizens;
		LPPosition stakedLPPosition;
	}

	/// Whether or not setting the LP token contract address is locked.
	bool public lpLocked;

	/**
		This struct records an input to the staker's `configurePools` function.

		@param assetType The asset type for the corresponding pool to set.
		@param daoTax The percent, in basis points, of the reward emissions sent to 
			the DAO.
		@param rewardWindows An array specifying the historic amount of BYTES token
			rewarded per-second across all stakers in this particular pool.
	*/
	struct PoolConfigurationInput {
		AssetType assetType;
		uint256 daoTax;
		RewardWindow[] rewardWindows;
	}

	/**
		This event is emitted when an asset is successfully staked.

		@param staker The address of the caller who staked an `asset`.
		@param asset The address of the asset being staked.
		@param timelockOption Data encoding the parameters surrounding the timelock 
			option used in staking the particular asset. Alternatively, this encodes 
			ctiizen information for BYTES staking.
		@param amountOrTokenId The amount of `asset` staked or, for S1 and S2 
			Citizens, the ID of the specific token staked.
	*/
	event Stake (
		address indexed staker,
		address indexed asset,
		uint256 timelockOption,
		uint256 amountOrTokenId
	);

	/**
		This event is emitted each time a recipient claims a reward.

		@param recipient The recipient of the reward.
		@param reward The amount of BYTES rewarded to the `recipient`.
		@param tax The amount of BYTES minted as tax to the DAO.
	*/
	event Claim (
		address indexed recipient,
		uint256 reward,
		uint256 tax
	);

	/**
		This event is emitted when an asset is successfully withdrawn.

		@param caller The address of the caller who withdrew an `asset`.
		@param asset The address of the asset being withdrawn.
		@param amountOrTokenId The amount of `asset` withdrawn or, for S1 and S2 
			Citizens, the ID of the specific token withdrawn.
	*/
	event Withdraw (
		address indexed caller,
		address indexed asset,
		uint256 amountOrTokenId
	);

	/**
		Construct a new instance of this Neo Tokyo staker configured with the given 
		immutable contract addresses.

		@param _bytes The address of the BYTES 2.0 ERC-20 token contract.
		@param _s1Citizen The address of the assembled Neo Tokyo S1 Citizen.
		@param _s2Citizen The address of the assembled Neo Tokyo S2 Citizen.
		@param _lpToken The address of the LP token.
		@param _identity The address of the specific Neo Tokyo Identity sub-item.
		@param _vault The address of the specific Neo Tokyo Vault sub-item.
		@param _vaultCap The limit on the number of BYTES that may be staked per S1 
			Citizen assembled with a component Vault or staked alongside a Vault.
		@param _noVaultCap The limit on the number of BYTES that may be staked per 
			S2 Citizen or S1 Citizen without Vault.
	*/
	constructor (
		address _bytes,
		address _s1Citizen,
		address _s2Citizen,
		address _lpToken,
		address _identity,
		address _vault,
		address _sbt,
		uint256 _vaultCap,
		uint256 _noVaultCap
	) {
		BYTES = _bytes;
		S1_CITIZEN = _s1Citizen;
		S2_CITIZEN = _s2Citizen;
		LP = _lpToken;
		IDENTITY = _identity;
		VAULT = _vault;
		NT_STAKED_CITIZEN = _sbt;
		VAULT_CAP = _vaultCap;
		NO_VAULT_CAP = _noVaultCap;
	}

	/**
		Neo Tokyo Identity items do not expose their "Credit Yield" trait values in 
		an easily-consumed fashion. This function works backwards to calculate the 
		underlying "Credit Yield" trait value of the component Identity item of the 
		Neo Tokyo S1 Citizen with the token ID of `_citizenId` given the reward 
		rate of the S1 Citizen as a whole and the credit multiplier of any 
		component Vault.

		@param _citizenId The token ID of the Neo Tokyo S1 Citizen to retrieve an 
			Identity "Credit Yield" trait value for.
		@param _vaultId The token ID of the Neo Tokyo S1 Citizen's component Vault, 
			if there is one. This parameter is separated to optimized for callers who 
			have already predetermined the token ID of the Vault.

		@return The "Credit Yield" trait value of the component Identity item of 
			the S1 Citizen with the token ID of `_citizenId`.
	*/
	function getCreditYield (
		uint256 _citizenId,
		uint256 _vaultId
	) public view returns (string memory) {

		// Retrieve the total reward rate of this S1 Citizen.
		IGenericGetter citizen = IGenericGetter(S1_CITIZEN);
		uint256 rewardRate = citizen.getRewardRateOfTokenId(_citizenId);
		if (rewardRate == 0) {
			revert CitizenDoesNotExist(_citizenId);
		}

		// Retrieve the credit rate multiplier of any associated Vault.
		IGenericGetter vault = IGenericGetter(VAULT);
		string memory vaultMultiplier = (_vaultId != 0)
			? vault.getCreditMultiplier(_vaultId)
			: "";
		
		// Deduce the original Identity credit yield.
		return identityCreditYield[rewardRate][vaultMultiplier];
	}

	/**
		The multipliers to S1 Citizen points contributed by their component Vaults 
		may be independently configured by permitted administrators of this staking 
		contract. This helper function returns any of the multipliers that may have 
		been configured.

		@param _vaultId The token ID of a Neo Tokyo S1 Vault to retrieve the 
			configued multiplier for.

		@return The configured point multiplier for the Vault with token ID of 
			`_vaultId`.
	*/
	function getConfiguredVaultMultiplier (
		uint256 _vaultId
	) public view returns (uint256) {

		// Retrieve the credit rate multiplier of the Vault.
		IGenericGetter vault = IGenericGetter(VAULT);
		string memory vaultMultiplier = (_vaultId != 0)
			? vault.getCreditMultiplier(_vaultId)
			: "";
		
		// Deduce the configured Vault multiplier.
		return vaultCreditMultiplier[vaultMultiplier];
	}

	/**
		Return the list of `_staker`'s token IDs for the specified `_assetType` if 
		that type is the Neo Tokyo S1 Citizen or S2 Citizen. In order to determine 
		the staker's position in the LP asset type, the public `stakerLPPosition` 
		mapping should be used. It is not valid to directly determine the position 
		in BYTES of a particular staker; to retrieve that kind of cumulative data 
		the full output `getStakerPositions` function should be used.

		@param _staker The address of the staker to check for staked Citizen 
			holdings.
		@param _assetType The asset type to check for staked holdings. This must be 
			the S1 Citizen or S2 Citizen type.

		@return The list of token IDs of a particular Citizen type that have been 
			staked by `_staker`.
	*/
	function getStakerPosition (
		address _staker,
		AssetType _assetType
	) external view returns (uint256[] memory) {
		if (_assetType == AssetType.S1_CITIZEN) {
			return _stakerS1Position[_staker];
		} else if (_assetType == AssetType.S2_CITIZEN) {
			return _stakerS2Position[_staker];
		} else {
			revert UnknowablePosition(uint256(_assetType));
		}
	}

	/**
		Retrieve the entire position of the specified `_staker` across all asset 
		types in this staker.

		@param _staker The address of the staker to check for assets.

		@return The position of the `_staker` across all asset types.
	*/
	function getStakerPositions (
		address _staker
	) external view returns (StakerPosition memory) {

		// Compile the S1 Citizen details.
		StakedS1CitizenOutput[] memory stakedS1Details =
			new StakedS1CitizenOutput[](_stakerS1Position[_staker].length);
		for (uint256 i; i < _stakerS1Position[_staker].length; ) {
			uint256 citizenId = _stakerS1Position[_staker][i];
			StakedS1Citizen memory citizenDetails = stakedS1[_staker][citizenId];
			stakedS1Details[i] = StakedS1CitizenOutput({
				citizenId: citizenId,
				stakedBytes: citizenDetails.stakedBytes,
				timelockEndTime: citizenDetails.timelockEndTime,
				points: citizenDetails.points,
				hasVault: citizenDetails.hasVault,
				stakedVaultId: citizenDetails.stakedVaultId
			});
			unchecked { i++; }
		}

		// Compile the S2 Citizen details.
		StakedS2CitizenOutput[] memory stakedS2Details =
			new StakedS2CitizenOutput[](_stakerS2Position[_staker].length);
		for (uint256 i; i < _stakerS2Position[_staker].length; ) {
			uint256 citizenId = _stakerS2Position[_staker][i];
			StakedS2Citizen memory citizenDetails = stakedS2[_staker][citizenId];
			stakedS2Details[i] = StakedS2CitizenOutput({
				citizenId: citizenId,
				stakedBytes: citizenDetails.stakedBytes,
				timelockEndTime: citizenDetails.timelockEndTime,
				points: citizenDetails.points
			});
			unchecked { i++; }
		}

		// Return the final output position struct.
		return StakerPosition({
			stakedS1Citizens: stakedS1Details,
			stakedS2Citizens: stakedS2Details,
			stakedLPPosition: stakerLPPosition[_staker]
		});
	}

	/**
		A private helper function for performing the low-level call to 
		`transferFrom` on either a specific ERC-721 token or some amount of ERC-20 
		tokens.

		@param _asset The address of the asset to perform the transfer call on.
		@param _from The address to attempt to transfer the asset from.
		@param _to The address to attempt to transfer the asset to.
		@param _idOrAmount This parameter encodes either an ERC-721 token ID or an 
			amount of ERC-20 tokens to attempt to transfer, depending on what 
			interface is implemented by `_asset`.
	*/
	function _assetTransferFrom (
		address _asset,
		address _from,
		address _to,
		uint256 _idOrAmount
	) private {
		(bool success, bytes memory data) = 
			_asset.call(
				abi.encodeWithSelector(
					_TRANSFER_FROM_SELECTOR,
					_from,
					_to, 
					_idOrAmount
				)
			);

		// Revert if the low-level call fails.
		if (!success) {
			revert(string(data));
		}
	}

	/**
		A private helper function for performing the low-level call to `transfer` 
		on some amount of ERC-20 tokens.

		@param _asset The address of the asset to perform the transfer call on.
		@param _to The address to attempt to transfer the asset to.
		@param _amount The amount of ERC-20 tokens to attempt to transfer.
	*/
	function _assetTransfer (
		address _asset,
		address _to,
		uint256 _amount
	) private {
		(bool success, bytes memory data) = 
			_asset.call(
				abi.encodeWithSelector(
					_TRANSFER_SELECTOR,
					_to, 
					_amount
				)
			);

		// Revert if the low-level call fails.
		if (!success) {
			revert(string(data));
		}
	}

	/**
		A private helper for checking equality between two strings.

		@param _a The first string to compare.
		@param _b The second string to compare.

		@return Whether or not `_a` and `_b` are equal.
	*/
	function _stringEquals (
		string memory _a,
		string memory _b
	) private pure returns (bool) {
		bytes memory a = bytes(_a);
		bytes memory b = bytes(_b);
		
		// Check equivalence of the two strings by comparing their contents.
		bool equal = true;
		assembly {
			let length := mload(a)
			switch eq(length, mload(b))

			// Proceed to compare string contents if lengths are equal. 
			case 1 {
				let cb := 1

				// Iterate through the strings and compare contents.
				let mc := add(a, 0x20)
				let end := add(mc, length)
				for {
					let cc := add(b, 0x20)
				} eq(add(lt(mc, end), cb), 2) {
					mc := add(mc, 0x20)
					cc := add(cc, 0x20)
				} {

					// If any of these checks fails then arrays are not equal.
					if iszero(eq(mload(mc), mload(cc))) {
						equal := 0
						cb := 0
					}
				}
			}

			// By default the array length is not equal so the strings are not equal.
			default {
				equal := 0
			}
		}
		return equal;
	}

	/**
		A private helper function for managing the staking of a particular S1 
		Citizen. S1 Citizens may optionally be staked at the same time as a Vault, 
		if they do not already contain a Vault.

		@param _timelock The selected timelock option for the asset being staked. 
			This encodes the timelock duration and multiplier.
	*/
	function _stakeS1Citizen (
		uint256 _timelock
	) private {
		uint256 citizenId;
		uint256 vaultId;
		uint256 handClaimant;

		/*
			Extract the S1 Citizen ID, optional Vault token ID, and optional Hand 
			claimant ID from calldata.
		*/
		assembly {
			citizenId := calldataload(0x44)
			vaultId := calldataload(0x64)
			handClaimant := calldataload(0x84)
		}

		/*
			Attempt to transfer the S1 Citizen to be held in escrow by this staking 
			contract. This transfer will fail if the caller is not the holder of the 
			Citizen. This prevents double staking.
		*/
		_assetTransferFrom(S1_CITIZEN, msg.sender, address(this), citizenId);

		// Retrieve storage for tracking the staking state of this S1 Citizen.
		StakedS1Citizen storage citizenStatus = stakedS1[msg.sender][citizenId];

		// Attach a getter to the S1 Citizen and check for a component Vault.
		IGenericGetter citizen = IGenericGetter(S1_CITIZEN);
		uint256 citizenVaultId = citizen.getVaultIdOfTokenId(citizenId);

		/*
			A new Vault to stake may only be provided if the S1 Citizen being staked 
			does not already have a component Vault.
		*/
		if (citizenVaultId != 0 && vaultId != 0) {
			revert CitizenAlreadyHasVault(citizenVaultId, vaultId);

		/*
			If no optional vault is provided, and the S1 Citizen being staked already 
			has an existing Vault, override the provided `vaultId`.
		*/
		} else if (citizenVaultId != 0 && vaultId == 0) {
			citizenStatus.hasVault = true;
			vaultId = citizenVaultId;

		/*
			Otherwise, if the S1 Citizen has no component Vault, the newly-provided 
			Vault is staked and the S1 Citizen is recorded as carrying an optional, 
			separately-attached vault.
		*/
		} else if (citizenVaultId == 0 && vaultId != 0) {
			_assetTransferFrom(VAULT, msg.sender, address(this), vaultId);
			citizenStatus.hasVault = true;
			citizenStatus.stakedVaultId = vaultId;
		}

		/*
			If the S1 Citizen contains no component Vault and is not staked alongside 
			an optional Vault (`citizenVaultId` == 0 && `vaultId` == 0), we need not 
			do anything to change the initial state of a staked S1 Citizen's Vault.
		*/

		// Determine the base worth in points of the S1 Citizen's Identity.
		string memory citizenCreditYield = getCreditYield(
			citizenId,
			citizenVaultId
		);
		uint256 identityPoints = identityCreditPoints[citizenCreditYield];

		// Hands of the Citadel are always given the same multiplier as '?' Vaults.
		uint256 vaultMultiplier = 100;
		if (handClaimant == 1) {
			uint256 identityId = citizen.getIdentityIdOfTokenId(citizenId);
			string memory class = IGenericGetter(IDENTITY).getClass(identityId);
			if (_stringEquals(class, "Hand of Citadel")) {
				vaultMultiplier = vaultCreditMultiplier["?"];
			} else {
				revert CitizenIsNotHand(citizenId);
			}

		// Otherwise use the configured Vault multiplier, if any.
		} else if (vaultId != 0) {
			vaultMultiplier = getConfiguredVaultMultiplier(vaultId);
		}

		// Decode the timelock option's duration and multiplier.
		uint256 timelockDuration = _timelock >> 128;
		uint256 timelockMultiplier = _timelock & type(uint128).max;

		// Update caller staking information and asset data.
		PoolData storage pool = _pools[AssetType.S1_CITIZEN];
		unchecked {
			citizenStatus.points =
				identityPoints * vaultMultiplier * timelockMultiplier /
				_DIVISOR / _DIVISOR;
			citizenStatus.timelockEndTime = block.timestamp + timelockDuration;

			// Record the caller's staked S1 Citizen.
			_stakerS1Position[msg.sender].push(citizenId);

			// Update stakers missed rewards.
			pool.rewardsMissed[msg.sender] += 
				pool.rewardPerPoint * citizenStatus.points;

			// Update the pool point weights for rewards
			pool.totalPoints += citizenStatus.points;
		}

		// mint the soulbound token upon staking
        INTStakedToken(NT_STAKED_CITIZEN).give(msg.sender, abi.encode(S1_CITIZEN, uint64(citizenId)), "");

		// Emit an event recording this S1 Citizen staking.
		emit Stake(
			msg.sender,
			S1_CITIZEN,
			_timelock,
			citizenId
		);
	}

	/**
		A private function for managing the staking of a particular S2 Citizen.

		@param _timelock The selected timelock option for the asset being staked. 
			This encodes the timelock duration and multiplier.
	*/
	function _stakeS2Citizen (
		uint256 _timelock
	) private {
		uint256 citizenId;

		// Extract the S2 Citizen ID from the calldata.
		assembly {
			citizenId := calldataload(0x44)
		}

		/*
			Attempt to transfer the S2 Citizen to be held in escrow by this staking 
			contract. This transfer will fail if the caller is not the holder of the 
			Citizen. This prevents double staking.
		*/
		_assetTransferFrom(S2_CITIZEN, msg.sender, address(this), citizenId);

		// Retrieve storage for tracking the staking state of this S2 Citizen.
		StakedS2Citizen storage citizenStatus = stakedS2[msg.sender][citizenId];

		// Decode the timelock option's duration and multiplier.
		uint256 timelockDuration = _timelock >> 128;
		uint256 timelockMultiplier = _timelock & type(uint128).max;

		// Update caller staking information and asset data.
		PoolData storage pool = _pools[AssetType.S2_CITIZEN];
		unchecked {
			citizenStatus.points = 100 * timelockMultiplier / _DIVISOR;
			citizenStatus.timelockEndTime = block.timestamp + timelockDuration;

			// Record the caller's staked S2 Citizen.
			_stakerS2Position[msg.sender].push(citizenId);

			// Update the pool point weights for rewards
			pool.totalPoints += citizenStatus.points;

			// Update stakers missed rewards.
			pool.rewardsMissed[msg.sender] += 
				pool.rewardPerPoint * citizenStatus.points;
		}


		// mint the soulbound token upon staking
        INTStakedToken(NT_STAKED_CITIZEN).give(msg.sender, abi.encode(S2_CITIZEN, uint64(citizenId)), "");



		// Emit an event recording this S1 Citizen staking.
		emit Stake(
			msg.sender,
			S2_CITIZEN,
			_timelock,
			citizenId
		);
	}

	/**
		A private function for managing the staking of BYTES into a Citizen.
	*/
	function _stakeBytes (
		uint256
	) private {
		uint256 amount;
		uint256 citizenId;
		uint256 seasonId;
		assembly{
			amount := calldataload(0x44)
			citizenId := calldataload(0x64)
			seasonId := calldataload(0x84)
		}

		// Attempt to transfer BYTES to escrow.
		_assetTransferFrom(BYTES, msg.sender, address(this), amount);

		// Handle staking BYTES into an S1 Citizen.
		if (seasonId == 1) {
			StakedS1Citizen storage citizenStatus = stakedS1[msg.sender][citizenId];
			uint256 cap = VAULT_CAP;
			if (!citizenStatus.hasVault) {
				cap = NO_VAULT_CAP;
			}
			if (citizenStatus.stakedBytes + amount > cap) {
				revert AmountExceedsCap(citizenStatus.stakedBytes + amount, cap);
			}

			// Validate that the caller actually staked the Citizen.
			if (citizenStatus.timelockEndTime == 0) {
				revert CannotStakeIntoUnownedCitizen(citizenId, seasonId);
			}

			PoolData storage pool = _pools[AssetType.S1_CITIZEN];
			unchecked {
				uint256 bonusPoints = (amount * 100 / _BYTES_PER_POINT);
				citizenStatus.stakedBytes += amount;
				citizenStatus.points += bonusPoints;
				pool.totalPoints += bonusPoints;

				// Update stakers missed rewards.
				pool.rewardsMissed[msg.sender] += 
					pool.rewardPerPoint * bonusPoints;
			}

		// Handle staking BYTES into an S2 Citizen.
		} else if (seasonId == 2) {
			StakedS2Citizen storage citizenStatus = stakedS2[msg.sender][citizenId];
			uint256 cap = NO_VAULT_CAP;
			if (citizenStatus.stakedBytes + amount > cap) {
				revert AmountExceedsCap(citizenStatus.stakedBytes + amount, cap);
			}

			// Validate that the caller actually staked the Citizen.
			if (citizenStatus.timelockEndTime == 0) {
				revert CannotStakeIntoUnownedCitizen(citizenId, seasonId);
			}

			PoolData storage pool = _pools[AssetType.S2_CITIZEN];
			unchecked {
				uint256 bonusPoints = (amount * 100 / _BYTES_PER_POINT);
				citizenStatus.stakedBytes += amount;
				citizenStatus.points += bonusPoints;
				pool.totalPoints += bonusPoints;

				// Update stakers missed rewards.
				pool.rewardsMissed[msg.sender] += 
					pool.rewardPerPoint * bonusPoints;
			}

		// Revert because an invalid season ID has been supplied.
		} else {
			revert InvalidSeasonId(seasonId);
		}

		// Emit an event.
		emit Stake(
			msg.sender,
			BYTES,
			(seasonId << 128) + citizenId,
			amount
		);
	}

	/**
		A private function for managing the staking of LP tokens.

		@param _timelock The selected timelock option for the asset being staked. 
			This encodes the timelock duration and multiplier.
	*/
	function _stakeLP (
		uint256 _timelock
	) private {
		uint256 amount;
		assembly{
			amount := calldataload(0x44)
		}

		/*
			Attempt to transfer the LP tokens to be held in escrow by this staking 
			contract. This transfer will fail if the caller does not hold enough 
			tokens.
		*/
		_assetTransferFrom(LP, msg.sender, address(this), amount);

		// Decode the timelock option's duration and multiplier.
		uint256 timelockDuration = _timelock >> 128;
		uint256 timelockMultiplier = _timelock & type(uint128).max;

		// If this is a new stake of this asset, initialize the multiplier details.
		if (stakerLPPosition[msg.sender].multiplier == 0) {
			stakerLPPosition[msg.sender].multiplier = timelockMultiplier;

		// If a multiplier exists already, we must match it.
		} else if (stakerLPPosition[msg.sender].multiplier != timelockMultiplier) {
			revert MismatchedTimelock();
		}

		// Update caller staking information and asset data.
		PoolData storage pool = _pools[AssetType.LP];
		unchecked {
			uint256 points = amount * 100 / 1e18 * timelockMultiplier / _DIVISOR;

			// Update the caller's LP token stake.
			stakerLPPosition[msg.sender].timelockEndTime =
				block.timestamp + timelockDuration;
			stakerLPPosition[msg.sender].amount += amount;
			stakerLPPosition[msg.sender].points += points;

			/// Update stakers missed rewards.
			pool.rewardsMissed[msg.sender] += 
				pool.rewardPerPoint * points;

			// Update the pool point weights for rewards.
			pool.totalPoints += points;
		}

		// Emit an event recording this LP staking.
		emit Stake(
			msg.sender,
			LP,
			_timelock,
			amount
		);
	}

	/**
		Use the emission schedule of a particular asset pool to calculate the total
		amount of staking reward token emitted between two specified timestamps.

		@param _assetType The type of the asset to calculate emissions for.
		@param _from The time to begin calculating emissions from.
	*/
	function getTotalEmissions (
		AssetType _assetType,
		uint256 _from
	) public view returns (uint256) {
		PoolData storage pool = _pools[_assetType];

		/*
				Determine the reward for the `_recipient` based on their points total. 
				Iterate through the entire array of pool reward windows to find the 
				applicable time period.
			*/
			uint256 totalReward;
			uint256 windowCount = pool.rewardCount;
			for (uint256 i; i < windowCount; ) {
				RewardWindow memory window = pool.rewardWindows[i];

				/*
					If the last reward time is less than the starting time of this 
					window, then the reward was accrued in the previous window.
				*/
				if (_from < window.startTime) {
					uint256 currentRewardRate = pool.rewardWindows[i - 1].reward;

					/*
						Iterate forward to the present timestamp over any unclaimed reward 
						windows.
					*/
					for (uint256 j = i; j < windowCount; ) {

						// If the current time falls within this window, complete.
						if (block.timestamp <= window.startTime) {
							unchecked {
								uint256 timeSinceReward = block.timestamp - _from;
								totalReward += currentRewardRate * timeSinceReward;	
							}

							// We have no forward goto and thus include this bastardry.
							i = windowCount;
							break;

						// Otherwise, accrue the remainder of this window and iterate.
						} else {
							unchecked {
								uint256 timeSinceReward = window.startTime - _from;
								totalReward += currentRewardRate * timeSinceReward;
							}
							currentRewardRate = window.reward;
							_from = window.startTime;

							/*
								Handle the special case of overrunning the final window by 
								fulfilling the prior window and then jumping forward to use the 
								final reward window.
							*/
							if (j == windowCount - 1) {
								unchecked {
									uint256 timeSinceReward =
										block.timestamp - _from;
									totalReward += currentRewardRate * timeSinceReward;
								}
	
								// We have no forward goto and thus include this bastardry.
								i = windowCount;
								break;
	
							// Otherwise, iterate.
							} else {
								window = pool.rewardWindows[j + 1];
							}
						}
						unchecked { j++; }
					}

				/*
					Otherwise, the last reward rate, and therefore the entireity of 
					accrual, falls in the last window.
				*/
				} else if (i == windowCount - 1) {
					unchecked {
						uint256 timeSinceReward = block.timestamp - _from;
						totalReward = window.reward * timeSinceReward;
					}
					break;
				}
				unchecked { i++; }
			}
		
		return totalReward;
	}

  /**
		This function supports retrieving the reward and tax earned by a particular 
		`_recipient` on a specific pool of type `_assetType`. It is meant to be
    called by a frontend interface that needs to show pending rewards.

		@param _assetType The type of the asset to calculate rewards for.
		@param _recipient The recipient of the reward.
	*/
	function getPendingPoolReward (
		AssetType _assetType,
		address _recipient
	) external view returns (uint256, uint256) {

		/*
			During the very first stake, there will not be any points in the pool. In 
			this case, do not attempt to grant any rewards so as to prevent reversion.
		*/
		PoolData storage pool = _pools[_assetType];
    if (pool.totalPoints == 0) {
			return (0, 0);
		}

		// Calculate rewards for this pool.
		uint256 totalEmissions = getTotalEmissions(
			_assetType,
			pool.lastUpdated
		);

		// Update the pool rewards per point to pay users the amount remaining.
		uint256 pendingRPP = pool.rewardPerPoint
			+ (totalEmissions / pool.totalPoints);

		// Calculate the total number of points accrued to the `_recipient`.
		uint256 points;
		if (_assetType == AssetType.S1_CITIZEN) {
			for (uint256 i; i < _stakerS1Position[_recipient].length; ) {
				uint256 citizenId = _stakerS1Position[_recipient][i];
				StakedS1Citizen memory s1Citizen = stakedS1[_recipient][citizenId];
				unchecked {
					points += s1Citizen.points;
					i++;
				}
			}
		} else if (_assetType == AssetType.S2_CITIZEN) {
			for (uint256 i; i < _stakerS2Position[_recipient].length; ) {
				uint256 citizenId = _stakerS2Position[_recipient][i];
				StakedS2Citizen memory s2Citizen = stakedS2[_recipient][citizenId];
				unchecked {
					points += s2Citizen.points;
					i++;
				}
			}
		} else if (_assetType == AssetType.LP) {
			unchecked {
				points += stakerLPPosition[_recipient].points;
			}
		} else {
			revert InvalidAssetType(uint256(_assetType));
		}
		if (points > 0) {
  		uint256 share = points * pendingRPP
	  		- rewardAccrued[_recipient][_assetType]
				- pool.rewardsMissed[_recipient];
			uint256 daoShare = share * pool.daoTax / (100 * _DIVISOR);
			return ((share - daoShare), daoShare);
		}
		return (0, 0);
	}

	/**
		Update the pool corresponding to the specified asset.
		
		@param _assetType The type of the asset to update pool rewards for.
	*/
	function _updatePool (
		AssetType _assetType
	) private {
		PoolData storage pool = _pools[_assetType];
		if (pool.totalPoints == 0) {
			pool.lastUpdated = block.timestamp;
			return;
		}

		// Calculate rewards for this pool.
		uint256 totalEmissions = getTotalEmissions(
			_assetType,
			pool.lastUpdated
		);

		// Update the pool rewards per point to pay users the amount remaining.
		pool.rewardPerPoint = pool.rewardPerPoint
			+ (totalEmissions / pool.totalPoints);
		pool.lastUpdated = block.timestamp;
	}

	/**
		Stake a particular asset into this contract, updating its corresponding 
		rewards.

		@param _assetType An ID of the specific asset that the caller is attempting 
			to deposit into this staker.
		@param _timelockId The ID of a specific timelock period to select. This 
			timelock ID must be configured for the specific `_assetType`.
		@custom:param The third parameter is overloaded to have different meaning 
			depending on the `assetType` selected. In the event of staking an S1 or 
			S2 Citizen, this parameter is the token ID of the Citizen being staked. 
			In the event of staking BYTES or LP tokens, this parameter is the amount 
			of the respective token being staked.
		@custom:param If the asset being staked is an S1 Citizen, this is the ID of 
			a Vault to attempt to optionally attach.
		@custom:param If the asset being staked is an S1 Citizen, this is a flag to 
			attempt to claim a Hand of the Citadel bonus. If the asset being staked 
			is BYTES, this is either one or two to select the Neo Tokyo season ID of 
			the S1 or S2 Citizen that BYTES are being staked into.
	*/
	function stake (
		AssetType _assetType,
		uint256 _timelockId,
		uint256,
		uint256,
		uint256
	) external nonReentrant {

		// Validate that the asset being staked is of a valid type.
		if (uint8(_assetType) > 4) {
			revert InvalidAssetType(uint256(_assetType));
		}

		// Validate that the asset being staked matches a configured pool.
		if (_pools[_assetType].rewardCount == 0) {
			revert UnconfiguredPool(uint256(_assetType));
		}

		// Validate that the asset being staked matches an active pool.
		if (_pools[_assetType].rewardWindows[0].startTime >= block.timestamp) {
			revert InactivePool(uint256(_assetType));
		}

		// Validate that the selected timelock option is valid for the staked asset.
		uint256 timelockOption = timelockOptions[_assetType][_timelockId];
		if (timelockOption == 0) {
			revert InvalidTimelockOption(uint256(_assetType), _timelockId);
		}

		// Update pool rewards.
		_updatePool(_assetType);

		// Grant the caller their total rewards with each staking action.
		IByteContract(BYTES).getReward(msg.sender);

		// Store references to each available staking function.
		function (uint256) _s1 = _stakeS1Citizen;
		function (uint256) _s2 = _stakeS2Citizen;
		function (uint256) _b = _stakeBytes;
		function (uint256) _lp = _stakeLP;

		// Select the proper staking function based on the asset type being staked.
		function (uint256) _stake;
		assembly {
			switch _assetType
				case 0 {
					_stake := _s1
				}
				case 1 {
					_stake := _s2
				}
				case 2 {
					_stake := _b
				}
				case 3 {
					_stake := _lp
				}
				default {}
		}

		// Invoke the correct staking function.
		_stake(timelockOption);
	}

	/**
		This function supports retrieving the reward and tax earned by a particular 
		`_recipient` on a specific pool of type `_assetType`. It is meant to be
    called in conjuction with `_updatePool` and a reward claim.

		@param _assetType The type of the asset to calculate rewards for.
		@param _recipient The recipient of the reward.
	*/
	function _getPoolReward (
		AssetType _assetType,
		address _recipient
	) private view returns (uint256, uint256) {

		/*
			During the very first stake, there will not be any points in the pool. In 
			this case, do not attempt to grant any rewards so as to prevent reversion.
		*/
		PoolData storage pool = _pools[_assetType];

		// Calculate the total number of points accrued to the `_recipient`.
		uint256 points;
		if (_assetType == AssetType.S1_CITIZEN) {
			for (uint256 i; i < _stakerS1Position[_recipient].length; ) {
				uint256 citizenId = _stakerS1Position[_recipient][i];
				StakedS1Citizen memory s1Citizen = stakedS1[_recipient][citizenId];
				unchecked {
					points += s1Citizen.points;
					i++;
				}
			}
		} else if (_assetType == AssetType.S2_CITIZEN) {
			for (uint256 i; i < _stakerS2Position[_recipient].length; ) {
				uint256 citizenId = _stakerS2Position[_recipient][i];
				StakedS2Citizen memory s2Citizen = stakedS2[_recipient][citizenId];
				unchecked {
					points += s2Citizen.points;
					i++;
				}
			}
		} else if (_assetType == AssetType.LP) {
			unchecked {
				points += stakerLPPosition[_recipient].points;
			}
		} else {
			revert InvalidAssetType(uint256(_assetType));
		}
		if (points > 0) {
  		uint256 share = points * pool.rewardPerPoint
	  		- rewardAccrued[_recipient][_assetType]
				- pool.rewardsMissed[_recipient];
			uint256 daoShare = share * pool.daoTax / (100 * _DIVISOR);
			return ((share - daoShare), daoShare);
		}
		return (0, 0);
	}

	/**
		Determine the reward, based on staking participation at this moment, of a 
		particular recipient. Due to a historic web of Neo Tokyo dependencies, 
		rewards are actually minted through the BYTES contract.

		@param _recipient The recipient to calculate the reward for.

		@return A tuple containing (the number of tokens due to be minted to 
			`_recipient` as a reward, and the number of tokens that should be minted 
			to the DAO treasury as a DAO tax).
	*/
	function claimReward (
		address _recipient
	) external returns (uint256, uint256) {

		// This function may only be called by the BYTES contract.
		if (msg.sender != BYTES) {
			revert CallerIsNotBYTES();
		}

		// Update pool rewards.
		_updatePool(AssetType.S1_CITIZEN);
		_updatePool(AssetType.S2_CITIZEN);
		_updatePool(AssetType.LP);

		// Retrieve the `_recipient` reward share from each pool.
		(uint256 s1Reward, uint256 s1Tax) = _getPoolReward(
			AssetType.S1_CITIZEN,
			_recipient
		);
		(uint256 s2Reward, uint256 s2Tax) = _getPoolReward(
			AssetType.S2_CITIZEN,
			_recipient
		);
		(uint256 lpReward, uint256 lpTax) = _getPoolReward(
			AssetType.LP,
			_recipient
		);

		// Record the current time as the beginning time for checking rewards.
		lastRewardTime[_recipient][AssetType.S1_CITIZEN] = block.timestamp;
		lastRewardTime[_recipient][AssetType.S2_CITIZEN] = block.timestamp;
		lastRewardTime[_recipient][AssetType.LP] = block.timestamp;

		// Calculate total reward and tax.
		uint256 totalReward;
		uint256 totalTax;
		unchecked {
			totalReward = (s1Reward + s2Reward + lpReward);
			totalTax = (s1Tax + s2Tax + lpTax);
			rewardAccrued[_recipient][AssetType.S1_CITIZEN] += (s1Reward + s1Tax);
			rewardAccrued[_recipient][AssetType.S2_CITIZEN] += (s2Reward + s2Tax);
			rewardAccrued[_recipient][AssetType.LP] += (lpReward + lpTax);
		}

		// Emit an event.
		emit Claim (
			_recipient,
			totalReward,
			totalTax
		);

		// Return the final reward for the user and the tax rewarded to the DAO.
		return (totalReward, totalTax);
	}

	/**
		A private function for managing the withdrawal of S1 Citizens.
	*/
	function _withdrawS1Citizen () private {
		uint256 citizenId;
		assembly {
			citizenId := calldataload(0x24)
		}

		// Validate that the caller has cleared their asset timelock.
		StakedS1Citizen storage stakedCitizen = stakedS1[msg.sender][citizenId];
		if (block.timestamp < stakedCitizen.timelockEndTime) {
			revert TimelockNotCleared(stakedCitizen.timelockEndTime);
		}

		// Validate that the caller actually staked this asset.
		if (stakedCitizen.timelockEndTime == 0) {
			revert CannotWithdrawUnownedS1(citizenId);
		}
		
		// Return any staked BYTES.
		if (stakedCitizen.stakedBytes > 0) {
			_assetTransfer(BYTES, msg.sender, stakedCitizen.stakedBytes);
		}
		
		// Return any non-component Vault if one is present.
		if (stakedCitizen.stakedVaultId != 0) {
			_assetTransferFrom(
				VAULT,
				address(this),
				msg.sender,
				stakedCitizen.stakedVaultId
			);
		}

		// Return the S1 Citizen.
		_assetTransferFrom(S1_CITIZEN, address(this), msg.sender, citizenId);

		// burn the soulbound token
		uint256 tokenId;
		address addr = S1_CITIZEN;
        assembly {
            // this is the equivalent of
            // encoded = uint256(addr);
            // encoded <<= 96;
            // encoded |= citizen id
            tokenId := or(shl(96, addr), citizenId)
        }
		INTStakedToken(NT_STAKED_CITIZEN).burn(tokenId);

		/*
			Check each citizen ID to find its index and remove the token from the
			staked item array of its old position.
		*/
		uint256[] storage oldPosition = _stakerS1Position[msg.sender];
		for (uint256 stakedIndex; stakedIndex < oldPosition.length; ) {

			// Remove the element at the matching index.
			if (citizenId == oldPosition[stakedIndex]) {
				if (stakedIndex != oldPosition.length - 1) {
					oldPosition[stakedIndex] = oldPosition[oldPosition.length - 1];
				}
				oldPosition.pop();
				break;
			}
			unchecked { stakedIndex++; }
		}

		// Update caller staking information and asset data.
		PoolData storage pool = _pools[AssetType.S1_CITIZEN];
		uint256 leftoverPoints;
		for (uint256 i; i < _stakerS1Position[msg.sender].length; ) {
			uint256 leftoverId = _stakerS1Position[msg.sender][i];
			StakedS1Citizen memory s1Citizen = stakedS1[msg.sender][leftoverId];
			unchecked {
				leftoverPoints += s1Citizen.points;
				i++;
			}
		}

		unchecked {
			pool.totalPoints -= stakedCitizen.points;
		}

		pool.rewardsMissed[msg.sender] = leftoverPoints * pool.rewardPerPoint;
		delete rewardAccrued[msg.sender][AssetType.S1_CITIZEN];
		stakedCitizen.stakedBytes = 0;
		stakedCitizen.timelockEndTime = 0;
		stakedCitizen.points = 0;
		stakedCitizen.hasVault = false;
		stakedCitizen.stakedVaultId = 0;

		// Emit an event recording this S1 withdraw.
		emit Withdraw(
			msg.sender,
			S1_CITIZEN,
			citizenId
		);
	}

	/**
		A private function for managing the withdrawal of S2 Citizens.
	*/
	function _withdrawS2Citizen () private {
		uint256 citizenId;
		assembly {
			citizenId := calldataload(0x24)
		}

		// Validate that the caller has cleared their asset timelock.
		StakedS2Citizen storage stakedCitizen = stakedS2[msg.sender][citizenId];
		if (block.timestamp < stakedCitizen.timelockEndTime) {
			revert TimelockNotCleared(stakedCitizen.timelockEndTime);
		}

		// Validate that the caller actually staked this asset.
		if (stakedCitizen.timelockEndTime == 0) {
			revert CannotWithdrawUnownedS2(citizenId);
		}

		// Return any staked BYTES.
		if (stakedCitizen.stakedBytes > 0) {
			_assetTransfer(BYTES, msg.sender, stakedCitizen.stakedBytes);
		}

		// Return the S2 Citizen.
		_assetTransferFrom(S2_CITIZEN, address(this), msg.sender, citizenId);

		// burn the soulbound token
		uint256 tokenId;
		address addr = S2_CITIZEN;
        assembly {
            // this is the equivalent of
            // encoded = uint256(addr);
            // encoded <<= 96;
            // encoded |= citizen id
            tokenId := or(shl(96, addr), citizenId)
        }
		INTStakedToken(NT_STAKED_CITIZEN).burn(tokenId);

		/*
			Check each citizen ID to find its index and remove the token from the
			staked item array of its old position.
		*/
		uint256[] storage oldPosition = _stakerS2Position[msg.sender];
		for (uint256 stakedIndex; stakedIndex < oldPosition.length; ) {

			// Remove the element at the matching index.
			if (citizenId == oldPosition[stakedIndex]) {
				if (stakedIndex != oldPosition.length - 1) {
					oldPosition[stakedIndex] = oldPosition[oldPosition.length - 1];
				}
				oldPosition.pop();
				break;
			}
			unchecked { stakedIndex++; }
		}

		// Calculate the caller's leftover points.
		uint256 leftoverPoints;
		for (uint256 i; i < _stakerS2Position[msg.sender].length; ) {
			uint256 leftoverId = _stakerS2Position[msg.sender][i];
			StakedS2Citizen memory s2Citizen = stakedS2[msg.sender][leftoverId];
			unchecked {
				leftoverPoints += s2Citizen.points;
				i++;
			}
		}

		// Update caller staking information and asset data.
		PoolData storage pool = _pools[AssetType.S2_CITIZEN];
		unchecked {
			pool.totalPoints -= stakedCitizen.points;
		}
		pool.rewardsMissed[msg.sender] = leftoverPoints * pool.rewardPerPoint;
		delete rewardAccrued[msg.sender][AssetType.S2_CITIZEN];
		stakedCitizen.stakedBytes = 0;
		stakedCitizen.timelockEndTime = 0;
		stakedCitizen.points = 0;

		// Emit an event recording this S2 withdraw.
		emit Withdraw(
			msg.sender,
			S2_CITIZEN,
			citizenId
		);
	}

	/**
		A private function for managing the withdrawal of LP tokens.
	*/
	function _withdrawLP () private {
		uint256 amount;
		assembly{
			amount := calldataload(0x24)
		}

		// Validate that the caller has cleared their asset timelock.
		LPPosition storage lpPosition = stakerLPPosition[msg.sender];
		if (block.timestamp < lpPosition.timelockEndTime) {
			revert TimelockNotCleared(lpPosition.timelockEndTime);
		}

		// Validate that the caller has enough staked LP tokens to withdraw.
		if (lpPosition.amount < amount) {
			revert NotEnoughLPTokens(amount, lpPosition.amount);
		}

		/*
			Attempt to transfer the LP tokens held in escrow by this staking contract 
			back to the caller.
		*/
		_assetTransfer(LP, msg.sender, amount);

		// Update caller staking information and asset data.
		PoolData storage pool = _pools[AssetType.LP];
		unchecked {
			uint256 points = amount * 100 / 1e18 * lpPosition.multiplier / _DIVISOR;
			uint256 pointsIntact = points > lpPosition.points ? 0 : lpPosition.points - points;
			delete rewardAccrued[msg.sender][AssetType.LP];
			pool.rewardsMissed[msg.sender] = pointsIntact * pool.rewardCount;

			// Update the caller's LP token stake.
			lpPosition.amount -= amount;
			lpPosition.points = pointsIntact;

			// Update the pool point weights for rewards.
			pool.totalPoints -= points;
		}

		// If all LP tokens are withdrawn, we must clear the multiplier.
		if (lpPosition.amount == 0) {
			lpPosition.multiplier = 0;
		}

		// Emit an event recording this LP withdraw.
		emit Withdraw(
			msg.sender,
			LP,
			amount
		);
	}

	/**
		Withdraw a particular asset from this contract, updating its corresponding 
		rewards. A caller may only withdraw an asset provided they are the staker 
		and that timelocks are not violated.

		@param _assetType An ID of the specific asset that the caller is attempting 
			to withdraw from this staker.
		@custom:param The third parameter is overloaded to have different meaning 
			depending on the `assetType` selected. In the event of withdrawing an S1 
			or S2 Citizen, this is the token ID of the Citizen to attempt to 
			withdraw. In the event of withdrawing LP tokens, this is the amount of 
			the LP token to withdraw.
	*/
	function withdraw (
		AssetType _assetType,
		uint256
	) external nonReentrant {

		/*
			Validate that the asset being withdrawn is of a valid type. BYTES may not 
			be withdrawn independently of the Citizen that they are staked into.
		*/
		if (uint8(_assetType) == 2 || uint8(_assetType) > 4) {
			revert InvalidAssetType(uint256(_assetType));
		}

		// Update pool rewards.
		_updatePool(_assetType);

		// Grant the caller their total rewards with each withdrawal action.
		IByteContract(BYTES).getReward(msg.sender);

		// Store references to each available withdraw function.
		function () _s1 = _withdrawS1Citizen;
		function () _s2 = _withdrawS2Citizen;
		function () _lp = _withdrawLP;

		// Select the proper withdraw function based on the asset type.
		function () _withdraw;
		assembly {
			switch _assetType
				case 0 {
					_withdraw := _s1
				}
				case 1 {
					_withdraw := _s2
				}
				case 3 {
					_withdraw := _lp
				}
				default {}
		}

		// Invoke the correct withdraw function.
		_withdraw();
	}

	/**
		This function allows a permitted user to configure the LP token contract 
		address. Extreme care must be taken to avoid doing this if there are any LP 
		stakers, lest staker funds be lost. It is recommended that `lockLP` be 
		invoked.

		@param _lp The address of the LP token contract to specify.
	*/
	function configureLP (
		address _lp
	) external hasValidPermit(UNIVERSAL, CONFIGURE_LP) {
		if (lpLocked) {
			revert LockedConfigurationOfLP();
		}
		LP = _lp;
	}

	/**
		This function allows a permitted user to forever prevent alteration of the 
		LP token contract address.
	*/
	function lockLP () external hasValidPermit(UNIVERSAL, CONFIGURE_LP) {
		lpLocked = true;
	}

	/**
		This function allows a permitted user to configure the timelock options 
		available for each type of asset.

		@param _assetType The type of asset whose timelock options are being 
			configured.
		@param _timelockIds An array with IDs for specific timelock options 
			available under `_assetType`.
		@param _encodedSettings An array keyed to `_timelockIds` containing a 
			bit-packed value specifying the details of the timelock. The upper 128 
			bits are the timelock duration and the lower 128 bits are the multiplier.
	*/
	function configureTimelockOptions (
		AssetType _assetType,
		uint256[] memory _timelockIds,
		uint256[] memory _encodedSettings
	) external hasValidPermit(bytes32(uint256(_assetType)), CONFIGURE_TIMELOCKS) {
		for (uint256 i; i < _timelockIds.length; ) {
			timelockOptions[_assetType][_timelockIds[i]] = _encodedSettings[i];
			unchecked { ++i; }
		}
	}

	/**
		This function allows a permitted user to configure the double mapping of 
		combined S1 Citizen reward rates and Vault reward credit multipliers 
		required to deduce the resulting S1 Identity "Credit Yield" strings.

		@param _citizenRewardRates An array of S1 Citizen reward rate values.
		@param _vaultRewardRates An array of Vault reward rate multipliers 
			corresponding to the provided `_citizenRewardRates`.
		@param _identityCreditYields An array of the S1 Identity "Credit Yield" 
			strings that must correspond to the provided `_citizenRewardRates` and 
			`_vaultRewardRates`.
	*/
	function configureIdentityCreditYields (
		uint256[] memory _citizenRewardRates, 
		string[] memory _vaultRewardRates,
		string[] memory _identityCreditYields
	) hasValidPermit(UNIVERSAL, CONFIGURE_CREDITS) external {
		for (uint256 i; i < _citizenRewardRates.length; ) {
			identityCreditYield[
				_citizenRewardRates[i]
			][
				_vaultRewardRates[i]
			] = _identityCreditYields[i];
			unchecked { ++i; }
		}
	}

	/**
		This funciton allows a permitted user to override the base points 
		associated with a particular S1 Identity "Credit Yield" string.

		@param _identityCreditYields An array of S1 Identity "Credit Yield" strings.
		@param _points The base points associated with each value in 
			`_identityCreditYields`.
	*/
	function configureIdentityCreditPoints (
		string[] memory _identityCreditYields,
		uint256[] memory _points
	) hasValidPermit(UNIVERSAL, CONFIGURE_CREDITS) external {
		for (uint256 i; i < _identityCreditYields.length; ) {
			identityCreditPoints[_identityCreditYields[i]] = _points[i];
			unchecked { ++i; }
		}
	}

	/**
		This function allows a permitted user to override the S1 Vault multiplier 
		rates associated with a particular S1 Vault "credit multiplier" string.

		@param _vaultCreditMultipliers An array of S1 Vault credit multiplier 
			strings.
		@param _multipliers An array of multipliers, in basis points, keyed to each 
			value in `_vaultCreditMultipliers`.
	*/
	function configureVaultCreditMultipliers (
		string[] memory _vaultCreditMultipliers,
		uint256[] memory _multipliers
	) hasValidPermit(UNIVERSAL, CONFIGURE_CREDITS) external {
		for (uint256 i; i < _vaultCreditMultipliers.length; ) {
			vaultCreditMultiplier[_vaultCreditMultipliers[i]] = _multipliers[i];
			unchecked { ++i; }
		}
	}

	/**
		This function allows a permitted user to set the reward emission and DAO 
		tax rates of the asset staking pools.

		@param _inputs An array of `PoolConfigurationInput` structs defining 
			configuration details for each of the pools being updated.
	*/
	function configurePools (
		PoolConfigurationInput[] memory _inputs
	) hasValidPermit(UNIVERSAL, CONFIGURE_POOLS) external {
		for (uint256 i; i < _inputs.length; ) {
			uint256 poolRewardWindowCount = _inputs[i].rewardWindows.length;
			_pools[_inputs[i].assetType].rewardCount = poolRewardWindowCount;
			_pools[_inputs[i].assetType].daoTax = _inputs[i].daoTax;

			// Set the pool reward window details by populating the mapping.
			uint256 lastTime;
			for (uint256 j; j < poolRewardWindowCount; ) {
				_pools[_inputs[i].assetType].rewardWindows[j] =
					_inputs[i].rewardWindows[j];

				// Revert if an invalid pool configuration is supplied.
				if (j != 0 && _inputs[i].rewardWindows[j].startTime <= lastTime) {
					revert RewardWindowTimesMustIncrease();
				}
				lastTime = _inputs[i].rewardWindows[j].startTime;
				unchecked { j++; }
			}
			unchecked { ++i; }
		}
	}

	/**
		This function allows a permitted user to update the vaulted and unvaulted 
		Citizen BYTES staking caps.

		@param _vaultedCap The new cap of BYTES staking on vaulted Citizens.
		@param _unvaultedCap The new cap of BYTES staking on unvaulted Citizens.
	*/
	function configureCaps (
		uint256 _vaultedCap,
		uint256 _unvaultedCap
	) hasValidPermit(UNIVERSAL, CONFIGURE_CAPS) external {
		VAULT_CAP = _vaultedCap;
		NO_VAULT_CAP = _unvaultedCap;
	}
}