// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Parapad.sol";

contract ParapadV2 is Ownable {
    using SafeERC20 for IERC20;

    address public usdtAddress;
    address public paradoxAddress;

    IERC20 internal para;
    IERC20 internal usdt;

    Parapad public parapadV1;

    mapping(address => bool) public _claimed;

    uint256 internal constant PARADOX_DECIMALS = 10 ** 18;
    uint256 internal constant USDT_DECIMALS = 10 ** 6;

    uint256 internal constant EXCHANGE_RATE = 3;
    uint256 internal constant EXCHANGE_RATE_DENOMINATOR = 100;

    uint256 internal constant MONTH = 4 weeks;

    /** MAXIMUM OF $1000 per person */
    uint256 internal constant MAX_AMOUNT = 1000 * USDT_DECIMALS;

    mapping(address => Lock) public locks;
    
    mapping(address => bool)public islockedOnV2;

    struct Lock {
        uint256 total;
        uint256 paid;
        uint256 debt;
        uint256 startTime;
    }

    constructor(address _usdt, address _paradox, address _parapadV1) {
        usdtAddress = _usdt;
        usdt = IERC20(_usdt);

        paradoxAddress = _paradox;
        para = IERC20(_paradox);
        parapadV1 = Parapad(_parapadV1);
    }

    function buyParadox(uint256 amount) external {
        
        // Check if user already claimed on ParapadV1 or ParapadV2
        bool claimed = islockedOnV2[msg.sender] ? _claimed[msg.sender] : parapadV1._claimed(msg.sender);
        
        require(!claimed, "Limit reached");

        require(amount <= MAX_AMOUNT, "Wrong amount");
        // get exchange rate to para
        uint256 rate = (amount * EXCHANGE_RATE_DENOMINATOR * PARADOX_DECIMALS) /
            (USDT_DECIMALS * EXCHANGE_RATE);

        require(rate <= para.balanceOf(address(this)), "Low balance");
        // give user 20% now
        uint256 rateNow = (rate * 20) / 100;
        
        uint256 vestingRate = rate - rateNow;

        Lock memory userLock;
        
        // Getting userLock from ParapadV2 or ParapadV1 if user triggers function for the first time
       if(islockedOnV2[msg.sender]){
              userLock = locks[msg.sender];
        }else{
            (uint256 total, uint256 paid, uint256 debt, uint256 startTime) = parapadV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
        }

        if (userLock.total == 0) {
            // new claim
            locks[msg.sender] = Lock({
                total: vestingRate,
                paid: amount,
                debt: 0,
                startTime: block.timestamp
            });

            if (amount == MAX_AMOUNT) _claimed[msg.sender] = true;

        } else {
            // at this point, the user still has some pending amount they can claim
            require(amount +  userLock.paid <= MAX_AMOUNT, "Too Much");

            userLock.total += vestingRate;

            if (amount + userLock.paid == MAX_AMOUNT) _claimed[msg.sender] = true;

            userLock.paid += amount;
        }
        
        // Save userLock info to the storage
        locks[msg.sender] = userLock;

        // Update mapping to identify where to fetch info about user lock
        if(!islockedOnV2[msg.sender]){
          islockedOnV2[msg.sender] = true;
        }

        usdt.safeTransferFrom(msg.sender, address(this), amount);
        para.safeTransfer(msg.sender, rateNow);
    }

    function pendingVestedParadox(
        address _user
    ) external view returns (uint256) {
          Lock memory userLock;

         if(islockedOnV2[_user]){
              userLock = locks[_user];
         }else{
            (uint256 total, uint256 paid, uint256 debt, uint256 startTime) = parapadV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
         }

        uint256 monthsPassed = (block.timestamp - userLock.startTime) / 4 weeks;
        /** @notice 5% released each MONTH after 2 MONTHs */
        uint256 monthlyRelease =  userLock.total + (userLock.total * 20)/100;

        uint256 release;
        for (uint256 i = 0; i < monthsPassed; i++) {
            if (i >= 2) {
                if (release >= userLock.total) {
                    release = userLock.total;
                    break;
                }
                release += monthlyRelease;
            }
        }

        return release - userLock.debt;
    }

    function claimVestedParadox() external {
         Lock memory userLock;

         if(islockedOnV2[msg.sender]){
              userLock = locks[msg.sender];
         }else{
            (uint256 total, uint256 paid, uint256 debt, uint256 startTime) = parapadV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
         }

        require(userLock.total > userLock.debt, "Vesting Complete");

        uint256 monthsPassed = (block.timestamp - userLock.startTime) / 4 weeks;
        
        // All lock including 20% which user already got buyingParadox
        uint256 totalLock = userLock.total + (userLock.total * 20)/100;
        /** @notice 5% released each MONTH after 2 MONTHs */
        uint256 monthlyRelease = (totalLock * 5) / 100;

        uint256 release;
        for (uint256 i = 0; i < monthsPassed; i++) {
            if (i >= 2) {
                if (release >= userLock.total) {
                    release = userLock.total;
                    break;
                }
                release += monthlyRelease;
            }
        }
        uint256 reward = release - userLock.debt;
        userLock.debt += reward;
        
        // Save userLock info to the storage
        locks[msg.sender] = userLock;      
        
        // Update mapping to identify where to fetch info about user lock
        if(!islockedOnV2[msg.sender]){
          islockedOnV2[msg.sender] = true;
        }

        para.transfer(msg.sender, reward);
    }

    function getUserNextClaimTimestamp(address _user) external view returns(uint256){
         Lock memory userLock;

         if(islockedOnV2[_user]){
              userLock = locks[_user];
         }else{
            (uint256 total, uint256 paid, uint256 debt, uint256 startTime) = parapadV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
         }
        
        uint256 monthsPassed = (block.timestamp - userLock.startTime) / 4 weeks;
        
        uint256 nextClaimTimestamp = monthsPassed + MONTH;

         return nextClaimTimestamp - block.timestamp;
    }

     function getUserClaimed(address _user) external view returns(uint256){
         Lock memory userLock;

         if(islockedOnV2[_user]){
              userLock = locks[_user];
         }else{
            (uint256 total, uint256 paid, uint256 debt, uint256 startTime) = parapadV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
         }

         return userLock.debt;
    }

     function getUserLeftToClaim(address _user) external view returns(uint256){
         Lock memory userLock;

         if(islockedOnV2[_user]){
              userLock = locks[_user];
         }else{
            (uint256 total, uint256 paid, uint256 debt, uint256 startTime) = parapadV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
         }

         return userLock.total - userLock.debt;
    }

    function withdrawTether(address _destination) external onlyOwner {
        usdt.safeTransfer(_destination, usdt.balanceOf(address(this)));
    }

    function updateParadoxV1(address _paradoxV1) external onlyOwner {
        parapadV1 = Parapad(_paradoxV1);
    }

     function updateParadoxAddress(address _paradox) external onlyOwner {
        para = IERC20(_paradox);
    }

     function updateUsdtAddress(address _usdt) external onlyOwner {
        usdt = IERC20(_usdt);
    }

    /** @notice EMERGENCY FUNCTIONS */
    function updateClaimed(address _user) external onlyOwner {
        _claimed[_user] = !_claimed[_user];
    }

    function updateUserLock(
        address _user,
        uint256 _total,
        uint256 _paid,
        uint256 _startTime
    ) external onlyOwner {
        Lock storage lock = locks[_user];
        lock.total = _total;
        lock.paid = _paid;
        lock.startTime = _startTime;
    }

    function withdrawETH() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function withdrawParadox() external onlyOwner {
        para.safeTransfer(msg.sender, para.balanceOf(address(this)));
    }
}