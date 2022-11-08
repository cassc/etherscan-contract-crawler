// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract bADD is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, UUPSUpgradeable{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
	
	IERC20Upgradeable public stakedToken;
	uint256 public minStaking;
	uint256 public totalStaked;
	uint256 public claimInterval;
	
	bool public initialized;
	
    struct UserInfo {
       uint256 amount; 
	   uint256 rewardWithdrawal;
       uint256 startTime;
	   uint256 lastClaim;
    }
	
    mapping(address => UserInfo) internal userInfo;
	
    event MigrateTokens(IERC20Upgradeable tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event MinStakePerUser(uint256 minStakePerUser);
    event Withdraw(address indexed user, uint256 amount);
	
    function initialize() public initializer {
		 require(!initialized, "Contract instance has already been initialized");
		 initialized = true;
		 
		__ERC20_init("bADD", "bADD");
		__Pausable_init();
		__Ownable_init();
		__ERC20Permit_init("add");
		__ERC20Votes_init();
		__UUPSUpgradeable_init();
		
		minStaking = 1 * 10**18;
		claimInterval = 7 days;
    }
	receive() external payable {}
	
	function deposit(uint256 amount) external{
	    UserInfo storage user = userInfo[msg.sender];
		uint256 balance = stakedToken.balanceOf(msg.sender);
		
		require(balance >= amount, "Balance not available for staking");
		require(amount >= minStaking, "Amount is less than minimum staking amount");
		
		uint256 pending = pendingreward(msg.sender);
		
		user.amount += amount;
		user.startTime = block.timestamp;
		user.lastClaim = block.timestamp;
		user.rewardWithdrawal += pending;
		
		totalStaked += amount;
		
		stakedToken.safeTransferFrom(address(msg.sender), address(this), amount);
		if(pending > 0) 
		{
		    payable(msg.sender).transfer(pending);
		}
		_mint(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }
	
	function withdraw() external{
	    UserInfo storage user = userInfo[msg.sender];
		require(user.amount > 0, "Amount is not staked");
		
		uint256 amount   = user.amount;
		uint256 pending  = pendingreward(msg.sender);
		
		require(stakedToken.balanceOf(address(this)) >= amount, "Token balance not available for withdraw");
		
		totalStaked = totalStaked - amount;
		
		user.amount = 0;
		user.rewardWithdrawal = 0;
		user.startTime = 0;
		user.lastClaim = 0;
		
		stakedToken.safeTransfer(address(msg.sender), amount);
		if(pending > 0) {
		    payable(msg.sender).transfer(pending);
		}
		_burn(msg.sender, amount);
		emit Withdraw(msg.sender, amount);
    }
	
	function withdrawReward() external{
		UserInfo storage user = userInfo[msg.sender];
		uint256 pending = pendingreward(msg.sender);
		
		require(user.amount > 0, "Amount is not staked");
		require(pending > 0, "Not amount for claim");
		
		user.rewardWithdrawal +=  pending;
		user.lastClaim = block.timestamp;
		
		payable(msg.sender).transfer(pending);
		emit Withdraw(msg.sender, pending);
    }
	
	function pendingreward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
		if(user.amount > 0) {
			uint256 cTime  = user.lastClaim;
			uint256 eTime  = block.timestamp;
			if((cTime + claimInterval) >= eTime)  {
			    uint256 reward = uint(user.amount) * uint(address(this).balance) / uint(totalStaked);
			    return reward;
			} else {
			   return 0;
			}
		} else {
		    return 0;
		}
    }
	
	function getUserInfo(address userAddress) external view returns (uint256, uint256, uint256, uint256) {
        UserInfo storage user = userInfo[userAddress];
        return (user.amount, user.rewardWithdrawal, user.startTime, user.lastClaim);
    }
	
	function claimPeriodLeft(address userAddress) external view returns (uint256) {
		UserInfo storage user = userInfo[userAddress];
		if( block.timestamp >= user.lastClaim + claimInterval) {
		   return (0);
		} else  {
		   return (user.lastClaim + claimInterval - block.timestamp);
		}
    }
	
	function migrateTokens(IERC20Upgradeable tokenAddress, uint256 tokenAmount) external onlyOwner{
       IERC20Upgradeable(tokenAddress).safeTransfer(address(msg.sender), tokenAmount);
       emit MigrateTokens(tokenAddress, tokenAmount);
    }
	
	function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
	
	function updateMinStaking(uint256 minStakingAmount) external onlyOwner {
	    require(stakedToken.totalSupply() > minStakingAmount, "Total supply is less than minimum staking amount");
		require(minStakingAmount >= 1 * 10**18, "Amount is less than `1` tokens");
		
        minStaking = minStakingAmount;
        emit MinStakePerUser(minStakingAmount);
    }
	
	function setStakingTokens(IERC20Upgradeable tokenAddress) external onlyOwner{
       stakedToken = IERC20Upgradeable(tokenAddress);
    }
	
	function setNewClaimInterval(uint256 newClaimInterval) external onlyOwner{
       require(newClaimInterval > 0, "new claim interval is less than or equal to zero");
	   claimInterval = newClaimInterval;
    }
	
    function _mint(address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable){
        super._burn(account, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable){
        ERC20VotesUpgradeable._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if(from == address(0) || to == address(0)){
            super._beforeTokenTransfer(from, to, amount);
        }else{
            revert("Non transferable token");
        }
    }
	
    function _delegate(address delegator, address delegatee) internal virtual override {
        super._delegate(delegator,delegatee);
    }
	
    function _authorizeUpgrade(address) internal view override {
        require(owner() == msg.sender, "Only owner can upgrade implementation");
    }
	
}