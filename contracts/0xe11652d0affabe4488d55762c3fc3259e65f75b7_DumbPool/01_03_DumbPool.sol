// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";


contract DumbPool is Ownable {

    receive() external payable {
  }
    function withdraw() external onlyOwner {
        address owner = this.owner();
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
  }
}