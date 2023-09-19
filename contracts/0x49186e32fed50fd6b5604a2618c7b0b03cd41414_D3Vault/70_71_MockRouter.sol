// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "contracts/intf/ID3Oracle.sol";
import "./MockERC20.sol";

contract MockRouter {
    address public oracle;
    bool public enable = true;
    uint256 public slippage = 100;

    constructor(address _oracle) {
        oracle = _oracle;
    }

    function enableRouter() public {
        enable = true;
    }

    function disableRouter() public {
        enable = false;
    }

    function setSlippage(uint256 s) public {
        slippage = s;
    }

    function swap(address fromToken, address toToken, uint256 fromAmount) public {
        require(enable, "router not available");
        uint256 fromTokenPrice = ID3Oracle(oracle).getPrice(fromToken);
        uint256 toTokenPrice = ID3Oracle(oracle).getPrice(toToken);
        uint256 toAmount = (fromAmount * fromTokenPrice) / toTokenPrice;
        toAmount = toAmount * slippage / 100;
        MockERC20(toToken).transfer(msg.sender, toAmount);
    }

    // Make forge coverage ignore
    function testSuccess() public {}
}