//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

error NotWhitelisted();
error TransactionError();

contract OceansStakingPool_v2 is Initializable,ReentrancyGuardUpgradeable, OwnableUpgradeable {
    
    IERC20 public OCEANS;
    address whitelistedCaller;
    uint256 unstakeTime;
    uint256 correctionFactor;

    struct database {
        uint256 _totalvalue;
        uint256 _totalapy;
        uint256 _stakeTime;
        uint256 _lastClaimed;
        uint256 _unlockvalue;   //30 days timer
    }
    mapping(address => database) public _userDB;
    mapping(address => uint256) public _userEarning;

    modifier onlyWhitelisted() {
        if (msg.sender != whitelistedCaller) {
            revert NotWhitelisted();
        }
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        whitelistedCaller = 0x0f4F5c49C7304bFC66083eD6e63Ddb3f67C0eC64;   
        OCEANS = IERC20(0x2A54F9710ddeD0eBdde0300BB9ac7e21cF0E8DA5);    //mainnet ocean
        unstakeTime = 30 days;
        correctionFactor = 10**13;
    }

    function stake(
        address _user,
        uint256 _apy,
        uint256 _tokenValue
    ) public onlyWhitelisted nonReentrant {

        uint LastTime = _userDB[_user]._stakeTime;
        uint LastClaimed = _userDB[_user]._lastClaimed;
        uint LastApy = _userDB[_user]._totalapy;
        uint reserve;

        if(block.timestamp >= LastTime + unstakeTime && LastTime > 0) {
            _userDB[_user]._stakeTime = block.timestamp;
            _userDB[_user]._unlockvalue += _userDB[_user]._totalvalue;
            _userDB[_user]._totalvalue = 0;
        }

        uint subtotal = _userDB[_user]._totalvalue + _userDB[_user]._unlockvalue;

        if(block.timestamp > LastClaimed && LastClaimed > 0) {
            uint _seconds = calTime(LastClaimed);
            uint Factor = subtotal*correctionFactor;
            if(_seconds != 0) {
                uint ActualAmount = calapy(Factor,LastApy);
                uint Reward = ActualAmount*_seconds;
                reserve = Reward / correctionFactor;    
            }
        }

        if(reserve > 0) {
            _userEarning[_user] = reserve;
            _userDB[_user]._lastClaimed = block.timestamp;       
        }

        _userDB[_user]._totalvalue += _tokenValue;
        _userDB[_user]._stakeTime = block.timestamp;
        _userDB[_user]._lastClaimed = block.timestamp;
        _userDB[_user]._totalapy += _apy;

    }

    function claimReward() public {

        address _user = msg.sender;

        uint LastStaked = _userDB[_user]._totalvalue + _userDB[_user]._unlockvalue;
        uint LastClaimed = _userDB[_user]._lastClaimed;
        uint LastApy = _userDB[_user]._totalapy;
        uint reserve = _userEarning[_user];
        uint RewardExtracted;

        if(block.timestamp > LastClaimed && LastClaimed > 0) {
            uint _seconds = calTime(LastClaimed);
            uint Factor = LastStaked*correctionFactor;
            if(_seconds != 0) {
                uint ActualAmount = calapy(Factor,LastApy);
                uint Reward = ActualAmount*_seconds;
                RewardExtracted = Reward / correctionFactor;    
            }
        }
        
        uint transferable = reserve + RewardExtracted;

        if(transferable > 0) {
            if(RewardExtracted > 0) {
                _userDB[_user]._lastClaimed = block.timestamp;
            }
            _userEarning[_user] = 0;
            OCEANS.transfer(_user,transferable);
        }
        else {
            revert("Not Reward Generated so Far!!");
        }

    } 


    function unstake(uint _amount) public nonReentrant {

        address _user = msg.sender;

        uint LastStaked = _userDB[_user]._totalvalue;
        uint LastTime = _userDB[_user]._stakeTime;
        uint LastApy = _userDB[_user]._totalapy;

        if(block.timestamp >= LastTime + unstakeTime && LastTime > 0) {
            _userDB[_user]._stakeTime = block.timestamp;
            _userDB[_user]._unlockvalue += LastStaked;
            _userDB[_user]._totalvalue = 0;
        }

        uint subtotal = _userDB[_user]._stakeTime + _userDB[_user]._unlockvalue;
        uint percent = (_amount * 100 ) / subtotal;
        uint updateApy = ( LastApy * percent ) / 100;

        if(_amount > _userDB[_user]._unlockvalue) {
            revert("Amount Exceeded from Available Amount!!");
        }
        else{   
            _userDB[_user]._unlockvalue -= _amount;
            _userDB[_user]._totalapy -= updateApy;
            OCEANS.transfer(_user,_amount);
        }
        
    }

    //to show the user earning
    function getEarning(address _user) public view returns (uint) {

        uint LastStaked = _userDB[_user]._totalvalue;
        uint LastClaimed = _userDB[_user]._lastClaimed;
        uint LastApy = _userDB[_user]._totalapy;
        uint RewardExtracted;

        uint subtotal = LastStaked + _userDB[_user]._unlockvalue;

        if(block.timestamp > LastClaimed && LastClaimed > 0) {
            uint _seconds = calTime(LastClaimed);
            uint Factor = subtotal*correctionFactor;
            if(_seconds != 0) {
                uint ActualAmount = calapy(Factor,LastApy);
                uint Reward = ActualAmount*_seconds;
                RewardExtracted = Reward / correctionFactor;    
            }
        }
        
        uint transferable = _userEarning[_user] + RewardExtracted;
        return transferable;

    } 

    function getUnlockToken(address _user) public view returns (uint) {

        uint LastStaked = _userDB[_user]._totalvalue;
        uint LastTime = _userDB[_user]._stakeTime;
        uint LastUnlock = _userDB[_user]._unlockvalue;
        
        uint unlockedValue;

        if(block.timestamp >= LastTime + unstakeTime && LastTime > 0) {
            unlockedValue += LastStaked;
        }

        return (unlockedValue + LastUnlock);

    }

    function treasuryBalance() public view returns (uint) {
        return OCEANS.balanceOf(address(this));
    }

    function setWhitelistCaller(address _adr) public onlyOwner {
        whitelistedCaller = _adr;
    }

    function setUnstakeTime(uint256 _value) public onlyOwner {
        unstakeTime = _value;
    }

    function calapy(uint _amount,uint _apy) internal pure returns (uint){
        uint num =  (_amount * _apy) / 100;
        return num / (31536000);
    }

    function calTime(uint _time) internal view returns (uint) {
        if(_time == 0) return 0;
        uint sec = block.timestamp - (_time);
        return sec;
    }

    function rescueToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_token).transfer(_recipient, _amount);
    }

    function rescueFunds() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        if (!os) revert TransactionError();
    }

    function setOceans(address _adr) public onlyOwner {
        OCEANS = IERC20(_adr);
    }

    receive() external payable {}

    //this is to fix issue in v2 , this function will remove in v3 

    function fixUserIssue(address _adr, uint _fixedValue) public onlyOwner {
        _userDB[_adr]._totalvalue = _fixedValue;
    }

}