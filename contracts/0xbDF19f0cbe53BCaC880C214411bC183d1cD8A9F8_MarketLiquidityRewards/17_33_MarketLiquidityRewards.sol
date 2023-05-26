// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IMarketLiquidityRewards.sol";

import "./interfaces/IMarketRegistry.sol";
import "./interfaces/ICollateralManager.sol";
import "./interfaces/ITellerV2.sol";

import { BidState } from "./TellerV2Storage.sol";

// Libraries
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/*
- Allocate and claim rewards for loans based on bidId  

- Anyone can allocate rewards and an allocation has specific parameters that can be set to incentivise certain types of loans
 
*/

contract MarketLiquidityRewards is IMarketLiquidityRewards, Initializable {
    address immutable tellerV2;
    address immutable marketRegistry;
    address immutable collateralManager;

    uint256 allocationCount;

    //allocationId => rewardAllocation
    mapping(uint256 => RewardAllocation) public allocatedRewards;

    //bidId => allocationId => rewardWasClaimed
    mapping(uint256 => mapping(uint256 => bool)) public rewardClaimedForBid;

    modifier onlyMarketOwner(uint256 _marketId) {
        require(
            msg.sender ==
                IMarketRegistry(marketRegistry).getMarketOwner(_marketId),
            "Only market owner can call this function."
        );
        _;
    }

    event CreatedAllocation(
        uint256 allocationId,
        address allocator,
        uint256 marketId
    );

    event UpdatedAllocation(uint256 allocationId);

    event IncreasedAllocation(uint256 allocationId, uint256 amount);

    event DecreasedAllocation(uint256 allocationId, uint256 amount);

    event DeletedAllocation(uint256 allocationId);

    event ClaimedRewards(
        uint256 allocationId,
        uint256 bidId,
        address recipient,
        uint256 amount
    );

    constructor(
        address _tellerV2,
        address _marketRegistry,
        address _collateralManager
    ) {
        tellerV2 = _tellerV2;
        marketRegistry = _marketRegistry;
        collateralManager = _collateralManager;
    }

    function initialize() external initializer {}

    /**
     * @notice Creates a new token allocation and transfers the token amount into escrow in this contract
     * @param _allocation - The RewardAllocation struct data to create
     * @return allocationId_
     */
    function allocateRewards(RewardAllocation calldata _allocation)
        public
        virtual
        returns (uint256 allocationId_)
    {
        allocationId_ = allocationCount++;

        require(
            _allocation.allocator == msg.sender,
            "Invalid allocator address"
        );

        require(
            _allocation.requiredPrincipalTokenAddress != address(0),
            "Invalid required principal token address"
        );

        IERC20Upgradeable(_allocation.rewardTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _allocation.rewardTokenAmount
        );

        allocatedRewards[allocationId_] = _allocation;

        emit CreatedAllocation(
            allocationId_,
            _allocation.allocator,
            _allocation.marketId
        );
    }

    /**
     * @notice Allows the allocator to update properties of an allocation
     * @param _allocationId - The id for the allocation
     * @param _minimumCollateralPerPrincipalAmount - The required collateralization ratio
     * @param _rewardPerLoanPrincipalAmount - The reward to give per principal amount
     * @param _bidStartTimeMin - The block timestamp that loans must have been accepted after to claim rewards
     * @param _bidStartTimeMax - The block timestamp that loans must have been accepted before to claim rewards
     */
    function updateAllocation(
        uint256 _allocationId,
        uint256 _minimumCollateralPerPrincipalAmount,
        uint256 _rewardPerLoanPrincipalAmount,
        uint32 _bidStartTimeMin,
        uint32 _bidStartTimeMax
    ) public virtual {
        RewardAllocation storage allocation = allocatedRewards[_allocationId];

        require(
            msg.sender == allocation.allocator,
            "Only the allocator can update allocation rewards."
        );

        allocation
            .minimumCollateralPerPrincipalAmount = _minimumCollateralPerPrincipalAmount;
        allocation.rewardPerLoanPrincipalAmount = _rewardPerLoanPrincipalAmount;
        allocation.bidStartTimeMin = _bidStartTimeMin;
        allocation.bidStartTimeMax = _bidStartTimeMax;

        emit UpdatedAllocation(_allocationId);
    }

    /**
     * @notice Allows anyone to add tokens to an allocation
     * @param _allocationId - The id for the allocation
     * @param _tokenAmount - The amount of tokens to add
     */
    function increaseAllocationAmount(
        uint256 _allocationId,
        uint256 _tokenAmount
    ) public virtual {
        IERC20Upgradeable(allocatedRewards[_allocationId].rewardTokenAddress)
            .transferFrom(msg.sender, address(this), _tokenAmount);
        allocatedRewards[_allocationId].rewardTokenAmount += _tokenAmount;

        emit IncreasedAllocation(_allocationId, _tokenAmount);
    }

    /**
     * @notice Allows the allocator to withdraw some or all of the funds within an allocation
     * @param _allocationId - The id for the allocation
     * @param _tokenAmount - The amount of tokens to withdraw
     */
    function deallocateRewards(uint256 _allocationId, uint256 _tokenAmount)
        public
        virtual
    {
        require(
            msg.sender == allocatedRewards[_allocationId].allocator,
            "Only the allocator can deallocate rewards."
        );

        //enforce that the token amount withdraw must be LEQ to the reward amount for this allocation
        if (_tokenAmount > allocatedRewards[_allocationId].rewardTokenAmount) {
            _tokenAmount = allocatedRewards[_allocationId].rewardTokenAmount;
        }

        //subtract amount reward before transfer
        _decrementAllocatedAmount(_allocationId, _tokenAmount);

        IERC20Upgradeable(allocatedRewards[_allocationId].rewardTokenAddress)
            .transfer(msg.sender, _tokenAmount);

        //if the allocated rewards are drained completely, delete the storage slot for it
        if (allocatedRewards[_allocationId].rewardTokenAmount == 0) {
            delete allocatedRewards[_allocationId];

            emit DeletedAllocation(_allocationId);
        } else {
            emit DecreasedAllocation(_allocationId, _tokenAmount);
        }
    }

    struct LoanSummary {
        address borrower;
        address lender;
        uint256 marketId;
        address principalTokenAddress;
        uint256 principalAmount;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        BidState bidState;
    }

    function _getLoanSummary(uint256 _bidId)
        internal
        returns (LoanSummary memory _summary)
    {
        (
            _summary.borrower,
            _summary.lender,
            _summary.marketId,
            _summary.principalTokenAddress,
            _summary.principalAmount,
            _summary.acceptedTimestamp,
            _summary.lastRepaidTimestamp,
            _summary.bidState
        ) = ITellerV2(tellerV2).getLoanSummary(_bidId);
    }

    /**
     * @notice Allows a borrower or lender to withdraw the allocated ERC20 reward for their loan
     * @param _allocationId - The id for the reward allocation
     * @param _bidId - The id for the loan. Each loan only grants one reward per allocation.
     */
    function claimRewards(uint256 _allocationId, uint256 _bidId)
        external
        virtual
    {
        RewardAllocation storage allocatedReward = allocatedRewards[
            _allocationId
        ];

        //set a flag that this reward was claimed for this bid to defend against re-entrancy
        require(
            !rewardClaimedForBid[_bidId][_allocationId],
            "reward already claimed"
        );
        rewardClaimedForBid[_bidId][_allocationId] = true;

        //make this a struct ?
        LoanSummary memory loanSummary = _getLoanSummary(_bidId); //ITellerV2(tellerV2).getLoanSummary(_bidId);

        address collateralTokenAddress = allocatedReward
            .requiredCollateralTokenAddress;

        //require that the loan was started in the correct timeframe
        _verifyLoanStartTime(
            loanSummary.acceptedTimestamp,
            allocatedReward.bidStartTimeMin,
            allocatedReward.bidStartTimeMax
        );

        //if a collateral token address is set on the allocation, verify that the bid has enough collateral ratio
        if (collateralTokenAddress != address(0)) {
            uint256 collateralAmount = ICollateralManager(collateralManager)
                .getCollateralAmount(_bidId, collateralTokenAddress);

            //require collateral amount
            _verifyCollateralAmount(
                collateralTokenAddress,
                collateralAmount,
                loanSummary.principalTokenAddress,
                loanSummary.principalAmount,
                allocatedReward.minimumCollateralPerPrincipalAmount
            );
        }

        require(
            loanSummary.principalTokenAddress ==
                allocatedReward.requiredPrincipalTokenAddress,
            "Principal token address mismatch for allocation"
        );

        require(
            loanSummary.marketId == allocatedRewards[_allocationId].marketId,
            "MarketId mismatch for allocation"
        );

        uint256 principalTokenDecimals = IERC20MetadataUpgradeable(
            loanSummary.principalTokenAddress
        ).decimals();

        address rewardRecipient = _verifyAndReturnRewardRecipient(
            allocatedReward.allocationStrategy,
            loanSummary.bidState,
            loanSummary.borrower,
            loanSummary.lender
        );

        uint32 loanDuration = loanSummary.lastRepaidTimestamp -
            loanSummary.acceptedTimestamp;

        uint256 amountToReward = _calculateRewardAmount(
            loanSummary.principalAmount,
            loanDuration,
            principalTokenDecimals,
            allocatedReward.rewardPerLoanPrincipalAmount
        );

        if (amountToReward > allocatedReward.rewardTokenAmount) {
            amountToReward = allocatedReward.rewardTokenAmount;
        }

        require(amountToReward > 0, "Nothing to claim.");

        _decrementAllocatedAmount(_allocationId, amountToReward);

        //transfer tokens reward to the msgsender
        IERC20Upgradeable(allocatedRewards[_allocationId].rewardTokenAddress)
            .transfer(rewardRecipient, amountToReward);

        emit ClaimedRewards(
            _allocationId,
            _bidId,
            rewardRecipient,
            amountToReward
        );
    }

    /**
     * @notice Verifies that the bid state is appropriate for claiming rewards based on the allocation strategy and then returns the address of the reward recipient(borrower or lender)
     * @param _strategy - The strategy for the reward allocation.
     * @param _bidState - The bid state of the loan.
     * @param _borrower - The borrower of the loan.
     * @param _lender - The lender of the loan.
     * @return rewardRecipient_ The address that will receive the rewards. Either the borrower or lender.
     */
    function _verifyAndReturnRewardRecipient(
        AllocationStrategy _strategy,
        BidState _bidState,
        address _borrower,
        address _lender
    ) internal virtual returns (address rewardRecipient_) {
        if (_strategy == AllocationStrategy.BORROWER) {
            require(_bidState == BidState.PAID, "Invalid bid state for loan.");

            rewardRecipient_ = _borrower;
        } else if (_strategy == AllocationStrategy.LENDER) {
            //Loan must have been accepted in the past
            require(
                _bidState >= BidState.ACCEPTED,
                "Invalid bid state for loan."
            );

            rewardRecipient_ = _lender;
        } else {
            revert("Unknown allocation strategy");
        }
    }

    /**
     * @notice Decrements the amount allocated to keep track of tokens in escrow
     * @param _allocationId - The id for the allocation to decrement
     * @param _amount - The amount of ERC20 to decrement
     */
    function _decrementAllocatedAmount(uint256 _allocationId, uint256 _amount)
        internal
    {
        allocatedRewards[_allocationId].rewardTokenAmount -= _amount;
    }

    /**
     * @notice Calculates the reward to claim for the allocation
     * @param _loanPrincipal - The amount of principal for the loan for which to reward
     * @param _loanDuration - The duration of the loan in seconds
     * @param _principalTokenDecimals - The number of decimals of the principal token
     * @param _rewardPerLoanPrincipalAmount - The amount of reward per loan principal amount, expanded by the principal token decimals
     * @return The amount of ERC20 to reward
     */
    function _calculateRewardAmount(
        uint256 _loanPrincipal,
        uint256 _loanDuration,
        uint256 _principalTokenDecimals,
        uint256 _rewardPerLoanPrincipalAmount
    ) internal view returns (uint256) {
        uint256 rewardPerYear = MathUpgradeable.mulDiv(
            _loanPrincipal,
            _rewardPerLoanPrincipalAmount, //expanded by principal token decimals
            10**_principalTokenDecimals
        );

        return MathUpgradeable.mulDiv(rewardPerYear, _loanDuration, 365 days);
    }

    /**
     * @notice Verifies that the collateral ratio for the loan was sufficient based on _minimumCollateralPerPrincipalAmount of the allocation
     * @param _collateralTokenAddress - The contract address for the collateral token
     * @param _collateralAmount - The number of decimals of the collateral token
     * @param _principalTokenAddress - The contract address for the principal token
     * @param _principalAmount - The number of decimals of the principal token
     * @param _minimumCollateralPerPrincipalAmount - The amount of collateral required per principal amount. Expanded by the principal token decimals and collateral token decimals.
     */
    function _verifyCollateralAmount(
        address _collateralTokenAddress,
        uint256 _collateralAmount,
        address _principalTokenAddress,
        uint256 _principalAmount,
        uint256 _minimumCollateralPerPrincipalAmount
    ) internal virtual {
        uint256 principalTokenDecimals = IERC20MetadataUpgradeable(
            _principalTokenAddress
        ).decimals();

        uint256 collateralTokenDecimals = IERC20MetadataUpgradeable(
            _collateralTokenAddress
        ).decimals();

        uint256 minCollateral = _requiredCollateralAmount(
            _principalAmount,
            principalTokenDecimals,
            collateralTokenDecimals,
            _minimumCollateralPerPrincipalAmount
        );

        require(
            _collateralAmount >= minCollateral,
            "Loan does not meet minimum collateralization ratio."
        );
    }

    /**
     * @notice Calculates the minimum amount of collateral the loan requires based on principal amount
     * @param _principalAmount - The number of decimals of the principal token
     * @param _principalTokenDecimals - The number of decimals of the principal token
     * @param _collateralTokenDecimals - The number of decimals of the collateral token
     * @param _minimumCollateralPerPrincipalAmount - The amount of collateral required per principal amount. Expanded by the principal token decimals and collateral token decimals.
     */
    function _requiredCollateralAmount(
        uint256 _principalAmount,
        uint256 _principalTokenDecimals,
        uint256 _collateralTokenDecimals,
        uint256 _minimumCollateralPerPrincipalAmount
    ) internal view virtual returns (uint256) {
        return
            MathUpgradeable.mulDiv(
                _principalAmount,
                _minimumCollateralPerPrincipalAmount, //expanded by principal token decimals and collateral token decimals
                10**(_principalTokenDecimals + _collateralTokenDecimals)
            );
    }

    /**
     * @notice Verifies that the loan start time is within the bounds set by the allocation requirements
     * @param _loanStartTime - The timestamp when the loan was accepted
     * @param _minStartTime - The minimum time required, after which the loan must have been accepted
     * @param _maxStartTime - The maximum time required, before which the loan must have been accepted
     */
    function _verifyLoanStartTime(
        uint32 _loanStartTime,
        uint32 _minStartTime,
        uint32 _maxStartTime
    ) internal virtual {
        require(
            _minStartTime == 0 || _loanStartTime > _minStartTime,
            "Loan was accepted before the min start time."
        );
        require(
            _maxStartTime == 0 || _loanStartTime < _maxStartTime,
            "Loan was accepted after the max start time."
        );
    }

    /**
     * @notice Returns the amount of reward tokens remaining in the allocation
     * @param _allocationId - The id for the allocation
     */
    function getRewardTokenAmount(uint256 _allocationId)
        public
        view
        override
        returns (uint256)
    {
        return allocatedRewards[_allocationId].rewardTokenAmount;
    }
}