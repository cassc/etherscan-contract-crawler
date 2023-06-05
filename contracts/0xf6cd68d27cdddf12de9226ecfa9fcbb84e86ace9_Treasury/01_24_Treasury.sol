// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./access/Manageable.sol";
import "./storage/TreasuryStorage.sol";
import "./interfaces/external/IVPool.sol";
import "./interfaces/external/IPoolRewards.sol";

error SenderIsNotDepositToken();
error AddressIsNull();
error RecipientIsNull();
error AmountIsZero();

/**
 * @title Treasury contract
 */
contract Treasury is ReentrancyGuard, Manageable, TreasuryStorageV1 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IDepositToken;

    string public constant VERSION = "1.2.0";

    /**
     * @dev Throws if caller isn't a deposit token
     */
    modifier onlyIfDepositToken() {
        if (!pool.doesDepositTokenExist(IDepositToken(msg.sender))) revert SenderIsNotDepositToken();
        _;
    }

    function initialize(IPool pool_) external initializer {
        __ReentrancyGuard_init();
        __Manageable_init(pool_);
    }

    /**
     * @notice Transfer all funds to another contract
     * @dev This function can become too expensive depending on the length of the arrays
     * @param newTreasury_ The new treasury
     */
    function migrateTo(address newTreasury_) external override onlyPool {
        if (newTreasury_ == address(0)) revert AddressIsNull();

        address[] memory _depositTokens = pool.getDepositTokens();
        uint256 _depositTokensLength = _depositTokens.length;

        for (uint256 i; i < _depositTokensLength; ++i) {
            IERC20 _underlying = IDepositToken(_depositTokens[i]).underlying();

            uint256 _underlyingBalance = _underlying.balanceOf(address(this));

            if (_underlyingBalance > 0) {
                _underlying.safeTransfer(newTreasury_, _underlyingBalance);
            }
        }
    }

    /**
     * @notice Pull token from the Treasury
     * @param to_ The transfer recipient
     * @param amount_ The transfer amount
     */
    function pull(address to_, uint256 amount_) external override nonReentrant onlyIfDepositToken {
        if (to_ == address(0)) revert RecipientIsNull();
        if (amount_ == 0) revert AmountIsZero();
        IDepositToken(msg.sender).underlying().safeTransfer(to_, amount_);
    }

    /**
     * @notice Claim and withdraw rewards from Vesper
     * @param vPool_ The Vesper pool to collect rewards from
     * @param to_ The transfer recipient
     */
    function claimFromVesper(IVPool vPool_, address to_) external onlyGovernor {
        IPoolRewards _rewards = IPoolRewards(vPool_.poolRewards());
        _rewards.updateReward(address(this));
        _rewards.claimReward(address(this));

        address[] memory _rewardTokens = _rewards.getRewardTokens();
        uint256 _len = _rewardTokens.length;
        for (uint256 i; i < _len; ++i) {
            IERC20 _token = IERC20(_rewardTokens[i]);
            uint256 _amount = _token.balanceOf(address(this));

            // Note: If the reward token is a collateral, transfer the surpass balance only
            IDepositToken _depositToken = pool.depositTokenOf(_token);
            if (address(_depositToken) != address(0)) {
                _amount -= _depositToken.totalSupply();
            }

            if (_amount > 0) {
                _token.safeTransfer(to_, _amount);
            }
        }
    }
}