// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ======================= DEIStablecoin (DEI) ======================
// ====================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Vahid: https://github.com/vahid-dev
// SAYaghoubnejad: https://github.com/SAYaghoubnejad

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "../Common/Context.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/ERC20Custom.sol";
import "../ERC20/ERC20.sol";
import "../Staking/Owned.sol";
import "../DEUS/DEUS.sol";
import "./Pools/DEIPool.sol";
import "../Oracle/Oracle.sol";
import "../Oracle/ReserveTracker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DEIStablecoin is ERC20Custom, AccessControl {
	using ECDSA for bytes32;

	/* ========== STATE VARIABLES ========== */
	enum PriceChoice {
		DEI,
		DEUS
	}
	address public oracle;
	string public symbol;
	string public name;
	uint8 public constant decimals = 18;
	address public creator_address;
	address public deus_address;
	uint256 public constant genesis_supply = 10000e18; // genesis supply is 10k on Mainnet. This is to help with establishing the Uniswap pools, as they need liquidity
	address public reserve_tracker_address;

	// The addresses in this array are added by the oracle and these contracts are able to mint DEI
	address[] public dei_pools_array;

	// Mapping is also used for faster verification
	mapping(address => bool) public dei_pools;

	// Constants for various precisions
	uint256 private constant PRICE_PRECISION = 1e6;

	uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
	uint256 public dei_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
	uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
	// uint256 public price_target; // The price of DEI at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
	uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

	bytes32 public constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
	bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bool public collateral_ratio_paused = false;


	// 6 decimals of precision
	uint256 public growth_ratio;
	uint256 public GR_top_band;
	uint256 public GR_bottom_band;

	// Bands
	uint256 public DEI_top_band;
	uint256 public DEI_bottom_band;

	// Booleans
	// bool public is_active;
	bool public use_growth_ratio;
	bool public FIP_6;


	/* ========== MODIFIERS ========== */

	modifier onlyCollateralRatioPauser() {
		require(hasRole(COLLATERAL_RATIO_PAUSER, msg.sender), "DEI: you are not the collateral ratio pauser");
		_;
	}

	modifier onlyPoolsOrMinters() {
		require(
			dei_pools[msg.sender] == true ||
			hasRole(MINTER_ROLE, msg.sender),
			"DEI: you are not minter"
		);
		_;
	}

	modifier onlyPools() {
		require(
			dei_pools[msg.sender] == true,
			"DEI: only dei pools can call this function"
		);
		_;
	}

	modifier onlyByTrusty() {
		require(
			hasRole(TRUSTY_ROLE, msg.sender),
			"DEI: you are not the owner"
		);
		_;
	}

	/* ========== CONSTRUCTOR ========== */

	constructor(
		string memory _name,
		string memory _symbol,
		address _creator_address,
		address _trusty_address
	){
		require(
			_creator_address != address(0),
			"DEI: zero address detected."
		);
		name = _name;
		symbol = _symbol;
		creator_address = _creator_address;
		_setupRole(DEFAULT_ADMIN_ROLE, _trusty_address);
		_mint(creator_address, genesis_supply);
		_setupRole(COLLATERAL_RATIO_PAUSER, creator_address);
		dei_step = 2500; // 6 decimals of precision, equal to 0.25%
		global_collateral_ratio = 800000; // Dei system starts off fully collateralized (6 decimals of precision)
		refresh_cooldown = 300; // Refresh cooldown period is set to 5 minutes (300 seconds) at genesis
		price_band = 5000; // Collateral ratio will not adjust if between $0.995 and $1.005 at genesis
		_setupRole(TRUSTY_ROLE, _trusty_address);

		// Upon genesis, if GR changes by more than 1% percent, enable change of collateral ratio
		GR_top_band = 1000;
		GR_bottom_band = 1000; 
	}

	/* ========== VIEWS ========== */

	// Verify X DEUS or X DEI = 1 USD or ...
	function verify_price(bytes32 sighash, bytes[] calldata sigs)
		public
		view
		returns (bool)
	{
		return Oracle(oracle).verify(sighash.toEthSignedMessageHash(), sigs);
	}

	// This is needed to avoid costly repeat calls to different getter functions
	// It is cheaper gas-wise to just dump everything and only use some of the info
	function dei_info(uint256[] memory collat_usd_price)
		public
		view
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		return (
			totalSupply(), // totalSupply()
			global_collateral_ratio, // global_collateral_ratio()
			globalCollateralValue(collat_usd_price) // globalCollateralValue
		);
	}

	// Iterate through all dei pools and calculate all value of collateral in all pools globally
	function globalCollateralValue(uint256[] memory collat_usd_price) public view returns (uint256) {
		uint256 total_collateral_value_d18 = 0;

		for (uint256 i = 0; i < dei_pools_array.length; i++) {
			// Exclude null addresses
			if (dei_pools_array[i] != address(0)) {
				total_collateral_value_d18 = total_collateral_value_d18 + DEIPool(dei_pools_array[i]).collatDollarBalance(collat_usd_price[i]);
			}
		}
		return total_collateral_value_d18;
	}

	function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

	/* ========== PUBLIC FUNCTIONS ========== */

	// There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
	uint256 public last_call_time; // Last time the refreshCollateralRatio function was called

	// Note: New function to refresh collateral ratio
	function refreshCollateralRatio(uint deus_price, uint dei_price, uint256 expire_block, bytes[] calldata sigs) external {
		require(collateral_ratio_paused == false, "DEI::Collateral Ratio has been paused");
		uint256 time_elapsed = (block.timestamp) - last_call_time;
		require(time_elapsed >= refresh_cooldown, "DEI::Internal cooldown not passed");
		uint256 deus_reserves = ReserveTracker(reserve_tracker_address).getDEUSReserves();

		bytes32 sighash = keccak256(abi.encodePacked(
										deus_address,
										deus_price,
										address(this),
										dei_price,
										expire_block,
                                    	getChainID()
                                    ));

		verify_price(sighash, sigs);

		uint256 deus_liquidity = deus_reserves * deus_price; // Has 6 decimals of precision

		uint256 dei_supply = totalSupply();

		uint256 new_growth_ratio = deus_liquidity / dei_supply; // (E18 + E6) / E18

		if(FIP_6){
			require(dei_price > DEI_top_band || dei_price < DEI_bottom_band, "DEI::Use refreshCollateralRatio when DEI is outside of peg");
		}

		// First, check if the price is out of the band
		if(dei_price > DEI_top_band){
			global_collateral_ratio = global_collateral_ratio - dei_step;
		} else if (dei_price < DEI_bottom_band){
			global_collateral_ratio = global_collateral_ratio + dei_step;

		// Else, check if the growth ratio has increased or decreased since last update
		} else if(use_growth_ratio){
			if(new_growth_ratio > growth_ratio * (1e6 + GR_top_band) / 1e6){
				global_collateral_ratio = global_collateral_ratio - dei_step;
			} else if (new_growth_ratio < growth_ratio * (1e6 - GR_bottom_band) / 1e6){
				global_collateral_ratio = global_collateral_ratio + dei_step;
			}
		}

		growth_ratio = new_growth_ratio;
		last_call_time = block.timestamp;

		// No need for checking CR under 0 as the last_collateral_ratio.sub(dei_step) will throw 
		// an error above in that case
		if(global_collateral_ratio > 1e6){
			global_collateral_ratio = 1e6;
		}

		emit CollateralRatioRefreshed(global_collateral_ratio);

	}

	function useGrowthRatio(bool _use_growth_ratio) external onlyByTrusty {
		use_growth_ratio = _use_growth_ratio;

		emit UseGrowthRatioSet(_use_growth_ratio);
	}

	function setGrowthRatioBands(uint256 _GR_top_band, uint256 _GR_bottom_band) external onlyByTrusty {
		GR_top_band = _GR_top_band;
		GR_bottom_band = _GR_bottom_band;
		emit GrowthRatioBandSet( _GR_top_band, _GR_bottom_band);
	}

	function setPriceBands(uint256 _top_band, uint256 _bottom_band) external onlyByTrusty {
		DEI_top_band = _top_band;
		DEI_bottom_band = _bottom_band;

		emit PriceBandSet(_top_band, _bottom_band);
	}

	function activateFIP6(bool _activate) external onlyByTrusty {
		FIP_6 = _activate;

		emit FIP_6Set(_activate);
	}

	// Used by pools when user redeems
	function pool_burn_from(address b_address, uint256 b_amount)
		public
		onlyPools
	{
		super._burnFrom(b_address, b_amount);
		emit DEIBurned(b_address, msg.sender, b_amount);
	}

	// This function is what other dei pools will call to mint new DEI
	function pool_mint(address m_address, uint256 m_amount) public onlyPoolsOrMinters {
		super._mint(m_address, m_amount);
		emit DEIMinted(msg.sender, m_address, m_amount);
	}

	// Adds collateral addresses supported, such as tether and busd, must be ERC20
	function addPool(address pool_address)
		public
		onlyByTrusty
	{
		require(pool_address != address(0), "DEI::addPool: Zero address detected");
		require(dei_pools[pool_address] == false, "DEI::addPool: Address already exists");

		dei_pools[pool_address] = true;
		dei_pools_array.push(pool_address);

		emit PoolAdded(pool_address);
	}

	// Remove a pool
	function removePool(address pool_address)
		public
		onlyByTrusty
	{
		require(pool_address != address(0), "DEI::removePool: Zero address detected");

		require(dei_pools[pool_address] == true, "DEI::removePool: Address nonexistant");

		// Delete from the mapping
		delete dei_pools[pool_address];

		// 'Delete' from the array by setting the address to 0x0
		for (uint256 i = 0; i < dei_pools_array.length; i++) {
			if (dei_pools_array[i] == pool_address) {
				dei_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
				break;
			}
		}

		emit PoolRemoved(pool_address);
	}
	
	function setOracle(address _oracle)
		public
		onlyByTrusty
	{
		oracle = _oracle;

		emit OracleSet(_oracle);
	}

	function setDEIStep(uint256 _new_step)
		public
		onlyByTrusty
	{
		dei_step = _new_step;

		emit DEIStepSet(_new_step);
	}

	function setReserveTracker(address _reserve_tracker_address)
		external
		onlyByTrusty
	{		
		reserve_tracker_address = _reserve_tracker_address;

		emit ReserveTrackerSet(_reserve_tracker_address);
	}

	function setRefreshCooldown(uint256 _new_cooldown)
		public
		onlyByTrusty
	{
		refresh_cooldown = _new_cooldown;

		emit RefreshCooldownSet(_new_cooldown);
	}

	function setDEUSAddress(address _deus_address)
		public
		onlyByTrusty
	{
		require(_deus_address != address(0), "DEI::setDEUSAddress: Zero address detected");

		deus_address = _deus_address;

		emit DEUSAddressSet(_deus_address);
	}

	function toggleCollateralRatio()
		public
		onlyCollateralRatioPauser 
	{
		collateral_ratio_paused = !collateral_ratio_paused;

		emit CollateralRatioToggled(collateral_ratio_paused);
	}

	/* ========== EVENTS ========== */

	// Track DEI burned
	event DEIBurned(address indexed from, address indexed to, uint256 amount);
	// Track DEI minted
	event DEIMinted(address indexed from, address indexed to, uint256 amount);
	event CollateralRatioRefreshed(uint256 global_collateral_ratio);
	event PoolAdded(address pool_address);
	event PoolRemoved(address pool_address);
	event DEIStepSet(uint256 new_step);
	event RefreshCooldownSet(uint256 new_cooldown);
	event DEUSAddressSet(address deus_address);
	event PriceBandSet(uint256 top_band, uint256 bottom_band);
	event CollateralRatioToggled(bool collateral_ratio_paused);
	event OracleSet(address oracle);
	event ReserveTrackerSet(address reserve_tracker_address);
	event UseGrowthRatioSet( bool use_growth_ratio);
	event FIP_6Set(bool activate);
	event GrowthRatioBandSet(uint256 GR_top_band, uint256 GR_bottom_band);
}

//Dar panah khoda