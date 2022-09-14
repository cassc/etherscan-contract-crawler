//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IStopLimitOrder.sol";
import "../interfaces/IBentoBoxV1.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IERC20.sol";

contract StopLimitOrderWrapper{
    IBentoBoxV1 public immutable bentoBox;
    address payable public immutable registry;
    address public immutable gasFeeForwarder;
    IStopLimitOrder public immutable stopLimitOrderContract;
    address public immutable WETH;
    IUniswapV2Router02 immutable uni;

    uint256 internal constant MAX_UINT = type(uint256).max;
    uint256 public constant DEADLINE = 2429913600;

    constructor(
        address payable registry_,
        address gasFeeForwarder_,
        address bentoBox_,
        address stopLimitOrderContract_,
        address WETH_,
        address uni_
    ) {
        require(registry_ != address(0), "Invalid registry");
        require(gasFeeForwarder_ != address(0), "Invalid gasForwarder");
        require(bentoBox_ != address(0), "Invalid BentoBox");
        require(stopLimitOrderContract_ != address(0), "Invalid stopLimitOrder");
        require(WETH_ != address(0), "Invalid WETH");
        require(uni_ != address(0), "Invalid uni-router");

        registry = registry_;
        gasFeeForwarder = gasFeeForwarder_;
        bentoBox = IBentoBoxV1(bentoBox_);

        stopLimitOrderContract = IStopLimitOrder(stopLimitOrderContract_);
        WETH = WETH_;
        uni = IUniswapV2Router02(uni_);
    }

    function fillOrder(
        uint256 feeAmount,
        OrderArgs memory order,
        address tokenIn,
        address tokenOut, 
        address receiver, 
        bytes calldata data
    ) external gasFeeForwarderVerified {
        stopLimitOrderContract.fillOrder(
            order,
            tokenIn,
            tokenOut,
            receiver,
            data
        );

        /// @dev stopLimitOrder charges fee by tokenOut
        uint256 _feeReceivedAsShare = bentoBox.balanceOf(tokenOut, address(this));
        uint256 _feeReceivedAmount = bentoBox.toAmount(tokenOut, _feeReceivedAsShare, false);

        if (tokenOut == WETH) {
            require(_feeReceivedAmount >= feeAmount, "Insufficient Fee");

            bentoBox.withdraw(
                address(0), // USE_ETHEREUM
                address(this),
                registry,   // transfer to registry
                feeAmount,  // amount
                0 // share
            );

            /// @dev transfer residue amount to maker
            _feeReceivedAsShare = bentoBox.balanceOf(WETH, address(this));
            if (_feeReceivedAsShare > 0) {
                bentoBox.transfer(
                    WETH,
                    address(this),
                    order.maker,
                    _feeReceivedAsShare
                );
            }
        } else {
            bentoBox.withdraw(
                tokenOut,
                address(this),
                address(this),
                0,
                _feeReceivedAsShare
            );

            /// @dev swap tokenOut to ETH, and transfer to registry
            IERC20 _tokenOut = IERC20(tokenOut);
            if (_tokenOut.allowance(address(this), address(uni)) < _feeReceivedAmount) {
                _tokenOut.approve(address(uni), MAX_UINT);
            }
            address[] memory routePath = new address[](2);
            routePath[0] = tokenOut;
            routePath[1] = WETH;
            uni.swapTokensForExactETH(
                feeAmount, // amountOut
                _feeReceivedAmount, // amountInMax
                routePath, // path
                registry, // to
                DEADLINE // deadline
            );

            /// @dev deposit residue amount of tokenOut into bentoBox again, and transfer to maker
            uint256 leftTokenOut = _tokenOut.balanceOf(address(this));
            if (leftTokenOut > 0) {
                if (_tokenOut.allowance(address(this), address(bentoBox)) < leftTokenOut) {
                    _tokenOut.approve(address(bentoBox), MAX_UINT);
                }
                bentoBox.deposit(
                    tokenOut,
                    address(this),
                    order.maker,
                    leftTokenOut,
                    0
                );
            }
        }
    }

    modifier gasFeeForwarderVerified() {
        require(msg.sender == gasFeeForwarder, "StopLimitOrderWrapper: no gasFF");
        _;
    }
}