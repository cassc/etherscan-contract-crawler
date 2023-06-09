// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../Interfaces/IPendleDepositor.sol";
import "../Interfaces/IVlEqb.sol";

contract PendleCampaign is AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    address public pendle;
    address public eqb;
    address public ePendle;
    address public pendleDepositor;
    address public vlEqb;
    address public treasury;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public penalty;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalReward;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    bool public isShutdown;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SHUTDOWN_ROLE = keccak256("SHUTDOWN_ROLE");

    event RewardRatedUpdated(uint256 _rewardRate);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(
        address indexed _user,
        uint256 _reward,
        bool _lock,
        uint256 _lockWeeks
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function setParams(
        address _pendle,
        address _treasury,
        uint256 _penalty,
        uint256 _rewardRate
    ) external onlyRole(ADMIN_ROLE) {
        require(pendle == address(0), "params have already been set");

        require(_pendle != address(0), "invalid _pendle!");
        require(_treasury != address(0), "invalid _treasury!");
        require(_penalty > 0, "invalid _penalty!");
        require(_penalty < DENOMINATOR, "invalid _penalty!");

        pendle = _pendle;
        treasury = _treasury;

        penalty = _penalty;
        rewardRate = _rewardRate;

        lastUpdateTime = block.timestamp;

        emit RewardRatedUpdated(_rewardRate);
    }

    function setRewardRate(
        uint256 _rewardRate
    ) external onlyRole(ADMIN_ROLE) updateReward(address(0)) {
        rewardRate = _rewardRate;

        emit RewardRatedUpdated(_rewardRate);
    }

    function setEqbAddresses(
        address _eqb,
        address _ePendle,
        address _pendleDepositor,
        address _vlEqb
    ) external onlyRole(ADMIN_ROLE) {
        require(eqb == address(0), "params have already been set");

        require(_eqb != address(0), "invalid _eqb!");
        require(_ePendle != address(0), "invalid _ePendle!");
        require(_pendleDepositor != address(0), "invalid _pendleDepositor!");
        require(_vlEqb != address(0), "invalid _vlEqb!");

        eqb = _eqb;
        ePendle = _ePendle;
        pendleDepositor = _pendleDepositor;
        vlEqb = _vlEqb;
    }

    function end() external onlyRole(ADMIN_ROLE) updateReward(address(0)) {
        require(periodFinish == 0, "already ended");
        require(eqb != address(0), "eqb addresses have not been set");
        require(!isShutdown, "already shutdown");

        periodFinish = block.timestamp;

        IERC20(eqb).safeTransferFrom(msg.sender, address(this), totalReward);

        _approveTokenIfNeeded(pendle, pendleDepositor, _totalSupply);
        IPendleDepositor(pendleDepositor).deposit(_totalSupply, false);
    }

    function emergencyShutdown() external onlyRole(SHUTDOWN_ROLE) {
        require(!isShutdown, "already shutdown");
        require(periodFinish == 0, "campaign has ended");

        isShutdown = true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    modifier updateReward(address _user) {
        uint256 newRewardPerToken = rewardPerToken();
        totalReward +=
            ((newRewardPerToken - rewardPerTokenStored) * totalSupply()) /
            1e18;
        rewardPerTokenStored = newRewardPerToken;
        lastUpdateTime = lastTimeRewardApplicable();

        if (_user != address(0)) {
            rewards[_user] = earned(_user);
            userRewardPerTokenPaid[_user] = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        if (periodFinish == 0) {
            return block.timestamp;
        } else {
            return Math.min(block.timestamp, periodFinish);
        }
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / totalSupply());
    }

    function earned(address _user) public view returns (uint256) {
        return
            ((balanceOf(_user) *
                (rewardPerToken() - userRewardPerTokenPaid[_user])) / 1e18) +
            rewards[_user];
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        require(periodFinish == 0, "campaign has ended");

        _totalSupply = _totalSupply + _amount;
        _balances[msg.sender] = _balances[msg.sender] + _amount;

        IERC20(pendle).safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw() external updateReward(msg.sender) {
        require(isShutdown, "campaign must be shutdown");

        uint256 amount = balanceOf(msg.sender);
        require(amount > 0, "no balance to withdraw");

        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = 0;

        IERC20(pendle).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claim(
        bool _lock,
        uint256 _lockWeeks
    ) public updateReward(msg.sender) {
        require(periodFinish > 0, "campaign is still running");
        require(
            !_lock || (_lockWeeks >= 24 && _lockWeeks <= 52),
            "invalid lock weeks"
        );

        uint256 amount = balanceOf(msg.sender);
        require(amount > 0, "no balance to claim");

        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = 0;

        IERC20(ePendle).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);

        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            if (_lock) {
                _approveTokenIfNeeded(eqb, vlEqb, reward);
                IVlEqb(vlEqb).lock(msg.sender, reward, _lockWeeks);
            } else {
                uint256 penaltyAmount = (reward * penalty) / DENOMINATOR;
                IERC20(eqb).safeTransfer(treasury, penaltyAmount);
                IERC20(eqb).safeTransfer(msg.sender, reward - penaltyAmount);
            }
            emit RewardPaid(msg.sender, reward, _lock, _lockWeeks);
        }
    }

    function _approveTokenIfNeeded(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            IERC20(_token).safeApprove(_to, 0);
            IERC20(_token).safeApprove(_to, type(uint256).max);
        }
    }
}