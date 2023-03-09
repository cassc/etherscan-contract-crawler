// SPDX-License-Identifier: UNLICENSED

import "Guardable/ERC1155Guardable.sol";
import "solmate/auth/Owned.sol";
import "./lib/MarauderErrors.sol";

pragma solidity 0.8.18;

contract MadMarauderMysterySerum is ERC1155Guardable, Owned {
  uint256 private constant SERUM_TOKEN_ID = 1;
  address public immutable BOX_O_BAD_GUYS_CONTRACT_ADDRESS;
  address public consumer;

  string public constant name = "Mad Marauder Mystery Serum";
  string public constant symbol = "SERUM";

  constructor(string memory _uri, address _mintPassContractAddress) ERC1155Guardable(_uri) Owned(msg.sender) {
    BOX_O_BAD_GUYS_CONTRACT_ADDRESS = _mintPassContractAddress;
  }

  function mintFromBox(address recipient, uint256 amount) external {
    if (msg.sender != BOX_O_BAD_GUYS_CONTRACT_ADDRESS) revert InvalidCaller();
    _mint(recipient, SERUM_TOKEN_ID, amount, "");
  }

  function setSerumConsumer(address _consumer) external onlyOwner {
    if (consumer != address(0)) revert ConsumerAlreadySet();

    consumer = _consumer;
  }

  function setUri(string calldata _uri) external onlyOwner {
    _setURI(_uri);
  }

  function burn(address from, uint256 amount) external {
    if (msg.sender != consumer || !isApprovedForAll(from, msg.sender)) revert InvalidCaller();

    _burn(from, SERUM_TOKEN_ID, amount);
  }
}