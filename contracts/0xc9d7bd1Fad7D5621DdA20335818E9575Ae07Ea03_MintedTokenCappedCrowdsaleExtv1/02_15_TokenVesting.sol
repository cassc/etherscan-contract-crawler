// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC20.sol";
import "./SafeMathLibExt.sol";
import "./Allocatable.sol";


/**
 * Contract to enforce Token Vesting
 */
contract TokenVesting is Allocatable {

    using SafeMathLibExt for uint;

    address public crowdSaleTokenAddress;

    /** keep track of total tokens yet to be released, 
     * this should be less than or equal to UTIX tokens held by this contract. 
     */
    uint256 public totalUnreleasedTokens;

    // default vesting parameters
    uint256 private startAt = 0;
    uint256 private cliff = 1;
    uint256 private duration = 4; 
    uint256 private step = 300; //15778463;  //2592000;
    bool private changeFreezed = false;

    struct VestingSchedule {
        uint256 startAt;
        uint256 cliff;
        uint256 duration;
        uint256 step;
        uint256 amount;
        uint256 amountReleased;
        bool changeFreezed;
    }

    mapping (address => VestingSchedule) public vestingMap;

    address[] public vestedWallets;

    event VestedTokensReleased(address _adr, uint256 _amount);
    
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Token Address cannot be Null Address");
        crowdSaleTokenAddress = _tokenAddress;
    }

    /** Modifier to check if changes to vesting is freezed  */
    modifier changesToVestingFreezed(address _adr) {
        require(vestingMap[_adr].changeFreezed);
        _;
    }

    /** Modifier to check if changes to vesting is not freezed yet  */
    modifier changesToVestingNotFreezed(address adr) {
        require(!vestingMap[adr].changeFreezed); // if vesting not set then also changeFreezed will be false
        _;
    }

    /** Function to set default vesting schedule parameters. */
    function setDefaultVestingParameters(
        uint256 _startAt, uint256 _cliff, uint256 _duration,
        uint256 _step, bool _changeFreezed) public onlyAllocateAgent {

        // data validation
        require(_step != 0);
        require(_duration != 0);
        require(_cliff <= _duration);

        startAt = _startAt;
        cliff = _cliff;
        duration = _duration; 
        step = _step;
        changeFreezed = _changeFreezed;

    }

    /** Function to set vesting with default schedule. */
    function setVestingWithDefaultSchedule(address _adr, uint256 _amount) 
    public 
    changesToVestingNotFreezed(_adr) onlyAllocateAgent {
       require(_adr != address(0), "Cannot set Vesting to Null Address");
       setVesting(_adr, startAt, cliff, duration, step, _amount, changeFreezed);
    }    

    /** Function to set/update vesting schedule. PS - Amount cannot be changed once set */
    function setVesting(
        address _adr,
        uint256 _startAt,
        uint256 _cliff,
        uint256 _duration,
        uint256 _step,
        uint256 _amount,
        bool _changeFreezed) 
    public changesToVestingNotFreezed(_adr) onlyAllocateAgent {
        require(_adr!=address(0), "Cannot set Null Address");
        VestingSchedule storage vestingSchedule = vestingMap[_adr];

        // data validation
        require(_step != 0);
        require(_amount != 0 || vestingSchedule.amount > 0);
        require(_duration != 0);
        require(_cliff <= _duration);

        //if startAt is zero, set current time as start time.
        if (_startAt == 0) 
            _startAt = block.timestamp;

        vestingSchedule.startAt = _startAt;
        vestingSchedule.cliff = _cliff;
        vestingSchedule.duration = _duration;
        vestingSchedule.step = _step;

        // special processing for first time vesting setting
        if (vestingSchedule.amount == 0) {
            // check if enough tokens are held by this contract
            ERC20 token = ERC20(crowdSaleTokenAddress);
            require(token.balanceOf(address(this)) >= totalUnreleasedTokens.plus(_amount));
            totalUnreleasedTokens = totalUnreleasedTokens.plus(_amount);
            vestingSchedule.amount = _amount; 
        }

        vestingSchedule.amountReleased = 0;
        vestingSchedule.changeFreezed = _changeFreezed;

        vestedWallets.push(_adr);
    }

    function isVestingSet(address adr) public view returns (bool isSet) {
        return vestingMap[adr].amount != 0;
    }

    function freezeChangesToVesting(address _adr) public changesToVestingNotFreezed(_adr) onlyAllocateAgent {
        require(isVestingSet(_adr)); // first check if vesting is set
        vestingMap[_adr].changeFreezed = true;
    }
    
    /** Release tokens to all the vested wallets */
    function releaseAllVestedTokens() public onlyOwner{
        for(uint256 i = 0; i < vestedWallets.length; i++){
            releaseVestedTokens(vestedWallets[i]);
        }
    }

    /** Release tokens as per vesting schedule, called by anyone  */
    function releaseVestedTokens(address _adr) internal changesToVestingFreezed(_adr) {
        VestingSchedule storage vestingSchedule = vestingMap[_adr];
        
        // check if all tokens are not vested
        require(vestingSchedule.amount.minus(vestingSchedule.amountReleased) > 0);
        
        // calculate total vested tokens till now
        uint256 totalTime = block.timestamp.minus(vestingSchedule.startAt);
        uint256 totalSteps = totalTime.divides(vestingSchedule.step);

        // check if cliff is passed
        require(vestingSchedule.cliff <= totalSteps);

        uint256 tokensPerStep = vestingSchedule.amount.divides(vestingSchedule.duration);
        // check if amount is divisble by duration
        if (tokensPerStep.times(vestingSchedule.duration) != vestingSchedule.amount) tokensPerStep.plus(1);

        uint256 totalReleasableAmount = tokensPerStep.times(totalSteps);

        // handle the case if user has not claimed even after vesting period is over or amount was not divisible
        if (totalReleasableAmount > vestingSchedule.amount) totalReleasableAmount = vestingSchedule.amount;

        uint256 amountToRelease = totalReleasableAmount.minus(vestingSchedule.amountReleased);
        vestingSchedule.amountReleased = vestingSchedule.amountReleased.plus(amountToRelease);

        // transfer vested tokens
        ERC20 token = ERC20(crowdSaleTokenAddress);
        token.transfer(_adr, amountToRelease);
        // decrement overall unreleased token count
        totalUnreleasedTokens = totalUnreleasedTokens.minus(amountToRelease);
        emit VestedTokensReleased(_adr, amountToRelease);
    }

    /**
    * Allow to (re)set Token.
    */
    function setCrowdsaleTokenExtv1(address _token) public onlyAllocateAgent {    
        require(_token != address(0), "Token Address cannot set to Null Address");   
        crowdSaleTokenAddress = _token;
    }
}