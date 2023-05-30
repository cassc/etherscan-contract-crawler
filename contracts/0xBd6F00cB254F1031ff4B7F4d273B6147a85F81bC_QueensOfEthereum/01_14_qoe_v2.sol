// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";

contract QueensOfEthereum is ERC721AQueryable, Ownable, DefaultOperatorFilterer, ReentrancyGuard {
  /** Using String for Token URI */
  using Strings for uint256;  
  /** Maximum number of tokens per wallet for WL */
  uint256 public maxWalletWl = 3;
  /** Maximum number of tokens per wallet */
  uint256 public maxWallet = 30;
  /** Maximum amount of tokens in collection */
  uint256 public constant maxSupply = 7777;
  /** Max free */
  uint256 public free = 5555;
  /** MaxPrice per token when presale is over */
  uint256 public maxCost = 0.012 ether;
  /** Price per token for WL*/
  uint256 public cost = 0.009 ether;
  
  /** Base URI */
  string internal baseURI;
  /** Hidden Metadata Uri */
  string public hiddenMetadataUri = "ipfs://bafybeidlfucgjb2bdef2yn4o6oe4tefs5svx627nmy6ehtakdolwnv4wai/Hidden.json";
  /** Merkle Root */
  bytes32 internal merkleRoot;
  /** Reveal state */
  bool public revealed = false;

  /** Step sale state */
  enum stepSale {
    Before,
    WhiteListSale,
    WhiteListFinished,
    PublicSale,
    Finished
  }
    /** SaleState*/
  stepSale public saleState;
     
  /** Notify on reveal state change */
  event RevealStateChanged(bool _val);
   /** Notify on sale state change */
  event SaleStateChanged(stepSale _step);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 _val);

  constructor(
    string memory _name, 
    string memory _symbol
  )
    ERC721A(_name, _symbol) {}

  /// @notice Verification that the caller is not a smart contract
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  /// @notice Start TokenID at 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /// @notice Returns the _base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// @notice Returns the Token URI
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
  }

  /// @notice Gets cost to mint n amount of NFTs, taking account for first one free
  /// @param _numberMinted How many a given wallet has already minted
  /// @param _numberToMint How many a given wallet is planning to mint
  /// @param _costPerMint Price of one nft
  function subtotal(uint256 _numberMinted, uint256 _numberToMint, uint256 _costPerMint) public pure returns (uint256) {
    return _numberToMint * _costPerMint - (_numberMinted > 0 ? 0 : _costPerMint);
  }

  /// @notice Gets number of NFTs minted for a given wallet
  /// @param _wallet Wallet to check
  function numberMinted(address _wallet) external view returns (uint256) {
    return _numberMinted(_wallet);
  }

  /// @notice Verify the proof & wallet for whitelist
  /// @param _wallet Wallet to check
  function isWhiteListed(address _wallet, bytes32[] calldata _proof) internal view returns (bool) {
    return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_wallet)));
  }

  /// @notice Sets MerkleRoot
  /// @param _root MerkleRoot
  function setMerkleRoot(bytes32 _root) public onlyOwner {
    merkleRoot = _root;
  }
  
  /// @notice Sets reveal state
  /// @param _state New reveal state
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
    emit RevealStateChanged(_state);
  }
  
  /// @notice Sets the max price
  /// @param _cost New max price
  function setMaxCost(uint256 _cost) external onlyOwner {
    maxCost = _cost;
  }

  /// @notice Sets the price
  /// @param _cost New price
  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  /// @notice Sets the maxWallet
  /// @param _maxWallet New mawWallet
  function setMaxWallet(uint256 _maxWallet) external onlyOwner {
    maxWallet = _maxWallet;
  }

  /// @notice Sets the maxWalletWl
  /// @param _maxWallet New mawWallet
  function setMaxWalletWl(uint256 _maxWallet) external onlyOwner {
    maxWalletWl = _maxWallet;
  }

  /// @notice Sets the Free number
  /// @param _free free number
  function setFree(uint256 _free) external onlyOwner {
    free = _free;
  }

  /// @notice Sets the base metadata URI
  /// @param _uri The new URI
  function setBaseURI(string calldata _uri) external onlyOwner {
    baseURI = _uri;
  }

  /// @notice Sets the hidden metadata URI
  /// @param _uri The new hidden URI
  function setHiddenURI(string calldata _uri) external onlyOwner {
    hiddenMetadataUri = _uri;
  }

  /// @notice Sets the step
  /// @param _step the new step
  function setSaleState(stepSale _step) external onlyOwner {
    saleState = _step;      
    emit SaleStateChanged(saleState);
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner callerIsUser {
        _mint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Airdrop a set of NFTs (giveaways, etc)
  /// @param _amt The amount to airdrop
  /// @param _wallet Wallet to airdrop
  function airDrop(uint256 _amt, address _wallet) external onlyOwner callerIsUser {
    _mint(_wallet, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function preMint(uint256 _amt, bytes32[] calldata _proof) external payable callerIsUser {
    require(isWhiteListed(msg.sender,_proof), "Not whitelisted");
    require(saleState == stepSale.WhiteListSale, "Presale is not active.");
    require(_amt + _numberMinted(msg.sender) <= maxWalletWl, "Amount of tokens exceeds maximum number of tokens per wallet.");
    require(totalSupply() + _amt <= maxSupply, "Amount exceeds supply.");
    require(subtotal(_numberMinted(msg.sender), _amt, cost) <= msg.value, "ETH sent not equal to cost.");
          
    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function mint(uint256 _amt) external payable callerIsUser {
    require(saleState == stepSale.PublicSale, "Sale is not active.");
    require(_amt + _numberMinted(msg.sender) <= maxWallet, "Amount of tokens exceeds maximum number of tokens per wallet.");
    require(totalSupply() + _amt <= maxSupply, "Amount exceeds supply.");

    if (totalSupply() >= free ) { 
        require(maxCost * _amt <= msg.value, "ETH sent not equal to cost.");
    }
    else { 
        require(subtotal(_numberMinted(msg.sender), _amt, maxCost) <= msg.value, "ETH sent not equal to cost.");
    }

    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Withdraw
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }  

  /// @notice Override function for OperatorFilterer
  function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public payable override(ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  } 
  
}