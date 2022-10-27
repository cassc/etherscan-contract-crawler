// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract StormTrooperPFPToken is
  OwnableUpgradeable,
  PausableUpgradeable,
  ERC721EnumerableUpgradeable,
  ERC721HolderUpgradeable
{
  using StringsUpgradeable for uint256;

  string public provenanceHash;
  uint256 public maxStormTrooperSupply;
  address public ethQueueSale;
  string public baseURI;
  uint256 public nextMintedTokenID;
  bool isReveal;
  uint256 public startingIndex;

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _baseMetadataURI,
    uint256 _maxStormTrooperSupply,
    address _ethQueueSale
  ) public initializer validAddress(_ethQueueSale) {
    __Ownable_init();
    __Pausable_init();
    __ERC721_init(_name, _symbol);
    __ERC721Holder_init();
    baseURI = _baseMetadataURI;
    maxStormTrooperSupply = _maxStormTrooperSupply;
    ethQueueSale = _ethQueueSale;
    isReveal = false;
    nextMintedTokenID = 0;
  }

  modifier validAddress(address _addr) {
    require(_addr != address(0), "Not valid address");
    _;
  }

  function flipSaleState() external onlyOwner {
    if (!paused()) {
      _pause();
    } else {
      _unpause();
    }
  }

  /**
      @notice Set provenance once it's calculated
      @dev can only by called from owner 
      @param _provenanceHash hash of provenance
  */
  function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
    provenanceHash = _provenanceHash;
  }

  function setBaseURI(string memory _baseMetadataURI) public onlyOwner {
    isReveal = true;
    baseURI = _baseMetadataURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    _requireMinted(tokenId);
    if (isReveal) {
      return
        bytes(_baseURI()).length > 0
          ? string(abi.encodePacked(baseURI, tokenId.toString()))
          : "";
    } else {
      return _baseURI();
    }
  }

  /**
      @notice receive a request from ethQueueSale SM to handle the purchase action from user. 
      @notice ethQueueSale takes care of deduplicating calls for downstream calls to buy
      @notice Therefore we do not need to deduplicate calls here for efficiency
      @dev only accepts the request from ethQueueSale address
      @dev _seed    unsed parameter, just keep compatible with the interface from ethQueueSale
      @dev _isStake    unsed parameter, just keep compatible with the interface from ethQueueSale
      @param _buyer address
      @param _numberOfTokens   number of Tokens
      @return tokenIds list of random received tokenIDs
  */
  function buy(
    address _buyer,
    uint256 _numberOfTokens,
    uint256, /*_seed*/
    bool /*_isStake*/
  ) external whenNotPaused returns (uint256[] memory) {
    require(msg.sender == ethQueueSale, "Unauthorized");

    return mintTokens(_buyer, _numberOfTokens);
  }

  /**
      @notice Helper to mint a quantity of tokens to the specified address. 
      @dev makes sure all tokenIds it not minted yet
      @param _to mint to address
      @param _numberOfTokens number to mint
      @return tokenIds list of received tokenIDs
   */
  function mintTokens(address _to, uint256 _numberOfTokens)
    private
    returns (uint256[] memory tokenIds)
  {
    require(
      totalSupply() + _numberOfTokens <= maxStormTrooperSupply,
      "Exceed maximum total supply"
    );

    // Set the starting index for the collection.
    // NOTE: This does not have to be perfectly random. Blockhash is a sufficient randomness source
    if (startingIndex == 0) {
      startingIndex =
        uint256(blockhash(block.number - 1)) %
        maxStormTrooperSupply;
      if (startingIndex == 0) {
        startingIndex = 1; // Slightly better odds to get index 1 but that is OK
      }
      nextMintedTokenID = startingIndex;
    }

    uint256 tempNextMintedTokenID = nextMintedTokenID;

    tokenIds = new uint256[](_numberOfTokens);

    for (uint256 i = 0; i < _numberOfTokens; i++) {
      while (_exists(tempNextMintedTokenID)) {
        tempNextMintedTokenID =
          (tempNextMintedTokenID + 1) %
          maxStormTrooperSupply;
      }
      _safeMint(_to, tempNextMintedTokenID);
      tokenIds[i] = tempNextMintedTokenID;
      tempNextMintedTokenID =
        (tempNextMintedTokenID + 1) %
        maxStormTrooperSupply;
    }
    nextMintedTokenID = tempNextMintedTokenID;
  }

  /**
      @notice reserve by tokenIds. 
      @dev can only be called from owner 
      @dev make sure all tokenIds it not minted yet
      @param _toAddress reserve to address
      @param _tokenIds   list of tokenIDs
  */
  function reserveByTokenIds(address _toAddress, uint256[] memory _tokenIds)
    external
    onlyOwner
  {
    require(
      totalSupply() + _tokenIds.length <= maxStormTrooperSupply,
      "Exceed maximum total supply"
    );
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(_tokenIds[i] < maxStormTrooperSupply, "invalid tokenId");
      _safeMint(_toAddress, _tokenIds[i]);
    }
  }

  /**
      @notice reserve by number of token. 
      @dev can only by called from owner 
      @param _toAddress reserve to address
      @param _quantity number of token
      @return tokenIds list of received tokenIDs
  */

  function reserveByQuantity(address _toAddress, uint256 _quantity)
    external
    onlyOwner
    returns (uint256[] memory)
  {
    return mintTokens(_toAddress, _quantity);
  }
}