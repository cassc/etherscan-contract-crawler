// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../libraries/SSTORE2Map.sol';
import '../interfaces/IDataStorage.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract AdminEditableStorage is IDataStorage, Ownable, ERC165 {
  address public writer;
  mapping(uint256 => bytes) indexedData;

  constructor() {}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IDataStorage).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function setWriter(address _writer) public onlyOwner {
    writer = _writer;
  }

  function editData(uint256 index, bytes calldata data) public {
    require(
      writer == msg.sender,
      'AdminWritableStorage: Only writer can write to storage.'
    );
    indexedData[index] = data;
  }

  function indexToData(uint256 index) public view returns (bytes memory) {
    return indexedData[index];
  }
}