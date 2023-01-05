// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./dependencies/uniswap/v2-periphery/libraries/UniswapV2LiquidityMathLibrary.sol";
import "./utils/TokenHolder.sol";
import "./interfaces/external/aave/IAave.sol";
import "./interfaces/external/uniswap-v2/IUniswapV2Callee.sol";

error CanNotSweep();
error InvalidSender();
error NotInitiator();
error BothAmountsReceived();
error NotAavePool();
error BalanceLessThanMin();

contract MultiSend is IUniswapV2Callee, Ownable, TokenHolder {
    using Address for address;

    PoolAddressesProvider internal immutable poolAddressesProvider;
    IUniswapV2Factory internal immutable uniV2Factory;
    address internal immutable nativeToken;

    constructor(address nativeToken_, PoolAddressesProvider poolAddressesProvider_, IUniswapV2Factory uniV2Factory_) {
        nativeToken = nativeToken_;
        poolAddressesProvider = poolAddressesProvider_;
        uniV2Factory = uniV2Factory_;
    }

    receive() external payable override {}

    struct Call {
        address target;
        bytes data;
        uint256 value;
        bool isDelegateCall;
    }

    function _executeTxs(bytes memory callsInBytes_) private {
        Call[] memory _calls = abi.decode(callsInBytes_, (Call[]));
        uint256 _len = _calls.length;
        for (uint256 i; i < _len; ++i) {
            Call memory _call = _calls[i];
            if (_call.isDelegateCall) {
                _call.target.functionDelegateCall(_call.data);
            } else {
                _call.target.functionCallWithValue(_call.data, _call.value);
            }
        }
    }

    function executeTxs(bytes memory callsInBytes_) external payable onlyOwner {
        _executeTxs(callsInBytes_);
    }

    /// @inheritdoc TokenHolder
    function _requireCanSweep() internal view override {
        if (msg.sender != owner() && msg.sender != address(this)) revert CanNotSweep();
    }

    function uniswapV2Call(
        address sender_,
        uint amount0_,
        uint amount1_,
        bytes calldata callsInBytes_
    ) external override {
        IUniswapV2Pair _pair = IUniswapV2Pair(msg.sender);
        address _token0 = _pair.token0();
        address _token1 = _pair.token1();
        if (msg.sender != uniV2Factory.getPair(_token0, _token1)) revert InvalidSender();
        if (sender_ != address(this)) revert NotInitiator();
        if (amount0_ > 0 && amount1_ > 0) revert BothAmountsReceived();

        // Do logic
        _executeTxs(callsInBytes_);

        // Repay 0.3% fee, +1 to round up
        // See more: https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps#single-token
        uint256 _amount = amount0_ > 0 ? amount0_ : amount1_;
        uint256 _amountToRepay = (_amount * 1000) / 997 + 1;
        IERC20 _token = IERC20(amount0_ > 0 ? _token0 : _token1);
        _token.transfer(address(_pair), _amountToRepay);
    }

    function executeOperation(
        address[] calldata /*_assets*/,
        uint256[] calldata /*_amounts*/,
        uint256[] calldata /*_premiums*/,
        address _initiator,
        bytes calldata callsInBytes_
    ) external returns (bool) {
        if (msg.sender != poolAddressesProvider.getLendingPool()) revert NotAavePool();
        if (_initiator != address(this)) revert NotInitiator();

        _executeTxs(callsInBytes_);

        // Note: The Aave will pull the fee (_amounts[0] + _premiums[0]) after operation
        // unlike UniV2, there is no need to perform a transfer
        return true;
    }

    function checkBalance(address token_, uint256 balanceMin_) external view {
        if (token_ == address(0)) {
            if (address(this).balance < balanceMin_) revert BalanceLessThanMin();
        } else {
            if (IERC20(token_).balanceOf(address(this)) < balanceMin_) revert BalanceLessThanMin();
        }
    }

    function approveIfNeeded(address token_, address spender_) external {
        if (msg.sender != address(this)) revert InvalidSender();

        IERC20 _token = IERC20(token_);

        uint256 _amount = _token.balanceOf(address(this));

        if (token_ == address(nativeToken)) {
            _amount = Math.max(address(this).balance, _amount);
        }

        if (_amount > 0 && _token.allowance(address(this), spender_) < _amount) {
            _token.approve(spender_, type(uint256).max);
        }
    }
}