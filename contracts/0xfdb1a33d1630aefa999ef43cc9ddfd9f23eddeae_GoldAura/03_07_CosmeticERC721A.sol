// SPDX-License-Identifier: Unliscensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract CosmeticERC721A is ERC721A, Ownable {

  /**
   * @notice address of the cosmetic registry.
   * 
   * @dev used in the { onlyCosmeticRegistry } modifier to make sure 
   * { claim } is only called by the registry.
   */
  address public cosmeticRegistry;

  /**
   * @notice the URI for the cosmetic NFT.
   */
  string public URI;


  /**
   * @notice constructor setting the erc721a name and symbol.
   */
  constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol) {}

  /**
   * @notice modifier to make sure only the cosmetic registry can call { claim }.
   * 
   * @param _address the address to check.
   */
  modifier onlyCosmeticRegistry(address _address) {
    require(_address == cosmeticRegistry, "Only the cosmetic registry can call this function.");
    _;
  }

  /**
   * @notice function to check if an address is eligible for the claim.
   * 
   * @dev override in the cosmetic contract for your own eligibility checks.
   */
  function isEligible(address _address) public virtual returns (bool) {
    _address;
    return false;
  }

  /**
   * @notice function to claim a cosmetic NFT.
   * 
   * @dev mints the NFT to the address if it is called by the cosmetic registry.
   * @param _to the address to mint the NFT to.
   */
  function claim(address _to) public virtual onlyCosmeticRegistry(msg.sender) {
    _mint(_to, 1);
  }

  /**
   * @notice function for the owner to change the cosmeticRegistry address if necessary.
   */
  function setCosmeticRegistry(address _cosmeticRegistry) public onlyOwner {
    cosmeticRegistry = _cosmeticRegistry;
  }

  /**
   * @notice { ER721A } override, returning the URI for the cosmetic NFT.
   * 
   * @param _tokenId the token ID to check.
   */
  function tokenURI(uint256 _tokenId) public override view returns (string memory) {
    // check the token actually exists //
    require(_exists(_tokenId), "TokenID does not exist");

    // return the URI //
    return URI;
  }

  /**
   * @notice function for the owner to set the URI for the cosmetic NFT.
   * 
   * @param _URI the new URI.
   */
  function setURI(string memory _URI) public onlyOwner {
    URI = _URI;
  }

  function getCosmeticRegistry() public view returns (address) {
    return cosmeticRegistry;
  }
}