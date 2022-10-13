// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.8 <0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC721Tradable.sol";

contract ERC721Tradable is
  IERC721Tradable,
  ERC721Enumerable,
  ERC721Burnable,
  Ownable
{
  constructor(
    address _ownerAddress,
    string memory _name,
    string memory _symbol,
    string memory _baseMetadataURI
  ) ERC721(_name, _symbol) {
    transferOwnership(_ownerAddress);
    baseURI = _baseMetadataURI;
    minter = _ownerAddress;
  }

  string public baseURI;
  address public minter;

  /**
   * @dev Throws if called by any account other than the minter or owner.
   */
  modifier onlyOwnerOrMinter() {
    require(
      minter == msg.sender || owner() == msg.sender,
      "caller is not the owner or minter"
    );
    _;
  }

  /**
   * @dev Set minter
   * Can only be called by the current owner.
   */
  function setMinter(address newMinter) public onlyOwner {
    require(newMinter != address(0), "new minter is the zero address");
    minter = newMinter;
  }

  function mintTo(address _to, uint256 _newTokenId)
    external
    override
    onlyOwnerOrMinter
  {
    _safeMint(_to, _newTokenId);
  }

  function isExist(uint256 tokenId) external view override returns (bool) {
    return _exists(tokenId);
  }

  function setBaseMetadataURI(string calldata _baseMetadataURI)
    public
    override
    onlyOwnerOrMinter
  {
    baseURI = _baseMetadataURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}