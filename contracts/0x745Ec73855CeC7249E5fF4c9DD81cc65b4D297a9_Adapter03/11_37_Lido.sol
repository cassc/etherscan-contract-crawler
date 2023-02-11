// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IstETH.sol";

contract Lido {
    address public immutable stETH;

    constructor(address _stETH) public {
        stETH = _stETH;
    }

    function swapOnLido(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        require(address(fromToken) == Utils.ethAddress(), "srcToken should be ETH");
        require(address(toToken) == stETH, "destToken should be stETH");

        IstETH(stETH).submit{ value: fromAmount }(address(0));
    }
}