// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IMeritToken.sol";

contract TokenBurner {

    IMeritToken public immutable token;

    event Burn(address indexed burner, uint256 amount);

    constructor(address _token) {
        token = IMeritToken(_token);
    }

    function burn() external {
        uint256 burnAmount = token.balanceOf(address(this));
        token.burn(address(this), burnAmount);
        emit Burn(msg.sender, burnAmount);
    }

}