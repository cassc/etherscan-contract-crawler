//SPDX-License-Identifier: MIT

import "../extensions/Timelock.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity 0.8.15;

interface IParallax {
    /**
     * @notice Represents a single strategy with its relevant data.
     */
    struct Strategy {
        uint256 fee;
        uint256 totalStaked;
        uint256 totalShares;
        uint256 lastCompoundTimestamp;
        uint256 cap;
        uint256 rewardPerBlock;
        uint256 rewardPerShare;
        uint256 lastUpdatedBlockNumber;
        address strategy;
        uint32 timelock;
        bool isActive;
        IERC20Upgradeable rewardToken;
        uint256 usersCount;
        address incentivization;
    }

    /**
     * @notice Represents a single user's position in a strategy.
     */
    struct UserPosition {
        uint256 tokenId;
        uint256 shares;
        uint256 deposited;
        uint256 lastStakedBlockNumber;
        uint256 reward;
        uint256 former;
        uint32 lastStakedTimestamp;
        bool created;
        bool closed;
    }

    /**
     * @notice Represents a single user's position in a strategy.
     * @dev holder address can be obtained from contract erc721
     */
    struct TokenInfo {
        uint256 strategyId;
        uint256 positionId;
    }

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param positionId - an ID of a position.
     * @param user - a user who makes a staking.
     * @param amount - amount of staked tokens.
     * @param shares - fraction of the user's contribution
     * (calculated from the deposited amount and the total number of tokens)
     */
    event Staked(
        uint256 indexed strategyId,
        uint256 indexed positionId,
        address user,
        address indexed holder,
        uint256 amount,
        uint256 shares
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param positionId - an ID of a position.
     * @param user - a user who makes a withdrawal.
     * @param amount - amount of staked tokens (calculated from input shares).
     * @param shares - fraction of the user's contribution.
     */
    event Withdrawn(
        uint256 indexed strategyId,
        uint256 indexed positionId,
        address indexed user,
        address receiver,
        uint256 amount,
        uint256 currentFee,
        uint256 shares
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param blockNumber - block number in which the compound was made.
     * @param user - a user who makes compound.
     * @param amount - amount of staked tokens (calculated from input shares).
     */
    event Compounded(
        uint256 indexed strategyId,
        uint256 indexed blockNumber,
        address indexed user,
        uint256 amount
    );

    /**
     * @param positionId - an ID of a position.
     * @param user - a user for whom the position was created.
     * @param blockNumber - block number in which the position was created.
     */
    event PositionCreated(
        uint256 indexed positionId,
        address indexed user,
        uint256 blockNumber
    );

    /**
     * @param from - who sent the position.
     * @param to - recipient.
     * @param tokenId - id of recipient's position.
     */
    event PositionTransferred(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );

    /**
     * @dev Whitelists a new token that can be accepted as the token for
     *      deposits and withdraws. Can only be called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token An address of a new token to add.
     */
    function addToken(uint256 strategyId, address token) external;

    /**
     * @dev Removes a token from a whitelist of tokens that can be accepted as
     *      the tokens for deposits and withdraws. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token A token to remove.
     */
    function removeToken(uint256 strategyId, address token) external;

    /**
     * @dev Registers a new earning strategy on this contract. An earning
     *      strategy must be deployed before the calling of this method. Can
     *      only be called by the current owner.
     * @param strategy An address of a new earning strategy that should be added.
     * @param incentivization The address of the Incentivization contract.
     * @param timelock A number of seconds during which users can't withdraw
     *                 their deposits after last deposit. Applies only for
     *                 earning strategy that is adding. Can be updated later.
     * @param cap A cap for the amount of deposited LP tokens.
     * @param initialFee A fees that will be applied for earning strategy that
     *                    is adding. Currently only withdrawal fee is supported.
     *                    Applies only for earning strategy that is adding. Can
     *                    be updated later. Each fee should contain 2 decimals:
     *                    5 = 0.05%, 10 = 0.1%, 100 = 1%, 1000 = 10%.
     */
    function addStrategy(
        address strategy,
        address incentivization,
        uint32 timelock,
        uint256 cap,
        uint256 initialFee,
        bool isActive
    ) external;

    /**
     * @dev Sets a new receiver for fees from all earning strategies. Can only
     *      be called by the current owner.
     * @param newFeesReceiver A wallet that will receive fees from all earning
     *                        strategies.
     */
    function setFeesReceiver(address newFeesReceiver) external;

    /**
     * @dev Sets the address of the Incentivization contract.
     * @param newIncentivization The new address of the Incentivization contract.
     */
    function setIncentivization(
        uint256 strategyId,
        address newIncentivization
    ) external;

    /**
     * @dev Sets a new fees for an earning strategy. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param newFee Fee that will be applied for earning strategy. Fee should contain
     *                2 decimals: 5 = 0.05%, 10 = 0.1%, 100 = 1%, 1000 = 10%.
     */
    function setFee(uint256 strategyId, uint256 newFee) external;

    /**
     * @dev Sets a timelock for withdrawals (in seconds). Timelock - period
     *      during which user is not able to make a withdrawal after last
     *      successful deposit. Can only be called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param timelock A new timelock for withdrawals (in seconds).
     */
    function setTimelock(uint256 strategyId, uint32 timelock) external;

    /**
     * @dev Sets a new cap for the amount of deposited LP tokens. A new cap must
     *      be more or equal to the amount of staked LP tokens. Can only be
     *      called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param cap A new cap for the amount of deposited LP tokens which will be
     *            applied for earning strategy.
     */
    function setCap(uint256 strategyId, uint256 cap) external;

    /**
     * @dev Sets a value for an earning strategy (in reward token) after which
     *      compound must be executed. The compound operation is performed
     *      during every deposit and withdrawal. And sometimes there may not be
     *      enough reward tokens to complete all the exchanges and liquidity
     *      additions. As a result, deposit and withdrawal transactions may
     *      fail. To avoid such a problem, this value is provided. And if the
     *      number of rewards is even less than it, compound does not occur.
     *      As soon as there are more of them, a compound immediately occurs in
     *      time of first deposit or withdrawal. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param compoundMinAmount A value in reward token after which compound
     *                          must be executed.
     */
    function setCompoundMinAmount(
        uint256 strategyId,
        uint256 compoundMinAmount
    ) external;

    /**
     * @notice Setups a strategy status. Sets permission or prohibition for
     *         depositing funds on the strategy. Can only be called by the
     *         current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param flag A strategy status. `false` - not active, `true` - active.
     */
    function setStrategyStatus(uint256 strategyId, bool flag) external;

    /// @notice The view method for getting current feesReceiver.
    function feesReceiver() external view returns (address);

    /**
     * @notice The view method for getting current withdrawal fee by strategy.
     * @param strategy An address of a strategy.
     * @return Withdrawal fee.
     **/
    function getFee(address strategy) external view returns (uint256);

    /** @notice Returns the ID of the NFT owned by the specified user at the
     *           given index.
     *  @param user The address of the user who owns the NFT.
     *  @param index The index of the NFT to return.
     *  @return The ID of the NFT at the given index, owned by the specified
     *          user.
     */
    function getNftByUserAndIndex(
        address user,
        uint256 index
    ) external view returns (uint256);

    /** @notice Returns the positionInfo
     *   @param strategyId - an ID of an earning strategy.
     *   @param user The address of position holder
     *   @param positionId - id of the position.
     */
    function getPositionInfo(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view returns (UserPosition memory);

    /**
     * @notice The view method to check if the token is in the whitelist.
     * @param strategy An address of a strategy.
     * @param token An address of a token to check.
     * @return Boolean flag.
     **/
    function tokensWhitelist(
        address strategy,
        address token
    ) external view returns (bool);

    /**
     * @notice Adds a new transaction to the execution queue. Can only be called
     *         by the current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     * @return A transaction hash.
     */
    function addTransaction(
        Timelock.Transaction memory transaction
    ) external returns (bytes32);

    /**
     * @notice Removes a transaction from the execution queue. Can only be
     *         called by the current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     */
    function removeTransaction(
        Timelock.Transaction memory transaction
    ) external;

    /**
     * @notice Executes a transaction from the queue. Can only be called by the
     *         current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     * @return Returned data.
     */
    function executeTransaction(
        Timelock.Transaction memory transaction
    ) external returns (bytes memory);

    /**
     * @notice Returns an amount of strategy final tokens (LPs) that are staked
     *         under a specified shares amount. Can be called by anyone.
     * @dev Staked == deposited + earned.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param shares An amount of shares for which to calculate a staked
     *               amount of tokens.
     * @return An amount of tokens that are staked under the shares amount.
     */
    function getStakedBySharesAmount(
        uint256 strategyId,
        uint256 shares
    ) external view returns (uint256);

    /**
     * @notice Returns an amount of strategy final (LPs) tokens earned by the
     *         specified shares amount in a specified earning strategy. Can be
     *         called by anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param user A holder of position.
     * @param positionId An ID of a position.
     * @param shares An amount of shares for which to calculate an earned
     *               amount of tokens.
     * @return An amount of earned by shares tokens.
     */
    function getEarnedBySharesAmount(
        uint256 strategyId,
        address user,
        uint256 positionId,
        uint256 shares
    ) external view returns (uint256);

    /**
     * @notice Returns an amount of strategy final tokens (LPs) earned by the
     *         specified user in a specified earning strategy. Can be called by
     *         anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param user A user to check earned tokens amount.
     * @param positionId An ID of a position. Must be an existing position ID.
     * @return An amount of earned by user tokens.
     */
    function getEarnedByUserAmount(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view returns (uint256);

    /**
     * @dev Withdraws an ETH token that accidentally ended up on an earning
     *      strategy contract and cannot be used in any way. Can only be called
     *      by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param amount A number of tokens to withdraw from this contract.
     * @param receiver A wallet that will receive withdrawing tokens.
     */
    function rescueNativeToken(
        uint256 strategyId,
        uint256 amount,
        address receiver
    ) external;

    /**
     * @dev Withdraws an ERC-20 token that accidentally ended up on an earning
     *      strategy contract and cannot be used in any way. Can only be called
     *      by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token A number of tokens to withdraw from this contract.
     * @param amount A number of tokens to withdraw from this contract.
     * @param receiver A wallet that will receive withdrawing tokens.
     */
    function rescueERC20Token(
        uint256 strategyId,
        address token,
        uint256 amount,
        address receiver
    ) external;

    /**
     * @notice Transfer position. Can be called by obly ERC721.
     * @param from A wallet from which token (user position) will be transferred.
     * @param to A wallet to which token (user position) will be transferred.
     * @param tokenId An ID of token to transfer.
     */
    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}