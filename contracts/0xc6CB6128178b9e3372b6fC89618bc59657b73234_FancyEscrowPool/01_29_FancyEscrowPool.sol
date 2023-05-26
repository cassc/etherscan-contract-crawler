// SPDX-License-Identifier: MIT
// Forked from Merit Circle
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./base/BaseEscrowPool.sol";
import "./interfaces/IFancyStakingPool.sol";
import "./interfaces/ILiquidityMiningManager.sol";

contract FancyEscrowPool is BaseEscrowPool, IFancyStakingPool {
    using Math for uint256;
    using SafeERC20 for IMintableBurnableERC20;

    uint256 public constant MIN_LOCK_DURATION = 10 minutes;

    uint256 public immutable maxLockDuration;
    mapping(address => Deposit[]) public depositsOf;

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
    }
    address public rewardSource;
    ILiquidityMiningManager public liquidityMiningManager;
    IMintableBurnableERC20 public immutable withdrawToken;

    constructor(
        string memory _name,
        string memory _symbol,
        address _withdrawToken,
        address _rewardSource,
        ILiquidityMiningManager _liquidityMiningManager,
        uint256 _maxLockDuration
    ) BaseEscrowPool(_name, _symbol) {
        require(_withdrawToken != address(0), "BaseEscrowPool.constructor: Withdraw token must be set");
        require(_rewardSource != address(0), "BaseEscrowPool.constructor: Reward source must be set");
        withdrawToken = IMintableBurnableERC20(_withdrawToken);
        require(
            _maxLockDuration >= MIN_LOCK_DURATION,
            "FancyEscrowPool.constructor: max lock duration must be greater or equal to minimum lock duration"
        );
        maxLockDuration = _maxLockDuration;
        rewardSource = _rewardSource;
        liquidityMiningManager = _liquidityMiningManager;
    }

    event Deposited(uint256 amount, uint256 duration, address indexed receiver, address indexed from);
    event Withdrawn(uint256 indexed depositId, address indexed receiver, address indexed from, uint256 amount);

    function deposit(
        uint256 _amount,
        uint256 _duration,
        address _receiver
    ) external override {
        require(liquidityMiningManager.getPoolAdded(msg.sender), "only pools");
        require(_amount > 0, "FancyEscrowPool.deposit: cannot deposit 0");
        // Don't allow locking > maxLockDuration
        uint256 duration = _duration.min(maxLockDuration);
        // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
        duration = duration.max(MIN_LOCK_DURATION);

        depositsOf[_receiver].push(
            Deposit({
                amount: _amount,
                start: uint64(block.timestamp),
                end: uint64(block.timestamp) + uint64(duration)
            })
        );

        _mint(_receiver, _amount);
        emit Deposited(_amount, duration, _receiver, _msgSender());
    }

    function withdraw(uint256 _depositId, address _receiver) external {
        require(_depositId < depositsOf[_msgSender()].length, "FancyEscrowPool.withdraw: Deposit does not exist");
        Deposit memory userDeposit = depositsOf[_msgSender()][_depositId];
        require(block.timestamp >= userDeposit.end, "FancyEscrowPool.withdraw: too soon");

        // remove Deposit
        depositsOf[_msgSender()][_depositId] = depositsOf[_msgSender()][depositsOf[_msgSender()].length - 1];
        depositsOf[_msgSender()].pop();

        // burn pool shares
        _burn(_msgSender(), userDeposit.amount);

        withdrawToken.safeTransferFrom(rewardSource, _receiver, userDeposit.amount); // transfer FNC
        emit Withdrawn(_depositId, _receiver, _msgSender(), userDeposit.amount);
    }

    function getTotalDeposit(address _account) public view returns (uint256) {
        uint256 total;
        for (uint256 i; i < depositsOf[_account].length; i++) {
            total += depositsOf[_account][i].amount;
        }

        return total;
    }

    function getDepositsOf(address _account) public view returns (Deposit[] memory) {
        return depositsOf[_account];
    }

    function getDepositsOfLength(address _account) public view returns (uint256) {
        return depositsOf[_account].length;
    }
}