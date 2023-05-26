pragma solidity ^0.7.3;

import "./library/LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./mixin/MixinOwnable.sol";

contract HashRegistry is Ownable {
  using LibSafeMath for uint256;

  ERC1155Mintable public mintableErc1155;

  mapping(uint256 => uint256) public tokenIdToTxHash;
  mapping(uint256 => uint256) public txHashToTokenId;
  mapping(address => bool) public permissedWriters;

  constructor(
    address _mintableErc1155
  ) {
    permissedWriters[msg.sender] = true;
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
  }

  event UpdatedRegistry(
      uint256 tokenId,
      uint256 txHash
  );

  modifier onlyIfPermissed(address writer) {
    require(permissedWriters[writer] == true, "writer can't write to registry");
    _;
  }

  function updatePermissedWriterStatus(address _writer, bool status) public onlyIfPermissed(msg.sender) {
    permissedWriters[_writer] = status;
  }

  function writeToRegistry(uint256[] memory tokenIds, uint256[] memory txHashes) public onlyIfPermissed(msg.sender) {
    require(tokenIds.length == txHashes.length, "tokenIds and txHashes size mismatch");
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      uint256 txHash = txHashes[i];
      require(mintableErc1155.ownerOf(tokenId) != address(0), 'token does not exist');
      require(txHashToTokenId[txHash] == 0, 'txHash already exists');
      require(tokenIdToTxHash[tokenId] == 0, 'tokenId already exists');
      tokenIdToTxHash[tokenId] = txHash;
      txHashToTokenId[txHash] = tokenId;
      emit UpdatedRegistry(tokenId, txHash); 
    }
  }
}