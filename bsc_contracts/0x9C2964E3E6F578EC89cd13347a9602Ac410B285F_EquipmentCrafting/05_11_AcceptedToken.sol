//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PermissionGroup.sol";

contract AcceptedToken is PermissionGroup {
    IERC20 public acceptedToken; // Token to be used in the ecosystem.

    constructor(IERC20 tokenAddress) {
        acceptedToken = tokenAddress;
    }

    modifier collectTokenAsFee(uint amount, address destAddr) {
        require(acceptedToken.balanceOf(msg.sender) >= amount, "AcceptedToken: insufficient token balance");
        _;
        acceptedToken.transferFrom(msg.sender, destAddr, amount);
    }

    /**
     * @dev Sets accepted token using in the ecosystem.
     */
    function setAcceptedTokenContract(IERC20 tokenAddr) external onlyOwner {
        acceptedToken = tokenAddr;
    }
}