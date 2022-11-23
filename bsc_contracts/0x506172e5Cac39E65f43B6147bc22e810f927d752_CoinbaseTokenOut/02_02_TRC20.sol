pragma solidity ^0.4.25;

contract TRC20 {
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function transfer(address to, uint value) public returns (bool ok);
}