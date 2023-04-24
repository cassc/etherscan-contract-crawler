// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../external/compound/ICompLike.sol";

import "../../owner-manager/Ownable.sol";

import "../interfaces/IDrawBeacon.sol";
import "../interfaces/IPrizePool.sol";
import "../interfaces/ITicket.sol";

import "../../Constants.sol";

/**
 * @title  Asymetrix Protocol V1 PrizePool
 * @author Asymetrix Protocol Inc Team
 * @notice Escrows assets and deposits them into a yield source. Exposes
 *         interest to Prize Flush. Users deposit and withdraw from this
 *         contract to participate in Prize Pool. Accounting is managed using
 *         Controlled Tokens, whose mint and burn functions can only be called
 *         by this contract. Must be inherited to provide specific
 *         yield-bearing asset control, such as Compound cTokens.
 */
abstract contract PrizePool is
    Initializable,
    IPrizePool,
    Ownable,
    Constants,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ERC165CheckerUpgradeable for address;
    using SafeCastUpgradeable for uint256;

    /// @notice Semver Version.
    string public constant VERSION = "4.0.0";

    /// @notice Accuracy for calculations.
    uint256 internal constant ACCURACY = 10 ** 18;

    /// @notice Prize Pool ticket. Can only be set once by calling `setTicket()`.
    ITicket internal ticket;

    /// @notice Draw Beacon contract. Can only be set once by calling
    ///         `setDrawBeacon()`.
    IDrawBeacon internal drawBeacon;

    /// @notice ASX token contract. Can only be set once in the constructor.
    IERC20Upgradeable internal rewardToken;

    /// @notice The Prize Flush that this Prize Pool is bound to.
    address internal prizeFlush;

    /// @notice The reward last updated timestamp.
    uint64 internal lastUpdated;

    /// @notice The reward claim interval, in seconds.
    uint32 internal claimInterval;

    /// @notice The total amount of tickets a user can hold.
    uint256 internal balanceCap;

    /// @notice The total amount of funds that the prize pool can hold.
    uint256 internal liquidityCap;

    /// @notice The awardable balance.
    uint256 internal _currentAwardBalance;

    /// @notice The reward per second that will be used in time of distribution
    ///         of ASX tokens.
    uint256 internal rewardPerSecond;

    /// @notice The reward per share coefficient.
    uint256 internal rewardPerShare;

    /// @notice Stores information about users' stakes and rewards.
    mapping(address => UserStakeInfo) internal userStakeInfo;

    /// @notice The timestamp when ASX tokens distribution will finish.
    uint32 internal distributionEnd;

    /// @notice The duration after finishing of a draw when user can leave the
    ///         protocol without fee charging (in stETH).
    uint32 internal freeExitDuration;

    /// @notice The timestamp of the deployment of this contract.
    uint32 internal deploymentTimestamp;

    /// @notice The timestamp of the first Lido's rebase that will take place
    ///         after the deployment of this contract.
    uint32 internal firstLidoRebaseTimestamp;

    /// @notice The maximum claim interval, in seconds.
    uint32 internal maxClaimInterval;

    /// @notice The APR of the Lido protocol, percentage with 2 decimals.
    uint16 internal lidoAPR;

    /* ============ Modifiers ============ */

    /// @dev Function modifier to ensure caller is the prize-flush.
    modifier onlyPrizeFlush() {
        require(msg.sender == prizeFlush, "PrizePool/only-prizeFlush");
        _;
    }

    /// @dev Function modifier to ensure caller is the ticket.
    modifier onlyTicket() {
        require(msg.sender == address(ticket), "PrizePool/only-ticket");
        _;
    }

    /// @dev Function modifier to ensure the deposit amount does not exceed the
    ///      liquidity cap (if set).
    modifier canAddLiquidity(uint256 _amount) {
        require(_canAddLiquidity(_amount), "PrizePool/exceeds-liquidity-cap");
        _;
    }

    /* ============ Initialize ============ */

    /// @notice Deploy the Prize Pool.
    /// @param _owner Address of the Prize Pool owner.
    /// @param _rewardToken The ASX token address.
    /// @param _rewardPerSecond The reward per second that will be used in time
    ///                         of distribution of ASX tokens.
    /// @param _maxClaimInterval The reward maximum claim interval, in seconds.
    /// @param _claimInterval The reward claim interval, in seconds.
    /// @param _freeExitDuration The duration after finishing of a draw when
    ///                          user can leave the protocol without fee
    ///                          charging (in stETH).
    /// @param _firstLidoRebaseTimestamp The timestamp of the first Lido's
    ///                                  rebase that will take place after the
    ///                                  deployment of this contract.
    /// @param _lidoAPR An APR of the Lido protocol.
    function __PrizePool_init_unchained(
        address _owner,
        IERC20Upgradeable _rewardToken,
        uint256 _rewardPerSecond,
        uint32 _maxClaimInterval,
        uint32 _claimInterval,
        uint32 _freeExitDuration,
        uint32 _firstLidoRebaseTimestamp,
        uint16 _lidoAPR
    ) internal onlyInitializing {
        __Ownable_init_unchained(_owner);
        __ReentrancyGuard_init_unchained();

        _setLiquidityCap(type(uint256).max);
        _setRewardToken(_rewardToken);
        _setRewardPerSecond(_rewardPerSecond);
        _setMaxClaimInterval(_maxClaimInterval);
        _setClaimInterval(_claimInterval);
        _setFreeExitDuration(_freeExitDuration);
        _setFirstLidoRebaseTimestamp(_firstLidoRebaseTimestamp);
        _setLidoAPR(_lidoAPR);

        distributionEnd = uint32(block.timestamp) + 31_536_000; // In one year
        deploymentTimestamp = uint32(block.timestamp);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizePool
    function balance() external override returns (uint256) {
        return _balance();
    }

    /// @inheritdoc IPrizePool
    function awardBalance() external view override returns (uint256) {
        return _currentAwardBalance;
    }

    /// @inheritdoc IPrizePool
    function canAwardExternal(
        address _externalToken
    ) external view override returns (bool) {
        return _canAwardExternal(_externalToken);
    }

    /// @inheritdoc IPrizePool
    function isControlled(
        ITicket _controlledToken
    ) external view override returns (bool) {
        return _isControlled(_controlledToken);
    }

    /// @inheritdoc IPrizePool
    function getAccountedBalance() external view override returns (uint256) {
        return _ticketTotalSupply();
    }

    /// @inheritdoc IPrizePool
    function getBalanceCap() external view override returns (uint256) {
        return balanceCap;
    }

    /// @inheritdoc IPrizePool
    function getLiquidityCap() external view override returns (uint256) {
        return liquidityCap;
    }

    /// @inheritdoc IPrizePool
    function getTicket() external view override returns (ITicket) {
        return ticket;
    }

    /// @inheritdoc IPrizePool
    function getDrawBeacon() external view override returns (IDrawBeacon) {
        return drawBeacon;
    }

    /// @inheritdoc IPrizePool
    function getRewardToken()
        external
        view
        override
        returns (IERC20Upgradeable)
    {
        return rewardToken;
    }

    /// @inheritdoc IPrizePool
    function getPrizeFlush() external view override returns (address) {
        return prizeFlush;
    }

    /// @inheritdoc IPrizePool
    function getToken() external view override returns (address) {
        return address(_token());
    }

    /// @inheritdoc IPrizePool
    function getLastUpdated() external view override returns (uint64) {
        return lastUpdated;
    }

    /// @inheritdoc IPrizePool
    function getRewardPerSecond() external view override returns (uint256) {
        return rewardPerSecond;
    }

    /// @inheritdoc IPrizePool
    function getRewardPerShare() external view override returns (uint256) {
        return rewardPerShare;
    }

    /// @inheritdoc IPrizePool
    function getMaxClaimInterval() external view override returns (uint32) {
        return maxClaimInterval;
    }

    /// @inheritdoc IPrizePool
    function getClaimInterval() external view override returns (uint32) {
        return claimInterval;
    }

    /// @inheritdoc IPrizePool
    function getFreeExitDuration() external view override returns (uint32) {
        return freeExitDuration;
    }

    /// @inheritdoc IPrizePool
    function getDeploymentTimestamp() external view override returns (uint32) {
        return deploymentTimestamp;
    }

    /// @inheritdoc IPrizePool
    function getFirstLidoRebaseTimestamp()
        external
        view
        override
        returns (uint32)
    {
        return firstLidoRebaseTimestamp;
    }

    /// @inheritdoc IPrizePool
    function getLidoAPR() external view override returns (uint16) {
        return lidoAPR;
    }

    /// @inheritdoc IPrizePool
    function getUserStakeInfo(
        address _user
    ) external view override returns (UserStakeInfo memory) {
        return userStakeInfo[_user];
    }

    /// @inheritdoc IPrizePool
    function getDistributionEnd() external view override returns (uint32) {
        return distributionEnd;
    }

    /// @inheritdoc IPrizePool
    function getClaimableReward(
        address _user
    ) external view override returns (uint256) {
        UserStakeInfo memory userInfo = userStakeInfo[_user];

        return
            (userInfo.reward +
                ((ticket.balanceOf(_user) * _getUpdatedRewardPerShare()) -
                    userInfo.former)) / ACCURACY;
    }

    /// @inheritdoc IPrizePool
    function captureAwardBalance()
        external
        override
        nonReentrant
        returns (uint256)
    {
        uint256 ticketTotalSupply = _ticketTotalSupply();
        uint256 currentAwardBalance = _currentAwardBalance;

        /**
         * It's possible for the balance to be slightly less due to rounding
         * errors in the underlying yield source
         */
        uint256 currentBalance = _balance();
        uint256 totalInterest = (currentBalance > ticketTotalSupply)
            ? currentBalance - ticketTotalSupply
            : 0;
        uint256 unaccountedPrizeBalance = (totalInterest > currentAwardBalance)
            ? totalInterest - currentAwardBalance
            : 0;

        if (unaccountedPrizeBalance > 0) {
            currentAwardBalance = totalInterest;
            _currentAwardBalance = currentAwardBalance;

            emit AwardCaptured(unaccountedPrizeBalance);
        }

        return currentAwardBalance;
    }

    /// @inheritdoc IPrizePool
    function depositTo(
        address _to,
        uint256 _amount
    ) external override nonReentrant canAddLiquidity(_amount) {
        _depositTo(msg.sender, _to, _amount);
    }

    /// @inheritdoc IPrizePool
    function depositToAndDelegate(
        address _to,
        uint256 _amount,
        address _delegate
    ) external override nonReentrant canAddLiquidity(_amount) {
        _depositTo(msg.sender, _to, _amount);

        ticket.controllerDelegateFor(msg.sender, _delegate);
    }

    /// @notice Transfers tokens in from one user and mints tickets to another.
    /// @notice _operator The user to transfer tokens from.
    /// @notice _to The user to mint tickets to.
    /// @notice _amount The amount to transfer and mint.
    function _depositTo(
        address _operator,
        address _to,
        uint256 _amount
    ) internal {
        require(_canDeposit(_to, _amount), "PrizePool/exceeds-balance-cap");

        _updateReward();

        UserStakeInfo storage userInfo = userStakeInfo[_to];
        uint256 _rewardPerShare = rewardPerShare;
        ITicket _ticket = ticket;

        _token().safeTransferFrom(_operator, address(this), _amount);

        userInfo.reward +=
            (_ticket.balanceOf(_to) * _rewardPerShare) -
            userInfo.former;

        _mint(_to, _amount, _ticket);
        _supply(_amount);

        userInfo.former = _ticket.balanceOf(_to) * _rewardPerShare;

        emit Deposited(_operator, _to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePool
    function withdrawFrom(
        address _from,
        uint256 _amount
    ) external override nonReentrant returns (uint256) {
        _updateReward();

        UserStakeInfo storage userInfo = userStakeInfo[_from];
        uint256 _rewardPerShare = rewardPerShare;
        ITicket _ticket = ticket;

        userInfo.reward +=
            (_ticket.balanceOf(_from) * _rewardPerShare) -
            userInfo.former;

        // Burn the tickets
        _ticket.controllerBurnFrom(msg.sender, _from, _amount);

        // Redeem the tickets
        uint256 _redeemed = _redeem(_amount);

        userInfo.former = _ticket.balanceOf(_from) * _rewardPerShare;

        uint32 _currentTimestamp = uint32(block.timestamp);

        if (
            drawBeacon.getNextDrawId() == 1 ||
            _currentTimestamp - drawBeacon.getBeaconPeriodStartedAt() >
            freeExitDuration
        ) {
            uint256 _secondsNumber = uint256(
                _getSecondsNumberToPayExitFee(_currentTimestamp)
            );
            uint256 _percent = ((_secondsNumber * uint256(lidoAPR)) * 1 ether) /
                31_536_000 /
                10 ** 4;
            uint256 _actualRedeemed = (_redeemed * (1 ether - _percent)) /
                1 ether;

            _redeemed = _actualRedeemed;
        }

        _token().safeTransfer(_from, _redeemed);

        emit Withdrawal(
            msg.sender,
            _from,
            _ticket,
            _amount,
            _redeemed,
            _amount - _redeemed
        );

        return _redeemed;
    }

    /// @inheritdoc IPrizePool
    function updateUserRewardAndFormer(
        address _user,
        uint256 _beforeBalance,
        uint256 _afterBalance
    ) external override onlyTicket {
        _updateReward();

        UserStakeInfo storage userInfo = userStakeInfo[_user];
        uint256 _rewardPerShare = rewardPerShare;

        userInfo.reward += (_beforeBalance * _rewardPerShare) - userInfo.former;
        userInfo.former = _afterBalance * _rewardPerShare;
    }

    /// @inheritdoc IPrizePool
    function claim(address _user) external override nonReentrant {
        UserStakeInfo storage userInfo = userStakeInfo[_user];

        require(
            uint32(block.timestamp) - userInfo.lastClaimed > claimInterval,
            "PrizePool/claim-interval-not-finished"
        );

        _updateReward();

        uint256 _rewardPerShare = rewardPerShare;
        ITicket _ticket = ticket;

        userInfo.reward +=
            (_ticket.balanceOf(_user) * _rewardPerShare) -
            userInfo.former;

        uint256 _reward = userInfo.reward / ACCURACY;
        uint256 _rewardTokenBalance = rewardToken.balanceOf(address(this));

        if (_rewardTokenBalance < _reward) {
            _reward = _rewardTokenBalance;
        }

        if (_reward > 0) {
            userInfo.reward = userInfo.reward - (_reward * ACCURACY);
            userInfo.lastClaimed = uint32(block.timestamp);

            rewardToken.safeTransfer(_user, _reward);
        }

        userInfo.former = _ticket.balanceOf(_user) * _rewardPerShare;
    }

    /// @inheritdoc IPrizePool
    function award(
        address _to,
        uint256 _amount
    ) external override onlyPrizeFlush {
        if (_amount == 0) {
            return;
        }

        uint256 currentAwardBalance = _currentAwardBalance;

        require(
            _amount <= currentAwardBalance,
            "PrizePool/award-exceeds-avail"
        );

        unchecked {
            _currentAwardBalance = currentAwardBalance - _amount;
        }

        ITicket _ticket = ticket;

        _mint(_to, _amount, _ticket);

        emit Awarded(_to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePool
    function transferExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeFlush {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit TransferredExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePool
    function awardExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeFlush {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit AwardedExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePool
    function awardExternalERC721(
        address _to,
        address _externalToken,
        uint256[] calldata _tokenIds
    ) external override onlyPrizeFlush {
        require(
            _canAwardExternal(_externalToken),
            "PrizePool/invalid-external-token"
        );

        if (_tokenIds.length == 0) {
            return;
        }

        require(
            _tokenIds.length <= MAX_TOKEN_IDS_LENGTH,
            "PrizePool/wrong-array-length"
        );

        uint256[] memory _awardedTokenIds = new uint256[](_tokenIds.length);
        bool hasAwardedTokenIds;

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            try
                IERC721Upgradeable(_externalToken).safeTransferFrom(
                    address(this),
                    _to,
                    _tokenIds[i]
                )
            {
                hasAwardedTokenIds = true;
                _awardedTokenIds[i] = _tokenIds[i];
            } catch (bytes memory error) {
                emit ErrorAwardingExternalERC721(error);
            }
        }
        if (hasAwardedTokenIds) {
            emit AwardedExternalERC721(_to, _externalToken, _awardedTokenIds);
        }
    }

    /// @inheritdoc IPrizePool
    function setBalanceCap(
        uint256 _balanceCap
    ) external override onlyOwner returns (bool) {
        _setBalanceCap(_balanceCap);

        return true;
    }

    /// @inheritdoc IPrizePool
    function setLiquidityCap(
        uint256 _liquidityCap
    ) external override onlyOwner {
        _setLiquidityCap(_liquidityCap);
    }

    /// @inheritdoc IPrizePool
    function setTicket(
        ITicket _ticket
    ) external override onlyOwner returns (bool) {
        require(
            address(_ticket) != address(0),
            "PrizePool/ticket-not-zero-address"
        );
        require(address(ticket) == address(0), "PrizePool/ticket-already-set");

        ticket = _ticket;

        emit TicketSet(_ticket);

        _setBalanceCap(type(uint256).max);

        return true;
    }

    /// @inheritdoc IPrizePool
    function setDrawBeacon(IDrawBeacon _drawBeacon) external onlyOwner {
        require(
            address(_drawBeacon) != address(0),
            "PrizePool/draw-beacon-not-zero-address"
        );

        drawBeacon = _drawBeacon;

        emit DrawBeaconSet(_drawBeacon);
    }

    /// @inheritdoc IPrizePool
    function setPrizeFlush(address _prizeFlush) external onlyOwner {
        _setPrizeFlush(_prizeFlush);
    }

    /// @inheritdoc IPrizePool
    function setRewardPerSecond(
        uint256 _rewardPerSecond
    ) external override onlyOwner {
        _setRewardPerSecond(_rewardPerSecond);
    }

    /// @inheritdoc IPrizePool
    function setMaxClaimInterval(
        uint32 _maxClaimInterval
    ) external override onlyOwner {
        _setMaxClaimInterval(_maxClaimInterval);
    }

    /// @inheritdoc IPrizePool
    function setClaimInterval(
        uint32 _claimInterval
    ) external override onlyOwner {
        _setClaimInterval(_claimInterval);
    }

    /// @inheritdoc IPrizePool
    function setFreeExitDuration(
        uint32 _freeExitDuration
    ) external override onlyOwner {
        _setFreeExitDuration(_freeExitDuration);
    }

    /// @inheritdoc IPrizePool
    function setLidoAPR(uint16 _lidoAPR) external override onlyOwner {
        _setLidoAPR(_lidoAPR);
    }

    /// @inheritdoc IPrizePool
    function compLikeDelegate(
        ICompLike _compLike,
        address _to
    ) external override onlyOwner {
        if (_compLike.balanceOf(address(this)) > 0) {
            _compLike.delegate(_to);
        }
    }

    /// @inheritdoc IERC721ReceiverUpgradeable
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /* ============ Internal Functions ============ */

    /// @notice Transfer out `amount` of `externalToken` to recipient `to`.
    /// @dev Only awardable `externalToken` can be transferred out.
    /// @param _to Recipient address.
    /// @param _externalToken Address of the external asset token being
    ///                       transferred.
    /// @param _amount Amount of external assets to be transferred.
    /// @return `true` if transfer is successful.
    function _transferOut(
        address _to,
        address _externalToken,
        uint256 _amount
    ) internal returns (bool) {
        require(
            _canAwardExternal(_externalToken),
            "PrizePool/invalid-external-token"
        );

        if (_amount == 0) {
            return false;
        }

        IERC20Upgradeable(_externalToken).safeTransfer(_to, _amount);

        return true;
    }

    /// @notice Called to mint controlled tokens.  Ensures that token listener
    ///         callbacks are fired.
    /// @param _to The user who is receiving the tokens.
    /// @param _amount The amount of tokens they are receiving.
    /// @param _controlledToken The token that is going to be minted.
    function _mint(
        address _to,
        uint256 _amount,
        ITicket _controlledToken
    ) internal {
        _controlledToken.controllerMint(_to, _amount);
    }

    /// @dev Checks if `user` can deposit in the Prize Pool based on the current
    ///      balance cap.
    /// @param _user Address of the user depositing.
    /// @param _amount The amount of tokens to be deposited into the Prize Pool.
    /// @return True if the Prize Pool can receive the specified `amount` of
    ///         tokens.
    function _canDeposit(
        address _user,
        uint256 _amount
    ) internal view returns (bool) {
        uint256 _balanceCap = balanceCap;

        if (_balanceCap == type(uint256).max) return true;

        return (ticket.balanceOf(_user) + _amount <= _balanceCap);
    }

    /// @dev Checks if the Prize Pool can receive liquidity based on the current
    ///      cap.
    /// @param _amount The amount of liquidity to be added to the Prize Pool.
    /// @return True if the Prize Pool can receive the specified amount of
    ///         liquidity.
    function _canAddLiquidity(uint256 _amount) internal view returns (bool) {
        uint256 _liquidityCap = liquidityCap;

        if (_liquidityCap == type(uint256).max) return true;

        return (_ticketTotalSupply() + _amount <= _liquidityCap);
    }

    /// @dev Checks if a specific token is controlled by the Prize Pool.
    /// @param _controlledToken The address of the token to check.
    /// @return `true` if the token is a controlled token, `false` otherwise.
    function _isControlled(
        ITicket _controlledToken
    ) internal view returns (bool) {
        return (ticket == _controlledToken);
    }

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @param _balanceCap New balance cap.
    function _setBalanceCap(uint256 _balanceCap) internal {
        balanceCap = _balanceCap;

        emit BalanceCapSet(_balanceCap);
    }

    /// @notice Allows the owner to set a liquidity cap for the pool.
    /// @param _liquidityCap New liquidity cap.
    function _setLiquidityCap(uint256 _liquidityCap) internal {
        if (address(ticket) != address(0)) {
            require(
                _liquidityCap >= _ticketTotalSupply(),
                "PrizePool/liquidity-cap-too-small"
            );
        }

        liquidityCap = _liquidityCap;

        emit LiquidityCapSet(_liquidityCap);
    }

    /// @notice Sets the prize flush of the prize pool. Only callable by the
    ///         owner.
    /// @param _prizeFlush The new prize flush.
    function _setPrizeFlush(address _prizeFlush) internal {
        require(
            _prizeFlush != address(0),
            "PrizePool/prize-flush-not-zero-address"
        );

        prizeFlush = _prizeFlush;

        emit PrizeFlushSet(_prizeFlush);
    }

    /// @notice Sets the reward token address (ASX token) for the prize pool
    ///         that will be used for distribution. Only callable by the owner.
    /// @param _rewardToken The ASX token address.
    function _setRewardToken(IERC20Upgradeable _rewardToken) internal {
        require(
            address(_rewardToken) != address(0),
            "PrizePool/reward-token-not-zero-address"
        );

        rewardToken = _rewardToken;

        emit RewardTokenSet(_rewardToken);
    }

    /// @notice Sets the reward per second for the prize pool that will be used
    ///         for ASX tokens distribution. Only callable by the owner.
    /// @param _rewardPerSecond The new reward per second.
    function _setRewardPerSecond(uint256 _rewardPerSecond) internal {
        _updateReward();

        rewardPerSecond = _rewardPerSecond;

        emit RewardPerSecondSet(_rewardPerSecond);
    }

    /// @notice Sets the maximum claim interval for the prize pool that will be
    ///         used in time of claim interval sets. Only callable by the owner.
    /// @param _maxClaimInterval The new maximum claim interval, in seconds.
    function _setMaxClaimInterval(uint32 _maxClaimInterval) internal {
        maxClaimInterval = _maxClaimInterval;

        emit MaxClaimIntervalSet(_maxClaimInterval);
    }

    /// @notice Sets the claim interval for the prize pool that will be used in
    ///         time of claiming of ASX tokens. Only callable by the owner.
    /// @param _claimInterval The new claim interval, in seconds.
    function _setClaimInterval(uint32 _claimInterval) internal {
        require(
            _claimInterval <= maxClaimInterval,
            "PrizePool/claim-interval-is-too-big"
        );

        claimInterval = _claimInterval;

        emit ClaimIntervalSet(_claimInterval);
    }

    /// @notice Sets the free exit duration, in seconds. Only callable by the
    ///         owner.
    /// @param _freeExitDuration The duration after finishing of a draw when
    ///                          user can leave the protocol without fee
    ///                          charging (in stETH).
    function _setFreeExitDuration(uint32 _freeExitDuration) internal {
        freeExitDuration = _freeExitDuration;

        emit FreeExitDurationSet(_freeExitDuration);
    }

    /// @notice Sets the first Lido's rebase timestamp.
    /// @dev Can be set once, only in time of this contract deployment.
    /// @param _firstLidoRebaseTimestamp The timestamp of the first Lido's
    ///                                  rebase that will take place after the
    ///                                  deployment of this contract.
    function _setFirstLidoRebaseTimestamp(
        uint32 _firstLidoRebaseTimestamp
    ) internal {
        require(
            _firstLidoRebaseTimestamp > block.timestamp,
            "PrizePool/first-lido-rebase-timestamp-must-be-in-the-future"
        );

        firstLidoRebaseTimestamp = _firstLidoRebaseTimestamp;

        emit FirstLidoRebaseTimestampSet(_firstLidoRebaseTimestamp);
    }

    /// @notice Set APR of the Lido protocol. Only callable by the owner.
    /// @dev 10000 is equal to 100.00% (2 decimals). Zero (0) is a valid value.
    /// @param _lidoAPR An APR of the Lido protocol.
    function _setLidoAPR(uint16 _lidoAPR) internal {
        require(_lidoAPR <= 10000, "PrizePool/lido-APR-is-too-high");

        lidoAPR = _lidoAPR;

        emit LidoAPRSet(_lidoAPR);
    }

    /// @notice The current total of tickets.
    /// @return Ticket total supply.
    function _ticketTotalSupply() internal view returns (uint256) {
        return ticket.totalSupply();
    }

    /// @dev Gets the current time as represented by the current block.
    /// @return The timestamp of the current block.
    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Updates the reward during each deposit, withdraw and transfer.
    function _updateReward() internal {
        if (lastUpdated <= uint64(distributionEnd)) {
            rewardPerShare = _getUpdatedRewardPerShare();
            lastUpdated = uint64(block.timestamp);

            emit RewardUpdated(lastUpdated);
        }
    }

    /// @dev Calculates new reward per share.
    /// @return Updated reward per share.
    function _getUpdatedRewardPerShare() internal view returns (uint256) {
        uint256 _rewardPerShare = rewardPerShare;

        if (address(ticket) != address(0)) {
            uint256 totalSupply = _ticketTotalSupply();

            if (totalSupply != 0) {
                uint64 timeDelta = uint32(block.timestamp) > distributionEnd
                    ? uint64(distributionEnd) - lastUpdated
                    : uint64(block.timestamp) - lastUpdated;
                uint256 reward = uint256(timeDelta) * rewardPerSecond;

                _rewardPerShare += (reward * ACCURACY) / totalSupply;
            }
        }

        return _rewardPerShare;
    }

    /// @notice Calculates a number of seconds for which the user has to pay the
    ///         exit fee.
    /// @dev If Lido's rebase operatio didn't happen yet, calculates the seconds
    ///      difference between contract's deployment timestamp and user's
    ///      current withdraw timestamp.
    /// @dev If at least one Lido's rebase operation took place, calculates the
    ///      seconds difference between last Lido's rebase timestamp and user's
    ///      current withdraw timestamp.
    /// @param _withdrawTimestamp The timestamp of the withdraw transaction.
    /// @return The number of seconds for which the user has to pay the exit fee.
    function _getSecondsNumberToPayExitFee(
        uint32 _withdrawTimestamp
    ) private view returns (uint32) {
        uint32 _firstLidoRebaseTimestamp = firstLidoRebaseTimestamp;

        if (_withdrawTimestamp < _firstLidoRebaseTimestamp) {
            return _withdrawTimestamp - deploymentTimestamp;
        } else {
            return
                _withdrawTimestamp -
                _getLastLidoRebaseTimestamp(
                    _firstLidoRebaseTimestamp,
                    _withdrawTimestamp
                );
        }
    }

    /// @notice Calculates Lido's last rebase timestamp using Lido's first
    ///         rebase timestamp.
    /// @param _firstLidoRebaseTimestamp The timestamp of Lido's first rebase
    ///                                  operation.
    /// @param _actionTimestamp The timestamp of an operation for which to
    ///                         calculate Lido's last rebase timestamp.
    /// @return The Lido's last rebase timestamp.
    function _getLastLidoRebaseTimestamp(
        uint32 _firstLidoRebaseTimestamp,
        uint32 _actionTimestamp
    ) private pure returns (uint32) {
        uint32 _secondsPerDay = 86_400;
        uint32 _daysDiff = (_actionTimestamp - _firstLidoRebaseTimestamp) /
            _secondsPerDay;

        return _firstLidoRebaseTimestamp + (_daysDiff * _secondsPerDay);
    }

    /* ============ Abstract Contract Implementatiton ============ */

    /// @notice Determines whether the passed token can be transferred out as
    ///         an external award.
    /// @dev Different yield sources will hold the deposits as another kind of
    ///      token: such a Compound's cToken. The prize flush should not be
    ///      allowed to move those tokens.
    /// @dev Should be implemented in a child contract during the inheritance.
    /// @param _externalToken The address of the token to check.
    /// @return `true` if the token may be awarded, `false` otherwise.
    function _canAwardExternal(
        address _externalToken
    ) internal view virtual returns (bool);

    /// @notice Returns the ERC20 asset token used for deposits.
    /// @dev Should be implemented in a child contract during the inheritance.
    /// @return The ERC20 asset token.
    function _token() internal view virtual returns (IERC20Upgradeable);

    /// @notice Returns the total balance (in asset tokens). This includes the
    ///         deposits and interest.
    /// @dev Should be implemented in a child contract during the inheritance.
    /// @return The underlying balance of asset tokens.
    function _balance() internal virtual returns (uint256);

    /// @notice Supplies asset tokens to the yield source.
    /// @dev Should be implemented in a child contract during the inheritance.
    /// @param _mintAmount The amount of asset tokens to be supplied.
    function _supply(uint256 _mintAmount) internal virtual;

    /// @notice Redeems asset tokens from the yield source.
    /// @dev Should be implemented in a child contract during the inheritance.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed.
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal virtual returns (uint256);

    uint256[45] private __gap;
}