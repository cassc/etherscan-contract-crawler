// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract Vesting is Ownable {
    /// @notice Vested token contract
    address public immutable vestedToken;

    /// @notice Payment token contract
    address public immutable paymentToken;

    /// @notice Vested token unit (10**decimals)
    uint256 public immutable vestedTokenUnit;

    /// @notice Timestamp of the overall vesting begin time
    uint256 public vestingBegin;

    /// @notice True if vesting begin time cannot be changed
    bool public vestingBeginIsLocked;

    struct VestingParams {
        uint256 vestAmount; // amount of "vestedToken" that is already on vesting
        uint256 allocation; // amount of "vestedToken" that can be bought for "price" and shifted to vesting
        uint256 price; // value of "paymentToken" amount asked per 1 "vestedToken" unit
        uint256 lockupPeriod; // period of time in seconds during which tokens cannot be claimed
        uint256 vestingPeriod; // time period of linear tokens unlock
        uint256 claimedAmount; // counter of already claimed vested tokens
    }

    /// @notice Mapping of IDs to vesting params
    mapping(uint256 => VestingParams) public vestings;

    /// @notice Mapping of addresses to lists of their vesting IDs
    mapping(address => uint256[]) public vestingIds;

    /// @notice Last vesting object ID (1-based)
    uint256 public lastVestingId;

    struct AllocParams {
        address investor;
        uint256 vestAmount;
        uint256 allocation;
        uint256 price;
        uint256 lockupPeriod;
        uint256 vestingPeriod;
    }

    event Claimed(address indexed account, uint256 indexed id, uint256 amount);
    event Bought(
        address indexed account,
        uint256 indexed id,
        uint256 amount,
        uint256 price
    );
    event VestingBeginSet(uint256 vestingBeginTime);
    event Allocated(address[] investors, uint256[] ids);
    event Revoked(uint256 indexed id);

    error IncorrectVestingBegin();
    error IncorrectVestingPeriod();
    error ZeroAmount();
    error ZeroPrice();
    error TimeChangeIsLocked();
    error VestingAlreadyStarted();
    error BeginIsNotSet();

    // CONSTRUCTOR

    /**
     * @notice Contract constructor
     * @param vestedToken_ Address of the vested token contract
     * @param paymentToken_ Address of the payment token contract
     */
    constructor(address vestedToken_, address paymentToken_, uint8 vestedTokenDecimals_) Ownable() {
        vestedToken = vestedToken_;
        paymentToken = paymentToken_;
        vestedTokenUnit = 10**vestedTokenDecimals_;
    }

    // USER FUNCTIONS

    /**
     * @notice Claim all available vested tokens for account
     * @param account Address to claim tokens for
     */
    function claim(address account) external {
        uint256 totalAmount;
        uint256[] storage ids = vestingIds[account];
        uint256 len = ids.length;
        uint256 id;
        uint256 amount;
        for (uint8 i = 0; i < len; i++) {
            id = ids[i];
            amount = getAvailableBalance(id);
            if (amount > 0) {
                totalAmount += amount;
                vestings[id].claimedAmount += amount;
                emit Claimed(account, id, amount);
            }
        }
        if (totalAmount == 0) revert ZeroAmount();
        TransferHelper.safeTransfer(vestedToken, account, totalAmount);
    }

    /**
     * @notice Buy all available allocations of msg.sender and shift them to vesting
     */
    function buy() external {
        uint256 totalCost;
        uint256[] storage ids = vestingIds[msg.sender];
        uint256 len = ids.length;
        uint256 alloc;
        uint256 id;
        uint256 price;
        VestingParams storage vesting;

        for (uint8 i = 0; i < len; i++) {
            id = ids[i];
            vesting = vestings[id];
            alloc = vesting.allocation;
            if (alloc > 0) {
                price = vesting.price;
                totalCost += alloc * price / vestedTokenUnit;
                vesting.allocation = 0;
                vesting.vestAmount += alloc;
                emit Bought(msg.sender, id, alloc, price);
            }
        }
        if (totalCost == 0) revert ZeroAmount();
        TransferHelper.safeTransferFrom(
            paymentToken,
            msg.sender,
            address(this),
            totalCost
        );
    }

    // RESTRICTED FUNCTIONS

    /**
     * @notice Lock changing of vesting begin time
     */
    function lockVestingBegin() external onlyOwner {
        if (vestingBegin == 0) revert BeginIsNotSet();
        vestingBeginIsLocked = true;
    }

    /**
     * @notice Change vesting begin time
     * @param vestingBegin_ Timestamp of new time
     */
    function setVestingBegin(uint256 vestingBegin_) external onlyOwner {
        if (vestingBeginIsLocked) revert TimeChangeIsLocked();
        _checkVestingBegin();
        if (vestingBegin_ <= block.timestamp) revert IncorrectVestingBegin();
        vestingBegin = vestingBegin_;
        emit VestingBeginSet(vestingBegin_);
    }

    /**
     * @notice Give vested token allocations to investors
     * @param allocParams Allocations parameters
     */
    function allocate(AllocParams[] calldata allocParams) external onlyOwner {
        _checkVestingBegin();
        uint256 totalAmount;
        uint256 lastId = lastVestingId;
        uint256 len = allocParams.length;
        AllocParams calldata params;
        VestingParams storage vesting;
        address[] memory investors = new address[](len);
        uint256[] memory ids = new uint256[](len);

        for (uint8 i = 0; i < len; i++) {
            params = allocParams[i];
            if (params.allocation == 0) {
                if (params.vestAmount == 0) revert ZeroAmount();
            } else {
                if (params.price == 0) revert ZeroPrice();
            }
            if (params.vestingPeriod == 0) revert IncorrectVestingPeriod();

            totalAmount += params.allocation + params.vestAmount;
            vesting = vestings[++lastId];
            vesting.vestAmount = params.vestAmount;
            vesting.allocation = params.allocation;
            vesting.price = params.price;
            vesting.lockupPeriod = params.lockupPeriod;
            vesting.vestingPeriod = params.vestingPeriod;

            vestingIds[params.investor].push(lastId);
            investors[i] = params.investor;
            ids[i] = lastId;
        }
        lastVestingId = lastId;
        emit Allocated(investors, ids);
        TransferHelper.safeTransferFrom(
            vestedToken,
            msg.sender,
            address(this),
            totalAmount
        );
    }

    /**
     * @notice Revoke and withdraw unsold vested token allocations of given vesting IDs
     * @param vestingIds_ Vesting IDs array
     */
    function revokeUnsoldAllocation(uint256[] calldata vestingIds_)
        external
        onlyOwner
    {
        uint256 len = vestingIds_.length;
        uint256 alloc;
        uint256 totalAlloc;
        uint256 id;
        VestingParams storage vesting;

        for (uint8 i = 0; i < len; i++) {
            id = vestingIds_[i];
            vesting = vestings[id];
            alloc = vesting.allocation;
            if (alloc > 0) {
                totalAlloc += alloc;
                vesting.allocation = 0;
                emit Revoked(id);
            }
        }
        if (totalAlloc == 0) revert ZeroAmount();
        TransferHelper.safeTransfer(vestedToken, msg.sender, totalAlloc);
    }

    /**
     * @notice Withdraw "paymentToken" balance of the contract to given address
     * @param to Destination address
     */
    function withdraw(address to) external onlyOwner {
        uint256 amount = IERC20(paymentToken).balanceOf(address(this));
        if (amount == 0) revert ZeroAmount();
        TransferHelper.safeTransfer(paymentToken, to, amount);
    }

    // VIEW

    /**
     * @notice Get total amount of available for claim tokens for account
     * @param account Account to calculate amount for
     * @return amount Total amount of available tokens
     */
    function getAvailableBalanceOf(address account)
        external
        view
        returns (uint256 amount)
    {
        uint256[] memory ids = vestingIds[account];
        for (uint8 i = 0; i < ids.length; i++) {
            amount += getAvailableBalance(ids[i]);
        }
    }

    /**
     * @notice Get amount of vesting objects for account
     * @param account Address of account
     * @return Amount of vesting objects
     */
    function vestingCountOf(address account) external view returns (uint256) {
        return vestingIds[account].length;
    }

    /**
     * @notice Get array of vesting objects IDs for account
     * @param account Address of account
     * @return Array of vesting objects IDs
     */
    function vestingIdsOf(address account) external view returns (uint256[] memory) {
        return vestingIds[account];
    }

    /**
     * @notice Get voting power for compound delegated votes with vesting allocation
     * @param account Address of account
     * @return Amount of votes
     */
    function getVotesWithVested(address account)
        external
        view
        returns (uint256)
    {
        return
            ERC20Votes(vestedToken).getVotes(account) + getBalanceOf(account);
    }

    /**
     * @notice Get total amount tokens for claim in future
     * @param account Account to calculate amount for
     * @return amount Total amount of tokens
     */
    function getBalanceOf(address account)
        public
        view
        returns (uint256 amount)
    {
        uint256[] memory ids = vestingIds[account];
        for (uint8 i = 0; i < ids.length; i++) {
            VestingParams storage vestParams = vestings[ids[i]];
            amount += vestParams.vestAmount - vestParams.claimedAmount;
        }
    }

    /**
     * @notice Get amount of available for claim tokens in exact vesting object
     * @param vestingId ID of the vesting object
     * @return Amount of available tokens
     */
    function getAvailableBalance(uint256 vestingId)
        public
        view
        returns (uint256)
    {
        VestingParams storage vestParams = vestings[vestingId];
        uint256 userVestingBegin_ = vestingBegin + vestParams.lockupPeriod;
        uint256 userVestingEnd_ = userVestingBegin_ + vestParams.vestingPeriod;

        if (block.timestamp < userVestingBegin_ || vestingBegin == 0) {
            return 0;
        }

        uint256 amount;
        if (block.timestamp >= userVestingEnd_) {
            amount = vestParams.vestAmount - vestParams.claimedAmount;
        } else {
            amount =
                (vestParams.vestAmount *
                    (block.timestamp - userVestingBegin_)) /
                (userVestingEnd_ - userVestingBegin_) -
                vestParams.claimedAmount;
        }
        return amount;
    }

    function _checkVestingBegin() internal view {
        if (vestingBegin > 0 && vestingBegin <= block.timestamp)
            revert VestingAlreadyStarted();
    }
}