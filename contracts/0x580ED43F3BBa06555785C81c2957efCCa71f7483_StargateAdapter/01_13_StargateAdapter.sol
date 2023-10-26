// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "../interfaces/IRouteProcessor.sol";
import "../interfaces/IWETH.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ISushiXSwapV2Adapter.sol";
import "../interfaces/stargate/IStargateRouter.sol";
import "../interfaces/stargate/IStargateReceiver.sol";
import "../interfaces/stargate/IStargateWidget.sol";
import "../interfaces/stargate/IStargateEthVault.sol";

contract StargateAdapter is ISushiXSwapV2Adapter, IStargateReceiver {
    using SafeERC20 for IERC20;

    IStargateRouter public immutable stargateComposer;
    IStargateWidget public immutable stargateWidget;
    address public immutable sgeth;
    IRouteProcessor public immutable rp;
    IWETH public immutable weth;

    address constant NATIVE_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct StargateTeleportParams {
        uint16 dstChainId; // stargate dst chain id
        address token; // token getting bridged
        uint256 srcPoolId; // stargate src pool id
        uint256 dstPoolId; // stargate dst pool id
        uint256 amount; // amount to bridge
        uint256 amountMin; // amount to bridge minimum
        uint256 dustAmount; // native token to be received on dst chain
        address receiver; // detination address for sgReceive
        address to; // address for fallback tranfers on sgReceive
        uint256 gas; // extra gas to be sent for dst chain operations
    }

    error InsufficientGas();
    error NotStargateComposer();
    error RpSentNativeIn();

    constructor(
        address _stargateComposer,
        address _stargateWidget,
        address _sgeth,
        address _rp,
        address _weth
    ) {
        stargateComposer = IStargateRouter(_stargateComposer);
        stargateWidget = IStargateWidget(_stargateWidget);
        sgeth = _sgeth;
        rp = IRouteProcessor(_rp);
        weth = IWETH(_weth);
    }

    /// @inheritdoc ISushiXSwapV2Adapter
    function swap(
        uint256 _amountBridged,
        bytes calldata _swapData,
        address _token,
        bytes calldata _payloadData
    ) external payable override {
        IRouteProcessor.RouteProcessorData memory rpd = abi.decode(
            _swapData,
            (IRouteProcessor.RouteProcessorData)
        );

        // send tokens to RP
        if (_token != sgeth) {
            IERC20(rpd.tokenIn).safeTransfer(address(rp), _amountBridged);
        }

        rp.processRoute{value: _token == sgeth ? _amountBridged : 0}(
            rpd.tokenIn,
            _amountBridged,
            rpd.tokenOut,
            rpd.amountOutMin,
            rpd.to,
            rpd.route
        );

        // tokens should be sent via rp
        if (_payloadData.length > 0) {
            PayloadData memory pd = abi.decode(_payloadData, (PayloadData));
            try
                IPayloadExecutor(pd.target).onPayloadReceive{gas: pd.gasLimit}(
                    pd.targetData
                )
            {} catch (bytes memory) {
                revert();
            }
        }
    }

    /// @inheritdoc ISushiXSwapV2Adapter
    function executePayload(
        uint256 _amountBridged,
        bytes calldata _payloadData,
        address _token
    ) external payable override {
        PayloadData memory pd = abi.decode(_payloadData, (PayloadData));

        if (_token != sgeth) {
            IERC20(_token).safeTransfer(pd.target, _amountBridged);
        }

        IPayloadExecutor(pd.target).onPayloadReceive{
            gas: pd.gasLimit,
            value: _token == sgeth ? _amountBridged : 0
        }(pd.targetData);
    }

    /// @notice Get the fees to be paid in native token for the swap
    /// @param _dstChainId stargate dst chainId
    /// @param _functionType stargate Function type 1 for swap.
    /// See more at https://stargateprotocol.gitbook.io/stargate/developers/function-types
    /// @param _receiver receiver on the dst chain
    /// @param _gas extra gas being sent
    /// @param _dustAmount dust amount to be received at the dst chain
    /// @param _payload payload being sent at the dst chain
    function getFee(
        uint16 _dstChainId,
        uint8 _functionType,
        address _receiver,
        uint256 _gas,
        uint256 _dustAmount,
        bytes memory _payload
    ) external view returns (uint256 a, uint256 b) {
        (a, b) = stargateComposer.quoteLayerZeroFee(
            _dstChainId,
            _functionType,
            abi.encodePacked(_receiver),
            abi.encode(_payload),
            IStargateRouter.lzTxObj(
                _gas,
                _dustAmount,
                abi.encodePacked(_receiver)
            )
        );
    }

    /// @inheritdoc ISushiXSwapV2Adapter
    function adapterBridge(
        bytes calldata _adapterData,
        address _refundAddress,
        bytes calldata _swapData,
        bytes calldata _payloadData
    ) external payable override {
        StargateTeleportParams memory params = abi.decode(
            _adapterData,
            (StargateTeleportParams)
        );

        if (params.token == NATIVE_ADDRESS) {
            // RP should not send native in, since we won't know the exact amount to bridge
            if (params.amount == 0) revert RpSentNativeIn();
        } else if (params.token == address(weth)) {
            // this case is for when rp sends weth in
            if (params.amount == 0)
                params.amount = weth.balanceOf(address(this));
            weth.withdraw(params.amount);
        } else {
            if (params.amount == 0)
                params.amount = IERC20(params.token).balanceOf(address(this));

            IERC20(params.token).safeApprove(
                address(stargateComposer),
                params.amount
            );
        }

        bytes memory payload = bytes("");
        if (_swapData.length > 0 || _payloadData.length > 0) {
            /// @dev dst gas should be more than 100k
            if (params.gas < 100000) revert InsufficientGas();
            payload = abi.encode(params.to, _swapData, _payloadData);
        }

        stargateComposer.swap{value: address(this).balance}(
            params.dstChainId,
            params.srcPoolId,
            params.dstPoolId,
            payable(_refundAddress), // refund address
            params.amount,
            params.amountMin,
            IStargateRouter.lzTxObj(
                params.gas,
                params.dustAmount,
                abi.encodePacked(params.receiver)
            ),
            abi.encodePacked(params.receiver),
            payload
        );

        stargateWidget.partnerSwap(0x0001);
    }

    /// @notice Receiver function on dst chain
    /// @param _token bridge token received
    /// @param amountLD amount received
    /// @param payload ABI-Encoded data received from src chain
    function sgReceive(
        uint16,
        bytes memory,
        uint256,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external {
        uint256 gasLeft = gasleft();
        if (msg.sender != address(stargateComposer)) revert NotStargateComposer();

        (address to, bytes memory _swapData, bytes memory _payloadData) = abi
            .decode(payload, (address, bytes, bytes));

        uint256 reserveGas = 100000;

        if (gasLeft < reserveGas) {
            if (_token != sgeth) {
                IERC20(_token).safeTransfer(to, amountLD);
            }

            /// @dev transfer any native token received as dust to the to address
            if (address(this).balance > 0)
                to.call{value: (address(this).balance)}("");

            return;
        }

        // 100000 -> exit gas
        uint256 limit = gasLeft - reserveGas;

        if (_swapData.length > 0) {
            try
                ISushiXSwapV2Adapter(address(this)).swap{gas: limit}(
                    amountLD,
                    _swapData,
                    _token,
                    _payloadData
                )
            {} catch (bytes memory) {}
        } else if (_payloadData.length > 0) {
            try
                ISushiXSwapV2Adapter(address(this)).executePayload{gas: limit}(
                    amountLD,
                    _payloadData,
                    _token
                )
            {} catch (bytes memory) {}
        } else {}

        if (IERC20(_token).balanceOf(address(this)) > 0 && _token != sgeth)
            IERC20(_token).safeTransfer(to, IERC20(_token).balanceOf(address(this)));

        /// @dev transfer any native token received as dust to the to address
        if (address(this).balance > 0)
            to.call{value: (address(this).balance)}("");
    }

    /// @inheritdoc ISushiXSwapV2Adapter
    function sendMessage(bytes calldata _adapterData) external {
        (_adapterData);
        revert();
    }

    receive() external payable {}
}