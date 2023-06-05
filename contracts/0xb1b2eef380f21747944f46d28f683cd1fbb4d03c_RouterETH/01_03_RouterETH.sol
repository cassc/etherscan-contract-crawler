// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargateEthVault.sol";

contract RouterETH {
    struct SwapAmount {
        uint256 amountLD; // the amount, in Local Decimals, to be swapped
        uint256 minAmountLD; // the minimum amount accepted out on destination
    }

    address public immutable stargateEthVault;
    IStargateRouter public immutable stargateRouter;
    uint16 public immutable poolId;

    constructor(address _stargateEthVault, address _stargateRouter, uint16 _poolId) {
        require(_stargateEthVault != address(0x0), "RouterETH: _stargateEthVault cant be 0x0");
        require(_stargateRouter != address(0x0), "RouterETH: _stargateRouter cant be 0x0");
        stargateEthVault = _stargateEthVault;
        stargateRouter = IStargateRouter(_stargateRouter);
        poolId = _poolId;
    }

    function addLiquidityETH() external payable {
        require(msg.value > 0, "Stargate: msg.value is 0");

        uint256 amountLD = msg.value;

        // wrap the ETH into WETH
        IStargateEthVault(stargateEthVault).deposit{value: amountLD}();
        IStargateEthVault(stargateEthVault).approve(address(stargateRouter), amountLD);

        // addLiquidity using the WETH that was just wrapped,
        // and mint the LP token to the msg.sender
        stargateRouter.addLiquidity(poolId, amountLD, msg.sender);
    }

    ///@notice compose stargate to swap ETH on the source to ETH on the destination and arbitrary call
    function swapETHAndCall(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        SwapAmount memory _swapAmount, // the amount and the minimum swap amount
        IStargateRouter.lzTxObj memory _lzTxParams, // the LZ tx params
        bytes calldata _payload // the payload to send to the destination
    ) external payable {
        require(msg.value > _swapAmount.amountLD, "Stargate: msg.value must be > _swapAmount.amountLD");

        IStargateEthVault(stargateEthVault).deposit{value: _swapAmount.amountLD}();
        IStargateEthVault(stargateEthVault).approve(address(stargateRouter), _swapAmount.amountLD);

        stargateRouter.swap{value: (msg.value - _swapAmount.amountLD)}(
            _dstChainId, // destination Stargate chainId
            poolId, // WETH Stargate poolId on source
            poolId, // WETH Stargate poolId on destination
            _refundAddress, // message refund address if overpaid
            _swapAmount.amountLD, // the amount in Local Decimals to swap()
            _swapAmount.minAmountLD, // the minimum amount swap()er would allow to get out (ie: slippage)
            _lzTxParams, // the LZ tx params
            _toAddress, // address on destination to send to
            _payload // payload to send to the destination
        );
    }

    // this contract needs to accept ETH
    receive() external payable {}
}