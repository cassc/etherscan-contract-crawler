// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/IExtraReward.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IGauge.sol";
import "./BaseGauge.sol";
import "./interfaces/IVotingYFI.sol";
import "./interfaces/IDYfiRewardPool.sol";

/** @title  Gauge stake vault token get YFI rewards
    @notice Deposit your vault token (one gauge per vault).
    YFI are paid based on the number of vault tokens, the veYFI balance, and the duration of the lock.
    @dev this contract is used behind multiple delegate proxies.
 */

contract Gauge is BaseGauge, ERC20Upgradeable, IGauge {
    using SafeERC20 for IERC20;

    struct Balance {
        uint256 realBalance;
        uint256 boostedBalance;
    }

    struct Approved {
        bool claim;
        bool lock;
    }

    uint256 public constant BOOSTING_FACTOR = 1;
    uint256 public constant BOOST_DENOMINATOR = 10;

    IERC20 public asset;
    //// @notice veYFI
    address public immutable VEYFI;
    //// @notice the veYFI YFI reward pool, penalty are sent to this contract.
    address public immutable VE_YFI_POOL;
    //// @notice a copy of the veYFI max lock duration
    uint256 public constant PRECISION_FACTOR = 10 ** 18;
    //// @notice Penalty does not apply for locks expiring after 3y11m

    mapping(address => uint256) private _boostedBalances;
    mapping(address => address) public recipients;

    event TransferredPenalty(address indexed account, uint256 transfered);
    event BoostedBalanceUpdated(address account, uint256 amount);

    event Initialize(address indexed asset, address indexed owner);

    event RecipientUpdated(address indexed account, address indexed recipient);

    constructor(
        address _veYfi,
        address _dYfi,
        address _veYfiDYfiPool
    ) BaseGauge(_dYfi) {
        require(_veYfi != address(0x0), "_asset 0x0 address");
        require(_veYfiDYfiPool != address(0x0), "_asset 0x0 address");

        VEYFI = _veYfi;
        VE_YFI_POOL = _veYfiDYfiPool;
    }

    /** @notice initialize the contract
     *  @dev Initialize called after contract is cloned.
     *  @param _asset The vault token to stake
     *  @param _owner owner address
     */
    function initialize(address _asset, address _owner) external initializer {
        __initialize(_owner);
        asset = IERC20(_asset);
        __ERC20_init(
            string.concat("yGauge ", IERC20Metadata(_asset).name()),
            string.concat("yG-", IERC20Metadata(_asset).symbol())
        );
        emit Initialize(_asset, _owner);
    }

    /** @return total of the staked vault token
     */
    function totalAssets() public view returns (uint256) {
        return totalSupply();
    }

    /**
        The amount of shares that the Vault would exchange for the amount of assets provided.
    */
    function convertToShares(uint256 _assets) public view returns (uint256) {
        return _assets;
    }

    /**
        The amount of assets that the Vault would exchange for the amount of shares provided.
    */
    function convertToAssets(uint256 _shares) public view returns (uint256) {
        return _shares;
    }

    /**
    Maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call.
    */
    function maxDeposit(address) public view returns (uint256) {
        return type(uint256).max;
    }

    /**
    Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
    */
    function previewDeposit(uint256 _assets) public view returns (uint256) {
        return _assets;
    }

    /**
    Maximum amount of shares that can be minted from the Vault for the receiver, through a mint call.
    */
    function maxMint(address) public view returns (uint256) {
        return type(uint256).max;
    }

    /**
    Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
    */
    function previewMint(uint256 _shares) public view returns (uint256) {
        return _shares;
    }

    /** @param _account to look balance for
     *  @return amount of staked token for an account
     */
    function boostedBalanceOf(
        address _account
    ) external view returns (uint256) {
        return _boostedBalances[_account];
    }

    /** @notice
     *   Performs a snapshot of the account's accrued rewards since the previous update.
     *  @dev
     *   The snapshot made by this function depends on:
     *    1. The account's boosted balance
     *    2. The amount of reward emissions that have been added to the gauge since the
     *       account's rewards were last updated.
     *   Any function that mutates an account's balance, boostedBalance, userRewardPerTokenPaid,
     *   or rewards MUST call updateReward before performing the mutation.
     */
    function _updateReward(address _account) internal override {
        rewardPerTokenStored = _rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            if (_boostedBalances[_account] != 0) {
                uint256 newEarning = _newEarning(_account);
                uint256 maxEarning = _maxEarning(_account);

                rewards[_account] += newEarning;
                uint256 penalty = maxEarning - newEarning;
                _transferVeYfiORewards(penalty);
                emit TransferredPenalty(_account, penalty);
            }
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
            emit UpdatedRewards(
                _account,
                rewardPerTokenStored,
                lastUpdateTime,
                rewards[_account],
                userRewardPerTokenPaid[_account]
            );
        }
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256
    ) internal override {
        if (_from != address(0)) {
            _updateReward(_from);
        }
        if (_to != address(0)) {
            _updateReward(_to);
        }
    }

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256
    ) internal override {
        if (_from != address(0)) {
            _boostedBalances[_from] = _boostedBalanceOf(_from);
            emit BoostedBalanceUpdated(_from, _boostedBalances[_from]);
        }
        if (_to != address(0)) {
            _boostedBalances[_to] = _boostedBalanceOf(_to);
            emit BoostedBalanceUpdated(_to, _boostedBalances[_to]);
        }
    }

    function _rewardPerToken() internal view override returns (uint256) {
        if (totalAssets() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                PRECISION_FACTOR) / totalAssets());
    }

    /** @notice The total undistributed earnings for an account.
     *  @dev Earnings are based on lock duration and boost
     *  @return
     *   Amount of tokens the account has earned that have yet to be distributed.
     */
    function earned(
        address _account
    ) external view override(BaseGauge, IBaseGauge) returns (uint256) {
        uint256 newEarning = _newEarning(_account);

        return newEarning + rewards[_account];
    }

    /** @notice Calculates an account's earnings based on their boostedBalance.
     *   This function only reflects the accounts earnings since the last time
     *   the account's rewards were calculated via _updateReward.
     */
    function _newEarning(
        address _account
    ) internal view override returns (uint256) {
        return
            (_boostedBalances[_account] *
                (_rewardPerToken() - userRewardPerTokenPaid[_account])) /
            PRECISION_FACTOR;
    }

    /** @notice Calculates an account's potential maximum earnings based on
     *   a maximum boost.
     *   This function only reflects the accounts earnings since the last time
     *   the account's rewards were calculated via _updateReward.
     */
    function _maxEarning(address _account) internal view returns (uint256) {
        return
            (balanceOf(_account) *
                (_rewardPerToken() - userRewardPerTokenPaid[_account])) /
            PRECISION_FACTOR;
    }

    /** @notice
     *   Calculates the boosted balance of based on veYFI balance.
     *  @dev
     *   This function expects this._totalAssets to be up to date.
     *  @return
     *   The account's boosted balance. Always lower than or equal to the
     *   account's real balance.
     */
    function nextBoostedBalanceOf(
        address _account
    ) external view returns (uint256) {
        return _boostedBalanceOf(_account);
    }

    /** @notice
     *   Calculates the boosted balance of based on veYFI balance.
     *  @dev
     *    This function expects the account's _balances[_account].realBalance
     *    to be up to date.
     *  @dev This function expects this._totalAssets to be up to date.
     *  @return
     *   The account's boosted balance. Always lower than or equal to the
     *   account's real balance.
     */
    function _boostedBalanceOf(
        address _account
    ) internal view returns (uint256) {
        return _boostedBalanceOf(_account, balanceOf(_account));
    }

    /** @notice
     *   Calculates the boosted balance of an account based on its gauge stake
     *   proportion & veYFI lock proportion.
     *  @dev This function expects this._totalAssets to be up to date.
     *  @param _account The account whose veYFI lock should be checked.
     *  @param _realBalance The amount of token _account has locked in the gauge.
     *  @return
     *   The account's boosted balance. Always lower than or equal to the
     *   account's real balance.
     */
    function _boostedBalanceOf(
        address _account,
        uint256 _realBalance
    ) internal view returns (uint256) {
        uint256 veTotalSupply = IVotingYFI(VEYFI).totalSupply();
        if (veTotalSupply == 0) {
            return _realBalance;
        }
        return
            Math.min(
                ((_realBalance * BOOSTING_FACTOR) +
                    (((totalSupply() * IVotingYFI(VEYFI).balanceOf(_account)) /
                        veTotalSupply) *
                        (BOOST_DENOMINATOR - BOOSTING_FACTOR))) /
                    BOOST_DENOMINATOR,
                _realBalance
            );
    }

    /** @notice deposit vault tokens into the gauge
     *  @dev a user without a veYFI should not lock.
     *  @dev will deposit the min between user balance and user approval
     *  @dev This call updates claimable rewards
     *  @return amount of assets deposited
     */
    function deposit() external returns (uint256) {
        uint256 balance = Math.min(
            asset.balanceOf(msg.sender),
            asset.allowance(msg.sender, address(this))
        );
        _deposit(balance, msg.sender);
        return balance;
    }

    /** @notice deposit vault tokens into the gauge
     *  @dev a user without a veYFI should not lock.
     *  @dev This call updates claimable rewards
     *  @param _assets of vault token
     *  @return amount  of assets deposited
     */
    function deposit(uint256 _assets) external returns (uint256) {
        _deposit(_assets, msg.sender);
        return _assets;
    }

    /** @notice deposit vault tokens into the gauge for a user
     *   @dev vault token is taken from msg.sender
     *   @dev This call update  `_for` claimable rewards
     *   @param _assets to deposit
     *   @param _receiver the account to deposit to
     *   @return true
     */
    function deposit(
        uint256 _assets,
        address _receiver
    ) external returns (uint256) {
        _deposit(_assets, _receiver);
        return _assets;
    }

    /** @notice deposit vault tokens into the gauge for a user
     *   @dev vault token is taken from msg.sender
     *   @dev This call update  `_for` claimable rewards
     *   @dev shares and
     *   @param _shares to deposit
     *   @param _receiver the account to deposit to
     *   @return amount of shares transfered
     */
    function mint(
        uint256 _shares,
        address _receiver
    ) external returns (uint256) {
        _deposit(_shares, _receiver);
        return _shares;
    }

    function _deposit(uint256 _assets, address _receiver) internal {
        require(_assets != 0, "RewardPool : Cannot deposit 0");

        //take away from sender
        asset.safeTransferFrom(msg.sender, address(this), _assets);

        // mint shares
        _mint(_receiver, _assets);

        emit Deposit(msg.sender, _receiver, _assets, _assets);
    }

    /**
      Maximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault, through a withdraw call.
    */
    function maxWithdraw(address _owner) external view returns (uint256) {
        return balanceOf(_owner);
    }

    function previewWithdraw(uint256 _assets) external view returns (uint256) {
        return _assets;
    }

    /** @notice Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *  @dev This call updates claimable rewards
     *  @param _assets amount to withdraw
     *  @param _receiver account that will recieve the shares
     *  @param _owner shares will be taken from account
     *  @param _claim claim veYFI and additional reward
     *  @return amount of shares withdrawn
     */
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        bool _claim
    ) external returns (uint256) {
        return _withdraw(_assets, _receiver, _owner, _claim);
    }

    /** @notice Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *  @dev This call updates claimable rewards
     *  @param _assets amount to withdraw
     *  @param _receiver account that will recieve the shares
     *  @param _owner shares will be taken from account
     *  @return amount of shares withdrawn
     */
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256) {
        return _withdraw(_assets, _receiver, _owner, false);
    }

    /** @notice withdraw all vault tokens from gauge
     *   @dev This call updates claimable rewards
     *   @param _claim claim veYFI and additional reward
     *  @return amount of shares withdrawn
     */
    function withdraw(bool _claim) external returns (uint256) {
        return _withdraw(balanceOf(msg.sender), msg.sender, msg.sender, _claim);
    }

    /** @notice withdraw all vault token from gauge
     *  @dev This call update claimable rewards
     *  @return amount of shares withdrawn
     */
    function withdraw() external returns (uint256) {
        return _withdraw(balanceOf(msg.sender), msg.sender, msg.sender, false);
    }

    function _withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        bool _claim
    ) internal returns (uint256) {
        require(_assets != 0, "RewardPool : Cannot withdraw 0");

        if (msg.sender != _owner) {
            _spendAllowance(_owner, msg.sender, _assets);
        }

        _burn(_owner, _assets);

        if (_claim) {
            _getReward(_owner);
        }

        asset.safeTransfer(_receiver, _assets);
        emit Withdraw(msg.sender, _receiver, _owner, _assets, _assets);

        return _assets;
    }

    function maxRedeem(address _owner) external view returns (uint256) {
        return balanceOf(_owner);
    }

    function previewRedeem(uint256 _assets) external view returns (uint256) {
        return _assets;
    }

    /** @notice Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *  @dev This call updates claimable rewards
     *  @param _assets amount to withdraw
     *  @param _receiver account that will recieve the shares
     *  @param _owner shares will be taken from account
     *  @return amount of shares withdrawn
     */
    function redeem(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external override returns (uint256) {
        return _withdraw(_assets, _receiver, _owner, true);
    }

    /**
     * @notice
     *  Get rewards
     * @return true
     */
    function getReward() external updateReward(msg.sender) returns (bool) {
        _getReward(msg.sender);
        return true;
    }

    /**
     * @notice
     *  Get rewards for an account
     * @dev rewards are transferred to _account
     * @param _account to claim rewards for
     * @return true
     */
    function getReward(
        address _account
    ) external updateReward(_account) returns (bool) {
        _getReward(_account);

        return true;
    }

    /** @notice Distributes the rewards for the specified account.
     *  @dev
     *   This function MUST NOT be called without the caller invoking
     *   updateReward(_account) first.
     */
    function _getReward(address _account) internal {
        uint256 boostedBalance = _boostedBalanceOf(_account);
        _boostedBalances[_account] = boostedBalance;
        emit BoostedBalanceUpdated(_account, boostedBalance);

        uint256 reward = rewards[_account];
        if (reward != 0) {
            rewards[_account] = 0;
            address recipient = recipients[_account];
            if (recipient != address(0x0)) {
                REWARD_TOKEN.safeTransfer(recipient, reward);
            } else {
                REWARD_TOKEN.safeTransfer(_account, reward);
            }
            emit RewardPaid(_account, reward);
        }
    }

    function _transferVeYfiORewards(uint256 _penalty) internal {
        IERC20(REWARD_TOKEN).approve(VE_YFI_POOL, _penalty);
        IDYfiRewardPool(VE_YFI_POOL).burn(_penalty);
    }

    function _protectedTokens(
        address _token
    ) internal view override returns (bool) {
        return _token == address(REWARD_TOKEN) || _token == address(asset);
    }

    /**
    @notice Kick `addr` for abusing their boost
    @param _accounts Addresses to kick
    */
    function kick(address[] calldata _accounts) public {
        for (uint256 i = 0; i < _accounts.length; ++i) {
            _kick(_accounts[i]);
        }
    }

    function _kick(address _account) internal updateReward(_account) {
        uint256 balance = balanceOf(_account);
        uint256 boostedBalance = _boostedBalanceOf(_account, balance);
        _boostedBalances[_account] = boostedBalance;
        emit BoostedBalanceUpdated(_account, boostedBalance);
    }

    /**
    @notice Set the recipient of rewards for an account
    @param _recipient Address to send rewards to
    */
    function setRecipient(address _recipient) external {
        recipients[msg.sender] = _recipient;
        emit RecipientUpdated(msg.sender, _recipient);
    }
}