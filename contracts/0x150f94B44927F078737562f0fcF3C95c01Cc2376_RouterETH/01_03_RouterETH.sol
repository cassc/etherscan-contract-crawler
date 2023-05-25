// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargateEthVault.sol";

contract RouterETH {
    address public immutable stargateEthVault;
    IStargateRouter public immutable stargateRouter;
    uint16 public immutable poolId;

    constructor(address _stargateEthVault, address _stargateRouter, uint16 _poolId){
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
        stargateRouter.addLiquidity(
            poolId,
            amountLD,
            msg.sender
        );
    }

    // compose stargate to swap ETH on the source to ETH on the destination
    function swapETH(
        uint16 _dstChainId,                         // destination Stargate chainId
        address payable _refundAddress,             // refund additional messageFee to this address
        bytes calldata _toAddress,                  // the receiver of the destination ETH
        uint256 _amountLD,                          // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD                        // the minimum amount accepted out on destination
    ) external payable {
        require(msg.value > _amountLD, "Stargate: msg.value must be > _amountLD");

        // wrap the ETH into WETH
        IStargateEthVault(stargateEthVault).deposit{value: _amountLD}();
        IStargateEthVault(stargateEthVault).approve(address(stargateRouter), _amountLD);

        // messageFee is the remainder of the msg.value after wrap
        uint256 messageFee = msg.value - _amountLD;

        // compose a stargate swap() using the WETH that was just wrapped
        stargateRouter.swap{value: messageFee}(
            _dstChainId,                        // destination Stargate chainId
            poolId,                             // WETH Stargate poolId on source
            poolId,                             // WETH Stargate poolId on destination
            _refundAddress,                     // message refund address if overpaid
            _amountLD,                          // the amount in Local Decimals to swap()
            _minAmountLD,                       // the minimum amount swap()er would allow to get out (ie: slippage)
            IStargateRouter.lzTxObj(0, 0, "0x"),
            _toAddress,                         // address on destination to send to
            bytes("")                           // empty payload, since sending to EOA
        );
    }

    // this contract needs to accept ETH
    receive() external payable {}

}