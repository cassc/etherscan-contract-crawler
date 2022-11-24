//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StakingAssist
 * @author gotbit
 */

import './Staking.sol';
import './StakingShadow.sol';

contract StakingAssist {
    Staking public staking;
    StakingShadow public stakingShadow;

    struct AdminInfo {
        Staking.StrategyParameters strategy;
        uint256 depositedAmountDeposits;
        uint256 requestedAmountDeposits;
        uint256 totalToClaim;
        uint256 depositStable;
        uint256 rewardStable;
    }

    struct TokenPrice {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint256 stableAmount;
    }

    constructor(Staking staking_, StakingShadow stakingShadow_) {
        staking = staking_;
        stakingShadow = stakingShadow_;
    }

    /// @dev returns list of strategies
    ///
    /// @return strategies list of strategies
    function getStrategies() public view returns (Staking.StrategyParameters[] memory) {
        string[] memory strategies = staking.getStrategyNames();
        uint256 length = strategies.length;

        Staking.StrategyParameters[]
            memory strategiesParameters_ = new Staking.StrategyParameters[](length);
        for (uint256 i; i < length; ++i) {
            (
                string memory name,
                bool isSafe,
                uint256 rateX1000,
                bool isPaused,
                uint256 withdrawId
            ) = staking.strategiesParameters(strategies[i]);
            strategiesParameters_[i] = Staking.StrategyParameters({
                name: name,
                isSafe: isSafe,
                rateX1000: rateX1000,
                isPaused: isPaused,
                withdrawId: withdrawId
            });
        }
        return strategiesParameters_;
    }

    /// @dev returns list of strategies
    /// @param strategyName name of strategy
    ///
    /// @return tokens list of available tokens
    function getStrategyTokens(string memory strategyName)
        external
        view
        returns (Staking.TokenParameters[] memory)
    {
        IERC20Metadata[] memory tokens = staking.getRegistredTokens();
        uint256 tokenLength = tokens.length;
        uint256 length;

        for (uint256 i; i < tokenLength; ++i)
            if (staking.isLegalToken(strategyName, tokens[i])) ++length;

        Staking.TokenParameters[] memory tokensParameters = new Staking.TokenParameters[](
            length
        );
        uint256 realIndex;
        for (uint256 i; i < tokenLength; ++i)
            if (staking.isLegalToken(strategyName, tokens[i])) {
                tokensParameters[realIndex] = staking.getTokenParameters(tokens[i]);
                ++realIndex;
            }
        return tokensParameters;
    }

    /// @dev returns list of admin info per strategy
    ///
    /// @return adminInfos list of admin info per strategy
    function getAdminInfo(uint256 from, uint256 to)
        external
        view
        returns (AdminInfo[] memory)
    {
        uint256 totalToClaim = _totalToClaim();

        Staking.StrategyParameters[] memory strategies = getStrategies();
        uint256 length = strategies.length;
        AdminInfo[] memory adminInfos = new AdminInfo[](length);

        for (uint256 i; i < length; ++i) {
            string memory strategyName = strategies[i].name;

            (, , uint256 depositedInStableTokens) = staking.calculateWithdrawAmountAdmin(
                strategyName
            );
            (, , uint256 rewards) = stakingShadow.calculateWithdrawAmountAdminRewards(
                strategyName
            );
            adminInfos[i] = AdminInfo({
                strategy: strategies[i],
                depositedAmountDeposits: _amountOfDeposits(
                    strategyName,
                    Staking.Status.DEPOSITED,
                    from,
                    to
                ),
                requestedAmountDeposits: _amountOfDeposits(
                    strategyName,
                    Staking.Status.REQUESTED,
                    from,
                    to
                ),
                totalToClaim: totalToClaim,
                depositStable: depositedInStableTokens,
                rewardStable: rewards
            });
        }
        return adminInfos;
    }

    /// @dev returns list of deposits of user with `status` from `offset` to `offset` + `limit`
    /// @param user address of user
    /// @param status status of deposit (Status.NULL returns all deposit)
    /// @param offset start index
    /// @param limit length of list
    ///
    /// @return deposits list of deposits of user with status
    function getUserDepositsStatus(
        address user,
        Staking.Status status,
        uint256 offset,
        uint256 limit
    ) external view returns (Staking.Deposit[] memory) {
        uint256[] memory userDeposits = staking.getUserDeposits(user);
        Staking.Deposit[] memory deposits_ = new Staking.Deposit[](limit);

        if (status == Staking.Status.NULL) {
            for (uint256 i; i < limit; ++i) {
                if (userDeposits.length <= offset + i) break;
                deposits_[i] = staking.getDeposit(userDeposits[offset + i]);
            }
        } else {
            // find real offset (takes count the status)
            uint256 realOffset = 0;
            for (uint256 i; i < userDeposits.length; ++i) {
                if (realOffset >= offset) break; // edge case: offset == 0
                if (staking.getDeposit(userDeposits[i]).status == status) ++realOffset;
            }

            uint256 realIndex = 0;
            for (uint256 i; i < userDeposits.length; ++i) {
                if (realOffset + i >= userDeposits.length || i >= limit) break;
                if (staking.getDeposit(userDeposits[realOffset + i]).status == status)
                    deposits_[realIndex++] = staking.getDeposit(
                        userDeposits[realOffset + i]
                    );
            }
        }
        return deposits_;
    }

    /// @dev returns list of history with `historyType` from `offset` to `offset` + `limit`
    /// @param historyType status of deposit (Status.NULL returns all deposit)
    /// @param offset start index
    /// @param limit length of list
    ///
    /// @return history list of history with type
    function getHistoryType(
        Staking.HistoryType historyType,
        uint256 offset,
        uint256 limit
    ) external view returns (Staking.History[] memory) {
        uint256 hisotyLengt = staking.getHistoryLength();
        Staking.History[] memory history_ = new Staking.History[](limit);

        if (historyType == Staking.HistoryType.NULL) {
            for (uint256 i; i < limit; ++i) {
                if (hisotyLengt <= offset + i) break;
                history_[i] = staking.getHistoryById(offset + i);
            }
        } else {
            // find real offset (takes count the type)
            uint256 realOffset = 0;
            for (uint256 i; i < hisotyLengt; ++i) {
                if (realOffset >= offset) break; // edge case: offset == 0
                if (staking.getHistoryById(i).historyType == historyType) ++realOffset;
            }

            uint256 realIndex = 0;
            for (uint256 i; i < hisotyLengt; ++i) {
                if (realOffset + i >= hisotyLengt || i >= limit) break;
                if (staking.getHistoryById(realOffset + i).historyType == historyType)
                    history_[realIndex++] = staking.getHistoryById(realOffset + i);
            }
        }
        return history_;
    }

    /// @dev returns list of tokens' prices
    ///
    /// @return tokenPrices list of tokens' prices
    function getTokenPrices() external view returns (TokenPrice[] memory) {
        IERC20Metadata[] memory tokens = staking.getRegistredTokens();
        uint256 length = tokens.length;
        TokenPrice[] memory tokenPrices = new TokenPrice[](length);
        for (uint256 i; i < length; ++i) {
            if (address(tokens[i]) == address(staking.stableToken())) {
                tokenPrices[i] = TokenPrice({
                    token: address(tokens[i]),
                    name: tokens[i].name(),
                    symbol: tokens[i].symbol(),
                    decimals: tokens[i].decimals(),
                    stableAmount: 10**tokens[i].decimals()
                });
            } else {
                uint256[] memory amounts = staking.router().getAmountsOut(
                    10**tokens[i].decimals(),
                    staking.getTokenParameters(tokens[i]).swapPath
                );
                tokenPrices[i] = TokenPrice({
                    token: address(tokens[i]),
                    name: tokens[i].name(),
                    symbol: tokens[i].symbol(),
                    decimals: tokens[i].decimals(),
                    stableAmount: amounts[amounts.length - 1]
                });
            }
        }
        return tokenPrices;
    }

    /// @dev returns deposit amount in token for strategy
    /// @param strategyName name of strategy
    /// @param token address of token
    ///
    /// @return deposit amount of deposits in token
    /// @return reward amount of rewards in token
    function getDepositAmount(string memory strategyName, address token)
        external
        view
        returns (uint256 deposit, uint256 reward)
    {
        uint256 depositsLength = staking.getDepositsLength();

        for (uint256 i; i < depositsLength; ++i) {
            Staking.Deposit memory _deposit = staking.getDeposit(i);
            if (!_stringEq(_deposit.strategyName, strategyName)) continue;
            if (address(_deposit.token) != token) continue;
            if (_deposit.status != Staking.Status.DEPOSITED) continue;

            deposit += _deposit.deposited;
            reward += _deposit.reward;
        }
    }

    /// @dev returns amount of stable tokens to claim by admin
    ///
    /// @return totalStableAmount amount of stable token can be claimed by admin
    function _totalToClaim() internal view returns (uint256) {
        IERC20Metadata[] memory registeredTokens = staking.getRegistredTokens();

        uint256 length = registeredTokens.length;
        uint256 totalStableAmount = 0;
        for (uint256 i; i < length; i++) {
            IERC20Metadata token = registeredTokens[i];
            uint256 tokenDeposit = staking.deposited(token);
            if (tokenDeposit == 0) continue;

            uint256 stableAmount = 0;
            if (address(token) == address(staking.stableToken())) {
                stableAmount = tokenDeposit;
            } else {
                stableAmount = staking.router().getAmountsOut(
                    tokenDeposit,
                    staking.getTokenParameters(token).swapPath
                )[staking.getTokenParameters(token).swapPath.length - 1];
            }
            totalStableAmount += stableAmount;
        }
        return totalStableAmount;
    }

    /// @dev returns amount of deposit in strategy with status
    /// @param strategyName name of strategy
    /// @param status status of deposit
    ///
    /// @return amount of deposits
    function _amountOfDeposits(
        string memory strategyName,
        Staking.Status status,
        uint256 from,
        uint256 to
    ) internal view returns (uint256) {
        uint256 amount;

        uint256 depositsLength = staking.getDepositsLength();
        if (to > depositsLength) to = depositsLength;
        require(from < to);

        for (uint256 i = from; i < to; ++i) {
            Staking.Deposit memory _deposit = staking.getDeposit(i);
            if (
                _deposit.status == status &&
                _stringEq(_deposit.strategyName, strategyName)
            ) ++amount;
        }
        return amount;
    }

    /// @dev compare two strings
    /// @param s1 first string
    /// @param s2 second string
    ///
    /// @return equality of strings
    function _stringEq(string memory s1, string memory s2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function getDeposits(uint256 from, uint256 to)
        external
        view
        returns (Staking.Deposit[] memory)
    {
        uint256 length = staking.getDepositsLength();
        if (to > length) to = length;

        require(from < to, 'from < to');

        Staking.Deposit[] memory _deposits = new Staking.Deposit[](to - from);

        for (uint256 i = from; i < to; ++i) {
            _deposits[i] = staking.getDeposit(i);
        }
        return _deposits;
    }

    function getHistory(uint256 from, uint256 to)
        external
        view
        returns (Staking.History[] memory)
    {
        uint256 length = staking.getHistoryLength();
        if (to > length) to = length;

        require(from < to, 'from < to');

        Staking.History[] memory _histories = new Staking.History[](to - from);

        for (uint256 i = from; i < to; ++i) {
            _histories[i] = staking.getHistoryById(i);
        }
        return _histories;
    }
}