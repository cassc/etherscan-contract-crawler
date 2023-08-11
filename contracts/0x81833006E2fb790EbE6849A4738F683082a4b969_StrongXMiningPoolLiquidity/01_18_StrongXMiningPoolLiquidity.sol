// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IStrongX.sol";

contract StrongXMiningPoolLiquidity is ReentrancyGuard, AccessControl, Pausable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // STATE VARIABLES

    IStrongX public rewardsToken;
    IERC20 public stakingToken;
    uint public aprRate;
    uint public lastRewardsTimestamp;
    bool public rewardsDisabled;

    address private immutable admin;
    address private immutable pair;
    address private immutable WETH;
    uint private _totalSupply;

    mapping(address => uint) private _balances;
    mapping(address => uint) private _timestamps;
    mapping(address => uint) private _rewards;

    // CONSTRUCTOR

    constructor (
        address _rewardsToken,
        address _stakingToken,
        uint _aprRate
    ) {
        rewardsToken = IStrongX(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        aprRate = _aprRate;

        admin = _msgSender();
        pair = rewardsToken.uniswapV2Pair();
        WETH = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).WETH();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    // VIEWS

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function balanceOfInTokens(address account) public view returns (uint) {
        uint tokenBalance = rewardsToken.balanceOf(pair);
        uint lpBalance = IERC20(pair).totalSupply();
        uint tokensPerLp = tokenBalance.mul(1e18).div(lpBalance);
        return tokensPerLp
            .mul(2)
            .mul(_balances[account])
            .div(1e18);
    }

    function earned(address account) public view returns (uint) {
        return 
            _rewards[account]
                .add(_getUnclaimedRewards(account));
    }

    function getRewardRate(address account) public view returns (uint) {
        return 
            balanceOfInTokens(account)
                .mul(aprRate)
                .div(1000)
                .div(365 days);
    }

    function min(uint a, uint b) public pure returns (uint) {
        return a < b ? a : b;
    }

    // PUBLIC FUNCTIONS

    function stake(address account, uint amount, bool isCompound)
        external
        nonReentrant
        whenNotPaused
        onlyRole(MANAGER_ROLE)
    {
        require(amount > 0, "Cannot stake 0");

        uint balBefore = stakingToken.balanceOf(address(this));
        if (isCompound) stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
        else stakingToken.safeTransferFrom(account, address(this), amount);
        uint balAfter = stakingToken.balanceOf(address(this));
        uint actualReceived = balAfter.sub(balBefore);

        _claimPendingRewards(account);
        _totalSupply = _totalSupply.add(actualReceived);
        _balances[account] = _balances[account].add(actualReceived);
        
        emit Staked(account, actualReceived);
    }

    function withdraw(address account, uint amount)
        public
        nonReentrant
        onlyRole(MANAGER_ROLE)
    {
        require(amount > 0, "Cannot withdraw 0");

        _claimPendingRewards(account);
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        stakingToken.safeTransfer(account, amount);

        emit Withdrawn(account, amount);
    }

    function claim(address account, bool compound) 
        public 
        nonReentrant
        onlyRole(MANAGER_ROLE) 
    {
        uint rewards = earned(account);
        if (rewards > 0) {
            _rewards[account] = 0;
            _timestamps[account] = block.timestamp;

            if (compound) rewardsToken.mint(_msgSender(), rewards);
            else rewardsToken.mint(account, rewards);
            emit RewardPaid(account, rewards);
        }
    }

    // INTERNAL FUNCTIONS

    function _claimPendingRewards(address account) internal {
        _rewards[account] = _rewards[account].add(_getUnclaimedRewards(account));
        _timestamps[account] = block.timestamp;
    }

    function _getUnclaimedRewards(address account) internal view returns (uint) {
        uint lastApplicableTimestamp = block.timestamp;
        if (lastRewardsTimestamp != 0 && block.timestamp > lastRewardsTimestamp)
            lastApplicableTimestamp = lastRewardsTimestamp;

        if (_timestamps[account] > lastApplicableTimestamp) {
            return 0;
        } else {
            return
                getRewardRate(account)
                    .mul(lastApplicableTimestamp.sub(_timestamps[account]));
        }
    }

    // RESTRICTED FUNCTIONS

    function recoverTokens(address tokenAddress, uint tokenAmount)
        external
        onlyRole(MANAGER_ROLE)
    {
        // Cannot recover the staking token or the rewards token
        require(
            tokenAddress != address(stakingToken) &&
                tokenAddress != address(rewardsToken),
            "Cannot withdraw the staking or rewards tokens"
        );
        IERC20(tokenAddress).safeTransfer(admin, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function enableDeposits()
        external
        onlyRole(MANAGER_ROLE)
    {
        _unpause();
    }

    function disableDeposits()
        external
        onlyRole(MANAGER_ROLE)
    {
        _pause();
    }

    function disableRewards()
        external
        onlyRole(MANAGER_ROLE)
    {
        require(!rewardsDisabled, "Rewards are already disabled");
        rewardsDisabled = true;
        lastRewardsTimestamp = block.timestamp;
    }

    function setAprRate(uint _aprRate)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(_aprRate > 0, "APR rate must be more than zero");
        aprRate = _aprRate;
    }

    // EVENTS

    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);
    event Recovered(address token, uint amount);
}