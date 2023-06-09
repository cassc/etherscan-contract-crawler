// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Dependencies/WeekMath.sol";
import "./Interfaces/IBaseRewardPool.sol";
import "./Interfaces/IPendleDepositor.sol";
import "./Interfaces/IPendleProxyMainchain.sol";
import "./Interfaces/IEqbExternalToken.sol";

contract PendleDepositor is IPendleDepositor, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public pendle;

    address public pendleProxy;

    address public ePendle;

    address public ePendleRewardPool;

    uint256 public lockTimeInterval;
    uint256 public lastLockTime;

    uint128 public constant MAX_LOCK_TIME = 104 weeks;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setParams(
        address _pendle,
        address _pendleProxy,
        address _ePendle,
        address _ePendleRewardPool
    ) external onlyOwner {
        require(pendleProxy == address(0), "params have already been set");

        require(_pendle != address(0), "invalid _pendle!");
        require(_pendleProxy != address(0), "invalid _pendleProxy!");
        require(_ePendle != address(0), "invalid _ePendle!");
        require(
            _ePendleRewardPool != address(0),
            "invalid _ePendleRewardPool!"
        );

        pendle = _pendle;

        pendleProxy = _pendleProxy;
        ePendle = _ePendle;

        ePendleRewardPool = _ePendleRewardPool;

        lockTimeInterval = 1 days;
        lastLockTime = block.timestamp;
    }

    function setLockTimeInterval(uint256 _lockTimeInterval) external onlyOwner {
        lockTimeInterval = _lockTimeInterval;
    }

    // lock pendle
    function _lockPendle() internal {
        uint256 pendleBalance = IERC20(pendle).balanceOf(address(this));
        if (pendleBalance > 0) {
            IERC20(pendle).safeTransfer(pendleProxy, pendleBalance);
        }

        IPendleProxyMainchain(pendleProxy).lockPendle(
            WeekMath.getWeekStartTimestamp(
                uint128(block.timestamp) + MAX_LOCK_TIME
            )
        );
        lastLockTime = block.timestamp;
    }

    function lockPendle() external onlyOwner {
        _lockPendle();
    }

    // deposit pendle for ePendle
    function deposit(uint256 _amount, bool _stake) public override {
        require(_amount > 0, "!>0");

        if (block.timestamp > lastLockTime + lockTimeInterval) {
            // lock immediately, transfer directly to pendleProxy to skip an erc20 transfer
            IERC20(pendle).safeTransferFrom(msg.sender, pendleProxy, _amount);
            _lockPendle();
        } else {
            // move tokens here
            IERC20(pendle).safeTransferFrom(msg.sender, address(this), _amount);
        }

        if (!_stake) {
            // mint for msg.sender
            IEqbExternalToken(ePendle).mint(msg.sender, _amount);
        } else {
            // mint here
            IEqbExternalToken(ePendle).mint(address(this), _amount);
            // stake for msg.sender
            IERC20(ePendle).safeApprove(ePendleRewardPool, 0);
            IERC20(ePendle).safeApprove(ePendleRewardPool, _amount);
            IBaseRewardPool(ePendleRewardPool).stakeFor(msg.sender, _amount);
        }

        emit Deposited(msg.sender, _amount);
    }

    function depositAll(bool _stake) external {
        uint256 pendleBal = IERC20(pendle).balanceOf(msg.sender);
        deposit(pendleBal, _stake);
    }
}