// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../exchange/IHasSecondarySaleFees.sol";

contract TrashArtERC1155 is IHasSecondarySaleFees, Ownable, ERC1155 {
  string public name;
  string public symbol;
  uint256 public nextTokenId;

  mapping(uint256 => Fee[]) public fees;
  mapping(uint256 => address) public creators;

  event SecondarySaleFees(uint256 tokenId, address[] recipients, uint256[] bps);

  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 internal constant SECONDARY_FEE_INTERFACE_ID = 0xb7799584;

  struct Fee {
    address payable recipient;
    uint256 value;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _uri
  ) ERC1155(_uri) {
    name = _name;
    symbol = _symbol;
  }

  function setURI(string memory newuri) external onlyOwner {
    _setURI(newuri);
  }

  function getFeeRecipients(uint256 id) external view override returns (address payable[] memory) {
    Fee[] memory _fees = fees[id];
    address payable[] memory result = new address payable[](_fees.length);
    for (uint256 i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].recipient;
    }
    return result;
  }

  function getFeeBps(uint256 id) external view override returns (uint256[] memory) {
    Fee[] memory _fees = fees[id];
    uint256[] memory result = new uint256[](_fees.length);
    for (uint256 i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].value;
    }
    return result;
  }

  function mint(
    address _to,
    uint256 _amount,
    Fee[] memory _fees
  ) external onlyOwner {
    _mint(_to, nextTokenId, _amount, "");
    addSecondaryFee(nextTokenId++, _fees);
  }

  function mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    Fee[] memory _fees
  ) external onlyOwner {
    require(_id < nextTokenId, "Invalid Token ID");
    _mint(_to, _id, _amount, "");
    addSecondaryFee(_id, _fees);
  }

  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory amounts,
    Fee[][] memory _fees
  ) external onlyOwner {
    _mintBatch(_to, _ids, amounts, "");
    for (uint256 i = 0; i < _fees.length; i++) {
      require(_ids[i] < nextTokenId, "Invalid Token ID");
      addSecondaryFee(_ids[i], _fees[i]);
    }
  }

  function mintBatch(
    address _to,
    uint256[] memory amounts,
    Fee[][] memory _fees
  ) external onlyOwner {
    uint256[] memory _ids = new uint256[](amounts.length);
    for (uint256 i = 0; i < _fees.length; i++) {
      _ids[i] = nextTokenId++;
      addSecondaryFee(_ids[i], _fees[i]);
    }
    _mintBatch(_to, _ids, amounts, "");
  }

  function addSecondaryFee(uint256 _id, Fee[] memory _fees) internal {
    creators[_id] = msg.sender;
    address[] memory recipients = new address[](_fees.length);
    uint256[] memory bps = new uint256[](_fees.length);
    for (uint256 i = 0; i < _fees.length; i++) {
      require(_fees[i].recipient != address(0x0), "Recipient should be present");
      require(_fees[i].value != 0, "Fee value should be positive");
      fees[_id].push(_fees[i]);
      recipients[i] = _fees[i].recipient;
      bps[i] = _fees[i].value;
    }
    if (_fees.length > 0) {
      emit SecondarySaleFees(_id, recipients, bps);
    }
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return interfaceId == SECONDARY_FEE_INTERFACE_ID || super.supportsInterface(interfaceId);
  }
}