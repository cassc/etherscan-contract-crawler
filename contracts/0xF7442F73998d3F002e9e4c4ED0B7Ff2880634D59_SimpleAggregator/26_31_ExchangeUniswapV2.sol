//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

import "../lib/UniversalERC20.sol";
import "../interface/uniswap/ISwapRouter.sol";

contract ExchangeUniswapV2 {
    using UniversalERC20 for IERC20;

    ISwapRouter public constant router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    function _swap(
        address from,
        address to,
        uint256 _amount,
        bytes calldata _swapParams
    ) public payable returns (uint256 amount) {
        IERC20(from).universalApprove(address(router), _amount);

        uint256 balanceBefore = IERC20(to).balanceOf(address(this));

        (bool success, bytes memory results) = address(router).call(_swapParams);

        if (!success) {
            revert(_getRevertMsg(results));
        }

        uint256 balanceAfter = IERC20(to).balanceOf(address(this));

        amount = balanceAfter - balanceBefore;
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) {
            return "Transaction reverted silently";
        }

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}