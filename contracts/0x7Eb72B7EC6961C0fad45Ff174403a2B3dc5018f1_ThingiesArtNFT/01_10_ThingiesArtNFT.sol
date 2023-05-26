//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";

contract ThingiesArtNFT is ERC721A, AccessControl, Ownable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bool public PAUSED = false;
  string public tokenUriBase;

  event PausedUpdated(bool indexed state);
  event TokenURIUpdated(string indexed url);

  constructor() ERC721A("FLUF World: Art by Thingies", "THINGIESART") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /* @dev: Pause/Unpause the contract mints
   * @param: _state - true/false
   */
  function setPaused(bool _state) external onlyOwner {
    PAUSED = _state;
    emit PausedUpdated({state: _state});
  }

  /* @dev: Returns tokenUri for desired tokenId
   * @return: tokenId - The tokenId to append to the tokenUriBase
   */
  function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
    return string(abi.encodePacked(tokenUriBase, _toString(tokenId)));
  }

  /* @dev: Updates the Token URI Base
   * @param: _tokenUriBase - The tokenURI base to update to
   */
  function setTokenURI(string calldata _tokenUriBase) public onlyOwner {
    tokenUriBase = _tokenUriBase;
    emit TokenURIUpdated({url: _tokenUriBase});
  }

  /* @dev: Mints NFT to desired wallet
   * @param: walletAddress - The walletAddress to mint to
   * @param: quantity - The quantity to mint
   */
  function mint(address walletAddress, uint256 quantity) external onlyRole(MINTER_ROLE) {
    require(!PAUSED, "Minting is paused");
    _safeMint(walletAddress, quantity);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}