//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StakingShadow
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {IPancakeRouter02} from 'pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol';
import './utils/IWETH.sol';

contract StakingShadow is Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;
    using Address for address;

    struct TokenParameters {
        IERC20Metadata token;
        address[] swapPath;
        address[] reverseSwapPath;
        string symbol;
        string name;
        uint256 decimals;
    }

    struct StrategyParameters {
        string name;
        bool isSafe;
        uint256 rateX1000;
        bool isPaused;
        uint256 withdrawId;
    }

    struct Bank {
        bool fulfilled;
        bool fullDeposited;
        bool fullReward;
        uint256 deposited;
        uint256 reward;
        // uint256 updateTimestamp;
    }

    struct TokenManager {
        uint256 deposited;
        uint256 reward;
        Bank bank;
    }

    enum Status {
        NULL, // NULL
        DEPOSITED, // User deposits tokens
        REQUESTED, // User requests withdraw
        WITHDRAWED // User withdrawed tokens
    }

    struct Deposit {
        uint256 id;
        string strategyName;
        address user;
        IERC20Metadata token;
        uint256 deposited;
        uint256 reward;
        uint256 timestamp;
        uint256 withdrawId;
        uint256 period;
        uint256 endTimestamp;
        uint256 lastRewardId;
        Status status;
    }

    enum HistoryType {
        NULL,
        CLAIM,
        FULFILL,
        PURCHASE,
        REWARD
    }

    struct History {
        HistoryType historyType;
        uint256 timestamp;
        address user;
        uint256 stableAmount;
        string strategyName;
    }
    /// duplication storage capacity ---------------

    // config
    IERC20 private stableToken;
    IPancakeRouter02 private router;

    uint256[3] private gap0;

    mapping(IERC20Metadata => TokenParameters) private tokensParameters;
    mapping(string => StrategyParameters) private strategiesParameters;
    mapping(uint256 => mapping(string => mapping(IERC20Metadata => TokenManager)))
        private _tokenManager;

    uint256[2] private gap1;

    mapping(string => mapping(IERC20Metadata => uint256)) private totalRewards;
    mapping(uint256 => mapping(string => mapping(IERC20Metadata => uint256[2])))
        private _rewardFulfillRatesByIds;
    uint256 private _currentRewardId;
    uint256 lastRewardsFulfillTimestamp;
    uint256 claimOffset = 5 days;

    uint256 private gap2;

    IERC20Metadata[] private _registeredTokens;

    uint256 private gap3;

    Deposit[] public _deposits;

    uint256 private gap4;

    mapping(string => uint256) public stableTokenBank;
    uint256 private slippageX1000 = 20;
    History[] private _history;

    /// -------------------------------------------

    event FulfilledDeposited(
        uint256 indexed timestamp,
        string indexed strategyName,
        uint256 withdrawId
    );
    event FulfilledRewards(uint256 indexed timestamp, string indexed strategyName);

    /// @dev fulfills pending requests for rewards (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    /// @param amountMaxInStable max amount that can be transfer from admin
    function fulfillDeposited(string memory strategyName, uint256 amountMaxInStable)
        external
    {
        require(amountMaxInStable > 0, 'max = 0');
        uint256 withdrawId = strategiesParameters[strategyName].withdrawId;
        (
            uint256[] memory depositedInTokens,
            uint256[] memory depositedInStableTokenForTokens,
            uint256 depositedInStableTokens
        ) = calculateWithdrawAmountAdmin(strategyName);

        uint256 length = _registeredTokens.length;
        uint256 totalStableTokens = amountMaxInStable;

        require(depositedInStableTokens > 0, 'Nothing fulfill');
        stableToken.approve(address(router), amountMaxInStable);

        if (
            strategiesParameters[strategyName].isSafe ||
            depositedInStableTokens <= amountMaxInStable
        ) {
            require(depositedInStableTokens <= amountMaxInStable, 'need > max');
            totalStableTokens = depositedInStableTokens;
            stableToken.safeTransferFrom(
                msg.sender,
                address(this),
                depositedInStableTokens
            );

            for (uint256 i; i < length; i++) {
                IERC20Metadata token = _registeredTokens[i];
                TokenManager storage tm = _tokenManager[withdrawId][strategyName][token];

                tm.bank.deposited = depositedInTokens[i];

                uint256 amountOut = tm.bank.deposited;
                uint256 amountInMax = depositedInStableTokenForTokens[i];
                if (address(token) != address(stableToken) && amountOut != 0) {
                    uint256[] memory amounts = router.swapTokensForExactTokens(
                        amountOut,
                        amountInMax,
                        tokensParameters[token].reverseSwapPath,
                        address(this),
                        block.timestamp
                    );
                    uint256 left = amountInMax - amounts[0];
                    if (left > 0) {
                        stableToken.safeTransfer(msg.sender, left);
                        totalStableTokens -= left;
                    }
                }

                tm.bank.fulfilled = true;
                tm.bank.fullDeposited = true;
            }

            _history.push(
                History({
                    historyType: HistoryType.FULFILL,
                    timestamp: block.timestamp,
                    user: msg.sender,
                    stableAmount: totalStableTokens,
                    strategyName: strategyName
                })
            );
        } else {
            if (depositedInStableTokens <= amountMaxInStable) {
                stableToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    depositedInStableTokens
                );
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];
                    TokenManager storage tm = _tokenManager[withdrawId][strategyName][
                        token
                    ];
                    tm.bank.deposited = depositedInTokens[i];

                    uint256 amountOut = tm.bank.deposited;
                    uint256 amountInMax = depositedInStableTokenForTokens[i];

                    if (address(token) != address(stableToken) && amountOut != 0) {
                        uint256[] memory amounts = router.swapTokensForExactTokens(
                            amountOut,
                            amountInMax,
                            tokensParameters[token].reverseSwapPath,
                            address(this),
                            block.timestamp
                        );
                        uint256 left = amountInMax - amounts[0];
                        if (left > 0) {
                            stableToken.safeTransfer(msg.sender, left);
                            totalStableTokens -= left;
                        }
                    }

                    tm.bank.fulfilled = true;
                    tm.bank.fullDeposited = true;
                }
            } else {
                stableToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    amountMaxInStable
                );
                uint256 lessDepositedInStable = amountMaxInStable;
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];
                    TokenManager storage tm = _tokenManager[withdrawId][strategyName][
                        token
                    ];

                    tm.bank.deposited =
                        (lessDepositedInStable * depositedInTokens[i]) /
                        depositedInStableTokens;

                    uint256 amountOut = tm.bank.deposited;
                    uint256 amountInMax = (lessDepositedInStable *
                        depositedInStableTokenForTokens[i]) / depositedInStableTokens;

                    if (address(token) != address(stableToken) && amountOut != 0) {
                        uint256[] memory amounts = router.swapTokensForExactTokens(
                            amountOut,
                            amountInMax,
                            tokensParameters[token].reverseSwapPath,
                            address(this),
                            block.timestamp
                        );
                        uint256 left = amountInMax - amounts[0];
                        if (left > 0) {
                            stableToken.safeTransfer(msg.sender, left);
                            totalStableTokens -= left;
                        }
                    }

                    tm.bank.fulfilled = true;
                    tm.bank.fullDeposited = false;
                }
            }
        }

        _history.push(
            History({
                historyType: HistoryType.FULFILL,
                timestamp: block.timestamp,
                user: msg.sender,
                stableAmount: totalStableTokens,
                strategyName: strategyName
            })
        );

        strategiesParameters[strategyName].withdrawId++;

        emit FulfilledDeposited(
            block.timestamp,
            strategyName,
            strategiesParameters[strategyName].withdrawId - 1
        );
    }

    /// @dev fulfills pending requests for rewards (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    /// @param amountMaxInStable max amount that can be transfer from admin
    function fulfillRewards(string memory strategyName, uint256 amountMaxInStable)
        external
    {
        require(amountMaxInStable > 0, 'max = 0');
        (
            uint256[] memory rewardsInTokens,
            uint256[] memory rewardsInStable,
            uint256 _totalRewards
        ) = calculateWithdrawAmountAdminRewards(strategyName);

        uint256 length = _registeredTokens.length;
        uint256 totalStableTokens = amountMaxInStable;

        require(_totalRewards > 0, 'Nothing fulfill');
        stableToken.approve(address(router), amountMaxInStable);

        if (
            strategiesParameters[strategyName].isSafe ||
            _totalRewards <= amountMaxInStable
        ) {
            require(_totalRewards <= amountMaxInStable, 'need > max');

            stableToken.safeTransferFrom(msg.sender, address(this), _totalRewards);

            for (uint256 i; i < length; i++) {
                IERC20Metadata token = _registeredTokens[i];

                uint256 amountOut = rewardsInTokens[i];
                uint256 amountInMax = rewardsInStable[i];
                if (address(token) != address(stableToken) && amountOut != 0) {
                    uint256[] memory amounts = router.swapTokensForExactTokens(
                        amountOut,
                        amountInMax,
                        tokensParameters[token].reverseSwapPath,
                        address(this),
                        block.timestamp
                    );
                    uint256 left = amountInMax - amounts[0];
                    if (left > 0) {
                        stableToken.safeTransfer(msg.sender, left);
                        totalStableTokens -= left;
                    }
                }
                _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][0] = 1;
                _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][1] = 1;
            }
        } else {
            if (_totalRewards <= amountMaxInStable) {
                stableToken.safeTransferFrom(msg.sender, address(this), _totalRewards);
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];

                    uint256 amountOut = rewardsInTokens[i];
                    uint256 amountInMax = rewardsInStable[i];

                    if (address(token) != address(stableToken) && amountOut != 0) {
                        uint256[] memory amounts = router.swapTokensForExactTokens(
                            amountOut,
                            amountInMax,
                            tokensParameters[token].reverseSwapPath,
                            address(this),
                            block.timestamp
                        );
                        uint256 left = amountInMax - amounts[0];
                        if (left > 0) {
                            stableToken.safeTransfer(msg.sender, left);
                            totalStableTokens -= left;
                        }
                    }
                    _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][
                        0
                    ] = 1;
                    _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][
                        1
                    ] = 1;
                }
            } else {
                stableToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    amountMaxInStable
                );
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];

                    uint256 amountOut = (rewardsInTokens[i] * amountMaxInStable) /
                        _totalRewards;
                    uint256 amountInMax = (rewardsInStable[i] * amountMaxInStable) /
                        _totalRewards;

                    if (address(token) != address(stableToken) && amountOut != 0) {
                        uint256[] memory amounts = router.swapTokensForExactTokens(
                            amountOut,
                            amountInMax,
                            tokensParameters[token].reverseSwapPath,
                            address(this),
                            block.timestamp
                        );
                        uint256 left = amountInMax - amounts[0];
                        if (left > 0) {
                            stableToken.safeTransfer(msg.sender, left);
                            totalStableTokens -= left;
                        }
                    }
                    _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][
                        0
                    ] = amountMaxInStable;
                    _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][
                        1
                    ] = _totalRewards;
                }
            }
        }
        _currentRewardId++;
        lastRewardsFulfillTimestamp = block.timestamp;
        _history.push(
            History({
                historyType: HistoryType.REWARD,
                timestamp: block.timestamp,
                user: msg.sender,
                stableAmount: totalStableTokens,
                strategyName: strategyName
            })
        );
        emit FulfilledRewards(block.timestamp, strategyName);
    }

    /// @dev calculates withdraw amount for class for admin (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    ///
    /// @return depositedInTokens deposited amount in tokens
    /// @return depositedInStableTokenForTokens deposited amount in stable token for token
    /// @return depositedInStableTokens deposited amount in stable token
    function calculateWithdrawAmountAdmin(string memory strategyName)
        public
        view
        returns (
            uint256[] memory depositedInTokens,
            uint256[] memory depositedInStableTokenForTokens,
            uint256 depositedInStableTokens
        )
    {
        depositedInTokens = new uint256[](_registeredTokens.length);
        depositedInStableTokenForTokens = new uint256[](_registeredTokens.length);

        for (uint256 i; i < _registeredTokens.length; i++) {
            IERC20Metadata token = _registeredTokens[i];
            TokenManager memory tm = _tokenManager[
                strategiesParameters[strategyName].withdrawId
            ][strategyName][token];

            uint256 depositedInStableTokenForToken;
            if (address(token) == address(stableToken)) {
                depositedInStableTokenForToken = tm.deposited;
            } else {
                uint256 lastIndex = tokensParameters[token].swapPath.length - 1;

                if (tm.deposited != 0)
                    depositedInStableTokenForToken = _addSlippage(
                        router.getAmountsOut(
                            tm.deposited,
                            tokensParameters[token].swapPath
                        )[lastIndex]
                    );
            }
            depositedInTokens[i] = tm.deposited;
            depositedInStableTokenForTokens[i] = depositedInStableTokenForToken;
            depositedInStableTokens += depositedInStableTokenForToken;
        }
    }

    /// @dev calculates withdraw rewards amount for class for admin (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    ///
    /// @return rewardsInTokens
    /// @return rewardsInStable
    /// @return _totalRewards
    function calculateWithdrawAmountAdminRewards(string memory strategyName)
        public
        view
        returns (
            uint256[] memory rewardsInTokens,
            uint256[] memory rewardsInStable,
            uint256 _totalRewards
        )
    {
        rewardsInTokens = new uint256[](_registeredTokens.length);
        rewardsInStable = new uint256[](_registeredTokens.length);

        for (uint256 i; i < _registeredTokens.length; i++) {
            IERC20Metadata token = _registeredTokens[i];
            uint256 tokenRewards = totalRewards[strategyName][token];

            uint256 rewardsInStableTokenForTokens;
            if (address(token) == address(stableToken)) {
                rewardsInStableTokenForTokens = tokenRewards;
            } else {
                uint256 lastIndex = tokensParameters[token].swapPath.length - 1;

                if (tokenRewards != 0)
                    rewardsInStableTokenForTokens = _addSlippage(
                        router.getAmountsOut(
                            tokenRewards,
                            tokensParameters[token].swapPath
                        )[lastIndex]
                    );
            }
            rewardsInTokens[i] = tokenRewards;
            rewardsInStable[i] = rewardsInStableTokenForTokens;
            _totalRewards += rewardsInStableTokenForTokens;
        }
    }

    /// @dev returns bool flag can be fulfilled deposit from bank
    /// @param depositId id of deposit
    ///
    /// @return can bool flag
    /// @return stableTokenTotal amount of stable tokens to swap
    /// @return totalAmount amount of token to fulfill deposit
    function canWithdraw(uint256 depositId)
        public
        view
        returns (
            bool can,
            uint256 stableTokenTotal,
            uint256 totalAmount
        )
    {
        Deposit memory deposit_ = _deposits[depositId];

        totalAmount = deposit_.deposited;

        // require(totalAmount > 0, 'totalAmount = 0');

        if (address(deposit_.token) == address(stableToken))
            return (
                totalAmount <= stableTokenBank[deposit_.strategyName],
                totalAmount,
                totalAmount
            );

        // else
        uint256[] memory amounts = router.getAmountsOut(
            totalAmount,
            tokensParameters[deposit_.token].swapPath
        );
        stableTokenTotal = _addSlippage(amounts[amounts.length - 1]);
        return (
            stableTokenTotal <= stableTokenBank[deposit_.strategyName],
            stableTokenTotal,
            totalAmount
        );
    }

    /// @dev returns value plus slippage
    /// @param value value for convertion
    ///
    /// @return slippageValue value after convertions
    function _addSlippage(uint256 value) internal view returns (uint256 slippageValue) {
        return (value * (1000 + slippageX1000)) / 1000;
    }
}