//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/IERC721MintableBurnable.sol";
import "./interfaces/IParallaxStrategy.sol";
import "./interfaces/IParallaxOrbital.sol";
import "./interfaces/Incentivization.sol";

import "./extensions/TokensRescuer.sol";
import "./extensions/Timelock.sol";

error OnlyNonZeroTotalSharesValue();
error OnlyActiveStrategy();
error OnlyValidFee();
error OnlyExistPosition();
error OnlyExistStrategy();
error OnlyContractAddress();
error OnlyAfterLock(uint32 remainTime);
error OnlyValidWithdrawalSharesAmount();
error OnlyERC721();
error CapExceeded();
error CapTooSmall();
error CallerIsNotOwnerOrApproved();
error NoTokensToClaim();
error StrategyAlreadyAdded();
error IncorrectRewards();

/**
 * @title Main contract of the system.
 *        This contract is responsible for interaction with all strategies,
 *        that is added to the system through this contract
 *        Direct interaction with strategies is not possible.
 *        Current contract supports 2 roles:
 *        simple user and owner of the contract.
 *        Simple user can only make deposits, withdrawals,
 *        transfers of NFTs (ERC-721 tokens) and compounds.
 *        The owner of the contract can execute all owner's methods.
 *        Each user can have many positions
 *        where he will able to deposit or withdraw.
 *        Each user position is represented as ERC-721 token
 *        and can be transferred or approved for transfer.
 *        In time of position creation user receives a new ERC-721 token.
 */
contract ParallaxOrbitalUpgradeable is
    IParallaxOrbital,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    TokensRescuer,
    Timelock
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    IERC721MintableBurnable public ERC721;

    uint256 public usersCount;
    uint256 public strategiesCount;
    uint256 public tokensCount;
    address public feesReceiver;

    mapping(address => mapping(address => bool)) public tokensWhitelist;
    mapping(address => uint256) public strategyToId;
    mapping(address => uint256) public userAmountStrategies;
    mapping(uint256 => Strategy) public strategies;
    mapping(uint256 => mapping(address => mapping(uint256 => UserPosition)))
        public positions;
    mapping(uint256 => mapping(address => uint256)) public positionsIndex;
    mapping(uint256 => mapping(address => uint256)) public positionsCount;
    mapping(uint256 => TokenInfo) public tokens;
    mapping(uint256 => mapping(address => uint256)) public strategyUsersToId;
    mapping(uint256 => mapping(uint256 => address)) public strategyUsers;

    mapping(address => uint256) public usersToId;
    mapping(uint256 => address) public users;
    mapping(address => EnumerableSetUpgradeable.UintSet) private userToNftIds;

    modifier onlyContract(address addressToCheck) {
        _onlyContract(addressToCheck);
        _;
    }

    modifier onlyExistingStrategy(uint256 strategyId) {
        _onlyExistingStrategy(strategyId);
        _;
    }

    modifier onlyValidFee(address strategy, uint256 fee) {
        _onlyValidFee(strategy, fee);
        _;
    }

    modifier onlyValidWithdrawalSharesAmount(
        uint256 strategyId,
        address user,
        uint256 positionId,
        uint256 shares
    ) {
        _onlyValidWithdrawalSharesAmount(strategyId, user, positionId, shares);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     * @param initialFeesReceiver Arecipient of commissions.
     * @param initialERC721 An address of ERC-721 contract for positions.
     */
    function __ParallaxOrbital_init(
        address initialFeesReceiver,
        IERC721MintableBurnable initialERC721
    ) external initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ParallaxOrbital_init_unchained(initialFeesReceiver, initialERC721);
    }

    /// @inheritdoc IParallax
    function addToken(
        uint256 strategyId,
        address token
    )
        external
        onlyOwner
        onlyContract(token)
        onlyExistingStrategy(strategyId)
        onlyNonZeroAddress(token)
    {
        tokensWhitelist[strategies[strategyId].strategy][token] = true;
        
        IParallaxStrategy(strategies[strategyId].strategy).executeApprovals(token);
    }

    /// @inheritdoc IParallax
    function removeToken(
        uint256 strategyId,
        address token
    ) external onlyOwner onlyExistingStrategy(strategyId) {
        tokensWhitelist[strategies[strategyId].strategy][token] = false;
    }

    /// @inheritdoc IParallax
    function addStrategy(
        address strategy,
        address incentivization,
        uint32 timelock,
        uint256 cap,
        uint256 initialFee,
        bool isActive
    )
        external
        onlyOwner
        onlyContract(strategy)
        onlyValidFee(strategy, initialFee)
    {
        if (strategyToId[strategy] != 0) {
            revert StrategyAlreadyAdded();
        }

        ++strategiesCount;

        Strategy storage newStrategy = strategies[strategiesCount];

        newStrategy.fee = initialFee;
        newStrategy.timelock = timelock;
        newStrategy.cap = cap;
        newStrategy.strategy = strategy;
        newStrategy.incentivization = incentivization;
        newStrategy.isActive = isActive;

        strategyToId[strategy] = strategiesCount;
    }

    /// @inheritdoc IParallax
    function setFeesReceiver(
        address newFeesReceiver
    ) external onlyOwner onlyNonZeroAddress(newFeesReceiver) {
        feesReceiver = newFeesReceiver;
    }

    /// @inheritdoc IParallax
    function setFee(
        uint256 strategyId,
        uint256 newFee
    )
        external
        onlyExistingStrategy(strategyId)
        onlyValidFee(strategies[strategyId].strategy, newFee)
        onlyOwner
    {
        strategies[strategyId].fee = newFee;
    }

    /// @inheritdoc IParallax
    function setTimelock(
        uint256 strategyId,
        uint32 timelock
    ) external onlyExistingStrategy(strategyId) onlyInternalCall {
        strategies[strategyId].timelock = timelock;
    }

    /// @inheritdoc IParallax
    function setCap(
        uint256 strategyId,
        uint256 cap
    ) external onlyOwner onlyExistingStrategy(strategyId) {
        if (cap < strategies[strategyId].totalStaked) {
            revert CapTooSmall();
        }

        strategies[strategyId].cap = cap;
    }

    /// @inheritdoc IParallax
    function setIncentivization(
        uint256 strategyId,
        address newIncentivization
    ) external onlyOwner onlyExistingStrategy(strategyId) {
        strategies[strategyId].incentivization = newIncentivization;
    }

    /// @inheritdoc IParallax
    function setCompoundMinAmount(
        uint256 strategyId,
        uint256 compoundMinAmount
    ) external onlyOwner onlyExistingStrategy(strategyId) {
        IParallaxStrategy(strategies[strategyId].strategy).setCompoundMinAmount(
            compoundMinAmount
        );
    }

    /// @inheritdoc IParallax
    function setStrategyStatus(
        uint256 strategyId,
        bool flag
    ) external onlyOwner onlyExistingStrategy(strategyId) {
        strategies[strategyId].isActive = flag;
    }

    /// @inheritdoc IParallaxOrbital
    function depositLPs(
        DepositAndCompoundParams memory params
    ) external nonReentrant {
        _beforeDeposit(params);

        uint256 deposited = IParallaxStrategy(
            strategies[params.depositParams.strategyId].strategy
        ).depositLPs(_depositParamsAdapter(params.depositParams, _msgSender()));

        _updatePosition(params.depositParams, _msgSender(), deposited);
    }

    /// @inheritdoc IParallaxOrbital
    function depositTokens(
        DepositAndCompoundParams memory params
    ) external nonReentrant {
        _beforeDeposit(params);

        uint256 deposited = IParallaxStrategy(
            strategies[params.depositParams.strategyId].strategy
        ).depositTokens(
                _depositParamsAdapter(params.depositParams, _msgSender())
            );

        _updatePosition(params.depositParams, _msgSender(), deposited);
    }

    /// @inheritdoc IParallaxOrbital
    function depositAndSwapNativeToken(
        DepositAndCompoundParams memory params
    ) external payable nonReentrant {
        _beforeDeposit(params);

        uint256 deposited = IParallaxStrategy(
            strategies[params.depositParams.strategyId].strategy
        ).depositAndSwapNativeToken{ value: msg.value }(
            _depositParamsAdapter(params.depositParams, _msgSender())
        );

        _updatePosition(params.depositParams, _msgSender(), deposited);
    }

    /// @inheritdoc IParallaxOrbital
    function depositAndSwapERC20Token(
        DepositAndCompoundParams memory params
    ) external nonReentrant {
        _beforeDeposit(params);

        uint256 deposited = IParallaxStrategy(
            strategies[params.depositParams.strategyId].strategy
        ).depositAndSwapERC20Token(
                _depositParamsAdapter(params.depositParams, _msgSender())
            );

        _updatePosition(params.depositParams, _msgSender(), deposited);
    }

    /// @inheritdoc IParallaxOrbital
    function withdrawLPs(
        WithdrawAndCompoundParams memory params
    ) external nonReentrant {
        (uint256 amount, uint256 earned) = _withdraw(params);

        IParallaxStrategy(strategies[params.withdrawParams.strategyId].strategy)
            .withdrawLPs(
                _withdrawParamsAdapter(
                    params.withdrawParams,
                    _msgSender(),
                    amount,
                    earned
                )
            );
    }

    /// @inheritdoc IParallaxOrbital
    function withdrawTokens(
        WithdrawAndCompoundParams memory params
    ) external nonReentrant {
        (uint256 amount, uint256 earned) = _withdraw(params);

        IParallaxStrategy(strategies[params.withdrawParams.strategyId].strategy)
            .withdrawTokens(
                _withdrawParamsAdapter(
                    params.withdrawParams,
                    _msgSender(),
                    amount,
                    earned
                )
            );
    }

    /// @inheritdoc IParallaxOrbital
    function withdrawAndSwapForNativeToken(
        WithdrawAndCompoundParams memory params
    ) external nonReentrant {
        (uint256 amount, uint256 earned) = _withdraw(params);

        IParallaxStrategy(strategies[params.withdrawParams.strategyId].strategy)
            .withdrawAndSwapForNativeToken(
                _withdrawParamsAdapter(
                    params.withdrawParams,
                    _msgSender(),
                    amount,
                    earned
                )
            );
    }

    /// @inheritdoc IParallaxOrbital
    function withdrawAndSwapForERC20Token(
        WithdrawAndCompoundParams memory params
    ) external nonReentrant {
        (uint256 amount, uint256 earned) = _withdraw(params);
        IParallaxStrategy(strategies[params.withdrawParams.strategyId].strategy)
            .withdrawAndSwapForERC20Token(
                _withdrawParamsAdapter(
                    params.withdrawParams,
                    _msgSender(),
                    amount,
                    earned
                )
            );
    }

    /// @inheritdoc IParallaxOrbital
    function compound(
        uint256 strategyId,
        uint256[] memory amountsOutMin
    ) external nonReentrant onlyExistingStrategy(strategyId) {
        _compound(strategyId, amountsOutMin, true);
    }

    /// @inheritdoc IParallaxOrbital
    function claim(
        uint256 strategyId,
        uint256 positionId
    ) external nonReentrant onlyExistingStrategy(strategyId) {
        address incentivization = strategies[strategyId].incentivization;

        if (incentivization != address(0)) {
            Incentivization(strategies[strategyId].incentivization).claim(
                strategyId,
                _msgSender(),
                positionId
            );
        }
    }

    /// @inheritdoc IParallax
    function addTransaction(
        Timelock.Transaction memory transaction
    ) external onlyOwner returns (bytes32) {
        return _addTransaction(transaction);
    }

    /// @inheritdoc IParallax
    function removeTransaction(
        Timelock.Transaction memory transaction
    ) external onlyOwner {
        _removeTransaction(transaction);
    }

    /// @inheritdoc IParallax
    function executeTransaction(
        Timelock.Transaction memory transaction
    ) external onlyOwner returns (bytes memory) {
        return _executeTransaction(transaction);
    }

    /// @inheritdoc IParallax
    function getFee(address strategy) external view returns (uint256) {
        return strategies[strategyToId[strategy]].fee;
    }

    /// @inheritdoc IParallax
    function getStakedBySharesAmount(
        uint256 strategyId,
        uint256 shares
    ) external view onlyExistingStrategy(strategyId) returns (uint256) {
        return _getStakedBySharesAmount(strategyId, shares);
    }

    /// @inheritdoc IParallax
    function getEarnedBySharesAmount(
        uint256 strategyId,
        address user,
        uint256 positionId,
        uint256 shares
    )
        external
        view
        onlyExistingStrategy(strategyId)
        onlyValidWithdrawalSharesAmount(strategyId, user, positionId, shares)
        returns (uint256)
    {
        return _getEarnedBySharesAmount(strategyId, user, positionId, shares);
    }

    /// @inheritdoc IParallax
    function getEarnedByUserAmount(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view onlyExistingStrategy(strategyId) returns (uint256) {
        return
            _getEarnedBySharesAmount(
                strategyId,
                user,
                positionId,
                positions[strategyId][user][positionId].shares
            );
    }

    /// @inheritdoc IParallax
    function getNftByUserAndIndex(
        address user,
        uint256 index
    ) external view returns (uint256) {
        return userToNftIds[user].at(index);
    }

    /// @inheritdoc IParallax
    function getPositionInfo(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view returns (UserPosition memory) {
        return positions[strategyId][user][positionId];
    }

    /// @inheritdoc ITokensRescuer
    function rescueNativeToken(
        uint256 amount,
        address receiver
    ) external onlyOwner {
        _rescueNativeToken(amount, receiver);
    }

    /// @inheritdoc IParallax
    function rescueNativeToken(
        uint256 strategyId,
        uint256 amount,
        address receiver
    ) external onlyOwner onlyExistingStrategy(strategyId) {
        IParallaxStrategy(strategies[strategyId].strategy).rescueNativeToken(
            amount,
            receiver
        );
    }

    /// @inheritdoc ITokensRescuer
    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) external onlyOwner {
        _rescueERC20Token(token, amount, receiver);
    }

    /// @inheritdoc IParallax
    function rescueERC20Token(
        uint256 strategyId,
        address token,
        uint256 amount,
        address receiver
    ) external onlyOwner onlyExistingStrategy(strategyId) {
        IParallaxStrategy(strategies[strategyId].strategy).rescueERC20Token(
            token,
            amount,
            receiver
        );
    }

    /// @inheritdoc IParallax
    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external nonReentrant {
        if (_msgSender() != address(ERC721)) {
            revert OnlyERC721();
        }

        TokenInfo storage tokenInfo = tokens[tokenId];
        uint256 strategyId = tokenInfo.strategyId;

        userToNftIds[from].remove(tokenId);
        userToNftIds[to].add(tokenId);

        uint256 fromPositionId = tokenInfo.positionId;
        uint256 toPositionId = ++positionsIndex[strategyId][to];

        if (from != to) {
            ++positionsCount[strategyId][to];
            --positionsCount[strategyId][from];

            _addNewUserIfNeeded(strategyId, to);
        }

        tokenInfo.positionId = toPositionId;

        UserPosition storage fromUserPosition = positions[strategyId][from][
            fromPositionId
        ];
        UserPosition storage toUserPosition = positions[strategyId][to][
            toPositionId
        ];

        toUserPosition.tokenId = tokenId;
        toUserPosition.shares = fromUserPosition.shares;
        toUserPosition.lastStakedTimestamp = fromUserPosition
            .lastStakedTimestamp;
        toUserPosition.deposited = fromUserPosition.deposited;
        toUserPosition.created = true;

        fromUserPosition.shares = 0;
        fromUserPosition.deposited = 0;
        fromUserPosition.closed = true;

        emit PositionTransferred(from, to, tokenId);
    }

    /**
     * @dev Initializes the contract (unchained).
     * @param initialFeesReceiver A recipient of commissions.
     * @param initialERC721 An address of ERC-721 contract for positions.
     */
    function __ParallaxOrbital_init_unchained(
        address initialFeesReceiver,
        IERC721MintableBurnable initialERC721
    ) internal onlyInitializing onlyNonZeroAddress(initialFeesReceiver) {
        feesReceiver = initialFeesReceiver;
        ERC721 = initialERC721;
    }

    /**
     * @notice Allows to update position information at the time of deposit.
     * @param params Deposit params.
     * @param user An address of a user who makes deposit.
     * @param amount An amount of staked tokens (LPs).
     */
    function _updatePosition(
        DepositParams memory params,
        address user,
        uint256 amount
    ) private {
        uint256 strategyId = params.strategyId;
        address holder = params.holder;
        uint256 positionId = params.positionId;

        uint256 cap = strategies[strategyId].cap;
        if (cap > 0 && strategies[strategyId].totalStaked + amount > cap) {
            revert CapExceeded();
        }
        if (positionId == 0) {
            positionId = ++positionsIndex[strategyId][holder];
            ++positionsCount[strategyId][holder];

            _addNewUserIfNeeded(strategyId, holder);

            positions[strategyId][holder][positionId].created = true;

            _mintNft(holder, strategyId, positionId);
        } else {
            UserPosition memory positionToCheck = positions[strategyId][holder][
                positionId
            ];

            if (positionToCheck.closed == true) {
                positions[strategyId][holder][positionId].closed = false;

                _mintNft(holder, strategyId, positionId);
            } else {
                _onlyExistingPosition(positionToCheck);
            }
        }

        uint256 totalShares = strategies[strategyId].totalShares;
        uint256 shares = totalShares == 0
            ? amount
            : (amount * totalShares) / strategies[strategyId].totalStaked;

        UserPosition storage position = positions[strategyId][holder][
            positionId
        ];

        position.shares += shares;
        position.lastStakedTimestamp = uint32(block.timestamp);
        position.deposited += amount;

        strategies[strategyId].totalStaked += amount;
        strategies[strategyId].totalShares += shares;

        emit Staked(strategyId, positionId, user, holder, amount, shares);
    }

    /**
     * @notice Allows to update position information at the time of withdrawal.
     * @param params withdraw and compound params.
     * @return Staked by shares amount, earned by shares amount
     */
    function _withdraw(
        WithdrawAndCompoundParams memory params
    ) private returns (uint256, uint256) {
        uint256 strategyId = params.withdrawParams.strategyId;
        uint256 positionId = params.withdrawParams.positionId;
        uint256 shares = params.withdrawParams.shares;
        address receiver = params.withdrawParams.receiver;

        _onlyAfterLock(_msgSender(), strategyId, positionId);
        _onlyExistingStrategy(strategyId);
        _onlyValidWithdrawalSharesAmount(
            strategyId,
            _msgSender(),
            positionId,
            shares
        );

        if (params.toMakeCompound) {
            _compound(strategyId, params.compoundAmountsOutMin, false);
        }

        UserPosition storage position = positions[strategyId][_msgSender()][
            positionId
        ];

        _onlyExistingPosition(position);

        uint256 stakedBySharesAmount = _getStakedBySharesAmount(
            strategyId,
            shares
        );

        uint256 earnedBySharesAmount = _getEarnedBySharesAmount(
            strategyId,
            _msgSender(),
            positionId,
            shares
        );

        position.shares -= shares;
        position.deposited -= stakedBySharesAmount - earnedBySharesAmount;

        strategies[strategyId].totalStaked -= stakedBySharesAmount;
        strategies[strategyId].totalShares -= shares;

        uint256 actualFee = strategies[strategyId].fee;

        emit Withdrawn(
            strategyId,
            positionId,
            _msgSender(),
            receiver,
            stakedBySharesAmount,
            actualFee,
            shares
        );

        return (stakedBySharesAmount, earnedBySharesAmount);
    }

    /**
     * @notice Claims all rewards from an earning strategy and reinvests them to
     *         increase future rewards.
     * @param strategyId An ID of an earning strategy.
     * @param amountsOutMin An array of minimum values that will be received
     *                      during exchanges, withdrawals or deposits of
     *                      liquidity, etc. The length of the array is unique
     *                      for each earning strategy. See the specific earning
     *                      strategy documentation for more details.
     * @param toRevertIfFail A flag indicating whether the method should be
     *                       reverted if the swap in the harvest yields more
     *                       than the maximum slippage from the oracle.
     */
    function _compound(
        uint256 strategyId,
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) private {
        uint256 compounded = IParallaxStrategy(strategies[strategyId].strategy)
            .compound(amountsOutMin, toRevertIfFail);

        strategies[strategyId].totalStaked += compounded;
        strategies[strategyId].lastCompoundTimestamp = block.timestamp;

        emit Compounded(strategyId, block.number, _msgSender(), compounded);
    }

    /**
     * @notice Increases a number of user positions by 1. Also, adds a user to
     *         a strategy and parallax if it was his first position in a
     *         strategy and parallax.
     * @param strategyId An ID of an earning strategy.
     * @param user A user to check his positions count.
     */
    function _addNewUserIfNeeded(uint256 strategyId, address user) private {
        if (positionsCount[strategyId][user] == 1) {
            Strategy storage strategy = strategies[strategyId];

            ++strategy.usersCount;
            ++userAmountStrategies[user];

            strategyUsers[strategyId][strategy.usersCount] = user;
            strategyUsersToId[strategyId][user] = strategy.usersCount;

            if (userAmountStrategies[user] == 1) {
                ++usersCount;

                users[usersCount] = user;
                usersToId[user] = usersCount;
            }
        }
    }

    /**
     * @notice Performs various checks before depositing and compounding.
     * @param params A struct containing deposit and compound parameters.
     */
    function _beforeDeposit(DepositAndCompoundParams memory params) private {
        _onlyExistingStrategy(params.depositParams.strategyId);
        _isStrategyActive(params.depositParams.strategyId);

        if (params.toMakeCompound) {
            _compound(
                params.depositParams.strategyId,
                params.compoundAmountsOutMin,
                false
            );
        }
    }

    /**
     * @notice Adapts deposit parameters for IParallaxStrategy.
     * @param params A struct containing deposit parameters.
     * @param user Address of the user who makes deposit.
     * @return A struct containing adapted deposit parameters.
     */
    function _depositParamsAdapter(
        DepositParams memory params,
        address user
    )
        private
        pure
        onlyNonZeroAddress(params.holder)
        returns (IParallaxStrategy.DepositParams memory)
    {
        return
            IParallaxStrategy.DepositParams({
                amountsOutMin: params.amountsOutMin,
                paths: params.paths,
                user: user,
                holder: params.holder,
                positionId: params.positionId,
                amounts: params.amounts,
                data: params.data
            });
    }

    /**
     * @notice Adapts withdrawal parameters for IParallaxStrategy.
     * @param params A struct containing withdrawal parameters.
     * @param amount Amount to be withdrawn.
     * @param earned Earned amount.
     * @return A struct containing adapted withdrawal parameters.
     */
    function _withdrawParamsAdapter(
        WithdrawParams memory params,
        address holder,
        uint256 amount,
        uint256 earned
    )
        private
        pure
        onlyNonZeroAddress(params.receiver)
        returns (IParallaxStrategy.WithdrawParams memory)
    {
        return
            IParallaxStrategy.WithdrawParams({
                amountsOutMin: params.amountsOutMin,
                paths: params.paths,
                positionId: params.positionId,
                earned: earned,
                amount: amount,
                receiver: params.receiver,
                holder: holder,
                data: params.data
            });
    }

    /**
     * @notice Mints a new NFT and assigns it to the holder.
     * @param holder The address to receive the minted NFT.
     * @param strategyId The ID of the strategy associated with the NFT.
     * @param positionId The ID of the position associated with the NFT.
     */
    function _mintNft(
        address holder,
        uint256 strategyId,
        uint256 positionId
    ) private {
        uint256 tokenId = ++tokensCount;

        positions[strategyId][holder][positionId].tokenId = tokenId;

        tokens[tokenId].strategyId = strategyId;
        tokens[tokenId].positionId = positionId;

        ERC721.mint(holder, tokenId);

        userToNftIds[holder].add(tokenId);

        emit PositionCreated(tokenId, holder, block.number);
    }

    /**
     * @notice returns an amount of strategy final tokens (LPs) that are staked
     *         under a specified shares amount.
     * @param strategyId An ID of an earning strategy.
     * @param shares An amount of shares for which to calculate a staked
     *               amount of tokens.
     * @return An amount of tokens that are staked under the shares amount.
     */
    function _getStakedBySharesAmount(
        uint256 strategyId,
        uint256 shares
    ) private view returns (uint256) {
        uint256 totalShares = strategies[strategyId].totalShares;

        return
            totalShares == 0
                ? 0
                : (strategies[strategyId].totalStaked * shares) / totalShares;
    }

    /**
     * @notice Returns an amount of strategy final tokens (LPs) earned by the
     *         specified shares amount in a specified earning strategy.
     * @param strategyId An ID of an earning strategy.
     * @param user A holder of position.
     * @param shares An amount of shares for which to calculate an earned
     *               amount of tokens.
     * @param positionId An ID of a position.
     * @return An amount of earned by shares tokens (LPs).
     */
    function _getEarnedBySharesAmount(
        uint256 strategyId,
        address user,
        uint256 positionId,
        uint256 shares
    ) private view returns (uint256) {
        UserPosition memory position = positions[strategyId][user][positionId];

        uint256 stakedBySharesAmount = _getStakedBySharesAmount(
            strategyId,
            position.shares
        );

        uint256 totalEarnedAmount;
        if (position.deposited > stakedBySharesAmount) {
            totalEarnedAmount = 0;
        } else {
            totalEarnedAmount = stakedBySharesAmount - position.deposited;
        }

        uint256 earnedByShares = position.shares == 0
            ? 0
            : (totalEarnedAmount * shares) / position.shares;

        return earnedByShares;
    }

    /**
     * @notice Checks if a user can make a withdrawal. It depends on
     *         `lastStakedTimestamp` for a user and timelock duration of
     *          strategy. Fails if timelock is not finished.
     * @param user An user to check.
     * @param strategyId An ID of an earning strategy.
     * @param positionId An ID of a position.
     */
    function _onlyAfterLock(
        address user,
        uint256 strategyId,
        uint256 positionId
    ) private view {
        uint32 timeDifference = uint32(block.timestamp) -
            positions[strategyId][user][positionId].lastStakedTimestamp;
        uint32 timeLock = strategies[strategyId].timelock;

        if (timeDifference < timeLock) {
            revert OnlyAfterLock(timeLock - timeDifference);
        }
    }

    /**
     * @notice Сhecks if provided address is a contract address. Fails otherwise.
     * @param addressToCheck An address to check.
     */
    function _onlyContract(address addressToCheck) private view {
        if (!AddressUpgradeable.isContract(addressToCheck)) {
            revert OnlyContractAddress();
        }
    }

    /**
     * @notice Сhecks if there is strategy for the given ID. Fails otherwise.
     * @param strategyId An ID of an earning strategy.
     */
    function _onlyExistingStrategy(uint256 strategyId) private view {
        if (strategyId > strategiesCount || strategyId == 0) {
            revert OnlyExistStrategy();
        }
    }

    /**
     * @notice Сhecks if the position is open. Fails otherwise.
     * @param position A position info.
     */
    function _onlyExistingPosition(UserPosition memory position) private pure {
        if (position.created == false || position.closed == true) {
            revert OnlyExistPosition();
        }
    }

    /**
     * @notice Checks the upper bound of the withdrawal commission. Fee must be
     *         less than or equal to maximum possible fee. Fails otherwise.
     * @param strategy An address of an earning strategy.
     * @param fee A withdrawal commission amount.
     */
    function _onlyValidFee(address strategy, uint256 fee) private view {
        uint256 maxStrategyFee = IParallaxStrategy(strategy).getMaxFee();

        if (fee > maxStrategyFee) {
            revert OnlyValidFee();
        }
    }

    /**
     * @notice Checks if provided shares amount is less than or equal to user's
     *         shares balance. Fails otherwise.
     * @param strategyId An ID of an earning strategy.
     * @param positionId An ID of a position.
     * @param shares A fraction of the user's contribution.
     */
    function _onlyValidWithdrawalSharesAmount(
        uint256 strategyId,
        address user,
        uint256 positionId,
        uint256 shares
    ) private view {
        if (shares > positions[strategyId][user][positionId].shares) {
            revert OnlyValidWithdrawalSharesAmount();
        }
    }

    /**
     * @notice Checks if a strategy is active. Fails otherwise.
     * @param strategyId An ID of an earning strategy to check.
     */
    function _isStrategyActive(uint256 strategyId) private view {
        if (!strategies[strategyId].isActive) {
            revert OnlyActiveStrategy();
        }
    }
}