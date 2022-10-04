pragma solidity ^0.4.24;

contract Ownable {

    address public owner;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Address is not an owner");
        _;
    }

    function transferOwnership (address newOwner) public onlyOwner {
        require(newOwner != address(0), "New Address is not valid address");
        owner = newOwner;
    }
}

interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external view returns (uint256 balance);
}