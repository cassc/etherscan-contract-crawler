//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract StrategyMock {
    using SafeERC20 for IERC20;

    uint256 gain;
    address token;
    uint256 amount;

    constructor(address _token, uint256 _gain) public {
        token = _token;
        gain = _gain;
    }

    function deposit(uint256 _amount) public {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        amount = _amount;
    }

    function withdraw() public {
        IERC20(token).safeTransfer(msg.sender, (amount * gain) / 10000);
    }

    function setGain(uint256 _gain) public {
        gain = _gain;
    }
}