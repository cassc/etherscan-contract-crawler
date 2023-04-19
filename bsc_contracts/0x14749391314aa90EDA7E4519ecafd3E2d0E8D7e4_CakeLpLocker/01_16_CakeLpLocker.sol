// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "@shared/lib-contracts/contracts/Dependencies/ManagerUpgradeable.sol";
import "./Interfaces/Pancake/IPancakePair.sol";
import "./Interfaces/IVlQuoV2.sol";
import "./Interfaces/ILpLocker.sol";

contract CakeLpLocker is
    ILpLocker,
    ManagerUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public token;

    IVlQuoV2 public vlQuoV2;
    IERC20 public quo;

    uint256 public multiplier;

    uint256 public constant WEEK = 86400 * 7;
    uint256 public constant MAX_LOCK_WEEKS = 52;

    uint256 public maxLockLength;

    address public treasury;

    uint256 public constant FEE_DENOMINATOR = 10000;

    struct LockInfo {
        uint256 amount;
        uint256 vlQuoAmount;
        uint256 lockTime;
        uint256 unlockTime;
    }

    mapping(address => LockInfo[]) public userLocks;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function initialize() public initializer {
        __ManagerUpgradeable_init();

        __ReentrancyGuard_init_unchained();

        __Pausable_init_unchained();
    }

    function setParams(
        address _token,
        address _vlquoV2,
        address _treasury
    ) external onlyOwner {
        require(address(token) == address(0), "params have already been set");

        require(_token != address(0), "invalid _token!");
        require(_vlquoV2 != address(0), "invalid _vlquoV2!");
        require(_treasury != address(0), "invalid _treasury!");

        token = _token;
        vlQuoV2 = IVlQuoV2(_vlquoV2);
        quo = vlQuoV2.quo();
        treasury = _treasury;

        maxLockLength = 10000;
        multiplier = 10000;
    }

    function setMultiplier(uint256 _multiplier) external onlyManager {
        multiplier = _multiplier;
    }

    function pause() external onlyManager {
        _pause();
    }

    function unpause() external onlyManager {
        _unpause();
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return _balances[_user];
    }

    function getUserLocks(
        address _user
    ) external view returns (LockInfo[] memory) {
        return userLocks[_user];
    }

    function lock(
        address _user,
        uint256 _amount,
        uint256 _weeks
    ) external override nonReentrant whenNotPaused {
        require(_user != address(0), "invalid _user!");
        require(
            msg.sender == _user || !vlQuoV2.blockThirdPartyActions(_user),
            "Cannot lock on behalf of this account"
        );

        require(_weeks > 0, "Min 1 week");
        require(_weeks <= MAX_LOCK_WEEKS, "Exceeds MAX_LOCK_WEEKS");
        require(_amount > 0, "Amount must be nonzero");

        require(userLocks[_user].length < maxLockLength, "locks too much");

        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 vlQuoAmount = _getVlQuoAmount(_amount, _weeks);
        uint256 unlockTime = _getNextWeek().add(_weeks.mul(WEEK));
        userLocks[_user].push(
            LockInfo(_amount, vlQuoAmount, block.timestamp, unlockTime)
        );

        _totalSupply = _totalSupply.add(_amount);
        _balances[_user] = _balances[_user].add(_amount);

        vlQuoV2.increaseBalance(_user, vlQuoAmount);

        emit Locked(_user, _amount, _weeks);
    }

    function unlock(
        uint256 _slot
    ) external override nonReentrant whenNotPaused {
        uint256 length = userLocks[msg.sender].length;
        require(_slot < length, "wut?");

        LockInfo memory lockInfo = userLocks[msg.sender][_slot];
        require(lockInfo.unlockTime <= block.timestamp, "not yet meh");

        _totalSupply = _totalSupply.sub(lockInfo.amount);
        _balances[msg.sender] = _balances[msg.sender].sub(lockInfo.amount);

        uint256 punishment;
        {
            uint256 unlockGracePeriod = vlQuoV2.unlockGracePeriod();
            if (block.timestamp > lockInfo.unlockTime.add(unlockGracePeriod)) {
                punishment = block
                    .timestamp
                    .sub(lockInfo.unlockTime.add(unlockGracePeriod))
                    .div(WEEK)
                    .add(1)
                    .mul(vlQuoV2.unlockPunishment())
                    .mul(lockInfo.amount)
                    .div(FEE_DENOMINATOR);
                punishment = Math.min(punishment, lockInfo.amount);
            }
        }

        // remove slot
        if (_slot != length - 1) {
            userLocks[msg.sender][_slot] = userLocks[msg.sender][length - 1];
        }
        userLocks[msg.sender].pop();

        if (punishment > 0) {
            _safeTransferToken(token, treasury, punishment);
        }
        _safeTransferToken(token, msg.sender, lockInfo.amount.sub(punishment));

        vlQuoV2.decreaseBalance(msg.sender, lockInfo.vlQuoAmount);

        emit Unlocked(
            msg.sender,
            lockInfo.unlockTime,
            lockInfo.amount,
            lockInfo.vlQuoAmount
        );
    }

    function getVlQuoAmount(
        uint256 _amount,
        uint256 _weeks
    ) external view returns (uint256) {
        return _getVlQuoAmount(_amount, _weeks);
    }

    function _safeTransferToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 tokenBal = IERC20(_token).balanceOf(address(this));
        if (_amount > tokenBal) {
            _amount = tokenBal;
        }
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _getVlQuoAmount(
        uint256 _amount,
        uint256 _weeks
    ) internal view returns (uint256) {
        return
            _amount
                .mul(quo.balanceOf(token))
                .div(IPancakePair(token).totalSupply())
                .mul(_weeks)
                .mul(multiplier)
                .div(FEE_DENOMINATOR);
    }

    function _getCurWeek() internal view returns (uint256) {
        return block.timestamp.div(WEEK).mul(WEEK);
    }

    function _getNextWeek() internal view returns (uint256) {
        return _getCurWeek().add(WEEK);
    }
}