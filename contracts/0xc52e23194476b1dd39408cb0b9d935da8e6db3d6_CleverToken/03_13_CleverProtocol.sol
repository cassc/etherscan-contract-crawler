pragma solidity ^0.5.0;

import "hardhat/console.sol";

import "./TimedSwap.sol";
import "./CleverToken.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

/**
 * @title CleverProtocol
 * @dev Extension of Crowdsale contract that increases the price of tokens linearly in time.
 * Note that what should be provided to the constructor is the addresses of mintable token and the TimedSwap contract
 */
contract CleverProtocol is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    //state variables
    uint256 private openingTime;
    uint256 private closingTime;
    uint256 private _interval;
    uint256 public fortnight;
    bool public isLive;
    uint256 MAX_SUPPLY;
    
    //set DECIMALS
    uint DECIMALS = 1e18;
    
    // The token being managed
    CleverToken private _cleverToken;
    TimedSwap private _timedSwap; // just for loading isOpen() and openingTime/interval
    address payable adminWallet;
    
    // Track Cycles completed
    uint256 private cycles;
    
    //Store the cycle varaibles
    mapping(uint256 => uint256) private cycleAwards;
    mapping(uint256 => uint256) private cycleBonus;
    mapping(uint256 => uint256) private payoutPercent;
    
    //track the addresses being paid out on a cycle basis
    mapping(uint256 => bool) private cyclePaid;
    mapping(uint256 => bool) private ETHflushed;
    
    
    /*
     * @dev Constructor, sets the addresses of token and TimedSwap
    */
    constructor (CleverToken _token, address payable _adminWallet)  public {
        adminWallet = _adminWallet;
        
        //set the on-chain contract addresses
        _cleverToken = CleverToken(_token);
        
        //set the state variables
        fortnight = 14;
        MAX_SUPPLY = uint256(1_000_000_000_000).mul(DECIMALS);
        
        //init the # of cycles
        cycles = 0;
        
        //setFundsRequired & cycleAwards
        //-- setting these in the constructor function gurantees they will not be manipulated
        setCycleAwards();
        setCycleBonus();
        
        //for admin fee
        setThePayoutPercentage();
        
        /*just for testing*/
        //openingTime = now.sub(30 minutes);
        //closingTime = now;
        
        
    }
    function() payable external {
        //here simply to get forwarded funds from timedswap
    }

    function checkIsLive() public returns(bool){
        require(now > openingTime, "Timed Swap has not begun");

        if(!_timedSwap.hasClosed()){
            return false;
        }else{
            isLive = true;
            return isLive;    
        }
        
    }
    
    function setTimedSwap(address payable _TimedSwap) public onlyOwner{
        //inits the timedSwap contract
        _timedSwap = TimedSwap(_TimedSwap);
        openingTime = _timedSwap.openingTime();
        closingTime = _timedSwap.closingTime();
        _interval = _timedSwap.interval();
    }
    function timedSwap() public view returns(address){
        return address(_timedSwap);
    }
    
    function distributeCycleAward() public nonReentrant returns (uint256){
        //update isLive
        require(checkIsLive(), "Not live yet");
        
        //calculate cycle
        uint256 cycle = getCycle();
        require(cycle > 0, "cycle is not greater than 0");
        
        if (cyclePaid[cycle]){
            revert("cycle has been paid already");
        }
        
        uint256 in_application_cycle = cycle;
        
        //map the cycle -> range 
        if (cycle < 51) {
            in_application_cycle = cycle;
        } else if(cycle > 50 && cycle <101){
            in_application_cycle = 51;
        } else if (cycle > 100 && cycle <201) {
            in_application_cycle = 101;
        } else if (cycle > 201 && cycle < 401){
            in_application_cycle = 201;
        } else if (cycle > 400 && cycle < 601){
            in_application_cycle = 401;
        } else if (cycle > 600 && cycle < 801){
            in_application_cycle = 601;
        } else {
            in_application_cycle = 801;
        }
        
        //differentiation is made between cycle and in_application_cycle as the token will
        //only accept non repeating cycles, this is done to ensure only one payout is possible
        //per cycle

        uint256 cycleAwardPercentage = cycleAwards[in_application_cycle];
        uint256 cycleBonusPercentage = cycleBonus[in_application_cycle];

        //cycle award first, then the cycle bonus basedo newly established balance
        //call on the Coin to distribute set percentageo each wallet's holdings
        _cleverToken.distribute(cycle, cycleAwardPercentage, cycleBonusPercentage);

        
        
        
        //this check is made to prevent bricking the function in case of low balance amount within the contract
        if(address(this).balance >= 10000000) {
            //flush the ETH with the corresponding percentage for this cycle and update payment flag
            uint256 cyclepayoutPercent = getPayoutPercentage(in_application_cycle);

            adminWallet.transfer(address(this).balance.mul(cyclepayoutPercent).div(1e5));
            ETHflushed[cycle] = true;
        }

        //set this cycle to being paid
        cyclePaid[cycle] = true;
        
        //update cycles complete
        cycles = cycle;
        
        return cycles;
    }
    
    function getPayoutPercentage(uint256 _cycle) internal view returns(uint256){
        uint256 cycle;
        if( _cycle < 9){
            cycle = _cycle;
        } else{
            cycle = 8;
        }
        return payoutPercent[cycle];
    }
    
    /* returns floor of vision therefore giving the proper cycle #*/
    function getCycle() public view returns (uint256){
        //automatically determines if in isLive window
        require(isLive, "The swapping phase must have ended! -- no cycles to return");
        
        //auto reverts when day < 1st fortnight
        return ((getDay().sub(30)).div(fortnight));
    }
     
    function getDay() public view returns (uint256){
        require(now > openingTime, "Swap has not begun yet");
        return getElapsedTime().div(_interval); 
    }
    
    function getElapsedTime() public view returns (uint256){
        return block.timestamp.sub(openingTime);
    }
    function cyclesCompleted() public view returns (uint256) {
        return cycles;
    }
    function timeRestrictedWithdraw() public onlyOwner{
        require(cycles>8, "It is too soon to be able to withdraw remaining ETH");
        adminWallet.transfer(address(this).balance);
    }
    
    function token() public view returns(address){
        return address(_cleverToken);
    }
    function admin() public view returns(address payable){
        return adminWallet;
    }

    /*
    Called once on contract creation
    */
    function setThePayoutPercentage () internal {
        payoutPercent[1] = 45000;
        payoutPercent[2] = 40000;
        payoutPercent[3] = 35000;
        payoutPercent[4] = 30000;
        payoutPercent[5] = 20000;
        payoutPercent[6] = 10000;
        payoutPercent[7] = 5000;
        payoutPercent[8] = 4000;
    }
    function setCycleAwards() private {
        //0.01% as 10, 0.1% as 1e2, 1% as 1e3 ,10% as 1e4, 100% as 1e5
        cycleAwards[1] = 1e4;
        cycleAwards[2] = 5e3;
        cycleAwards[3] = 49e2;
        cycleAwards[4] = 48e2;
        cycleAwards[5] = 47e2;
        cycleAwards[6] = 46e2;
        cycleAwards[7] = 45e2;
        cycleAwards[8] = 44e2;
        cycleAwards[9] = 43e2;
        cycleAwards[10] = 42e2;
        cycleAwards[11] = 41e2;
        cycleAwards[12] = 40e2; //4.0%
        cycleAwards[13] = 39e2;
        cycleAwards[14] = 38e2;
        cycleAwards[15] = 37e2;
        cycleAwards[16] = 36e2;
        cycleAwards[17] = 35e2;
        cycleAwards[18] = 34e2;
        cycleAwards[19] = 33e2;
        cycleAwards[20] = 32e2;
        cycleAwards[21] = 31e2;
        cycleAwards[22] = 30e2;
        cycleAwards[23] = 29e2;
        cycleAwards[24] = 28e2;
        cycleAwards[25] = 27e2;
        cycleAwards[26] = 26e2;
        cycleAwards[27] = 25e2; //2.5%
        cycleAwards[28] = 24e2;
        cycleAwards[29] = 23e2;
        cycleAwards[30] = 22e2;
        cycleAwards[31] = 21e2;
        cycleAwards[32] = 20e2;
        cycleAwards[33] = 19e2;
        cycleAwards[34] = 18e2;
        cycleAwards[35] = 17e2;
        cycleAwards[36] = 16e2;
        cycleAwards[37] = 15e2;
        cycleAwards[38] = 14e2;
        cycleAwards[39] = 13e2;
        cycleAwards[40] = 12e2;
        cycleAwards[41] = 11e2;
        cycleAwards[42] = 10e2; //1%
        cycleAwards[43] = 950;
        cycleAwards[44] = 900;
        cycleAwards[45] = 850;
        cycleAwards[46] = 800;
        cycleAwards[47] = 750;
        cycleAwards[48] = 700;
        cycleAwards[49] = 650;
        cycleAwards[50] = 600;
        cycleAwards[51] = 500;
        cycleAwards[101] = 250;
        cycleAwards[201] = 200;
        cycleAwards[401] = 150;
        cycleAwards[601] = 100;
        cycleAwards[801] = 50; //%0.05%
    }
    function setCycleBonus() private {
        //0.01% as 10, 0.1% as 1e2, 1% as 1e3 ,10% as 1e4, 100% as 1e5
        cycleBonus[1] = 1e3;
        cycleBonus[2] = 1e3;
        cycleBonus[3] = 1e3;
        cycleBonus[4] = 1e3;
        cycleBonus[5] = 1e3;
        cycleBonus[6] = 1e3;
        cycleBonus[7] = 1e3;
        cycleBonus[8] = 1e3;
        cycleBonus[9] = 0;
        cycleBonus[10] = 0;
        cycleBonus[11] = 0;
        cycleBonus[12] = 0; 
        cycleBonus[13] = 0;
        cycleBonus[14] = 0;
        cycleBonus[15] = 0;
        cycleBonus[16] = 1e3;
        cycleBonus[17] = 0;
        cycleBonus[18] = 0;
        cycleBonus[19] = 0;
        cycleBonus[20] = 0;
        cycleBonus[21] = 0;
        cycleBonus[22] = 0;
        cycleBonus[23] = 0;
        cycleBonus[24] = 1e3;
        cycleBonus[25] = 0;
        cycleBonus[26] = 0;
        cycleBonus[27] = 0;
        cycleBonus[28] = 0;
        cycleBonus[29] = 0;
        cycleBonus[30] = 0;
        cycleBonus[31] = 0;
        cycleBonus[32] = 1e3;
        cycleBonus[33] = 0;
        cycleBonus[34] = 0;
        cycleBonus[35] = 0;
        cycleBonus[36] = 0;
        cycleBonus[37] = 0;
        cycleBonus[38] = 0;
        cycleBonus[39] = 0;
        cycleBonus[40] = 1e3;
        cycleBonus[41] = 0;
        cycleBonus[42] = 0; //1%
        cycleBonus[43] = 0;
        cycleBonus[44] = 0;
        cycleBonus[45] = 0;
        cycleBonus[46] = 0;
        cycleBonus[47] = 0;
        cycleBonus[48] = 1e3;
        cycleBonus[49] = 0;
        cycleBonus[50] = 0;
        cycleBonus[51] = 0;
        cycleBonus[101] = 0;
        cycleBonus[201] = 0;
        cycleBonus[401] = 0;
        cycleBonus[601] = 0;
        cycleBonus[801] = 0; 

    }
}