// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Governable} from "./access/Governable.sol";
import {IExchangeWithExactOutput} from "./interfaces/IExchangeWithExactOutput.sol";
import {IMasterOracle} from "./interfaces/external/bloq/IMasterOracle.sol";
import {SwapperStorage} from "./SwapperStorage.sol";

error NoRoutingFound();
error AmountOutBelowMin();

contract Swapper is Initializable, Governable, SwapperStorage {
    using Address for address;
    using SafeERC20 for IERC20;

    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Emitted when exact-input swap is executed
    event SwapExactInput(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// @notice Emitted when exact-output swap is executed
    event SwapExactOutput(
        address indexed tokenIn, address indexed tokenOut, uint256 amountInMax, uint256 amountIn, uint256 amountOut
    );

    /// @notice Emitted when exact input routing is updated
    event ExactInputRoutingUpdated(address indexed tokenIn, address indexed tokenOut, bytes newRouting);

    /// @notice Emitted when exact output routing is updated
    event ExactOutputRoutingUpdated(
        address indexed tokenIn, address indexed tokenOut, IExchangeWithExactOutput indexed exchange, bytes path
    );

    /// @notice Emitted when master oracle contract is updated
    event MasterOracleUpdated(IMasterOracle indexed oldMasterOracle, IMasterOracle indexed newMasterOracle);

    function initialize(IMasterOracle masterOracle_) public initializer {
        __Governable_init();
        masterOracle = masterOracle_;
    }

    function getAmountInUsingOracle(address tokenIn_, address tokenOut_, uint256 amountOut_)
        public
        view
        override
        returns (uint256 _amountIn)
    {
        return masterOracle.quote(tokenOut_, tokenIn_, amountOut_);
    }

    function getAmountOutUsingOracle(address tokenIn_, address tokenOut_, uint256 amountIn_)
        public
        view
        override
        returns (uint256 _amountOut)
    {
        return masterOracle.quote(tokenIn_, tokenOut_, amountIn_);
    }

    function getRouting(SwapType type_, address tokenIn_, address tokenOut_) public pure returns (bytes memory _key) {
        _key = abi.encodePacked(type_, tokenIn_, tokenOut_);
    }

    /// @dev This function gets spot price and may incurs in price manipulations
    function getAmountIn(address tokenIn_, address tokenOut_, uint256 amountOut_)
        public
        override
        returns (uint256 _amountIn)
    {
        bytes memory _routing = routings[getRouting(SwapType.EXACT_OUTPUT, tokenIn_, tokenOut_)];
        if (_routing.length == 0) revert NoRoutingFound();

        (IExchangeWithExactOutput _exchange, bytes memory _path) =
            abi.decode(_routing, (IExchangeWithExactOutput, bytes));

        return _exchange.getAmountIn(amountOut_, _path);
    }

    function swapExactInput(address tokenIn_, address tokenOut_, uint256 amountIn_, uint256 amountOutMin_)
        external
        payable
        override
        returns (uint256 _amountOut)
    {
        // 1. Find routing
        bytes memory _routing = routings[getRouting(SwapType.EXACT_INPUT, tokenIn_, tokenOut_)];
        if (_routing.length == 0) revert NoRoutingFound();

        // 2. Get input amount
        if (tokenIn_ != ETH) {
            IERC20(tokenIn_).safeTransferFrom(msg.sender, address(this), amountIn_);
        }

        // 2. Execute routing
        _executeCalls(abi.decode(_routing, (Call[])));

        // 3. Check post-conditions
        _amountOut = tokenOut_ == ETH ? address(this).balance : IERC20(tokenOut_).balanceOf(address(this));
        if (_amountOut < amountOutMin_) revert AmountOutBelowMin();

        // 4. Send output amount
        if (_amountOut > 0) {
            if (tokenOut_ == ETH) {
                Address.sendValue(payable(msg.sender), _amountOut);
            } else {
                IERC20(tokenOut_).safeTransfer(msg.sender, _amountOut);
            }
        }

        emit SwapExactInput(tokenIn_, tokenOut_, amountIn_, _amountOut);
    }

    function swapExactOutput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address receiver_
    ) external returns (uint256 _amountIn) {
        bytes memory _routing = routings[getRouting(SwapType.EXACT_OUTPUT, tokenIn_, tokenOut_)];
        if (_routing.length == 0) revert NoRoutingFound();

        (IExchangeWithExactOutput _exchange, bytes memory _path) =
            abi.decode(_routing, (IExchangeWithExactOutput, bytes));
        IERC20(tokenIn_).safeTransferFrom(msg.sender, address(_exchange), amountInMax_);
        _amountIn = _exchange.swapExactOutput(_path, amountOut_, amountInMax_, msg.sender, receiver_);
        emit SwapExactOutput(tokenIn_, tokenOut_, amountInMax_, _amountIn, amountOut_);
    }

    function _executeCalls(Call[] memory _calls) private {
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

    function _setRouting(SwapType type_, address tokenIn_, address tokenOut_, bytes memory _newRouting) private {
        bytes memory _key = getRouting(type_, tokenIn_, tokenOut_);
        if (_newRouting.length == 0) {
            delete routings[_key];
        } else {
            routings[_key] = _newRouting;
        }
    }

    function setExactInputRouting(address tokenIn_, address tokenOut_, bytes memory _newRouting)
        external
        onlyGovernor
    {
        _setRouting(SwapType.EXACT_INPUT, tokenIn_, tokenOut_, _newRouting);
        emit ExactInputRoutingUpdated(tokenIn_, tokenOut_, _newRouting);
    }

    function setExactOutputRouting(
        address tokenIn_,
        address tokenOut_,
        IExchangeWithExactOutput exchange_,
        bytes calldata path_
    ) external onlyGovernor {
        bytes memory _newRouting = abi.encode(exchange_, path_);
        _setRouting(SwapType.EXACT_OUTPUT, tokenIn_, tokenOut_, _newRouting);
        emit ExactOutputRoutingUpdated(tokenIn_, tokenOut_, exchange_, path_);
    }

    function updateMasterOracle(IMasterOracle masterOracle_) external onlyGovernor {
        emit MasterOracleUpdated(masterOracle, masterOracle_);
        masterOracle = masterOracle_;
    }

    receive() external payable override {}
}