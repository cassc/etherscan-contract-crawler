// SPDX-License-Identifier: MIT

/*
   ___ ___ ___ ___ _  _   ___ ___ _    _    
  / __| _ \ __| __| \| | | _ \_ _| |  | |   
 | (_ |   / _|| _|| .` | |  _/| || |__| |__ 
  \___|_|_\___|___|_|\_| |_| |___|____|____|

*/
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkelProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./Strings.sol";

contract GreenPill is ERC721A, Ownable, DefaultOperatorFilterer {

  // MintPrice = "Free Mint"

  using Strings for uint256;
  string _baseTokenURI;
  bytes32 public merkleRoot;

  string public hiddenURI ="ipfs://QmatwLLzCcLwbd76afmMacQ6SvpYzdm9ALbk1xQAWywx2X";

  bool public isActive = false;
  bool public isWhitelistSaleActive = false;
  bool public revealed = false;

  uint256 public mintPrice = 0.005 ether; //Price for public
  uint256 public MAX_SUPPLY = 3000;
  uint256 public WL_SUPPLY = 1000;
  uint256 public maximumAllowedTokensPerPurchase = 2;
  uint256 public whitelistWalletLimitation = 1;
  uint256 public publicWalletLimitation = 2;

  address private ownerWallet = 0xCd8655862c02C97cad101fCfA49Bd90990b9C99b;

  mapping(address => uint256) private _whitelistWalletMints;
  mapping(address => uint256) private _publicWalletMints;


  constructor(string memory baseURI) ERC721A("GREEN PILL", "GP") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  // Minting for devs to use in future giveaways and raffles and treasury

  function devMint(uint256 _count, address _address) external onlyOwner {
    uint256 mintIndex = totalSupply();
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");

    _safeMint(_address, _count);
  }

  // Free mint for whitelisted people

  function whitelistMint(bytes32[] calldata _merkleProof, uint256 _count) public payable isValidMerkleProof(_merkleProof) saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isWhitelistSaleActive, "Presale is not active");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(_count <= whitelistWalletLimitation, "Exceeds maximum allowed tokens");
    require(_whitelistWalletMints[msg.sender] + _count <= whitelistWalletLimitation, "You have already minted max");

    _whitelistWalletMints[msg.sender] += _count;

    if (mintIndex + _count == WL_SUPPLY) {
      isWhitelistSaleActive = false;
      isActive = true;
    }

    _safeMint(msg.sender, _count);

  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(_count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_publicWalletMints[msg.sender] + _count <= publicWalletLimitation, "You have already minted or minting more than allowed.");
    require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");

    _publicWalletMints[msg.sender] += _count;

    _safeMint(msg.sender, _count);
    
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
      require(
          MerkleProof.verify(
              merkleProof,
              merkleRoot,
              keccak256(abi.encodePacked(msg.sender))
          ),
          "Address does not exist in list"
      );
    _;
  }

  function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
    merkleRoot = _rootHash;
  }
  
  function setWhitelistSaleWalletLimitation(uint256 _maxMint) external  onlyOwner {
    whitelistWalletLimitation = _maxMint;
  }

  function setPublicSaleWalletLimitation(uint256 _count) external  onlyOwner {
    publicWalletLimitation = _count;
  }

  function setMaximumAllowedTokensPerPurchase(uint256 _count) public onlyOwner {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMaxMintSupply(uint256 _maxMintSupply) external  onlyOwner {
    MAX_SUPPLY = _maxMintSupply;
  }

  function setWlMintSupply(uint256 _maxWlSupply) external  onlyOwner {
    WL_SUPPLY = _maxWlSupply;
  }

  function setMintPrice(uint256 _price) public onlyOwner {
    mintPrice = _price;
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }

  function toggleWhiteslistSaleStatus() external onlyOwner {
    isWhitelistSaleActive = !isWhitelistSaleActive;
  }

  function reveal() external onlyOwner {
    revealed = !revealed;
  }

  function setHiddenURI(string memory _hiddenURI) public onlyOwner {
    hiddenURI = _hiddenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
    require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
      if (revealed == false) {
        return hiddenURI;
      }
      string memory currentBaseURI = _baseURI();
    return bytes( currentBaseURI ).length > 0 ? string( abi.encodePacked( currentBaseURI, _tokenId.toString(), ".json" ) ) : "";
  }

  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    payable(ownerWallet).transfer(balance);
  }

  // For compliance with opensea

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}