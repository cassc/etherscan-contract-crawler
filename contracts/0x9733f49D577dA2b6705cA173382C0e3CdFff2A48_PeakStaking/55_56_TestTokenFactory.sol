pragma solidity 0.5.17;

import "./TestToken.sol";

contract TestTokenFactory {
  mapping(bytes32 => address) public createdTokens;

  event CreatedToken(string symbol, address addr);

  function newToken(string memory name, string memory symbol, uint8 decimals) public returns(address) {
    bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
    require(createdTokens[symbolHash] == address(0));
    
    TestToken token = new TestToken(name, symbol, decimals);
    token.addMinter(msg.sender);
    token.renounceMinter();
    createdTokens[symbolHash] = address(token);
    emit CreatedToken(symbol, address(token));
    return address(token);
  }

  function getToken(string memory symbol) public view returns(address) {
    return createdTokens[keccak256(abi.encodePacked(symbol))];
  }
}