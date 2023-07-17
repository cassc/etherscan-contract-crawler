pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";
import "./SafeMath.sol";
import "./LendingWhiteList.sol";
import "./EnumerableSet.sol";
import "./owned.sol";

contract EsgSHIP is owned, LendingWhiteList {
	using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _set;

    /// @notice ESG token
    EIP20Interface public esg;

    /// @notice Emitted when referral set referral
    event SetReferral(address referralAddress);

    /// @notice Emitted when ESG is staked  
    event EsgStaked(address account, uint amount);

    /// @notice Emitted when ESG is withdrawn 
    event EsgWithdrawn(address account, uint amount);

    /// @notice Emitted when ESG is claimed 
    event EsgClaimed(address account, uint amount);

    // @notice The rate every day. 
    uint256 public dayEsgRate; 

    // @notice A checkpoint for staking
    struct Checkpoint {
        uint256 deposit_time; //last check time
        uint256 total_staked;
        uint256 bonus_unclaimed;
    }

    // @notice staking struct of every account
    mapping (address => Checkpoint) public stakings;

    mapping (address => EnumerableSet.AddressSet) inviteelist;//1:n

	struct User {
        address referrer_addr;
    }

    mapping (address => User) referrerlist;//1:1

    // @notice total stake amount
    uint256 public total_deposited;
    uint256 public referrer_rate;
    uint256 public ship_rate;
    uint256 public referrer_limit_num;
    uint256 public referrer_reward_limit_num;
    uint256 public ship_reward_limit_num;

    constructor(address esgAddress) public {
        owner = msg.sender;
		dayEsgRate = 1.37e15;
		referrer_rate = 2e17;
	    ship_rate = 8e16;
	    referrer_limit_num = 1e21;
	    referrer_reward_limit_num = 1e21;
	    ship_reward_limit_num = 1e23;
		esg = EIP20Interface(esgAddress);
    }

    function setInvitee(address inviteeAddress) public returns (bool) {
    	require(inviteeAddress != address(0), "inviteeAddress should not be 0x0.");

    	EnumerableSet.AddressSet storage es = inviteelist[msg.sender];
    	User storage user = referrerlist[inviteeAddress];
    	require(user.referrer_addr == address(0), "This account had been invited!");

    	Checkpoint storage cpt = stakings[inviteeAddress];
    	require(cpt.total_staked == 0, "This account had staked!");

    	Checkpoint storage cp = stakings[msg.sender];

    	if(isWhitelisted(msg.sender)){
    		EnumerableSet.add(es, inviteeAddress);  	
	    	user.referrer_addr = msg.sender;
	    }else{
	    	if(cp.total_staked >= referrer_limit_num){
	    		EnumerableSet.add(es, inviteeAddress);
		    	user.referrer_addr = msg.sender;
		    }else{
		        return false;
		    }
	    }
    	emit SetReferral(inviteeAddress);
        return true;   
    }

    function getInviteelist(address referrerAddress) public view returns (address[] memory) {
    	require(referrerAddress != address(0), "referrerAddress should not be 0x0.");
    	EnumerableSet.AddressSet storage es = inviteelist[referrerAddress];
    	uint256 _length = EnumerableSet.length(es);
    	address[] memory _inviteelist = new address[](_length);
    	for(uint i=0; i<EnumerableSet.length(es); i++){
    		_inviteelist[i] = EnumerableSet.at(es,i);
    	}
    	return _inviteelist;
    }

    function getReferrer(address inviteeAddress) public view returns (address) {
    	require(inviteeAddress != address(0), "inviteeAddress should not be 0x0.");
    	User storage user = referrerlist[inviteeAddress];
    	return user.referrer_addr;
    }

    /**
     * @notice Stake ESG token to contract 
     * @param amount The amount of address to be staked 
     * @return Success indicator for whether staked 
     */
    function stake(uint256 amount) public returns (bool) {
		require(amount > 0, "No zero.");
		require(amount <= esg.balanceOf(msg.sender), "Insufficient ESG token.");

		Checkpoint storage cp = stakings[msg.sender];

		esg.transferFrom(msg.sender, address(this), amount);

		if(cp.deposit_time > 0)
		{
			uint256 bonus = block.timestamp.sub(cp.deposit_time).mul(cp.total_staked).mul(dayEsgRate).div(1e18).div(86400);
			cp.bonus_unclaimed = cp.bonus_unclaimed.add(bonus);
			cp.total_staked = cp.total_staked.add(amount);
			cp.deposit_time = block.timestamp;
		}else
		{
			cp.total_staked = amount;
			cp.deposit_time = block.timestamp;
		}
	    total_deposited = total_deposited.add(amount);
		emit EsgStaked(msg.sender, amount);

		return true;
    }

    /**
     * @notice withdraw all ESG token staked in contract 
     * @return Success indicator for success 
     */
    function withdraw() public returns (bool) {
    	
    	Checkpoint storage cp = stakings[msg.sender];
		uint256 amount = cp.total_staked;
		uint256 bonus = block.timestamp.sub(cp.deposit_time).mul(cp.total_staked).mul(dayEsgRate).div(1e18).div(86400);
		cp.bonus_unclaimed = cp.bonus_unclaimed.add(bonus);
		cp.total_staked = 0;
		cp.deposit_time = 0;
	    total_deposited = total_deposited.sub(amount);
		
		esg.transfer(msg.sender, amount);

		emit EsgWithdrawn(msg.sender, amount); 

		return true;
    }

    /**
     * @notice claim all ESG token bonus in contract 
     * @return Success indicator for success 
     */
    function claim() public returns (bool) {
		User storage user = referrerlist[msg.sender];
    	address _referrer_addr = user.referrer_addr;
    	uint256 incentive;
    	uint256 incentive_holder;

		Checkpoint storage cp = stakings[msg.sender];
		Checkpoint storage cpt = stakings[_referrer_addr];

		uint256 amount = cp.bonus_unclaimed;
		if(cp.deposit_time > 0)
		{
			uint256 bonus = block.timestamp.sub(cp.deposit_time).mul(cp.total_staked).mul(dayEsgRate).div(1e18).div(86400);
			amount = amount.add(bonus);
			cp.bonus_unclaimed = 0; 
			cp.deposit_time = block.timestamp;
			
		}else{
			//has beed withdrawn
			cp.bonus_unclaimed = 0;
		}

		if(total_deposited >= ship_reward_limit_num){
			incentive_holder = amount.mul(ship_rate).div(1e18);
			if(_referrer_addr != address(0)){
				if(cpt.total_staked >= referrer_reward_limit_num){
					incentive = amount.mul(referrer_rate).div(1e18);
					esg.transfer(_referrer_addr, incentive);
				}
				esg.transfer(owner, incentive_holder);
				esg.transfer(msg.sender, amount);
    		}else
	    	{
	    		esg.transfer(owner, incentive_holder);
	    		esg.transfer(msg.sender, amount.sub(incentive_holder));
	    	}
		}else
		{
			if(_referrer_addr != address(0)){
				if(cpt.total_staked >= referrer_reward_limit_num){
					incentive = amount.mul(referrer_rate).div(1e18);
					esg.transfer(_referrer_addr, incentive);
				}
				esg.transfer(msg.sender, amount);
    		}else
	    	{
	    		esg.transfer(msg.sender, amount);
	    	}
		}

		emit EsgClaimed (msg.sender, amount); 

		return true;
    }

    // set the dayrate
    function setDayEsgRate(uint256 dayRateMantissa) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    dayEsgRate = dayRateMantissa;
    }

    // set referrerRate
    function setReferrerRate(uint256 referrerRateMantissa) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    referrer_rate = referrerRateMantissa;
    }

    // set shipRate
    function setShipRate(uint256 shipRateMantissa) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    ship_rate = shipRateMantissa;
    }

    // set referrerLimitNum
    function setReferrerLimitNum(uint256 referrerLimitNum) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    referrer_limit_num = referrerLimitNum;
    }

    // set referrerRewardLimitNum
    function setReferrerRewardLimitNum(uint256 referrerRewardLimitNum) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    referrer_reward_limit_num = referrerRewardLimitNum;
    }

    // set shipRewardLimitNum
    function setShipRewardLimitNum(uint256 shipRewardLimitNum) public{
	    require(msg.sender == owner, "only owner can set this value.");
	    ship_reward_limit_num = shipRewardLimitNum;
    }

    function _withdrawERC20Token(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "invalid address");
        uint256 tokenAmount = esg.balanceOf(address(this));
        if(tokenAmount > 0)
            esg.transfer(msg.sender, tokenAmount);
        else
            revert("insufficient ERC20 tokens");
    }

    /**
     * @notice Returns the balance of ESG an account has staked
     * @param account The address of the account 
     * @return balance of ESG 
     */
    function getStakingBalance(address account) external view returns (uint256) {
		Checkpoint memory cp = stakings[account];
        return cp.total_staked;
    }

    /**
     * @notice Return the unclaimed bonus ESG of staking 
     * @param account The address of the account 
     * @return The amount of unclaimed ESG 
     */
    function getUnclaimedEsg(address account) public view returns (uint256) {
		Checkpoint memory cp = stakings[account];

		uint256 amount = cp.bonus_unclaimed;
		if(cp.deposit_time > 0)
		{
			uint256 bonus = block.timestamp.sub(cp.deposit_time).mul(cp.total_staked).mul(dayEsgRate).div(1e18).div(86400);
			amount = amount.add(bonus);
		}
		return amount;
    }

    /**
     * @notice Return the APY of staking 
     * @return The APY multiplied 1e18
     */
    function getStakingAPYMantissa() public view returns (uint256) {
        return dayEsgRate.mul(365);
    }

    /**
     * @notice Return the address of the ESG token
     * @return The address of ESG 
     */
    function getEsgAddress() public view returns (address) {
        return address(esg);
    }

}