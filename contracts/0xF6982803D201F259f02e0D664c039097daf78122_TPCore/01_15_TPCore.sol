// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// Openzeppelin imports
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Local imports
import {LiquidityToken} from "./LiquidityToken.sol";
import {IStrategy} from "./IStrategy.sol";
import "hardhat/console.sol";

contract TPCore is AccessControl {
    struct Staking {
        uint16 intervalNumber;
        uint104 amount;
        uint136 calculatedTPYs;
        uint104 pendingAmount;
        bool lastActionIsUnstake;
    }

    using SafeERC20 for IERC20;
    using SafeERC20 for LiquidityToken; //The users receive Liqudity Tokens to keep track of their stake in the USDC pool

    uint16 public ownerPercentage = 9000; //(this means the platform charges 10% fee on the profit) make sure when changing it to keep this formatting
    uint16 public ownerNewPercentage = 9000;
    uint32 public ownerPercentageLastChangeTS;
    uint32 public startingTS;


    // 48 bit minimum
    uint48 private startingTpyRewardPerInterval = 77000 * (10**8); //The amount of TPYs that will be distributed among the users based on the proportion of their stake in the USDC pool. The admin will be able to change the number in the future. 

    // 32 (max 1 year)
    uint32 public tpyInterval = 28 days;
    uint256 public takenTPY;

    mapping(address => Staking) private userStaking;
    uint256[1000] public intervalStakes;
    uint256[1000] public intervalUnstakes;
    mapping(uint256 => uint256) private tpyIntervalRewards;

    /// contracts
    LiquidityToken public liquidityToken;
    IStrategy public strategy;
    IERC20 public stakingcoin;
    IERC20 public tpy;

    /// Events
    event Minted(address indexed minter, uint256 amount);
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event TPYRewarded(address indexed staker, uint256 amount);
    event OwnerPercentageChanged(uint256 oldValue, uint256 amount);

    /// Constructor
    constructor(
        address stakingcoinAddress,
        address tpyTokenAddress,
        address initialStrategyAddress
    ) {
        startingTS = uint32(block.timestamp);
        ownerPercentageLastChangeTS = uint32(block.timestamp);
        tpyIntervalRewards[1] = startingTpyRewardPerInterval;
        strategy = IStrategy(initialStrategyAddress);
        require(
            address(0x0) != address(strategy),
            "Initialize correct strategy!"
        );
        liquidityToken = new LiquidityToken();

        stakingcoin = IERC20(stakingcoinAddress);
        tpy = IERC20(tpyTokenAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function withdraw(address tokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 amountToTransfer = token.balanceOf(address(this));

        if(tokenAddress == address(tpy)) {
            uint256 lockedTPYs = totalTPYEarned() - takenTPY;
            if(amountToTransfer <= lockedTPYs) {
                return;
            }
            else {
                amountToTransfer -= lockedTPYs;
            }
        }
        token.transfer(_msgSender(), amountToTransfer);
    }

    function changeOwnerPercentage(uint16 percentage)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            percentage <= 10000,
            "Percentage must be from 0 to 10000 (10000 means 100%)"
        );
        //The admin may change the profit fee charged to the users. After the admin makes this change, it will take 7 days before the changes come into effect. 
        if(uint32(block.timestamp) - ownerPercentageLastChangeTS < 7 days) {
            ownerNewPercentage = percentage;
            ownerPercentageLastChangeTS = uint32(block.timestamp);
        }
        else {
            ownerPercentage = ownerNewPercentage;
            ownerNewPercentage = percentage;
            ownerPercentageLastChangeTS = uint32(block.timestamp);
        }
        emit OwnerPercentageChanged(ownerPercentage, percentage);
    }

    function changeTPYPerIntervalReward(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tpyIntervalRewards[nextInterval()] = value;
    }

    function stake(uint104 amount) external {
        require(amount > 0, "The amount must be greater than 0.");
        uint256 allowance = stakingcoin.allowance(_msgSender(), address(this));
        require(
            amount <= allowance,
            "There is no as much allowance for staking coin."
        );

        uint256 totalRewardBeforeStake = strategy.estimateReward(address(this)); 

        stakingcoin.safeTransferFrom(_msgSender(), address(this), amount);

        ////Stakes into Yearn
        (bool success, bytes memory result) = address(strategy).delegatecall(
            abi.encodeWithSignature(
                "farm(address,uint256)",
                stakingcoin,
                amount
            )
        );
        require(success, "Staking to yearn failed");
        uint256 stakingCoinAmount = abi.decode(result, (uint256));

        uint256 liquidityAmount;
        uint256 totalReward = strategy.estimateReward(address(this));
        uint256 rewarDdifference = totalReward - totalRewardBeforeStake;        
        if (
            totalReward == 0 ||
            totalReward <= stakingCoinAmount ||                             
            liquidityToken.totalSupply() == 0
        ) {
            liquidityAmount = rewarDdifference;                             
        } else {
            liquidityAmount =
                (rewarDdifference * liquidityToken.totalSupply()) /      
                (totalReward - rewarDdifference);                           
        }

        liquidityToken.mint(_msgSender(), liquidityAmount);

        registerTPY(msg.sender, amount);

        emit Staked(_msgSender(), amount);
    }

    function unstake(uint104 amount) external {
        require(0 < amount, "The amount must be greater than 0.");
        uint256 totalReward = strategy.estimateReward(address(this));
        (uint104 gross, uint104 net, , ) = estimateRewardDetails(_msgSender());
        require(
            amount <= net,
            "Dont be greedy (the amount must be less than or equal to net rewards)."
        );

        uint104 wantedGross = (amount * gross) / net;

        uint256 liquidityAmount = liquidityToken.balanceOf(_msgSender());

        uint256 lToBurn = (wantedGross * liquidityToken.totalSupply()) /
            totalReward;
        if (liquidityAmount < lToBurn) {
            lToBurn = liquidityAmount;
        }

        takeReward(wantedGross); // yearn => TPCore
        stakingcoin.safeTransfer(_msgSender(), amount); // TPCore => user
        liquidityToken.burn(_msgSender(), lToBurn);

        takeTPYReward(amount);

        emit Unstaked(_msgSender(), amount);
    }

    function emergencyUnstake() external {
        (uint104 gross, uint104 net, , ) = estimateRewardDetails(_msgSender());
        require(0 < net, "The amount must be greater than 0.");
        uint256 liquidityAmount = liquidityToken.balanceOf(_msgSender());
        takeReward(gross); // yearn => TPCore
        stakingcoin.safeTransfer(_msgSender(), net);
        liquidityToken.burn(_msgSender(), liquidityAmount);

        Staking storage staking = userStaking[_msgSender()];
        intervalUnstakes[nextInterval()] +=
            staking.amount +
            staking.pendingAmount;
        staking.amount = 0;
        staking.pendingAmount = 0;
        staking.calculatedTPYs = 0;

        emit Unstaked(_msgSender(), net);
    }

    function stakingAmount(address lpProvider) external view returns (uint104) {
        Staking storage staking = userStaking[lpProvider];
        return staking.amount + staking.pendingAmount;
    }

    function totalStakedForTPYInterval() external view returns (uint256) {
        return totalStakedUntilInterval(nextInterval());
    }

    function rewardForTPYInterval() external view returns (uint256) {
        return getTPYIntervalReward(nextInterval());
    }

    function estimateNetReward(address lpProvider)
        external
        view
        returns (uint104)
    {
        uint104 grossReward = estimateGrossReward(lpProvider);
        Staking storage staking = userStaking[lpProvider];
        uint104 stakingAmountPart = staking.amount + staking.pendingAmount;
        if(grossReward <= stakingAmountPart) {
            return grossReward;
        }
        else {
            uint104 profit = grossReward - stakingAmountPart;
            uint104 fee = ((10000 - ownerCurrentPercentage()) * profit) / 10000;
            uint104 netReward = grossReward - fee;
            return netReward;
        }
    }

    function estimateRewardDetails(address lpProvider)
        public
        view
        returns (
            uint104 gross,
            uint104 net,
            uint104 profit,
            uint104 fee
        )
    {
        gross = estimateGrossReward(lpProvider);
        Staking storage staking = userStaking[lpProvider];
        uint104 userStakingAmount = staking.amount + staking.pendingAmount;
        if(gross <= userStakingAmount) {
            profit = 0;
            fee = 0;
            net = gross;
        }
        else {
            profit = gross - userStakingAmount;
            fee = ((10000 - ownerCurrentPercentage()) * profit) / 10000;
            net = gross - fee;
        }
    }

    function ownerCurrentPercentage() public view returns (uint32) {
        if(uint32(block.timestamp) - ownerPercentageLastChangeTS < 7 days) {
            return ownerPercentage;
        }
        else {
            return ownerNewPercentage;
        }
    }

    function totalTPYEarned() public view returns (uint256) {
        uint256 lastInterval = currentInterval();
        uint256 totalTPYs = 0;
        for (uint256 i = 0; i <= lastInterval; i++) {
            totalTPYs += getTPYIntervalReward(i);
        }
        return totalTPYs;
    }

    function nextIntervalTPYs(address lpProvider)
        external
        view
        returns (uint256)
    {
        uint256 currentIntervalNumber = currentInterval();
        uint256 intervalTotalStakingAmount = totalStakedUntilInterval(
            currentIntervalNumber
        );

        if (intervalTotalStakingAmount > 0) {
            uint256 intervalTotalReward = getTPYIntervalReward(
                currentIntervalNumber
            );
            Staking memory staking = userStaking[lpProvider];
            if (
                staking.intervalNumber == currentIntervalNumber + 1 &&
                staking.pendingAmount == 0
            ) {
                if (staking.lastActionIsUnstake) {
                    return
                        (staking.amount * intervalTotalReward) /
                        intervalTotalStakingAmount;
                } else {
                    return 0;
                }
            } else if (staking.intervalNumber == currentIntervalNumber + 1) {
                return
                    (staking.amount * intervalTotalReward) /
                    intervalTotalStakingAmount;
            } else {
                return
                    ((staking.amount + staking.pendingAmount) *
                        intervalTotalReward) / intervalTotalStakingAmount;
            }
        } else {
            return 0;
        }
    }

    /// public functions
    function estimateGrossReward(address lpProvider)
        public
        view
        returns (uint104)
    {
        if (liquidityToken.totalSupply() == 0) {
            return 0;
        }
        uint256 totalReward = strategy.estimateReward(address(this));
        uint104 userReward = uint104(
            (totalReward * liquidityToken.balanceOf(lpProvider)) /
                liquidityToken.totalSupply()
        );
        return userReward;
    }

    function totalStakedUntilInterval(uint256 finalInterval)
        public
        view
        returns (uint256)
    {
        if (finalInterval == 0) {
            return 0;
        }
        uint256 totalPositive = 0;
        uint256 totalNegative = 0;
        for (uint256 i = 0; i <= finalInterval; i++) {
            totalPositive += intervalStakes[i];
            totalNegative += intervalUnstakes[i];
        }
        return totalPositive - totalNegative;
    }

    function estimateTPYReward(address addr) public view returns (uint136) {
        Staking memory staking = userStaking[addr];
        uint256 intervalNumber = staking.intervalNumber;

        if (staking.amount == 0) {
            return 0;
        }

        uint256 lastCompleteInterval;
        uint256 estimatedTPYs;

        if (currentInterval() == 0) {
            lastCompleteInterval = 0;
        } else {
            lastCompleteInterval = currentInterval() - 1;
        }

        estimatedTPYs += staking.calculatedTPYs;

        uint256 stakedUntilInterval;

        if (staking.pendingAmount == 0) {
            if (lastCompleteInterval >= intervalNumber) {
                stakedUntilInterval = totalStakedUntilInterval(intervalNumber);
                if (stakedUntilInterval > 0) {
                    estimatedTPYs +=
                        (staking.amount *
                            getTPYIntervalReward(intervalNumber)) /
                        stakedUntilInterval;
                }
                for (
                    uint256 i = intervalNumber + 1;
                    i <= lastCompleteInterval;
                    i++
                ) {
                    stakedUntilInterval += intervalStakes[i];
                    stakedUntilInterval -= intervalUnstakes[i];
                    if (stakedUntilInterval == 0) {
                        continue;
                    }
                    estimatedTPYs +=
                        (staking.amount * getTPYIntervalReward(i)) /
                        stakedUntilInterval;
                }
            }
        } else {
            stakedUntilInterval = totalStakedUntilInterval(intervalNumber - 1);
            if (
                intervalNumber - 1 <= lastCompleteInterval &&
                !staking.lastActionIsUnstake
            ) {
                estimatedTPYs +=
                    (staking.amount *
                        getTPYIntervalReward(intervalNumber - 1)) /
                    stakedUntilInterval;
            }
            for (uint256 i = intervalNumber; i <= lastCompleteInterval; i++) {
                stakedUntilInterval += intervalStakes[i];
                stakedUntilInterval -= intervalUnstakes[i];
                if (stakedUntilInterval == 0) {
                    continue;
                }
                estimatedTPYs +=
                    ((staking.amount + staking.pendingAmount) *
                        getTPYIntervalReward(i)) /
                    stakedUntilInterval;
            }
        }
        return uint136(estimatedTPYs);
    }

    function currentInterval() public view returns (uint16) {
        return uint16((block.timestamp - startingTS) / tpyInterval);
    }

    /// private functions
    function takeReward(uint256 amount) private {
        if (0 != amount) {
            (bool success, ) = address(strategy).delegatecall(
                abi.encodeWithSignature(
                    "takeReward(address,uint256)",
                    address(this),
                    amount
                )
            );
            require(success, "Failed to take the stakes from YEARN");
        }
    }

    function registerTPY(address staker, uint104 stakingCoinAmount) private {
        uint16 nextIntervalNumber = nextInterval();
        if (userStaking[staker].amount > 0) {
            Staking storage staking = userStaking[staker];
            if (staking.intervalNumber == nextIntervalNumber) {
                if (staking.pendingAmount == 0) {
                    staking.amount += stakingCoinAmount;
                } else {
                    staking.pendingAmount += stakingCoinAmount;
                }
            } else {
                uint136 currentReward = estimateTPYReward(staker);
                staking.calculatedTPYs = currentReward;
                staking.amount += staking.pendingAmount;
                staking.pendingAmount = stakingCoinAmount;
                staking.intervalNumber = nextIntervalNumber;
            }
        } else {
            // first time
            userStaking[staker] = Staking(
                nextIntervalNumber,
                stakingCoinAmount,
                0,
                0,
                false
            );
        }
        userStaking[staker].lastActionIsUnstake = false;
        intervalStakes[nextIntervalNumber] += stakingCoinAmount;
    }

    function takeTPYReward(uint104 unstakeCoinAmount) private {
        Staking storage staking = userStaking[_msgSender()];
        if (staking.amount == 0) {
            return;
        }

        if (unstakeCoinAmount > staking.amount + staking.pendingAmount) {
            unstakeCoinAmount = staking.amount + staking.pendingAmount;
        }

        uint104 pending = staking.pendingAmount;
        uint256 tpyRewards = estimateTPYReward(_msgSender());
        uint136 tpyToTransfer = uint136(
            (unstakeCoinAmount * tpyRewards) /
                (staking.amount + staking.pendingAmount)
        );
        staking.calculatedTPYs = uint136(tpyRewards);
        if (unstakeCoinAmount <= staking.pendingAmount) {
            staking.pendingAmount -= unstakeCoinAmount;
        } else {
            staking.amount -= (unstakeCoinAmount - staking.pendingAmount);
            staking.pendingAmount = 0;
        }

        uint16 currentIntervalNumber = currentInterval();

        if (staking.intervalNumber > currentIntervalNumber) {
            if (pending >= unstakeCoinAmount || pending == 0) {
                intervalUnstakes[
                    currentIntervalNumber + 1
                ] += unstakeCoinAmount;
            } else {
                intervalUnstakes[currentIntervalNumber + 1] += pending;
                intervalUnstakes[currentIntervalNumber] +=
                    unstakeCoinAmount -
                    pending;
            }
        } else {
            intervalUnstakes[currentIntervalNumber] += unstakeCoinAmount;
        }

        if (
            (staking.intervalNumber <= currentIntervalNumber) ||
            (pending > 0 && staking.pendingAmount == 0)
        ) {
            staking.intervalNumber = currentIntervalNumber;
        }

        if (staking.intervalNumber > currentIntervalNumber) {
            staking.lastActionIsUnstake = false;
        } else {
            staking.lastActionIsUnstake = true;
        }

        if (
            tpyToTransfer != 0 && tpy.balanceOf(address(this)) >= tpyToTransfer
        ) {
            // Not enough tpy balance for TPCore !!!
            console.log("TPY transfered", _msgSender(), tpyToTransfer);
            tpy.safeTransfer(_msgSender(), tpyToTransfer);
            staking.calculatedTPYs -= tpyToTransfer;
            takenTPY += tpyToTransfer;
        }

        emit TPYRewarded(_msgSender(), tpyToTransfer);
    }

    function getTPYIntervalReward(uint256 intervalNumber)
        private
        view
        returns (uint256)
    {
        if (intervalNumber == 0) {
            return 0;
        }
        while (tpyIntervalRewards[intervalNumber] == 0) {
            intervalNumber--;
        }
        return tpyIntervalRewards[intervalNumber];
    }

    function nextInterval() private view returns (uint16) {
        return currentInterval() + 1;
    }
}