pragma solidity 0.8.6;


// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Staking3Months is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _stakes;

    string public name;
    uint256 public immutable stakingStarts;
    uint256 public immutable stakingEnds;
    uint256 public stakingCap;// = 1000000 ether;
    uint256 public depositTime;//= 90 days;
    uint256 public rewardPerc;// = 175; //17.5 %
    uint256 public stakedTotal;
    address public rewardAddress;
    bool private depositEnabled = true;

    IERC20 immutable token;

    mapping(address => uint256) public deposited;

    event Staked(
        address indexed token,
        address indexed staker_,
        uint256 requestedAmount_,
        uint256 stakedAmount_
    );
    event PaidOut(
        address indexed token,
        address indexed staker_,
        uint256 amount_,
        uint256 reward_
    );

    event EmergencyWithdrawDone(
        address indexed sender,
        address indexed token,
        uint256 amount_
    );

    event EmergencyWithdrawAdminDone(
        address indexed sender,
        address indexed token,
        uint256 amount_
    );

    event DepositEnabledSet(bool value);

    event StakingCapSet(uint256 value);
    event DepositTimeSet(uint256 value);
    event RewardPercSet(uint256 value);

    event RewardAddressChanged(
        address indexed sender,
        address indexed rewardAddress
    );

    modifier _after(uint256 eventTime) {
        require(
            block.timestamp >= eventTime,
            "Error: bad timing for the request"
        );
        _;
    }

    modifier _before(uint256 eventTime) {
        require(
            block.timestamp < eventTime,
            "Error: bad timing for the request"
        );
        _;
    }

    constructor(string memory name_, address _token, uint256 _stakingStarts, uint256 _stakingEnds, address _rewardAddress,
        uint256 _rewardPerc, uint256 _depositTime, uint256 _stakingCap) {
        require(_rewardAddress != address(0), "_rewardAddress should not be 0");
        name = name_;
        token = IERC20(_token);
        stakingStarts = _stakingStarts; 
        stakingEnds = _stakingEnds; 
        rewardAddress = _rewardAddress;
        rewardPerc = _rewardPerc;
        depositTime = _depositTime;
        stakingCap = _stakingCap;
    }

    function stakeOf(address account) external view returns (uint256) {
        return _stakes[account];
    }

    function timeStaked(address account) external view returns (uint256) {
        return deposited[account];
    }

    function canWithdraw(address _addy) external view returns (bool) {
        if (block.timestamp >= deposited[_addy]+(depositTime)) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Requirements:
     * - `amount` Amount to be staked
     */
    function stake(uint256 amount)
        external
    {
        require(depositEnabled,"Deposits not enabled");
        _stake(msg.sender, amount);
    }

    function withdraw()
        external
    {
        require(
            block.timestamp >= deposited[msg.sender]+(depositTime),
            "Error: Staking period not passed yet"
        );
        _withdrawAfterClose(msg.sender, _stakes[msg.sender]);
    }

    function _withdrawAfterClose(address from, uint256 amount) private {
        uint256 reward = amount*(rewardPerc)/(1000);

        _stakes[from] = _stakes[from]-(amount);
        stakedTotal = stakedTotal-(amount);

        emit PaidOut(address(token), from, amount, reward);
        token.safeTransferFrom(rewardAddress, from, reward); //transfer Reward
        token.safeTransfer(from, amount); //transfer initial stake
    }

    function _stake(address staker, uint256 amount)
        private
        _after(stakingStarts)
        _before(stakingEnds)
    {
        // check the remaining amount to be staked
        uint256 remaining = amount;
        if (remaining > (stakingCap-(stakedTotal))) {
            remaining = stakingCap-(stakedTotal);
        }
        // These requires are not necessary, because it will never happen, but won't hurt to double check
        // this is because stakedTotal is only modified in this method during the staking period
        require(remaining > 0, "Error: Staking cap is filled");
        require(
            (remaining+(stakedTotal)) <= stakingCap,
            "Error: this will increase staking amount pass the cap"
        );

        stakedTotal = stakedTotal+(remaining);
        _stakes[staker] = _stakes[staker]+(remaining);
        deposited[msg.sender] = block.timestamp;

        emit Staked(address(token), staker, amount, remaining);

        token.safeTransferFrom(staker, address(this), remaining);
    }

    function setRewardPerc(uint256 _rewardPerc) external onlyOwner{
        rewardPerc = _rewardPerc;
        emit RewardPercSet(_rewardPerc);

    }

    function setDepositTime(uint256 _depositTime) external onlyOwner{
        depositTime = _depositTime;
        emit DepositTimeSet(_depositTime);

    }

    function setStakingCap(uint256 _stakingCap) external onlyOwner{
        stakingCap = _stakingCap;
        emit StakingCapSet(_stakingCap);

    }

    function emergencyWithdraw() external {
        uint256 stakesAmount = _stakes[msg.sender];

        stakedTotal = stakedTotal-(stakesAmount);

        _stakes[msg.sender] = 0;
        emit EmergencyWithdrawAdminDone(msg.sender,address(token), stakesAmount);
        token.safeTransfer(msg.sender,stakesAmount);
    }

    function emergencyWithdrawAdmin() external onlyOwner {
        depositEnabled = false;
        uint256 amount = token.balanceOf(address(this));
        emit EmergencyWithdrawAdminDone(msg.sender,address(token), amount);
        token.safeTransfer(msg.sender,amount);
    }

    function setDepositEnabled() external onlyOwner {
        depositEnabled = !depositEnabled;
        emit DepositEnabledSet(depositEnabled);
    }

    function changeRewardAddress(address _address) external onlyOwner {
        require(_address != address(0), "Address should not be 0");
        rewardAddress = _address;
        emit RewardAddressChanged(msg.sender,_address);
    }
}