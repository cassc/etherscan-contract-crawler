// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 	// ERC20 interface
import "@openzeppelin/contracts/access/Ownable.sol"; 		// OZ: Ownable

contract SuperHolder is Ownable{

    enum DepositCategory{
        HOLDER,
        SUPER_HOLDER
    }
    enum DepositType
    {
        HOLDER_3MONTHS,
        HOLDER_6MONTHS,
        HOLDER_12MONTHS
    }

    uint256 public constant HOLDER_QUOTA = 200;
    uint256 public constant SUPER_HOLDER_QUOTA = 20;
    uint256 public  HOLDER_DEPOSIT_LIMIT = 2500 * 1 ether;
    uint256[] public  HOLDER_PERIOD = [7776000,15552000,31104000];
    uint256[] public  HOLDER_APY_TIERS = [9,11,15];
    uint256[] public  SUPER_HOLDER_APY_TIERS = [12,14,18];
    uint256 public constant ONE_YEAR_SECONDS = 31536000;
    uint256 public  SUPER_HOLDER_DEPOSIT_LIMIT = 5000 * 1 ether;
    uint256 public holders_num;
    uint256 public super_holders_num;
    uint256 public total_locked_esg;
    uint256 public total_interest_claimed;
    IERC20 public immutable esgToken;
    struct User{
        uint256 depositTimestamp;
        uint256 claimedAmount;
        uint256 isUsed;
        DepositCategory category;
        DepositType dtype;
    }

    mapping (address => User) public accounts;

    constructor (address _esgAddress){
        require(_esgAddress != address(0), "invalid token address");
        esgToken = IERC20(_esgAddress);

        holders_num = 0;
        super_holders_num = 0;
        total_locked_esg = 0;
        total_interest_claimed = 0;
    }

    function deposit(DepositCategory _category, DepositType _type) external {
        require(_category <= DepositCategory.SUPER_HOLDER, "invalid deposit category");
        require(_type <= DepositType.HOLDER_12MONTHS, "invalid deposit type");
        if(_category == DepositCategory.HOLDER)
        {
            require(holders_num+1 <= HOLDER_QUOTA, "holders number exceeds limit");
            holders_num = holders_num + 1;
        }
        else if(_category == DepositCategory.SUPER_HOLDER)
        {
            require(super_holders_num+1 <= SUPER_HOLDER_QUOTA, "super holders number exceeds limit");
            super_holders_num = super_holders_num + 1;
        }
            
        User storage user = accounts[msg.sender];
        require(user.isUsed == 0, "user has already deposited.");
        uint256 amount = HOLDER_DEPOSIT_LIMIT;
        if(_category == DepositCategory.SUPER_HOLDER)
            amount = SUPER_HOLDER_DEPOSIT_LIMIT;
	user.depositTimestamp = block.timestamp;
        total_locked_esg = total_locked_esg + amount;
        esgToken.transferFrom(msg.sender, address(this), amount);
        accounts[msg.sender] = User(block.timestamp, 0, 1, _category, _type);
    }

    function claimInterest() external {
        User storage user = accounts[msg.sender];
        require(user.isUsed == 1, "no deposit");
        uint256 amount = getInterestAvailable(msg.sender);
        uint256 balance = esgToken.balanceOf(address(this));
        if(balance < amount)
            amount = balance;
        user.claimedAmount = user.claimedAmount + amount;
        total_interest_claimed = total_interest_claimed + amount;
        esgToken.transfer(msg.sender, amount);
    }

    function withdrawPrincipal() external {
        User memory user = accounts[msg.sender];
        require(user.isUsed == 1, "no deposit");
        uint256 timeSpan = block.timestamp - user.depositTimestamp;
        require(timeSpan > HOLDER_PERIOD[uint256(user.dtype)], "deposit is in locked status");

        uint256 amount = HOLDER_DEPOSIT_LIMIT;
        if(user.category == DepositCategory.HOLDER)
        {
            holders_num = holders_num - 1;
        }
        else if(user.category == DepositCategory.SUPER_HOLDER)
        {
            amount = SUPER_HOLDER_DEPOSIT_LIMIT;
            super_holders_num = super_holders_num - 1;
        }
            
        total_locked_esg = total_locked_esg - amount;

        amount = amount + getInterestAvailable(msg.sender);
        uint256 balance = esgToken.balanceOf(address(this));
        if(balance < amount)
            amount = balance;
        delete accounts[msg.sender];
        esgToken.transfer(msg.sender, amount);
    }

    function getInterestAvailable(address account) public view returns(uint256){
        User memory user = accounts[account];
        if(user.isUsed == 0)
            return 0;
        else
        {
            uint256 amount = 0;
            if(user.category == DepositCategory.HOLDER)
            {
                if(block.timestamp - user.depositTimestamp >=  HOLDER_PERIOD[uint256(user.dtype)])
                    amount = HOLDER_DEPOSIT_LIMIT * HOLDER_APY_TIERS[uint256(user.dtype)] * HOLDER_PERIOD[uint256(user.dtype)] / ONE_YEAR_SECONDS / 100;
                else
                    amount = HOLDER_DEPOSIT_LIMIT * HOLDER_APY_TIERS[uint256(user.dtype)] * (block.timestamp - user.depositTimestamp)/ ONE_YEAR_SECONDS / 100;
            }else if(user.category == DepositCategory.SUPER_HOLDER)
            {
                if(block.timestamp - user.depositTimestamp >=  HOLDER_PERIOD[uint256(user.dtype)])
                    amount = SUPER_HOLDER_DEPOSIT_LIMIT * SUPER_HOLDER_APY_TIERS[uint256(user.dtype)] * HOLDER_PERIOD[uint256(user.dtype)] / ONE_YEAR_SECONDS / 100;
                else
                    amount = SUPER_HOLDER_DEPOSIT_LIMIT * SUPER_HOLDER_APY_TIERS[uint256(user.dtype)] * (block.timestamp - user.depositTimestamp)/ ONE_YEAR_SECONDS / 100;
            }
            return amount - user.claimedAmount;
        }
    }

    function _withdrawERC20Token(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "invalid address");
        uint256 tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
        if(tokenAmount > 0)
            IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        else
            revert("insufficient ERC20 tokens");
    }

    function _setHolderDepositLimit(uint256 depositLimit) external onlyOwner {
        HOLDER_DEPOSIT_LIMIT = depositLimit;
    }

    function _setSuperHolderDepositLimit(uint256 depositLimit) external onlyOwner {
        SUPER_HOLDER_DEPOSIT_LIMIT = depositLimit;
    }
}