// SPDX-License-Identifier: MIT

/// PEPE AI Coupon
/// ---------------
/// Pepe Analytics is an analytics dashboard for memecoins.
/// This NFT represents PepeAI coupons which will be redeemable for PEPEAI tokens when the dashboard is live.
/// The tokens will grant lifetime access.
/// ---------------
/// Website: http://www.pepeanalytics.com
/// Twitter: https://twitter.com/pepeanalyticsai
/// Discord: http://discord.gg/pepeanalytics
/// Medium: https://medium.com/@pepeanalytics

pragma solidity ^0.8.0;

import "@openzeppelin/token/common/ERC2981.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

contract PEPEAICoupon is ERC721Enumerable, ERC2981, Ownable {
  
  uint256 public constant MINT_PRICE = 0.35 ether;
  uint256 public constant MAX_SUPPLY = 520;
  uint256 public MINT_STAGE = 0;

  uint256 public nextTokenId;
  bytes32 immutable public merkleRoot;
  mapping(address => bool) public addressMinted;
  
  string public baseTokenURI = "ipfs://QmRjpEU2XEsFFc7Z2c9ac28RtKqdMzgieVUmFtEJ1NcRJH/";
  string private _contractURIBackingField = "ipfs://QmeYiBhWHeqHxk4djAMxQzqTrMjSj5RJ8PeiHqhgLQ5Vxf";

  constructor(bytes32 _merkleRoot, address reservedOwner, uint128 reservedAlloc)
    ERC721("PEPEAI Coupon", "PEPEAI")
    Ownable(msg.sender) {
    
    merkleRoot = _merkleRoot;

    for(uint j = 0; j < reservedAlloc; j++)
    {
      nextTokenId++;
      _mint(reservedOwner, nextTokenId);
    }

    _setDefaultRoyalty(msg.sender, 800);
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

  function mintWhitelist(bytes32[] calldata merkleProof) public payable {
    require(MINT_STAGE >= 1, "whitelist minting not open");
    require(nextTokenId < MAX_SUPPLY, "minted out");
    require(!isAlreadyClaimed(msg.sender), "already claimed");
    addressMinted[msg.sender] = true;
    require(isWhitelisted(merkleProof, msg.sender), "invalid merkle proof");
    require(msg.value >= MINT_PRICE, "insufficient value");
    nextTokenId++;
    _mint(msg.sender, nextTokenId);
  }
  
  function mintPublic() public payable {
	  require(nextTokenId < MAX_SUPPLY, "minted out");
	  require(MINT_STAGE >= 2, "public minting not open");
  	require(msg.value >= MINT_PRICE, "insufficient value");
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