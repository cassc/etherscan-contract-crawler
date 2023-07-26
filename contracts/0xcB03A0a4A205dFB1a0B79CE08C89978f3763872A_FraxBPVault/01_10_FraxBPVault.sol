// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20Upgradeable as IERC20, SafeERC20Upgradeable as SafeERC20} from "@openzeppelin-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IConvexBooster, IConvexFeeRegistry, IConvexVault} from "@interfaces/IConvexFraxVaults.sol";
import "@interfaces/IFraxFarmERC20.sol";
import "@interfaces/IRewardsDistributor.sol";
import "@interfaces/IFeeManager.sol";
import "@interfaces/IERC1155Receipt.sol";

/**
*   @title Asset Strategy Vault - Convex & Frax staked Curve LP
*   @notice This is the implementation logic for staking Curve LP assets through Convex to a FraxFarm.
*   @author Hourglass Finance
*/

contract FraxBPVault {
    using SafeERC20 for IERC20;

    /// @notice The address of the convex booster to clone vaults from
    address internal constant CONVEX_BOOSTER = address(0x569f5B842B5006eC17Be02B8b94510BA8e79FbCa);
    /// @notice The address of the convex fee registry
    address internal constant CONVEX_FEE_REGISTRY = address(0xC9aCB83ADa68413a6Aa57007BC720EE2E2b3C46D);
    /// @notice The convex pool id for this asset/strategy
    uint256 internal constant CONVEX_PID = 9;
    /// @notice Address of FXS token
    address internal constant FXS = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    /// @notice Fee denominator for fee calculations
    uint256 internal constant FEE_DENOMINATOR = 10000;

    /// @notice The address of the fee manager contract
    address internal feeManager;
    /// @notice The asset id of this strategy
    uint256 internal assetId;
    /// @notice Address of the token that is deposited into the convex vault
    address internal depositToken;
    /// @notice Address of the 1155 receipt users receive for depositing into this vault
    address internal receiptToken;
    /// @notice The timestamp at which this vault can be withdrawn from, also, the 1155 token id
    uint256 internal maturityTimestamp;

    /// @notice Address of the cloned convex vault this contract owns
    address internal depositVault;
    /// @notice The kek id for the locked stake - as array in case this needs to be managed by a generalized contract
    bytes32[] internal depositId;

    /// @notice The address of the owner (custodian)
    address internal owner;
    /// @notice Whether this contract has been initialized yet.
    bool internal isInitialized;


    ////////// Getters for the internal vars //////////
    /// @notice Get the address of the fee manager
    function getFeeManager() external view returns (address) {
        return feeManager;
    }
    /// @notice Get the the address of the vault this owns
    function getDepositVault() external view returns (address) {
        return depositVault;
    }
    /// @notice Get the address of the token that is deposited into the convex vault
    function getDepositToken() external view returns (address) {
        return depositToken;
    }
    /// @notice Get the maturity timestamp for this vault
    function getMaturityTimestamp() external view returns (uint256) {
        return maturityTimestamp;
    }
    /// @notice returns the value of the deposit id
    function getDepositId() external view returns (bytes32) {
        return depositId[0];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    /// @notice Initialization is called when the implementation is cloned for new maturities
    function initialize(
        address _feeManager,
        address _depositToken, // curve LP token
        uint256 initAmount,
        uint256 _maturityTimestamp,
        uint256 _assetId,
        address _receipt, 
        bytes calldata,
        bytes calldata
    ) public {
        require(!isInitialized, "!init");
        owner = msg.sender;
        isInitialized = true;

        depositVault = IConvexBooster(CONVEX_BOOSTER).createVault(CONVEX_PID);

        // just a check to make sure the assets are correct!
        require(_depositToken == IConvexVault(depositVault).curveLpToken(), "!depositToken");
        feeManager = _feeManager;
        depositToken = _depositToken;
        maturityTimestamp = _maturityTimestamp; 
        receiptToken = _receipt;
        assetId = _assetId;

        /// Set approvals - convex vault OK to pull from here & if needed reward collector to pull from here
        IERC20(_depositToken).approve(depositVault, type(uint256).max);

        /// seed stake 
        bytes32 kekId = IConvexVault(depositVault).stakeLockedCurveLp(initAmount, (_maturityTimestamp - block.timestamp));
        depositId.push(kekId);
    }
    
    /// @notice Triggers the deposit of the assets into the strategy
    /// @param _amount The amount of the deposit token to deposit
    /// @dev This contract must receive the deposit token first, and `_amount` must be <= the balance of this contract
    function deposit(uint256 _amount, bytes calldata) external onlyOwner {
        // The deposit token is sent into this vault before this function is called
        require(_amount <= IERC20(depositToken).balanceOf(address(this)), "!balance");

        // call convex vault lockAdditional
        IConvexVault(depositVault).lockAdditionalCurveLp(depositId[0], _amount);
    }

    /// @notice Withdraws unlocked assets once maturity is reached, claiming rewards
    /// @param destination The address to send the matured assets to
    /// @param toUser Whether or not this is a user triggered withdrawal
    /// @param user The user address to send the user portion to (if applicable)
    /// @param userAmount The amount of the matured assets to send to the user (if applicable)
    /// @dev sending to user prevents them from having to again withdraw from the mature vault
    function withdrawMatured(
        address destination, 
        bool toUser, 
        address user, 
        uint256 userAmount
    ) external onlyOwner returns (uint256 totalWithdrawn) {
        // claim rewards first so it sends to reward distributor
        claimRewards();

        // withdraw from convex vault to this address
        IConvexVault(depositVault).withdrawLockedAndUnwrap(depositId[0]);

        // get the balance of the deposit token now held here
        totalWithdrawn = IERC20(depositToken).balanceOf(address(this));
        require(totalWithdrawn >= userAmount, "!userAmount");
        
        // if user triggered this withdrawal, send their portion to them & the rest to the mature vault
        if (toUser) {
            // send to user
            IERC20(depositToken).safeTransfer(user, userAmount);
            // send to destination mature holding vault
            IERC20(depositToken).safeTransfer(destination, totalWithdrawn - userAmount);
        } else {
            // send to destination mature holding vault
            IERC20(depositToken).safeTransfer(destination, totalWithdrawn);
        }
    }

    /// @notice this returns the amounts accrued by the vault BEFORE Convex or our fees are deducted
    /// @return rewardTokens The reward tokens earned
    /// @return amountEarned The amount of each reward token earned
    /// @dev This does not return reliable values if the frax farm reward period has entered a new round && the farm has not claimed it's new rewards yet (checkpointed)
    function earned() public view returns (address[] memory rewardTokens, uint256[] memory amountEarned) {
        // this function will only work if the farm has been sync'd during the current reward period
        require(
            IFraxFarmERC20(IConvexVault(depositVault).stakingAddress()).periodFinish() 
            >= block.timestamp, 
            "!periodFinish"
        );

        // call vault's `earned` to obtain token addresses & amounts earned
        (rewardTokens, amountEarned) = IConvexVault(depositVault).earned();

        // loop through the tokens and apply our fee (& convex fee if it is FXS)
        uint256 numTokens = rewardTokens.length;
        for (uint256 i; i < numTokens; i++) {
            // if FXS, deduct the Convex fee
            if (rewardTokens[i] == FXS) {
                uint256 convexFee = IConvexFeeRegistry(CONVEX_FEE_REGISTRY).totalFees();
                require(convexFee <= FEE_DENOMINATOR, "!convexFee");
                amountEarned[i] -= (amountEarned[i] * convexFee / FEE_DENOMINATOR);
            }

            // calculate our fee
            uint256 fee = (amountEarned[i] * IFeeManager(feeManager).rewardsFee() / FEE_DENOMINATOR);

            // if there's a fee, deduct it before returning earned amonuts
            if (fee > 0) {
                amountEarned[i] -= fee;
            }
        }
    }

    /// @notice Allows anyone to claim this vault's rewards, regardless of whether the epoch has finished
    /// @return rewardTokens The reward tokens earned
    /// @return amountEarned The amount of each reward token earned
    /// @dev sends reward tokens to the reward distributor checkpointer for later posting/distribution
    function claimRewards() public returns (address[] memory rewardTokens, uint256[] memory amountEarned) {
        // call vault's `earned` to obtain token addresses & amounts earned
        (rewardTokens, amountEarned) = IConvexVault(depositVault).earned();

        // claim rewards from convex vault
        IConvexVault(depositVault).getReward();

        address feeAddress = IFeeManager(feeManager).feeAddress();
        // update with any other rewards in here
        uint256 numTokens = rewardTokens.length;
        for (uint256 i; i < numTokens; i++) {
            // convex doesn't return the correct amounts earned due to their fee, so build those values here
            amountEarned[i] = IERC20(rewardTokens[i]).balanceOf(address(this));

            // calculate if there's a fee
            /// @dev Note that rewardsFee MUST be less than FEE_DENOMINATOR, which is checked on setting the fee @ FeeManager
            uint256 fee = (amountEarned[i] * IFeeManager(feeManager).rewardsFee() / FEE_DENOMINATOR);
            
            // if there's a fee, send it to the fee address
            if (fee > 0) {
                amountEarned[i] -= fee;
                IERC20(rewardTokens[i]).transfer(feeAddress, fee);
                emit FeeSent(rewardTokens[i], fee);
            }

            // send the reward token with updated balances to the reward destination
            IERC20(rewardTokens[i]).transfer(IFeeManager(feeManager).rewardsAddress(), amountEarned[i]);
        }

        emit RewardsClaimed(rewardTokens, amountEarned, numTokens);

        return (rewardTokens, amountEarned);
    }

    /// @notice Allows the owner (custodian) to rescue any ERC20 tokens sent to this contract
    function rescue(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner, _amount);
        emit TokenRescued(owner, _token, _amount);
    }

    /// @notice Allows the owner (custodian) to set vault variables
    function setVars(bytes calldata _data) external onlyOwner {
        /// Do nothing
    }

    /// @notice Allows custodian to transfer ownership of this vault to a new address
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "!addr(0)");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    /////////// Events ///////////

    /// @dev note that most events are emitted in other contracts
    event FeeSent(address _token, uint256 _amount);
    /// @notice Emitted when rewards are claimed & allows for easy off-chain tracking of rewards
    event RewardsClaimed(address[] _rewardTokens, uint256[] _amounts, uint256 indexed _numberOfRewardTkns);
    event TokenRescued(address indexed _receiver, address indexed _token, uint256 indexed _amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}