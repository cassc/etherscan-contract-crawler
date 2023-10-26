// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "solmate/auth/Owned.sol";
import "./KekotronSwapV2.sol";
import "./KekotronSwapV3.sol";
import "./KekotronErrors.sol";

contract KekotronRouterV1 is Owned, KekotronSwapV2, KekotronSwapV3 {

    uint8 public fee = 100; // 1%
    address public feeReceiver;

    constructor(address owner, address receiver, address weth) Owned(owner) KekotronSwapV2(weth) KekotronSwapV3(weth) {
        feeReceiver = receiver;
    }

    function _requireIsOwner() internal view {
        if (msg.sender != owner) { 
            revert("KekotronErrors.OnlyOwner"); 
        }
    }

    function updateFee(uint8 newFee) external {
        _requireIsOwner();
        fee = newFee;
    }

    function updateFeeReceiver(address newFeeReceiver) external {
        _requireIsOwner();
        feeReceiver = newFeeReceiver;
    }

    fallback() payable external {

        bytes4 selector = bytes4(msg.data[:4]);

        if (selector == 0x10d1e85c) {
            (address sender, uint256 amount0, uint256 amount1, bytes memory data) = abi.decode(msg.data[4:], (address, uint256, uint256, bytes));
            return _callbackV2(sender, amount0, amount1, data);
        }

        if (selector == 0xfa461e33) {
            (int256 amount0Delta, int256 amount1Delta, bytes memory data) = abi.decode(msg.data[4:], (int256, int256, bytes));
            return _callbackV3(amount0Delta, amount1Delta, data);
        }
        
        uint8 version;
        uint8 feeOn;

        assembly {
            version := byte(0, calldataload(0))
            feeOn := byte(1, calldataload(0))
        }

        if (version == 0) { // v2
            SwapV2 memory swapV2;

            assembly {
                let offset := 0x02
                calldatacopy(add(swapV2, 0x0c), offset, 0x14)               // pool
                calldatacopy(add(swapV2, 0x2c), add(offset, 0x14), 0x14)    // tokenIn
                calldatacopy(add(swapV2, 0x4c), add(offset, 0x28), 0x14)    // tokenIn
                calldatacopy(add(swapV2, 0x70), add(offset, 0x3c), 0x10)    // amountIn
                calldatacopy(add(swapV2, 0x90), add(offset, 0x4c), 0x20)    // amountOut
            }

            return _swapExactInputV2(swapV2, feeReceiver, fee, feeOn);
        }

        if (version == 1) { // v3 
            SwapV3 memory swapV3;

            assembly {
                let offset := 0x02
                calldatacopy(add(swapV3, 0x0c), offset, 0x14)               // pool
                calldatacopy(add(swapV3, 0x2c), add(offset, 0x14), 0x14)    // tokenIn
                calldatacopy(add(swapV3, 0x4c), add(offset, 0x28), 0x14)    // tokenIn
                calldatacopy(add(swapV3, 0x70), add(offset, 0x3c), 0x10)    // amountIn
                calldatacopy(add(swapV3, 0x90), add(offset, 0x4c), 0x20)    // amountOut
            }

            return _swapExactInputV3(swapV3, feeReceiver, fee, feeOn);
        }

        revert("KekotronErrors.InvalidVersion");
    }

    receive() payable external {}
}