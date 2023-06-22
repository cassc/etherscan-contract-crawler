// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Order is Ownable, ReentrancyGuard {    
    address public FMBAddress = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;

    event OrderByFMB(address player, uint256 amount, string indexed verify);

    function buyFMB(uint256 amount, string calldata verify) nonReentrant external {
        require(bytes(verify).length > 0, "Verify not empty");
        IERC20 FMB = IERC20(FMBAddress);
        FMB.transferFrom(msg.sender, address(this), amount);
        emit OrderByFMB(msg.sender, amount, verify);
    }

    function setFMBAddress(address newAddress) onlyOwner external {
        FMBAddress = newAddress;
    }

    function withdraw() onlyOwner external  nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawTokens(address _token, uint256 _amount) onlyOwner external nonReentrant {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, _amount);
    }
}