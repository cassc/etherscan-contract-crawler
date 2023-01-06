// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../Common/Merkle.sol";
import "../Common/Signed.sol";

contract DarkLabs is ERC721AQueryable, OperatorFilterer, Merkle, Signed {
  using Address for address;

  error OperatorDenied();
  error AccountNotListed();
  error ExceedsSupplyLimit();
  error ExceedsWalletLimit();
  error FourPackSoldOut();
  error InvalidPayment();
  error InvalidQuantity();
  error InvalidSaleState();
  error InvalidDenylistRegistry();
  error SaleNotActive();
  error UnbalancedInputs();
  error MaxSupplyLowerThanTotalSupply();
  error SupplyGreaterThanExistingMax();

  enum SaleState{
    NONE,
    WHITELIST
  }

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxSupply;
    SaleState saleState;
  }

  MintConfig public config = MintConfig(
    1.00 ether,    //ethPrice
    875,           //maxSupply
    SaleState.NONE
  );

  uint8 public batchSize = 4;
  uint8 public fourPacks = 95;
  string public baseURI = "https://ipfs.io/ipfs/QmY25D51dQ9Pz5vT5tR5gMZ8BCxW1yzCBBJ1PBdxZ5xPPd?";
  bool public isOSEnabled = true;
  address public crossmintOperator = 0xdAb1a1854214684acE522439684a145E62505233;


  modifier onlyCrossmint(){
    if(msg.sender != crossmintOperator) revert OperatorDenied();

    _;
  }

  modifier onlyAllowedOperator(address from) override {
    if (isOSEnabled && from != msg.sender) {
      _checkFilterOperator(msg.sender);
    }
    _;
  }

  modifier onlyAllowedOperatorApproval(address operator) override {
    if(isOSEnabled){
      _checkFilterOperator(operator);
    }
    _;
  }


  constructor(address signer)
    ERC721A("Dark Labs", "DL")
    OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true)
    Signed(signer)
  {}


  function withdraw() external onlyOwner{
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner{
    baseURI = newBaseURI;
  }


  //payable - public
  function mint(uint16 quantity, bytes32[] calldata proof) external payable{
    if(!_isValidProof(keccak256(abi.encodePacked(msg.sender)), proof))
      revert AccountNotListed();

    if(quantity == 1){      
      _mintPacks(1, msg.sender);
    }
    else if(quantity == 4){
      if(fourPacks == 0) revert FourPackSoldOut();

      fourPacks--;
      _mintPacks(4, msg.sender);
    }
    else{
      revert InvalidQuantity();
    }
  }

  function crossMint(
    uint16 quantity,
    address recipient,
    bytes memory signature
  ) external payable onlyCrossmint
  {
    if(!_verifySignature(abi.encodePacked(recipient), signature))
      revert AccountNotListed();

    if(quantity == 1){      
      _mintPacks(1, recipient);
    }
    else if(quantity == 4){
      if(fourPacks == 0) revert FourPackSoldOut();

      fourPacks--;
      _mintPacks(4, recipient);
    }
    else{
      revert InvalidQuantity();
    }
  }


  //payable - onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    if(quantity.length != recipient.length) revert UnbalancedInputs();

    uint256 totalQuantity = 0;
    for(uint256 i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    if(totalSupply() + totalQuantity > config.maxSupply) revert ExceedsSupplyLimit();

    for(uint256 i = 0; i < recipient.length; ++i){
      _mintBatch(recipient[i], quantity[i]);
    }
  }


  //nonpayable - onlyDelegates
  function setBatchSize(uint8 newBatchSize) external onlyDelegates{
    batchSize = newBatchSize;
  }

  function setConfig(MintConfig calldata newConfig) external onlyDelegates{
    if(newConfig.maxSupply < totalSupply()) revert MaxSupplyLowerThanTotalSupply();
    if(newConfig.maxSupply > config.maxSupply) revert SupplyGreaterThanExistingMax();
    if(uint8(newConfig.saleState) > 1) revert InvalidSaleState();

    config = newConfig;
  }

  function setCrossmint(address operator) external onlyDelegates{
    crossmintOperator = operator;
  }

  function setSigner(address signer) external onlyDelegates{
    _setSigner(signer);
  }

  //view - public
  function supportsInterface(bytes4 interfaceId) public view
    override(IERC721A, ERC721A) returns (bool)
  {
    return ERC721A.supportsInterface(interfaceId);
  }


  //internal
  function _mintPacks(uint16 quantity, address recipient) internal{
    MintConfig memory cfg = config;
    if(cfg.saleState != SaleState.WHITELIST)
      revert SaleNotActive();

    if(msg.value != (quantity * cfg.ethPrice)) revert InvalidPayment();
    if(_numberMinted(recipient) > 0) revert ExceedsWalletLimit();
    if(totalSupply() + quantity > cfg.maxSupply) revert ExceedsSupplyLimit();

    _mintBatch(recipient, quantity );
  }

  function _mintBatch(address to, uint256 quantity) internal {
    while(quantity > 0){
      if(quantity > batchSize){
        _mint(to, batchSize);
        quantity -= batchSize;
      }
      else{
        _mint(to, quantity);
        break;
      }
    }
  }


  //internal - override
  function _startTokenId() internal pure override returns (uint256) {
      return 1;
  }

  /**
  * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
  */
  function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
      if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

      return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
  }



  //OS overrides
  function approve(address operator, uint256 tokenId)
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function setApprovalForAll(address operator, bool approved)
    public
    override(IERC721A, ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override(IERC721A, ERC721A) onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function transferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperator(from)
  {
    if (_ownershipAt( tokenId ).extraData > 0)
      revert( "Private sale tokens temporarily locked" );

    super.transferFrom(from, to, tokenId);
  }
}