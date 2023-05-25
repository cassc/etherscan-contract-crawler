// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PremintCreatorKey is ERC721, ERC721Enumerable, Ownable, Pausable {
  using Address for address payable;
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 private pricePerToken = 1 ether;
  string private baseURI = "";

  Counters.Counter private nextTokenId;
  address payable public beneficiary;

  constructor() ERC721("Premint Creator Key", "PREMINTKEY") {
    baseURI = "https://creators.premint.xyz/metadata/";
    beneficiary = payable(msg.sender);
  }

  /// @notice Mint amount of tokens to `to`
  /// @param to the address to mint to
  /// @param amount the number of tokens to mint
  function mint(address to, uint256 amount) external payable whenNotPaused {
    require(
      msg.value >= getPrice() * amount,
      "Ether value sent is not correct"
    );

    _multimint(to, amount);
    beneficiary.sendValue(getPrice() * amount);
  }

  // @notice Mint function for the owner of the contract
  function gift(address to, uint256 amount) external onlyOwner {
    _multimint(to, amount);
  }

  /// @dev (internal) Mint amount of tokens to address
  function _multimint(address to, uint256 amount) private {
    uint256 startTokenId = nextTokenId.current();
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, startTokenId + i);
      nextTokenId.increment();
    }
  }

  /// @notice Sets the recipient of revenues.
  function setBeneficiary(address payable _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  // @dev Returns the max token supply allowed by the contract
  function getPrice() public view returns (uint256) {
    return pricePerToken;
  }

  /// @notice Allows to change the mint price
  /// @param newPrice the new mint price
  function setPrice(uint256 newPrice) public onlyOwner {
    pricePerToken = newPrice;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  // @notice Returns the total number of mints
  function totalSupply() public view override returns (uint256) {
    return nextTokenId.current();
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      tokenId <= nextTokenId.current(),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory uri = _baseURI();
    return
      bytes(uri).length > 0
        ? string(abi.encodePacked(uri, tokenId.toString()))
        : "";
  }

  /// @notice get the current baseURI
  function getBaseURI() public view returns (string memory) {
    return baseURI;
  }

  /// @notice Allows to change the baseURI
  /// @param _uri the new uri
  function setBaseURI(string memory _uri) public onlyOwner {
    baseURI = _uri;
  }

  /// @dev Override the baseURI so it can be changed
  function _baseURI()
    internal
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    return baseURI;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    return super._beforeTokenTransfer(from, to, tokenId);
  }
}