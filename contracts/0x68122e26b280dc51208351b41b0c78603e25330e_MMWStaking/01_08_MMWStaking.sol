// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MMWStaking is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public mmwAddress;

    uint256 public constant ROI_PERCENTAGE = 500; // 500%
    uint256 public constant TOTAL_PERCENTAGE = 100; // 100%
    uint256 public constant TOTAL_NUMBER_OF_DAYS = 365 days;
    uint256 public constant MIN_STAKE_TIME = 3 days;
    uint256 public totalLiquidityProvided;

    struct DepositStruct {
        address investor;
        uint256 amountStaked;
        uint256 maxReward;
        uint256 rewardClaimed;
        uint256 stakedDate;
        uint256 lastClaimedDate;
        bool isWithdrawn;
    }

    uint256 public currentDepositID;
    mapping(address => uint256[]) public ownedDeposits;
    mapping(uint256 => DepositStruct) public depositData;
    uint256 public totalStaked;
    uint256 public totalWithdrawn;

    constructor(address _mmwAddress) {
        require(_mmwAddress != address(0), "Invalid MMW Address");
        mmwAddress = _mmwAddress;
    }

    function setMMWAddress(address _mmwAddress) external onlyOwner {
        require(_mmwAddress != address(0), "Invalid MMW Address");
        mmwAddress = _mmwAddress;
    }

    function invest(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        currentDepositID = currentDepositID.add(1);

        uint256 _id = currentDepositID;

        uint256 totalWithdrawal = _amount
            .mul(ROI_PERCENTAGE)
            .div(TOTAL_PERCENTAGE)
            .add(_amount);

        ownedDeposits[msg.sender].push(_id);

        depositData[_id] = DepositStruct({
            investor: msg.sender,
            amountStaked: _amount,
            maxReward: totalWithdrawal,
            stakedDate: block.timestamp,
            isWithdrawn: false,
            rewardClaimed: 0,
            lastClaimedDate: block.timestamp
        });

        totalStaked = totalStaked.add(_amount);
        IERC20(mmwAddress).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function getTotalRewardForSingleId(
        uint256 _id
    ) public view returns (uint256) {
        DepositStruct memory deposit = depositData[_id];
        uint256 totalReward = 0;
        if (deposit.isWithdrawn == false) {
            uint256 totalDays = block
                .timestamp
                .sub(deposit.lastClaimedDate)
                .div(1 days);
            totalReward = deposit
                .amountStaked
                .mul(totalDays)
                .mul(ROI_PERCENTAGE)
                .div(TOTAL_PERCENTAGE)
                .div(365);
        }
        return totalReward;
    }

    function getTotalReward(address _investor) public view returns (uint256) {
        uint256 length = ownedDeposits[_investor].length;
        uint256 totalReward = 0;
        for (uint256 i = 0; i < length; i++) {
            totalReward = totalReward.add(
                getTotalRewardForSingleId(ownedDeposits[_investor][i])
            );
        }
        return totalReward;
    }

    function claimReward() external {
        require(
            getTotalReward(msg.sender) > 0,
            "You don't have any rewards to claim"
        );

        uint256 length = ownedDeposits[msg.sender].length;
        uint256 totalReward = 0;
        for (uint256 i = 0; i < length; i++) {
            uint256 id = ownedDeposits[msg.sender][i];
            DepositStruct storage deposit = depositData[id];
            if (deposit.isWithdrawn == false) {
                uint256 totalDays = block
                    .timestamp
                    .sub(deposit.lastClaimedDate)
                    .div(1 days);
                if (totalDays < MIN_STAKE_TIME) {
                    continue;
                }

                if (totalDays > 365) {
                    totalDays = 365;
                }

                uint256 reward = deposit
                    .amountStaked
                    .mul(totalDays)
                    .mul(ROI_PERCENTAGE)
                    .div(TOTAL_PERCENTAGE)
                    .div(365);
                totalReward = totalReward.add(reward);
                deposit.lastClaimedDate = block.timestamp;
                deposit.rewardClaimed = deposit.rewardClaimed.add(reward);
            }
        }
        IERC20(mmwAddress).safeTransfer(msg.sender, totalReward);
    }

    function unstakeInvestment(uint256 _investmentId) external {
        require(
            depositData[_investmentId].investor == msg.sender,
            "You are not the owner of this investment"
        );

        require(
            depositData[_investmentId].isWithdrawn == false,
            "You have already withdrawn this investment"
        );

        uint256 amount = depositData[_investmentId].amountStaked;
        // if minimum stake time is passed, then calculate reward
        uint256 totalDaysSinceStake = block
            .timestamp
            .sub(depositData[_investmentId].stakedDate)
            .div(1 days);

        uint256 totalCalculationDays = block
            .timestamp
            .sub(depositData[_investmentId].lastClaimedDate)
            .div(1 days);

        if (totalDaysSinceStake >= MIN_STAKE_TIME) {
            uint256 reward = depositData[_investmentId]
                .amountStaked
                .mul(totalCalculationDays)
                .mul(ROI_PERCENTAGE)
                .div(TOTAL_PERCENTAGE)
                .div(365);
            amount = amount.add(reward);
        }

        depositData[_investmentId].isWithdrawn = true;
        depositData[_investmentId].lastClaimedDate = block.timestamp;

        totalStaked = totalStaked.sub(depositData[_investmentId].amountStaked);

        IERC20(mmwAddress).safeTransfer(msg.sender, amount);
    }

    function getMMWBalance() public view returns (uint256 totalMmwBalance) {
        totalMmwBalance = IERC20(mmwAddress).balanceOf(address(this));
    }

    function getMMWLiquidity() public view returns (uint256 totalMmwBalance) {
        totalMmwBalance = totalLiquidityProvided;
    }

    function addLiquidity(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        totalLiquidityProvided = totalLiquidityProvided.add(_amount);
        IERC20(mmwAddress).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function removeLiquidity(uint256 _amount) external onlyOwner {
        require(_amount <= totalLiquidityProvided, "Insufficient liquidity");
        totalLiquidityProvided = totalLiquidityProvided.sub(_amount);
        IERC20(mmwAddress).safeTransfer(msg.sender, _amount);
    }

    function getOwnedDeposits(
        address _investors
    ) public view returns (uint256[] memory) {
        return ownedDeposits[_investors];
    }
}