// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../strategies/IBonfireStrategicCalls.sol";
import "../strategies/IBonfireStrategyAccumulator.sol";

/*
 * Strategies can be suggested by anyone, but owner needs to add them.
 * Strategies are dedicated to a single Token and need to implement
 * IBonfireStrategicCalls interface.
 */

contract BonfireStrategyAccumulator is IBonfireStrategyAccumulator, Ownable {
    mapping(address => address[]) public strategies;
    address[] public tokens;

    event StrategySuggestionEvent(
        address indexed strategy,
        address indexed sender,
        address indexed token
    );
    event StrategyUpdate(
        address indexed strategy,
        address indexed token,
        uint112 indexed index,
        bool enabled
    );
    event TokenUpdate(address indexed token, bool enabled);
    event Execution(
        address indexed token,
        address indexed to,
        uint256 indexed gains
    );

    error BadValues(uint256 v1, uint256 v2);
    error BadUse(bool enable);

    constructor(address admin) Ownable() {
        transferOwnership(admin);
    }

    modifier ensure(uint256 deadline) {
        if (deadline < block.timestamp) {
            revert BadValues(deadline, block.timestamp); //expired
        }
        _;
    }

    function tokenRegistered(address token)
        external
        view
        override
        returns (bool)
    {
        return strategies[token].length > 0;
    }

    function strategiesLength(address token) external view returns (uint256) {
        return strategies[token].length;
    }

    function tokensLength() external view returns (uint256) {
        return tokens.length;
    }

    function _addToken(address token) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) return;
        }
        tokens.push(token);
        emit TokenUpdate(token, true);
    }

    function swapStrategies(
        address token,
        uint112 indexA,
        uint112 indexB
    ) external onlyOwner {
        emit StrategyUpdate(strategies[token][indexA], token, indexB, true);
        emit StrategyUpdate(strategies[token][indexB], token, indexA, true);
        (strategies[token][indexA], strategies[token][indexB]) = (
            strategies[token][indexB],
            strategies[token][indexA]
        );
    }

    function setStrategy(address strategy, bool enable) external onlyOwner {
        address token = IBonfireStrategicCalls(strategy).token();
        if (strategies[token].length == 0) {
            _addToken(token);
        }
        uint112 i;
        for (i = 0; i < strategies[token].length; i++) {
            if (strategies[token][i] == strategy) {
                if (enable) {
                    revert BadUse(enable); //wrong setting
                }
                if (strategies[token].length == 1) {
                    for (uint256 j = 0; j < tokens.length; j++) {
                        if (tokens[j] == token) {
                            tokens[j] = tokens[tokens.length - 1];
                            tokens.pop();
                            emit TokenUpdate(token, false);
                        }
                    }
                } else {
                    strategies[token][i] = strategies[token][
                        strategies[token].length - 1
                    ];
                }
                strategies[token].pop();
                emit StrategyUpdate(strategy, token, i, false);
                return;
            }
        }
        if (!enable) {
            revert BadUse(enable); //wrong setting
        }
        strategies[token].push(strategy);
        emit StrategyUpdate(strategy, token, i, true);
    }

    function suggestStrategy(address strategy) external {
        emit StrategySuggestionEvent(
            strategy,
            IBonfireStrategicCalls(strategy).token(),
            msg.sender
        );
    }

    function quote(address token, uint256 threshold)
        external
        view
        override
        returns (uint256 expectedGains)
    {
        for (uint256 i = 0; i < strategies[token].length; i++) {
            uint256 g = IBonfireStrategicCalls(strategies[token][i]).quote();
            if (g > threshold) {
                expectedGains += g;
            }
        }
        return (expectedGains);
    }

    function execute(
        address token,
        uint256 threshold,
        uint256 deadline,
        address to
    ) external override ensure(deadline) returns (uint256 gains) {
        for (uint256 i = 0; i < strategies[token].length; ) {
            uint256 g = IBonfireStrategicCalls(strategies[token][i]).execute(
                threshold,
                to
            );
            unchecked {
                if (g > 0) gains += g;
                i++;
            }
        }
        emit Execution(token, to, gains);
    }
}