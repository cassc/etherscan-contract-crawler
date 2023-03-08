//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author Lumishare
 *
 * @notice contract that
 */
contract ColdStaking is Ownable {
    struct Stake {
        uint256 stakeId;
        address stakerAddress;
        uint256 amountStaked;
        uint256 finalReward;
        uint256 deadline;
    }

    event NewStake(
        uint256 stakeId,
        address indexed stakerAddress,
        uint256 amountStaked,
        uint256 deadline
    );

    event StakePaid(
        uint256 stakeId,
        address indexed stakerAddress,
        uint256 amountStaked,
        uint256 deadline
    );

    event StakingStarted();
    event StakingStopped();
    event BalanceAddedToStaking(uint256 amount);
    event BalanceWithdrawnFromStaking(uint256 amount);

    mapping(uint256 => Stake) public stakes;

    uint256 public stakeCounter;

    address public admin;

    // How much stake reward is already being expected;
    uint256 internal _totalReward;

    bool public stakingActive;

    //  user address => his amount of stakedBalance
    mapping(address => uint256) public stakedBalance;

    uint256 public stakingBalance;

    constructor(uint256 _stakingBalance) {
        stakingBalance = _stakingBalance;
    }

    function stake(uint256 amount, uint256 hourAmount) external {
        require(stakingActive, "Staking is not active");
        require(amount > 0, "amount = 0");

        require(hourAmount >= 720, "Minimum time staked is one month");

        require(hourAmount <= 8760, "Maximum time staked is one year");
        require(
            IERC20(address(this)).balanceOf(msg.sender) >=
                stakedBalance[msg.sender] + amount,
            "Don't have any unlocked tokens to stake"
        );

        // Calculate if contract has enough money to pay

        //     APYBase = 6 %
        //     APYExtraHour = 0.0328358/24 %                                 hours
        //     finalReward = amount * (APYBase+ hours*(APYExtraHour))  *    ------
        //                                                                    8760

        uint256 finalReward = ((amount * 6 * hourAmount) /
            100 +
            (amount * hourAmount**2 * 13681583) /
            1000000000000) / 8760;

        //
        //  BC = SRG balance of contract
        //  TR = How much token is already saved to pay for current stakers
        //  FR = The final reward of staker after his locked duration ends
        //
        //  BC - TR >= FR

        require(
            stakingBalance - _totalReward >= finalReward,
            "Contract doesn't have enough SRG Token to give rewards"
        );

        _totalReward += finalReward;
        stakedBalance[msg.sender] += amount;

        uint256 stakeId = stakeCounter++;
        Stake storage newStake = stakes[stakeId];

        newStake.deadline = block.timestamp + hourAmount * (1 hours);
        newStake.amountStaked = amount;
        newStake.finalReward = finalReward;
        newStake.stakeId = stakeId;
        newStake.stakerAddress = msg.sender;

        emit NewStake(stakeId, msg.sender, amount, newStake.deadline);
    }

    function unStake(uint256 stakeId) external {
        require(
            stakes[stakeId].stakerAddress == msg.sender,
            "Only staker can withdraw"
        );

        require(
            stakes[stakeId].deadline <= block.timestamp,
            "Stake has not expired"
        );

        uint256 reward = stakes[stakeId].finalReward;
        _totalReward -= reward;
        stakingBalance -= reward;
        stakedBalance[msg.sender] -= stakes[stakeId].amountStaked;

        emit StakePaid(
            stakeId,
            msg.sender,
            stakes[stakeId].amountStaked,
            stakes[stakeId].deadline
        );

        delete stakes[stakeId];
        IERC20(address(this)).transfer(msg.sender, reward);
    }

    function setAdminAddress(address _admin) external onlyOwner {
        require(_admin != address(0x0));
        admin = _admin;
    }

    // Function to start staking for everyone
    function startStaking() public onlyOwner {
        stakingActive = true;

        // Emit the StakingStarted event
        emit StakingStarted();
    }

    // Function to stop/pause staking
    function stopStaking() public onlyOwner {
        stakingActive = false;

        // Emit the StakingStopped event
        emit StakingStopped();
    }

    /**
     * @dev this function adds more balance to coldstaking mechanism
     * @param amount, the amount of tokens that owner will send

     */
    function addBalanceToStaking(uint256 amount) public onlyOwner {
        IERC20(address(this)).transferFrom(msg.sender, address(this), amount);

        stakingBalance += amount;
        emit BalanceAddedToStaking(amount);
    }

    /**
     * @dev this function  withdraws balance from the coldstaking
     * @param amount, the amount of tokens that owner will withdraw

     */
    function withdrawBalanceFromStaking(uint256 amount) public onlyOwner {
        require(stakingBalance > 0, "staking balance empty");
        IERC20(address(this)).transfer(msg.sender, amount);

        stakingBalance -= amount;
        emit BalanceWithdrawnFromStaking(amount);
    }
}