// SPDX-License-Identifier: MIT
/*  
                                                                              
                                             .******,.                                            
                                   &@@@@@@@@@@@@@@@@@@@@@@@@@@&                                 
                             ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                           
                         *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                       
                      #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/                    
                    @@@@@@@@@@@@@@@@@@@@@@@%.        .&@@@@@@@@@@@@@@@@@@@@@@@                  
                 ,@@@@@@@@@@@@@@@@@@(                                                           
               [email protected]@@@@@@@@@@@@@@@                                                                
              @@@@@@@@@@@@@@@.                                                                  
             @@@@@@@@@@@@@@                                                                     
           *@@@@@@@@@@@@@              *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
          [email protected]@@@@@@@@@@@%          /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         
          @@@@@@@@@@@@/         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        
         @@@@@@@@@@@@&         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*       
         @@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       
         @@@@@@@@@@@@                                                                           
        *@@@@@@@@@@@(                                                                           
        [email protected]@@@@@@@@@@&                                                                           
         @@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       
         @@@@@@@@@@@@,        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%       
          @@@@@@@@@@@@         *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        
          %@@@@@@@@@@@@          /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*        
           @@@@@@@@@@@@@&            #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%         
            &@@@@@@@@@@@@@,                                            [email protected]@@@@@@@@@@@@*          
             [email protected]@@@@@@@@@@@@@/                                        ,@@@@@@@@@@@@@@            
               @@@@@@@@@@@@@@@@.                                   @@@@@@@@@@@@@@@&             
                 @@@@@@@@@@@@@@@@@@                            @@@@@@@@@@@@@@@@@@               
                   @@@@@@@@@@@@@@@@@@@@@#                #@@@@@@@@@@@@@@@@@@@@@                 
                     /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                   
                        /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                      
                            &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                          
                                 &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                               
                                         (@@@@@@@@@@@@@@(.                                      
                                                                                                                     
                                                                                           

              ______  _   _   ______   _____     _____   _____   ______  ______  _   _ 
             |  ____ | \ | | |  ____  |  __ \   / ____| |  __ \ |  ____ |  ____ | \ | |
             | |__   |  \| | | |__    | |__) | | |  __  | |__)| | |__   | |__   |  \| |
             |  __|  | . ` | |  __|   |  _  /  | | |_ | |  _  / |  __|  |  __|  | . ` |
             | |____ | |\  | | |____  | | \ \  | |__| | | | \ \ | |____ | |____ | |\  |
             |______ |_| \_| |______  |_|  \_\  \_____| |_|  \_||______ |______ |_| \_|
                                                               
                                                            
@author : Baris Arya Cantepe        
*/
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EnergreenToken is ERC20,ERC20Burnable, Ownable , ReentrancyGuard {

    uint256 public constant MAX_SUPPLY = 200000000 * (10 ** 18);

    uint256 private constant INITIAL_STAKING = 60000000 * (10 ** 18);
    uint256 private constant INITIAL_LIQUIDITY = 3000000 * (10 ** 18);
    uint256 private constant INITIAL_IDO = 80000 * (10 ** 18);
    uint256 private constant INITIAL_PRIVATE_SALE_1 = 35039350 * (10 ** 15);
    uint256 private constant INITIAL_PRIVATE_SALE_2 = 40000 * (10 ** 18);
    uint256 private constant INITIAL_RESERVE = 75000000 * (10 ** 18);

    address public constant stakingAddress = 0xe1C9E85A91f97090f27bE358D03E4Ad28f8F242A ; 
    address public constant liquidityAddress = 0x656F4EAc864393d61362e24434f8Ad2987543aC3 ; 
    address public constant idoAddress = 0x34EcE43178f23F908164651aB673ffbfc26b0b22 ; 
    address public constant privateSale1Address = 0xFaC7c87D1777662909b7Bf7e4E7bc0922423229c ; 
    address public constant privateSale2Address = 0x14530Dd3325CE7D035d231210CC4b2bF5b0ebE88 ; 
    address public constant marketingAddress = 0x3aca898549cC4863beC8D95362Ecc4030a6ad346 ; 
    address public constant reserveAddress = 0x66D9Bb5cC0D8B32C62C46Dfb7376031A497afe70 ; 
    address public constant teamAddress = 0x7F4C6325b0690d98138229C1b2938886ffe10A65 ; 
    address public constant advisorAddress = 0x9c137226d0D4c191F4A680F646dFEb381e7Acee4 ; 

    address public releaserAddress = 0x5299020821E252fD686F372EAFC06a57bA4B303c;

    uint256 public startDate;
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    struct Vesting {
        uint256 vestingTime;
        uint256 period;
        uint256 amount;
        uint256 totalVesting;
    }

    mapping(address => Vesting) public vestings; 
    mapping(address => bool) public blacklist;

    event VestingClaimed(address indexed beneficiary, uint256 amount , uint256 claimedPeriod);

    constructor( ) ERC20("ENERGREEN", "EGRN") {

        startDate = block.timestamp;

        uint256 _currentDay;
        (, , _currentDay) = timestampToDate(startDate) ;
        // releaseVesting function sets the new vesting time in next month as the same day of current month
        // Constructor checks deploy day to block errors when estimating new vestings (Some months don't have 29. day or more.).
        require(_currentDay < 29 , "This contract can not be deployed when the current day of month is bigger than 28.") ;

        _mint(address(this), MAX_SUPPLY);

        _transfer(address(this), stakingAddress, INITIAL_STAKING);
        _transfer(address(this), liquidityAddress, INITIAL_LIQUIDITY);
        _transfer(address(this), idoAddress, INITIAL_IDO);
        _transfer(address(this), privateSale1Address, INITIAL_PRIVATE_SALE_1);
        _transfer(address(this), privateSale2Address, INITIAL_PRIVATE_SALE_2);
        _transfer(address(this), reserveAddress, INITIAL_RESERVE);

        vestings[marketingAddress] = Vesting({
            vestingTime: getNextVestingMonth(1 , startDate) , 
            period: 133, 
            amount: 248120300751879699248120, // Approximately 248,120 EGRN
            totalVesting: 133
        });

        vestings[privateSale1Address] = Vesting({
            vestingTime: getNextVestingMonth(9 , startDate), 
            period: 13, 
            amount: 51211357692307692307692, // Approximately 51,211 EGRN
            totalVesting: 13
        });

        vestings[privateSale2Address] = Vesting({
            vestingTime: getNextVestingMonth(8 , startDate), 
            period: 13, 
            amount: 58461538461538461538461, // Approximately 58,461 EGRN
            totalVesting: 13
        });

        vestings[idoAddress] = Vesting({
            vestingTime: getNextVestingMonth(1 , startDate), 
            period: 200, 
            amount: 4600 * (10 ** 18),
            totalVesting: 200
        });

        vestings[teamAddress] = Vesting({
            vestingTime: getNextVestingMonth(12 , startDate), 
            period: 96, 
            amount: 208333333333333333333333, // Approximately 208,333 EGRN
            totalVesting: 96
        });

        vestings[advisorAddress] = Vesting({
            vestingTime: getNextVestingMonth(12 , startDate), 
            period: 48, 
            amount: 135400270833333333333333 , // Approximately 135,400 EGRN
            totalVesting: 48
        });

    }

    // VESTING LOCK RELEASE
    function releaseVesting (address vestingAddress) public releaserOrOwner nonReentrant {

        Vesting memory vesting = vestings[vestingAddress] ;

        require( block.timestamp >= vesting.vestingTime , "Vesting time is not now." ) ;
        require( vesting.period > 0 , "Vesting is over for this address" ) ;

        uint256 nextVestingTime ;

        if (vestingAddress == idoAddress) {
            nextVestingTime = vesting.vestingTime + 1 weeks ; }                 // Adding 1 week for IDO vesting 
        else {
            nextVestingTime = getNextVestingMonth(1 , vesting.vestingTime) ;    // Vesting day is same for every month except IDO sale.
        }

        vesting.vestingTime = nextVestingTime;
        vesting.period -= 1 ;

        vestings[vestingAddress] = vesting ;
        _transfer(address(this), vestingAddress, vesting.amount);

        emit VestingClaimed(vestingAddress, vesting.amount,(vesting.totalVesting - vesting.period));

    }

    //Pure functions
    function  getNextVestingMonth (uint256 _addingMonth , uint256 _currentTimestamp) public pure returns (uint256 _timestamp) {
        uint256 currentYear ;
        uint256 currentMonth ;
        uint256 currentDay ;

        (currentYear, currentMonth , currentDay) = timestampToDate(_currentTimestamp) ;
        uint256 nextYear = (_addingMonth / 12 ) + currentYear ;
        uint256 nextMonth = (_addingMonth % 12 ) + currentMonth ;

        if (nextMonth > 12 ) {
            nextYear += 1 ;
            nextMonth = nextMonth % 12 ;
        }

        uint256 nextTimestamp = timestampFromDate(nextYear , nextMonth , currentDay) ;
        return nextTimestamp ;
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampFromDate(uint year, uint month, uint day) public pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    // View functions
    function getClaimedVestingCountForAddress (address _address) public view returns (uint256) {
        return vestings[_address].totalVesting - vestings[_address].period ;
    }

    function getTotalRemainingVestingAmountsForAddress (address _address) public view returns (uint256) {
        Vesting memory vesting = vestings[_address] ;
        uint256 remainingPeriod = vesting.period ;
        uint256 periodicAmount = vesting.amount ;
        uint256 remainingVestingAmount = remainingPeriod * periodicAmount ;
        return remainingVestingAmount ;
    }

    // Setter
    function setReleaserAddress(address _releaserAddress) public onlyOwner{
        releaserAddress = _releaserAddress;
    }

    // Blacklist related
    function addToBlacklist(address user) public onlyOwner {
        blacklist[user] = true;
    }

    function removeFromBlacklist(address user) public onlyOwner {
        blacklist[user] = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!blacklist[from], "Token transfer not allowed: source address is blacklisted");
        require(!blacklist[to], "Token transfer not allowed: destination address is blacklisted");       
        super._beforeTokenTransfer(from, to, amount);
    }

    modifier releaserOrOwner() {
        require(owner() == _msgSender() || releaserAddress == _msgSender() , "You don't have permission to call release function.");
        _;
    }

}