//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./mixins/ExchangeUniswapV2.sol";

interface IWETH {
    function withdraw(uint wad) external;
    function deposit() external payable;
}

contract ExchangeAggregator is ExchangeUniswapV2 {
    using UniversalERC20 for IERC20;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;


    function exchange(address from, address to, uint256 _amount, bytes calldata _swapParams) internal returns(uint _value) {
        if (to == address(0)) {
            _value = _swap(from, WETH, _amount, _swapParams);

            IERC20(WETH).universalApprove(WETH, _value);
            IWETH(WETH).withdraw(_value);
        } else if (from == address(0)) {
            IWETH(WETH).deposit{value: _amount}();
            IERC20(WETH).balanceOf(address(this));
            _value = _swap(WETH, to, _amount, _swapParams);
        } else {
            _value = _swap(from, to, _amount, _swapParams);
        }
    }
}