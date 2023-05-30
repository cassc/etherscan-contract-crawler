// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IMint.sol";
import "@solmate/tokens/ERC20.sol";
import "./interfaces/IESZTHV1.sol";

/**
 * @title Zenith ETH
 */
contract ESZTHV2 is ERC20("Zenith Escrowed Token V2", "esZTH2", 18) {
    uint256 private constant _SLEEP_TIMES = 1 minutes;
    uint256 private constant _MAX_LOCK_TIMES = 14 days;
    address private constant _DEAD = 0x000000000000000000000000000000000000dEaD;

    address public immutable MASTERCHEF;
    address public immutable TREASURY;
    address public immutable ZTHTOKEN;

    LockInfo[] private _lockPositions;
    IESZTHV1 private immutable _exZTHV1;
    uint256 private immutable _v1LastLockId;
    mapping(address => bool) public balanceSynced;

    struct LockInfo {
        address holder;
        uint64 unlockTime;
        uint128 amountIn;
        uint128 amountOut;
    }

    constructor(address masterChef, address treasury, address zthToken, IESZTHV1 exZTHV1, uint256 v1LastLockId) {
        if (masterChef == address(0)) revert AddressIsZero();
        if (treasury == address(0)) revert AddressIsZero();
        if (zthToken == address(0)) revert AddressIsZero();

        MASTERCHEF = masterChef;
        TREASURY = treasury;
        ZTHTOKEN = zthToken;
        _v1LastLockId = v1LastLockId;
        _exZTHV1 = exZTHV1;

        assembly {
            sstore(_lockPositions.slot, add(v1LastLockId, 1))
        }
    }

    function syncV1(address account) public {
        if (balanceSynced[account]) return;
        balanceSynced[account] = true;

        uint256 balance = _exZTHV1.balanceOf(account);
        if (balance > 0) {
            _mint(account, balance);
        }
    }

    function balanceOfV2(address account) public view returns (uint256) {
        if (balanceSynced[account]) {
            return balanceOf[account];
        }
        return balanceOf[account] + _exZTHV1.balanceOf(account);
    }

    function mint(address to, uint256 amount) external onlyMasterChef {
        syncV1(to);
        _mint(to, amount);
    }

    function swapWithPermit(uint256 amount, uint256 lockTimes, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        // get allowance
        // use the max approve
        ERC20(ZTHTOKEN).permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);

        swap(amount, lockTimes);
    }

    /**
     * @notice Swap ESZTH to ZTH
     * @dev Early redemption will result in the loss of the corresponding ZTH share,
     *  which 50% will be burned and other 50% belonging to the team treasury.
     */
    function swap(uint256 amount, uint256 lockTimes) public {
        syncV1(msg.sender);

        _burn(msg.sender, amount);

        // stake the same amount of ZTH
        ERC20(ZTHTOKEN).transferFrom(msg.sender, address(this), amount);

        uint256 amountOut = getAmountOut(amount, lockTimes);

        uint256 loss;
        unchecked {
            loss = amount - amountOut;
        }
        // mint ZTH to treasury
        if (loss > 0) {
            IMint(ZTHTOKEN).mint(_DEAD, loss / 2);
            IMint(ZTHTOKEN).mint(TREASURY, loss / 2);
        }

        uint256 lid = _lockPositions.length;
        _lockPositions.push(
            LockInfo({
                holder: msg.sender,
                unlockTime: uint64(block.timestamp + lockTimes),
                amountIn: uint128(amount),
                amountOut: uint128(amountOut)
            })
        );
        emit Swap(msg.sender, lid, amount, lockTimes, amountOut);
    }

    function redeemV1(uint256 lockId) public {
        if (_lockPositions[lockId].holder != address(0)) revert LockedAmountIsZero();

        // get lock position from v1 contract
        (address holder, uint256 amount, uint256 unlockTime) = _exZTHV1.getLockPosition(lockId);
        if (unlockTime > block.timestamp) revert UnlockTimeNotArrived();
        if (amount == 0) revert LockedAmountIsZero();

        // update state
        _lockPositions[lockId] = LockInfo(holder, uint64(unlockTime), 0, 0);

        // mint ZTH to holder
        IMint(ZTHTOKEN).mint(holder, amount);
        emit Redeem(holder, lockId, amount);
    }

    function redeem(uint256 lockId) public {
        if (lockId <= _v1LastLockId) {
            redeemV1(lockId);
        } else {
            LockInfo storage lockInfo = _lockPositions[lockId];
            if (lockInfo.unlockTime > block.timestamp) revert UnlockTimeNotArrived();
            uint256 amount = lockInfo.amountOut;

            if (amount == 0) revert LockedAmountIsZero();

            // update state
            lockInfo.amountOut = 0;
            // mint ZTH to holder
            IMint(ZTHTOKEN).mint(lockInfo.holder, amount);
            // unlock staked ZTH to holder
            ERC20(ZTHTOKEN).transfer(lockInfo.holder, lockInfo.amountIn);

            emit Redeem(lockInfo.holder, lockId, amount);
        }
    }

    function batchRedeem(uint256[] calldata lockIds) external {
        for (uint256 i = 0; i < lockIds.length; i++) {
            redeem(lockIds[i]);
        }
    }

    function getAmountOut(uint256 amount, uint256 lockTimes) public pure returns (uint256) {
        if (lockTimes < _SLEEP_TIMES || lockTimes > _MAX_LOCK_TIMES) revert InvalidLockTimes();
        // 20% of the amount will be locked for 3 days
        // 100% of the amount will be locked for 14 days
        // amount= 20%+ 80%*(lockTimes-3days)/(14days-3days)
        unchecked {
            return (amount * 2 + amount * 8 * (lockTimes - _SLEEP_TIMES) / (_MAX_LOCK_TIMES - _SLEEP_TIMES)) / 10;
        }
    }

    function getLockPosition(uint256 lockId) external view returns (LockInfo memory) {
        return _lockPositions[lockId];
    }

    function getLastPositionId() external view returns (uint256) {
        return _lockPositions.length - 1;
    }

    modifier onlyMasterChef() {
        if (msg.sender != MASTERCHEF) revert OnlyCallByMasterChef();

        _;
    }

    event Swap(address indexed holder, uint256 lockId, uint256 amount, uint256 lockTimes, uint256 amountOut);
    event Redeem(address indexed holder, uint256 lockId, uint256 amount);

    error AddressIsZero();
    error OnlyCallByMasterChef();
    error InvalidLockTimes();
    error LockedAmountIsZero();
    error UnlockTimeNotArrived();
}