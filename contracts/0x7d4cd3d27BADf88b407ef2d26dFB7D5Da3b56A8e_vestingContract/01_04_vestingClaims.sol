//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


interface IToken {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 _amount) external;

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function decimals() external
        view
        returns (uint256);
}


contract vestingContract {


    using Counters for Counters.Counter;
    using SafeMath for uint256;
    address public token;

    uint256 public timeUnit;
    address public admin;

    mapping(address => uint256[]) vestingIds;
    
    uint256 public listedAt;
    Counters.Counter private _id;

    constructor (address _token,address _admin) {
        admin = _admin;
        timeUnit = 60;
        token = _token;
    }


    struct claimInfo {
        bool initialized;
        address owner;
        uint totalEligible;
		uint totalClaimed;
		uint remainingBalTokens;
		uint lastClaimedAt;
        uint startTime;
        uint totalVestingDays;
        uint slicePeriod;

    }


    modifier onlyAdmin()   {
        require(
            msg.sender == admin,
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    mapping(address => mapping(uint256 => claimInfo)) public userClaimData; 

    function launch() external  {
        require(admin == msg.sender,"caller is not the admin ");
        require(listedAt == 0, "Already Listed!");
        listedAt = block.timestamp;
    }

    function createVesting (address _creator,uint _totalDays, uint _slicePeriod,uint tokenAmount) public onlyAdmin {
                
        uint256 launchedAt = listedAt;
        uint256 currentTime = getCurrentTime();
        _id.increment();
        
        vestingIds[_creator].push(_id.current());
        
        userClaimData[_creator][_id.current()] = claimInfo({
            initialized:true,
            owner:_creator,
            totalEligible:tokenAmount,
            totalClaimed:0,
            remainingBalTokens:tokenAmount,
            lastClaimedAt:launchedAt,
            startTime:currentTime,
            totalVestingDays:_totalDays,
            slicePeriod:_slicePeriod
        });
        
    }


    function getCurrentTime()internal virtual view
    returns(uint256){
        return block.timestamp;
    }

    function getLaunchedAt() public view returns(uint256 ) {
        return(listedAt);
    }


    function getClaimableAmount(address _walletAddress,uint256 _vestingId) public view returns(uint _claimAmount) {

        if(getLaunchedAt()==0) {
            return 0;
        }

        claimInfo storage userData = userClaimData[_walletAddress][_vestingId];        
        uint256 timeLeft = 0;
        uint slicePeriodSeconds = userData.slicePeriod * timeUnit;
        uint256 claimAmount =0;
        uint256 _amount =0;

        uint256 currentTime = getCurrentTime();
        uint totalEligible = userData.totalEligible;
        uint lastClaimedAt = userData.lastClaimedAt;
        if(getLaunchedAt() !=0 && lastClaimedAt==0){
            if(currentTime>getLaunchedAt()){
            timeLeft = currentTime.sub(getLaunchedAt());
      
            }else{
            timeLeft =  getLaunchedAt().sub(currentTime);
            }

        }else{
            
            if(currentTime>lastClaimedAt){
            timeLeft = currentTime.sub(lastClaimedAt);
      
            }else{
            timeLeft =  lastClaimedAt.sub(currentTime);
            }

        }
        _amount = totalEligible;

        if(timeLeft/slicePeriodSeconds > 0){
            claimAmount = ((_amount*userData.slicePeriod)/userData.totalVestingDays)*(timeLeft/slicePeriodSeconds) ;
        }

        uint _lastReleaseAmount = userData.totalClaimed;

        uint256 temp = _lastReleaseAmount.add(claimAmount);

        if(temp > totalEligible){
            _amount = totalEligible.sub(_lastReleaseAmount);
            return (_amount);
        }
        return (claimAmount);
      
    }

    function claim(address _walletAddress,uint256 _vestingId) public {
        require(getLaunchedAt() != 0,"Not yet launched");
        require(getClaimableAmount(_walletAddress,_vestingId)>0,'Insufficient funds to claims.');
        require( msg.sender==userClaimData[_walletAddress][_vestingId].owner,"You are not the owner");
        uint256 _amount = getClaimableAmount(_walletAddress,_vestingId);
        userClaimData[_walletAddress][_vestingId].totalClaimed += _amount;
        userClaimData[_walletAddress][_vestingId].remainingBalTokens = userClaimData[_walletAddress][_vestingId].totalEligible-userClaimData[_walletAddress][_vestingId].totalClaimed;
        userClaimData[_walletAddress][_vestingId].lastClaimedAt = getCurrentTime();
        IToken(token).transfer(_walletAddress, _amount);
    }


    function setAdmin(address account) external  {
        require(admin == msg.sender,"caller is not the admin ");
        require(account != address(0),"Invalid Address, Address should not be zero");
        admin = account;
    }

    function getVestingIds(address _walletAddress)  
    external view
    returns (uint[] memory)
    {
        return vestingIds[_walletAddress];
    }

    // remove token for admin

    function balance() public view returns(uint256){
        return IToken(token).balanceOf(address(this));
    }

    function removeERC20() public {
        require(admin == msg.sender,"caller is not the admin ");
        IToken(token).transfer(admin,IToken(token).balanceOf(address(this)));
    }


    function setTimeUnit(uint _unit) public onlyAdmin{
        timeUnit = _unit;
    }


}