pragma solidity 0.5.17;

import "./TestCERC20.sol";

contract TestCERC20Factory {
  mapping(address => address) public createdTokens;

  event CreatedToken(address underlying, address cToken);

  function newToken(address underlying, address comptroller) public returns(address) {
    require(createdTokens[underlying] == address(0));
    
    TestCERC20 token = new TestCERC20(underlying, comptroller);
    createdTokens[underlying] = address(token);
    emit CreatedToken(underlying, address(token));
    return address(token);
  }
}