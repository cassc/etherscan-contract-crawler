// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './Interfaces/IRouter.sol';
import '../Oracle/PIDController.sol';
import '../XSD/XSDStablecoin.sol';
import '../XSD/Pools/RewardManager.sol';
import './BankXLibrary.sol';
import '../Utils/Initializable.sol';
import '../ERC20/IWETH.sol';
import '../XSD/Pools/XSDWETHpool.sol';
import '../XSD/Pools/BankXWETHpool.sol';
//swap first
//then burn 10% using different function maybe
//recalculate price
// do not burn uXSD if there is a deficit
contract Router is IRouter, Initializable {

    address public WETH;
    address public collateral_pool_address;
    address public XSDWETH_pool_address;
    address public BankXWETH_pool_address;
    address public reward_manager_address;
    address public bankx_address;
    address public xsd_address;
    address public treasury;
    address public smartcontract_owner;
    uint public last_called;
    uint public pid_cooldown;
    bool public swap_paused;
    bool public liquidity_paused;
    XSDStablecoin private XSD;
    RewardManager private reward_manager;
    PIDController private pid_controller;
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BankXRouter: EXPIRED');
        _;
    }

     // called once by the smart contract owner at time of deployment
     // sets the pool&token addresses
    function initialize(address _bankx_address, address _xsd_address,address _XSDWETH_pool, address _BankXWETH_pool,address _collateral_pool,address _reward_manager_address,address _pid_address,uint _pid_cooldown,address _treasury, address _smartcontract_owner,address _WETH) public initializer {
        require((_bankx_address != address(0))
        &&(_xsd_address != address(0))
        &&(_XSDWETH_pool != address(0))
        &&(_BankXWETH_pool != address(0))
        &&(_collateral_pool != address(0))
        &&(_treasury != address(0))
        &&(_pid_address != address(0))
        &&(_pid_cooldown != 0)
        &&(_smartcontract_owner != address(0))
        &&(_WETH != address(0)), "Zero address detected");
        bankx_address = _bankx_address;
        xsd_address = _xsd_address;
        XSDWETH_pool_address = _XSDWETH_pool;
        BankXWETH_pool_address = _BankXWETH_pool;
        collateral_pool_address = _collateral_pool;
        reward_manager_address = _reward_manager_address;
        reward_manager = RewardManager(_reward_manager_address);
        pid_controller = PIDController(_pid_address);
        pid_cooldown = _pid_cooldown;
        XSD = XSDStablecoin(_xsd_address);
        treasury = _treasury;
        WETH = _WETH;
        smartcontract_owner = _smartcontract_owner;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    // add a variable that keeps track of 10% swap burn.
    // **** ADD LIQUIDITY ****
    //creator may add XSD/BankX to their respective pools via this function
    function creatorProvideLiquidity(address pool) internal  {
        if(pool == XSDWETH_pool_address){
            reward_manager.creatorProvideXSDLiquidity();
        }
        else if(pool == BankXWETH_pool_address){
            reward_manager.creatorProvideBankXLiquidity();
        }
    }

    function userProvideLiquidity(address pool, address sender) internal  {
        if(pool == XSDWETH_pool_address){
            reward_manager.userProvideXSDLiquidity(sender);
        }
        else if(pool == BankXWETH_pool_address){
            reward_manager.userProvideBankXLiquidity(sender);
        }
    }

    function refreshPID() internal{
        if(block.timestamp>(last_called+pid_cooldown)){
            pid_controller.systemCalculations();
            last_called = block.timestamp;
        }
    }

    function creatorAddLiquidityTokens(
        address tokenB,
        uint amountB
    ) public override {
        require(msg.sender == treasury || msg.sender == smartcontract_owner, "ONLY TREASURY & SMARTCONTRACT OWNER");
        require(tokenB == xsd_address || tokenB == bankx_address, "token address is invalid");
        require(amountB>0, "Please enter a valid amount");
        if(tokenB == xsd_address){
            TransferHelper.safeTransferFrom(tokenB, msg.sender, XSDWETH_pool_address, amountB);
            reward_manager.creatorProvideXSDLiquidity();
    }
    else if(tokenB == bankx_address){
        TransferHelper.safeTransferFrom(tokenB, msg.sender, BankXWETH_pool_address, amountB);
        reward_manager.creatorProvideBankXLiquidity();
    }
    }

    function creatorAddLiquidityETH(
        address pool
    ) external payable override {
        require(msg.sender == treasury || msg.sender == smartcontract_owner, "ONLY TREASURY & SMARTCONTRACT OWNER");
        require(pool == XSDWETH_pool_address || pool == BankXWETH_pool_address, "Pool address is invalid");
        require(msg.value>0,"Please enter a valid amount");
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pool, msg.value));
        creatorProvideLiquidity(pool);
    }

    function userAddLiquidityETH(
        address pool
    ) external  payable override{
        require(pool == XSDWETH_pool_address || pool == BankXWETH_pool_address || pool == collateral_pool_address, "Pool address is not valid");
        require(!liquidity_paused, "Liquidity providing has been paused");
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pool, msg.value));
        if(pool==collateral_pool_address){
            reward_manager.userProvideCollatPoolLiquidity(msg.sender, msg.value);
        }
        else{
            userProvideLiquidity(pool, msg.sender);
        }
    }

    //this redemption only applies to the liquidity pools
    //collateral pool redemption happens in the same contract
    function userRedeemLiquidity(address pool) external override {
        if(pool == XSDWETH_pool_address){
            reward_manager.LiquidityRedemption(pool,msg.sender);
        }
        else if(pool == BankXWETH_pool_address){
            reward_manager.LiquidityRedemption(pool,msg.sender);
        }
        else if (pool == collateral_pool_address){
            reward_manager.LiquidityRedemption(pool,msg.sender);
        }
    }

    // **** SWAP ****
    /* 
    10% of swap amount is burnt after swapping
    swap amount can only burnt from the liquidity pools
    */
    // PID controller is called every hour to update calculations.
    function swapETHForXSD(uint amountOut, address to)
        external
        payable
        override
    {
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IXSDWETHpool(XSDWETH_pool_address).getReserves();
        uint amounts = BankXLibrary.quote(msg.value, reserveB, reserveA);
        require(amounts >= amountOut, 'BankXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(XSDWETH_pool_address, msg.value));
        IXSDWETHpool(XSDWETH_pool_address).swap(amountOut, 0, to);
        refreshPID();
    }
    //approve router to use users xsd
    //burn 10% of XSD when uXSD is +ve
    function swapXSDForETH(uint amountOut, uint amountInMax, address to)
        external
        override
    {
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IXSDWETHpool(XSDWETH_pool_address).getReserves();
        uint amounts = BankXLibrary.quote(amountOut, reserveB, reserveA);
        require(amounts <= amountInMax, 'BankXRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            xsd_address, msg.sender, XSDWETH_pool_address, amountInMax
        );
        XSDWETHpool(XSDWETH_pool_address).swap(0, amountOut, address(this));
        //function will fail if conditions are not met
        //XSDWETHpool(XSDWETH_pool_address).flush();
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
        //burn xsd here 
        //value of xsd liquidity pool has to be greater than 20% of the total xsd value
        if(XSD.totalSupply()-CollateralPool(payable(collateral_pool_address)).collat_XSD()>amountOut/10 && !pid_controller.bucket1()){
            XSD.burnpoolXSD(amountInMax/10);
        }
        refreshPID();
    }

    function swapETHForBankX(uint amountOut, address to)
        external
        override
        payable
    {
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IBankXWETHpool(BankXWETH_pool_address).getReserves();
        uint amounts = BankXLibrary.quote(msg.value, reserveB, reserveA);
        require(amounts >= amountOut, 'BankXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(BankXWETH_pool_address, msg.value));
        IBankXWETHpool(BankXWETH_pool_address).swap(amountOut, 0, to);
        refreshPID();
    }
    //approve the router to access users bankx
    //if bankx is inflationary burn 10% of tokens swapped into pool
    function swapBankXForETH(uint amountOut, uint amountInMax, address to)
        external
        override
    {
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IBankXWETHpool(BankXWETH_pool_address).getReserves();
        uint amounts = BankXLibrary.quote(amountOut, reserveB, reserveA);
        require(amounts <= amountInMax, 'BankXRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            bankx_address, msg.sender, BankXWETH_pool_address, amountInMax
        );
        IBankXWETHpool(BankXWETH_pool_address).swap(0,amountOut, address(this));
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
        if((BankXToken(bankx_address).totalSupply() - amountOut/10)>BankXToken(bankx_address).genesis_supply()){
            BankXToken(bankx_address).burnpoolBankX(amountOut/10);
        }
        refreshPID();
    }

    //swap for xsd for eth first
    //swap eth for bankx
    // release bankx to user
    function swapXSDForBankX(uint XSD_amount,address sender,uint256 slippage)
        external 
        override
    {
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IXSDWETHpool(XSDWETH_pool_address).getReserves();
        (uint reserve1, uint reserve2, ) = IBankXWETHpool(BankXWETH_pool_address).getReserves();
        uint ethamount = BankXLibrary.quote(XSD_amount, reserveA, reserveB);
        ethamount = ethamount - ((ethamount*slippage)/100);
        uint bankxamount = BankXLibrary.quote(ethamount, reserve2, reserve1);
        bankxamount = bankxamount - ((bankxamount*slippage)/100);
        TransferHelper.safeTransferFrom(
            xsd_address, sender, XSDWETH_pool_address, XSD_amount
        );
        IXSDWETHpool(XSDWETH_pool_address).swap(0, ethamount, BankXWETH_pool_address);
        IBankXWETHpool(BankXWETH_pool_address).swap(bankxamount,0,sender);
    }

    //swap bankx for eth 
    //swap eth for xsd
    //release xsd to user
    function swapBankXForXSD(uint bankx_amount, address sender, uint256 slippage)
        external
        override
    {
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IXSDWETHpool(XSDWETH_pool_address).getReserves();
        (uint reserve1, uint reserve2, ) = IBankXWETHpool(BankXWETH_pool_address).getReserves();
        uint ethamount = BankXLibrary.quote(bankx_amount, reserve1, reserve2);
        ethamount = ethamount - ((ethamount*slippage)/100);
        uint xsdamount = BankXLibrary.quote(ethamount, reserveB, reserveA);
        xsdamount = xsdamount - ((xsdamount*slippage)/100);
        TransferHelper.safeTransferFrom(
            bankx_address, sender, BankXWETH_pool_address, bankx_amount
        );
        IBankXWETHpool(BankXWETH_pool_address).swap(0, ethamount, XSDWETH_pool_address);
        IXSDWETHpool(XSDWETH_pool_address).swap(xsdamount,0,sender);
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

    //Need to setter function for PID cooldown
    
    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure  returns (uint amountB) {
        return BankXLibrary.quote(amountA, reserveA, reserveB);
    }

    function pauseSwaps() external {
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        swap_paused = !swap_paused;
    }

    function pauseLiquidity() external {
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        liquidity_paused = !liquidity_paused;
    }
    
    
    function setBankXAddress(address _bankx_address) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        bankx_address = _bankx_address;
    }

    function setXSDAddress(address _xsd_address) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        xsd_address = _xsd_address;
    }

    function setXSDPoolAddress(address _XSDWETH_pool) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        XSDWETH_pool_address = _XSDWETH_pool;
    }

    function setBankXPoolAddress(address _BankXWETH_pool) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        BankXWETH_pool_address = _BankXWETH_pool;
    }

    function setCollateralPool(address _collateral_pool) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        collateral_pool_address = _collateral_pool;
    }

    function setRewardManager(address _reward_manager_address) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        reward_manager_address = _reward_manager_address;
        reward_manager = RewardManager(_reward_manager_address);
    }

    function setPIDController(address _pid_address, uint _pid_cooldown) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        pid_controller = PIDController(_pid_address);
        pid_cooldown = _pid_cooldown;
    }
}