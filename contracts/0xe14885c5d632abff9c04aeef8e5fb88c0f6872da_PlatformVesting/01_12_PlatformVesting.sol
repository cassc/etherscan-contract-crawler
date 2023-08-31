// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../access_controller/PlatformAccessController.sol";
import "../token/IplatformToken/IPlatformToken.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IPlatformVesting/IPlatformVesting.sol";

/**
 * @notice Separate vesting pool, each with separate liquidity, whitelists and parameters
 */
contract PlatformVesting is PlatformAccessController, ReentrancyGuard, IPlatformVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    event InsertVestingList(address indexed admin, uint256 vestingCount);

    /**
     * @notice Emit during vesting vesting liquidity increasing
     * Liquidity of the vesting decreases
     * @param admin Platform admin which do this action
     * @param vestingId The vesting id
     * @param amount The PROPC token amount which add to vesting free amount
     */
    event IncreaseLiquidity(
        address indexed admin,
        uint256 indexed vestingId,
        uint256 amount
    );

    /**
     * @notice Emit during vesting vesting liquidity decreasing process
     * Liquidity of the vesting increases
     * @param admin Platform admin which do this action
     * @param amount The PROPC token amount which rem from vesting free amount
     */
    event DecreaseLiquidity(
        address indexed admin,
        uint256 amount
    );

    event InsertWalletListToVesting(
        address indexed admin,
        uint256 indexed vestingId,
        address[] walletList
    );

    event RemoveWalletListFromVesting(
        address indexed admin,
        uint256 indexed vestingId,
        address[] walletList
    );

    event TGESet(
        uint256 tgeDate,
        uint256 timestamp
    );

    event UpdateTokenAddress(
        address _address,
        uint256 timestamp
    );

    event VestingRemoved(
        uint256 id,
        uint256 timestamp
    );

    event VestingAdded(
        uint256 amountForUser,
        uint256 tgeAmountForUser,
        uint256 startTime,
        uint256 tickCount,
        uint256 tickDuration,
        uint256 timestamp
    );

    /**
     * @notice Emit when user claim his PROPC from vesting
     * @param vestingId The vesting id
     * @param wallet The user wallet
     * @param amount The PROPC token amount which user save
     */
    event Claim(
        uint256 indexed vestingId,
        address indexed wallet,
        uint256 amount
    );

    struct VestingProperties {
        uint256 amountForUser;
        uint256 tgeAmountForUser;
        uint256 startTime;
        uint256 tickCount;
        uint256 tickDuration;
        uint256 unallocatedAmount;
        bool active;
    }

    struct UserProperties {
        bool isActive;
        uint256 spentAmount;
        uint256 vestingId;
        bool tgeClaimed;
    }

    error InsufficientBalance();
    error InvalidTimestamp();
    error ZeroAddress();
    error ZeroAmount();
    error OutOfBounds();
    error EmptyArray();
    error ArraySizeDoesNotMatch();
    error VestingDoesNotExist();
    error UserAlreadyActive();
    error UserNotActive();
    error NoClaimAvailable();
    error VestingAlreadyActive();
    error StartBeforeNow();
    error StartBeforeTGE();
    error TicksMissing();
    error FatalError(string message);

    struct VestingLink {
        address user;
        bool active;
    }

    uint256 private constant TOTAL_SHARE = 100_000;

    uint256 public tgeStartDate;
    address private _token;

    uint256 public _vestingCount;
    uint256 public totalRemainingAllocatedAmount;

    mapping(uint256 => VestingProperties) private _vestingMap;
    mapping(uint256 => VestingLink) private _vestingToUser;
    mapping(address => UserProperties) private _userMapping;

    modifier existingVesting(uint256 vestingId) {
        require(vestingId <= _vestingCount, "vesting does not exist");
        _;
    }

    constructor(address adminPanel) {
        if(adminPanel == address(0))
            revert ZeroAddress();
        _initiatePlatformAccessController(adminPanel);
    }

    function setTgeDate(uint256 timestamp) external onlyPlatformAdmin {
        if(timestamp < block.timestamp)
            revert InvalidTimestamp();
        tgeStartDate = timestamp;

        emit TGESet(timestamp, block.timestamp);
    }

    function updateTokenAddress(address token) external onlyPlatformAdmin {
        if(token == address(0))
            revert ZeroAddress();
        _token = token;

        emit UpdateTokenAddress(token, block.timestamp);
    }

    /**
     * @notice Get vesting pool properties list
     * vesting.amountForUser   Total PROPC amount which user can claim
     * vesting.tgeAmountForUser   PROPC amount which user can claim immediately after the `tgeStartDate`
     * vesting.startTime   The moment after that users can start claiming tick by tick
     * vesting.tickCount   The number of ticks that must pass to fully unlock funds
     * Each tick unlocks a proportional amount
     * vesting.tickDuration   Tick duration on seconds
     * vesting.unallocatedAmount PROPC that has not yet been assigned to any users
     * Grows when users are deleted and liquidity is increased by the admin
     * Falls when users are deleted and the liquidity is reduced by the admin
     */
    function vestingPropertiesList()
    external
    view
    returns (VestingProperties[] memory vestingList)
    {
        uint256 count = _vestingCount;

        vestingList = new VestingProperties[](count);

        while (0 < count) {
            --count;

            vestingList[count] = _vestingMap[count];
        }
    }

    /**
     * @notice Get properties list for the user
     * @param wallet User wallet
     * user.isActive   Indicates whether the user is on the whitelist or not
     * Admin can add or remove users.
     * user.spentAmount   Amount that was branded by the user or seized as staking fee
     */
    function userPropertiesList(address wallet)
    external
    view
    returns (UserProperties memory userProperties)
    {
        userProperties = _userMapping[wallet];
    }

    /**
     * @notice Get possible claim amount for user list for vesting pool
     * @param wallet User wallet
     * @param timestampInSeconds Time at which they plan to make claim
     */
    function amountForClaim(address wallet, uint256 timestampInSeconds)
    external
    view
    returns (uint256 amount)
    {
        UserProperties storage user = _userMapping[wallet];
        VestingProperties storage vesting = _vestingMap[user.vestingId];
        amount = _amountForClaim(
            vesting,
            user,
            timestampInSeconds
        );
    }

    /**
     * @notice Only platform admin can do
     * If 0 < vesting.unallocatedAmount amount will be transfer from sender wallet
     */
    function insertVestingList(
        VestingProperties[] calldata vestingList
    ) external onlyPlatformAdmin {
        uint256 count = _vestingCount;
        if(vestingList.length == 0)
            revert EmptyArray();

        uint256 liquidity;

        uint256 index = vestingList.length;

        while (0 < index) {
            --index;

            liquidity += _setVesting(count + index, vestingList[index]);
        }

        _vestingCount += vestingList.length;

        if (liquidity > 0) {
            totalRemainingAllocatedAmount += liquidity;
            emit InsertVestingList(msgSender(), vestingList.length);
        }
    }

    function removeVesting(uint256 vestingId) external onlyPlatformAdmin {
        if(vestingId >= _vestingCount)
            revert OutOfBounds();

        VestingProperties storage vp = _vestingMap[vestingId];
        VestingLink storage vl = _vestingToUser[vestingId];
        UserProperties storage up = _userMapping[vl.user];

        if(!vp.active)
            revert VestingDoesNotExist();

        if(vp.amountForUser < up.spentAmount)
            revert FatalError("user exceeded maximum spending amount");

        uint256 remainingPayoutAmount = vp.amountForUser - up.spentAmount;
        if(totalRemainingAllocatedAmount < remainingPayoutAmount)
            revert FatalError("less balance than allocated amount");
        totalRemainingAllocatedAmount -= remainingPayoutAmount;

        delete _userMapping[vl.user];
        delete _vestingMap[vestingId];
        delete _vestingToUser[vestingId];

        emit VestingRemoved(vestingId, block.timestamp);
    }

    /**
     * @notice Only platform admin can do
     * @param vestingId Target vesting pool id
     * @param amount Target additional liquidity amount
     * Amount will be transfer from sender wallet
     */
    function increaseLiquidity(
        uint256 vestingId,
        uint256 amount,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyPlatformAdmin existingVesting(vestingId) nonReentrant {
        if(amount == 0)
            revert ZeroAmount();

        VestingProperties storage vesting = _vestingMap[vestingId];

        address admin = msgSender();

        IPlatformToken(_token).specialTransferFrom(
            admin,
            amount,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );

        vesting.unallocatedAmount += amount;

        emit IncreaseLiquidity(admin, vestingId, amount);
    }

    /**
     * @notice Only platform admin can do
     * @param amount Target removal liquidity amount
     * Amount will be transfer to sender wallet
     */
    function decreaseLiquidity(uint256 amount)
    external
    onlyPlatformAdmin
    {
        if(amount == 0)
            revert ZeroAmount();
        uint256 availableSenderBalance = IERC20(_token).balanceOf(address(this));
        if(amount > availableSenderBalance)
            revert InsufficientBalance();

        if(totalRemainingAllocatedAmount > availableSenderBalance)
            revert FatalError("balance less than allocated amount");

        uint256 availableBalance = availableSenderBalance - totalRemainingAllocatedAmount;
        if(amount > availableBalance)
            revert InsufficientBalance();

        address admin = msgSender();
        IERC20(_token).safeTransfer(admin, amount);

        emit DecreaseLiquidity(admin, amount);
    }

    function insertWalletListToVesting(
        uint256[] calldata vestingIdList,
        address[] calldata walletList
    ) external onlyPlatformAdmin {
        if(walletList.length != vestingIdList.length)
            revert ArraySizeDoesNotMatch();
        if(walletList.length == 0)
            revert EmptyArray();

        uint256 decrease;

        uint256 index = walletList.length;
        while (0 < index) {
            --index;

            uint256 vestingId = vestingIdList[index];
            if(vestingId >= _vestingCount)
                revert VestingDoesNotExist();

            VestingProperties storage vesting = _vestingMap[vestingId];
            uint256 amountForUser = vesting.amountForUser;

            address wallet = walletList[index];
            UserProperties storage user = _userMapping[wallet];

            if(user.isActive)
                revert UserAlreadyActive();
            user.isActive = true;
            user.vestingId = vestingId;

            VestingLink storage vl = _vestingToUser[vestingId];
            if(vl.active)
                revert VestingAlreadyActive();
            vl.user = wallet;
            vl.active = true;

            decrease = amountForUser - user.spentAmount;

            uint256 oldUnallocatedAmount = vesting.unallocatedAmount;

            if(decrease > oldUnallocatedAmount)
                revert InsufficientBalance();
            vesting.unallocatedAmount = oldUnallocatedAmount - decrease;

            emit InsertWalletListToVesting(msgSender(), vestingId, walletList);
        }
    }

    function removeWalletListFromVesting(
        address[] calldata walletList
    ) external onlyPlatformAdmin {
        if(walletList.length == 0)
            revert EmptyArray();

        uint256 increasing;

        uint256 index = walletList.length;
        while (0 < index) {
            --index;

            address wallet = walletList[index];
            UserProperties storage user = _userMapping[wallet];

            uint256 vestingId = user.vestingId;
            VestingProperties storage vesting = _vestingMap[vestingId];
            uint256 amountForUser = vesting.amountForUser;

            if(!user.isActive)
                revert UserNotActive();
            user.isActive = false;
            VestingLink storage vl = _vestingToUser[vestingId];
            vl.user = address(0);
            vl.active = false;

            increasing = amountForUser - user.spentAmount;

            vesting.unallocatedAmount += increasing;
            emit RemoveWalletListFromVesting(msgSender(), vestingId, walletList);
        }
    }

    /**
     * @notice Claim possible for user amount from the pool
     * If possible amounts equal to zero will revert
     * @param wallet User wallet
     */
    function claim(address wallet) external {
        _claim(wallet);
    }

    function _claim(address wallet) private {
        UserProperties storage user = _userMapping[wallet];
        VestingProperties storage vesting = _vestingMap[user.vestingId];

        uint256 claimAmount = _amountForClaim(vesting, user, block.timestamp);
        if(claimAmount == 0)
            revert NoClaimAvailable();

        user.spentAmount += claimAmount;
        uint256 vestingId = user.vestingId;

        totalRemainingAllocatedAmount -= claimAmount;

        IERC20(_token).safeTransfer(wallet, claimAmount);

        emit Claim(vestingId, wallet, claimAmount);
    }

    /**
    * @notice allows to individually send the TGE amount to a participant
    */
    function distributeAmount(uint256 vestingId) private {
        if(vestingId >= _vestingCount)
            revert OutOfBounds();
        VestingLink memory vl = _vestingToUser[vestingId];

        if(vl.active)   {
            _claim(vl.user);
        }
    }

    /**
    * @notice allows to airdrop currently available amounts to all vesting wallets
    * @param batchSize the number of people being airdropped in this call
    * @param offset the offset to select the correct batch
    */
    function airdrop(uint256 batchSize, uint256 offset) external onlyPlatformAdmin {
        if(offset > _vestingCount)
            revert OutOfBounds();

        uint256 index = _vestingCount - offset;

        while (0 < index) {
            --index;
            if(batchSize == 0)
                return;

            distributeAmount(index);
            batchSize--;
        }
    }

    function _share(
        uint256 amount,
        uint256 share,
        uint256 total
    ) private pure returns (uint256) {
        return (amount * share) / total;
    }

    /**
     * @notice Returns the total amount claimable until the nowPoint point in time
     * @param vesting schedule to calculate amount for
     * @param user to retrieve the already spent amount
     * @param nowTime point in time to check for
     */
    function _amountForClaim(
        VestingProperties storage vesting,
        UserProperties storage user,
        uint256 nowTime
    ) private view returns (uint256) {
        uint256 startTime = vesting.startTime;

        if (!user.isActive) {
            return 0;
        }

        if (nowTime < tgeStartDate) {
            return 0;
        } else if (nowTime >= tgeStartDate && nowTime < startTime) {
            return vesting.tgeAmountForUser - user.spentAmount;
        }



        uint256 tickCount = vesting.tickCount;
        uint256 tick = (nowTime - startTime) / vesting.tickDuration + 1; // at start time, the first tick is available

        uint256 amount = vesting.tgeAmountForUser;
        uint256 rest = vesting.amountForUser - amount;
        if (tick < tickCount) {
            uint256 share = _share(TOTAL_SHARE, tick, tickCount);
            amount += _share(rest, share, TOTAL_SHARE);
        } else {
            amount += rest;
        }

        uint256 alreadyClaimed = user.spentAmount;
        if (amount <= alreadyClaimed) {
            return 0;
        }

        return amount - alreadyClaimed;
    }

    function _setVesting(uint256 vestingId, VestingProperties calldata setting)
    private
    returns (uint256 liquidity)
    {
        if(setting.tgeAmountForUser > setting.amountForUser)
            revert FatalError("tge amount greater than total amount");

        if(setting.startTime <= block.timestamp)
            revert StartBeforeNow();
        if(setting.startTime < tgeStartDate)
            revert StartBeforeTGE();

        if (setting.tgeAmountForUser < setting.amountForUser) {
            if(0 == setting.tickCount || setting.tickDuration == 0)
                revert TicksMissing();
        }

        _vestingMap[vestingId] = setting;

        liquidity = setting.unallocatedAmount;

        emit VestingAdded(
            setting.amountForUser,
            setting.tgeAmountForUser,
            setting.startTime,
            setting.tickCount,
            setting.tickDuration,
            block.timestamp
        );
    }
}