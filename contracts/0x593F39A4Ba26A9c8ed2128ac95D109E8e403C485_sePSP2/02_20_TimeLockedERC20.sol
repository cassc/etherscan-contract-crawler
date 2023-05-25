pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "./Utils.sol";

error TimelockOutOfRange(uint256 attemptedTimelockDuration);
error CannotCancelWithdrawalRequest(int256 reqId);
error CannotWithdraw(int256 reqId);
error CannotWithdrawYet(int256 reqId);
error InvalidWithdrawalRequestId(int256 reqId);

contract TimeLockedERC20 is ERC20Permit, Ownable, Pausable {
    enum WITHDRAW_STATUS {
        UNUSED,
        UNLOCKING,
        RELEASED,
        CANCELLED
    }

    IERC20 public immutable asset;

    uint256 public timeLockDuration;

    uint256 public immutable minTimeLockDuration;
    uint256 public immutable maxTimeLockDuration;

    uint256 public unlockingAssets;

    struct WithdrawalRequest {
        uint256 amount;
        uint256 releaseTime;
        WITHDRAW_STATUS status;
    }

    mapping(address => mapping(int256 => WithdrawalRequest)) public userVsWithdrawals;

    mapping(address => int256) public userVsNextID;

    event TimeLockChanged(uint256 oldTimeLock, uint256 newTimeLock);

    event RequestedUnlocking(int256 indexed id, address indexed user, uint256 amount);

    event Withdraw(int256 indexed id, address indexed user, uint256 amount);

    event Deposited(address indexed user, uint256 amount);

    event CancelledWithdrawalRequest(int256 indexed id, address indexed user, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        IERC20 _asset,
        uint256 _timeLockDuration,
        uint256 _minTimeLockDuration,
        uint256 _maxTimeLockDuration
    ) public ERC20Permit(name) ERC20(name, symbol) {
        if (_timeLockDuration < _minTimeLockDuration || _timeLockDuration > _maxTimeLockDuration) {
            revert TimelockOutOfRange(_timeLockDuration);
        }

        asset = _asset;
        timeLockDuration = _timeLockDuration;
        minTimeLockDuration = _minTimeLockDuration;
        maxTimeLockDuration = _maxTimeLockDuration;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function changeTimeLock(uint256 newTimeLockDuration) external onlyOwner {
        if (newTimeLockDuration < minTimeLockDuration || newTimeLockDuration > maxTimeLockDuration) {
            revert TimelockOutOfRange(newTimeLockDuration);
        }

        emit TimeLockChanged(timeLockDuration, newTimeLockDuration);

        timeLockDuration = newTimeLockDuration;
    }

    function depositWithPermit(uint256 _assetAmount, bytes calldata permit) external {
        Utils.permit(asset, permit);
        deposit(_assetAmount);
    }

    function requestWithdraw(uint256 _unlockingAmount) external {
        int256 id = userVsNextID[msg.sender]++;

        _burn(msg.sender, _unlockingAmount);

        WithdrawalRequest storage request = userVsWithdrawals[msg.sender][id];

        request.amount = _unlockingAmount;
        request.releaseTime = block.timestamp + timeLockDuration;
        request.status = WITHDRAW_STATUS.UNLOCKING;

        unlockingAssets += _unlockingAmount;

        emit RequestedUnlocking(id, msg.sender, _unlockingAmount);
    }

    function withdrawMultiple(int256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            withdraw(ids[i]);
        }
    }

    function cancelMultipleWithdrawalRequests(int256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            cancelWithdrawalRequest(ids[i]);
        }
    }

    function deposit(uint256 _assetAmount) public {
        asset.transferFrom(msg.sender, address(this), _assetAmount);

        _deposit(_assetAmount);
    }

    function _deposit(uint256 _assetAmount) internal whenNotPaused {
        _mint(msg.sender, _assetAmount);

        emit Deposited(msg.sender, _assetAmount);
    }

    function withdraw(int256 id) public {
        uint256 _assetAmount = _withdraw(id);
        asset.transfer(msg.sender, _assetAmount);
    }

    function _withdraw(int256 id) internal returns (uint256) {
        if (id < 0) {
            revert InvalidWithdrawalRequestId(id);
        }

        WithdrawalRequest storage request = userVsWithdrawals[msg.sender][id];

        if (request.status != WITHDRAW_STATUS.UNLOCKING) {
            revert CannotWithdraw(id);
        }

        if (request.releaseTime > block.timestamp) {
            revert CannotWithdrawYet(id);
        }

        request.status = WITHDRAW_STATUS.RELEASED;

        uint256 _assetAmount = request.amount;

        unlockingAssets -= _assetAmount;

        emit Withdraw(id, msg.sender, _assetAmount);

        return _assetAmount;
    }

    function cancelWithdrawalRequest(int256 id) public whenNotPaused {
        if (id < 0) {
            revert InvalidWithdrawalRequestId(id);
        }

        WithdrawalRequest storage request = userVsWithdrawals[msg.sender][id];
        if (request.status != WITHDRAW_STATUS.UNLOCKING) {
            revert CannotCancelWithdrawalRequest(id);
        }

        request.status = WITHDRAW_STATUS.CANCELLED;

        uint256 _assetAmount = request.amount;

        _mint(msg.sender, _assetAmount);

        unlockingAssets -= _assetAmount;

        emit CancelledWithdrawalRequest(id, msg.sender, _assetAmount);
    }

    // This is for use off chain, it finds any locked IDs in the specified range
    // If start is negative, starts looking that many entries back from the end
    function findUnlockingIDs(
        address user,
        int256 start,
        uint16 countToCheck
    ) external view returns (int256[] memory ids) {
        int256 nextID = userVsNextID[user];

        if (start >= nextID) return ids;
        if (start < 0) start += nextID;
        int256 end = start + int256(uint256(countToCheck));
        if (end <= 0) return ids;
        if (end > nextID) end = nextID;
        if (start < 0) start = 0;

        mapping(int256 => WithdrawalRequest) storage withdrawals = userVsWithdrawals[user];

        ids = new int256[](uint256(end - start));
        uint256 length = 0;

        // Nothing in here can overflow so disable the checks for the loop
        unchecked {
            for (int256 id = start; id < end; ++id) {
                if (withdrawals[id].status == WITHDRAW_STATUS.UNLOCKING) {
                    ids[length++] = id;
                }
            }
        }

        // Need to force the array length to the correct value using assembly
        assembly {
            mstore(ids, length)
        }
    }
}