// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeMath.sol";

/*

Linq - A new Paradigm

A simple drip feed staking contract which takes deposits in Linq Lp token, and gives you a set 
Ethereum claimable amount per block while you are locked. 

This is a V1 Staking contract for Linq LP, this is unaudited software so use at your own risk. 
A V2 contract will be released 1-2 weeks after V1 and will be audited, users will be recommended 
to move to that pool, When the V2 contract is deployed this contract will be discontinued by shutting off 
staking deposits via the stake_lockdown function. Withdraws will remain open, and funds will be added while users are staked.

There is a Bad Actor mapping to tag users who potentially are looking to game the contract, we are watching, you will be seen.
Play Nice, you get one warning.

0xA8A837E2bf0c37fEf5C495951a0DFc33aaEAD57A
714000000000000

*/





contract LinqStakingV1 is Ownable, ReentrancyGuard {


    struct StakingDetails {
        uint256 amount;
        uint256 deposit_time;
        uint256 unlock_time;
        uint256 last_claim_time;
        bool participant;
    }

    using SafeMath for uint256;

    address public LP_token_address;
    IERC20 public LP_token;

    uint256 public locking_period;

    bool public claim_enabled = false;
    bool public lock_enabled = true;
    bool public stake_lockdown = true;

 

    uint256 public total_lp_tokens;
    uint256 public depositors;
    uint256 public eth_per_block;
    uint check_threshold = 500;

    bool public emergencyMeasures = false;

    uint256 minThreshold = 1000000000000000000;

    event RewardsAdded(uint256 deposit_amount, uint256 time);
    event RunningLowOnRewards(uint256 left_remaining, uint256 time);
    event Claimed(address account, uint256 amount_due, uint256 time);
    event LargeDeposit(address account, uint256 amount, uint256 time);

    mapping(address => StakingDetails) public stake_details;
    mapping(address => bool) public BadActor;

    constructor(address _pair, uint256 block_reward) {
        LP_token = IERC20(_pair);
        LP_token_address = _pair;

        eth_per_block = block_reward;
        locking_period = 110960;
    }

    receive() external payable {}

    function returnLPbalance() public view returns (uint256) {
        return LP_token.balanceOf(address(this));
    }

    function returnETHbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function fetchEthPerBlock() internal view returns (uint256) {
        return eth_per_block;
    }

    function UpdateAllSettings(
        bool claim_state,
        bool lock_state,
        bool stake_lock_state
    ) public onlyOwner {
        enable_claim(claim_state);
        toggle_lock(lock_state);
        toggle_stake_lock(stake_lock_state);
    }

    function init() public onlyOwner {
        enable_claim(true);
        toggle_lock(true);
        toggle_stake_lock(false);
    }

    function emergencymeasuresstate(bool state) public onlyOwner {
        emergencyMeasures = state;
    }

    function DepositRewards() public payable onlyOwner {
        emit RewardsAdded(msg.value, block.timestamp);
    }

    function enable_claim(bool state) public onlyOwner {
        claim_enabled = state;
    }

    function declare_bad_actor(address account, bool state) public onlyOwner {
        BadActor[account] = state;
    }

    function changeEthPerBock(uint256 newvalue) public onlyOwner {
        eth_per_block = newvalue;
    }

    function changeLockingPeriod(uint256 newtime) public onlyOwner {
        require(newtime <= 500000, "Can't set lock longer then 2 months");
        locking_period = newtime;
    }

    // if there is a deposit lock for 2 weeks
    function toggle_lock(bool state) public onlyOwner {
        lock_enabled = state;
    }

    // deposits on/off
    function toggle_stake_lock(bool state) public onlyOwner {
        stake_lockdown = state;
    }

    function change_threshold(uint amount) public onlyOwner {
        check_threshold = amount;
    }

    // have to approve the vault on the pair contract first
    function Deposit_LP(uint256 amount) public nonReentrant {
        require(stake_lockdown == false, " cannot stake at this time ");
        require(!BadActor[msg.sender]);
        require(amount > 0);
        amount = amount * 10**18;
        if(amount > check_threshold){
            emit LargeDeposit(msg.sender, amount, block.timestamp);
        }
        if (stake_details[msg.sender].participant == true) {
            if(claim_enabled){
            internalClaim(msg.sender); }
            stake_details[msg.sender].amount += amount;
            LP_token.transferFrom(msg.sender, address(this), amount);
            total_lp_tokens += amount;
        } else {
            bool success = LP_token.transferFrom(
                msg.sender,
                address(this),
                amount
            );
            require(success);
            depositors += 1;

            stake_details[msg.sender].amount += amount;

            stake_details[msg.sender].participant = true;

            stake_details[msg.sender].deposit_time = block.timestamp;

            stake_details[msg.sender].last_claim_time = block.timestamp;

            stake_details[msg.sender].unlock_time =
                block.timestamp +
                locking_period;

            total_lp_tokens += amount;
        }
    }

    function WithdrawLP() public nonReentrant {
        require(stake_details[msg.sender].participant == true);
        require(!BadActor[msg.sender]);
        if (lock_enabled) {
            require(
                stake_details[msg.sender].deposit_time + locking_period <=
                    block.timestamp,
                "your still locked wait until block.timestamp is later then your lock period"
            );
        }

        if (stake_details[msg.sender].last_claim_time < block.timestamp) {
            if(claim_enabled){
            internalClaim(msg.sender);
            }
        }

        stake_details[msg.sender].participant = false;
        depositors -= 1;
        bool success = LP_token.transfer(
            msg.sender,
            stake_details[msg.sender].amount
        );
        require(success);
        total_lp_tokens -= stake_details[msg.sender].amount;
        stake_details[msg.sender].amount = 0;
        
    }

    function EmergencyUnstake() public nonReentrant {
        require(emergencyMeasures == true, "can only use in emergency state");
        require(stake_details[msg.sender].participant == true);
        require(!BadActor[msg.sender]);
        if (lock_enabled) {
            require(
                stake_details[msg.sender].deposit_time + locking_period <=
                    block.timestamp,
                "your still locked wait until block.timestamp is later then your lock period"
            );
        }
        stake_details[msg.sender].participant = false;
        depositors -= 1;
        bool success = LP_token.transfer(
            msg.sender,
            stake_details[msg.sender].amount
        );
        require(success);
        total_lp_tokens -= stake_details[msg.sender].amount;
        stake_details[msg.sender].amount = 0;
    }

    function internalClaim(address account) private {
        require(claim_enabled, " claim has not been enabled yet ");
        require(
            stake_details[account].participant == true,
            " not recognized as acive staker"
        );
        require(
            block.timestamp > stake_details[account].last_claim_time,
            "you can only claim once per block"
        );

        stake_details[account].last_claim_time = block.timestamp;

        uint256 amount_due = getPendingReturns(account);

        if (amount_due == 0) {
            return;
        }

        (bool success, ) = payable(account).call{value: amount_due}("");
        require(success);

        emit Claimed(account, amount_due, block.timestamp);

        if (address(this).balance <= minThreshold) {
            emit RunningLowOnRewards(address(this).balance, block.timestamp);
        }
    }

    function Claim() public nonReentrant {
        require(!BadActor[msg.sender]);
        require(claim_enabled, " claim has not been enabled yet ");
        require(
            stake_details[msg.sender].participant == true,
            " not recognized as active staker"
        );
        require(
            block.timestamp > stake_details[msg.sender].last_claim_time,
            "you can only claim once per block"
        );
        require(
            block.timestamp <= stake_details[msg.sender].deposit_time + locking_period,
            "you must re-lock your LP for another lock duration before claiming again Withraw will auto claim rewards"
        );

        uint256 amount_due = getPendingReturns(msg.sender);

        stake_details[msg.sender].last_claim_time = block.timestamp;

        if (amount_due == 0) {
            return;
        }

        (bool success, ) = payable(msg.sender).call{value: amount_due}("");
        require(success);

        emit Claimed(msg.sender, amount_due, block.timestamp);

        if (address(this).balance <= minThreshold) {
            emit RunningLowOnRewards(address(this).balance, block.timestamp);
        }
    }

    function Compound() public nonReentrant {
        require(!BadActor[msg.sender]);
        require(
            stake_lockdown == false,
            "stake lockdown active, please remove your tokens, or wait for activation"
        );
        require(
            stake_details[msg.sender].participant == true,
            " not recognized as acive staker"
        );
        if (lock_enabled) {
            require(
                stake_details[msg.sender].deposit_time + locking_period <=
                    block.timestamp,
                "your still locked - wait for lock duration to time out "
            );
        }

        if (stake_details[msg.sender].last_claim_time < block.timestamp) {
            internalClaim(msg.sender);
        }

        stake_details[msg.sender].deposit_time = block.timestamp;

        stake_details[msg.sender].last_claim_time = block.timestamp;
        stake_details[msg.sender].unlock_time =
            block.timestamp +
            locking_period;
    }

    function getTimeInPool(address account) public view returns(uint256){
        return stake_details[account].deposit_time - block.timestamp;
    }


    function getTimeleftTillUnlock(address account) public view returns(uint256){
        return stake_details[account].deposit_time + locking_period - block.timestamp;
    }

    function getPendingReturns(address account) public view returns (uint256) {
        uint256 reward_blocks = block.timestamp -
            stake_details[account].last_claim_time;
        uint256 reward_rate = fetchEthPerBlock();
        uint256 amount_due = ((reward_rate * users_pool_percentage(account)) /
            10000) * reward_blocks;
        return amount_due;
    }

    function users_pool_percentage(address account)
        public
        view
        returns (uint256)
    {
        uint256 userStake = stake_details[account].amount;
        uint256 totalSupply = LP_token.balanceOf(address(this));

        if (totalSupply == 0) {
            return 0; // Avoid division by zero
        }

        uint256 percentage = (userStake * 10000) / totalSupply;

        return percentage;
    }

    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }


    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: ETHbalance}("");
        require(success);
    }
}