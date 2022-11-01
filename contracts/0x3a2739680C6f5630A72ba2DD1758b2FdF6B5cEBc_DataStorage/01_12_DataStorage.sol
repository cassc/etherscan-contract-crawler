// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../libraries/SSTORE2Map.sol';
import '../interfaces/IDataStorage.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract DataStorage is IDataStorage, Ownable, ERC165 {
  constructor() {}

  // index starts from zero, useful to use the 0th index as a empty case.
  uint16 public currentMaxDataIndex = 0;

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

  function batchAddData(bytes[] calldata data) public onlyOwner {
    for (uint16 i = 0; i < data.length; ++i) {
      SSTORE2Map.write(bytes32(uint256(currentMaxDataIndex + i)), data[i]);
    }
    currentMaxDataIndex += uint16(data.length);
  }

  function indexToData(uint256 index) public view returns (bytes memory) {
    return SSTORE2Map.read(bytes32(uint256(index)));
  }
}