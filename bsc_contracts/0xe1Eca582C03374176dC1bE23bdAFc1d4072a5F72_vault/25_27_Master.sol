// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//imports for liquitity interactions
import "./IUniswapV2Router02.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';


//local imports
import "./AMT.sol";
import "./LIQUIDITYAMT.sol";

//Standar imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//Timelock import
import "@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol";

contract liqLocker is TokenTimelock{
    using SafeERC20 for IERC20;
    Master masterContract;
    IERC20 payToken;
    IERC20 liqToken;
    constructor(
        IERC20 token_,
        IERC20 payToken_,
        IERC20 liqToken_,
        address beneficiary_,
        uint256 releaseTime_,
        address masterContract_
        )
        TokenTimelock(token_,beneficiary_,releaseTime_){
            masterContract = Master(masterContract_);
            payToken=payToken_;
            liqToken=liqToken_;
        }

    function charge(uint256 snapId) public{
        masterContract.liqCharge(snapId);
        payToken.transfer(beneficiary(),payToken.balanceOf(address(this)));
    }

    function release() public virtual override{
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(address(masterContract), amount);
        liqToken.transfer(beneficiary(),amount);
    }
}


contract Master is Ownable{

    //Data variables

    address addrLiqLocker;
    //Control variables
    bool liqLocked = false;

    //General variables
    AMT masterCoin;
    IERC20 payCoin;
	IERC20 buyCoin;
    LIQUIDITYAMT liqToken;
    IERC20 externalLiqToken;
    address addrRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02 liqRouter = IUniswapV2Router02(addrRouter);
    IUniswapV2Factory liqFactory;
    address vault;
    address liqPool;
	address payerWallet;  // wallet which makes payments	
	

    mapping(uint256 => uint256) public pays; // snapId -> corresponding amount payed on that snapshot, registry of the amount of payToken payed on specific snapshot
    mapping(uint256 => uint256) public liqPays; // snapId -> corresponding amount payd on that snapshot to liq providers
    mapping(address => mapping(uint256 => bool)) public alreadyCharged; // Registry of already charged by address for normal pays
    mapping (address => mapping(uint256 => bool)) public liqAlreadyCharged; //Registry of already charged by address for liquidity providers

    constructor(address _masterCoin, address _payCoin, address _buyCoin, address _vault, address _liqToken, address _payerWallet){
        masterCoin = AMT(_masterCoin);
        payCoin = IERC20(_payCoin);
		buyCoin = IERC20(_buyCoin);
        liqToken = LIQUIDITYAMT(_liqToken);
        //liqFactory = IUniswapV2Factory(liqRouter.factory());
        //externalLiqToken = IERC20(liqFactory.createPair(_masterCoin, _payCoin));
        vault = _vault;
        //liqPool = address(externalLiqToken);
        //payCoin.approve(addrRouter, 99999999999999999999*(10**18));
        //masterCoin.approve(addrRouter, 99999999999999999999*(10**18));
		payerWallet = _payerWallet;
    }
	
	// Extended approve function	
	function extendApprove(uint256 amount) public onlyOwner {
		buyCoin.approve(addrRouter, amount);
        masterCoin.approve(addrRouter, amount);		
	}
	
	// Change payer wallet
	function setPayerWallet(address newPayerWallet) public onlyOwner{
		payerWallet = newPayerWallet;
	}

    //View functions
    function addressLiquidityPool() public view returns(address){
        return liqPool;
    }

    function addressLiquidityLocker() public view returns(address){
        return addrLiqLocker;
    }

    //Pays the rent and shares between the snapshot pay and the lucros vault at the rate determined by vaultParticipation
    function payRent(uint256 amount, uint256 vaultParticipation) public{

        // General checks
        require(payCoin.balanceOf(msg.sender) >= amount, "insuficient ammount");
        require (vaultParticipation > 0, "vaultParticipation cannot be zero");
        require(vaultParticipation <= 100, "vaultParticipation cannot be higher than 100");
        require(amount > 100, "amount to small");
		require(msg.sender == payerWallet, "Only payer wallet can pay");

        //Pays definition to every part

        //The amount to share to the vault
        uint256 toVault = (amount * vaultParticipation)/100;

        //The amount to share to the Liquity pool
        uint256 toLiqProviders = ((amount - toVault)*masterCoin.balanceOf(liqPool))/masterCoin.totalSupply(); 

        //The amount to share to AMT holders
        uint256 toPay = amount - toVault - toLiqProviders;

        //Withdrawl of funds from payer
        payCoin.transferFrom(msg.sender,address(this),amount-toVault);
        payCoin.transferFrom(msg.sender, vault, toVault);
        uint256 snap = masterCoin.snapshot();
        uint256 liqSnap = liqToken.snapshot();
        pays[snap] = toPay;
        liqPays[liqSnap] = toLiqProviders;
    }

    //Charge function for AMT holders
    function charge(uint256 snapId) public returns(uint256) { //We will need the return statement for the charging from the vault
        require(alreadyCharged[msg.sender][snapId] == false, "already charged");
        require(masterCoin.balanceOfAt(msg.sender,snapId)>0,"nothing to charge");
        alreadyCharged[msg.sender][snapId] = true;
        uint256 toPay = (pays[snapId]*masterCoin.balanceOfAt(msg.sender,snapId))/(masterCoin.totalSupplyAt(snapId)-masterCoin.balanceOfAt(liqPool,snapId));
        payCoin.transfer(msg.sender,toPay);
        return toPay;
    }

    //Charge function for liqProviders
    function liqCharge(uint256 snapId) public {
        require(liqAlreadyCharged[msg.sender][snapId] == false, "already charged");
        require(liqToken.balanceOfAt(msg.sender,snapId)>0, "nothing to charge");
        liqAlreadyCharged[msg.sender][snapId] = true;
        payCoin.transfer(msg.sender,(liqPays[snapId]*liqToken.balanceOfAt(msg.sender,snapId))/liqToken.totalSupplyAt(snapId));
    }

    //Locking Liquidity - Master add liquidity provider function. Only executed once
    function addLiquidityLocking(uint256 amountMasterCoin, uint256 amountPayCoin) public onlyOwner {
        //Transaction variables
        uint256 posibleVariation = 2; //Used to calculate minA and minB, its in %
        uint256 milisecsToValidate = 60000; // Used to pass deadline as current timestamp plus 1 minute

        //Check requirements
        require(liqLocked == false, "already locked");
        require(masterCoin.balanceOf(msg.sender) > amountMasterCoin, "Not enougth AMT");
        require(payCoin.balanceOf(msg.sender) > amountPayCoin, "Not enougth BBTC");
        require(amountMasterCoin*(100-posibleVariation) > 100, "to small"); //Checks to avoid extremly small balances transactions resulting on 0 transfer
        require(amountPayCoin*(100-posibleVariation) > 100, "to small"); ////Checks to avoid extremly small balances transactions resulting on 0 transfer

        liqLocked = true;
        masterCoin.transferFrom(msg.sender,address(this),amountMasterCoin);
        payCoin.transferFrom(msg.sender,address(this),amountPayCoin);
        uint256 amountLiquidityCreated;
        uint256 amountMasterToLiq;
        uint256 amountPayToLiq;
        (amountMasterToLiq,amountPayToLiq,amountLiquidityCreated) = liqRouter.addLiquidity(
            address(masterCoin),
            address(payCoin),
            amountMasterCoin,
            amountPayCoin,
            (amountMasterCoin*(100-posibleVariation))/100,
            (amountPayCoin*(100-posibleVariation))/100,
            address(this),
            block.timestamp + milisecsToValidate
        );

        //Deploy of timelock
        uint256 lockingTime = 60*40; // locking time in milisecs, actually 40 minutes. Two years = 60*60*24*365
        liqLocker contractLiqLocker = new liqLocker(
            externalLiqToken,
            payCoin,
            liqToken,
            msg.sender,
            block.timestamp + lockingTime,
            address(this)
        );
        externalLiqToken.transfer(address(contractLiqLocker),amountLiquidityCreated);
        liqToken.mint(address(contractLiqLocker), amountLiquidityCreated);
        masterCoin.transfer(msg.sender,amountMasterCoin-amountMasterToLiq);
        payCoin.transfer(msg.sender,amountPayCoin-amountPayToLiq);
        addrLiqLocker = address(contractLiqLocker);
    }

    //Master add liquidity provider function
    function addLiquidity(uint256 amountMasterCoin, uint256 amountPayCoin) public {

        //Transaction variables
        uint256 posibleVariation = 2; //Used to calculate minA and minB, its in %
        uint256 milisecsToValidate = 60000; // Used to pass deadline as current timestamp plus 1 minute

        //Check requirements
        require(masterCoin.balanceOf(msg.sender) > amountMasterCoin, "Not enougth AMT");
        require(payCoin.balanceOf(msg.sender) > amountPayCoin, "Not enougth BBTC");
        require(amountMasterCoin*(100-posibleVariation) > 100, "to small"); //Checks to avoid extremly small balances transactions resulting on 0 transfer
        require(amountPayCoin*(100-posibleVariation) > 100, "to small"); ////Checks to avoid extremly small balances transactions resulting on 0 transfer

        masterCoin.transferFrom(msg.sender,address(this),amountMasterCoin);
        payCoin.transferFrom(msg.sender,address(this),amountPayCoin);
        uint256 amountLiquidityCreated;
        uint256 amountMasterToLiq;
        uint256 amountPayToLiq;
        (amountMasterToLiq,amountPayToLiq,amountLiquidityCreated) = liqRouter.addLiquidity(
            address(masterCoin),
            address(payCoin),
            amountMasterCoin,
            amountPayCoin,
            (amountMasterCoin*(100-posibleVariation))/100,
            (amountPayCoin*(100-posibleVariation))/100,
            address(this),
            block.timestamp + milisecsToValidate
        );
        liqToken.mint(msg.sender, amountLiquidityCreated);
        masterCoin.transfer(msg.sender,amountMasterCoin-amountMasterToLiq);
        payCoin.transfer(msg.sender,amountPayCoin-amountPayToLiq);
    }

    //Master remove liquidity provider function
    function removeLiquidity(uint256 amount) public {

        //Check requirements
        require(liqToken.balanceOf(msg.sender) >= amount, "Not enougth liqAMT");

        //Transaction variables
        uint256 milisecsToValidate = 60000; // Used to pass deadline as current timestamp plus 1 minute
        
        uint256 amountMasterFromLiq;
        uint256 amountPayFromLiq;

        externalLiqToken.approve(addrRouter,amount);
        
        (amountMasterFromLiq, amountPayFromLiq) = liqRouter.removeLiquidity(
            address(masterCoin),
            address(payCoin),
            amount,
            0,
            0,
            address(this),
            block.timestamp + milisecsToValidate
        );
        liqToken.burnFrom(msg.sender,amount);
        masterCoin.transfer(msg.sender,amountMasterFromLiq);
        payCoin.transfer(msg.sender,amountPayFromLiq);
    }
	// Minting function for AMT
    function mintMaster(address account, uint256 amount) public onlyOwner(){
        masterCoin.mint(account, amount);   
    }

}