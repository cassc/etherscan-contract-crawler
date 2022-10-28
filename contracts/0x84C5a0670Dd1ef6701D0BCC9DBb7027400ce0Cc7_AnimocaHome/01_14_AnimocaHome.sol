// SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/MinterAccessControl.sol";

contract AnimocaHome is Ownable, ERC721Enumerable, MinterAccessControl {

  /// @dev a string of base uri for this nft
  string private baseURI;
  /// @dev maxSupply of 8bit tokens
  uint256 public maxSupply;

  /**
   * @dev Fired in updateBaseURI()
   *
   * @param sender an address which performed an operation, usually contract owner
   * @param uri a stringof base uri for this nft
   */
  event UpdateBaseUri(address indexed sender, string uri);

  /**
   * @dev Creates/deploys an instance of the NFT
   *
   * @param name_ the name of this nft
   * @param symbol_ the symbol of this nft
   * @param uri_ a stringof base uri for this nft
   * @param maxSupply_ maximum supply of this nft
   */
  constructor(
    string memory name_,
    string memory symbol_,
    string memory uri_,
    uint256 maxSupply_
  ) ERC721(name_, symbol_) {
    baseURI = uri_;
    maxSupply = maxSupply_;
  }

  /**
   * @notice Service function to update base uri
   *
   * @dev this function can only be called by owner
   *
   * @param uri_ a string for updating base uri
   */
  function updateBaseURI(string memory uri_) external onlyOwner {
    baseURI = uri_;
    emit UpdateBaseUri(_msgSender(), uri_);
  }

  /**
   * @notice Service function to update max Supply
   *
   * @dev this function can only be called by owner
   *
   * @param newMaxSupply_ a string for updating maxSupply
   */
  function updateMaxSupply(uint256 newMaxSupply_) external onlyOwner {
    maxSupply = newMaxSupply_;
  }

  /**
   * @dev Additionally to the parent smart contract, return string of base uri
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
  /**
   * @notice Service function to mint nft
   *
   * @dev this function can only be called by minter
   *
   * @param to_ an address which received nft
   * @param tokenId_ a number of id to be minted
    */
  function safeMint(address to_, uint256 tokenId_) external virtual onlyMinter {
    require(totalSupply() < maxSupply, "mint exceed maxSupply");
    _safeMint(to_, tokenId_);
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirement:
   * - The caller must own `tokenId` or be an approved operator.
   * 
   * @param tokenId_ a number of id to be minted
   */
  function burn(uint256 tokenId_) public virtual {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId_), "caller is not owner nor approved");
    _burn(tokenId_);
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * @dev Additionally to the parent smart contract, restrict this contract can not be receiver.
   */
  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual override {
    require(to_ != address(this), 'this contract cannot be receiver');
    super._beforeTokenTransfer(from_, to_, tokenId_);
  }

  /**
   * @notice Service function to transfer mulitply nfts at once
   * 
   * @param from_ is who send token from
   * @param to_ is where the token is send to
   * @param ids_ are those ids which are about to be transfered.
   */
  function safeBatchTransferFrom(
    address from_,
    address to_,
    uint256[] memory ids_
  ) public virtual {
    for(uint256 index; index < ids_.length; index++) {
      safeTransferFrom(from_, to_, ids_[index]);
    }
  }

  /**
   * @notice Service function to add address into MinterRole
   *
   * @dev this function can only be called by Owner
   *
   * @param addr_ an address which is adding into MinterRole
   */
  function grantMinterRole(address addr_) external onlyOwner {
    _grantMinterRole(addr_);
  }

  /**
   * @notice Service function to remove address into MinterRole
   *
   * @dev this function can only be called by Owner
   *
   * @param addr_ an address which is removing from MinterRole
   */
  function revokeMinterRole(address addr_) external onlyOwner {
    _revokeMinterRole(addr_);
  }
}