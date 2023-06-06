pragma solidity ^0.6.0;

contract MockSelfDestruct {
    constructor() public payable {}

    fallback() external payable {
        selfdestruct(msg.sender);
    }

    function kill(address payable target) external payable {
        selfdestruct(target);
    }
}