// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./PEGS.sol";
import "./Pusd.sol";
import "./ERC20.sol";
// import './TransferHelper.sol';
import "./UniswapPairOracle.sol";
import "./AccessControl.sol";
// import "./StringHelpers.sol";
import "./PusdPoolLibrary.sol";

contract PusdPool is AccessControl {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ERC20 private collateral_token;
    address private collateral_address;
    address private owner_address;
    // address private oracle_address;
    address private pusd_contract_address;
    address private pegs_contract_address;
    address private timelock_address; // Timelock address for the governance contract
    PUSDShares private PEGS;
    PUSDStablecoin private PUSD;
    // UniswapPairOracle private oracle;
    UniswapPairOracle private collatEthOracle;
    address private collat_eth_oracle_address;
    address private weth_address;
    address private bonus_address;

    uint256 private minting_fee;
    uint256 private redemption_fee;

    mapping (address => uint256) public redeemPEGSBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolPEGS;
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

    // Bonus rate on PEGS minted during recollateralizePUSD(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonus_rate = 7500;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;

    // AccessControl Roles
    // bytes32 private constant MINT_PAUSER = keccak256("MINT_PAUSER");
    // bytes32 private constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
    // bytes32 private constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
    // bytes32 private constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    // bytes32 private constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");
    
    // AccessControl state variables
    bool public mintPaused = true;
    bool public redeemPaused = false;
    bool public recollateralizePaused = true;
    bool public buyBackPaused = true;
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
        address _pusd_contract_address,
        address _pegs_contract_address,
        address _collateral_address,
        address _creator_address,
        address _timelock_address,
        uint256 _pool_ceiling
    ) public {
        PUSD = PUSDStablecoin(_pusd_contract_address);
        PEGS = PUSDShares(_pegs_contract_address);
        pusd_contract_address = _pusd_contract_address;
        pegs_contract_address = _pegs_contract_address;
        collateral_address = _collateral_address;
        timelock_address = _timelock_address;
        owner_address = _creator_address;
        collateral_token = ERC20(_collateral_address);
        pool_ceiling = _pool_ceiling;
        missing_decimals = uint(18).sub(collateral_token.decimals());

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // grantRole(MINT_PAUSER, timelock_address);
        // grantRole(REDEEM_PAUSER, timelock_address);
        // grantRole(RECOLLATERALIZE_PAUSER, timelock_address);
        // grantRole(BUYBACK_PAUSER, timelock_address);
        // grantRole(COLLATERAL_PRICE_PAUSER, timelock_address);
    }

    /* ========== VIEWS ========== */

    // Returns dollar value of collateral held in this Pusd pool
    function collatDollarBalance() public view returns (uint256) {
        uint256 eth_usd_price = PUSD.eth_usd_price();
        uint256 eth_collat_price = collatEthOracle.consult(weth_address, (PRICE_PRECISION *(10 ** missing_decimals)));

        uint256 collat_usd_price = eth_usd_price.mul(PRICE_PRECISION).div(eth_collat_price);
        return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(collat_usd_price).div(PRICE_PRECISION); //.mul(getCollateralPrice()).div(1e6);    
    }

    // Returns the value of excess collateral held in this Pusd pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        uint256 total_supply = PUSD.totalSupply();
        uint256 global_collateral_ratio = PUSD.global_collateral_ratio();
        uint256 global_collat_value = PUSD.globalCollateralValue();

        if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION) global_collateral_ratio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 PUSD with $1 of collateral at current collat ratio
        if (global_collat_value > required_collat_dollar_value_d18) return global_collat_value.sub(required_collat_dollar_value_d18);
        else return 0;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view returns (uint256) {
        if(collateralPricePaused == true){
            return pausedPrice;
        } else {
            uint256 eth_usd_price = PUSD.eth_usd_price();
            return eth_usd_price.mul(PRICE_PRECISION).div(collatEthOracle.consult(weth_address, PRICE_PRECISION* (10 ** missing_decimals) ));
        }
    }

    function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external onlyByOwnerOrGovernance {
        collat_eth_oracle_address = _collateral_weth_oracle_address;
        collatEthOracle = UniswapPairOracle(_collateral_weth_oracle_address);
        weth_address = _weth_address;
    }

    function setBonusAddress(address _bonus_address) external onlyByOwnerOrGovernance {
        bonus_address = _bonus_address;
    }

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1PUSD(uint256 collateral_amount, uint256 PUSD_out_min) external notMintPaused {
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 global_collateral_ratio = PUSD.global_collateral_ratio();

        require(global_collateral_ratio >= COLLATERAL_RATIO_MAX, "Collateral ratio must be >= 1");
        require((collateral_token.balanceOf(address(this))).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "[Pool's Closed]: Ceiling reached");
        
        (uint256 pusd_amount_d18) = PusdPoolLibrary.calcMint1t1PUSD(
            getCollateralPrice(),
            0,
            collateral_amount_d18
        ); //1 PUSD for each $1 worth of collateral

        require(PUSD_out_min <= pusd_amount_d18, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        uint256 total_feeAmount = pusd_amount_d18.mul(minting_fee).div(1e6);
        PUSD.pool_mint(bonus_address, total_feeAmount.mul(70).div(100));
        PUSD.pool_mint(msg.sender, pusd_amount_d18.sub(total_feeAmount));
    }

    // 0% collateral-backed
    // function mintAlgorithmicPUSD(uint256 pegs_amount_d18, uint256 PUSD_out_min) external notMintPaused {
    //     uint256 pegs_price = PUSD.pegs_price();
    //     uint256 global_collateral_ratio = PUSD.global_collateral_ratio();
    //     require(global_collateral_ratio == 0, "Collateral ratio must be 0");
        
    //     (uint256 pusd_amount_d18) = PusdPoolLibrary.calcMintAlgorithmicPUSD(
    //         minting_fee, 
    //         pegs_price, // X PEGS / 1 USD
    //         pegs_amount_d18
    //     );

    //     require(PUSD_out_min <= pusd_amount_d18, "Slippage limit reached");
    //     PEGS.pool_burn_from(msg.sender, pegs_amount_d18);
    //     PUSD.pool_mint(msg.sender, pusd_amount_d18);
    // }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalPUSD(uint256 collateral_amount, uint256 pegs_amount, uint256 PUSD_out_min) external notMintPaused {
        uint256 pusd_price = PUSD.pusd_price();
        uint256 pegs_price = PUSD.pegs_price();
        uint256 global_collateral_ratio = PUSD.global_collateral_ratio();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        require(collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "Pool ceiling reached, no more PUSD can be minted with this collateral");

        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        PusdPoolLibrary.MintFF_Params memory input_params = PusdPoolLibrary.MintFF_Params(
            0, 
            pegs_price,
            pusd_price,
            getCollateralPrice(),
            pegs_amount,
            collateral_amount_d18,
            (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)),
            pool_ceiling,
            global_collateral_ratio
        );

        (uint256 mint_amount, uint256 pegs_needed) = PusdPoolLibrary.calcMintFractionalPUSD(input_params);

        require(PUSD_out_min <= mint_amount, "Slippage limit reached");
        require(pegs_needed <= pegs_amount, "Not enough PEGS inputted");
        PEGS.pool_burn_from(msg.sender, pegs_needed);
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        
        uint256 total_feeAmount = mint_amount.mul(minting_fee).div(1e6);
        PUSD.pool_mint(bonus_address, total_feeAmount.mul(70).div(100));
        PUSD.pool_mint(msg.sender, mint_amount.sub(total_feeAmount));
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1PUSD(uint256 PUSD_amount, uint256 COLLATERAL_out_min) external notRedeemPaused {
        uint256 global_collateral_ratio = PUSD.global_collateral_ratio();
        require(global_collateral_ratio == COLLATERAL_RATIO_MAX, "Collateral ratio must be == 1");

        // // Need to adjust for decimals of collateral
        uint256 PUSD_amount_precision = PUSD_amount.div(10 ** missing_decimals);
        (uint256 collateral_needed) = PusdPoolLibrary.calcRedeem1t1PUSD(
            getCollateralPrice(),
            PUSD_amount_precision,
            0
        );

        require(collateral_needed <= collateral_token.balanceOf(address(this)), "Not enough collateral in pool");

    
        uint256 total_feeAmount = collateral_needed.mul(redemption_fee).div(1e6);
        
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed.sub(total_feeAmount));
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed.sub(total_feeAmount));
        lastRedeemed[msg.sender] = block.number;

        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");
        
       
        // Move all external functions to the end
        uint256 transfer_amount = PUSD_amount.mul(redemption_fee).div(1e6).mul(70).div(100);
        PUSD.transferFrom(msg.sender, bonus_address, transfer_amount);
        PUSD.pool_burn_from(msg.sender, PUSD_amount.sub(transfer_amount));
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem PUSD for collateral and PEGS. > 0% and < 100% collateral-backed
    function redeemFractionalPUSD(uint256 PUSD_amount, uint256 PEGS_out_min, uint256 COLLATERAL_out_min) external notRedeemPaused {
        uint256 global_collateral_ratio = PUSD.global_collateral_ratio();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");

        uint256 PUSD_amount_post_fee = PUSD_amount.sub((PUSD_amount.mul(0)).div(PRICE_PRECISION));
        uint256 pegs_amount = PUSD_amount_post_fee.sub(PUSD_amount_post_fee.mul(global_collateral_ratio).div(PRICE_PRECISION)).mul(PRICE_PRECISION).div(PUSD.pegs_price());

        uint256 collateral_amount = PUSD_amount_post_fee.div(10 ** missing_decimals).mul(global_collateral_ratio).div(PRICE_PRECISION).mul(PRICE_PRECISION).div(getCollateralPrice());
        
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount.sub(collateral_amount.mul(redemption_fee).div(1e6)));
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount.sub(collateral_amount.mul(redemption_fee).div(1e6)));

        redeemPEGSBalances[msg.sender] = redeemPEGSBalances[msg.sender].add(pegs_amount.sub(pegs_amount.mul(redemption_fee).div(1e6)));
        unclaimedPoolPEGS = unclaimedPoolPEGS.add(pegs_amount.sub(pegs_amount.mul(redemption_fee).div(1e6)));

        lastRedeemed[msg.sender] = block.number;

        require(collateral_amount <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount && PEGS_out_min <= pegs_amount, "Slippage limit reached");
        
        // Move all external functions to the end
        uint256 transfer_amount = PUSD_amount.mul(redemption_fee).div(1e6).mul(70).div(100);
        PUSD.transferFrom(msg.sender, bonus_address, transfer_amount);
        PUSD.pool_burn_from(msg.sender, PUSD_amount.sub(transfer_amount));
        PEGS.pool_mint(address(this), pegs_amount.sub(pegs_amount.mul(redemption_fee).div(1e6)));
    }

    // Redeem PUSD for PEGS. 0% collateral-backed
    // function redeemAlgorithmicPUSD(uint256 PUSD_amount, uint256 PEGS_out_min) external notRedeemPaused {
    //     uint256 pegs_price = PUSD.pegs_price();
    //     uint256 global_collateral_ratio = PUSD.global_collateral_ratio();

    //     require(global_collateral_ratio == 0, "Collateral ratio must be 0"); 
    //     uint256 pegs_dollar_value_d18 = PUSD_amount;
    //     pegs_dollar_value_d18 = pegs_dollar_value_d18.sub((pegs_dollar_value_d18.mul(redemption_fee)).div(PRICE_PRECISION)); //apply redemption fee

    //     uint256 pegs_amount = pegs_dollar_value_d18.mul(PRICE_PRECISION).div(pegs_price);
        
    //     redeemPEGSBalances[msg.sender] = redeemPEGSBalances[msg.sender].add(pegs_amount);
    //     unclaimedPoolPEGS = unclaimedPoolPEGS.add(pegs_amount);
        
    //     lastRedeemed[msg.sender] = block.number;
        
    //     require(PEGS_out_min <= pegs_amount, "Slippage limit reached");
    //     // Move all external functions to the end
    //     PUSD.pool_burn_from(msg.sender, PUSD_amount);
    //     PEGS.pool_mint(address(this), pegs_amount);
    // }

    // After a redemption happens, transfer the newly minted PEGS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out PUSD/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external {
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Must wait for redemption_delay blocks before collecting redemption");
        bool sendPEGS = false;
        bool sendCollateral = false;
        uint PEGSAmount;
        uint CollateralAmount;

        // Use Checks-Effects-Interactions pattern
        if(redeemPEGSBalances[msg.sender] > 0){
            PEGSAmount = redeemPEGSBalances[msg.sender];
            redeemPEGSBalances[msg.sender] = 0;
            unclaimedPoolPEGS = unclaimedPoolPEGS.sub(PEGSAmount);

            sendPEGS = true;
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);

            sendCollateral = true;
        }

        if(sendPEGS == true){
            PEGS.transfer(msg.sender, PEGSAmount);
        }
        if(sendCollateral == true){
            collateral_token.transfer(msg.sender, CollateralAmount);
        }
    }


    // When the protocol is recollateralizing, we need to give a discount of PEGS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get PEGS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of PEGS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra PEGS value from the bonus rate as an arb opportunity
    function recollateralizePUSD(uint256 collateral_amount, uint256 PEGS_out_min) external {
        require(recollateralizePaused == false, "Recollateralize is paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 pegs_price = PUSD.pegs_price();
        uint256 pusd_total_supply = PUSD.totalSupply();
        uint256 global_collateral_ratio = PUSD.global_collateral_ratio();
        uint256 global_collat_value = PUSD.globalCollateralValue();
        
        (uint256 collateral_units, uint256 amount_to_recollat) = PusdPoolLibrary.calcRecollateralizePUSDInner(
            collateral_amount_d18,
            getCollateralPrice(),
            global_collat_value,
            pusd_total_supply,
            global_collateral_ratio
        ); 

        uint256 collateral_units_precision = collateral_units.div(10 ** missing_decimals);

        uint256 pegs_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate)).div(pegs_price);

        require(PEGS_out_min <= pegs_paid_back, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_units_precision);
        PEGS.pool_mint(msg.sender, pegs_paid_back);
        
    }

    // Function can be called by an PEGS holder to have the protocol buy back PEGS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackPEGS(uint256 PEGS_amount, uint256 COLLATERAL_out_min) external {
        require(buyBackPaused == false, "Buyback is paused");
        uint256 pegs_price = PUSD.pegs_price();
        
        PusdPoolLibrary.BuybackPEGS_Params memory input_params = PusdPoolLibrary.BuybackPEGS_Params(
            availableExcessCollatDV(),
            pegs_price,
            getCollateralPrice(),
            PEGS_amount
        );

        (uint256 collateral_equivalent_d18) = PusdPoolLibrary.calcBuyBackPEGS(input_params);
        uint256 collateral_precision = collateral_equivalent_d18.div(10 ** missing_decimals);

        require(COLLATERAL_out_min <= collateral_precision, "Slippage limit reached");
        // Give the sender their desired collateral and burn the PEGS
        PEGS.pool_burn_from(msg.sender, PEGS_amount);
        collateral_token.transfer(msg.sender, collateral_precision);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external onlyByOwnerOrGovernance {
        // require(hasRole(MINT_PAUSER, msg.sender));
        mintPaused = !mintPaused;
    }
    
    function toggleRedeeming() external onlyByOwnerOrGovernance {
        // require(hasRole(REDEEM_PAUSER, msg.sender));
        redeemPaused = !redeemPaused;
    }

    function toggleRecollateralize() external onlyByOwnerOrGovernance {
        // require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;
    }
    
    function toggleBuyBack() external onlyByOwnerOrGovernance {
        // require(hasRole(BUYBACK_PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;
    }

    function toggleCollateralPrice() external onlyByOwnerOrGovernance {
        // require(hasRole(COLLATERAL_PRICE_PAUSER, msg.sender));
        // If pausing, set paused price; else if unpausing, clear pausedPrice
        if(collateralPricePaused == false){
            pausedPrice = getCollateralPrice();
        } else {
            pausedPrice = 0;
        }
        collateralPricePaused = !collateralPricePaused;
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, address _bonus_address) external onlyByOwnerOrGovernance {
        pool_ceiling = new_ceiling;
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay;
        minting_fee = PUSD.minting_fee();
        redemption_fee = PUSD.redemption_fee();
        bonus_address = _bonus_address;
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    /* ========== EVENTS ========== */

}
