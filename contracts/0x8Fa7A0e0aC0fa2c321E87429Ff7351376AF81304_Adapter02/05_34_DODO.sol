// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IDODO.sol";

contract DODO {
    struct DODOData {
        address[] dodoPairs;
        uint256 directions;
    }

    address public immutable erc20ApproveProxy;
    uint256 public immutable dodoSwapLimitOverhead;

    constructor(address _erc20ApproveProxy, uint256 _swapLimitOverhead) public {
        dodoSwapLimitOverhead = _swapLimitOverhead;
        erc20ApproveProxy = _erc20ApproveProxy;
    }

    function swapOnDodo(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        DODOData memory dodoData = abi.decode(payload, (DODOData));

        Utils.approve(erc20ApproveProxy, address(fromToken), fromAmount);

        IDODO(exchange).dodoSwapV1{ value: address(fromToken) == Utils.ethAddress() ? fromAmount : 0 }(
            address(fromToken),
            address(toToken),
            fromAmount,
            1,
            dodoData.dodoPairs,
            dodoData.directions,
            false,
            block.timestamp + dodoSwapLimitOverhead
        );
    }
}