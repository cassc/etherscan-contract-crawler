//
// .------..------..------..------..------..------..------.
// |O.--. ||C.--. ||T.--. ||O.--. ||M.--. ||O.--. ||B.--. |
// | :/\: || :/\: || :/\: || :/\: || (\/) || :/\: || :(): |
// | :\/: || :\/: || (__) || :\/: || :\/: || :\/: || ()() |
// | '--'O|| '--'C|| '--'T|| '--'O|| '--'M|| '--'O|| '--'B|
// `------'`------'`------'`------'`------'`------'`------'
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./UpdatableOperatorFilterer.sol";
import "./RevokableDefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OctomobFootSoldiers is ERC721A, RevokableDefaultOperatorFilterer, ReentrancyGuard,  Ownable {

  using Strings for uint256;
  uint256 public immutable maxSupply = 5555;

  ERC721 hitmenContract;
  ERC721 madeMenContract;
  address public madeMenAddress;
  address public hitmenAddress;
  bool public mintActive;
  bool public publicMintActive;
  bool public extraMintActive;

  mapping(uint256 => bool) public hitmenIsClaimed;
  mapping(uint256 => bool) public madeMenIsClaimed;

  uint256 public maxMintPerWallet = 10;
  uint256 public mintPrice = 0.05 ether;
  uint256 public publicMintPrice = 0.069 ether;
  string public baseUri;

  bytes32 private mobMerkleRoot;
  mapping(address => uint) public hasAlMinted;

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Cannot be called by contract");
    _;
  }

  constructor(address _madeMenAddress, address _hitmenAddress) ERC721A("OctoMob - Foot Soldiers", "FTSL") {
    mintActive = false;
    publicMintActive = false;
    extraMintActive = false;
    madeMenAddress = _madeMenAddress;
    madeMenContract = ERC721(madeMenAddress);
    hitmenAddress = _hitmenAddress;
    hitmenContract = ERC721(hitmenAddress);
  }

  function claimHitmen(uint16[] calldata _hitmenTokenIds) public nonReentrant callerIsUser {
    require(mintActive, "Mint is paused");

    uint256 totalMinted = totalSupply() + _hitmenTokenIds.length;
    require(totalMinted  <= maxSupply, "Not enough supply left for this mint quantity");

    for (uint256 i = 0; i < _hitmenTokenIds.length; i++) {
        require(
            !hitmenIsClaimed[_hitmenTokenIds[i]],
            "Cannot claim a Footsoldier with Hitmen that has already claimed a Footsoldier"
        );
        require(
            hitmenContract.ownerOf(_hitmenTokenIds[i]) == msg.sender,
            "Cannot claim a Footsoldier for Hitmen that you do not own"
        );
        
        hitmenIsClaimed[_hitmenTokenIds[i]] = true;
    }

    _safeMint(msg.sender, _hitmenTokenIds.length);
  }

  function claimMadeMen(uint16[] calldata _madeMenTokenIds) public nonReentrant callerIsUser {
    require(mintActive, "Mint is paused");

    uint256 quantity = _madeMenTokenIds.length * 2;
    uint256 totalMinted = totalSupply() + quantity;
    require(totalMinted  <= maxSupply, "Not enough supply left for this mint quantity");

    for (uint256 i = 0; i < _madeMenTokenIds.length; i++) {
        require(
            !madeMenIsClaimed[_madeMenTokenIds[i]],
            "Cannot claim a Footsoldier with MadeMen that have already claimed a hitmen"
        );
        require(
            madeMenContract.ownerOf(_madeMenTokenIds[i]) == msg.sender,
            "Cannot claim a hitmen for MadeMen that you do not own"
        );
        
        madeMenIsClaimed[_madeMenTokenIds[i]] = true;
    }
    
    _safeMint(msg.sender, quantity);
  }

 function alMint(bytes32[] calldata _merkleProof, uint _quantity) external payable nonReentrant callerIsUser {
    require(mintActive, "Mint is paused");
    require(_quantity  <= maxMintPerWallet, "Not allowed to mint such an amount");
    require(hasAlMinted[msg.sender] + _quantity <= maxMintPerWallet, "Already minted max amount");

    uint256 totalCost = mintPrice * _quantity;
    require(totalCost >= mintPrice, "Overflow when calculating total cost");

    uint256 totalMinted = totalSupply() + _quantity;
    require(totalMinted > totalSupply(), "Overflow when calculating total minted tokens");
    require(totalMinted <= maxSupply, "Not enough supply left for this mint quantity");


    require(msg.value >= totalCost, "Incorrect amount of Ether sent");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(_merkleProof, mobMerkleRoot, leaf) || MerkleProof.verify(_merkleProof, mobMerkleRoot, leaf) ,
      "Invalid Proof for AL"
    );  
   
   _safeMint(msg.sender, _quantity);

    hasAlMinted[msg.sender] = hasAlMinted[msg.sender] + _quantity;
  }


  function mint(uint16 _quantity) external payable nonReentrant callerIsUser {
    require(publicMintActive, "Mint is paused");
    require(_quantity <= maxMintPerWallet, "Not allowed to mint such an amount");
    require(hasAlMinted[msg.sender] + _quantity <= maxMintPerWallet, "Already minted max amount");

    uint256 totalCost = publicMintPrice * _quantity;
    require(totalCost >= publicMintPrice, "Overflow when calculating total cost");

    uint256 totalMinted = totalSupply() + _quantity;
    require(totalMinted > totalSupply(), "Overflow when calculating total minted tokens");
    require(totalMinted <= maxSupply, "Not enough supply left for this mint quantity");

    require(msg.value >= totalCost, "Incorrect amount of Ether sent");

    _safeMint(msg.sender, _quantity);

    hasAlMinted[msg.sender] = hasAlMinted[msg.sender] + _quantity;
}

  function extraMint(uint16 _quantity) external nonReentrant callerIsUser {
    require(extraMintActive, "Extra Mint is not active");
    require(_quantity <= maxMintPerWallet, "Not allowed to mint such an amount");
    require(hasAlMinted[msg.sender] + _quantity <= maxMintPerWallet, "Already minted max amount");

    uint256 totalMinted = totalSupply() + _quantity;
    require(totalMinted > totalSupply(), "Overflow when calculating total minted tokens");
    require(totalMinted <= maxSupply, "Not enough supply left for this mint quantity");

    _safeMint(msg.sender, _quantity);

    hasAlMinted[msg.sender] = hasAlMinted[msg.sender] + _quantity;
}

  function bossMint(address _to, uint _quantity) public onlyOwner(){
    require(
      totalSupply() + _quantity <= maxSupply,
      "Minting over collection size"
    );
    require(_quantity > 0, "Quantity must be greater than 0");
    _safeMint(_to, _quantity);
  }

  function registerClaimedHitmen(uint16[] calldata _hitmenTokenIds) public onlyOwner {
    for (uint256 i = 0; i < _hitmenTokenIds.length; i++) {
        hitmenIsClaimed[_hitmenTokenIds[i]] = true;
    }
  }

  function unRegisterClaimedHitmen(uint16[] calldata _hitmenTokenIds) public onlyOwner {
    for (uint256 i = 0; i < _hitmenTokenIds.length; i++) {
        hitmenIsClaimed[_hitmenTokenIds[i]] = false;
    }
  }

  function registerClaimedMadeMen(uint16[] calldata _madeMenTokenIds) public onlyOwner {
    for (uint256 i = 0; i < _madeMenTokenIds.length; i++) {
        madeMenIsClaimed[_madeMenTokenIds[i]] = true;
    }
  }

  function unRegisterClaimedMadeMen(uint16[] calldata _madeMenTokenIds) public onlyOwner {
    for (uint256 i = 0; i < _madeMenTokenIds.length; i++) {
        madeMenIsClaimed[_madeMenTokenIds[i]] = false;
    }
  }

  // set the mint price
  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  // set max mint per wallet
  function setMaxMintPerWallet(uint16 _maxMintPerWallet) public onlyOwner {
    maxMintPerWallet = _maxMintPerWallet;
  }

  // set the public mint price
  function setPublicMintPrice(uint256 _publicMintPrice) public onlyOwner {
    publicMintPrice = _publicMintPrice;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 0;
  }

  function tokenURI(uint256 _tokenId)
  public
  view
  override
  returns (string memory)
  {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

    return string(abi.encodePacked(baseUri, _tokenId.toString(), ".json"));
  }

  function setBaseUri(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }

  function setMobMerkleRoot(bytes32 _mobMerkleRoot) public onlyOwner {
    mobMerkleRoot = _mobMerkleRoot;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }


    // set public mint active
    function togglePublicMintActive() public onlyOwner {
        publicMintActive = !publicMintActive;
    }

    // set mint active
    function toggleMintActive() public onlyOwner {
        mintActive = !mintActive;
    }

    // set extra mint active
    function toggleExtraMintActive() public onlyOwner {
        extraMintActive = !extraMintActive;
    }


    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }


}