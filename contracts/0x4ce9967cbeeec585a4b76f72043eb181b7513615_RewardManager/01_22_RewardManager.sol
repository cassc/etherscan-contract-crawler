//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../../Utils/Initializable.sol';
import './Interfaces/IBankXWETHpool.sol';
import './Interfaces/IXSDWETHpool.sol';
import "../XSDStablecoin.sol";
import "../../BankX/BankXToken.sol";
import "./Interfaces/IRewardManager.sol";
import '../../Oracle/Interfaces/IPIDController.sol';
//manages rewards and crossovers for liquidity and collateral pools

contract RewardManager is IRewardManager,ReentrancyGuard,Initializable{
    address public smartcontract_owner;
    address public bankx_pool_address;
    address public xsd_pool_address;
    address public collat_pool_address;
    address public xsd_address;
    address public bankx_address;
    address public weth_address;
    IPIDController pid_controller;
    XSDStablecoin private XSD;
    BankXToken private BankX;
    IBankXWETHpool private bankxwethpool;
    IXSDWETHpool private xsdwethpool;
    uint public vesting1;
    uint public vesting2;
    uint public vesting3;
    struct Liquidity_Provider{
        uint vestingtimestamp;
        uint ethvalue;
        uint xsdrewards;
        uint bankxrewards;
    }
    mapping(address => mapping(address => mapping(uint => Liquidity_Provider))) public liquidity_provider;
    constructor(
        address _smartcontract_owner, 
        address _weth_address
    ){
        require((_smartcontract_owner != address(0))
        &&(_weth_address != address(0)),"Zero address detected");
        smartcontract_owner = _smartcontract_owner;
        weth_address = _weth_address;
    }
    // called once by the smart contract owner at time of deployment
    function initialize(address _bankx_address, address _xsd_address,address _xsd_pool_address,address _bankx_pool_address,address _collat_pool_address, address _pid_address,uint _vesting1,uint _vesting2,uint _vesting3) public initializer {
        require(msg.sender == smartcontract_owner, 'RewardManager: FORBIDDEN'); // sufficient check
        require((_bankx_address != address(0))
        &&(_xsd_address != address(0))
        &&(_xsd_pool_address != address(0))
        &&(_bankx_pool_address != address(0))
        &&(_pid_address != address(0)), "Zero address detected");
        bankx_address = _bankx_address;
        xsd_address = _xsd_address;
        bankx_pool_address = _bankx_pool_address;
        xsd_pool_address = _xsd_pool_address;
        collat_pool_address = _collat_pool_address;
        BankX = BankXToken(bankx_address);
        XSD = XSDStablecoin(_xsd_address);
        bankxwethpool = IBankXWETHpool(_bankx_pool_address);
        xsdwethpool = IXSDWETHpool(_xsd_pool_address);
        pid_controller = IPIDController(_pid_address);
        vesting1 = _vesting1;
        vesting2 = _vesting2;
        vesting3 = _vesting3;
    }

    function tier1(address pool,uint percent,address to,uint ethvalue,uint amountpaid,uint difference) private {
        uint actdiff = difference - amountpaid;
        if(ethvalue>actdiff){
           uint left_over = ethvalue - actdiff;
           liquidity_provider[pool][to][vesting1].ethvalue += actdiff;
           liquidity_provider[pool][to][vesting1].bankxrewards += actdiff + (actdiff*percent/100);
           liquidity_provider[pool][to][vesting1].xsdrewards += actdiff/20;
           liquidity_provider[bankx_pool_address][to][vesting2].vestingtimestamp = block.timestamp+vesting2;
           tier2(pool,percent,to,left_over,difference);
        }
        else{
            liquidity_provider[pool][to][vesting1].ethvalue += ethvalue;
            liquidity_provider[pool][to][vesting1].bankxrewards += ethvalue + (ethvalue*percent/100);
            liquidity_provider[pool][to][vesting1].xsdrewards += ethvalue/20;
        }
    }

    function tier2(address pool,uint percent,address to,uint ethvalue,uint difference) private {
        if(ethvalue>difference){
            uint left_over = ethvalue - difference;
            liquidity_provider[pool][to][vesting2].ethvalue += difference;
            liquidity_provider[pool][to][vesting2].bankxrewards += difference + (difference*percent/100);
            liquidity_provider[pool][to][vesting2].xsdrewards += difference/50;
            liquidity_provider[pool][to][vesting3].ethvalue += left_over;
            liquidity_provider[pool][to][vesting3].bankxrewards += left_over + (left_over*percent/100);
            liquidity_provider[bankx_pool_address][to][vesting3].vestingtimestamp = block.timestamp + vesting3;
            }
        else{
            liquidity_provider[pool][to][vesting2].ethvalue += ethvalue;
            liquidity_provider[pool][to][vesting2].bankxrewards += ethvalue + (ethvalue*percent/100);
            liquidity_provider[pool][to][vesting2].xsdrewards += ethvalue/50;
        }
    }
//When the creator adds liquidity during a deficit period it must be added to the amount paid variables
    function creatorProvideBankXLiquidity() external override nonReentrant{
        (uint112 _reserve0, uint112 _reserve1,) = bankxwethpool.getReserves(); // gas savings
        uint balance0 = IERC20(bankx_address).balanceOf(bankx_pool_address);
        uint balance1 = IERC20(weth_address).balanceOf(bankx_pool_address);
        uint amount0 = balance0-(_reserve0);
        uint amount1 = balance1-(_reserve1);
        if(pid_controller.bucket2()){
            uint ethvalue = ((amount0*XSD.bankx_price())+(amount1*XSD.eth_usd_price()))/(1e6);
            pid_controller.amountPaidBankXWETH(ethvalue);
        }
        bankxwethpool.sync();
        emit CreatorProvideBankXLiquidity(msg.sender, amount0, amount1);
    }

    function creatorProvideXSDLiquidity() external override nonReentrant{
        (uint112 _reserve0, uint112 _reserve1,) = xsdwethpool.getReserves();
        uint balance0 = IERC20(xsd_address).balanceOf(xsd_pool_address);
        uint balance1 = IERC20(weth_address).balanceOf(xsd_pool_address);
        uint amount0 = balance0-(_reserve0);
        uint amount1 = balance1-(_reserve1);
        if(pid_controller.bucket1()){
            uint ethvalue = ((amount0*XSD.xsd_price())+(amount1*XSD.eth_usd_price()))/(1e6);
            pid_controller.amountPaidXSDWETH(ethvalue);
        }
        xsdwethpool.sync();
        emit CreatorProvideXSDLiquidity(msg.sender, amount0, amount1);
    }
    //principal is split among tiers as well
    function userProvideBankXLiquidity(address to) external override nonReentrant{
        require(pid_controller.bucket2(), "RewardManager:NO DEFICIT");
        (, uint112 _reserve1,) = bankxwethpool.getReserves(); // gas savings
        uint balance1 = IERC20(weth_address).balanceOf(bankx_pool_address);
        uint amount = balance1-_reserve1;
        uint ethvalue = (amount*(XSD.eth_usd_price()))/(1e6);
        uint bankxamount = ethvalue/XSD.bankx_price();
        uint amountpaid = pid_controller.amountpaid2();
        uint difference = pid_controller.diff2()/3;
        require((ethvalue+amountpaid)<(difference*3),"BankXLiquidity:DEFICIT LIMIT");
        if(amountpaid<difference){
            tier1(bankx_pool_address,8,to,ethvalue,amountpaid,difference);//+604800;
            liquidity_provider[bankx_pool_address][to][vesting1].vestingtimestamp = block.timestamp+vesting1;
        }
        else if(amountpaid<(difference*(2))){
            tier2(bankx_pool_address,8,to,ethvalue,(2*difference)-amountpaid);//1209600;
            liquidity_provider[bankx_pool_address][to][vesting2].vestingtimestamp = block.timestamp+vesting2;
        }
        else{
            liquidity_provider[bankx_pool_address][to][vesting3].ethvalue += ethvalue;
            liquidity_provider[bankx_pool_address][to][vesting3].bankxrewards += ethvalue + (ethvalue*9/100);
            liquidity_provider[bankx_pool_address][to][vesting3].vestingtimestamp = block.timestamp + vesting3;
        }
        BankX.pool_mint(bankx_pool_address, bankxamount);
        pid_controller.amountPaidBankXWETH(ethvalue);
        bankxwethpool.sync();
        emit UserProvideBankXLiquidity(to, amount);
    }

    function userProvideXSDLiquidity(address to) external override nonReentrant{
        require(pid_controller.bucket1(),"RewardManager:NO DEFICIT");
        (, uint112 _reserve1,) = xsdwethpool.getReserves(); // gas savings
        uint balance1 = IERC20(weth_address).balanceOf(xsd_pool_address);
        uint amount = balance1-_reserve1;
        uint ethvalue = (amount*(XSD.eth_usd_price()))/(1e6);
        uint xsdamount = ethvalue/XSD.xsd_price();
        uint amountpaid = pid_controller.amountpaid1();
        uint difference = pid_controller.diff1()/3;
        require((ethvalue+amountpaid)<(difference*3),"XSDLiquidity:DEFICIT LIMIT");
        if(amountpaid<difference){
            tier1(xsd_pool_address,9,to,ethvalue,amountpaid,difference);//+604800;
            liquidity_provider[xsd_pool_address][to][vesting1].vestingtimestamp = block.timestamp+vesting1;
        }
        else if(amountpaid<(difference*(2))){
            tier2(xsd_pool_address,9,to,ethvalue,(2*difference)-amountpaid);//1209600;
            liquidity_provider[xsd_pool_address][to][vesting2].vestingtimestamp = block.timestamp+vesting2;
        }
        else{
            liquidity_provider[xsd_pool_address][to][vesting3].ethvalue += ethvalue;
            liquidity_provider[xsd_pool_address][to][vesting3].bankxrewards += ethvalue + (ethvalue*9/100);
            liquidity_provider[xsd_pool_address][to][vesting3].vestingtimestamp = block.timestamp + vesting3;
        }
        XSD.pool_mint(xsd_pool_address, xsdamount);
        pid_controller.amountPaidXSDWETH(ethvalue);
        xsdwethpool.sync();
        emit UserProvideXSDLiquidity(to, amount);
    }

    function userProvideCollatPoolLiquidity(address to, uint amount) external override nonReentrant{
        require(pid_controller.bucket3(),"RewardManager:NO DEFICIT");
        uint ethvalue = (amount*XSD.eth_usd_price())/(1e6);
        uint difference = pid_controller.diff3()/3;
        uint amountpaid = pid_controller.amountpaid3();
        require((ethvalue+amountpaid)<(difference*3),"CollatPoolLiquidity:DEFICIT LIMIT");
        if(amountpaid<difference){
            tier1(collat_pool_address,7,to,ethvalue,amountpaid,difference);//+604800;
            liquidity_provider[collat_pool_address][to][vesting1].vestingtimestamp = block.timestamp+vesting1;
        }
        else if(amountpaid<(difference*(2))){
            tier2(collat_pool_address,7,to,ethvalue,(2*difference)-amountpaid);//1209600;
            liquidity_provider[collat_pool_address][to][vesting2].vestingtimestamp = block.timestamp+vesting2;
        }
        else{
            liquidity_provider[collat_pool_address][to][vesting3].ethvalue += ethvalue;
            liquidity_provider[collat_pool_address][to][vesting3].bankxrewards += ethvalue + (ethvalue*9/100);
            liquidity_provider[collat_pool_address][to][vesting3].vestingtimestamp = block.timestamp + vesting3;
        }
        pid_controller.amountPaidCollateralPool(ethvalue);
        emit UserProvideCollatLiquidity(to, amount);

    }

    function tier1Redemption(address pool,address to) private returns(uint bankxamount,uint xsdamount){
        require(liquidity_provider[pool][to][vesting1].bankxrewards != 0 || liquidity_provider[pool][to][vesting1].xsdrewards != 0, "Nothing to claim");
        bankxamount = ((liquidity_provider[pool][to][vesting1].bankxrewards)*(1e6))/(XSD.bankx_price());
        xsdamount = ((liquidity_provider[pool][to][vesting1].xsdrewards)*(1e6))/(XSD.xsd_price());
        liquidity_provider[pool][to][vesting1].bankxrewards = 0;
        liquidity_provider[pool][to][vesting1].xsdrewards = 0;
        liquidity_provider[pool][to][vesting1].ethvalue = 0;
        liquidity_provider[pool][to][vesting1].vestingtimestamp = 0;
    }
    function tier2Redemption(address pool,address to) private returns(uint bankxamount,uint xsdamount){
        require(liquidity_provider[pool][to][vesting2].bankxrewards != 0 || liquidity_provider[pool][to][vesting2].xsdrewards != 0, "Nothing to claim");
        bankxamount = ((liquidity_provider[pool][to][vesting2].bankxrewards)*(1e6))/(XSD.bankx_price());
        xsdamount = ((liquidity_provider[pool][to][vesting2].xsdrewards)*(1e6))/(XSD.xsd_price());
        liquidity_provider[pool][to][vesting2].bankxrewards = 0;
        liquidity_provider[pool][to][vesting2].xsdrewards = 0;
        liquidity_provider[pool][to][vesting2].ethvalue = 0;
        liquidity_provider[pool][to][vesting2].vestingtimestamp = 0;
    }
    function tier3Redemption(address pool,address to) private returns(uint bankxamount){
        require(liquidity_provider[pool][to][vesting3].bankxrewards != 0, "RewardManager:NO CLAIM");
        bankxamount = ((liquidity_provider[pool][to][vesting3].bankxrewards)*(1e6))/(XSD.bankx_price());
        liquidity_provider[pool][to][vesting3].bankxrewards = 0;
        liquidity_provider[pool][to][vesting3].ethvalue = 0;
        liquidity_provider[pool][to][vesting3].vestingtimestamp = 0;
    }

    function LiquidityRedemption(address pool,address to) external override nonReentrant{
        //find a better way to check which tier
        uint bankxamount;
        uint xsdamount;
        if((liquidity_provider[pool][to][vesting1].ethvalue != 0) && (liquidity_provider[pool][to][vesting1].vestingtimestamp<=block.timestamp)){
            (bankxamount,xsdamount) = tier1Redemption(pool,to);
        }
        if((liquidity_provider[pool][to][vesting2].ethvalue != 0) && (liquidity_provider[pool][to][vesting2].vestingtimestamp<=block.timestamp)){
            uint bankxamount2;
            uint xsdamount2;
            (bankxamount2,xsdamount2) = tier2Redemption(pool,to);
            bankxamount += bankxamount2;
            xsdamount += xsdamount2; 
        }
        if((liquidity_provider[pool][to][vesting3].ethvalue != 0) && (liquidity_provider[pool][to][vesting3].vestingtimestamp<=block.timestamp)){
            bankxamount += tier3Redemption(pool,to);
        }
        BankX.pool_mint(to, bankxamount);
        XSD.pool_mint(to, xsdamount);
        emit liquidityRedemption(to, bankxamount, xsdamount);
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

    function resetAddresses(address _bankx_address, address _xsd_address,address _xsd_pool_address,address _bankx_pool_address,address _collat_pool_address, address _pid_address,uint _vesting1,uint _vesting2,uint _vesting3) external{
        require(msg.sender == smartcontract_owner, 'RewardManager: FORBIDDEN'); // sufficient check
        require((_bankx_address != address(0))
        &&(_xsd_address != address(0))
        &&(_xsd_pool_address != address(0))
        &&(_bankx_pool_address != address(0))
        &&(_pid_address != address(0)), "Zero address detected");
        bankx_address = _bankx_address;
        xsd_address = _xsd_address;
        bankx_pool_address = _bankx_pool_address;
        xsd_pool_address = _xsd_pool_address;
        collat_pool_address = _collat_pool_address;
        BankX = BankXToken(bankx_address);
        XSD = XSDStablecoin(_xsd_address);
        bankxwethpool = IBankXWETHpool(_bankx_pool_address);
        xsdwethpool = IXSDWETHpool(_xsd_pool_address);
        pid_controller = IPIDController(_pid_address);
        vesting1 = _vesting1;
        vesting2 = _vesting2;
        vesting3 = _vesting3;
    }
    // ========== EVENTS ========== 
    event CreatorProvideBankXLiquidity(address sender, uint amount0, uint amount1);
    event CreatorProvideXSDLiquidity(address sender, uint amount0, uint amount1);
    event UserProvideBankXLiquidity(address sender, uint amount);
    event UserProvideXSDLiquidity(address sender, uint amount);
    event UserProvideCollatLiquidity(address sender, uint amount);
    event liquidityRedemption(address sender, uint bankxamount, uint xsdamount);
    
}