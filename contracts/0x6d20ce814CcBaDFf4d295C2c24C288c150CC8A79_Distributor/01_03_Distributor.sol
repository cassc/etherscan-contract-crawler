//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Distributor is Ownable {
    function distribute(address[] calldata to, uint256 amountEach) external onlyOwner {
        for (uint256 i; i < to.length; i++) {
            to[i].call{ value: amountEach }("");
        }
    }

    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "address(0)");
        (bool succeed, ) = _to.call{ value: address(this).balance }("");
        require(succeed, "Failed to withdraw Ether");
    }

    receive() external payable {}
}