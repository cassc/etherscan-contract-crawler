//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./SignedAllowance.sol";
import "./MultisigOwnable.sol";
import "./BatchOffsets.sol";
import './ERC2981ContractWideRoyalties.sol';

/*
'##::::'##:'########::'##:::::::
 ###::'###: ##.... ##: ##:::::::
 ####'####: ##:::: ##: ##:::::::
 ## ### ##: ########:: ##:::::::
 ##. #: ##: ##.....::: ##:::::::
 ##:.:: ##: ##:::::::: ##:::::::
 ##:::: ##: ##:::::::: ########:
..:::::..::..:::::::::........::
*/

/// @title Martian Premier League
contract MPL is ERC721A, BatchOffsets, SignedAllowance, ReentrancyGuard, MultisigOwnable, ERC2981ContractWideRoyalties {

  using Strings for uint256;

  // Custom errors
  error OverMintLimit();
  error AllMinted();
  error InsufficientValue();
  error InvalidRecipient();
  error TokenDoesNotExist();
  error PublicSaleNotStarted();
  error MarsListInactive();
  error AlreadyClaimed();
  error SenderNotTxOrigin();
  error BatchNotMinted();
  error NonSequentialBatch();
  error LimitBatchMismatch();
  error OnlyOneCallPerBlockForNonEOA();
  error ContractIsFrozen();
  error NotUsingBatches();

  // events to help with indexing
  event LimitUpdated(uint256 newLimit);
  event BaseURIUpdated(string newBaseURI);
  event SuffixUpdated(string newSuffix);
  event PreRevealURIUpdated(string newPreRevealURI);
  event MaxQuantityUpdated(uint256 newMaxQuantity);
  event PriceUpdated(uint256 newPrice);
  event FundsWithdrawn(uint256 amount);
  event PublicSaleUpdated(bool newValue);
  event MarsListUpdated(bool newValue);
  event BatchSizeUpdated(uint256 newBatchSize);
  event Frozen();
  event FancyMathUpdated();
  event RoyaltiesUpdated(uint256 value);

  /*///////////////////////////////////////////////////////////////
                            Settings
  //////////////////////////////////////////////////////////////*/

  // tracking internal variables
  uint256 private _limit;
  uint256 private _revealedBatch;

  // max quantity that can be minted per mint()
  uint256 public maxQuantity;

  // price per character
  uint256 public price;

  // tokens reserved for the MPL team
  uint256 public ownerLimit;
  uint256 public ownerCount;

  // sale state variables
  bool public publicSale;
  bool public marsList;

  // metadata configuration
  string public baseURI;
  string public preRevealURI;
  string private _suffix = ".json";
  bool public frozen;
  bool public useFancyMath = true;

  // minimum index
  uint256 public minimumIndex;

  // tracking last calls from smart contracts minting, to prevent multi-minting
  mapping(address => uint256) public lastCallFrom;

  /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  struct InitialConfiguration {
      address owner;
      uint256 limit;
      uint256 maxQuantity;
      uint256 ownerLimit;
      uint256 price;
      string baseURI;
      string preRevealURI;
      uint256 revealBatchSize;
      uint256 royaltyValue;
  }

  /// @param config initial configuration for the MPL
  constructor(InitialConfiguration memory config) ERC721A("MPL", "MPL") {
      setBatchSize(config.revealBatchSize);
      setLimit(config.limit);
      setMaxQuantity(config.maxQuantity);
      ownerLimit = config.ownerLimit;
      setPrice(config.price);
      setBaseURI(config.baseURI);
      setPreRevealURI(config.preRevealURI);
      setRoyalties(config.royaltyValue);
      transferOwnership(config.owner);
      transferRealOwnership(config.owner);
  }

  /*///////////////////////////////////////////////////////////////
                        View functions
  //////////////////////////////////////////////////////////////*/

  /// @notice returns the maximum number of tokens available to mint
  /// @return limit the limit
  function limit() public view override returns (uint256) {
    return _limit;
  }

  /// @notice get the shuffled final character ID for a given token (once revealed)
  /// @param id tokenId
  /// @return the shuffled character ID
  function getShuffledId(uint256 id) public view override returns (uint256) {
    if(!useFancyMath) revert NotUsingBatches();
    if(ownerOf(id) == address(0)) revert TokenDoesNotExist();
    return BatchOffsets.getShuffledId(id);
  }

  /// @notice Returns the URI for a given token's metadata
  /// @param id the token ID of interest
  /// @return the URI for this token
  function tokenURI(uint256 id) public view override returns (string memory) {
      if(ownerOf(id) == address(0)) revert TokenDoesNotExist();
      if(!useFancyMath) {
        return string(abi.encodePacked(baseURI,id.toString(),_suffix));
      }
      if(idToBatch(id) > _revealedBatch) return preRevealURI;
      uint256 offsetId = getShuffledId(id);
      return string(abi.encodePacked(baseURI,offsetId.toString(),_suffix));
  }


  /// @notice Helper to know allowancesSigner address
  /// @return the allowance signer address
  function allowancesSigner() public view override returns (address) {
      return owner();
  }

  struct Configuration {
      uint256 limit;
      uint256 totalSupply;
      uint256 maxQuantity;
      uint256 price;
      string baseURI;
      bool marsList;
      bool publicSale;
  }

  /// @notice helper to fetch a lot of useful data in a single call
  /// @return the overall configuration
  function configuration() public view returns (Configuration memory) {
      Configuration memory config;
      config.limit = limit();
      config.totalSupply = totalSupply();
      config.maxQuantity = maxQuantity;
      config.price = price;
      config.baseURI = baseURI;
      config.marsList = marsList;
      config.publicSale = publicSale;
      return config;
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721A, ERC2981Base)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  /*///////////////////////////////////////////////////////////////
                        Updating settings
  //////////////////////////////////////////////////////////////*/

  /// @notice modifier to check if the contract metadata has been frozen
  modifier notFrozen() {
      if(frozen) revert ContractIsFrozen();
      _;
  }

  /// @notice owner only function to freeze the metadata
  function setFrozen() public onlyRealOwner notFrozen {
      emit Frozen();
      frozen = true;
  }

  /// @notice owner only function to toggle if we are using offsets for token IDs
  function setUseFancyMath() public onlyRealOwner notFrozen {
      emit FancyMathUpdated();
      useFancyMath = !useFancyMath;
  }

  /// @notice owner only function to update the metadata suffix
  /// @param newSuffix new suffix
  function setSuffix(string memory newSuffix) public onlyRealOwner notFrozen {
      emit SuffixUpdated(newSuffix);
      _suffix = newSuffix;
  }

  /// @notice owner only function to update the baseURI
  /// @param newBaseURI the new BaseURI
  function setBaseURI(string memory newBaseURI) public onlyRealOwner notFrozen {
      emit BaseURIUpdated(newBaseURI);
      baseURI = newBaseURI;
  }

  /// @notice owner only function to update the preRevealURI
  /// @param newPreRevealURI the new preRevealURI
  function setPreRevealURI(string memory newPreRevealURI) public onlyRealOwner {
      emit PreRevealURIUpdated(newPreRevealURI);
      preRevealURI = newPreRevealURI;
  }

  /// @notice owner only function to update the limit (not available once hit)
  /// batch reveal must divide cleanly into it
  /// @param newLimit the new Limit
  function setLimit(uint256 newLimit) public onlyRealOwner {
      if(totalSupply() == limit() && totalSupply() > 0) revert AllMinted();
      if(newLimit % batchSize() != 0) revert LimitBatchMismatch();
      emit LimitUpdated(newLimit);
      _limit = newLimit;
  }

  /// @notice owner only function to update the batch size for token reveals
  /// batch reveal must divide cleanly into the limit
  /// @param newBatchSize the new batch size
  function setBatchSize(uint256 newBatchSize) public onlyRealOwner {
      if(!useFancyMath) revert NotUsingBatches();
      if(totalSupply() == limit() && totalSupply() > 0) revert AllMinted();
      if(limit() % newBatchSize != 0) revert LimitBatchMismatch();
      emit BatchSizeUpdated(newBatchSize);
      _batchSize = newBatchSize;
  }

  /// @notice owner only function to update the max quantity per mint
  /// @param newMaxQuantity the new max quantity
  function setMaxQuantity(uint256 newMaxQuantity) public onlyRealOwner {
      emit MaxQuantityUpdated(newMaxQuantity);
      maxQuantity = newMaxQuantity;
  }

  /// @notice owner only function to update the price per mint
  /// @param newPrice the new price
  function setPrice(uint256 newPrice) public onlyRealOwner {
      emit PriceUpdated(newPrice);
      price = newPrice;
  }

  /// @notice owner only function to activate or deactivate the public sale
  function setPublicSale() public onlyRealOwner {
      emit PublicSaleUpdated(!publicSale);
      publicSale = !publicSale;
  }

  /// @notice owner only function to activate or deactivate the Mars list
  function setMarsList() public onlyRealOwner {
      emit MarsListUpdated(!marsList);
      marsList = !marsList;
  }

  /// @notice owner only function to set the minimum Mars List index supported
  /// @param newMinimumIndex the newMinimumIndex
  function setMinimumIndex(uint256 newMinimumIndex) public onlyRealOwner {
      minimumIndex = newMinimumIndex;
  }

  /// @notice Allows to set the royalties on the contract
  /// @param value royalties value (between 0 and 10000)
  function setRoyalties(uint256 value) public onlyRealOwner {
      emit RoyaltiesUpdated(value);
      _setRoyalties(realOwner, value);
  }

  /*///////////////////////////////////////////////////////////////
                      Updating Batches
  //////////////////////////////////////////////////////////////*/

  /// @notice simple predictable generator of randomness based on on-chain data, given a seed
  function _getPredictableRandom(uint256 _seed) internal view returns (uint256){
    return uint256(keccak256(abi.encodePacked( blockhash(block.number-1), _seed, msg.sender, address(this) )));
  }

  /// @notice set the random offsets for a batch of batchSize() tokens
  /// @param _batch the batch to reveal
  function setBatchOffset(uint256 _batch) public onlyRealOwner {
    if(!useFancyMath) revert NotUsingBatches();
    if(totalSupply() < batchSize() * _batch && totalSupply() < limit()) revert BatchNotMinted();
    if(_batch != (_revealedBatch + 1)) revert NonSequentialBatch();
    _revealedBatch = _batch;
    _setBatchOffset(_batch, _getPredictableRandom(_batch));
    }

  /*///////////////////////////////////////////////////////////////
                      Withdrawing proceeds
  //////////////////////////////////////////////////////////////*/

  /// @notice only owner function to withdraw funds
  function withdrawFunds() public onlyRealOwner {
      uint amount = address(this).balance;
      (bool success,) = msg.sender.call{value: amount}("");
      require(success, "Failed");
      emit FundsWithdrawn(amount);
  }

  /*///////////////////////////////////////////////////////////////
                          MINT LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @notice internal only function to batch mint tokens
  /// @param to address to receive the tokens
  /// @param quantity number of tokens to mint
  function _batchMint(address to, uint256 quantity) internal virtual {
      if(quantity > (limit() - totalSupply()) || (quantity > maxQuantity && msg.sender != realOwner) || quantity == 0) revert OverMintLimit();
      _safeMint(to, quantity);
  }

  /// @notice public mint function, for public sale
  /// @param quantity number of tokens to mint
  function mint(uint256 quantity) public payable nonReentrant {
      if(!publicSale) revert PublicSaleNotStarted();
      if(msg.value < (price * quantity)) revert InsufficientValue();

      // hat tip to @dieverdump https://twitter.com/dievardump/status/1486111678550974464
      if (msg.sender != tx.origin) {
        if (lastCallFrom[tx.origin] == block.number) {
          revert OnlyOneCallPerBlockForNonEOA();
        }
        lastCallFrom[tx.origin] = block.number;
      }
      _batchMint(msg.sender, quantity);
  }

  /// @notice function to batch mint tokens with an owner signature
  /// @param quantity number of tokens to mint
  /// @param index the index of the Mars List spot
  /// @param signature owner signed message
  function mintWithSignature(uint256 quantity, uint256 index, bytes memory signature) public payable {
      if(!marsList || index < minimumIndex) revert MarsListInactive();
      if(msg.value < (price * quantity)) revert InsufficientValue();
      _useAllowance(index, signature);
      _batchMint(msg.sender, quantity);
  }

  /// @notice only owner function to mint based on the ownerLimit
  /// @param quantity number of tokens to mint
  function ownerMint(uint256 quantity) public onlyRealOwner {
      if(ownerCount + quantity > ownerLimit) revert OverMintLimit();
      ownerCount = ownerCount + quantity;
      _batchMint(msg.sender, quantity);
  }

}