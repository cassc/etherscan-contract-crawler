// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/utils/math/SafeCast.sol";
import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./interfaces/IDebtToken.sol";
import "./interfaces/IDepositToken.sol";
import "./access/Manageable.sol";
import "./storage/RewardsDistributorStorage.sol";
import "./lib/WadRayMath.sol";

error DistributorDoesNotExist();
error InvalidToken();
error RewardTokenIsNull();
error ReachedMaxRewardTokens();
error ArraysLengthDoNotMatch();

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
    event RewardClaimed(address indexed account, uint256 amount);

    /// @notice Emitted when updating accrued token
    event TokensAccruedUpdated(IERC20 indexed token, address indexed account, uint256 tokensDelta, uint256 supplyIndex);

    /// @notice Emitted when updating token speed
    event TokenSpeedUpdated(IERC20 indexed token, uint256 oldSpeed, uint256 newSpeed);

    /// @notice Emitted when updating token index
    event TokenIndexUpdated(uint224 newIndex, uint32 newTimestamp);

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
        if (!_distributorAdded) revert DistributorDoesNotExist();
        _;
    }

    /**
     * @dev Throws if token doesn't exist
     * @dev Should be a DepositToken (suppliers) or DebtToken (borrowers)
     */
    modifier onlyIfTokenExists(address token_) {
        IPool _pool = pool;
        if (!_pool.doesDebtTokenExist(IDebtToken(token_)) && !_pool.doesDepositTokenExist(IDepositToken(token_))) {
            revert InvalidToken();
        }
        _;
    }

    function initialize(IPool pool_, IERC20 rewardToken_) external initializer {
        if (address(rewardToken_) == address(0)) revert RewardTokenIsNull();

        __ReentrancyGuard_init();
        __Manageable_init(pool_);

        rewardToken = rewardToken_;
    }

    /**
     * @notice Returns claimable amount consider all tokens
     */
    function claimable(address account_) external view override returns (uint256 _claimable) {
        for (uint256 i; i < tokens.length; ++i) {
            _claimable += claimable(account_, tokens[i]);
        }
    }

    /**
     * @notice Returns updated claimable amount for given token
     */
    function claimable(address account_, IERC20 token_) public view override returns (uint256 _claimable) {
        TokenState memory _tokenState = tokenStates[token_];
        (uint224 _newIndex, uint32 _newTimestamp) = _calculateTokenIndex(_tokenState, token_);
        if (_newIndex > 0 && _newTimestamp > 0) {
            _tokenState = TokenState({index: _newIndex, timestamp: _newTimestamp});
        } else if (_newTimestamp > 0) {
            _tokenState.timestamp = _newTimestamp;
        }
        (, , _claimable) = _calculateTokensAccruedOf(_tokenState, token_, account_);
    }

    /**
     * @notice Claim tokens accrued by account in all tokens
     */
    function claimRewards(address account_) external override {
        claimRewards(account_, tokens);
    }

    /**
     * @notice Claim tokens accrued by account in the specified tokens
     */
    function claimRewards(address account_, IERC20[] memory tokens_) public override {
        address[] memory _accounts = new address[](1);
        _accounts[0] = account_;
        claimRewards(_accounts, tokens_);
    }

    /**
     * @notice Claim tokens accrued by the accounts in the specified tokens
     */
    function claimRewards(address[] memory accounts_, IERC20[] memory tokens_) public override nonReentrant {
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
     * This function also may be called by anyone to update stored indexes
     */
    function updateBeforeMintOrBurn(IERC20 token_, address account_) external override {
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
    ) external override {
        if (tokenStates[token_].index > 0) {
            _updateTokenIndex(token_);
            _updateTokensAccruedOf(token_, from_);
            _updateTokensAccruedOf(token_, to_);
        }
    }

    /**
     * @notice Calculate updated token index values
     */
    function _calculateTokenIndex(TokenState memory _supplyState, IERC20 token_)
        private
        view
        returns (uint224 _newIndex, uint32 _newTimestamp)
    {
        uint256 _speed = tokenSpeeds[token_];
        uint256 _deltaTimestamps = block.timestamp - uint256(_supplyState.timestamp);
        if (_deltaTimestamps > 0 && _speed > 0) {
            uint256 _totalSupply = token_.totalSupply();
            uint256 _tokensAccrued = _deltaTimestamps * _speed;
            uint256 _ratio = _totalSupply > 0 ? _tokensAccrued.wadDiv(_totalSupply) : 0;
            _newIndex = (_supplyState.index + _ratio).toUint224();
            _newTimestamp = block.timestamp.toUint32();
        } else if (_deltaTimestamps > 0 && _supplyState.index > 0) {
            _newTimestamp = block.timestamp.toUint32();
        }
    }

    /**
     * @notice Calculate updated account index and claimable values
     */
    function _calculateTokensAccruedOf(
        TokenState memory _tokenState,
        IERC20 token_,
        address account_
    )
        private
        view
        returns (
            uint256 _tokenIndex,
            uint256 _tokensDelta,
            uint256 _tokensAccruedOf
        )
    {
        _tokenIndex = _tokenState.index;
        uint256 _accountIndex = accountIndexOf[token_][account_];

        if (_accountIndex == 0 && _tokenIndex > 0) {
            _accountIndex = INITIAL_INDEX;
        }

        uint256 _deltaIndex = _tokenIndex - _accountIndex;
        _tokensDelta = token_.balanceOf(account_).wadMul(_deltaIndex);
        _tokensAccruedOf = tokensAccruedOf[account_] + _tokensDelta;
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
        (uint256 _tokenIndex, uint256 _tokensDelta, uint256 _tokensAccruedOf) = _calculateTokensAccruedOf(
            tokenStates[token_],
            token_,
            account_
        );
        accountIndexOf[token_][account_] = _tokenIndex;
        tokensAccruedOf[account_] = _tokensAccruedOf;
        emit TokensAccruedUpdated(token_, account_, _tokensDelta, _tokenIndex);
    }

    /**
     * @notice Accrue reward token by updating the index
     */
    function _updateTokenIndex(IERC20 token_) private {
        TokenState storage _supplyState = tokenStates[token_];
        (uint224 _newIndex, uint32 _newTimestamp) = _calculateTokenIndex(_supplyState, token_);
        if (_newIndex > 0 && _newTimestamp > 0) {
            tokenStates[token_] = TokenState({index: _newIndex, timestamp: _newTimestamp});
            emit TokenIndexUpdated(_newIndex, _newTimestamp);
        } else if (_newTimestamp > 0) {
            _supplyState.timestamp = _newTimestamp;
            emit TokenIndexUpdated(_supplyState.index, _newTimestamp);
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
            // Add token to the list
            if (tokenStates[token_].index == 0) {
                if (tokens.length == MAX_REWARD_TOKENS) revert ReachedMaxRewardTokens();
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
    function updateTokenSpeed(IERC20 token_, uint256 newSpeed_) external override onlyGovernor {
        _updateTokenSpeed(token_, newSpeed_);
    }

    /**
     * @notice Update token speeds
     */
    function updateTokenSpeeds(IERC20[] calldata tokens_, uint256[] calldata speeds_) external override onlyGovernor {
        uint256 _tokensLength = tokens_.length;
        if (_tokensLength != speeds_.length) revert ArraysLengthDoNotMatch();

        for (uint256 i; i < _tokensLength; ++i) {
            _updateTokenSpeed(tokens_[i], speeds_[i]);
        }
    }
}