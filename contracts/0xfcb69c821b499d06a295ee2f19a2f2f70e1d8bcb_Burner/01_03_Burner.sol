// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
contract Burner {
    // Mapping of address to uint256
    function burn(uint256 amount, address tokenAddress) public {
        IERC20 yariToken = IERC20(tokenAddress);
        yariToken.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, amount);
        
    }
}