// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-strategies/contracts/IStrategy.sol';
import '@mimic-fi/v2-registry/contracts/implementations/BaseImplementation.sol';

import '../samples/TokenMock.sol';

contract StrategyMock is IStrategy, BaseImplementation {
    using FixedPoint for uint256;

    bytes32 public constant override NAMESPACE = keccak256('STRATEGY');

    address public immutable lpt;
    address public immutable token;
    address public immutable rewardToken;

    event Claimed(bytes data);
    event Joined(address[] tokensIn, uint256[] amountsIn, uint256 slippage, bytes data);
    event Exited(address[] tokensIn, uint256[] amountsIn, uint256 slippage, bytes data);

    constructor(address registry) BaseImplementation(registry) {
        lpt = address(new TokenMock('LPT'));
        token = address(new TokenMock('TKN'));
        rewardToken = address(new TokenMock('REW'));
    }

    function mockGains(address account, uint256 multiplier) external {
        uint256 balance = IERC20(lpt).balanceOf(account);
        TokenMock(lpt).mint(account, balance * (multiplier - 1));
    }

    function mockLosses(address account, uint256 divisor) external {
        uint256 balance = IERC20(lpt).balanceOf(account);
        TokenMock(lpt).burn(account, balance / divisor);
    }

    function joinTokens() public view override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = token;
    }

    function exitTokens() public view override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = lpt;
    }

    function valueRate() public pure override returns (uint256) {
        return FixedPoint.ONE;
    }

    function lastValue(address account) public view override returns (uint256) {
        return IERC20(lpt).balanceOf(account);
    }

    function claim(bytes memory data) external override returns (address[] memory tokens, uint256[] memory amounts) {
        uint256 amount = abi.decode(data, (uint256));
        TokenMock(rewardToken).mint(address(this), amount);
        tokens = new address[](1);
        tokens[0] = rewardToken;
        amounts = new uint256[](1);
        amounts[0] = amount;
        emit Claimed(data);
    }

    function join(address[] memory tokensIn, uint256[] memory amountsIn, uint256 slippage, bytes memory data)
        external
        override
        returns (address[] memory tokensOut, uint256[] memory amountsOut, uint256 value)
    {
        require(tokensIn.length == 1, 'STRATEGY_INVALID_TOKENS_IN_LEN');
        require(amountsIn.length == 1, 'STRATEGY_INVALID_AMOUNTS_IN_LEN');
        require(tokensIn[0] == token, 'STRATEGY_INVALID_JOIN_TOKEN');

        tokensOut = exitTokens();
        amountsOut = new uint256[](1);
        amountsOut[0] = amountsIn[0];

        TokenMock(token).burn(address(this), amountsIn[0]);
        TokenMock(lpt).mint(address(this), amountsOut[0]);
        value = amountsOut[0].mulDown(valueRate());
        emit Joined(tokensIn, amountsIn, slippage, data);
    }

    function exit(address[] memory tokensIn, uint256[] memory amountsIn, uint256 slippage, bytes memory data)
        external
        override
        returns (address[] memory tokensOut, uint256[] memory amountsOut, uint256 value)
    {
        require(tokensIn.length == 1, 'STRATEGY_INVALID_TOKENS_IN_LEN');
        require(amountsIn.length == 1, 'STRATEGY_INVALID_AMOUNTS_IN_LEN');
        require(tokensIn[0] == lpt, 'STRATEGY_INVALID_EXIT_TOKEN');

        tokensOut = joinTokens();
        amountsOut = new uint256[](1);
        amountsOut[0] = amountsIn[0];

        TokenMock(lpt).burn(address(this), amountsIn[0]);
        TokenMock(token).mint(address(this), amountsOut[0]);
        value = amountsIn[0].divUp(valueRate());
        emit Exited(tokensIn, amountsIn, slippage, data);
    }
}