// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGaiminERC1155.sol";


contract GaiminERC1155 is ERC1155, IGaiminERC1155, Ownable {
  
  address public minter;

  event Minter(
    address newMinter,
    uint256 timestamp
  );

  event Mint(
    address account,
    uint256 id,
    uint256 amount
  );

  event MintBatch(
    address   to,
    uint256[] ids,
    uint256[] amounts
  );

  constructor() ERC1155("ipfs://QmVC89SCSQ5KuXJZ2MtMggNDourLbA9Pa8HrMd9XpF835P/{id}.json") {}

  modifier onlyGaiminICOContract {
    require(minter == msg.sender, "Only GaiminICO contract can mint or burn token");
    _;
  }

  function setURI(string memory newuri) external onlyOwner {
    _setURI(newuri);
  }

  function mint(address account, uint256 id, uint256 amount, bytes memory data) external override onlyGaiminICOContract {
    _mint(account, id, amount, data);
    emit Mint(account, id, amount);
  }

  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external override onlyGaiminICOContract {
    _mintBatch(to, ids, amounts, data);
    emit MintBatch(to, ids, amounts);
  }

  function burn(address account, uint256 id, uint256 value) external override onlyGaiminICOContract {
    _burn(account, id, value);
  }

  function setMinter(address newMinter) external onlyOwner {
    require(newMinter != address(0), "Invalid address");
    minter = newMinter;
    emit Minter(newMinter, block.timestamp);
  }

}