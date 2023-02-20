/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

pragma solidity ^0.4.21;


contract IERC20 {
  function transfer(address _owner, uint256 _value) public returns (bool success);
}

contract BulkTransfer {
  address owner;

  constructor() public {
    owner = msg.sender;
  }

  function bulkTransfer(IERC20 token, address[] _addresses, uint256[] _amounts) public {
    require(msg.sender == owner);
    for (uint256 i = 0; i < _addresses.length; i++) {
      token.transfer(_addresses[i], _amounts[i]*1e18);
    }
  }
}