// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./BLOC.sol";
import "./Lyfe.sol";
import "./ERC20.sol";
// import '../../Uniswap/TransferHelper.sol';
import "./UniswapPairOracle.sol";
import "./AccessControl.sol";
// import "../../Utils/StringHelpers.sol";
import "./LyfePoolLibrary.sol";

/*
   Same as LyfePool.sol, but has some gas optimizations
*/



contract LyfePool is AccessControl {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ERC20 private collateral_token;
    address private collateral_address;
    address private owner_address;
    // address private oracle_address;
    address private lyfe_contract_address;
    address private bloc_contract_address;
    address private timelock_address; // Timelock address for the governance contract
    LYFEShares private BLOC;
    LYFEStablecoin private LYFE;
    // UniswapPairOracle private oracle;
    UniswapPairOracle private collatEthOracle;
    address private collat_eth_oracle_address;
    address private weth_address;

    uint256 private minting_fee;
    uint256 private redemption_fee;

    mapping (address => uint256) public redeemBLOCBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolBLOC;
    mapping (address => uint256) public lastRedeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

    // Number of decimals needed to get to 18
    uint256 private missing_decimals;
    
    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public pool_ceiling = 0;

    // Stores price of the collateral, if price is paused
    uint256 public pausedPrice = 0;

    // Bonus rate on BLOC minted during recollateralizeLYFE(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonus_rate = 7500;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;

    // AccessControl Roles
    bytes32 private constant MINT_PAUSER = keccak256("MINT_PAUSER");
    bytes32 private constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
    bytes32 private constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
    bytes32 private constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    bytes32 private constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");
    
    // AccessControl state variables
    bool private mintPaused = false;
    bool private redeemPaused = false;
    bool private recollateralizePaused = false;
    bool private buyBackPaused = false;
    bool private collateralPricePaused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner_address, "You are not the owner or the governance timelock");
        _;
    }

    modifier notRedeemPaused() {
        require(redeemPaused == false, "Redeeming is paused");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "Minting is paused");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor(
        address _lyfe_contract_address,
        address _bloc_contract_address,
        address _collateral_address,
        address _creator_address,
        address _timelock_address,
        uint256 _pool_ceiling
    ) public {
        LYFE = LYFEStablecoin(_lyfe_contract_address);
        BLOC = LYFEShares(_bloc_contract_address);
        lyfe_contract_address = _lyfe_contract_address;
        bloc_contract_address = _bloc_contract_address;
        collateral_address = _collateral_address;
        timelock_address = _timelock_address;
        owner_address = _creator_address;
        collateral_token = ERC20(_collateral_address);
        pool_ceiling = _pool_ceiling;
        missing_decimals = uint(18).sub(collateral_token.decimals());

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(MINT_PAUSER, timelock_address);
        grantRole(REDEEM_PAUSER, timelock_address);
        grantRole(RECOLLATERALIZE_PAUSER, timelock_address);
        grantRole(BUYBACK_PAUSER, timelock_address);
        grantRole(COLLATERAL_PRICE_PAUSER, timelock_address);
    }

    /* ========== VIEWS ========== */

    // Returns dollar value of collateral held in this Lyfe pool
    function collatDollarBalance() public view returns (uint256) {
        uint256 eth_usd_price = LYFE.eth_usd_price();
        uint256 eth_collat_price = collatEthOracle.consult(weth_address, (PRICE_PRECISION * (10 ** missing_decimals)));

        uint256 collat_usd_price = eth_usd_price.mul(PRICE_PRECISION).div(eth_collat_price);
        return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(collat_usd_price).div(PRICE_PRECISION); //.mul(getCollateralPrice()).div(1e6);    
    }

    // Returns the value of excess collateral held in this Lyfe pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        uint256 total_supply = LYFE.totalSupply();
        uint256 global_collateral_ratio = LYFE.global_collateral_ratio();
        uint256 global_collat_value = LYFE.globalCollateralValue();

        if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION) global_collateral_ratio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 LYFE with $1 of collateral at current collat ratio
        if (global_collat_value > required_collat_dollar_value_d18) return global_collat_value.sub(required_collat_dollar_value_d18);
        else return 0;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view returns (uint256) {
        if(collateralPricePaused == true){
            return pausedPrice;
        } else {
            uint256 eth_usd_price = LYFE.eth_usd_price();
            return eth_usd_price.mul(PRICE_PRECISION).div(collatEthOracle.consult(weth_address, PRICE_PRECISION * (10 ** missing_decimals)));
        }
    }

    function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external onlyByOwnerOrGovernance {
        collat_eth_oracle_address = _collateral_weth_oracle_address;
        collatEthOracle = UniswapPairOracle(_collateral_weth_oracle_address);
        weth_address = _weth_address;
    }

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1LYFE(uint256 collateral_amount, uint256 LYFE_out_min) external notMintPaused {
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 global_collateral_ratio = LYFE.global_collateral_ratio();

        require(global_collateral_ratio >= COLLATERAL_RATIO_MAX, "Collateral ratio must be >= 1");
        require((collateral_token.balanceOf(address(this))).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "[Pool's Closed]: Ceiling reached");
        
        (uint256 lyfe_amount_d18) = LyfePoolLibrary.calcMint1t1LYFE(
            getCollateralPrice(),
            minting_fee,
            collateral_amount_d18
        ); //1 LYFE for each $1 worth of collateral

        require(LYFE_out_min <= lyfe_amount_d18, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        LYFE.pool_mint(msg.sender, lyfe_amount_d18);
    }

    // 0% collateral-backed
    function mintAlgorithmicLYFE(uint256 bloc_amount_d18, uint256 LYFE_out_min) external notMintPaused {
        uint256 bloc_price = LYFE.bloc_price();
        uint256 global_collateral_ratio = LYFE.global_collateral_ratio();
        require(global_collateral_ratio == 0, "Collateral ratio must be 0");
        
        (uint256 lyfe_amount_d18) = LyfePoolLibrary.calcMintAlgorithmicLYFE(
            minting_fee, 
            bloc_price, // X BLOC / 1 USD
            bloc_amount_d18
        );

        require(LYFE_out_min <= lyfe_amount_d18, "Slippage limit reached");
        BLOC.pool_burn_from(msg.sender, bloc_amount_d18);
        LYFE.pool_mint(msg.sender, lyfe_amount_d18);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalLYFE(uint256 collateral_amount, uint256 bloc_amount, uint256 LYFE_out_min) external notMintPaused {
        uint256 lyfe_price = LYFE.lyfe_price();
        uint256 bloc_price = LYFE.bloc_price();
        uint256 global_collateral_ratio = LYFE.global_collateral_ratio();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        require(collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "Pool ceiling reached, no more LYFE can be minted with this collateral");

        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        LyfePoolLibrary.MintFF_Params memory input_params = LyfePoolLibrary.MintFF_Params(
            minting_fee, 
            bloc_price,
            lyfe_price,
            getCollateralPrice(),
            bloc_amount,
            collateral_amount_d18,
            (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)),
            pool_ceiling,
            global_collateral_ratio
        );

        (uint256 mint_amount, uint256 bloc_needed) = LyfePoolLibrary.calcMintFractionalLYFE(input_params);

        require(LYFE_out_min <= mint_amount, "Slippage limit reached");
        require(bloc_needed <= bloc_amount, "Not enough BLOC inputted");
        BLOC.pool_burn_from(msg.sender, bloc_needed);
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        LYFE.pool_mint(msg.sender, mint_amount);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1LYFE(uint256 LYFE_amount, uint256 COLLATERAL_out_min) external notRedeemPaused {
        uint256 global_collateral_ratio = LYFE.global_collateral_ratio();
        require(global_collateral_ratio == COLLATERAL_RATIO_MAX, "Collateral ratio must be == 1");

        // Need to adjust for decimals of collateral
        uint256 LYFE_amount_precision = LYFE_amount.div(10 ** missing_decimals);
        (uint256 collateral_needed) = LyfePoolLibrary.calcRedeem1t1LYFE(
            getCollateralPrice(),
            LYFE_amount_precision,
            redemption_fee
        );

        require(collateral_needed <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed);
        lastRedeemed[msg.sender] = block.number;

        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");
        
        // Move all external functions to the end
        LYFE.pool_burn_from(msg.sender, LYFE_amount);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem LYFE for collateral and BLOC. > 0% and < 100% collateral-backed
    function redeemFractionalLYFE(uint256 LYFE_amount, uint256 BLOC_out_min, uint256 COLLATERAL_out_min) external notRedeemPaused {
        uint256 bloc_price = LYFE.bloc_price();
        uint256 global_collateral_ratio = LYFE.global_collateral_ratio();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        uint256 col_price_usd = getCollateralPrice();

        uint256 LYFE_amount_post_fee = LYFE_amount.sub((LYFE_amount.mul(redemption_fee)).div(PRICE_PRECISION));
        uint256 bloc_dollar_value_d18 = LYFE_amount_post_fee.sub(LYFE_amount_post_fee.mul(global_collateral_ratio).div(PRICE_PRECISION));
        uint256 bloc_amount = bloc_dollar_value_d18.mul(PRICE_PRECISION).div(bloc_price);

        // Need to adjust for decimals of collateral
        uint256 LYFE_amount_precision = LYFE_amount_post_fee.div(10 ** missing_decimals);
        uint256 collateral_dollar_value = LYFE_amount_precision.mul(global_collateral_ratio).div(PRICE_PRECISION);
        uint256 collateral_amount = collateral_dollar_value.mul(PRICE_PRECISION).div(col_price_usd);

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount);

        redeemBLOCBalances[msg.sender] = redeemBLOCBalances[msg.sender].add(bloc_amount);
        unclaimedPoolBLOC = unclaimedPoolBLOC.add(bloc_amount);

        lastRedeemed[msg.sender] = block.number;

        require(collateral_amount <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount, "Slippage limit reached [collateral]");
        require(BLOC_out_min <= bloc_amount, "Slippage limit reached [BLOC]");
        
        // Move all external functions to the end
        LYFE.pool_burn_from(msg.sender, LYFE_amount);
        BLOC.pool_mint(address(this), bloc_amount);
    }

    // Redeem LYFE for BLOC. 0% collateral-backed
    function redeemAlgorithmicLYFE(uint256 LYFE_amount, uint256 BLOC_out_min) external notRedeemPaused {
        uint256 bloc_price = LYFE.bloc_price();
        uint256 global_collateral_ratio = LYFE.global_collateral_ratio();

        require(global_collateral_ratio == 0, "Collateral ratio must be 0"); 
        uint256 bloc_dollar_value_d18 = LYFE_amount;
        bloc_dollar_value_d18 = bloc_dollar_value_d18.sub((bloc_dollar_value_d18.mul(redemption_fee)).div(PRICE_PRECISION)); //apply redemption fee

        uint256 bloc_amount = bloc_dollar_value_d18.mul(PRICE_PRECISION).div(bloc_price);
        
        redeemBLOCBalances[msg.sender] = redeemBLOCBalances[msg.sender].add(bloc_amount);
        unclaimedPoolBLOC = unclaimedPoolBLOC.add(bloc_amount);
        
        lastRedeemed[msg.sender] = block.number;
        
        require(BLOC_out_min <= bloc_amount, "Slippage limit reached");
        // Move all external functions to the end
        LYFE.pool_burn_from(msg.sender, LYFE_amount);
        BLOC.pool_mint(address(this), bloc_amount);
    }

    // After a redemption happens, transfer the newly minted BLOC and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out LYFE/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external {
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Must wait for redemption_delay blocks before collecting redemption");
        bool sendBLOC = false;
        bool sendCollateral = false;
        uint BLOCAmount;
        uint CollateralAmount;

        // Use Checks-Effects-Interactions pattern
        if(redeemBLOCBalances[msg.sender] > 0){
            BLOCAmount = redeemBLOCBalances[msg.sender];
            redeemBLOCBalances[msg.sender] = 0;
            unclaimedPoolBLOC = unclaimedPoolBLOC.sub(BLOCAmount);

            sendBLOC = true;
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);

            sendCollateral = true;
        }

        if(sendBLOC == true){
            BLOC.transfer(msg.sender, BLOCAmount);
        }
        if(sendCollateral == true){
            collateral_token.transfer(msg.sender, CollateralAmount);
        }
    }


    // When the protocol is recollateralizing, we need to give a discount of BLOC to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get BLOC for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of BLOC + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra BLOC value from the bonus rate as an arb opportunity
    function recollateralizeFRAX(uint256 collateral_amount, uint256 BLOC_out_min) external {
        require(recollateralizePaused == false, "Recollateralize is paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 bloc_price = LYFE.bloc_price();
        uint256 lyfe_total_supply = LYFE.totalSupply();
        uint256 global_collateral_ratio = LYFE.global_collateral_ratio();
        uint256 global_collat_value = LYFE.globalCollateralValue();
        
        (uint256 collateral_units, uint256 amount_to_recollat) = LyfePoolLibrary.calcRecollateralizeLYFEInner(
            collateral_amount_d18,
            getCollateralPrice(),
            global_collat_value,
            lyfe_total_supply,
            global_collateral_ratio
        ); 

        uint256 collateral_units_precision = collateral_units.div(10 ** missing_decimals);

        uint256 bloc_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate)).div(bloc_price);

        require(BLOC_out_min <= bloc_paid_back, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_units_precision);
        BLOC.pool_mint(msg.sender, bloc_paid_back);
        
    }

    // Function can be called by an BLOC holder to have the protocol buy back BLOC with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackBLOC(uint256 BLOC_amount, uint256 COLLATERAL_out_min) external {
        require(buyBackPaused == false, "Buyback is paused");
        uint256 bloc_price = LYFE.bloc_price();
        
        LyfePoolLibrary.BuybackBLOC_Params memory input_params = LyfePoolLibrary.BuybackBLOC_Params(
            availableExcessCollatDV(),
            bloc_price,
            getCollateralPrice(),
            BLOC_amount
        );

        (uint256 collateral_equivalent_d18) = LyfePoolLibrary.calcBuyBackBLOC(input_params);
        uint256 collateral_precision = collateral_equivalent_d18.div(10 ** missing_decimals);

        require(COLLATERAL_out_min <= collateral_precision, "Slippage limit reached");
        // Give the sender their desired collateral and burn the BLOC
        BLOC.pool_burn_from(msg.sender, BLOC_amount);
        collateral_token.transfer(msg.sender, collateral_precision);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external {
        require(hasRole(MINT_PAUSER, msg.sender));
        mintPaused = !mintPaused;
    }
    
    function toggleRedeeming() external {
        require(hasRole(REDEEM_PAUSER, msg.sender));
        redeemPaused = !redeemPaused;
    }

    function toggleRecollateralize() external {
        require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;
    }
    
    function toggleBuyBack() external {
        require(hasRole(BUYBACK_PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;
    }

    function toggleCollateralPrice() external {
        require(hasRole(COLLATERAL_PRICE_PAUSER, msg.sender));
        // If pausing, set paused price; else if unpausing, clear pausedPrice
        if(collateralPricePaused == false){
            pausedPrice = getCollateralPrice();
        } else {
            pausedPrice = 0;
        }
        collateralPricePaused = !collateralPricePaused;
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay) external onlyByOwnerOrGovernance {
        pool_ceiling = new_ceiling;
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay;
        minting_fee = LYFE.minting_fee();
        redemption_fee = LYFE.redemption_fee();
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    /* ========== EVENTS ========== */

}