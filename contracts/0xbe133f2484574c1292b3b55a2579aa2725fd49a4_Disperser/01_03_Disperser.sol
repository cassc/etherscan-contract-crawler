// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20WithDecimals {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract Disperser is Ownable {
    function disperseEther(address payable[] memory recipients, uint value) external payable onlyOwner {
        for (uint i = 0; i < recipients.length; i++) {
            recipients[i].transfer(value);
        }
    }

    function disperseTokens(IERC20WithDecimals token, address[] memory recipients, uint value) external onlyOwner {
        uint tokenValue = value * (10 ** uint(token.decimals()));
        for (uint i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], tokenValue);
        }
    }
}