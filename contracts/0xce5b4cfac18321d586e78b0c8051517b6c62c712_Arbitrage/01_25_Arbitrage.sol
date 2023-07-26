// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './CollateralPool.sol';
import './Interfaces/IXSDWETHpool.sol';
import './Interfaces/IBankXWETHpool.sol';
import '../XSDStablecoin.sol';
import '../../UniswapFork/Interfaces/IRouter.sol';
import "./CollateralPoolLibrary.sol";
import '../../Oracle/PIDController.sol';
import "../../BankX/BankXToken.sol";

//calculate uXSD amount  = totalSupply - Amount minted in the smart contract.
// If uXSD value is positive then burn to 0 address
// If uXSD value is negative(0) then amount must be transferred to the origin address

contract Arbitrage is ReentrancyGuard{
    address public xsd_address;
    address public bankx_address;
    address public smartcontract_owner;
    address public router_address;
    address public pid_address;
    address public collateral_pool;
    address public xsd_pool;
    address public bankx_pool;
    address public origin_address;

    uint public arbitrage_paused;
    uint public last_update;
    bool public pause_arbitrage;

    XSDStablecoin private XSD;
    BankXToken private BankX;
    PIDController private pid_controller;
    IRouter private Router;

constructor(
        address _xsd_address,
        address _bankx_address,
        address _collateral_pool,
        address _router_address,
        address _pid_controller,
        address _xsd_pool,
        address _bankx_pool,
        address _origin_address,
        address _smartcontract_owner
    ) {
        require((_smartcontract_owner != address(0))
            && (_origin_address != address(0))
            && (_collateral_pool != address(0))
            && (_xsd_pool != address(0))
            && (_bankx_pool != address(0))
            && (_router_address != address(0))
            && (_xsd_address != address(0))
            && (_bankx_address != address(0))
            && (_pid_controller != address(0))
            , "Zero address detected");
        xsd_address = _xsd_address;
        XSD = XSDStablecoin(_xsd_address);
        bankx_address = _bankx_address;
        BankX = BankXToken(_bankx_address);
        collateral_pool = _collateral_pool;
        router_address = _router_address;
        Router = IRouter(_router_address);
        pid_address = _pid_controller;
        pid_controller = PIDController(_pid_controller);
        smartcontract_owner = _smartcontract_owner;
        origin_address = _origin_address;
        bankx_pool = _bankx_pool;
        xsd_pool = _xsd_pool;
    }

//if slippage is passed as zero change calculations accordingly
//mint principal amount of XSD after burning BankX
//above the peg
function burnBankX(uint256 bankx_amount,uint256 slippage) external nonReentrant {
    require(pause_arbitrage, "Arbitrage Paused");
    uint256 time_elapsed = block.timestamp - last_update;
    require(time_elapsed >= arbitrage_paused, "internal cooldown not passed");
    uint256 bankx_price = XSD.bankx_price();
    uint256 xag_usd_price = XSD.xag_usd_price();
    //no arbitrage unless there is a profit margin of more than half a penny
    //change range to half a percent
    uint silver_price = (xag_usd_price*(1e4))/(311035);
    require(XSD.xsd_price()>(silver_price + (silver_price/1e3)), "BurnBankX:ARBITRAGE ERROR");
    (uint256 xsd_amount) = CollateralPoolLibrary.calcMintAlgorithmicXSD(
    bankx_price, // X BankX / 1 USD
    xag_usd_price,
    bankx_amount
    );
    //recheck this
    require(xsd_amount<pid_controller.maxArbBurnAbove(), "BurnBankX");
    //approve collateral pool to burn your bankx
    BankX.pool_burn_from(msg.sender, bankx_amount);//burn bankx supplied
    XSD.pool_mint(msg.sender, xsd_amount);
    //XSDtoBankX swap
    Router.swapXSDForBankX(xsd_amount,msg.sender,slippage);
    last_update = block.timestamp;
    pid_controller.systemCalculations();
}
// mint principal amount of BankX after burning XSD
//below the peg
function burnXSD(uint256 XSD_amount,uint256 slippage) external nonReentrant {
    require(pause_arbitrage, "Arbitrage Paused");
    uint256 time_elapsed = block.timestamp - last_update;
    require(time_elapsed >= arbitrage_paused, "internal cooldown not passed");
    uint256 xag_usd_price = XSD.xag_usd_price();
    //XSD price has to be off peg by half a penny
    //change range to half a percent
    uint silver_price = (xag_usd_price*(1e4))/(311035); 
    require(XSD.xsd_price()<(silver_price - (silver_price/1e3)), "BurnXSD:ARBITRAGE ERROR");
    require(XSD_amount<=pid_controller.minArbBurnBelow(),"BurnXSD:Burnable limit");
    uint256 bankx_dollar_value_d18 = (XSD_amount*xag_usd_price)/(31103477); //31.1034768
    uint256 bankx_amount = (bankx_dollar_value_d18*(1e6))/XSD.bankx_price();
    // Move all external functions to the end
    //approve collateral pool to burn your xsd
    //transfer tokens to origin address if uXSD amount is positive
    if(XSD.totalSupply()>CollateralPool(payable(collateral_pool)).collat_XSD()){
        //burn XSD amount supplied
        XSD.pool_burn_from(msg.sender,XSD_amount);    }
    else{
        TransferHelper.safeTransferFrom(xsd_address, msg.sender,origin_address, XSD_amount);
    }
    BankX.pool_mint(msg.sender, bankx_amount);
    Router.swapBankXForXSD(bankx_amount,msg.sender,slippage);
    last_update = block.timestamp;
    pid_controller.systemCalculations();
}
function setArbitrageCooldown(uint sec) external {
    require(msg.sender == smartcontract_owner, "Only the owner can access this function");
    arbitrage_paused = block.timestamp + sec;
}
function pauseArbitrage() external {
    require(msg.sender == smartcontract_owner, "Only the owner can access this function");
    pause_arbitrage = !pause_arbitrage;
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

function resetAddresses(address _xsd_address,
        address _bankx_address,
        address _collateral_pool,
        address _router_address,
        address _pid_controller,
        address _xsd_pool,
        address _bankx_pool,
        address _origin_address,
        address _smartcontract_owner) external{
    require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
    require((_smartcontract_owner != address(0))
            && (_origin_address != address(0))
            && (_collateral_pool != address(0))
            && (_xsd_pool != address(0))
            && (_bankx_pool != address(0))
            && (_router_address != address(0))
            && (_xsd_address != address(0))
            && (_bankx_address != address(0))
            && (_pid_controller != address(0))
            , "Zero address detected");
        xsd_address = _xsd_address;
        XSD = XSDStablecoin(_xsd_address);
        bankx_address = _bankx_address;
        BankX = BankXToken(_bankx_address);
        collateral_pool = _collateral_pool;
        router_address = _router_address;
        Router = IRouter(_router_address);
        pid_address = _pid_controller;
        pid_controller = PIDController(_pid_controller);
        smartcontract_owner = _smartcontract_owner;
        origin_address = _origin_address;
        bankx_pool = _bankx_pool;
        xsd_pool = _xsd_pool;
}
}