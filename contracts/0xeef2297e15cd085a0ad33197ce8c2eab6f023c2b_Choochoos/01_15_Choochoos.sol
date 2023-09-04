// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import { ERC721, ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
 * @title Choochoos
 * @notice Some cool Choo Choos.
 */
contract Choochoos is ERC721Royalty, Ownable, ReentrancyGuard {

  /* ============ Variables ============ */
  /// @notice Contract address of the premint NFT token
  address[] public targetContracts;

  /// @notice Max number of NFTs available in this collection
  uint32 public immutable maxNFT;

  /// @notice Max number of NFTs that can be minted in public mint
  uint32 public immutable maxMint;

  /// @notice Max number of Presale NFTs that can be minted in premint
  uint32 public immutable presaleMaxMint;

  /// @notice Flag if sale is mintable
  bool public saleIsActive;

    /// @notice Flag if sale is in premint
  bool public premintIsActive;

  /// @notice Total supply of NFTs
  uint256 public totalSupply;

  /// @notice NFT tokens base URI
  string public baseURI;

  /// @notice Map to track number of mints per address
  mapping(address => uint256) public mintTracker;

  /// @notice Flag for if NFT metadata is revealed
  bool private revealed = false;

  string private constant REVEAL_URI = "ipfs://QmRJ6TQpAKUGAm8DHTi8CEHR5z3fpqxfaj1R6LsZhvmt7h";


  /* ============ Constructor ============ */

  /**
   * @notice Initializes the NFT contract
   * @param _name NFT collection name
   * @param _symbol NFT collection symbol
   * @param _maxNFT Max number of NFTs available in this collection
   * @param _maxMint Max number of NFTs that can be minted in a single transaction
   * @param _presaleMaxMint Max number of Presale NFTs that can be minted in a single transaction
   * @param _saleIsActive Boolean if NFTs are mintable
   * @param _premintActive Boolean if NFTs are in premint
   * @param _targetContracts List of contract addresses for premint
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint32 _maxNFT,
    uint32 _maxMint,
    uint32 _presaleMaxMint,
    bool _saleIsActive,
    bool _premintActive,
    address[] memory _targetContracts
  ) ERC721(_name, _symbol) {
    require(_maxNFT > 0, "CCNFT/max-nft-gt-zero");
    require(_maxMint > 0, "CCNFT/max-mint-gt-zero");
    require(_presaleMaxMint > 0, "CCNFT/pm-max-mint-gt-zero");

    maxNFT = _maxNFT;
    maxMint = _maxMint;
    presaleMaxMint = _presaleMaxMint;
    saleIsActive = _saleIsActive;
    premintIsActive = _premintActive;
    targetContracts = _targetContracts;
  }

  /* ============ External Functions ============ */

  /**
   * @notice Returns sale is active flag.
   */
  function isSaleActive() external view returns (bool) {
      return saleIsActive;
  }

  /**
   * @notice Returns premint is active flag.
   */
  function isPremintActive() external view returns (bool) {
      return premintIsActive;
  }

  /**
   * @notice Override: returns token uri or static reveal uri if reveal is not active
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (revealed == true){
      return super.tokenURI(tokenId);
    } else {
      return REVEAL_URI;
    }
  }

  /**
   * @notice Pause sale if active, make active if paused
   */
  function flipSaleState() public onlyOwner {
      saleIsActive = !saleIsActive;
  }

  /**
   * @notice set premint state to true if false and vice versa
   */
  function flipPremintState() public onlyOwner {
      premintIsActive = !premintIsActive;
  }

  /**
   * @notice set premint state to true if false and vice versa
   */
  function flipRevealedState() public onlyOwner {
      revealed = !revealed;
  }

  /**
   * @notice Set some Choo Choos aside
   * @param _amount Number of Choo Choos to owner mint
   */
  function reserveMint(uint256 _amount) public onlyOwner {        
      uint256 _totalSupply = totalSupply;
      uint256 i;
      for (i = 0; i < _amount; i++) {
          _safeMint(msg.sender, _totalSupply + i);
      }
      totalSupply = _totalSupply + _amount;
  }

  /**
   * @notice Mints a new number of NFTs if minter holds a certain NFT or vip listed.
   * @param _numberOfTokens Number of NFTs to mint
   */
  function preMint(uint256 _numberOfTokens) external nonReentrant {
    bool _premintIsActive = premintIsActive;

    require(_premintIsActive,"CCNFT/premint-inactive");
    
    bool _holder = false; 
    for (uint8 i; i < targetContracts.length; i++) {
      if (IERC721(targetContracts[i]).balanceOf(msg.sender) > 0){
        _holder = true;
        break;
      }
    }
    require(_holder, "CCNFT/premint-pass-non-holder");

    uint256 _totalSupply = totalSupply;

    require(_totalSupply + _numberOfTokens <= maxNFT, "CCNFT/pm-nfts-sold-out");
    require(_numberOfTokens <= presaleMaxMint, "CCNFT/pm-exceeds-max-mint");
    require(mintTracker[msg.sender] + _numberOfTokens <= presaleMaxMint, "CCNFT/pm-account-max-mint");

    for (uint256 index; index < _numberOfTokens; index++) {
      uint256 _mintIndex = _totalSupply + index;

      if (_mintIndex < maxNFT) {
        _safeMint(msg.sender, _mintIndex);
      }
    }

    mintTracker[msg.sender] += _numberOfTokens;

    totalSupply = _totalSupply + _numberOfTokens;
  }

  /**
   * @notice Mints a new number of NFTs.
   * @param _numberOfTokens Number of NFTs to mint
   */
  function mintNFT(uint256 _numberOfTokens) external nonReentrant {
    bool _saleIsActive = saleIsActive;

    require(_saleIsActive,"CCNFT/sale-inactive");

    uint256 _totalSupply = totalSupply;

    require(_totalSupply + _numberOfTokens <= maxNFT, "CCNFT/nfts-sold-out");
    require(_numberOfTokens <= maxMint, "CCNFT/exceeds-max-mint");
    require(mintTracker[msg.sender] + _numberOfTokens <= maxMint, "CCNFT/account-max-mint");

    for (uint256 index; index < _numberOfTokens; index++) {
      uint256 _mintIndex = _totalSupply + index;

      if (_mintIndex < maxNFT) {
        _safeMint(msg.sender, _mintIndex);
      }
    }

    mintTracker[msg.sender] += _numberOfTokens;

    totalSupply = _totalSupply + _numberOfTokens;
  }

  /**
   * @notice Set NFT tokens base URI
   * @dev This function is only callable by the owner of the contract.
   * @param baseURI_ NFT tokens base URI
   */
  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  /**
   * @notice Sets the royalty fee that all ids in this contract will default to.
   * @dev Fees are expressed in basis points. For example: 1000 = 10%
   * @param _recipient Address to whom the royalty fee will be paid
   * @param _fee Percentage of the secondary sales that will be paid to the `_recipient`
   */
  function setRoyaltyFee(address _recipient, uint96 _fee) external onlyOwner {
    _setDefaultRoyalty(_recipient, _fee);
  }

  /**
   * @notice Withdraw ETH from the contract.
   * @dev This function is only callable by the owner of the contract.
   */
  function withdraw() external onlyOwner {
    uint256 _amount = address(this).balance;
    require(_amount > 0, "CCNFT/withdraw-amount-gt-zero");

    (bool _success, ) = msg.sender.call{ value: _amount }("");

    require(_success, "CCNFT/failed-to-withdraw-eth");
  }

  receive() external payable {}

  /* ============ Internal Functions ============ */

  /**
   * @notice Set NFT base URI.
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   * @return NFT tokens base URI
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}