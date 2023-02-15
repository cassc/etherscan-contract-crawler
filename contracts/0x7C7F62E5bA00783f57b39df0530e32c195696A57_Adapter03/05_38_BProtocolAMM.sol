// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IBProtocolAMM.sol";

contract BProtocol {
    function swapOnBProtocol(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        Utils.approve(address(exchange), address(fromToken), fromAmount);

        IBProtocolAMM(exchange).swap(fromAmount, 1, payable(address(this)));
    }
}