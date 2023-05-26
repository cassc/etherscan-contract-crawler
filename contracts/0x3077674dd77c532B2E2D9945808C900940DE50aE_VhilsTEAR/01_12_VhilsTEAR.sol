// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155Supply, ERC1155 } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

//                                                                           %/
// %@@@            @@@@@/     @@@#   @@@    [email protected]@@@@@@@@(   @@@@@@@@@@@    @@@@ *@@@@
// %@@@           @@@ @@@      ,@@@@@@@     [email protected]@@          @@@     @@@    @@@@
// %@@@          @@@   @@@       @@@@       [email protected]@@@@@@@@    @@@@@@@@@@       @@@@@@@@
// %@@@         @@@@@@@@@@@      ,@@@       [email protected]@@          @@@     @@@   &@@(    @@@
// %@@@@@@@@%  *@@@      @@@     ,@@@       [email protected]@@@@@@@@(   @@@     @@@     @@@@@@@@

// Vhils + DRP + Pellar 2022

contract VhilsTEAR is Ownable, ERC1155Supply, ERC1155Burnable {
  struct TokenInfo {
    bool saleActive;
    bool tokenPaused;
    uint256 price;
    string uri;
  }

  // constants
  string public constant symbol = "TEAR";

  // variables
  mapping(uint256 => TokenInfo) public tokens;
  mapping(address => bool) public whitelistContracts;

  constructor() ERC1155("") {
    tokens[1].price = 0.1 ether; // alpha
    tokens[2].price = 0.1 ether; // beta
    tokens[1].uri = 'ipfs://Qmc3HLfeWznKZtSyHdNi5o2kN9cQ6muTnvRvkYF5uGpGTd';
    tokens[2].uri = 'ipfs://Qmd7rYdLVGpqMq9dSYHfT4PSFXmy4yNSrjCZHub3KGTEwW';

    _mint(msg.sender, 1, 15000, ""); // mint alpha
  }

  function mint(uint256 _id, uint256 _amount) external payable {
    require(tx.origin == msg.sender, "Not allowed");
    require(tokens[_id].saleActive, "Not active");
    require(_amount <= 10, "Exceed txn");
    require(msg.value >= _amount * tokens[_id].price, "Ether value incorrect");

    _mint(msg.sender, _id, _amount, "");
  }

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
    if (tx.origin != msg.sender && whitelistContracts[msg.sender]) {
      _safeTransferFrom(from, to, id, amount, data);
      return;
    }
    super.safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
    if (tx.origin != msg.sender && whitelistContracts[msg.sender]) {
      _safeBatchTransferFrom(from, to, ids, amounts, data);
      return;
    }
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      require(from == address(0) || !tokens[ids[i]].tokenPaused, "Token paused");
    }
  }

  function setTokenURIs(uint256[] memory _ids, string[] calldata _uris) external onlyOwner {
    require(_ids.length == _uris.length, "Input mismatch");
    for (uint256 i = 0; i < _ids.length; i++) {
      tokens[_ids[i]].uri = _uris[i];
    }
  }

  function adminMint(uint256 _id, uint256 _amount) external onlyOwner {
    _mint(msg.sender, _id, _amount, "");
  }

  function toggleSale(uint256 _id, bool _status) external onlyOwner {
    tokens[_id].saleActive = _status;
  }

  function setTokenPaused(uint256 _id, bool _status) external onlyOwner {
    tokens[_id].tokenPaused = _status;
  }

  function setWhitelistContracts(address[] calldata _contracts, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _contracts.length; i++) {
      whitelistContracts[_contracts[i]] = _status;
    }
  }

  function setTokenPrice(uint256 _id, uint256 _newPrice) external onlyOwner {
    tokens[_id].price = _newPrice;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function uri(uint256 _tokenId) public view virtual override returns (string memory) {
    return tokens[_tokenId].uri;
  }
}