// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error VasePrivateSale__NeedsMoreThanMinPurchaseAmount();
error VasePrivateSale__MoreThanMaxPurchaseAmount();
error VasePrivateSale_PurchaseFailed();
error VasePrivateSale__TransferFailed();
error VasePrivateSale__LockDurationNotReached();
error VasePrivateSale__VestingAmountReached();
error VasePrivateSale__VestingDurationNotReached();

contract VasePrivateSale is ReentrancyGuard, Ownable
{

    IERC20 public s_vaseToken;
    IERC20 public s_busdToken;


    address[] private allowedTokens;
    address[] private allowedTokensBusd;
    address[] private allowedTokenSale;
    address private s_busdAddress;

    // user struct
    struct User {
     uint256 monthlyPay;
     uint256 firstRelease;
     uint256 totalBusd;
     uint256 totalVase;
     uint256 runningVaseBalance;
     uint256 widCount;
    }
    
    // mapping of address=> user struct
    mapping(address=>User) private s_userTransactions;
    // total busd amount
    uint256 private s_totalBusd;

    // min purchase amount
    uint256 private s_minPurchaseAmount = 100 ether;

    // max purchase amount
    uint256 private s_maxPurchaseAmount = 10000 ether;

    // address to amount of busd 
    mapping(address=>uint256) private s_userTotalBusd;

    // address to amount of vase 
    mapping(address=>uint256) private s_userTotalVase;

    // address to monthly Vase
    mapping(address=>uint256) private s_userMonthlyVase;

    // address to initial Vase release
    mapping(address=>uint256) private s_userFirstVase;

    // address to count of buyers
    mapping(address=>bool) private s_buyers;

    // count of all buyers
    uint256 public allBuyers;

    // presale states
    enum PresaleState {Paused, Active, Stopped}

    PresaleState public status;

    event BuyVase(address indexed user, uint256 indexed busd);
    event PresaleVestingClaimed(address indexed user, uint256 indexed amount);

    // vesting schedule
    mapping(address => uint256) private s_vestingSchedule;

    //Locking period=>40 days after end of presale
    // mapping(uint256 => bool) private s_lockingPeriod;
    uint256 public s_lockingPeriod;


    constructor(address vaseToken, address busd)
    {
        s_vaseToken = IERC20(vaseToken);
        s_busdToken = IERC20(busd);
        allowedTokens.push(vaseToken);
        allowedTokensBusd.push(busd);
       
      
       
    }

    modifier checkAllowedTokensVase(address token)
    {
      address [] memory tempAllowed = allowedTokens;
        for(uint256 i = 0; i < tempAllowed.length; i++)
        {
            require(tempAllowed[i] == token, "Token Not Allowed");
                
        }
        
        _;
    }

    modifier checkAllowedTokensBusd(address token)
    {
      address [] memory tempAllowed = allowedTokensBusd;
        for(uint256 i = 0; i < tempAllowed.length; i++)
        {
            require(tempAllowed[i] == token, "Token Not Allowed");
                
        }
        
        _;
    }
     modifier moreThanMin(uint256 amount) {
        if (amount < s_minPurchaseAmount) {
            revert VasePrivateSale__NeedsMoreThanMinPurchaseAmount();
        }
        _;
    }

    modifier moreThanMax(uint256 amount) {
        if (amount > s_maxPurchaseAmount) {
            revert VasePrivateSale__MoreThanMaxPurchaseAmount();
        }
        _;
    }

    function buyVase(uint256 busdAmount, address busd) external
    checkAllowedTokensBusd(busd)
    moreThanMin(busdAmount)
    moreThanMax(busdAmount)
    nonReentrant
    {

        require(status == PresaleState.Active, "Presale not active");

        s_totalBusd += busdAmount;
        s_userTotalBusd[msg.sender] += busdAmount;

        // calculate quantity of vase user deserves
        // 100 busd=>1799 ether
        uint256 vaseQuantity = (busdAmount * 1799000000000000000000) / 100000000000000000000;
        s_userTotalVase[msg.sender] += vaseQuantity;

        // calculate first release
        uint256 initialRelease = (s_userTotalVase[msg.sender] * 28) / 100;


        // calculate monthly pay
        uint256 tempMonthlyPay = (s_userTotalVase[msg.sender] - initialRelease);
        uint256 userMonthlyPay = (tempMonthlyPay/18);

        // populate users struct
        User storage user = s_userTransactions[msg.sender];
        user.monthlyPay = userMonthlyPay;
        user.firstRelease = initialRelease;
        user.totalBusd = s_userTotalBusd[msg.sender];
        user.totalVase = s_userTotalVase[msg.sender];
        user.runningVaseBalance = tempMonthlyPay;
        user.widCount = 0;

        s_userMonthlyVase[msg.sender] = userMonthlyPay;
        s_userFirstVase[msg.sender] = initialRelease;

        if(!s_buyers[msg.sender])
        {
            
            allBuyers+=1;
            
        }
        s_buyers[msg.sender] = true;
        emit BuyVase(msg.sender, busdAmount);
        bool success = s_busdToken.transferFrom(msg.sender, address(this), busdAmount);
        if (!success) {
            revert VasePrivateSale_PurchaseFailed();
        }
        

        
    }

    function withdrawMonthlyVesting() external nonReentrant
    {
        require(status == PresaleState.Stopped, "Presale not ended");
        if(block.timestamp <  s_lockingPeriod)
        {
            revert VasePrivateSale__LockDurationNotReached();
        }
        if(block.timestamp <  s_vestingSchedule[msg.sender])
        {
            revert VasePrivateSale__VestingDurationNotReached();
        }

        User storage user = s_userTransactions[msg.sender];
        uint256 payout;

        if(user.widCount < 1){
            payout =  user.firstRelease;
        }else{
            payout =  user.monthlyPay;
            user.runningVaseBalance -= payout;
        }

        if(user.widCount >= 18)
        {
           revert VasePrivateSale__VestingAmountReached();
        }
        s_vestingSchedule[msg.sender] = block.timestamp + 31 days;
        user.widCount +=1;

        emit PresaleVestingClaimed(msg.sender, payout);
        bool success = s_vaseToken.transfer(msg.sender, payout);

        if (!success) {
            revert VasePrivateSale__TransferFailed();
        }
    }

     function getUserVaseBalance() external view returns(uint256){
       return s_userTotalVase[msg.sender];
    }
    
     function getUserBusdSpent() external view returns(uint256){
       return s_userTotalBusd[msg.sender];
    }

    function getUserMonthlyPay() external view returns(uint256){
       return s_userMonthlyVase[msg.sender];
    }

    function getUserFirstPay() external view returns(uint256){
       return s_userFirstVase[msg.sender];
    }

    function getBoughtStatus() external view returns(bool){
       return s_buyers[msg.sender];
    }

    function getTotalBusd() external view returns(uint256){
       return s_totalBusd;
    }

    function getAllBuyers() external view returns(uint256){
       return allBuyers;
    }

    function getSalesStatus() external view returns(PresaleState){
       return status;
    }

    function activateSales() external onlyOwner
    {
       status = PresaleState.Active;
    }

    function pauseSales() external onlyOwner
    {
       status = PresaleState.Paused;
    }
    function stopSales() external onlyOwner
    {
       status = PresaleState.Stopped;
       s_lockingPeriod = block.timestamp + 40 days;
    }

    function getWidCount() external view returns(uint256)
    {
       User storage user = s_userTransactions[msg.sender];
       return user.widCount;
    }

     function withdrawAdminBusd(uint256 amount) external onlyOwner nonReentrant {
        s_totalBusd -= amount;
        bool success = s_busdToken.transfer(msg.sender, amount);
        if (!success) {
            revert VasePrivateSale__TransferFailed();
        }
    }

    function withdrawAdminVase(uint256 amount) external onlyOwner nonReentrant {
        uint256 balAmount = s_vaseToken.balanceOf(address(this));
        balAmount -= amount;
        bool success = s_vaseToken.transfer(msg.sender, amount);
        if (!success) {
            revert VasePrivateSale__TransferFailed();
        }
    }

    //  owner withdraw other tokens
    function retrieveAltCoins(address token) public onlyOwner
    {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        bool success = IERC20(token).transfer(msg.sender, tokenBal);
            if (!success) {
                revert VasePrivateSale__TransferFailed();
            }

    }
 

    function getUserStruct() external view 
    returns(uint256, uint256, uint256, uint256, uint256, uint256)
    {
       User storage user = s_userTransactions[msg.sender];
       return (user.monthlyPay, user.firstRelease, user.totalBusd, user.totalVase, user.runningVaseBalance, user.widCount);
    }

    fallback() external payable
    {
        s_totalBusd += msg.value;
    }
    receive() external payable
    {
        s_totalBusd += msg.value;
    }


}