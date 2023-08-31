// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*

░█████╗░██████╗░████████╗███████╗███████╗░█████╗░░█████╗░████████╗░██████╗
██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
███████║██████╔╝░░░██║░░░█████╗░░█████╗░░███████║██║░░╚═╝░░░██║░░░╚█████╗░
██╔══██║██╔══██╗░░░██║░░░██╔══╝░░██╔══╝░░██╔══██║██║░░██╗░░░██║░░░░╚═══██╗
██║░░██║██║░░██║░░░██║░░░███████╗██║░░░░░██║░░██║╚█████╔╝░░░██║░░░██████╔╝
╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═════╝░


██████╗░██╗░░░██╗
██╔══██╗╚██╗░██╔╝
██████╦╝░╚████╔╝░
██╔══██╗░░╚██╔╝░░
██████╦╝░░░██║░░░
╚═════╝░░░░╚═╝░░░

░█████╗░██████╗░████████╗  ████████╗░█████╗░██╗░░██╗██╗░░░██╗░█████╗░
██╔══██╗██╔══██╗╚══██╔══╝  ╚══██╔══╝██╔══██╗██║░██╔╝╚██╗░██╔╝██╔══██╗
███████║██████╔╝░░░██║░░░  ░░░██║░░░██║░░██║█████═╝░░╚████╔╝░██║░░██║
██╔══██║██╔══██╗░░░██║░░░  ░░░██║░░░██║░░██║██╔═██╗░░░╚██╔╝░░██║░░██║
██║░░██║██║░░██║░░░██║░░░  ░░░██║░░░╚█████╔╝██║░╚██╗░░░██║░░░╚█████╔╝
╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░

░██████╗░██╗░░░░░░█████╗░██████╗░░█████╗░██╗░░░░░
██╔════╝░██║░░░░░██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██║░░██╗░██║░░░░░██║░░██║██████╦╝███████║██║░░░░░
██║░░╚██╗██║░░░░░██║░░██║██╔══██╗██╔══██║██║░░░░░
╚██████╔╝███████╗╚█████╔╝██████╦╝██║░░██║███████╗
░╚═════╝░╚══════╝░╚════╝░╚═════╝░╚═╝░░╚═╝╚══════╝

*/
/** 
  * @title ARTefacts by Art Tokyo Global
  * @author 0xjikangu
  * @notice This is the Main NFT contract for ARTefacts Marketplace
*/

contract ARTefacts is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;

  string public uriPrefix = "ipfs://Qme7zEuqPtbYJ9AdMGcd24am1yd59zpS4HkPrcKsGiUs8B/";
  string public uriSuffix = ".json";

  uint256 public cost = 10000000000000000000;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;

// ATG Main Constructor
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

  /* Mint Compliance */
  // Requirement for mint to work
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  // Reserve tokens 
  function reserveTokens (address _receiver, uint256 _mintAmount) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    address to = _receiver;
    _safeMint(to, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // Set Token Metadata Uri
  function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }
  
  // Set Current Mint Price
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  // Set Max Mint Amount
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  // Set Token Uri Prefix
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  // Set Token Uri Suffix
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  // Set Contract Status
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  /* Opensea Operator Filter Registry */
  // Requirement for royalties in OS
  function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override (ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // Fund Withdrawal
  function withdrawFund() external onlyOwner nonReentrant {
    (bool os, ) = payable(0xA107E9f9D382244F3a669340cf53014ABbc58629).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}