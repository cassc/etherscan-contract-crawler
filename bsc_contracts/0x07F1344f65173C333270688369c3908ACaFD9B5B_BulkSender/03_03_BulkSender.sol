// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract BulkSender is Ownable {
    
    receive() external payable {}

    function multiSend(address[] calldata to, uint256[] calldata amount) external payable onlyOwner {
        require(to.length == amount.length, "unequal lists");
        for (uint256 i = 0; i < to.length; i++) {
            (bool sent, ) = to[i].call{value: amount[i]}("");
            require(sent, "multiple ether send failed");
        }
    }

    function multiTransfer(address token, address[] calldata to, uint256[] calldata amount) external onlyOwner {
        require(to.length == amount.length, "unequal lists");
        for (uint256 i = 0; i < to.length; i++) {
            require(IERC20(token).transfer(to[i], amount[i]), "multiple token transfer failed");
        }
    }

    function multiTransferFrom(address token, address[] calldata to, uint256[] calldata amount) external onlyOwner {
        require(to.length == amount.length, "unequal lists");
        for (uint256 i = 0; i < to.length; i++) {
            require(IERC20(token).transferFrom(_msgSender(), to[i], amount[i]), "multiple token transferFrom failed");
        }
    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(to, amount), "withdraw token failed");
    }
}