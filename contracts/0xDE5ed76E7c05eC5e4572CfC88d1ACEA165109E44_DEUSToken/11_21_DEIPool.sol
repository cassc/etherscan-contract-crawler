// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;
// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ============================= DEIPool =============================
// ====================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Vahid Gh: https://github.com/vahid-dev
// SAYaghoubnejad: https://github.com/SAYaghoubnejad

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "../../Uniswap/TransferHelper.sol";
import "../../DEUS/IDEUS.sol";
import "../../DEI/IDEI.sol";
import "../../ERC20/ERC20.sol";
import "../../Governance/AccessControl.sol";
import "./DEIPoolLibrary.sol";

contract DEIPool is AccessControl {

    struct RecollateralizeDEI {
		uint256 collateral_amount;
		uint256 pool_collateral_price;
		uint256[] collateral_price;
		uint256 deus_current_price;
		uint256 expireBlock;
		bytes[] sigs;
    }

	/* ========== STATE VARIABLES ========== */

	ERC20 private collateral_token;
	address private collateral_address;

	address private dei_contract_address;
	address private deus_contract_address;

	uint256 public minting_fee;
	uint256 public redemption_fee;
	uint256 public buyback_fee;
	uint256 public recollat_fee;

	mapping(address => uint256) public redeemDEUSBalances;
	mapping(address => uint256) public redeemCollateralBalances;
	uint256 public unclaimedPoolCollateral;
	uint256 public unclaimedPoolDEUS;
	mapping(address => uint256) public lastRedeemed;

	// Constants for various precisions
	uint256 private constant PRICE_PRECISION = 1e6;
	uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
	uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

	// Number of decimals needed to get to 18
	uint256 private immutable missing_decimals;

	// Pool_ceiling is the total units of collateral that a pool contract can hold
	uint256 public pool_ceiling = 0;

	// Stores price of the collateral, if price is paused
	uint256 public pausedPrice = 0;

	// Bonus rate on DEUS minted during recollateralizeDEI(); 6 decimals of precision, set to 0.75% on genesis
	uint256 public bonus_rate = 7500;

	// Number of blocks to wait before being able to collectRedemption()
	uint256 public redemption_delay = 2;

	// Minting/Redeeming fees goes to daoWallet
	uint256 public daoShare = 0;

	DEIPoolLibrary poolLibrary;

	// AccessControl Roles
	bytes32 private constant MINT_PAUSER = keccak256("MINT_PAUSER");
	bytes32 private constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
	bytes32 private constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
	bytes32 private constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
	bytes32 public constant DAO_SHARE_COLLECTOR = keccak256("DAO_SHARE_COLLECTOR");
	bytes32 public constant PARAMETER_SETTER_ROLE = keccak256("PARAMETER_SETTER_ROLE");

	// AccessControl state variables
	bool public mintPaused = false;
	bool public redeemPaused = false;
	bool public recollateralizePaused = false;
	bool public buyBackPaused = false;

	/* ========== MODIFIERS ========== */

	modifier onlyByTrusty() {
		require(
			hasRole(TRUSTY_ROLE, msg.sender),
			"POOL::you are not trusty"
		);
		_;
	}

	modifier notRedeemPaused() {
		require(redeemPaused == false, "POOL::Redeeming is paused");
		_;
	}

	modifier notMintPaused() {
		require(mintPaused == false, "POOL::Minting is paused");
		_;
	}

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _dei_contract_address,
		address _deus_contract_address,
		address _collateral_address,
		address _trusty_address,
		address _admin_address,
		uint256 _pool_ceiling,
		address _library
	) {
		require(
			(_dei_contract_address != address(0)) &&
				(_deus_contract_address != address(0)) &&
				(_collateral_address != address(0)) &&
				(_trusty_address != address(0)) &&
				(_admin_address != address(0)) &&
				(_library != address(0)),
			"POOL::Zero address detected"
		);
		poolLibrary = DEIPoolLibrary(_library);
		dei_contract_address = _dei_contract_address;
		deus_contract_address = _deus_contract_address;
		collateral_address = _collateral_address;
		collateral_token = ERC20(_collateral_address);
		pool_ceiling = _pool_ceiling;
		missing_decimals = uint256(18) - collateral_token.decimals();

		_setupRole(DEFAULT_ADMIN_ROLE, _admin_address);
		_setupRole(MINT_PAUSER, _trusty_address);
		_setupRole(REDEEM_PAUSER, _trusty_address);
		_setupRole(RECOLLATERALIZE_PAUSER, _trusty_address);
		_setupRole(BUYBACK_PAUSER, _trusty_address);
        _setupRole(TRUSTY_ROLE, _trusty_address);
        _setupRole(TRUSTY_ROLE, _trusty_address);
        _setupRole(PARAMETER_SETTER_ROLE, _trusty_address);
	}

	/* ========== VIEWS ========== */

	// Returns dollar value of collateral held in this DEI pool
	function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
		return ((collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral) * (10**missing_decimals) * collat_usd_price) / (PRICE_PRECISION);
	}

	// Returns the value of excess collateral held in this DEI pool, compared to what is needed to maintain the global collateral ratio
	function availableExcessCollatDV(uint256[] memory collat_usd_price) public view returns (uint256) {
		uint256 total_supply = IDEIStablecoin(dei_contract_address).totalSupply();
		uint256 global_collateral_ratio = IDEIStablecoin(dei_contract_address).global_collateral_ratio();
		uint256 global_collat_value = IDEIStablecoin(dei_contract_address).globalCollateralValue(collat_usd_price);

		if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION)
			global_collateral_ratio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
		uint256 required_collat_dollar_value_d18 = (total_supply * global_collateral_ratio) / (COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 DEI with $1 of collateral at current collat ratio
		if (global_collat_value > required_collat_dollar_value_d18)
			return global_collat_value - required_collat_dollar_value_d18;
		else return 0;
	}

	function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

	/* ========== PUBLIC FUNCTIONS ========== */

	// We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency
	function mint1t1DEI(uint256 collateral_amount, uint256 collateral_price, uint256 expireBlock, bytes[] calldata sigs)
		external
		notMintPaused
		returns (uint256 dei_amount_d18)
	{

		require(
			IDEIStablecoin(dei_contract_address).global_collateral_ratio() >= COLLATERAL_RATIO_MAX,
			"Collateral ratio must be >= 1"
		);
		require(
			collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral +  collateral_amount <= pool_ceiling,
			"[Pool's Closed]: Ceiling reached"
		);

		require(expireBlock >= block.number, "POOL::mint1t1DEI: signature is expired");
        bytes32 sighash = keccak256(abi.encodePacked(collateral_address, collateral_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::mint1t1DEI: invalid signatures");

		uint256 collateral_amount_d18 = collateral_amount * (10**missing_decimals);
		dei_amount_d18 = poolLibrary.calcMint1t1DEI(
			collateral_price,
			collateral_amount_d18
		); //1 DEI for each $1 worth of collateral

		dei_amount_d18 = (dei_amount_d18 * (uint256(1e6) - minting_fee)) / 1e6; //remove precision at the end

		TransferHelper.safeTransferFrom(
			address(collateral_token),
			msg.sender,
			address(this),
			collateral_amount
		);

		daoShare += dei_amount_d18 *  minting_fee / 1e6;
		IDEIStablecoin(dei_contract_address).pool_mint(msg.sender, dei_amount_d18);
	}

	// 0% collateral-backed
	function mintAlgorithmicDEI(
		uint256 deus_amount_d18,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external notMintPaused returns (uint256 dei_amount_d18) {
		require(
			IDEIStablecoin(dei_contract_address).global_collateral_ratio() == 0,
			"Collateral ratio must be 0"
		);
		require(expireBlock >= block.number, "POOL::mintAlgorithmicDEI: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(deus_contract_address, deus_current_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::mintAlgorithmicDEI: invalid signatures");

		dei_amount_d18 = poolLibrary.calcMintAlgorithmicDEI(
			deus_current_price, // X DEUS / 1 USD
			deus_amount_d18
		);

		dei_amount_d18 = (dei_amount_d18 * (uint256(1e6) - (minting_fee))) / (1e6);
		daoShare += dei_amount_d18 *  minting_fee / 1e6;

		IDEUSToken(deus_contract_address).pool_burn_from(msg.sender, deus_amount_d18);
		IDEIStablecoin(dei_contract_address).pool_mint(msg.sender, dei_amount_d18);
	}

	// Will fail if fully collateralized or fully algorithmic
	// > 0% and < 100% collateral-backed
	function mintFractionalDEI(
		uint256 collateral_amount,
		uint256 deus_amount,
		uint256 collateral_price,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external notMintPaused returns (uint256 mint_amount) {
		uint256 global_collateral_ratio = IDEIStablecoin(dei_contract_address).global_collateral_ratio();
		require(
			global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0,
			"Collateral ratio needs to be between .000001 and .999999"
		);
		require(
			collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral + collateral_amount <= pool_ceiling,
			"Pool ceiling reached, no more DEI can be minted with this collateral"
		);

		require(expireBlock >= block.number, "POOL::mintFractionalDEI: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(collateral_address, collateral_price, deus_contract_address, deus_current_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::mintFractionalDEI: invalid signatures");

		DEIPoolLibrary.MintFD_Params memory input_params;

		// Blocking is just for solving stack depth problem
		{
			uint256 collateral_amount_d18 = collateral_amount * (10**missing_decimals);
			input_params = DEIPoolLibrary.MintFD_Params(
											deus_current_price,
											collateral_price,
											collateral_amount_d18,
											global_collateral_ratio
										);
		}						

		uint256 deus_needed;
		(mint_amount, deus_needed) = poolLibrary.calcMintFractionalDEI(input_params);
		require(deus_needed <= deus_amount, "Not enough DEUS inputted");
		
		mint_amount = (mint_amount * (uint256(1e6) - minting_fee)) / (1e6);

		IDEUSToken(deus_contract_address).pool_burn_from(msg.sender, deus_needed);
		TransferHelper.safeTransferFrom(
			address(collateral_token),
			msg.sender,
			address(this),
			collateral_amount
		);

		daoShare += mint_amount *  minting_fee / 1e6;
		IDEIStablecoin(dei_contract_address).pool_mint(msg.sender, mint_amount);
	}

	// Redeem collateral. 100% collateral-backed
	function redeem1t1DEI(uint256 DEI_amount, uint256 collateral_price, uint256 expireBlock, bytes[] calldata sigs)
		external
		notRedeemPaused
	{
		require(
			IDEIStablecoin(dei_contract_address).global_collateral_ratio() == COLLATERAL_RATIO_MAX,
			"Collateral ratio must be == 1"
		);

		require(expireBlock >= block.number, "POOL::mintAlgorithmicDEI: signature is expired.");
        bytes32 sighash = keccak256(abi.encodePacked(collateral_address, collateral_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::redeem1t1DEI: invalid signatures");

		// Need to adjust for decimals of collateral
		uint256 DEI_amount_precision = DEI_amount / (10**missing_decimals);
		uint256 collateral_needed = poolLibrary.calcRedeem1t1DEI(
			collateral_price,
			DEI_amount_precision
		);

		collateral_needed = (collateral_needed * (uint256(1e6) - redemption_fee)) / (1e6);
		require(
			collateral_needed <= collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral,
			"Not enough collateral in pool"
		);

		redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender] + collateral_needed;
		unclaimedPoolCollateral = unclaimedPoolCollateral + collateral_needed;
		lastRedeemed[msg.sender] = block.number;

		daoShare += DEI_amount * redemption_fee / 1e6;
		// Move all external functions to the end
		IDEIStablecoin(dei_contract_address).pool_burn_from(msg.sender, DEI_amount);
	}

	// Will fail if fully collateralized or algorithmic
	// Redeem DEI for collateral and DEUS. > 0% and < 100% collateral-backed
	function redeemFractionalDEI(
		uint256 DEI_amount,
		uint256 collateral_price, 
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external notRedeemPaused {
		uint256 global_collateral_ratio = IDEIStablecoin(dei_contract_address).global_collateral_ratio();
		require(
			global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0,
			"POOL::redeemFractionalDEI: Collateral ratio needs to be between .000001 and .999999"
		);

		require(expireBlock >= block.number, "DEI::redeemFractionalDEI: signature is expired");
		bytes32 sighash = keccak256(abi.encodePacked(collateral_address, collateral_price, deus_contract_address, deus_current_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::redeemFractionalDEI: invalid signatures");

		// Blocking is just for solving stack depth problem
		uint256 deus_amount;
		uint256 collateral_amount;
		{
			uint256 col_price_usd = collateral_price;

			uint256 DEI_amount_post_fee = (DEI_amount * (uint256(1e6) - redemption_fee)) / (PRICE_PRECISION);

			uint256 deus_dollar_value_d18 = DEI_amount_post_fee - ((DEI_amount_post_fee * global_collateral_ratio) / (PRICE_PRECISION));
			deus_amount = deus_dollar_value_d18 * (PRICE_PRECISION) / (deus_current_price);

			// Need to adjust for decimals of collateral
			uint256 DEI_amount_precision = DEI_amount_post_fee / (10**missing_decimals);
			uint256 collateral_dollar_value = (DEI_amount_precision * global_collateral_ratio) / PRICE_PRECISION;
			collateral_amount = (collateral_dollar_value * PRICE_PRECISION) / (col_price_usd);
		}
		require(
			collateral_amount <= collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral,
			"Not enough collateral in pool"
		);

		redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender] + collateral_amount;
		unclaimedPoolCollateral = unclaimedPoolCollateral + collateral_amount;

		redeemDEUSBalances[msg.sender] = redeemDEUSBalances[msg.sender] + deus_amount;
		unclaimedPoolDEUS = unclaimedPoolDEUS + deus_amount;

		lastRedeemed[msg.sender] = block.number;

		daoShare += DEI_amount * redemption_fee / 1e6;
		// Move all external functions to the end
		IDEIStablecoin(dei_contract_address).pool_burn_from(msg.sender, DEI_amount);
		IDEUSToken(deus_contract_address).pool_mint(address(this), deus_amount);
	}

	// Redeem DEI for DEUS. 0% collateral-backed
	function redeemAlgorithmicDEI(
		uint256 DEI_amount,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external notRedeemPaused {
		require(IDEIStablecoin(dei_contract_address).global_collateral_ratio() == 0, "POOL::redeemAlgorithmicDEI: Collateral ratio must be 0");

		require(expireBlock >= block.number, "DEI::redeemAlgorithmicDEI: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(deus_contract_address, deus_current_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::redeemAlgorithmicDEI: invalid signatures");

		uint256 deus_dollar_value_d18 = DEI_amount;

		deus_dollar_value_d18 = (deus_dollar_value_d18 * (uint256(1e6) - redemption_fee)) / 1e6; //apply fees

		uint256 deus_amount = (deus_dollar_value_d18 * (PRICE_PRECISION)) / deus_current_price;

		redeemDEUSBalances[msg.sender] = redeemDEUSBalances[msg.sender] + deus_amount;
		unclaimedPoolDEUS = unclaimedPoolDEUS + deus_amount;

		lastRedeemed[msg.sender] = block.number;

		daoShare += DEI_amount * redemption_fee / 1e6;
		// Move all external functions to the end
		IDEIStablecoin(dei_contract_address).pool_burn_from(msg.sender, DEI_amount);
		IDEUSToken(deus_contract_address).pool_mint(address(this), deus_amount);
	}

	// After a redemption happens, transfer the newly minted DEUS and owed collateral from this pool
	// contract to the user. Redemption is split into two functions to prevent flash loans from being able
	// to take out DEI/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
	function collectRedemption() external {
		require(
			(lastRedeemed[msg.sender] + redemption_delay) <= block.number,
			"POOL::collectRedemption: Must wait for redemption_delay blocks before collecting redemption"
		);
		bool sendDEUS = false;
		bool sendCollateral = false;
		uint256 DEUSAmount = 0;
		uint256 CollateralAmount = 0;

		// Use Checks-Effects-Interactions pattern
		if (redeemDEUSBalances[msg.sender] > 0) {
			DEUSAmount = redeemDEUSBalances[msg.sender];
			redeemDEUSBalances[msg.sender] = 0;
			unclaimedPoolDEUS = unclaimedPoolDEUS - DEUSAmount;

			sendDEUS = true;
		}

		if (redeemCollateralBalances[msg.sender] > 0) {
			CollateralAmount = redeemCollateralBalances[msg.sender];
			redeemCollateralBalances[msg.sender] = 0;
			unclaimedPoolCollateral = unclaimedPoolCollateral - CollateralAmount;
			sendCollateral = true;
		}

		if (sendDEUS) {
			TransferHelper.safeTransfer(address(deus_contract_address), msg.sender, DEUSAmount);
		}
		if (sendCollateral) {
			TransferHelper.safeTransfer(
				address(collateral_token),
				msg.sender,
				CollateralAmount
			);
		}
	}

	// When the protocol is recollateralizing, we need to give a discount of DEUS to hit the new CR target
	// Thus, if the target collateral ratio is higher than the actual value of collateral, minters get DEUS for adding collateral
	// This function simply rewards anyone that sends collateral to a pool with the same amount of DEUS + the bonus rate
	// Anyone can call this function to recollateralize the protocol and take the extra DEUS value from the bonus rate as an arb opportunity
	function recollateralizeDEI(RecollateralizeDEI memory inputs) external {
		require(recollateralizePaused == false, "POOL::recollateralizeDEI: Recollateralize is paused");

		require(inputs.expireBlock >= block.number, "POOL::recollateralizeDEI: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(
                                        collateral_address, 
                                        inputs.collateral_price,
                                        deus_contract_address, 
                                        inputs.deus_current_price, 
                                        inputs.expireBlock,
										getChainID()
                                    ));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, inputs.sigs), "POOL::recollateralizeDEI: invalid signatures");

		uint256 collateral_amount_d18 = inputs.collateral_amount * (10**missing_decimals);

		uint256 dei_total_supply = IDEIStablecoin(dei_contract_address).totalSupply();
		uint256 global_collateral_ratio = IDEIStablecoin(dei_contract_address).global_collateral_ratio();
		uint256 global_collat_value = IDEIStablecoin(dei_contract_address).globalCollateralValue(inputs.collateral_price);

		(uint256 collateral_units, uint256 amount_to_recollat) = poolLibrary.calcRecollateralizeDEIInner(
																				collateral_amount_d18,
																				inputs.collateral_price[inputs.collateral_price.length - 1], // pool collateral price exist in last index
																				global_collat_value,
																				dei_total_supply,
																				global_collateral_ratio
																			);

		uint256 collateral_units_precision = collateral_units / (10**missing_decimals);

		uint256 deus_paid_back = (amount_to_recollat * (uint256(1e6) + bonus_rate - recollat_fee)) / inputs.deus_current_price;

		TransferHelper.safeTransferFrom(
			address(collateral_token),
			msg.sender,
			address(this),
			collateral_units_precision
		);
		IDEUSToken(deus_contract_address).pool_mint(msg.sender, deus_paid_back);
	}

	// Function can be called by an DEUS holder to have the protocol buy back DEUS with excess collateral value from a desired collateral pool
	// This can also happen if the collateral ratio > 1
	function buyBackDEUS(
		uint256 DEUS_amount,
		uint256[] memory collateral_price,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external {
		require(buyBackPaused == false, "POOL::buyBackDEUS: Buyback is paused");
		require(expireBlock >= block.number, "DEI::buyBackDEUS: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(
										collateral_address,
										collateral_price,
										deus_contract_address,
										deus_current_price,
										expireBlock,
										getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::buyBackDEUS: invalid signatures");

		DEIPoolLibrary.BuybackDEUS_Params memory input_params = DEIPoolLibrary.BuybackDEUS_Params(
													availableExcessCollatDV(collateral_price),
													deus_current_price,
													collateral_price[collateral_price.length - 1], // pool collateral price exist in last index
													DEUS_amount
												);

		uint256 collateral_equivalent_d18 = (poolLibrary.calcBuyBackDEUS(input_params) * (uint256(1e6) - buyback_fee)) / (1e6);
		uint256 collateral_precision = collateral_equivalent_d18 / (10**missing_decimals);

		// Give the sender their desired collateral and burn the DEUS
		IDEUSToken(deus_contract_address).pool_burn_from(msg.sender, DEUS_amount);
		TransferHelper.safeTransfer(
			address(collateral_token),
			msg.sender,
			collateral_precision
		);
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function collectDaoShare(uint256 amount, address to) external {
		require(hasRole(DAO_SHARE_COLLECTOR, msg.sender));
		require(amount <= daoShare, "amount<=daoShare");
		IDEIStablecoin(dei_contract_address).pool_mint(to, amount);
		daoShare -= amount;

		emit daoShareCollected(amount, to);
	}

	function emergencyWithdrawERC20(address token, uint amount, address to) external onlyByTrusty {
		IERC20(token).transfer(to, amount);
	}

	function toggleMinting() external {
		require(hasRole(MINT_PAUSER, msg.sender));
		mintPaused = !mintPaused;

		emit MintingToggled(mintPaused);
	}

	function toggleRedeeming() external {
		require(hasRole(REDEEM_PAUSER, msg.sender));
		redeemPaused = !redeemPaused;

		emit RedeemingToggled(redeemPaused);
	}

	function toggleRecollateralize() external {
		require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
		recollateralizePaused = !recollateralizePaused;

		emit RecollateralizeToggled(recollateralizePaused);
	}

	function toggleBuyBack() external {
		require(hasRole(BUYBACK_PAUSER, msg.sender));
		buyBackPaused = !buyBackPaused;

		emit BuybackToggled(buyBackPaused);
	}

	// Combined into one function due to 24KiB contract memory limit
	function setPoolParameters(
		uint256 new_ceiling,
		uint256 new_bonus_rate,
		uint256 new_redemption_delay,
		uint256 new_mint_fee,
		uint256 new_redeem_fee,
		uint256 new_buyback_fee,
		uint256 new_recollat_fee
	) external {
		require(hasRole(PARAMETER_SETTER_ROLE, msg.sender), "POOL: Caller is not PARAMETER_SETTER_ROLE");
		pool_ceiling = new_ceiling;
		bonus_rate = new_bonus_rate;
		redemption_delay = new_redemption_delay;
		minting_fee = new_mint_fee;
		redemption_fee = new_redeem_fee;
		buyback_fee = new_buyback_fee;
		recollat_fee = new_recollat_fee;

		emit PoolParametersSet(
			new_ceiling,
			new_bonus_rate,
			new_redemption_delay,
			new_mint_fee,
			new_redeem_fee,
			new_buyback_fee,
			new_recollat_fee
		);
	}

	/* ========== EVENTS ========== */

	event PoolParametersSet(
		uint256 new_ceiling,
		uint256 new_bonus_rate,
		uint256 new_redemption_delay,
		uint256 new_mint_fee,
		uint256 new_redeem_fee,
		uint256 new_buyback_fee,
		uint256 new_recollat_fee
	);
	event daoShareCollected(uint256 daoShare, address to);
	event MintingToggled(bool toggled);
	event RedeemingToggled(bool toggled);
	event RecollateralizeToggled(bool toggled);
	event BuybackToggled(bool toggled);
}

//Dar panah khoda