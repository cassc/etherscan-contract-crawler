// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Ownable.sol";

contract RaffleGov is Ownable{
    address public govAddress;
    constructor(address _gov){
        govAddress = _gov;
    }
    modifier onlyGov{
        require(msg.sender == govAddress, "!gov");
        _;
    }
    function setGov(address gov) external onlyOwner {
        govAddress = gov;
    }
}