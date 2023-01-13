// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IERC165} from "./interfaces/IERC165.sol";
import {IERC173} from "./interfaces/IERC173.sol";

// NOTE: can we use the openzeppelin Ownable

contract Ownable is IERC173 {
  address public owner;

  constructor(address _owner) {
    owner = _owner;
  }

  /// @inheritdoc IERC173
  function transferOwnership(address _newOwner) external onlyOwner {
    address previousOwner = owner;
    owner = _newOwner;

    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return interfaceId == 0x7f5828d0;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert NotOwner();
    }
    _;
  }

  error NotOwner();
}