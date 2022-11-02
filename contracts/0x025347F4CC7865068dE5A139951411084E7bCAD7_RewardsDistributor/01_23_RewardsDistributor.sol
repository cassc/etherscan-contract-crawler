// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/utils/math/SafeCast.sol";
import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./interfaces/IDebtToken.sol";
import "./interfaces/IDepositToken.sol";
import "./access/Manageable.sol";
import "./storage/RewardsDistributorStorage.sol";
import "./lib/WadRayMath.sol";

/**
 * @title RewardsDistributor contract
 */
contract RewardsDistributor is ReentrancyGuard, Manageable, RewardsDistributorStorageV1 {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using WadRayMath for uint256;

    /// @notice The initial index
    uint224 public constant INITIAL_INDEX = 1e18;

    /// @notice Max reward tokens to avoid DoS scenario
    uint224 public constant MAX_REWARD_TOKENS = 20;

    /// @notice Emitted when reward is claimed
    event RewardClaimed(address account, uint256 amount);

    /// @notice Emitted when updating accrued token
    event TokensAccruedUpdated(IERC20 indexed token, address indexed account, uint256 tokensDelta, uint256 supplyIndex);

    /// @notice Emitted when updating token speed
    event TokenSpeedUpdated(IERC20 indexed token, uint256 oldSpeed, uint256 newSpeed);

    /**
     * @dev Throws if this contract isn't registered on pool
     */
    modifier onlyIfDistributorExists() {
        bool _distributorAdded = false;
        IRewardsDistributor[] memory _rewardsDistributors = pool.getRewardsDistributors();
        uint256 _length = _rewardsDistributors.length;
        for (uint256 i; i < _length; ++i) {
            if (_rewardsDistributors[i] == this) {
                _distributorAdded = true;
                break;
            }
        }
        require(_distributorAdded, "distributor-not-added");
        _;
    }

    /**
     * @dev Throws if token doesn't exist
     * @dev Should be a DepositToken (suppliers) or DebtToken (borrowers)
     */
    modifier onlyIfTokenExists(address token_) {
        IPool _pool = pool;
        require(
            _pool.isDebtTokenExists(IDebtToken(token_)) || _pool.isDepositTokenExists(IDepositToken(token_)),
            "invalid-token"
        );
        _;
    }

    function initialize(IPool pool_, IERC20 rewardToken_) external initializer {
        require(address(rewardToken_) != address(0), "reward-token-is-null");

        __ReentrancyGuard_init();
        __Manageable_init(pool_);

        rewardToken = rewardToken_;
    }

    /**
     * @notice Claim tokens accrued by account in all tokens
     */
    function claimRewards(address account_) external {
        claimRewards(account_, tokens);
    }

    /**
     * @notice Claim tokens accrued by account in the specified tokens
     */
    function claimRewards(address account_, IERC20[] memory tokens_) public {
        address[] memory _accounts = new address[](1);
        _accounts[0] = account_;
        claimRewards(_accounts, tokens_);
    }

    /**
     * @notice Claim tokens accrued by the accounts in the specified tokens
     */
    function claimRewards(address[] memory accounts_, IERC20[] memory tokens_) public nonReentrant {
        uint256 _accountsLength = accounts_.length;
        uint256 _tokensLength = tokens_.length;
        for (uint256 i; i < _tokensLength; ++i) {
            IERC20 _token = tokens_[i];

            if (tokenStates[_token].index > 0) {
                _updateTokenIndex(_token);
                for (uint256 j; j < _accountsLength; j++) {
                    _updateTokensAccruedOf(_token, accounts_[j]);
                }
            }
        }

        for (uint256 j; j < _accountsLength; j++) {
            address _account = accounts_[j];
            _transferRewardIfEnoughTokens(_account, tokensAccruedOf[_account]);
        }
    }

    /**
     * @notice Update indexes on pre-mint and pre-burn
     * @dev Called by DepositToken and DebtToken contracts
     */
    function updateBeforeMintOrBurn(IERC20 token_, address account_) external {
        if (tokenStates[token_].index > 0) {
            _updateTokenIndex(token_);
            _updateTokensAccruedOf(token_, account_);
        }
    }

    /**
     * @notice Update indexes on pre-transfer
     * @dev Called by DepositToken and DebtToken contracts
     */
    function updateBeforeTransfer(
        IERC20 token_,
        address from_,
        address to_
    ) external {
        if (tokenStates[token_].index > 0) {
            _updateTokenIndex(token_);
            _updateTokensAccruedOf(token_, from_);
            _updateTokensAccruedOf(token_, to_);
        }
    }

    /**
     * @notice Transfer tokens to the user
     * @dev If there is not enough tokens, we do not perform the transfer
     */
    function _transferRewardIfEnoughTokens(address account_, uint256 amount_) private {
        IERC20 _rewardToken = rewardToken;
        uint256 _balance = _rewardToken.balanceOf(address(this));
        if (amount_ > 0 && amount_ <= _balance) {
            tokensAccruedOf[account_] = 0;
            _rewardToken.safeTransfer(account_, amount_);
            emit RewardClaimed(account_, amount_);
        }
    }

    /**
     * @notice Calculate tokens accrued by an account
     */
    function _updateTokensAccruedOf(IERC20 token_, address account_) private {
        uint256 _tokenIndex = tokenStates[token_].index;
        uint256 _accountIndex = accountIndexOf[token_][account_];
        accountIndexOf[token_][account_] = _tokenIndex;

        if (_accountIndex == 0 && _tokenIndex > 0) {
            _accountIndex = INITIAL_INDEX;
        }

        uint256 _deltaIndex = _tokenIndex - _accountIndex;
        uint256 _tokensDelta = token_.balanceOf(account_).wadMul(_deltaIndex);
        tokensAccruedOf[account_] += _tokensDelta;
        emit TokensAccruedUpdated(token_, account_, _tokensDelta, _tokenIndex);
    }

    /**
     * @notice Accrue reward token by updating the index
     */
    function _updateTokenIndex(IERC20 token_) private {
        TokenState storage _supplyState = tokenStates[token_];
        uint256 _speed = tokenSpeeds[token_];
        uint256 _deltaTimestamps = block.timestamp - uint256(_supplyState.timestamp);
        if (_deltaTimestamps > 0 && _speed > 0) {
            uint256 _totalSupply = token_.totalSupply();
            uint256 _tokensAccrued = _deltaTimestamps * _speed;
            uint256 _ratio = _totalSupply > 0 ? _tokensAccrued.wadDiv(_totalSupply) : 0;
            uint256 _newIndex = _supplyState.index + _ratio;
            tokenStates[token_] = TokenState({index: _newIndex.toUint224(), timestamp: block.timestamp.toUint32()});
        } else if (_deltaTimestamps > 0 && _supplyState.index > 0) {
            _supplyState.timestamp = block.timestamp.toUint32();
        }
    }

    /**
     * @notice Update the speed for token
     */
    function _updateTokenSpeed(IERC20 token_, uint256 newSpeed_)
        private
        onlyIfDistributorExists
        onlyIfTokenExists(address(token_))
    {
        uint256 _currentSpeed = tokenSpeeds[token_];
        if (_currentSpeed > 0) {
            _updateTokenIndex(token_);
        } else if (newSpeed_ > 0) {
            // Add token token to the list
            if (tokenStates[token_].index == 0) {
                require(tokens.length < MAX_REWARD_TOKENS, "reached-max-reward-tokens");
                tokenStates[token_] = TokenState({index: INITIAL_INDEX, timestamp: block.timestamp.toUint32()});
                tokens.push(token_);
            } else {
                // Update timestamp to ensure extra interest is not accrued during the prior period
                tokenStates[token_].timestamp = block.timestamp.toUint32();
            }
        }

        if (_currentSpeed != newSpeed_) {
            tokenSpeeds[token_] = newSpeed_;
            emit TokenSpeedUpdated(token_, _currentSpeed, newSpeed_);
        }
    }

    /**
     * @notice Update speed for a single deposit token
     */
    function updateTokenSpeed(IERC20 token_, uint256 newSpeed_) external onlyGovernor {
        _updateTokenSpeed(token_, newSpeed_);
    }

    /**
     * @notice Update token speeds
     */
    function updateTokenSpeeds(IERC20[] calldata tokens_, uint256[] calldata speeds_) external onlyGovernor {
        uint256 _tokensLength = tokens_.length;
        require(_tokensLength == speeds_.length, "invalid-input");

        for (uint256 i; i < _tokensLength; ++i) {
            _updateTokenSpeed(tokens_[i], speeds_[i]);
        }
    }
}