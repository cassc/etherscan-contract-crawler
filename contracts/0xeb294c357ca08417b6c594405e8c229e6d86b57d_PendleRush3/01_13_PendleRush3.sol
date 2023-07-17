// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/ILocker.sol";
import "../interfaces/IConvertor.sol";

/// @title PendleRush3
/// @notice Contract for calculating incentive deposits and rewards points with the Pendle token
contract PendleRush3 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    struct UserInfo {
        uint256 converted;
        uint256 rewardClaimed;
    }    

    IERC20 public PENDLE; // Pendle token
    IERC20 public PNP;    // Penpie token
    ILocker public vlPNP; // Added this line
    address public mPendleConvertor;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public tierLength;
    uint256 public totalAccumulated;
    
    uint256[] public rewardMultiplier;
    uint256[] public rewardTier;

    mapping(address => UserInfo) public userInfos; // Total conversion amount per user

    /* ============ Events ============ */

    event PendleConverted(address indexed _account, uint256 _amount, uint256 _rewardedVlPNP);

    /* ============ Errors ============ */

    error InvalidAmount();
    error LengthMissmatch();    

    /* ============ Initialization ============ */

    function _PendleRush3_init(
        address _pendle,
        address _mPendleConvertor,
        address _vlPNP,
        address _PNP
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        PENDLE = IERC20(_pendle);
        vlPNP = ILocker(_vlPNP); // Corrected this line
        mPendleConvertor = _mPendleConvertor;
        PNP = IERC20(_PNP);
    }

    /* ============ External Read Functions ============ */

    function quoteDeposit(
        uint256 _amount,
        address _account
    ) public view returns (uint256) {
        if (_amount == 0 || rewardMultiplier.length == 0) return 0;
        
        UserInfo storage userInfo = userInfos[_account];
        uint256 accumulated = _amount + userInfo.converted;

        uint256 rewardAmount = 0;
        uint256 i = 1;
        while (i < rewardTier.length && accumulated > rewardTier[i]) {
            rewardAmount +=
                (rewardTier[i] - rewardTier[i - 1]) *
                rewardMultiplier[i - 1];
            i++;
        }
        rewardAmount +=
            (accumulated - rewardTier[i - 1]) *
            rewardMultiplier[i - 1];

        uint256 vlPNPReward = (rewardAmount / DENOMINATOR) - userInfo.rewardClaimed;
        uint256 PNPleft = PNP.balanceOf(address(this));

        return vlPNPReward > PNPleft ? PNPleft : vlPNPReward;
    }

    function getUserTier(address _account) public view returns (uint256) {
        uint256 userDeposited = userInfos[_account].converted;
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

        return rewardTier[userTier + 1] - userInfos[_account].converted;
    }

    /* ============ External Write Functions ============ */

    function deposit(uint256 _amount, bool _isStake) external whenNotPaused nonReentrant {
        IERC20(PENDLE).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(PENDLE).safeApprove(address(mPendleConvertor),_amount);
        if (_isStake)
            IConvertor(mPendleConvertor).convert(msg.sender, _amount, 1);
        else 
            IConvertor(mPendleConvertor).convert(msg.sender, _amount, 0);

        uint256 rewardToSend = this.quoteDeposit(_amount, msg.sender);

        UserInfo storage userInfo = userInfos[msg.sender];
        userInfo.converted += _amount;
        userInfo.rewardClaimed += rewardToSend;
        totalAccumulated += _amount;

        PNP.safeApprove(address(vlPNP), rewardToSend);
        vlPNP.lockFor(rewardToSend, msg.sender);

        emit PendleConverted(msg.sender, _amount, rewardToSend);
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

    function adminWithdrawTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
    }
}