// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract RiotGirls is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _tokenIds;


  bytes32 public merkleRoot;
  mapping(address => uint256) public preSaleMinted;

  uint256 constant private ABSOLUTE_MAX_SUPPLY = 666;
  uint256 public maxSupply = 468; // start with pre sale window 1 max
  uint256 public currentPrice = 0 ether; //set in constructor

  address constant private nadya = 0x955B6F06981d77f947F4d44CA4297D2e26a916d7;
  address constant private indieDAO = 0x762C0cefBdC51D3ca0553b81792D82fcA96EF7a3;

  enum MintingStage {
    CLOSED,
    PRE_SALE_WINDOW_1,
    PRE_SALE_WINDOW_2,
    PUBLIC_SALE
  }

  MintingStage public currentStage = MintingStage.CLOSED;

  string public baseTokenURI = 'https://riotgirls.2c.io/api/tokens/';

  constructor() ERC721('Riot Girls', 'RIOT') Ownable() {
    _mintNFTs(nadya,15);
    _mintNFTs(indieDAO,10);
    
    currentPrice = 0.222 ether;
  }

  function mint(uint256 count) external payable {
    require(
      currentStage == MintingStage.PUBLIC_SALE,
      'Public riot is not live...yet'
    );
    _mintNFTs(msg.sender,count);
  }

  function presaleMint(
    uint256 count,
    uint256 maxAllowed,
    bytes32[] calldata proof
  ) external payable {
    require(
      merkleRoot != 0 && currentStage != MintingStage.CLOSED,
      'Presale is booting up - check back soon'
    );
    require(
      _verify(_leaf(msg.sender, maxAllowed), proof),
      "Looks like there's an issue with your wallet babe"
    );
    require(
      preSaleMinted[msg.sender].add(count) <= maxAllowed,
      unicode"Someone's greedy 👀 - you've already minted your presale Riot Girls, come back during public mint for more."
    );

    //Don't allow total during preSale to be more than maxAllowed by Merkle Tree
    preSaleMinted[msg.sender] = preSaleMinted[msg.sender].add(count);

    _mintNFTs(msg.sender, count);
  }

  function _mintSingleNFT(address recipient, uint256 newTokenID) internal {
    _tokenIds.increment();
    _safeMint(recipient, newTokenID);
  }

  function _mintNFTs(address recipient, uint256 _count) internal {
    uint256 totalMinted = _tokenIds.current();

    require(
      totalMinted.add(_count) <= maxSupply,
      unicode'All of our Riot Girls have been unleashed! Sorry, not sorry. Find us on secondary 😘'
    );
    require(
      msg.value >= currentPrice.mul(_count),
      unicode"Girl, you need more ETH in your wallet if you want to hang with us. It's .222 per Riot Girl 💅"
    );

    for (uint256 i = 0; i < _count; i++) {
      _mintSingleNFT(recipient,totalMinted.add(i));
    }
  }

  function getTokenIds(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory _tokensOfOwner = new uint256[](ERC721.balanceOf(_owner));
    uint256 i;

    for (i = 0; i < ERC721.balanceOf(_owner); i++) {
      _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
    }

    return (_tokensOfOwner);
  }

  function getLastTokenId() external view returns (uint256) {
    return _tokenIds.current();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root;
  }

  function setMaxSupply(uint256 max) external onlyOwner {
    require(
      max <= ABSOLUTE_MAX_SUPPLY,
      "Easy there, we can't go over the limit"
    );
    maxSupply = max;
  }

  function setMintingStage(MintingStage stage) external onlyOwner {
    currentStage = stage;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'No ether left to withdraw');
    require(payable(msg.sender).send(balance), 'Transfer failed');
  }

  function _leaf(address recipient, uint256 amount)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(amount, recipient));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }
}