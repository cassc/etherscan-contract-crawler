// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC721Snapshot.sol";

error AlreadyMinted();
error WrongOwner();

contract ForeverNft is ERC721, ERC721Snapshot, AccessControl {
  bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
  IERC721 public immutable _manifoldContract;
  mapping (uint => address) public manifoldMints;

  constructor(address manifoldContractAddress) ERC721("ForeverPunks", "FOREVER") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _manifoldContract = IERC721(manifoldContractAddress);
  }

  function initialiseSnapshots(address snapshotOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(SNAPSHOT_ROLE, snapshotOwner);
  }

  function createSnapshot() public onlyRole(SNAPSHOT_ROLE) returns (uint256) {
    return _snapshot();
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://arweave.net/IWDfUhz40vceST-XbfFCs5UfwtO6t7iYLXci_omtSng";
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    return _baseURI();
  }

  function safeMintBulk(uint[] calldata tokenIds) public {
    for (uint256 i = tokenIds.length; i > 0;) {
      safeMint(tokenIds[i - 1]);
      unchecked{ --i; }
    }
  }

  function safeMint(uint256 tokenId) private {
    if (_manifoldContract.ownerOf(tokenId) != msg.sender) revert WrongOwner();
    if (manifoldMints[tokenId] != address(0)) revert AlreadyMinted();

    manifoldMints[tokenId] = msg.sender;
    _safeMint(msg.sender, tokenId);
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Snapshot)
  {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Snapshot, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}