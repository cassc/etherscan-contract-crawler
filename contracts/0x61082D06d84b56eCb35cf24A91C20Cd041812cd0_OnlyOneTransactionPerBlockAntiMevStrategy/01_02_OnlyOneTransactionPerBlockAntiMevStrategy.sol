// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../interfaces/IAntiMevStrategy.sol";

/// @title
/// @author
/// @notice This contains the logic necessary for blocking MEV bots from frontrunning transactions.
contract OnlyOneTransactionPerBlockAntiMevStrategy is IAntiMevStrategy {
  error OnlyOneTransferPerBlockPerAddress(address);
  error OnlyBen();

  address private ben;
  mapping(bytes32 accountHash => bool[2] directions) private accountTransferredPerBlock;

  modifier onlyBen() {
    if (msg.sender != ben) {
      revert OnlyBen();
    }
    _;
  }

  constructor(address _ben) {
    ben = _ben;
  }

  function onTransfer(
    address _from,
    address _to,
    bool _fromIsWhitelisted,
    bool _toIsWhitelisted,
    uint256 /*_amount*/,
    bool _isTaxingInProgress
  ) external override onlyBen {
    if (!_isTaxingInProgress) {
      if (!_fromIsWhitelisted) {
        bytes32 key = keccak256(abi.encodePacked(block.number, _from));
        if (accountTransferredPerBlock[key][1]) {
          revert OnlyOneTransferPerBlockPerAddress(_from);
        }
        accountTransferredPerBlock[key][0] = true;
      }
      if (!_toIsWhitelisted) {
        bytes32 key = keccak256(abi.encodePacked(block.number, _to));
        if (accountTransferredPerBlock[key][0]) {
          revert OnlyOneTransferPerBlockPerAddress(_to);
        }
        accountTransferredPerBlock[key][1] = true;
      }
    }
  }
}