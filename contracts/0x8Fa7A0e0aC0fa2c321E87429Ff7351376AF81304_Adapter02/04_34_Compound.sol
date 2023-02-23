// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICompound.sol";
import "../Utils.sol";

contract Compound {
    struct CompoundData {
        address cToken;
    }

    address public immutable ceth;

    constructor(address _ceth) public {
        ceth = _ceth;
    }

    function swapOnCompound(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        _swapOnCompound(fromToken, toToken, fromAmount, exchange, payload);
    }

    function buyOnCompound(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        _swapOnCompound(fromToken, toToken, fromAmount, exchange, payload);
    }

    function _swapOnCompound(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes memory payload
    ) private {
        CompoundData memory compoundData = abi.decode(payload, (CompoundData));

        Utils.approve(address(compoundData.cToken), address(fromToken), fromAmount);

        if (address(fromToken) == address(compoundData.cToken)) {
            if (address(toToken) == Utils.ethAddress()) {
                require(address(fromToken) == ceth, "Invalid to token");
            } else {
                require(ICERC20(compoundData.cToken).underlying() == address(toToken), "Invalid from token");
            }

            ICToken(compoundData.cToken).redeem(fromAmount);
        } else if (address(toToken) == address(compoundData.cToken)) {
            if (address(fromToken) == Utils.ethAddress()) {
                require(address(toToken) == ceth, "Invalid to token");

                ICEther(compoundData.cToken).mint{ value: fromAmount }();
            } else {
                require(ICERC20(compoundData.cToken).underlying() == address(fromToken), "Invalid from token");

                ICERC20(compoundData.cToken).mint(fromAmount);
            }
        } else {
            revert("Invalid token pair");
        }
    }
}