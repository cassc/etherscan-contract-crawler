// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./SuperpowerNFT.sol";

//import "hardhat/console.sol";

contract WhitelistSlot is ERC1155, Ownable {
  using Address for address;

  error NotTheBurner();
  error NotAContract();
  error InconsistentArrays();

  address internal _burner;

  // solhint-disable-next-line
  constructor() ERC1155("") {
    //    setBurner(burner);
  }

  function setURI(string memory newUri) public onlyOwner {
    _setURI(newUri);
  }

  function setBurner(address burner) public onlyOwner {
    if (!burner.isContract()) {
      revert NotAContract();
    }
    _burner = burner;
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, "");
  }

  function mintMany(
    address[] memory to,
    uint256[][] memory ids,
    uint256[][] memory amounts
  ) public onlyOwner {
    if (to.length != ids.length || ids.length != amounts.length) revert InconsistentArrays();
    for (uint256 i = 0; i < ids.length; i++) {
      _mintBatch(to[i], ids[i], amounts[i], "");
    }
  }

  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) public virtual {
    if (_burner != _msgSender()) {
      revert NotTheBurner();
    }
    _burn(account, id, amount);
  }
}