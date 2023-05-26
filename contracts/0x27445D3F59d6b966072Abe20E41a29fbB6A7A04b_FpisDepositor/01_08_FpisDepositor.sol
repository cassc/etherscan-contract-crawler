// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IStaker.sol";
import "./interfaces/ITokenMinter.sol";
import "./interfaces/IVoteEscrow.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


contract FpisDepositor{
    using SafeERC20 for IERC20;

    address public constant fpis = address(0xc2544A32872A91F4A553b404C6950e89De901fdb);
    address public constant escrow = address(0x574C154C83432B0A45BA3ad2429C3fA242eD7359);
    uint256 private constant MAXTIME = 4 * 364 * 86400;
    uint256 private constant WEEK = 7 * 86400;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public platformHolding = 0;
    address public platformDeposit;

    address public owner;
    address public pendingOwner;
    address public immutable staker;
    address public immutable minter;
    uint256 public unlockTime;

    event SetPendingOwner(address indexed _address);
    event OwnerChanged(address indexed _address);
    event ChangeHoldingRate(uint256 _rate, address _forward);

    constructor(address _staker, address _minter){
        staker = _staker;
        minter = _minter;
        owner = msg.sender;
    }

    //set next owner
    function setPendingOwner(address _po) external {
        require(msg.sender == owner, "!auth");
        pendingOwner = _po;
        emit SetPendingOwner(_po);
    }

    //claim ownership
    function acceptPendingOwner() external {
        require(msg.sender == pendingOwner, "!p_owner");

        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnerChanged(owner);
    }

    function setPlatformHoldings(uint256 _holdings, address _deposit) external{
        require(msg.sender==owner, "!auth");

        require(_holdings <= 2000, "too high");
        if(_holdings > 0){
            require(_deposit != address(0),"need address");
        }
        platformHolding = _holdings;
        platformDeposit = _deposit;
        emit ChangeHoldingRate(_holdings, _deposit);
    }

    function initialLock() external{
        require(msg.sender==owner, "!auth");

        uint256 vefpis = IERC20(escrow).balanceOf(staker);
        uint256 locked = IVoteEscrow(escrow).locked(staker);
        if(vefpis == 0 || vefpis == locked){
            uint256 unlockAt = block.timestamp + MAXTIME;
            uint256 unlockInWeeks = (unlockAt/WEEK)*WEEK;

            //release old lock if exists
            IStaker(staker).release();
            //create new lock
            uint256 fpisBalanceStaker = IERC20(fpis).balanceOf(staker);
            IStaker(staker).createLock(fpisBalanceStaker, unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    //lock fpis
    function _lockFpis() internal {
        uint256 fpisBalance = IERC20(fpis).balanceOf(address(this));
        if(fpisBalance > 0){
            IERC20(fpis).safeTransfer(staker, fpisBalance);
        }
        
        //increase ammount
        uint256 fpisBalanceStaker = IERC20(fpis).balanceOf(staker);
        if(fpisBalanceStaker == 0){
            return;
        }
        
        //increase amount
        IStaker(staker).increaseAmount(fpisBalanceStaker);
        

        uint256 unlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = (unlockAt/WEEK)*WEEK;

        //increase time too if over 1 week buffer
        if( unlockInWeeks - unlockTime >= 1){
            IStaker(staker).increaseTime(unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    function lockFpis() external {
        _lockFpis();
    }

    //deposit fpis for cvxFpis
    function deposit(uint256 _amount, bool _lock) public {
        require(_amount > 0,"!>0");

        //mint for msg.sender
        ITokenMinter(minter).mint(msg.sender,_amount);

        //check if some should be withheld
        if(platformHolding > 0){
            //can only withhold if there is surplus locked
            if(_amount + IERC20(minter).totalSupply() <= IVoteEscrow(escrow).locked(staker) ){
                uint256 holdAmt = _amount * platformHolding / DENOMINATOR;
                IERC20(fpis).safeTransferFrom(msg.sender, platformDeposit, holdAmt);
                _amount -= holdAmt;
            }
        }
        
        if(_lock){
            //lock immediately, transfer directly to staker to skip an erc20 transfer
            IERC20(fpis).safeTransferFrom(msg.sender, staker, _amount);
            _lockFpis();
        }else{
            //move tokens here
            IERC20(fpis).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    function depositAll(bool _lock) external{
        uint256 fpisBal = IERC20(fpis).balanceOf(msg.sender);
        deposit(fpisBal,_lock);
    }
}