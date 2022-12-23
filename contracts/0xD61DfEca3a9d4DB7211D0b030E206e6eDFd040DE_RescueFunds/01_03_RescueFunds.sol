// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RescueFunds is Ownable {
    constructor() {}

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    receive() external payable {}

    fallback() external payable {}
}