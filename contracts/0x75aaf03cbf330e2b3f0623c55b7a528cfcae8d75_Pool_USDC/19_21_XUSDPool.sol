// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../../Math/SafeMath.sol";
import "../../XUS/XUS.sol";
import "../../XUSD/XUSD.sol";
import "../../ERC20/ERC20.sol";
import "../../Oracle/UniswapPairOracle.sol";
import "./XUSDPoolLibrary.sol";

contract XUSDPool {
    using SafeMath for uint256;

    ERC20 private collateral_token;
    address private collateral_address;
    address private owner_address;
    address private xusd_contract_address;
    address private xus_contract_address;
    address private timelock_address; // Timelock address for the governance contract
    XUSDShares private XUS;
    XUSDStablecoin private XUSD;
    UniswapPairOracle private collatEthOracle;
    address private collat_eth_oracle_address;
    address private weth_address;

    mapping (address => uint256) public redeemXUSBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolXUS;
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

    // Bonus rate on XUS minted during recollateralizeXUSD(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonus_rate = 7500;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;
    
    // AccessControl state variables
    bool private mintPaused = false;
    bool private redeemPaused = false;
    bool private recollateralizePaused = false;
    bool private buyBackPaused = false;
    bool private collateralPricePaused = false;

    address feepool_address;

    ChainlinkETHUSDPriceConsumer private collat_usd_pricer;
    uint8 private collat_usd_pricer_decimals;
    address public collat_usd_consumer_address;
    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner_address, "unauthorized");
        _;
    }

    modifier notRedeemPaused() {
        require(redeemPaused == false, "redeem paused");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "mint paused");
        _;
    }

    modifier checkContract() {
        require(msg.sender == tx.origin, "contract not support");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor(
        address _xusd_contract_address,
        address _xus_contract_address,
        address _collateral_address,
        address _timelock_address,
        uint256 _pool_ceiling
    ) public {
        XUSD = XUSDStablecoin(_xusd_contract_address);
        XUS = XUSDShares(_xus_contract_address);
        xusd_contract_address = _xusd_contract_address;
        xus_contract_address = _xus_contract_address;
        collateral_address = _collateral_address;
        timelock_address = _timelock_address;
        owner_address = msg.sender;
        collateral_token = ERC20(_collateral_address);
        pool_ceiling = _pool_ceiling;
        missing_decimals = uint(18).sub(collateral_token.decimals());
    }

    function setCollatUSDOracle(address _collat_usd_consumer_address) public onlyByOwnerOrGovernance {
        collat_usd_consumer_address = _collat_usd_consumer_address;
        collat_usd_pricer = ChainlinkETHUSDPriceConsumer(collat_usd_consumer_address);
        collat_usd_pricer_decimals = collat_usd_pricer.getDecimals();
    }

    /* ========== VIEWS ========== */

    // Returns dollar value of collateral held in this XUSD pool
    function collatDollarBalance() public view returns (uint256) {
        // uint256 eth_usd_price = XUSD.eth_usd_price();
        // uint256 eth_collat_price = collatEthOracle.consult(weth_address, (PRICE_PRECISION * (10 ** missing_decimals)));

        // uint256 collat_usd_price = eth_usd_price.mul(PRICE_PRECISION).div(eth_collat_price);
        uint256 collat_usd_price = uint256(collat_usd_pricer.getLatestPrice()).mul(1e6).div(uint256(10) ** collat_usd_pricer_decimals);
        return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(collat_usd_price).div(PRICE_PRECISION); //.mul(getCollateralPrice()).div(1e6);    
    }

    // Returns the value of excess collateral held in this XUSD pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        ( , , uint256 total_supply, uint256 global_collateral_ratio, uint256 global_collat_value, , ,) = XUSD.xusd_info();
        if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION) global_collateral_ratio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 XUSD with $1 of collateral at current collat ratio
        if (global_collat_value > required_collat_dollar_value_d18) return global_collat_value.sub(required_collat_dollar_value_d18);
        else return 0;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view returns (uint256) {
        if(collateralPricePaused == true) {
            return pausedPrice;
        } else {
            // ( , , , , , , , uint256 eth_usd_price) = XUSD.xusd_info();
            // return eth_usd_price.mul(PRICE_PRECISION).div(collatEthOracle.consult(weth_address, PRICE_PRECISION * (10 ** missing_decimals)));
            return uint256(collat_usd_pricer.getLatestPrice()).mul(1e6).div(uint256(10) ** collat_usd_pricer_decimals); //collat_usd_price
        }
    }

    function setFeePool(address _feepool) external onlyByOwnerOrGovernance {
        feepool_address = _feepool;
    }

    function getMint1t1Out(uint256 collat_amount) public view returns (uint256, uint256) {
        uint256 collateral_amount_d18 = collat_amount * (10 ** missing_decimals);
        ( , , , uint256 global_collateral_ratio, , uint256 minting_fee, ,) = XUSD.xusd_info();
        require(global_collateral_ratio >= COLLATERAL_RATIO_MAX, "CR must >= 1");
        require((collateral_token.balanceOf(address(this))).sub(unclaimedPoolCollateral).add(collat_amount) <= pool_ceiling, "ceiling reached");
        (uint256 xusd_amount_d18, uint256 fee) = XUSDPoolLibrary.calcMint1t1XUSD(
            getCollateralPrice(),
            minting_fee,
            collateral_amount_d18
        );
        return (xusd_amount_d18, fee);
    }

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1XUSD(uint256 collateral_amount, uint256 XUSD_out_min) external notMintPaused {
        (uint256 xusd_amount_d18, uint256 fee) = getMint1t1Out(collateral_amount);

        require(XUSD_out_min <= xusd_amount_d18, "slippage");
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        XUSD.pool_mint(msg.sender, xusd_amount_d18);
        XUSD.pool_mint(feepool_address, fee);
    }

    function getMintAlgoOut(uint256 xus_amount) public view returns (uint256, uint256) {
        ( , uint256 xus_price, , uint256 global_collateral_ratio, , uint256 minting_fee, ,) = XUSD.xusd_info();
        require(global_collateral_ratio == 0, "CR != 0");

        (uint256 xusd_amount_d18, uint256 fee) = XUSDPoolLibrary.calcMintAlgorithmicXUSD(
            minting_fee, 
            xus_price, // X XUS / 1 USD
            xus_amount
        );
        return (xusd_amount_d18, fee);
    }

    // 0% collateral-backed
    function mintAlgorithmicXUSD(uint256 xus_amount_d18, uint256 XUSD_out_min) external notMintPaused {
        (uint256 xusd_amount_d18, uint256 fee) = getMintAlgoOut(xus_amount_d18);

        require(XUSD_out_min <= xusd_amount_d18, "slippage");
        XUS.pool_burn_from(msg.sender, xus_amount_d18);
        XUSD.pool_mint(msg.sender, xusd_amount_d18);
        XUSD.pool_mint(feepool_address, fee);
    }

    function getMintFracOut(uint256 collat_amount) public view returns (uint256, uint256, uint256) {
        (, uint256 xus_price, , uint256 global_collateral_ratio, , uint256 minting_fee, ,) = XUSD.xusd_info();
        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "CR not in range");
        require(collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral).add(collat_amount) <= pool_ceiling, "pool ceiling reached");
        
        uint256 collateral_amount_d18 = collat_amount * (10 ** missing_decimals);
        (uint256 mint_amount, uint256 xus_needed, uint256 fee) = XUSDPoolLibrary.calcMintFractionalXUSD(collateral_amount_d18, getCollateralPrice(), xus_price, global_collateral_ratio, minting_fee);
        return (mint_amount, xus_needed, fee);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalXUSD(uint256 collateral_amount, uint256 XUSD_out_min) external notMintPaused {
        (uint256 mint_amount, uint256 xus_needed, uint256 fee) = getMintFracOut(collateral_amount);

        require(XUSD_out_min <= mint_amount, "slippage");
        XUS.pool_burn_from(msg.sender, xus_needed);
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        XUSD.pool_mint(msg.sender, mint_amount);
        XUSD.pool_mint(feepool_address, fee);
    }

    function getRedeem1t1Out(uint256 xusd_amount) public view returns (uint256, uint256) {
        (, , , uint256 global_collateral_ratio, , , uint256 redemption_fee,) = XUSD.xusd_info();
        require(global_collateral_ratio == COLLATERAL_RATIO_MAX, "CR != 1");

        // Need to adjust for decimals of collateral
        uint256 XUSD_amount_precision = xusd_amount.div(10 ** missing_decimals);
        (uint256 collateral_needed, uint256 fee) = XUSDPoolLibrary.calcRedeem1t1XUSD(
            getCollateralPrice(),
            XUSD_amount_precision,
            redemption_fee
        );
        return (collateral_needed, fee);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1XUSD(uint256 XUSD_amount, uint256 COLLATERAL_out_min) external notRedeemPaused {
       
        (uint256 collateral_needed, uint256 fee) = getRedeem1t1Out(XUSD_amount);
        require(collateral_needed <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed);
        lastRedeemed[msg.sender] = block.number;

        require(COLLATERAL_out_min <= collateral_needed, "slippage");
        
        // Move all external functions to the end
        XUSD.pool_burn_from(msg.sender, XUSD_amount);
        XUSD.pool_mint(feepool_address, fee);
    }

    function getRedeemFracOut(uint256 XUSD_amount) public view returns (uint256, uint256, uint256) {
        (, uint256 xus_price, , uint256 global_collateral_ratio, , , uint256 redemption_fee,) = XUSD.xusd_info();
        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "CR not in range");
        uint256 col_price_usd = getCollateralPrice();

        uint256 fee = (XUSD_amount.mul(redemption_fee)).div(PRICE_PRECISION);
        uint256 XUSD_amount_post_fee = XUSD_amount.sub(fee);
        uint256 xus_dollar_value_d18 = XUSD_amount_post_fee.sub(XUSD_amount_post_fee.mul(global_collateral_ratio).div(PRICE_PRECISION));
        uint256 xus_amount = xus_dollar_value_d18.mul(PRICE_PRECISION).div(xus_price);

        // Need to adjust for decimals of collateral
        uint256 XUSD_amount_precision = XUSD_amount_post_fee.div(10 ** missing_decimals);
        uint256 collateral_dollar_value = XUSD_amount_precision.mul(global_collateral_ratio).div(PRICE_PRECISION);
        uint256 collateral_amount = collateral_dollar_value.mul(PRICE_PRECISION).div(col_price_usd);

        return (xus_amount, collateral_amount, fee);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem XUSD for collateral and XUS. > 0% and < 100% collateral-backed
    function redeemFractionalXUSD(uint256 XUSD_amount, uint256 XUS_out_min, uint256 COLLATERAL_out_min) external notRedeemPaused {
        (uint256 xus_amount, uint256 collateral_amount, uint256 fee) = getRedeemFracOut(XUSD_amount);

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount);

        redeemXUSBalances[msg.sender] = redeemXUSBalances[msg.sender].add(xus_amount);
        unclaimedPoolXUS = unclaimedPoolXUS.add(xus_amount);

        lastRedeemed[msg.sender] = block.number;

        require(collateral_amount <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "not enough collateral");
        require(COLLATERAL_out_min <= collateral_amount && XUS_out_min <= xus_amount, "slippage");
        
        // Move all external functions to the end
        XUSD.pool_burn_from(msg.sender, XUSD_amount);
        XUS.pool_mint(address(this), xus_amount);
        XUSD.pool_mint(feepool_address, fee);
    }

    function getRedeemAlgoOut(uint256 XUSD_amount) public view returns (uint256, uint256) {
        (, uint256 xus_price, , uint256 global_collateral_ratio, , , uint256 redemption_fee,) = XUSD.xusd_info();
        require(global_collateral_ratio == 0, "CR != 0"); 
        uint256 fee = XUSD_amount.mul(redemption_fee).div(1e6);
        uint256 xus_dollar_value_d18 = XUSD_amount.sub(fee);

        uint256 xus_amount = xus_dollar_value_d18.mul(PRICE_PRECISION).div(xus_price);
        return (xus_amount, fee);
    }

    // Redeem XUSD for XUS. 0% collateral-backed
    function redeemAlgorithmicXUSD(uint256 XUSD_amount, uint256 XUS_out_min) external notRedeemPaused {

        (uint256 xus_amount, uint256 fee) = getRedeemAlgoOut(XUSD_amount);
        
        redeemXUSBalances[msg.sender] = redeemXUSBalances[msg.sender].add(xus_amount);
        unclaimedPoolXUS = unclaimedPoolXUS.add(xus_amount);
        
        lastRedeemed[msg.sender] = block.number;
        
        require(XUS_out_min <= xus_amount, "slippage");
        // Move all external functions to the end
        XUSD.pool_burn_from(msg.sender, XUSD_amount);
        XUS.pool_mint(address(this), xus_amount);
        XUSD.pool_mint(feepool_address, fee);
    }

    // After a redemption happens, transfer the newly minted XUS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out XUSD/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external {
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "wait 1 block");
        bool sendXUS = false;
        bool sendCollateral = false;
        uint XUSAmount;
        uint CollateralAmount;

        // Use Checks-Effects-Interactions pattern
        if(redeemXUSBalances[msg.sender] > 0){
            XUSAmount = redeemXUSBalances[msg.sender];
            redeemXUSBalances[msg.sender] = 0;
            unclaimedPoolXUS = unclaimedPoolXUS.sub(XUSAmount);

            sendXUS = true;
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);

            sendCollateral = true;
        }

        if(sendXUS == true){
            XUS.transfer(msg.sender, XUSAmount);
        }
        if(sendCollateral == true){
            collateral_token.transfer(msg.sender, CollateralAmount);
        }
    }

    function getRecollatOut(uint256 collateral_amount) public view returns (uint256, uint256) {
        require(recollateralizePaused == false, "recollat paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        ( , uint256 xus_price, uint256 xusd_total_supply , uint256 global_collateral_ratio, uint256 global_collat_value, , , ) = XUSD.xusd_info();
        (uint256 collateral_units, uint256 amount_to_recollat) = XUSDPoolLibrary.calcRecollateralizeXUSDInner(
            collateral_amount_d18,
            getCollateralPrice(),
            global_collat_value,
            xusd_total_supply,
            global_collateral_ratio
        ); 

        uint256 xus_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate)).div(xus_price);
        uint256 collateral_units_precision = collateral_units.div(10 ** missing_decimals);
        return (collateral_units_precision, xus_paid_back);
    }

    // When the protocol is recollateralizing, we need to give a discount of XUS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get XUS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of XUS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra XUS value from the bonus rate as an arb opportunity
    function recollateralizeXUSD(uint256 collateral_amount, uint256 XUS_out_min) external { 

        (uint256 collateral_units_precision, uint256 xus_paid_back) = getRecollatOut(collateral_amount);

        require(XUS_out_min <= xus_paid_back, "slippage");
        collateral_token.transferFrom(msg.sender, address(this), collateral_units_precision);
        XUS.pool_mint(msg.sender, xus_paid_back);
    }

    function getBuybackOut(uint256 XUS_amount) public view returns (uint256) {
        require(buyBackPaused == false, "buyback paused");
        (, uint256 xus_price, , , , , ,) = XUSD.xusd_info();

        (uint256 collateral_equivalent_d18) = XUSDPoolLibrary.calcBuyBackXUS(XUS_amount, xus_price, availableExcessCollatDV(), getCollateralPrice());
        return collateral_equivalent_d18.div(10 ** missing_decimals);
    }

    // Function can be called by an XUS holder to have the protocol buy back XUS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackXUS(uint256 XUS_amount, uint256 COLLATERAL_out_min) external {
        uint256 collateral_precision = getBuybackOut(XUS_amount);

        require(COLLATERAL_out_min <= collateral_precision, "slippage");
        // Give the sender their desired collateral and burn the XUS
        XUS.pool_burn_from(msg.sender, XUS_amount);
        collateral_token.transfer(msg.sender, collateral_precision);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external onlyByOwnerOrGovernance {
        mintPaused = !mintPaused;
    }
    
    function toggleRedeeming() external onlyByOwnerOrGovernance {
        redeemPaused = !redeemPaused;
    }

    function toggleRecollateralize() external onlyByOwnerOrGovernance {
        recollateralizePaused = !recollateralizePaused;
    }
    
    function toggleBuyBack() external onlyByOwnerOrGovernance {
        buyBackPaused = !buyBackPaused;
    }

    function toggleCollateralPrice() external onlyByOwnerOrGovernance {
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
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }
}