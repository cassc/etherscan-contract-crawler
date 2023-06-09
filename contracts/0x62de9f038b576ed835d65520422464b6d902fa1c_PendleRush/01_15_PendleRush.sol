// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { IMasterPenpie } from "../interfaces/IMasterPenpie.sol";

/// @title PendleRush
/// @author Magpie Team, an incentive program to accumulate pendle
/// @notice pendle will be transfered to admin and lock forever

contract PendleRush is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    struct UserInfo {
        uint256 deposited;
        uint256 factor;
    }

    uint256 public constant DENOMINATOR = 10000;

    address public pendle;
    address public weth;

    mapping(address => UserInfo) public userInfos;
    uint256 public totalFactor;
    uint256 public totalDeposited;

    uint256 public tierLength;
    uint256[] public rewardMultiplier;
    uint256[] public rewardTier;

    //Upgrade
    address public mPendleOFT;
    address public masterPenpie;
    mapping(address => uint256) public claimedMPendle;

    /* ============ Events ============ */

    event Deposit(
        address indexed _user,
        uint256 _amount,
        uint256 _factorReceived
    );

    event Claim(address indexed _user, uint256 _amount);
    event SetAddresses(address _oldMPendleOFT, address _newMPendleOFT, address _oldMasterPenpie, address _newMasterPenpie);

    /* ============ Errors ============ */

    error InvalidAmount();
    error LengthMissmatch();
    error MasterPenpieNotSet();
    error AlreadyClaimed();

    /* ============ Constructor ============ */

    function __PendleRush_init(
        address _pendle,
        address _weth
    ) public initializer {
        __Ownable_init();
        pendle = _pendle;
        weth = _weth;
    }

    /* ============ Modifier ============ */

    /* ============ External Read Functions ============ */

    function quoteDeposit(
        uint256 _amountToDeposit,
        address _account
    ) external view returns (uint256 newUserFactor, uint256 newTotalFactor) {
        UserInfo memory userInfo = userInfos[_account];

        newTotalFactor = totalFactor - userInfo.factor;
        uint256 accumulated = _amountToDeposit + userInfo.deposited;
        uint256 accumulatedFactor = 0;
        uint256 i = 1;

        while (i < rewardTier.length && accumulated > rewardTier[i]) {
            accumulatedFactor +=
                (rewardTier[i] - rewardTier[i - 1]) *
                rewardMultiplier[i - 1];
            i++;
        }

        // Suggestion:
        // Do not accumulate the factor if the accumulated is less than the first tier.
        // if(rewardTier[i - 1] <= accumulated)
        accumulatedFactor +=
            (accumulated - rewardTier[i - 1]) *
            rewardMultiplier[i - 1];
        newUserFactor = (accumulatedFactor / DENOMINATOR);
        newTotalFactor += newUserFactor;
    }

    function getUserTier(address _account) public view returns (uint256) {
        uint256 userDeposited = userInfos[_account].deposited;
        for (uint256 i = tierLength - 1; i >= 1; i--) {
            if (userDeposited >= rewardTier[i]) {
                return i;
            }
        }

        return 0;
    }

    function amountToNextTier(
        address _account
    ) external view returns (uint256) {
        uint256 userTier = this.getUserTier(_account);
        if (userTier == tierLength - 1) return 0;

        return rewardTier[userTier + 1] - userInfos[_account].deposited;
    }

    /* ============ External Write Functions ============ */

    function deposit(uint256 _amount) external whenNotPaused nonReentrant {
        UserInfo storage userInfo = userInfos[msg.sender];
        uint256 originalFactor = userInfo.factor;
        if (_amount == 0) revert InvalidAmount();

        IERC20(pendle).safeTransferFrom(msg.sender, address(this), _amount);

        (userInfo.factor, totalFactor) = this.quoteDeposit(_amount, msg.sender);
        userInfo.deposited += _amount;
        totalDeposited += _amount;

        emit Deposit(msg.sender, _amount, userInfo.factor - originalFactor);
    }

    // no need to be paused to claim.
    function claim(bool _isStake) external nonReentrant {
        if (claimedMPendle[msg.sender] > 0)
            revert AlreadyClaimed();

        UserInfo storage userInfo = userInfos[msg.sender];

        if (_isStake && userInfo.deposited > 0) {
            if (masterPenpie == address(0)) revert MasterPenpieNotSet();
            IERC20(mPendleOFT).safeApprove(
                address(masterPenpie),
                userInfo.deposited
            );
            IMasterPenpie(masterPenpie).depositFor(
                address(mPendleOFT),
                address(msg.sender),
                userInfo.deposited
            );
        } else if (userInfo.deposited > 0) {
            IERC20(mPendleOFT).transfer(msg.sender, userInfo.deposited);
            emit Claim(msg.sender, userInfo.deposited);
        }

        claimedMPendle[msg.sender] = userInfo.deposited;
    }

    /* ============ Admin Functions ============ */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMultiplier(
        uint256[] calldata _multiplier,
        uint256[] calldata _tier
    ) external onlyOwner {
        if (
            _multiplier.length == 0 ||
            _tier.length == 0 ||
            (_multiplier.length != _tier.length)
        ) revert LengthMissmatch();

        for (uint8 i = 0; i < _multiplier.length; ++i) {
            if (_multiplier[i] == 0) revert InvalidAmount();
            rewardMultiplier.push(_multiplier[i]);
            rewardTier.push(_tier[i]);
            tierLength += 1;
        }
    }

    function resetMultiplier() external onlyOwner {
        uint256 len = rewardMultiplier.length;
        for (uint8 i = 0; i < len; ++i) {
            rewardMultiplier.pop();
            rewardTier.pop();
        }

        tierLength = 0;
    }

   function setAddresses(address _mPendleOFT, address _masterPenpie) external onlyOwner {
        address oldMPendleOFT = mPendleOFT;
        address oldMasterPenpie = masterPenpie;
        mPendleOFT = _mPendleOFT;
        masterPenpie = _masterPenpie;

        emit SetAddresses(oldMPendleOFT, _mPendleOFT, oldMasterPenpie, _masterPenpie);
    }

    function adminWithdrawPendle() external onlyOwner {
        uint256 pendleBalance = IERC20(pendle).balanceOf(address(this));
        IERC20(pendle).safeTransfer(owner(), pendleBalance);
    }
}