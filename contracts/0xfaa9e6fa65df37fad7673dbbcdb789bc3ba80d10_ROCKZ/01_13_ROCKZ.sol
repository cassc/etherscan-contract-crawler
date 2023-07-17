// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ROCKZ is ERC721AQueryable, Ownable, DefaultOperatorFilterer {
  using Strings for uint256;
  uint256 public MAX_SUPPLY = 6000;
  uint256 public maxPublicMintPerWallet = 10;
  uint256 public publicTokenPrice = .0033 ether;
  string _contractURI;

  bool public saleStarted = false;

  string private _baseTokenURI;

  constructor() ERC721A("The Rockz", "ROCKZ") {
    _baseTokenURI = "ipfs://bafybeia7qyp2pmjsioxt56rlkd6thqgcxycedkjcod4mx3a3kaxxpxevmm/";
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'ROCKZ: The caller is another contract');
    _;
  }

  modifier underMaxSupply(uint256 _quantity) {
    require(
      _totalMinted() + _quantity <= MAX_SUPPLY,
      "Unable to mint."
    );
    _;
  }

  function setTotalMaxSupply(uint256 _newSupply) external onlyOwner {
      MAX_SUPPLY = _newSupply;
  }

  function setPublicTokenPrice(uint256 _newPrice) external onlyOwner {
      publicTokenPrice = _newPrice;
  }

  function mint(uint256 _quantity) external payable callerIsUser underMaxSupply(_quantity) {
    require(balanceOf(msg.sender) < maxPublicMintPerWallet, "Max wallet reached.");
    require(saleStarted, "Sale has not started");
    require(msg.value >= _quantity * publicTokenPrice, "Unable to mint.");
    _mint(msg.sender, _quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function ownerMint(uint256 _numberToMint) external onlyOwner underMaxSupply(_numberToMint) {
    _mint(msg.sender, _numberToMint);
  }

  function ownerMintToAddress(address _recipient, uint256 _numberToMint)
    external
    onlyOwner
    underMaxSupply(_numberToMint)
  {
    _mint(_recipient, _numberToMint);
  }

  function setMaxPublicMintPerWallet(uint256 _count) external onlyOwner {
    maxPublicMintPerWallet = _count;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public payable
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // Storefront metadata
  // https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory _URI) external onlyOwner {
    _contractURI = _URI;
  }

  function withdrawFunds() external onlyOwner {
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success, "Transfer failed");
  }

  function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
    (bool success, ) = _address.call{ value: amount }("");
    require(success, "Transfer failed");
  }

  function flipSaleStarted() external onlyOwner {
    saleStarted = !saleStarted;
  }
}