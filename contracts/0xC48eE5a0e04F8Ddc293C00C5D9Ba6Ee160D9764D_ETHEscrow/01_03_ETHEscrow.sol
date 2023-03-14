pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHEscrow is Ownable {

    receive() external payable {}

    function withdrawETH() external onlyOwner {
        (bool _success, ) = msg.sender.call{value: address(this).balance}("");
        if (!_success)
            revert();
    }

}