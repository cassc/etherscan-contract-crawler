// SPDX-License-Identifier: MIT
/*
BBBBBBBBBBBBBBBBB                                         kkkkkkkk         XXXXXXX       XXXXXXX
B::::::::::::::::B                                        k::::::k         X:::::X       X:::::X
B::::::BBBBBB:::::B                                       k::::::k         X:::::X       X:::::X
BB:::::B     B:::::B                                      k::::::k         X::::::X     X::::::X
  B::::B     B:::::B   aaaaaaaaaaaaa   nnnn  nnnnnnnn      k:::::k kkkkkkk XXX:::::X   X:::::XXX
  B::::B     B:::::B   a::::::::::::a  n:::nn::::::::nn    k:::::k k:::::k    X:::::X X:::::X
  B::::BBBBBB:::::B    aaaaaaaaa:::::a n::::::::::::::nn   k:::::k k:::::k     X:::::X:::::X
  B:::::::::::::BB              a::::a nn:::::::::::::::n  k:::::k k:::::k      X:::::::::X
  B::::BBBBBB:::::B      aaaaaaa:::::a   n:::::nnnn:::::n  k::::::k:::::k       X:::::::::X
  B::::B     B:::::B   aa::::::::::::a   n::::n    n::::n  k:::::::::::k       X:::::X:::::X
  B::::B     B:::::B  a::::aaaa::::::a   n::::n    n::::n  k:::::::::::k      X:::::X X:::::X
  B::::B     B:::::B a::::a    a:::::a   n::::n    n::::n  k::::::k:::::k  XXX:::::X   X:::::XXX
BB:::::BBBBBB::::::B a::::a    a:::::a   n::::n    n::::n k::::::k k:::::k X::::::X     X::::::X
B:::::::::::::::::B  a:::::aaaa::::::a   n::::n    n::::n k::::::k k:::::k X:::::X       X:::::X
B::::::::::::::::B    a::::::::::aa:::a  n::::n    n::::n k::::::k k:::::k X:::::X       X:::::X
BBBBBBBBBBBBBBBBB      aaaaaaaaaa  aaaa  nnnnnn    nnnnnn kkkkkkkk kkkkkkk XXXXXXX       XXXXXXX


                                          Currency Creators Manifesto

Our world faces an urgent crisis of currency manipulation, theft and inflation.  Under the current system, currency is controlled by and benefits elite families, governments and large banking institutions.  We believe currencies should be minted by and benefit the individual, not the establishment.  It is time to take back the control of and the freedom that money can provide.

BankX is rebuilding the legacy banking system from the ground up by providing you with the capability to create currency and be in complete control of wealth creation with a concept we call ‘Individual Created Digital Currency’ (ICDC). You own the collateral.  You mint currency.  You earn interest.  You leverage without the risk of liquidation.  You stake to earn even more returns.  All of this is done with complete autonomy and decentralization.  BankX has built a stablecoin for Individual Freedom.

BankX is the antidote for the malevolent financial system bringing in a new future of freedom where you are in complete control with no middlemen, bank or central bank between you and your finances. This capability to create currency and be in complete control of wealth creation will be in the hands of every individual that uses BankX.

By 2030, we will rid the world of the corrupt, tyrannical and incompetent banking system replacing it with a system where billions of people will be in complete control of their financial future.  Everyone will be given ultimate freedom to use their assets to create currency, earn interest and multiply returns to accomplish their individual goals.  The mission of BankX is to be the first to mint $1 trillion in stablecoin. 

We will bring about this transformation by attracting people that believe what we believe.  We will partner with other blockchain protocols and build decentralized applications that drive even more usage.  Finally, we will deploy a private network that is never connected to the Internet to communicate between counterparties, that allows for blockchain-to-blockchain interoperability and stores private keys and cryptocurrency wallets.  Our ecosystem, network and platform has never been seen in the market and provides us with a long term sustainable competitive advantage.

We value individual freedom.
We believe in financial autonomy.
We are anti-establishment.
We envision a future of self-empowerment.

*/
pragma solidity ^0.8.0;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "../../BankX/BankXToken.sol";
import "../XSDStablecoin.sol";
import "./Interfaces/IBankXWETHpool.sol";
import "./Interfaces/IXSDWETHpool.sol";
import '../../Oracle/Interfaces/IPIDController.sol';
import "../../ERC20/IWETH.sol";
import "./CollateralPoolLibrary.sol";

contract CollateralPool is ReentrancyGuard {
    /* ========== STATE VARIABLES ========== */

    address public WETH;
    address public smartcontract_owner;
    address public xsd_contract_address;
    address public bankx_contract_address;
    address public xsdweth_pool;
    address public bankxweth_pool;
    address public pid_address;
    BankXToken private BankX;
    XSDStablecoin private XSD;
    IPIDController private pid_controller;
    uint256 public collat_XSD;
    uint256 public bankx_price;
    uint256 public xsd_price;
    bool public mint_paused;
    bool public redeem_paused;
    bool public buyback_paused;

    struct MintInfo {
        uint256 accum_interest; //accumulated interest from previous mints
        uint256 interest_rate; //interest rate at that particular timestamp
        uint256 time; //last timestamp
        uint256 amount; //XSD amount minted
    }
    struct PriceCheck{
        uint256 lastpricecheck;
        bool pricecheck;
    }
    mapping(address=>MintInfo) public mintMapping; 
    mapping (address => uint256) public redeemBankXBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    mapping (address => uint256) public vestingtimestamp;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolBankX;
    uint256 public collateral_equivalent_d18;
    uint256 public bankx_minted_count;
    mapping (address => uint256) public lastRedeemed;
    mapping (address => PriceCheck) public lastPriceCheck;

    uint256 public block_delay = 2;
    /* ========== MODIFIERS ========== */

    modifier onlyByOwner() {
        require(msg.sender == smartcontract_owner, "Not owner");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _xsd_contract_address,
        address _bankx_contract_address,
        address _bankxweth_pool,
        address _xsdweth_pool,
        address _WETH,
        address _smartcontract_owner
    ) {
        require(
            (_xsd_contract_address != address(0))
            && (_bankx_contract_address != address(0))
            && (_WETH != address(0))
            && (_bankxweth_pool != address(0))
            && (_xsdweth_pool != address(0))
        , "Zero address detected"); 
        XSD = XSDStablecoin(_xsd_contract_address);
        BankX = BankXToken(_bankx_contract_address);
        xsd_contract_address = _xsd_contract_address;
        bankx_contract_address = _bankx_contract_address;
        xsdweth_pool = _xsdweth_pool;
        bankxweth_pool = _bankxweth_pool;
        WETH = _WETH;
        smartcontract_owner = _smartcontract_owner;
    }

    /* ========== VIEWS ========== */

    //only accept ETH via fallback function from the WETH contract
    receive() external payable {
        assert(msg.sender == WETH);
    }

    // Returns dollar value of collateral held in this XSD pool
    function collatDollarBalance() public view returns (uint256) {
            return ((IWETH(WETH).balanceOf(address(this))*XSD.eth_usd_price())/(1e6));        
    }

    // Returns the value of excess collateral held in this XSD pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        uint256 global_collateral_ratio = XSD.global_collateral_ratio();
        uint256 global_collat_value = XSD.globalCollateralValue();

        if (global_collateral_ratio > (1e6)) global_collateral_ratio = (1e6); // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = ((collat_XSD)*global_collateral_ratio*(XSD.xag_usd_price()*(1e4))/(311035))/(1e12); // Calculates collateral needed to back each 1 XSD with $1 of collateral at current collat ratio
        if ((global_collat_value-unclaimedPoolCollateral)>required_collat_dollar_value_d18) return (global_collat_value-unclaimedPoolCollateral-required_collat_dollar_value_d18);
        else return 0;
    }
    /* ========== INTERNAL FUNCTIONS ======== */
    function priceCheck() external{
        bankx_price = XSD.bankx_price();
        xsd_price = XSD.xsd_price();
        lastPriceCheck[msg.sender].lastpricecheck = block.number;
        lastPriceCheck[msg.sender].pricecheck = true;
    }

    function mintInterestCalc(uint xsd_amount,address sender) internal {
        (mintMapping[sender].accum_interest, mintMapping[sender].interest_rate, mintMapping[sender].time, mintMapping[sender].amount) = CollateralPoolLibrary.calcMintInterest(xsd_amount,XSD.xag_usd_price(), XSD.interest_rate(), mintMapping[sender].accum_interest, mintMapping[sender].interest_rate, mintMapping[sender].time, mintMapping[sender].amount);
    }
    function redeemInterestCalc(uint xsd_amount,address sender) internal {
        (mintMapping[sender].accum_interest, mintMapping[sender].interest_rate, mintMapping[sender].time, mintMapping[sender].amount)=CollateralPoolLibrary.calcRedemptionInterest(xsd_amount,XSD.xag_usd_price(), mintMapping[sender].accum_interest, mintMapping[sender].interest_rate, mintMapping[sender].time, mintMapping[sender].amount);
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1XSD(uint256 XSD_out_min) external payable nonReentrant {
        require(!mint_paused, "Mint Paused");
        require(msg.value>0, "Invalid collateral amount");
        require(XSD.global_collateral_ratio() >= (1e6), "Collateral ratio must be >= 1");
        (uint256 xsd_amount_d18) = CollateralPoolLibrary.calcMint1t1XSD(
            XSD.eth_usd_price(),
            XSD.xag_usd_price(),
            msg.value
        ); //1 XSD for each $1 worth of collateral
        require(XSD_out_min <= xsd_amount_d18, "Slippage limit reached");
        mintInterestCalc(xsd_amount_d18,msg.sender);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(address(this), msg.value));
        collat_XSD = collat_XSD + xsd_amount_d18;
        XSD.pool_mint(msg.sender, xsd_amount_d18);
    }

    // 0% collateral-backed
    function mintAlgorithmicXSD(uint256 bankx_amount_d18, uint256 XSD_out_min) external nonReentrant {
        require(!mint_paused, "Mint Paused");
        require(((lastPriceCheck[msg.sender].lastpricecheck+(block_delay)) <= block.number) && (lastPriceCheck[msg.sender].pricecheck), "Must wait for block_delay blocks before minting");
        uint256 xag_usd_price = XSD.xag_usd_price();
        require(XSD.global_collateral_ratio() == 0, "Collateral ratio must be 0");
        (uint256 xsd_amount_d18) = CollateralPoolLibrary.calcMintAlgorithmicXSD(
            bankx_price, 
            xag_usd_price,
            bankx_amount_d18
        );
        require(XSD_out_min <= xsd_amount_d18, "Slippage limit reached");
        mintInterestCalc(xsd_amount_d18,msg.sender);
        collat_XSD = collat_XSD + xsd_amount_d18;
        bankx_minted_count = bankx_minted_count + bankx_amount_d18;
        lastPriceCheck[msg.sender].pricecheck = false;
        BankX.pool_burn_from(msg.sender, bankx_amount_d18);
        XSD.pool_mint(msg.sender, xsd_amount_d18);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalXSD(uint256 bankx_amount, uint256 XSD_out_min) external payable nonReentrant {
        require(!mint_paused, "Mint Paused");
        require(((lastPriceCheck[msg.sender].lastpricecheck+(block_delay)) <= block.number) && (lastPriceCheck[msg.sender].pricecheck), "Must wait for block_delay blocks before minting");
        uint256 xag_usd_price = XSD.xag_usd_price();
        uint256 global_collateral_ratio = XSD.global_collateral_ratio();

        require(global_collateral_ratio < (1e6) && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        CollateralPoolLibrary.MintFF_Params memory input_params = CollateralPoolLibrary.MintFF_Params(
            bankx_price,
            XSD.eth_usd_price(),
            bankx_amount,
            msg.value,
            global_collateral_ratio
        );

        (uint256 mint_amount, uint256 bankx_needed) = CollateralPoolLibrary.calcMintFractionalXSD(input_params);
        mint_amount = (mint_amount*31103477)/((xag_usd_price)); //grams of silver in calculated mint amount
        require(XSD_out_min <= mint_amount, "Slippage limit reached");
        require(bankx_needed <= bankx_amount, "Not enough BankX inputted");
        mintInterestCalc(mint_amount,msg.sender);
        bankx_minted_count = bankx_minted_count + bankx_needed;
        BankX.pool_burn_from(msg.sender, bankx_needed);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(address(this), msg.value));
        collat_XSD = collat_XSD + mint_amount;
        lastPriceCheck[msg.sender].pricecheck = false;
        XSD.pool_mint(msg.sender, mint_amount);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1XSD(uint256 XSD_amount, uint256 COLLATERAL_out_min) external nonReentrant {
        require(!pid_controller.bucket3(), "Cannot withdraw in times of deficit");
        require(!redeem_paused, "Redeem Paused");
        require(XSD.global_collateral_ratio() == (1e6), "Collateral ratio must be == 1");
        require(XSD_amount<=mintMapping[msg.sender].amount, "OVERREDEMPTION ERROR");
        require(((lastPriceCheck[msg.sender].lastpricecheck+(block_delay)) <= block.number) && (lastPriceCheck[msg.sender].pricecheck), "Must wait for block_delay blocks before redeeming");

        // convert xsd to $ and then to collateral value
        (uint256 XSD_dollar,uint256 collateral_needed) = CollateralPoolLibrary.calcRedeem1t1XSD(
            XSD.eth_usd_price(),
            XSD.xag_usd_price(),
            XSD_amount
        );
        uint total_xsd_amount = mintMapping[msg.sender].amount;
        require(collateral_needed <= (IWETH(WETH).balanceOf(address(this))-unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");
        redeemInterestCalc(XSD_amount, msg.sender);
        uint current_accum_interest = (XSD_amount*mintMapping[msg.sender].accum_interest)/total_xsd_amount;
        redeemBankXBalances[msg.sender] = (redeemBankXBalances[msg.sender]+current_accum_interest);
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender]+XSD_dollar;
        unclaimedPoolCollateral = unclaimedPoolCollateral+XSD_dollar;
        lastRedeemed[msg.sender] = block.number;
        unclaimedPoolBankX = (unclaimedPoolBankX+current_accum_interest);
        uint256 bankx_amount = (current_accum_interest*1e6)/bankx_price;
        collat_XSD -= XSD_amount;
        mintMapping[msg.sender].accum_interest = (mintMapping[msg.sender].accum_interest - current_accum_interest);
        lastPriceCheck[msg.sender].pricecheck = false;
        XSD.pool_burn_from(msg.sender, XSD_amount);
        BankX.pool_mint(address(this), bankx_amount);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem XSD for collateral and BankX. > 0% and < 100% collateral-backed
    function redeemFractionalXSD(uint256 XSD_amount, uint256 BankX_out_min, uint256 COLLATERAL_out_min) external nonReentrant {
        require(!pid_controller.bucket3(), "Cannot withdraw in times of deficit");
        require(((lastPriceCheck[msg.sender].lastpricecheck+(block_delay)) <= block.number) && (lastPriceCheck[msg.sender].pricecheck), "Must wait for block_delay blocks before redeeming");
        require(!redeem_paused, "Redeem Paused");
        require(XSD_amount<=mintMapping[msg.sender].amount, "OVERREDEMPTION ERROR");
        uint256 xag_usd_price = XSD.xag_usd_price();
        uint256 global_collateral_ratio = XSD.global_collateral_ratio();

        require(global_collateral_ratio < (1e6) && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        

        uint256 bankx_dollar_value_d18 = XSD_amount - ((XSD_amount*global_collateral_ratio)/(1e6));
        bankx_dollar_value_d18 = (bankx_dollar_value_d18*xag_usd_price)/(31103477);
        uint256 bankx_amount = (bankx_dollar_value_d18*1e6)/bankx_price;


        uint256 collateral_dollar_value = (XSD_amount*global_collateral_ratio)/(1e6);
        collateral_dollar_value = (collateral_dollar_value*xag_usd_price)/31103477;
        uint256 collateral_amount = (collateral_dollar_value*1e6)/XSD.eth_usd_price();


        require(collateral_amount <= (IWETH(WETH).balanceOf(address(this))-unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount, "Slippage limit reached [collateral]");
        require(BankX_out_min <= bankx_amount, "Slippage limit reached [BankX]");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender]+collateral_dollar_value;
        unclaimedPoolCollateral = unclaimedPoolCollateral+collateral_dollar_value;
        lastRedeemed[msg.sender] = block.number;
        uint total_xsd_amount = mintMapping[msg.sender].amount;
        redeemInterestCalc(XSD_amount, msg.sender);
        uint current_accum_interest = (XSD_amount*mintMapping[msg.sender].accum_interest)/total_xsd_amount;
        redeemBankXBalances[msg.sender] = redeemBankXBalances[msg.sender]+current_accum_interest;
        bankx_amount = bankx_amount + ((current_accum_interest*1e6)/bankx_price);
        mintMapping[msg.sender].accum_interest = mintMapping[msg.sender].accum_interest - current_accum_interest;
        redeemBankXBalances[msg.sender] = redeemBankXBalances[msg.sender]+bankx_dollar_value_d18;
        unclaimedPoolBankX = unclaimedPoolBankX+bankx_dollar_value_d18+current_accum_interest;
        collat_XSD -= XSD_amount;
        lastPriceCheck[msg.sender].pricecheck = false;
    
        XSD.pool_burn_from(msg.sender, XSD_amount);
        BankX.pool_mint(address(this), bankx_amount);
    }

    // Redeem XSD for BankX. 0% collateral-backed
    function redeemAlgorithmicXSD(uint256 XSD_amount, uint256 BankX_out_min) external nonReentrant {
        require(!pid_controller.bucket3(), "Cannot withdraw in times of deficit");
        require(!redeem_paused, "Redeem Paused");
        require(XSD_amount<=mintMapping[msg.sender].amount, "OVERREDEMPTION ERROR");
        require(((lastPriceCheck[msg.sender].lastpricecheck+(block_delay)) <= block.number) && (lastPriceCheck[msg.sender].pricecheck), "Must wait for block_delay blocks before redeeming");
        require(XSD.global_collateral_ratio() == 0, "Collateral ratio must be 0"); 
        uint256 bankx_dollar_value_d18 = (XSD_amount*XSD.xag_usd_price())/(31103477);

        uint256 bankx_amount = (bankx_dollar_value_d18*1e6)/bankx_price;
        
        lastRedeemed[msg.sender] = block.number;
        uint total_xsd_amount = mintMapping[msg.sender].amount;
        require(BankX_out_min <= bankx_amount, "Slippage limit reached");
        redeemInterestCalc(XSD_amount, msg.sender);
        uint current_accum_interest = XSD_amount*mintMapping[msg.sender].accum_interest/total_xsd_amount; //precision of 6
        redeemBankXBalances[msg.sender] = (redeemBankXBalances[msg.sender]+current_accum_interest);
        bankx_amount = bankx_amount + ((current_accum_interest*1e6)/bankx_price);
        mintMapping[msg.sender].accum_interest = (mintMapping[msg.sender].accum_interest - current_accum_interest);
        redeemBankXBalances[msg.sender] = redeemBankXBalances[msg.sender]+bankx_dollar_value_d18;
        unclaimedPoolBankX = unclaimedPoolBankX+bankx_dollar_value_d18+current_accum_interest;
        collat_XSD -= XSD_amount;
        lastPriceCheck[msg.sender].pricecheck = false;
        XSD.pool_burn_from(msg.sender, XSD_amount);
        BankX.pool_mint(address(this), bankx_amount);
    }

    // After a redemption happens, transfer the newly minted BankX and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out XSD/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external nonReentrant{
        require(!pid_controller.bucket3(), "Cannot withdraw in times of deficit");
        require(!redeem_paused, "Redeem Paused");
        require(((lastRedeemed[msg.sender]+(block_delay)) <= block.number) && ((lastPriceCheck[msg.sender].lastpricecheck+(block_delay)) <= block.number) && (lastPriceCheck[msg.sender].pricecheck), "Must wait for block_delay blocks before redeeming");
        uint BankXDollarAmount;
        uint CollateralDollarAmount;
        uint BankXAmount;
        uint CollateralAmount;

        // Use Checks-Effects-Interactions pattern
        if(redeemBankXBalances[msg.sender] > 0){
            BankXDollarAmount = redeemBankXBalances[msg.sender];
            BankXAmount = (BankXDollarAmount*1e6)/bankx_price;
            redeemBankXBalances[msg.sender] = 0;
            unclaimedPoolBankX = unclaimedPoolBankX-BankXDollarAmount;
            TransferHelper.safeTransfer(address(BankX), msg.sender, BankXAmount);
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralDollarAmount = redeemCollateralBalances[msg.sender];
            CollateralAmount = (CollateralDollarAmount*1e6)/XSD.eth_usd_price();
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral-CollateralDollarAmount;
            IWETH(WETH).withdraw(CollateralAmount); //try to unwrap eth in the redeem
            TransferHelper.safeTransferETH(msg.sender, CollateralAmount);
        }
        lastPriceCheck[msg.sender].pricecheck = false;
    }

    // Function can be called by an BankX holder to have the protocol buy back BankX with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    // add XSD as a burn option while uXSD value is positive
    // need two seperate functions: one for bankx and one for XSD
    function buyBackBankX(uint256 BankX_amount,uint256 COLLATERAL_out_min) external{
        require(!buyback_paused, "Buyback Paused");
        require(((lastPriceCheck[msg.sender].lastpricecheck+(block_delay)) <= block.number) && (lastPriceCheck[msg.sender].pricecheck), "Must wait for block_delay blocks before buyback");
        CollateralPoolLibrary.BuybackBankX_Params memory input_params = CollateralPoolLibrary.BuybackBankX_Params(
            availableExcessCollatDV(),
            bankx_price,
            XSD.eth_usd_price(),
            BankX_amount
        );

        (collateral_equivalent_d18) = (CollateralPoolLibrary.calcBuyBackBankX(input_params));

        require(COLLATERAL_out_min <= collateral_equivalent_d18, "Slippage limit reached");
        lastPriceCheck[msg.sender].pricecheck = false;
        // Give the sender their desired collateral and burn the BankX
        BankX.pool_burn_from(msg.sender, BankX_amount);
        TransferHelper.safeTransfer(address(WETH), address(this), collateral_equivalent_d18);
        IWETH(WETH).withdraw(collateral_equivalent_d18);
        TransferHelper.safeTransferETH(msg.sender, collateral_equivalent_d18);
    }
    //buyback with XSD instead of bankx
    function buyBackXSD(uint256 XSD_amount, uint256 collateral_out_min) external {
        require(!buyback_paused, "Buyback Paused");
        require(((lastPriceCheck[msg.sender].lastpricecheck+(block_delay)) <= block.number) && (lastPriceCheck[msg.sender].pricecheck), "Must wait for block_delay blocks before buyback");
        if(XSD_amount != 0) require((XSD.totalSupply()+XSD_amount)>collat_XSD, "uXSD MUST BE POSITIVE");

        CollateralPoolLibrary.BuybackXSD_Params memory input_params = CollateralPoolLibrary.BuybackXSD_Params(
            availableExcessCollatDV(),
            xsd_price,
            XSD.eth_usd_price(),
            XSD_amount
        );

        (collateral_equivalent_d18) = (CollateralPoolLibrary.calcBuyBackXSD(input_params));

        require(collateral_out_min <= collateral_equivalent_d18, "Slippage limit reached");
        lastPriceCheck[msg.sender].pricecheck = false;
        XSD.pool_burn_from(msg.sender, XSD_amount);
        TransferHelper.safeTransfer(address(WETH), address(this), collateral_equivalent_d18);
        IWETH(WETH).withdraw(collateral_equivalent_d18);
        TransferHelper.safeTransferETH(msg.sender, collateral_equivalent_d18);
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 new_block_delay, bool _mint_paused, bool _redeem_paused, bool _buyback_paused) external onlyByOwner {
        block_delay = new_block_delay;
        mint_paused = _mint_paused;
        redeem_paused = _redeem_paused;
        buyback_paused = _buyback_paused;
        emit PoolParametersSet(new_block_delay);
    }

    function setPIDController(address new_pid_address) external onlyByOwner {
        pid_controller = IPIDController(new_pid_address);
        pid_address = new_pid_address;
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

    function resetAddresses(address _xsd_contract_address,
        address _bankx_contract_address,
        address _bankxweth_pool,
        address _xsdweth_pool,
        address _WETH) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(
            (_xsd_contract_address != address(0))
            && (_bankx_contract_address != address(0))
            && (_WETH != address(0))
            && (_bankxweth_pool != address(0))
            && (_xsdweth_pool != address(0))
        , "Zero address detected"); 
        XSD = XSDStablecoin(_xsd_contract_address);
        BankX = BankXToken(_bankx_contract_address);
        xsd_contract_address = _xsd_contract_address;
        bankx_contract_address = _bankx_contract_address;
        xsdweth_pool = _xsdweth_pool;
        bankxweth_pool = _bankxweth_pool;
        WETH = _WETH;
    }

    /* ========== EVENTS ========== */

    event PoolParametersSet(uint256 new_block_delay);

}