pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./utils/ERC20Vault.sol";

import "../../interfaces/vault/IVaultCore.sol";
import "../../interfaces/vault/IVaultTransfers.sol";
import "../../interfaces/IController.sol";
import "../../interfaces/IStrategy.sol";

/// @title EURxbVault
/// @notice Base vault contract, used to manage funds of the clients
abstract contract BaseVaultV2 is
    IVaultCore,
    IVaultTransfers,
    ERC20Vault,
    Ownable,
    ReentrancyGuard,
    Pausable,
    Initializable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Controller instance, to simplify controller-related actions
    IController internal _controller;

    IERC20 public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;

    address public rewardsDistribution;

    // token => reward per token stored
    mapping(address => uint256) public rewardsPerTokensStored;

    // reward token => reward rate
    mapping(address => uint256) public rewardRates;

    // valid token => user => amount
    mapping(address => mapping(address => uint256))
    public userRewardPerTokenPaid;

    // user => valid token => amount
    mapping(address => mapping(address => uint256)) public rewards;

    EnumerableSet.AddressSet internal _validTokens;

    address public trustworthyEarnCaller;

    /* ========== EVENTS ========== */

    event RewardAdded(address what, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address what, address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);

    constructor(string memory _name, string memory _symbol)
        public
        ERC20Vault(_name, _symbol)
    {
        trustworthyEarnCaller = _msgSender();
    }

    /// @notice Default initialize method for solving migration linearization problem
    /// @dev Called once only by deployer
    /// @param _initialToken Business token logic address
    /// @param _initialController Controller instance address
    function _configure(
        address _initialToken,
        address _initialController,
        address _governance,
        uint256 _rewardsDuration,
        address[] memory _rewardsTokens,
        string memory _namePostfix,
        string memory _symbolPostfix
    ) internal {
        setController(_initialController);
        transferOwnership(_governance);
        stakingToken = IERC20(_initialToken);
        rewardsDuration = _rewardsDuration;
        _name = string(abi.encodePacked(_name, _namePostfix));
        _symbol = string(abi.encodePacked(_symbol, _symbolPostfix));
        for (uint256 i = 0; i < _rewardsTokens.length; i++) {
            _validTokens.add(_rewardsTokens[i]);
        }
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _updateAllRewards(sender);
        _updateAllRewards(recipient);
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }


    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        address sender = _msgSender();
        _updateAllRewards(sender);
        _updateAllRewards(recipient);
        _transfer(sender, recipient, amount);
        return true;
    }

    function setTrustworthyEarnCaller(address _who) external onlyOwner {
        trustworthyEarnCaller = _who;
    }

    /// @notice Usual setter with check if passet param is new
    /// @param _newController New value
    function setController(address _newController) public onlyOwner {
        require(address(_controller) != _newController, "!new");
        _controller = IController(_newController);
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish, "!periodFinish");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function addRewardToken(address _rewardToken) external onlyOwner {
        require(_validTokens.add(_rewardToken), "!add");
    }

    function removeRewardToken(address _rewardToken) external onlyOwner {
        require(_validTokens.remove(_rewardToken), "!remove");
    }

    function isTokenValid(address _rewardToken) external view returns (bool) {
        return _validTokens.contains(_rewardToken);
    }

    function getRewardToken(uint256 _index) external view returns (address) {
        return _validTokens.at(_index);
    }

    function getRewardTokensCount() external view returns (uint256) {
        return _validTokens.length();
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken(address _rewardToken)
        public
        view
        onlyValidToken(_rewardToken)
        returns (uint256)
    {
        if (_totalSupply == 0) {
            return rewardsPerTokensStored[_rewardToken];
        }
        return
        rewardsPerTokensStored[_rewardToken].add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRates[_rewardToken])
            .mul(1e18)
            .div(_totalSupply)
        );
    }

    function earned(address _rewardToken, address _account)
        public
        view
        virtual
        onlyValidToken(_rewardToken)
        returns (uint256)
    {
        return
        _balances[_account]
        .mul(
            rewardPerToken(_rewardToken).sub(
                userRewardPerTokenPaid[_rewardToken][_account]
            )
        )
        .div(1e18)
        .add(rewards[_account][_rewardToken]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _deposit(address _from, uint256 _amount)
        internal
        virtual
        returns (uint256)
    {
        require(_amount > 0, "Cannot stake 0");
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(_from, _amount);
        emit Staked(_from, _amount);
        return _amount;
    }

    function deposit(uint256 amount)
        public
        override
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        _deposit(msg.sender, amount);
    }

    function depositFor(uint256 _amount, address _for)
        public
        override
        nonReentrant
        whenNotPaused
        updateReward(_for)
    {
        _deposit(_for, _amount);
    }

    function depositAll()
        public
        override
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        uint256 _balance = stakingToken.balanceOf(msg.sender);
        require(_balance > 0, "0balance");
        _deposit(msg.sender, _balance);
    }

    function _withdrawFrom(address _from, uint256 _amount)
        internal
        virtual
        returns (uint256)
    {
        require(_amount > 0, "Cannot withdraw 0");
        _burn(msg.sender, _amount);
        address strategyAddress = IController(_controller).strategies(
            address(stakingToken)
        );
        uint256 amountOnVault = stakingToken.balanceOf(address(this));
        if (amountOnVault < _amount) {
            IStrategy(strategyAddress).withdraw(_amount.sub(amountOnVault));
        }
        stakingToken.safeTransfer(_from, _amount);
        emit Withdrawn(_from, _amount);
        return _amount;
    }

    function _withdraw(uint256 _amount) internal returns (uint256) {
        return _withdrawFrom(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public virtual override {
        withdraw(_amount, true);
    }

    function withdrawAll() public virtual override {
        withdraw(_balances[msg.sender], true);
    }

    function withdraw(uint256 _amount, bool _claimUnderlying)
        public
        virtual
        nonReentrant
        updateReward(msg.sender)
    {
        _getRewardAll(_claimUnderlying);
        _withdraw(_amount);
    }

    function _getReward(
        bool _claimUnderlying,
        address _for,
        address _rewardToken,
        address _stakingToken
    ) internal virtual {
        if (_claimUnderlying) {
            _controller.getRewardStrategy(_stakingToken);
        }
        _controller.claim(_stakingToken, _rewardToken);

        uint256 reward = rewards[_for][_rewardToken];
        if (reward > 0) {
            rewards[_for][_rewardToken] = 0;
            IERC20(_rewardToken).safeTransfer(_for, reward);
        }
        emit RewardPaid(_rewardToken, _for, reward);
    }

    function _getRewardAll(bool _claimUnderlying) internal virtual {
        for (uint256 i = 0; i < _validTokens.length(); i++) {
            _getReward(
                _claimUnderlying,
                msg.sender,
                _validTokens.at(i),
                address(stakingToken)
            );
        }
    }

    function getReward(bool _claimUnderlying)
        public
        virtual
        nonReentrant
        updateReward(msg.sender)
    {
        _getRewardAll(_claimUnderlying);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(address _rewardToken, uint256 _reward)
        external
        virtual
        onlyRewardsDistribution
        onlyValidToken(_rewardToken)
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRates[_rewardToken] = _reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRates[_rewardToken]);
            rewardRates[_rewardToken] = _reward.add(leftover).div(
                rewardsDuration
            );
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(_rewardToken).balanceOf(address(this));
        require(
            rewardRates[_rewardToken] <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(_rewardToken, _reward);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyValidToken(address _rewardToken) {
        require(_validTokens.contains(_rewardToken), "!valid");
        _;
    }

    function userReward(address _account, address _token)
        external
        view
        onlyValidToken(_token)
        returns (uint256)
    {
        return rewards[_account][_token];
    }

    function _updateReward(address _what, address _account) internal virtual {
        rewardsPerTokensStored[_what] = rewardPerToken(_what);
        if (_account != address(0)) {
            rewards[_account][_what] = earned(_what, _account);
            userRewardPerTokenPaid[_what][_account] = rewardsPerTokensStored[
            _what
            ];
        }
    }

    function _updateAllRewards(address _account) internal virtual {
        for (uint256 i = 0; i < _validTokens.length(); i++) {
            _updateReward(_validTokens.at(i), _account);
        }
        lastUpdateTime = lastTimeRewardApplicable();
    }

    modifier updateReward(address _account) {
        _updateAllRewards(_account);
        _;
    }

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    /// @notice Transfer tokens to controller, controller transfers it to strategy and earn (farm)
    function earn() external virtual override {
        require(_msgSender() == trustworthyEarnCaller, "!trustworthyEarnCaller");
        uint256 _bal = stakingToken.balanceOf(address(this));
        stakingToken.safeTransfer(address(_controller), _bal);
        _controller.earn(address(stakingToken), _bal);
        for (uint256 i = 0; i < _validTokens.length(); i++) {
            _controller.claim(address(stakingToken), _validTokens.at(i));
        }
    }

    function token() external view override returns (address) {
        return address(stakingToken);
    }

    function controller() external view override returns (address) {
        return address(_controller);
    }

    function balance() public view override returns (uint256) {
        IStrategy strategy = IStrategy(
            _controller.strategies(address(stakingToken))
        );
        return stakingToken.balanceOf(address(this)).add(strategy.balanceOf());
    }

    function _rewardPerTokenForDuration(
        address _rewardsToken,
        uint256 _duration
    ) internal view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardsPerTokensStored[_rewardsToken];
        }
        return
        rewardsPerTokensStored[_rewardsToken].add(
            _duration.mul(rewardRates[_rewardsToken]).mul(1e18).div(
                _totalSupply
            )
        );
    }

    function potentialRewardReturns(
        address _rewardsToken,
        uint256 _duration,
        address _account
    ) external view returns (uint256) {
        uint256 _rewardsAmount = _balances[_account]
        .mul(
            _rewardPerTokenForDuration(_rewardsToken, _duration).sub(
                userRewardPerTokenPaid[_rewardsToken][msg.sender]
            )
        )
        .div(1e18)
        .add(rewards[_account][_rewardsToken]);
        return _rewardsAmount;
    }
}