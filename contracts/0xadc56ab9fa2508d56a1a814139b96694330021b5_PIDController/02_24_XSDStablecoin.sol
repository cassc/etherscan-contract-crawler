// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../ERC20/ERC20Custom.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Pools/CollateralPool.sol";
import "./Pools/Interfaces/IBankXWETHpool.sol";
import "./Pools/Interfaces/IXSDWETHpool.sol";
import "../Oracle/ChainlinkETHUSDPriceConsumer.sol";
import "../Oracle/ChainlinkXAGUSDPriceConsumer.sol";

contract XSDStablecoin is ERC20Custom {

    /* ========== STATE VARIABLES ========== */
    enum PriceChoice { XSD, BankX }
    ChainlinkETHUSDPriceConsumer private eth_usd_pricer;
    ChainlinkXAGUSDPriceConsumer private xag_usd_pricer;
    uint8 private eth_usd_pricer_decimals;
    uint8 private xag_usd_pricer_decimals;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public pid_address;
    address public treasury; 
    address public collateral_pool_address;
    address public router;
    address public eth_usd_oracle_address;
    address public xag_usd_oracle_address;
    address public smartcontract_owner;
    uint256 public interest_rate;
    IBankXWETHpool private bankxEthPool;
    IXSDWETHpool private xsdEthPool;
    uint256 public cap_rate;
    uint256 public genesis_supply; 

    // The addresses in this array are added by the oracle and these contracts are able to mint xsd
    address[] public xsd_pools_array;

    // Mapping is also used for faster verification
    mapping(address => bool) public xsd_pools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public xsd_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of XSD at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

    bool public collateral_ratio_paused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(xsd_pools[msg.sender] == true, "Only xsd pools can call this function");
        _;//check happens before the function is executed 
    } 

    modifier onlyByOwner(){
        require(msg.sender == smartcontract_owner, "You are not the owner");
        _;
    }
    
    modifier onlyByOwnerPID() {
        require(msg.sender == smartcontract_owner || msg.sender == pid_address, "You are not the owner or the pid controller");
        _;
    }

    modifier onlyByOwnerOrPool() {
        require(
            msg.sender == smartcontract_owner  
            || xsd_pools[msg.sender] == true, 
            "You are not the owner or a pool");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _pool_amount,
        uint256 _genesis_supply,
        address _smartcontract_owner,
        address _treasury,
        uint256 _cap_rate
    ) {
        require((_smartcontract_owner != address(0))
                && (_treasury != address(0)), "Zero address detected"); 
        name = _name;
        symbol = _symbol;
        genesis_supply = _genesis_supply + _pool_amount;
        treasury = _treasury;
        _mint(_smartcontract_owner, _pool_amount);
        _mint(treasury, _genesis_supply);
        smartcontract_owner = _smartcontract_owner;
        xsd_step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // XSD system starts off fully collateralized (6 decimals of precision)
        interest_rate = 52800; //interest rate starts off at 5%
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 800000; // Change price target to 1 gram of silver
        price_band = 5000; // Collateral ratio will not adjust if 0.005 off target at genesis
        cap_rate = _cap_rate;// Maximum mint amount
    }
    /* ========== VIEWS ========== */

    function pool_price(PriceChoice choice) internal view returns (uint256) {
        // Get the ETH / USD price first, and cut it down to 1e6 precision
        uint256 _eth_usd_price = (uint256(eth_usd_pricer.getLatestPrice())*PRICE_PRECISION)/(uint256(10) ** eth_usd_pricer_decimals);
        uint256 price_vs_eth = 0;
        uint256 reserve0;
        uint256 reserve1;

        if (choice == PriceChoice.XSD) {
            (reserve0, reserve1, ) = xsdEthPool.getReserves();
            if(reserve0 == 0 || reserve1 == 0){
                return 1;
            }
            price_vs_eth = reserve0/(reserve1); // How much XSD if you put in 1 WETH
        }
        else if (choice == PriceChoice.BankX) {
            (reserve0, reserve1, ) = bankxEthPool.getReserves();
            if(reserve0 == 0 || reserve1 == 0){
                return 1;
            }
            price_vs_eth = reserve0/(reserve1);  // How much BankX if you put in 1 WETH
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (XSD) or 1 (BankX)");

        // Will be in 1e6 format
        return _eth_usd_price/price_vs_eth;
    }

    
    //XSD price
    function xsd_price() public view returns (uint256) {
        return pool_price(PriceChoice.XSD);
    }

    function bankx_price()  public view returns (uint256) {
        return pool_price(PriceChoice.BankX);
    }

    function eth_usd_price() public view returns (uint256) {
        return (uint256(eth_usd_pricer.getLatestPrice())*PRICE_PRECISION)/(uint256(10) ** eth_usd_pricer_decimals);
    }
    //silver price
    function xag_usd_price() public view returns (uint256) {
        return (uint256(xag_usd_pricer.getLatestPrice())*PRICE_PRECISION)/(uint256(10) ** xag_usd_pricer_decimals);
    }

    
    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function xsd_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            pool_price(PriceChoice.XSD), // xsd_price()
            pool_price(PriceChoice.BankX), // bankx_price()
            totalSupply(), // totalSupply()
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            (uint256(eth_usd_pricer.getLatestPrice())*PRICE_PRECISION)/(uint256(10) ** eth_usd_pricer_decimals) //eth_usd_price
        );
    }

    // Iterate through all xsd pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 collateral_amount = 0;
        collateral_amount = CollateralPool(payable(collateral_pool_address)).collatDollarBalance();
        return collateral_amount;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    // To simulate global collateral ratio set xsd price higher than silver price and hit refresh collateral ratio.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        uint256 xsd_price_cur = xsd_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setXSDStep()) 
        
        if (xsd_price_cur > (price_target+price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= xsd_step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio-xsd_step;
            }
        } else if (xsd_price_cur < price_target-price_band) { //increase collateral ratio
            if(global_collateral_ratio+xsd_step >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio+xsd_step;
            }
        }
        else
        last_call_time = block.timestamp; // Set the time of the last expansion
        uint256 _interest_rate = (1000000-global_collateral_ratio)/(2);
        //update interest rate
        if(_interest_rate>52800){
            interest_rate = _interest_rate;
        }
        else{
            interest_rate = 52800;
        }

        emit CollateralRatioRefreshed(global_collateral_ratio);
    }

    function creatorMint(uint256 amount) public onlyByOwner{
        require(genesis_supply+amount<cap_rate,"cap limit reached");
        super._mint(treasury,amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        super._burnFrom(b_address, b_amount);
        emit XSDBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other xsd pools will call to mint new XSD 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        super._mint(m_address, m_amount);
        emit XSDMinted(msg.sender, m_address, m_amount);
    }
    

    // Adds collateral addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwner {
        require(pool_address != address(0), "Zero address detected");

        require(xsd_pools[pool_address] == false, "Address already exists");
        xsd_pools[pool_address] = true; 
        xsd_pools_array.push(pool_address);

        emit PoolAdded(pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwner {
        require(pool_address != address(0), "Zero address detected");

        require(xsd_pools[pool_address] == true, "Address nonexistant");
        
        // Delete from the mapping
        delete xsd_pools[pool_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < xsd_pools_array.length; i++){ 
            if (xsd_pools_array[i] == pool_address) {
                xsd_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit PoolRemoved(pool_address);
    }
// create a seperate function for users and the pool
    function burnpoolXSD(uint _xsdamount) public {
        require(msg.sender == router, "Only the router can access this function");
        require(totalSupply()-CollateralPool(payable(collateral_pool_address)).collat_XSD()>_xsdamount, "uXSD has to be positive");
        super._burn(address(xsdEthPool),_xsdamount);
        xsdEthPool.sync();
        emit XSDBurned(msg.sender, address(this), _xsdamount);
    }
    // add burn function for users
    function burnUserXSD(uint _xsdamount) public {
        require(totalSupply()-CollateralPool(payable(collateral_pool_address)).collat_XSD()>_xsdamount, "uXSD has to be positive");
        super._burn(msg.sender, _xsdamount);
        emit XSDBurned(msg.sender, address(this), _xsdamount);
    }
    function setXSDStep(uint256 _new_step) public onlyByOwnerPID {
        xsd_step = _new_step;

        emit XSDStepSet(_new_step);
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerPID {
        price_target = _new_price_target;

        emit PriceTargetSet(_new_price_target);
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerPID {
    	refresh_cooldown = _new_cooldown;

        emit RefreshCooldownSet(_new_cooldown);
    }

    function setTreasury(address _new_treasury) public onlyByOwner {
        require(_new_treasury != address(0), "Zero address detected");
        treasury = _new_treasury;
    }

    function setETHUSDOracle(address _eth_usd_oracle_address) public onlyByOwner {
        require(_eth_usd_oracle_address != address(0), "Zero address detected");

        eth_usd_oracle_address = _eth_usd_oracle_address;
        eth_usd_pricer = ChainlinkETHUSDPriceConsumer(eth_usd_oracle_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();

        emit ETHUSDOracleSet(_eth_usd_oracle_address);
    }
    
    function setXAGUSDOracle(address _xag_usd_oracle_address) public onlyByOwner {
        require(_xag_usd_oracle_address != address(0), "Zero address detected");

        xag_usd_oracle_address = _xag_usd_oracle_address;
        xag_usd_pricer = ChainlinkXAGUSDPriceConsumer(xag_usd_oracle_address);
        xag_usd_pricer_decimals = xag_usd_pricer.getDecimals();

        emit XAGUSDOracleSet(_xag_usd_oracle_address);
    }

    function setPIDController(address _pid_address) external onlyByOwner {
        require(_pid_address != address(0), "Zero address detected");

        pid_address = _pid_address;

        emit PIDControllerSet(_pid_address);
    }

    function setRouterAddress(address _router) external onlyByOwner {
        require(_router != address(0), "Zero address detected");
        router = _router;
    }

    function setPriceBand(uint256 _price_band) external onlyByOwner {
        price_band = _price_band;

        emit PriceBandSet(_price_band);
    }

    // Sets the XSD_ETH Uniswap oracle address 
    function setXSDEthPool(address _xsd_pool_addr) public onlyByOwner {
        require(_xsd_pool_addr != address(0), "Zero address detected");
        xsdEthPool = IXSDWETHpool(_xsd_pool_addr); 

        emit XSDETHPoolSet(_xsd_pool_addr);
    }

    // Sets the BankX_ETH Uniswap oracle address 
    function setBankXEthPool(address _bankx_pool_addr) public onlyByOwner {
        require(_bankx_pool_addr != address(0), "Zero address detected");
        bankxEthPool = IBankXWETHpool(_bankx_pool_addr);

        emit BankXEthPoolSet(_bankx_pool_addr);
    }

    //sets the collateral pool address
    function setCollateralEthPool(address _collateral_pool_address) public onlyByOwner {
        require(_collateral_pool_address != address(0), "Zero address detected");
        collateral_pool_address = payable(_collateral_pool_address);
    }

    function setSmartContractOwner(address _smartcontract_owner) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(msg.sender != address(0), "Zero address detected");
        smartcontract_owner = _smartcontract_owner;
    }

    function renounceOwnership() external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        smartcontract_owner = address(0);
    }

    /* ========== EVENTS ========== */

    // Track XSD burned
    event XSDBurned(address indexed from, address indexed to, uint256 amount);

    // Track XSD minted
    event XSDMinted(address indexed from, address indexed to, uint256 amount);

    event CollateralRatioRefreshed(uint256 global_collateral_ratio);
    event PoolAdded(address pool_address);
    event PoolRemoved(address pool_address);
    event RedemptionFeeSet(uint256 red_fee);
    event MintingFeeSet(uint256 min_fee);
    event XSDStepSet(uint256 new_step);
    event PriceTargetSet(uint256 new_price_target);
    event RefreshCooldownSet(uint256 new_cooldown);
    event ETHUSDOracleSet(address eth_usd_oracle_address);
    event XAGUSDOracleSet(address xag_usd_oracle_address);
    event PIDControllerSet(address _pid_controller);
    event PriceBandSet(uint256 price_band);
    event XSDETHPoolSet(address xsd_pool_addr);
    event BankXEthPoolSet(address bankx_pool_addr);
    event CollateralRatioToggled(bool collateral_ratio_paused);
}