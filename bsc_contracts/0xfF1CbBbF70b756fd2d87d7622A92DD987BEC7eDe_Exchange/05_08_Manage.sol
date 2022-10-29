// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Manage is Ownable {
    mapping(address => bool) public manage;

    modifier onlyManage() {
        require(manage[_msgSender()], "Not manage");
        _;
    }

    function addManage(address _manage) external onlyOwner {
        manage[_manage] = true;
        emit AddManage(msg.sender);
    }

    function removeManage(address _manage) external onlyOwner {
        manage[_manage] = false;
        emit RemoveManage(msg.sender);
    }

    event AddManage(address manage);
    event RemoveManage(address manage);
}