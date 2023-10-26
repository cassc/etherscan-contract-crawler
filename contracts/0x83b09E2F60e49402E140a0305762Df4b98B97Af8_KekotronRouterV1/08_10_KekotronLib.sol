// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "src/interfaces/IERC20.sol";
import "src/interfaces/IWETH.sol";
import "./KekotronErrors.sol";

library KekotronLib {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) { 
            revert("KekotronErrors.TokenTransfer"); 
        }
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) { 
            revert("KekotronErrors.TokenTransferFrom"); 
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        if (!success) { 
            revert("KekotronErrors.EthTransfer"); 
        }
    }

    function depositWETH(address weth, uint256 value) internal {
        (bool success, ) = weth.call{value: value}(new bytes(0));
        if (!success) { 
            revert("KekotronErrors.WethDeposit"); 
        }
    }

    function withdrawWETH(address weth, uint256 value) internal {
        (bool success, ) = weth.call(abi.encodeWithSelector(IWETH.withdraw.selector, value));
        if (!success) { 
            revert("KekotronErrors.WethWithdraw"); 
        }
    }
}