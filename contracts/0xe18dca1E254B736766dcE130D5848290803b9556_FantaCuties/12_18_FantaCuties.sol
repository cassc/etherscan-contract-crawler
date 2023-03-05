// SPDX-License-Identifier: MIT

/*
██████████████████████████████████████████████████████████████████████████████
██████████████████████████████████████████████████████████████████████████████
██████▀▀▀▀▀▀███████████████░░██████████░░░░░░█████████░░███▄░█████████████████
██████░░▐█▄░█▀██▀▀█▀▀██▀▀█▀░░▀██▀▀█▀░█░░▐█░░▄▀▀▀█▀▀▀█░░░▀█▀▀▀██▀▀▀▀██▀▀▀▀█████
██████▌░░░░█░░▄░░▐█▌░░▄▄░▐█░░██▌░█▌░░█░░█████▄░▐█▌░░█▌░▐██▌░▐█░░▀░▄█░░▀▀██████
██████▀░░███░░▀░░░█▀░░██░░█░░▀█▌░▀░░░▐▌░░░░░▐█░░▀░░░█▌░░▀▀░░▀█░░▀▀░▀▀▀░░██████
██████████████████████████████████████████████████████████████████████████████
██████████████████████████████████████████████████████████████████████████████
*/

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract FantaCuties is
  Ownable,
  ERC721A,
  ERC2981,
  DefaultOperatorFilterer,
  ReentrancyGuard 
{
  using ECDSA for bytes32;
  using Strings for uint256;

  uint256 public maxSupply = 10000;
  uint256 public maxAmountPerTx = 10;

  struct Price {
    uint256 goldTier;
    uint256 silverTier;
    uint256 normalTier;
  }
  Price price = Price(0.025 ether, 0.035 ether, 0.05 ether);

  bool public presaleActive = false;
  bool public publicActive = false;
  bool public isRevealed = false;

  string private _baseTokenURI;
  string private _preRevealTokenURI;

  bytes32 private _whitelistRoot;
  mapping(address => bool) private _whitelistClaimed;

  constructor() ERC721A("FantaCuties", "FANTAQT") {
  }

  function _isContract(address _address) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(_address)
    }
    return size > 0;
  }

  modifier callerIsUser() {
    require(
      !_isContract(msg.sender),
      "FantaCuties :: The caller cannot be another contract"
    );
    require(
      tx.origin == msg.sender,
      "FantaCuties :: Proxies are not allowed"
    );
    _;
  }

  // Set maximum supply
  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  // Set maximum amount per transaction
  function setMaxAmountPerTx(uint256 _maxAmountPerTx) external onlyOwner {
    maxAmountPerTx = _maxAmountPerTx;
  }

  // Set mint price
  function setPrice(
    uint256 _goldTierPrice,
    uint256 _silverTierPrice,
    uint256 _normalTierPrice
  )
    external onlyOwner
  {
    price.goldTier = _goldTierPrice;
    price.silverTier = _silverTierPrice;
    price.normalTier = _normalTierPrice;
  }

  // Get mint price (tier codes: gold=2, silver=1, normal=0)
  function getPrice(uint256 _tierCode) public view returns (uint256) {
    if (_tierCode == 2) {
      return price.goldTier;
    } else if (_tierCode == 1) {
      return price.silverTier;
    } else {
      return price.normalTier;
    }
  }
  
  // State switches
  function togglePresale() external onlyOwner {
    presaleActive = !presaleActive;
  }

  function togglePublic() external onlyOwner {
    publicActive = !publicActive;
  }

  function toggleReveal() external onlyOwner {
    isRevealed = !isRevealed;
  }
  
  // Set merkle root
  function setWhitelistRoot(bytes32 _merkleRoot) external onlyOwner {
    _whitelistRoot = _merkleRoot;
  }

  // Metadata URI
  function _baseURI() 
    internal view virtual override
    returns (string memory) 
  {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setPreRevealURI(string calldata preRevealURI) external onlyOwner {
    _preRevealTokenURI = preRevealURI;
  }

  // Reserved mint
  function reservedMint(uint256 _quantity) external onlyOwner {
    _safeMint(msg.sender, _quantity);
  }

  // Presale mint
  function presaleMint(
    uint256 _quantity,
    uint256 _tierCode,
    bytes32[] calldata _merkleProof
  )
    external payable callerIsUser nonReentrant 
  {
    require(presaleActive, "FantaCuties :: Presale mint is not active");
    require(
      _whitelistClaimed[msg.sender] == false,
      "FantaCuties :: You already claimed your tokens"
    );

    bytes32 leaf = keccak256(
      abi.encodePacked(msg.sender, _quantity, _tierCode)
    );
    require(
      MerkleProof.verify(_merkleProof, _whitelistRoot, leaf),
      "FantaCuties :: You are not admitted to the presale"
    );

    uint256 mintPrice;
    if (_tierCode == 2) {
      mintPrice = price.goldTier;
    } else if (_tierCode == 1) {
      mintPrice = price.silverTier;
    } else {
      mintPrice = price.normalTier;
    }
    require(
      msg.value >= mintPrice * _quantity,
      "FantaCuties :: Insufficient funds"
    );

    _safeMint(msg.sender, _quantity);
    _whitelistClaimed[msg.sender] = true;
  }

  // Public mint
  function publicMint(uint256 _quantity)
    external payable callerIsUser nonReentrant
  {
    require(publicActive, "FantaCuties :: Public mint is not active");
    require(
      msg.value >= price.normalTier * _quantity,
      "FantaCuties :: Insufficient funds"
    );
    require(
      _quantity <= maxAmountPerTx,
      "FantaCuties :: Exceeding maximum amount per transaction"
    );
    require(
      totalSupply() + _quantity <= maxSupply,
      "FantaCuties :: Cannot mint beyond max supply"
    );
    _safeMint(msg.sender, _quantity);
  }

  // Get token URI
  function tokenURI(uint256 _tokenId) 
    public view virtual override returns (string memory) 
  {
    require(_exists(_tokenId), "FantaCuties: Token not found");
    
    if (isRevealed == false) {
      return _preRevealTokenURI;
    }
    return bytes(_baseTokenURI).length > 0
      ? string(abi.encodePacked(_baseTokenURI, _toString(_tokenId), ".json"))
      : "";
  }

  function withdraw() external onlyOwner {
    uint256 withdrawAmount = address(this).balance;
    payable(msg.sender).transfer(withdrawAmount);
  }

  // Set royalties
  function setRoyalties(
    address payable _royaltiesRecipientAddress,
    uint96 _percentageBasisPoints
  )
    external onlyOwner
  {
    _setDefaultRoyalty(_royaltiesRecipientAddress, _percentageBasisPoints);
  }

  // Apply operator filter to transfers and approvals
  function setApprovalForAll(address operator, bool approved)
    public override onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public payable override onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId)
    public payable override onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
    public payable override onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  )
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721A, ERC2981) returns (bool)
  {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}