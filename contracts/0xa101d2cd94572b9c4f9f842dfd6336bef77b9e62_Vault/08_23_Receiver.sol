// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC721Receiver.sol";

contract Receiver is IERC721Receiver {
  error NotAuthorized(address _sender);

  address private owner;

  function __initializeReceiver() external {
    owner = msg.sender;
  }

  function execute(address payable _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory) {
    if (msg.sender != owner) revert NotAuthorized(msg.sender);
    return _to.call{ value: _value }(_data);
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
    // return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    return 0x150b7a02;
  }

  receive() external payable { }
  fallback() external payable { }
}