pragma solidity ^0.6.0;


abstract contract IBatchedBancor {
  function transfer(address _token, uint _amount) public virtual;
}