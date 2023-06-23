pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./library/LibSafeMath.sol";
import "./mixin/MixinOwnable.sol";
import "./ERC721.sol";
import "./mixin/MixinOwnable.sol";
import "./HashRegistry.sol";
import "./ERC1155Mintable.sol";
import "./HashV2.sol";

contract HashRegistryV2 is Ownable {
  uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

  HashV2 public immutable hashV2;
  ERC1155Mintable public immutable originalHash;
  HashRegistry public immutable originalHashRegistry;

  mapping(uint256 => uint256) private tokenIdToTxHash_;
  mapping(uint256 => uint256) private txHashToTokenId_;
  mapping(address => bool) public permissedWriters;

  constructor(
    address originalHashRegistry_,
    address originalHash_,
    address hashV2_
  ) {
    originalHashRegistry = HashRegistry(originalHashRegistry_);
    originalHash = ERC1155Mintable(originalHash_);
    hashV2 = HashV2(hashV2_);
  }

  event UpdatedRegistry(
      uint256 tokenId,
      uint256 txHash
  );

  modifier onlyIfPermissed(address writer) {
    require(permissedWriters[writer] == true, "writer can't write to registry");
    _;
  }

  function updatePermissedWriterStatus(address _writer, bool status) public onlyOwner {
    permissedWriters[_writer] = status;
  }

  function writeToRegistry(uint256[] memory tokenIds, uint256[] memory txHashes) public onlyIfPermissed(msg.sender) {
    require(tokenIds.length == txHashes.length, "tokenIds and txHashes size mismatch");
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      uint256 txHash = txHashes[i];
      require(txHashToTokenId_[txHash] == 0, 'txHash already exists');
      require(tokenIdToTxHash_[tokenId] == 0, 'tokenId already exists');
      tokenIdToTxHash_[tokenId] = txHash;
      txHashToTokenId_[txHash] = tokenId;
      emit UpdatedRegistry(tokenId, txHash); 
    }
  }

  function tokenIdToTxHash(uint id) public view returns (uint256) {
    if (tokenIdToTxHash_[id] == 0 && originalHashRegistry.tokenIdToTxHash(id) != 0) {
      return originalHashRegistry.tokenIdToTxHash(id); 
    }
    return tokenIdToTxHash_[id]; 
  }

  function txHashToTokenId(uint txHash) public view returns (uint256) {
    if (txHashToTokenId_[txHash] == 0 && originalHashRegistry.txHashToTokenId(txHash) != 0) {
      return originalHashRegistry.txHashToTokenId(txHash); 
    }
    return txHashToTokenId_[txHash]; 
  }

  function _getNonFungibleBaseType(uint256 id) pure internal returns (uint256) {
    return id & TYPE_MASK;
  }

  function isMigrated(uint id) public view returns (bool) {
    uint tokenType = _getNonFungibleBaseType(id);
    try hashV2.ownerOf(id) returns (address owner) {
      return owner != address(0) && (originalHash.ownerOf(id) == address(0xdead));
    }
    catch (bytes memory _err) {
      return false;
    }
  }

  function ownerOf(uint id) public view returns (address) {
    uint tokenType = _getNonFungibleBaseType(id);
    address oldOwner = originalHash.ownerOf(id);
    try hashV2.ownerOf(id) returns (address owner) {
      if (owner == address(0) && oldOwner != address(0)) {
        return oldOwner;
      }
      return owner;
    }
    catch (bytes memory _err) {
      return oldOwner;
    }
  }

  function ownerOfByTxHash(uint txHash) public view returns (address) {
    uint id = txHashToTokenId(txHash);
    return ownerOf(id);
  } 
}