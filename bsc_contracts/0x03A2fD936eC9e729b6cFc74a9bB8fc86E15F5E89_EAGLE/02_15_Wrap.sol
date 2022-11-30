// SPDX-License-Identifier: Apache-2.0



import "./Interface/token/ERC20/IERC20.sol";

pragma solidity ^0.8.10;

contract Wrap {
    address public eagle;
    IERC20 public usdt;

    constructor(address _usdt,address _eagle) {
        eagle = _eagle;
        usdt = IERC20(_usdt);
    }

    function withdraw() public {
        require(msg.sender == eagle, "only eagle can withdraw");
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdt.transfer(eagle, usdtBalance);
        }
    }

}