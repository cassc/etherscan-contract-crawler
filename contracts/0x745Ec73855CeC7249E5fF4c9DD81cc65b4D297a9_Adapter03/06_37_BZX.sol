// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IBZX.sol";
import "../Utils.sol";
import "../WethProvider.sol";

abstract contract BZX is WethProvider {
    struct BZXData {
        address iToken;
    }

    function swapOnBzx(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnBZX(fromToken, toToken, fromAmount, payload);
    }

    function buyOnBzx(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnBZX(fromToken, toToken, fromAmount, payload);
    }

    function _swapOnBZX(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes memory payload
    ) private {
        BZXData memory data = abi.decode(payload, (BZXData));

        Utils.approve(address(data.iToken), address(fromToken), fromAmount);

        if (address(fromToken) == address(data.iToken)) {
            if (address(toToken) == Utils.ethAddress()) {
                require(IBZX(data.iToken).loanTokenAddress() == WETH, "Invalid to token");
                IBZX(data.iToken).burnToEther(payable(address(this)), fromAmount);
            } else {
                require(IBZX(data.iToken).loanTokenAddress() == address(toToken), "Invalid to token");
                IBZX(data.iToken).burn(address(this), fromAmount);
            }
        } else if (address(toToken) == address(data.iToken)) {
            if (address(fromToken) == Utils.ethAddress()) {
                require(IBZX(data.iToken).loanTokenAddress() == WETH, "Invalid from token");

                IBZX(data.iToken).mintWithEther{ value: fromAmount }(address(this));
            } else {
                require(IBZX(data.iToken).loanTokenAddress() == address(fromToken), "Invalid from token");
                IBZX(data.iToken).mint(address(this), fromAmount);
            }
        } else {
            revert("Invalid token pair!!");
        }
    }
}