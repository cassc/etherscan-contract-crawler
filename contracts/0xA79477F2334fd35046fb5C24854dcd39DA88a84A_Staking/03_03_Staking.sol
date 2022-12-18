// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Staking{

    event StakeLimitUpdated(Stake);
    event AmountStaked(address userAddress, uint256 level, uint256 amount);
    event Withdraw(address userAddress, uint256 withdrawAmount);
    event OwnershipTransferred(address owner, address newOwner);
    event Paused(address ownerAddress);
    event Unpaused(address ownerAddress);
    event TokenRecovered(address tokenAddress, address walletAddress);

    address public owner;
    IERC20 public token;
    bool private _paused;
    uint256 public reserveAmount;

    struct UserDetail {
        uint256 level;
        uint256 amount;
        uint256 initialTime;
        uint256 endTime;
        uint256 rewardAmount;
        uint256 withdrawAmount;
        bool status;
    }

    struct Stake {
        uint256 rewardFeePermile;
        uint256 stakeLimit;
        uint256 penaltyFeePermile;
    }

    mapping(address =>mapping(uint256 => UserDetail)) internal users;
    mapping(uint256 => Stake) internal stakingDetails;

    modifier onlyOwner() {
        require(owner == msg.sender,"Ownable: Caller is not owner");
        _;
    }

    constructor (IERC20 _token) {
        token = _token;

        stakingDetails[1] = Stake(30, 90 days, 35);
        stakingDetails[2] = Stake(65, 180 days, 65);
        stakingDetails[3] = Stake(140, 365 days, 140);

        owner = msg.sender;
    }

    function stake(uint256 amount, uint256 level)
        external
        returns(bool)
    {
        require(level > 0 && level <= 3, "Invalid level");
        require(!(users[msg.sender][level].status),"user already exist");
        require(_paused == false, "Function Paused");

        users[msg.sender][level].amount = amount;
        users[msg.sender][level].level = level;
        users[msg.sender][level].endTime = block.timestamp + stakingDetails[level].stakeLimit;        
        users[msg.sender][level].initialTime = block.timestamp;
        users[msg.sender][level].status = true;
        token.transferFrom(msg.sender, address(this), amount);
        addReserve(level);
       emit AmountStaked(msg.sender, level, amount);
        return true;
    }

    function getRewards(address account, uint256 level)
        internal
        view
        returns(uint256)
    {
        if(users[account][level].endTime <= block.timestamp) {
            uint256 stakeAmount = users[account][level].amount;
            uint256 rewardRate = stakingDetails[users[account][level].level].rewardFeePermile;
            uint256 rewardAmount = (stakeAmount * rewardRate / 1000);
            return rewardAmount;
        }
        else {
            return 0;
        }
    }

    function withdraw(uint256 level)
        external
        returns(bool)
    {
        require(level > 0 && level <= 3, "Invalid level");
        require(users[msg.sender][level].status, "user not exist");
        require(users[msg.sender][level].endTime <= block.timestamp, "staking end time is not reached");
        uint256 rewardAmount = getRewards(msg.sender, level);
        uint256 amount = rewardAmount + users[msg.sender][level].amount;
        token.transfer(msg.sender, amount);

        uint256 rAmount = rewardAmount + users[msg.sender][level].rewardAmount;
        uint256 wAmount = amount + users[msg.sender][level].withdrawAmount;
        removeReserve(level);
        users[msg.sender][level] = UserDetail(0, 0, 0, 0, rAmount, wAmount, false);
        emit Withdraw(msg.sender, amount);
        return true;
    }

    function emergencyWithdraw(uint256 level)
        external
        returns(uint256)
    {
        require(level > 0 && level <= 3, "Invalid level");
        require(users[msg.sender][level].status, "user not exist");
        uint256 stakedAmount = users[msg.sender][level].amount;
        uint256 penalty = stakedAmount * stakingDetails[level].penaltyFeePermile / 1000;
        token.transfer(msg.sender, stakedAmount - penalty);
        token.transfer(address(this), penalty);
        uint256 rewardAmount = users[msg.sender][level].rewardAmount;
        uint256 withdrawAmount = users[msg.sender][level].withdrawAmount;
        removeReserve(level);
        users[msg.sender][level] = UserDetail(0, 0, 0, 0, rewardAmount, withdrawAmount, false);

        emit Withdraw(msg.sender, stakedAmount);
        return stakedAmount;
    }

    function transferOwnership(address newOwner)
        external
        onlyOwner
    {
        require(newOwner != address(0), "Invalid Address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, owner);
    }

    function getUserDetails(address account, uint256 level)
        external
        view
        returns(UserDetail memory, uint256 rewardAmount)
    {
        uint256 reward = getRewards(account, level);
        return (users[account][level], reward);
    }

    function getstakingDetails(uint256 level) external view returns(Stake memory){
        return (stakingDetails[level]);
    }

    function setStakeDetails(uint256 level, Stake memory _stakeDetails)
        external
        onlyOwner
        returns(bool)
    {
        require(level > 0 && level <= 3, "Invalid level");
        stakingDetails[level] = _stakeDetails;
        emit StakeLimitUpdated(stakingDetails[level]);
        return true;
    }

    function paused() external view returns(bool) {
        return _paused;
    }

    function pause() external onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function addReserve(uint256 level) internal {
        uint256 amount = (users[msg.sender][level].amount * stakingDetails[users[msg.sender][level].level].rewardFeePermile)/1000;
        reserveAmount += (users[msg.sender][level].amount + amount);
    }

    function removeReserve(uint256 level) internal {
        uint256 amount = (users[msg.sender][level].amount * stakingDetails[users[msg.sender][level].level].rewardFeePermile)/1000;
        reserveAmount -= (users[msg.sender][level].amount + amount);
    }

    function recoverToken(address _tokenAddress, address walletAddress)
        external
        onlyOwner
    {
        require(walletAddress != address(0), "Null address");
        require(IERC20(_tokenAddress).balanceOf(address(this)) > reserveAmount, "Insufficient amount");
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this)) - reserveAmount;
        bool success = IERC20(_tokenAddress).transfer(
            walletAddress,
            amount
        );
        require(success, "tx failed");
        emit TokenRecovered(_tokenAddress, walletAddress);
    }

}