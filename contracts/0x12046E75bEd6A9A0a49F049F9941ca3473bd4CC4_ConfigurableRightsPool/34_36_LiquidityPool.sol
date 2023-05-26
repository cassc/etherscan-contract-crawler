// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

import "./LpToken.sol";
import "./Math.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IBFactory.sol";
import "../libraries/Address.sol";

import "../libraries/SafeERC20.sol";

contract LiquidityPool is BBronze, LpToken, Math {
    using Address for address;
    using SafeERC20 for IERC20;

    struct Record {
        bool bound; // is token bound to pool
        uint index; // private
        uint denorm; // denormalized weight
        uint balance;
    }

    event LOG_JOIN(address indexed caller, address indexed tokenIn, uint tokenAmountIn);

    event LOG_EXIT(address indexed caller, address indexed tokenOut, uint tokenAmountOut);

    event LOG_REBALANCE(address indexed tokenA, address indexed tokenB, uint newWeightA, uint newWeightB, uint newBalanceA, uint newBalanceB, bool isSoldout);

    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    bool private _mutex;

    IBFactory private _factory; // Factory address to push token exitFee to
    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint private _swapFee;
    bool private _finalized;

    address[] private _tokens;
    mapping(address => Record) private _records;
    uint private _totalWeight;

    Oracles private oracle;

    constructor() public {
        _controller = msg.sender;
        _factory = IBFactory(msg.sender);
        _swapFee = MIN_FEE;
        _publicSwap = false;
        _finalized = false;

        oracle = Oracles(_factory.getOracleAddress());
    }

    function isPublicSwap() external view returns (bool) {
        return _publicSwap;
    }

    function isFinalized() external view returns (bool) {
        return _finalized;
    }

    function isBound(address t) external view returns (bool) {
        return _records[t].bound;
    }

    function getNumTokens() external view returns (uint) {
        return _tokens.length;
    }

    function getCurrentTokens() external view _viewlock_ returns (address[] memory tokens) {
        return _tokens;
    }

    function getFinalTokens() external view _viewlock_ returns (address[] memory tokens) {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token) external view _viewlock_ returns (uint) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight() external view _viewlock_ returns (uint) {
        return _totalWeight;
    }

    function getNormalizedWeight(address token) external _viewlock_ returns (uint) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        uint denorm = _records[token].denorm;
        uint price = oracle.getPrice(token);

        uint[] memory _balances = new uint[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            _balances[i] = getBalance(_tokens[i]);
        }
        uint totalValue = oracle.getAllPrice(_tokens, _balances);
        uint currentValue = bmul(price, getBalance(token));
        return bdiv(currentValue, totalValue);
    }

    function getBalance(address token) public view _viewlock_ returns (uint) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee() external view _viewlock_ returns (uint) {
        return _swapFee;
    }

    function getController() external view _viewlock_ returns (address) {
        return _controller;
    }

    function setSwapFee(uint swapFee) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
    }

    function setController(address manager) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(manager != address(0),"ERR_ZERO_ADDRESS");
        _controller = manager;
    }

    function setPublicSwap(bool public_) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _publicSwap = public_;
    }

    function finalize() external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }

    function bind(
        address token,
        uint balance,
        uint denorm
    )
        external
        _logs_ // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0, // balance and denorm will be validated
            balance: 0 // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    function rebind(
        address token,
        uint balance,
        uint denorm
    ) public _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        } else if (denorm < oldWeight) {
            _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, so charge EXIT_FEE
            uint tokenBalanceWithdrawn = bsub(oldBalance, balance);
            _pushUnderlying(token, msg.sender, tokenBalanceWithdrawn);
        }
    }

    function rebindSmart(
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint deltaBalance,
        bool isSoldout,
        uint minAmountOut
    ) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");

        address[] memory paths = new address[](2);
        paths[0] = tokenA;
        paths[1] = tokenB;

        IUniswapV2Router02 swapRouter = IUniswapV2Router02(_factory.getSwapRouter());
        // tokenB is inside the etf
        if (_records[tokenB].bound) {
            uint oldWeightB = _records[tokenB].denorm;
            uint oldBalanceB = _records[tokenB].balance;
            uint newWeightB = badd(oldWeightB, deltaWeight);

            require(newWeightB <= MAX_WEIGHT, "ERR_MAX_WEIGHT_B");

            if (isSoldout) {
                require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
            } else {
                require(_records[tokenA].bound, "ERR_NOT_BOUND_A");

                uint newWeightA = bsub(_records[tokenA].denorm, deltaWeight);
                uint newBalanceA = bsub(_records[tokenA].balance, deltaBalance);
                require(newWeightA >= MIN_WEIGHT, "ERR_MIN_WEIGHT_A");
                require(newBalanceA >= MIN_BALANCE, "ERR_MIN_BALANCE_A");

                _records[tokenA].balance = newBalanceA;
                _records[tokenA].denorm = newWeightA;
            }

            // sell tokenA to get tokenB
            uint balanceBBefore = IERC20(tokenB).balanceOf(address(this));

            _safeApprove(IERC20(tokenA), address(swapRouter), uint(-1));

            swapRouter.swapExactTokensForTokens(deltaBalance, minAmountOut, paths, address(this), badd(block.timestamp, 1800));
            uint balanceBAfter = IERC20(tokenB).balanceOf(address(this));

            uint newBalanceB = badd(oldBalanceB, bsub(balanceBAfter, balanceBBefore));

            _records[tokenB].balance = newBalanceB;
            _records[tokenB].denorm = newWeightB;
        }
        // tokenB is outside the etf
        else {
            if (!isSoldout) {
                require(_records[tokenA].bound, "ERR_NOT_BOUND_A");

                uint newWeightA = bsub(_records[tokenA].denorm, deltaWeight);
                uint newBalanceA = bsub(_records[tokenA].balance, deltaBalance);

                require(newWeightA >= MIN_WEIGHT, "ERR_MIN_WEIGHT_A");
                require(newBalanceA >= MIN_BALANCE, "ERR_MIN_BALANCE_A");
                require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

                _records[tokenA].balance = newBalanceA;
                _records[tokenA].denorm = newWeightA;
            }

            // sell all tokenA to get tokenB
            uint balanceBBefore = IERC20(tokenB).balanceOf(address(this));

            _safeApprove(IERC20(tokenA), address(swapRouter), uint(-1));

            swapRouter.swapExactTokensForTokens(deltaBalance, minAmountOut, paths, address(this), badd(block.timestamp, 1800));
            uint balanceBAfter = IERC20(tokenB).balanceOf(address(this));

            uint newBalanceB = bsub(balanceBAfter, balanceBBefore);
            require(newBalanceB >= MIN_BALANCE, "ERR_MIN_BALANCE");
            require(deltaWeight >= MIN_WEIGHT, "ERR_MIN_WEIGHT_DELTA");

            _records[tokenB] = Record({bound: true, index: _tokens.length, denorm: deltaWeight, balance: newBalanceB});
            _tokens.push(tokenB);
        }

        emit LOG_REBALANCE(tokenA, tokenB, _records[tokenA].denorm, _records[tokenB].denorm, _records[tokenA].balance, _records[tokenB].balance, isSoldout);
    }

    function execute(
        address _target,
        uint _value,
        bytes calldata _data
    ) external _logs_ _lock_ returns (bytes memory _returnValue) {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");

        _returnValue = _target.functionCallWithValue(_data, _value);

        return _returnValue;
    }

    function unbind(address token) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        uint tokenBalance = _records[token].balance;

        _totalWeight = bsub(_totalWeight, _records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({bound: false, index: 0, denorm: 0, balance: 0});

        _pushUnderlying(token, msg.sender, tokenBalance);
    }

    function unbindPure(address token) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({bound: false, index: 0, denorm: 0, balance: 0});
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token) external _logs_ _lock_ {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external _logs_ _lock_ {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = this.totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external _logs_ _lock_ {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = this.totalSupply();
        uint ratio = bdiv(poolAmountIn, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety
    function _safeApprove(
        IERC20 token,
        address spender,
        uint amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.approve(spender, 0);
        }
        token.approve(spender, amount);
    }

    function _pullUnderlying(
        address erc20,
        address from,
        uint amount
    ) internal {
        IERC20(erc20).safeTransferFrom(from, address(this), amount);
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint amount
    ) internal {
        IERC20(erc20).safeTransfer(to, amount);
    }

    function _pullPoolShare(address from, uint amount) internal {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint amount) internal {
        _push(to, amount);
    }

    function _mintPoolShare(uint amount) internal {
        _mint(amount);
    }

    function _burnPoolShare(uint amount) internal {
        _burn(amount);
    }

    receive() external payable {}
}