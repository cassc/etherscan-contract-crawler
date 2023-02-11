// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAavee.sol";
import "../Utils.sol";

contract Aavee {
    struct AaveeDataV1 {
        address aToken;
    }

    uint16 public immutable refCodeV1;
    address public immutable spender;

    constructor(uint16 _refCode, address _spender) public {
        refCodeV1 = _refCode;
        spender = _spender;
    }

    function swapOnAavee(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        _swapOnAavee(fromToken, toToken, fromAmount, exchange, payload);
    }

    function buyOnAavee(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        _swapOnAavee(fromToken, toToken, fromAmount, exchange, payload);
    }

    function _swapOnAavee(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes memory payload
    ) private {
        AaveeDataV1 memory data = abi.decode(payload, (AaveeDataV1));

        Utils.approve(spender, address(fromToken), fromAmount);

        if (address(fromToken) == address(data.aToken)) {
            require(IAaveToken(data.aToken).underlyingAssetAddress() == address(toToken), "Invalid to token");

            IAaveToken(data.aToken).redeem(fromAmount);
        } else if (address(toToken) == address(data.aToken)) {
            require(IAaveToken(data.aToken).underlyingAssetAddress() == address(fromToken), "Invalid to token");
            if (address(fromToken) == Utils.ethAddress()) {
                IAaveV1LendingPool(exchange).deposit{ value: fromAmount }(fromToken, fromAmount, refCodeV1);
            } else {
                IAaveV1LendingPool(exchange).deposit(fromToken, fromAmount, refCodeV1);
            }
        } else {
            revert("Invalid aToken");
        }
    }
}