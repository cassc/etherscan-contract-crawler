// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

import "../interfaces/INftDistributor.sol";
import "../interfaces/ITaggrNft.sol";
import "../lib/BlackholePrevention.sol";

/// @custom:security-contact [email protected]
contract TaggrBase721 is
  ITaggrNft,
  Ownable,
  ERC721Pausable,
  ERC721URIStorage,
  ERC721Royalty,
  BlackholePrevention
{
  bool internal _initialized;
  uint256 internal _maxSupply;
  string internal _contractName;
  string internal _contractSymbol;
  string internal _baseTokenURI;
  address internal _tokenDistributor;


  /***********************************|
  |          Initialization           |
  |__________________________________*/

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

  function initialize(
    address _owner,
    address _distributor,
    string memory _name,
    string memory _symbol,
    string memory baseTokenUri,
    uint256 maxSupply,
    uint96 royaltiesPct
  )
    external
    virtual
    override
  {
    require(!_initialized, "TB:E-002");
    _tokenDistributor = _distributor;
    _contractName = _name;
    _contractSymbol = _symbol;
    _maxSupply = maxSupply;
    _transferOwnership(_owner);
    _setDefaultRoyalty(_owner, royaltiesPct);
    _baseTokenURI = baseTokenUri;
    _initialized = true;
  }


  /***********************************|
  |         Public Functions          |
  |__________________________________*/

  function name() public view virtual override returns (string memory) {
      return _contractName;
  }

  function symbol() public view virtual override returns (string memory) {
      return _contractSymbol;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Royalty)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }


  /***********************************|
  |        Only NFT Distributor       |
  |__________________________________*/

  function distributeToken(address to, uint256 tokenId) external virtual override {
    require(msg.sender == _tokenDistributor, "TB721:E-102");
    _safeMint(to, tokenId);
  }

  function distributeTokenWithURI(address to, uint256 tokenId, string memory tokenUri) external virtual override {
    require(msg.sender == _tokenDistributor, "TB721:E-102");
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, tokenUri);
  }


  /***********************************|
  |          Contract Hooks           |
  |__________________________________*/

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  )
    internal
    virtual
    override(ERC721, ERC721Pausable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }


  /***********************************|
  |            Only Owner             |
  |__________________________________*/

  function mintToken(address to, uint256 tokenId) external virtual onlyOwner {
    if (_tokenDistributor != address(0)) {
      require(!INftDistributor(_tokenDistributor).isFullyClaimed(address(this), tokenId), "TB721:E-402");
    }
    _safeMint(to, tokenId);
  }

  function mintTokenWithURI(address to, uint256 tokenId, string memory tokenUri) external virtual onlyOwner {
    if (_tokenDistributor != address(0)) {
      require(!INftDistributor(_tokenDistributor).isFullyClaimed(address(this), tokenId), "TB721:E-402");
    }
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, tokenUri);
  }

  function setBaseURI(string memory baseTokenURI) external virtual onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  function setTokenDistributor(address _distributor) external virtual onlyOwner {
    _tokenDistributor = _distributor;
  }

  function pause() external virtual onlyOwner {
    _pause();
  }

  function unpause() external virtual onlyOwner {
    _unpause();
  }


  /***********************************|
  |            Only Owner             |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external virtual onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external virtual onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external virtual onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }


  /***********************************|
  |         Private/Internal          |
  |__________________________________*/

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty, ERC721URIStorage) {
    super._burn(tokenId);
  }
}