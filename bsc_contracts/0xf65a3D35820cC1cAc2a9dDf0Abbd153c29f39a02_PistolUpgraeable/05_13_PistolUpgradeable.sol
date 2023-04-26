/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./token/ERC1155Upgradeable.sol";
import "./utils/Initializable.sol";
import "./access/OwnableUpgradeable.sol";
import "./utils/Strings.sol";

contract PistolUpgraeable is
  Initializable,
  ERC1155Upgradeable,
  OwnableUpgradeable
{
  function __pistolUpgradeable__init() public initializer {
    __ERC1155_init("");
    __Ownable_init();
  }

  /**
   * @dev function mint token
   * @param account - on which account nft will mint
   * @param id - pistol id
   * @param amount - amount
   * @param data - string
   */
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyOwner {
    _mint(account, id, amount, data);
  }

  /**
   * @dev function mint token
   * @param to - on which account nft will mint
   * @param ids - array of pistol ids
   * @param amounts - array of amounts
   * @param data - string
   */
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  /**
   * @dev uri
   * @param _tokenId - nft token id
   * @return - token metadata uri
   */
  function uri(uint256 _tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(_uri, Strings.toString(_tokenId), ".json"));
  }

  /**
   * @dev admin can update uri later on
   * @param _newUri - new ipfs uri
   */
  function updateBaseUri(string memory _newUri) external onlyOwner {
    _setURI(_newUri);
  }
}