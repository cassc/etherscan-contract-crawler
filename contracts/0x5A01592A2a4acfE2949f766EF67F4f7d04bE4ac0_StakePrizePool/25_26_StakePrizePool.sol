// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./PrizePool.sol";

/**
 * @title  Asymetrix Protocol V1 StakePrizePool
 * @author Asymetrix Protocol Inc Team
 * @notice The Stake Prize Pool is a prize pool in which users can deposit an
 *         ERC20 token. These tokens are simply held by the Stake Prize Pool and
 *         become eligible for prizes. Prizes are added manually by the Stake
 *         Prize Pool owner and are distributed to users at the end of the prize
 *         period.
 */
contract StakePrizePool is PrizePool {
    /// @notice Address of the stake token.
    IERC20Upgradeable private stakeToken;

    /// @dev Emitted when stake prize pool is deployed.
    /// @param stakeToken Address of the stake token.
    event Deployed(IERC20Upgradeable indexed stakeToken);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Deploy the Stake Prize Pool
    /// @param _owner Address of the Stake Prize Pool owner
    /// @param _stakeToken Address of the stake token
    /// @param _rewardToken The ASX token address
    /// @param _rewardPerSecond The reward per second that will be used in time
    ///                         of distribution of ASX tokens
    /// @param _maxClaimInterval The reward maximum claim interval, in seconds
    /// @param _claimInterval The reward claim interval, in seconds
    /// @param _freeExitDuration The duration after finishing of a draw when
    ///                          user can leave the protocol without fee
    ///                          charging (in stETH)
    /// @param _firstLidoRebaseTimestamp The timestamp of the first Lido's
    ///                                  rebase that will take place after the
    ///                                  deployment of this contract
    /// @param _lidoAPR An APR of the Lido protocol
    function initialize(
        address _owner,
        IERC20Upgradeable _stakeToken,
        IERC20Upgradeable _rewardToken,
        uint256 _rewardPerSecond,
        uint32 _maxClaimInterval,
        uint32 _claimInterval,
        uint32 _freeExitDuration,
        uint32 _firstLidoRebaseTimestamp,
        uint16 _lidoAPR
    ) external initializer {
        __PrizePool_init_unchained(
            _owner,
            _rewardToken,
            _rewardPerSecond,
            _maxClaimInterval,
            _claimInterval,
            _freeExitDuration,
            _firstLidoRebaseTimestamp,
            _lidoAPR
        );

        require(
            address(_stakeToken) != address(0),
            "StakePrizePool/stake-token-not-zero-address"
        );

        stakeToken = _stakeToken;

        emit Deployed(_stakeToken);
    }

    /// @notice Determines whether the passed token can be transferred out as an
    ///         external award.
    /// @dev Different yield sources will hold the deposits as another kind of
    ///      token: such a Compound's cToken. The prize flush should not be
    ///      allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(
        address _externalToken
    ) internal view override returns (bool) {
        return address(stakeToken) != _externalToken;
    }

    /// @notice Returns the total balance (in asset tokens). This includes the
    ///         deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal view override returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

    /// @notice Returns the address of the ERC20 asset token used for deposits.
    /// @return Address of the ERC20 asset token.
    function _token() internal view override returns (IERC20Upgradeable) {
        return stakeToken;
    }

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal pure override {
        // no-op because nothing else needs to be done
    }

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(
        uint256 _redeemAmount
    ) internal pure override returns (uint256) {
        return _redeemAmount;
    }
}