// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../core/SafeOwnable.sol";
import "./BabyPoolV2.sol";
import 'hardhat/console.sol';

contract BabyAutoPoolV2 is SafeOwnable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares;                 // number of shares for a user
        uint256 lastDepositedTime;      // keeps track of deposited time for potential penalty
        uint256 babyAtLastUserAction;   // keeps track of baby deposited at the last user action
        uint256 lastUserActionTime;     // keeps track of the last user action time
    }

    IERC20 public immutable token; 
    BabyPoolV2 public immutable pool;
    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;
    uint256 public lastHarvestedTime;
    address public admin;
    address public treasury;

    uint256 public constant MAX_PERFORMANCE_FEE = 500;          // 5%
    uint256 public constant MAX_CALL_FEE = 100;                 // 1%
    uint256 public constant MAX_WITHDRAW_FEE = 100;             // 1%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 72 hours; // 3 days

    uint256 public performanceFee = 200;                        // 2%
    uint256 public callFee = 25;                                // 0.25%
    uint256 public withdrawFee = 10;                            // 0.1%
    uint256 public withdrawFeePeriod = 72 hours;                // 3 days

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender, uint256 performanceFee, uint256 callFee);
    event Pause();
    event Unpause();

    constructor(BabyPoolV2 _pool, address _admin, address _treasury, address _owner) {
        require(address(_pool) != address(0), "_pool address should not be address(0)");
        require(_admin != address(0), "_admin should not be address(0)");
        require(_treasury != address(0), "_treasury should not be address(0)");
        token = _pool.token();
        pool = _pool;
        admin = _admin;
        treasury = _treasury;
        // Infinite approve
        _pool.token().safeApprove(address(_pool), uint256(-1));
        if (_owner != address(0)) {
            _transferOwnership(_owner);
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    mapping(string => bool) private _methodStatus;
    modifier nonReentrant(string memory methodName) {
        require(!_methodStatus[methodName], "reentrant call");
        _methodStatus[methodName] = true;
        _;
        _methodStatus[methodName] = false;
    }

    function balanceOf() public view returns (uint256) {
        (uint256 amount, ) = pool.userInfo(address(this));
        return token.balanceOf(address(this)).add(amount);
    }

    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function _earn() internal {
        uint256 bal = available();
        if (bal > 0) {
            pool.enterStaking(bal);
        }
    }

    function deposit(uint256 _amount)
        external
        whenNotPaused
        notContract
        nonReentrant("deposit")
    {
        require(_amount > 0, "Nothing to deposit");

        uint256 poolBalance = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(poolBalance);
        } else {
            currentShares = _amount;
        }
        UserInfo storage user = userInfo[msg.sender];
        user.shares = user.shares.add(currentShares);
        user.lastDepositedTime = block.timestamp;
        totalShares = totalShares.add(currentShares);
        user.babyAtLastUserAction = user.shares.mul(balanceOf()).div(
            totalShares
        );
        user.lastUserActionTime = block.timestamp;
        _earn();
        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    function withdraw(uint256 _shares)
        public
        notContract
        nonReentrant("withdraw")
    {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        uint256 bal = available();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount.sub(bal);
            pool.leaveStaking(balWithdraw);
            uint256 balAfter = available();
            uint256 diff = balAfter.sub(bal);
            if (diff < balWithdraw) {
                currentAmount = bal.add(diff);
            }
        }
        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            console.log('currentAmount: ', currentAmount); 
            uint256 currentWithdrawFee = currentAmount.mul(withdrawFee).div(10000);
            token.safeTransfer(treasury, currentWithdrawFee);
            currentAmount = currentAmount.sub(currentWithdrawFee);
            console.log('currentAmount: ', currentAmount); 
        }
        user.lastUserActionTime = block.timestamp;
        token.safeTransfer(msg.sender, currentAmount);
        if (user.shares > 0) {
            user.babyAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        } else {
            user.babyAtLastUserAction = 0;
        }
        emit Withdraw(msg.sender, currentAmount, _shares);
    }

    function withdrawAll() external notContract {
        withdraw(userInfo[msg.sender].shares);
    }

    function harvest()
        external
        notContract
        whenNotPaused
        nonReentrant("harvest")
    {
        pool.leaveStaking(0);
        uint256 bal = available();
        uint256 currentPerformanceFee = bal.mul(performanceFee).div(10000);
        token.safeTransfer(treasury, currentPerformanceFee);
        uint256 currentCallFee = bal.mul(callFee).div(10000);
        token.safeTransfer(msg.sender, currentCallFee);
        _earn();
        lastHarvestedTime = block.timestamp;
        emit Harvest(msg.sender, currentPerformanceFee, currentCallFee);
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyAdmin {
        require(
            _performanceFee <= MAX_PERFORMANCE_FEE,
            "performanceFee cannot be more than MAX_PERFORMANCE_FEE"
        );
        performanceFee = _performanceFee;
    }

    function setCallFee(uint256 _callFee) external onlyAdmin {
        require(
            _callFee <= MAX_CALL_FEE,
            "callFee cannot be more than MAX_CALL_FEE"
        );
        callFee = _callFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) external onlyAdmin {
        require(
            _withdrawFee <= MAX_WITHDRAW_FEE,
            "withdrawFee cannot be more than MAX_WITHDRAW_FEE"
        );
        withdrawFee = _withdrawFee;
    }

    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod)
        external
        onlyAdmin
    {
        require(
            _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
            "withdrawFeePeriod cannot be more than MAX_WITHDRAW_FEE_PERIOD"
        );
        withdrawFeePeriod = _withdrawFeePeriod;
    }

    function emergencyWithdraw() external onlyAdmin {
        pool.emergencyWithdraw();
    }

    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(
            _token != address(token),
            "Token cannot be same as deposit token"
        );
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function pause() external onlyAdmin whenNotPaused {
        _pause();
        emit Pause();
    }

    function unpause() external onlyAdmin whenPaused {
        _unpause();
        emit Unpause();
    }

    function calculateHarvestBabyRewards() external view returns (uint256) {
        uint256 amount = pool.pendingReward(address(this));
        amount = amount.add(available());
        uint256 currentCallFee = amount.mul(callFee).div(10000);
        return currentCallFee;
    }

    function calculateTotalPendingBabyRewards()
        external
        view
        returns (uint256)
    {
        uint256 amount = pool.pendingReward(address(this));
        amount = amount.add(available());
        return amount;
    }

    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : balanceOf().mul(1e18).div(totalShares);
    }
}