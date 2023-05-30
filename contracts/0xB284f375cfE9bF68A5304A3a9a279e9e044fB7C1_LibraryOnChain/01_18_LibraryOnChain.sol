// SPDX-License-Identifier: MIT

/// Library Onchain
/// ---------------
/// Imagine a library full of alpha. An alpha aggregator powered by onchain activities, research and networks.
/// NFTs grants access to the private discord of Library Onchain.
/// All services of Library Onchain are available for NFT holders.
/// ---------------
/// Website: https://libraryonchain.com/
/// Discord: https://discord.gg/libraryonchain
/// Medium: https://medium.com/@Libraryonchain
/// OpenSea: https://opensea.io/collection/library-onchain

pragma solidity ^0.8.0;

import "./base/ERC721Checkpointable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LibraryOnChain is ERC721Checkpointable, ERC2981, Ownable {
  
  uint256 public constant MINT_PRICE = 0.5 ether;
  uint256 public constant MAX_SUPPLY = 350;
  uint256 public MINT_STAGE = 0;

  uint256 public nextTokenId;
  bytes32 immutable public merkleRoot;
  mapping(address => bool) public addressMinted;
  
  string public baseTokenURI = "ipfs://QmUG4zAeWV4mTEr8mTA832iKDsKKQS9xHwcyHqo4X7ESxU/";
  string private _contractURIBackingField = "ipfs://QmfAHnnMQVRHqvRhwgJ6D5ujykqJ4kD3qfv2hfiDjTaExS";

  constructor(bytes32 _merkleRoot,
    address[] memory founders, address reserved, 
    uint128 foundersAlloc, uint128 reservedAlloc) ERC721("Library Onchain", "LOC") {
    
    merkleRoot = _merkleRoot;

    for(uint i = 0; i < founders.length; i++)
    {
      for(uint j = 0; j < foundersAlloc; j++)
      {
        nextTokenId++;
        _mint(founders[i], nextTokenId);
      }
    }

    for(uint j = 0; j < reservedAlloc; j++)
    {
      nextTokenId++;
      _mint(reserved, nextTokenId);
    }

    _setDefaultRoyalty(msg.sender, 600);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  function isWhitelisted(bytes32[] calldata merkleProof, address claimant) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(claimant));
	  return MerkleProof.verify(merkleProof, merkleRoot, leaf) == true;
  }

  function isAlreadyClaimed(address claimant) public view returns (bool) {
    return addressMinted[claimant] != false;
  }

  function whitelist_mint(bytes32[] calldata merkleProof) public payable {
    require(MINT_STAGE >= 1, "whitelist minting not open");
    require(nextTokenId < MAX_SUPPLY, "minted out");
    require(!isAlreadyClaimed(msg.sender), "already claimed");
    addressMinted[msg.sender] = true;
    require(isWhitelisted(merkleProof, msg.sender), "invalid merkle proof");
    require(msg.value >= MINT_PRICE, "insufficient value");
    nextTokenId++;
    _mint(msg.sender, nextTokenId);
  }
  
  function public_mint() public payable {
	  require(nextTokenId < MAX_SUPPLY, "minted out");
	  require(MINT_STAGE >= 2, "public minting not open");
  	require(msg.value >= MINT_PRICE, "insufficient value");
    require(!isAlreadyClaimed(msg.sender), "already minted");
    addressMinted[msg.sender] = true;
    nextTokenId++;
    _mint(msg.sender, nextTokenId);
  }

  function withdrawOtherTokens (address _token) external onlyOwner {
      require (_token != address(0), "!zero");
      IERC20 token = IERC20(_token);
      uint256 tokenBalance = token.balanceOf(address(this));

      if (tokenBalance > 0) {
          token.transfer(owner(), tokenBalance);
      }
  }

  function withdrawETH() external onlyOwner {
      uint256 contractBalance = address(this).balance;
      
      if (contractBalance > 0) {
        payable(owner()).transfer(contractBalance);
      }
  }

  function setRoyaltyInfo(address _receiver, uint96 _feeNumerator) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function setMintStage(uint256 stage) external onlyOwner {
    MINT_STAGE = stage;
  }

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }
  
  function contractURI() public view returns (string memory) {
      return _contractURIBackingField;
  }

  function setContractURI(string memory newURI) external onlyOwner {
      _contractURIBackingField = newURI;
  }
}