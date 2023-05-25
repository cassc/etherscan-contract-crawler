// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GibTransfer is ReentrancyGuard {
    event Transfer(address indexed from, address indexed to, uint256 value, string roleId);

    function transfer(address payable to, string memory roleId) public payable nonReentrant {
        if (isContract(to)) {
            (bool success, ) = to.call{value: msg.value}("");
            require(success, "Transfer failed");
        } else {
            to.transfer(msg.value);
        }
        emit Transfer(msg.sender, to, msg.value, roleId);
    }
    
    function isContract(address _addr) internal view returns (bool) {
        return _addr.code.length > 0;
    }
    
    function transferErc20(address tokenAddress, address owner, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s, string memory roleId) public
    {
        IERC20Permit(tokenAddress).permit(owner, address(this), amount, deadline, v, r, s);
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount, "Transfer not approved");
        require(IERC20(tokenAddress).transferFrom(msg.sender, to, amount), "Transfer failed");
        emit Transfer(msg.sender, to, amount, roleId);
    }
}