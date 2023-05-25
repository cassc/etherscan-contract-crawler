// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

//                      %@@@@@                @@@@@
//                      %@@@@@                @@@@@
//              @       %@@@@@       @        @@@@@       ,
//             @@@@@@   %@@@@@   @@@@@@@@@    @@@@@   [email protected]@@@@&
//             /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                #@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@          @@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@
//            @@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@ @@@@@ @@@@@@@@@#
//             @@@@@    %@@@@@    @@@@@@@     @@@@@    [email protected]@@@
//                      %@@@@@                @@@@@
//                      %@@@@@                @@@@@
//
//
//                               who*anon*
//
//
//
//                 @@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@
//          p   m  @@@@@@&&&&&&/      %%&&&%*     (&&&@@@@@
//          o   e  @@@@@@&&&&&&&%.     /%%*       #&&&@@@@@
//          w b t  @@@@@@&&&&&&&%#              ,%&&&@@@@@@
//          e y a  @@@@@@&&&&&&&&&%%,       .    (%&&@@@@@@
//          r   d  @@@@@@&&&&&&&&&&&%%    (/     #&&&@@@@@@
//          e   r  @@@@@@&&&#  &&&&&&&&%%%%*    /%&&&@@@@@@
//          d   o  @@@@@@&&&*   (&&&&&&&&&%.    (&&&@@@@@@@
//              p  @@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@
//
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @dev who*anon* ERC-1155 contract
 */
contract WhoAnonByMetadrop is
  ERC1155,
  Ownable,
  Pausable,
  ERC1155Burnable,
  ERC1155Supply
{
  // ERC-2981: NFT Royalty Standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  /**
   * @dev Add name and symbol for consistency with ERC-721 NFTs. Note that ERC-721 stores
   * these variables on-chain, but as they can only be set on the constructor we may as well
   * save the storage and have them as constants in the bytecode. You're welcome Ethereum!
   */
  string private constant NAME = "who*anon*";
  string private constant SYMBOL = "WHOANON";

  /**
   * @dev Developer address:
   */
  address public developer;
  address public beneficiary;

  /**
   * @dev Price buffer above and below the passed amount of ETH that will be accepted. This function
   * will be used to set the price for items in the UI, but there is always the possibility of price
   * fluctuations beween the display and the mint. These parameters determine as an amount per thousand
   * how high above or below the price the passed amount of ETH can be and still make a valid sale. The
   * stored values are in the following format:
   *   - priceBufferUp: amount as a proportion of 1,000. For example, if you set this to 1005 you allow the
   *       price to be up to 1005 / 1000 of the actual price, i.e. not exceeding 0.5% greater.
   *   - priceBufferDown: amount as a proportion of 1,000. For example, if you set this to 995 you allow the
   *       price to be up to 995 / 1000 of the actual price i.e. not exceeding 0.5% less.
   */
  uint16 public priceBufferUp;
  uint16 public priceBufferDown;

  bool public pausableShutoffProtectionDisabled = false;
  bool public pausableDisabled = false;

  bool public publicationShutoffProtectionDisabled = false;
  bool public publicationDisabled = false;

  // while we initialize to 0, we will mint the first token at 1
  uint256 public latestEdition;

  /**
   * @dev ERC-2981 configuration
   */
  address public royaltyReceipientAddress;
  uint256 public royaltyPercentageBasisPoints;

  AggregatorV3Interface internal priceFeed;

  /**
   * @dev titles struct:
   */
  struct PublishedTitle {
    // Slot 1 and 2 (at least)
    string titleURI;
    // Slot 3, 64 + 128 + 64 = 256
    uint64 maxSupply;
    uint128 priceInUSD;
    uint64 startTime;
    // Slot 4, 64 + 64 + 8 + 8 = 144
    uint64 endTime;
    uint64 developerAllocation;
    bool developerAllocationLocked;
    bool exists;
  }

  /**
   * @dev map token classes to parameters:
   */
  mapping(uint256 => PublishedTitle) public publishedTitles;

  mapping(uint256 => uint256) public developerAllocationMinted;

  /**
   * @dev Contract events:
   */
  event PriceBufferUpSet(uint256 priceBuffer);
  event PriceBufferDownSet(uint256 priceBuffer);
  event YouAreAnon(
    address account,
    uint256 tokenId,
    uint256 quantity,
    uint256 cost
  );
  event YouAreRedeemedAnon(
    address account,
    uint256 tokenId,
    uint256 quantity,
    bytes32 hashData,
    bytes data
  );
  event TitlePublished(
    uint256 tokenId,
    string titleURI,
    string redeemableURI_,
    uint64 maxSupply,
    uint128 priceInUSD,
    uint64 mintStartDate,
    uint64 mintEndDate,
    uint64 redeemStartDate,
    uint64 redeemEndDate,
    uint64 developerAllocation,
    bool developerAllocationLocked
  );

  error SupplyExceeded();
  error CannotMintRedeemTokens();
  error CannotRedeemRedeemTokens();
  error InvalidParameters();
  error DeveloperAllocationExceeded();
  error DeveloperAllocationLocked();
  error PublicationIsDisabled();
  error PausableIsDisabled();
  error PublicationShutoffProtectionIsOn();
  error PausableShutoffProtectionIsOn();

  /**
   * @dev Constructor must be passed an array of shareholders for the payment splitter, the first
   * array holding addresses and the second the corresponding shares. For example, you could have the following:
   *   - payees_ [beneficiaryAddress, developerAddress]
   *   - shares_ [90,10]
   * In this example the beneficiary address passed in can claim 90% of total ETH, the developer 10%
   */
  constructor(
    uint16[] memory priceBuffers_,
    address beneficiary_,
    address developer_,
    address priceFeedAddress_,
    PublishedTitle[] memory firstEditions_
  ) ERC1155("") {
    setPriceBufferUp(priceBuffers_[0]);
    setPriceBufferDown(priceBuffers_[1]);
    beneficiary = beneficiary_;
    developer = developer_;
    // @dev Contract address for pricefeed data.
    // MAINNET: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    // GOERLI: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    priceFeed = AggregatorV3Interface(priceFeedAddress_);
    _publishFirstEditions(firstEditions_);
  }

  modifier whenMintingOpen(uint256 tokenId_) {
    require(mintingIsOpen(tokenId_), "Minting is not open");
    _;
  }

  modifier whenMintingClosed(uint256 tokenId_) {
    require(!mintingIsOpen(tokenId_), "Minting is open");
    _;
  }

  modifier onlyOwnerOrDeveloper() {
    require(
      msg.sender == owner() || msg.sender == developer,
      "Only owner or developer"
    );
    _;
  }

  /**
   * @dev whenDeveloperAllocationAvailable
   */
  modifier whenDeveloperAllocationAvailable(
    uint256 tokenId_,
    uint256 quantity_
  ) {
    if (
      (developerAllocationMinted[tokenId_] + quantity_) >
      publishedTitles[tokenId_].developerAllocation
    ) {
      revert DeveloperAllocationExceeded();
    }
    _;
  }

  /**
   *  =======================================
   *  ADMIN FUNCTIONS
   *  =======================================
   */

  /**
   * @dev owner can publish new titles:
   */
  function publish(
    string memory mintableURI_,
    string memory redeemableURI_,
    uint64 maxSupply_,
    uint128 priceInUSD_,
    uint64 mintableStartTime_,
    uint64 mintableDurationInHours_,
    uint64 redeemableStartTime_,
    uint64 redeemableDurationInHours_,
    uint64 developerAllocation_,
    bool developerAllocationLocked_
  ) external onlyOwner {
    if (publicationDisabled) {
      revert PublicationIsDisabled();
    }

    uint256 mintableEditionTokenId = latestEdition + 1;
    uint256 redeemableEditionTokenId = mintableEditionTokenId + 1;

    // Publish the mintable edition:
    publishedTitles[mintableEditionTokenId].titleURI = mintableURI_;
    publishedTitles[mintableEditionTokenId].maxSupply = maxSupply_;
    publishedTitles[mintableEditionTokenId].priceInUSD = priceInUSD_;
    publishedTitles[mintableEditionTokenId].startTime = mintableStartTime_;
    publishedTitles[mintableEditionTokenId].endTime =
      mintableStartTime_ +
      (mintableDurationInHours_ * 1 hours);
    publishedTitles[mintableEditionTokenId]
      .developerAllocation = developerAllocation_;
    publishedTitles[mintableEditionTokenId]
      .developerAllocationLocked = developerAllocationLocked_;
    publishedTitles[mintableEditionTokenId].exists = true;

    // Publish the redeemable edition:
    publishedTitles[redeemableEditionTokenId].titleURI = redeemableURI_;
    publishedTitles[redeemableEditionTokenId].maxSupply = 0;
    publishedTitles[redeemableEditionTokenId].priceInUSD = 0;
    publishedTitles[redeemableEditionTokenId].startTime = redeemableStartTime_;
    publishedTitles[redeemableEditionTokenId].endTime =
      redeemableStartTime_ +
      (redeemableDurationInHours_ * 1 hours);
    publishedTitles[redeemableEditionTokenId].developerAllocation = 0;
    publishedTitles[redeemableEditionTokenId].developerAllocationLocked = true;
    publishedTitles[redeemableEditionTokenId].exists = true;

    latestEdition = redeemableEditionTokenId;

    emit TitlePublished(
      mintableEditionTokenId,
      mintableURI_,
      redeemableURI_,
      maxSupply_,
      priceInUSD_,
      mintableStartTime_,
      mintableStartTime_ + (mintableDurationInHours_ * 1 hours),
      redeemableStartTime_,
      redeemableStartTime_ + (redeemableDurationInHours_ * 1 hours),
      developerAllocation_,
      developerAllocationLocked_
    );
  }

  /**
   * @dev updatePriceFeedAddress
   */
  function updatePriceFeedAddress(address priceFeedAddress_)
    external
    onlyOwner
  {
    priceFeed = AggregatorV3Interface(priceFeedAddress_);
  }

  /**
   * @dev updateLatestEdition
   */
  function updateLatestEdition(uint32 latestEdition_) external onlyOwner {
    latestEdition = latestEdition_;
  }

  /**
   * @dev disablePausableShutoffProtection
   */
  function disablePausableShutoffProtection() external onlyOwner {
    pausableShutoffProtectionDisabled = true;
  }

  /**
   * @dev disablePausable
   */
  function disablePausable() external onlyOwner {
    if (pausableShutoffProtectionDisabled) {
      pausableDisabled = true;
    } else {
      revert PausableShutoffProtectionIsOn();
    }
  }

  /**
   * @dev enablePausableShutoffProtection
   */
  function enablePausableShutoffProtection() external onlyOwner {
    pausableShutoffProtectionDisabled = false;
  }

  /**
   * @dev disablePausableShutoffProtection
   */
  function disablePublicationShutoffProtection() external onlyOwner {
    publicationShutoffProtectionDisabled = true;
  }

  /**
   * @dev disablePublication
   */
  function disablePublication() external onlyOwner {
    if (publicationShutoffProtectionDisabled) {
      publicationDisabled = true;
    } else {
      revert PublicationShutoffProtectionIsOn();
    }
  }

  /**
   * @dev enablePublicationShutoffProtection
   */
  function enablePublicationShutoffProtection() external onlyOwner {
    publicationShutoffProtectionDisabled = false;
  }

  /**
   * @dev owner can reduce supply:
   */
  function reduceSupply(uint256 tokenId_, uint64 maxSupply_)
    external
    onlyOwner
  {
    require(publishedTitles[tokenId_].exists, "Token ID does not exist");

    // A supply of 0 is unlimited, so under no circumstances can this be a valid update:
    require(
      maxSupply_ != 0,
      "Cannot set to unlimited after initial publication"
    );

    // A supply of 0 is unlimited, so always allow a reduction from unlimited:
    if (publishedTitles[tokenId_].maxSupply > 0) {
      require(
        publishedTitles[tokenId_].maxSupply > maxSupply_,
        "Supply can only be decreased"
      );
    }
    publishedTitles[tokenId_].maxSupply = maxSupply_;
  }

  /**
   * @dev updateTokenURI
   */
  function updateTokenURI(uint256 tokenId_, string memory uri_)
    external
    onlyOwner
  {
    require(publishedTitles[tokenId_].exists, "Token ID does not exist");

    publishedTitles[tokenId_].titleURI = uri_;
  }

  /**
   * @dev updateTokenPriceInUSD
   */
  function updateTokenPriceInUSD(uint256 tokenId_, uint128 tokenPrice_)
    external
    onlyOwner
  {
    require(publishedTitles[tokenId_].exists, "Token ID does not exist");

    // A supply of 0 is unlimited, so under no circumstances can this be a valid update:
    publishedTitles[tokenId_].priceInUSD = tokenPrice_;
  }

  /**
   * @dev updateStartTime
   */
  function updateStartTime(uint256 tokenId_, uint64 startTime_)
    external
    onlyOwner
  {
    require(publishedTitles[tokenId_].exists, "Token ID does not exist");

    publishedTitles[tokenId_].startTime = startTime_;
  }

  /**
   * @dev updateEndTime
   */
  function updateEndTime(uint256 tokenId_, uint64 endTime_) external onlyOwner {
    require(publishedTitles[tokenId_].exists, "Token ID does not exist");

    publishedTitles[tokenId_].endTime = endTime_;
  }

  /**
   * @dev updateDeveloperAllocation
   */
  function updateDeveloperAllocation(
    uint256 tokenId_,
    uint64 developerAlloaction_
  ) external onlyOwner {
    require(publishedTitles[tokenId_].exists, "Token ID does not exist");

    if (publishedTitles[tokenId_].developerAllocationLocked) {
      revert DeveloperAllocationLocked();
    }

    publishedTitles[tokenId_].developerAllocation = developerAlloaction_;
  }

  /**
   * @dev lockDeveloperAllocationForTokenId
   */
  function lockDeveloperAllocationForTokenId(uint256 tokenId_)
    external
    onlyOwner
  {
    publishedTitles[tokenId_].developerAllocationLocked = true;
  }

  /**
   * @dev updateDeveloper
   */
  function updateDeveloper(address developer_) external onlyOwner {
    developer = developer_;
  }

  /**
   * @dev updateBeneficiary
   */
  function updateBeneficiary(address beneficiary_) external onlyOwner {
    beneficiary = beneficiary_;
  }

  /**
   * @dev setPriceBufferUp
   */
  function setPriceBufferUp(uint16 priceBufferUpToSet_) public onlyOwner {
    priceBufferUp = priceBufferUpToSet_;
    emit PriceBufferUpSet(priceBufferUp);
  }

  /**
   * @dev setPriceBufferDown
   */
  function setPriceBufferDown(uint16 priceBufferDownToSet_) public onlyOwner {
    priceBufferDown = priceBufferDownToSet_;
    emit PriceBufferDownSet(priceBufferDown);
  }

  /**
   * @dev pause
   */
  function pause() public onlyOwner {
    if (pausableDisabled) {
      revert PausableIsDisabled();
    }
    _pause();
  }

  /**
   * @dev unpause
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   *  =======================================
   *  GETTERS
   *  =======================================
   */

  /**
   * @dev get Title details
   */
  function getTitleDetails(uint256 _tokenId)
    external
    view
    returns (PublishedTitle memory)
  {
    return (publishedTitles[_tokenId]);
  }

  function getPriceFeedAddress() external view returns (address) {
    return (address(priceFeed));
  }

  function mintingIsOpen(uint256 tokenId_) public view returns (bool) {
    return (block.timestamp >= publishedTitles[tokenId_].startTime &&
      block.timestamp <= publishedTitles[tokenId_].endTime);
  }

  function getCurrentRate() external view returns (uint256) {
    return (uint256(getLatestPrice()));
  }

  function getDollarValueInWei(uint256 _dollarValue)
    external
    view
    returns (uint256)
  {
    uint256 latestPrice = uint256(getLatestPrice());
    return (_performConversion(latestPrice, _dollarValue));
  }

  function getETHPriceForTokenId(uint256 tokenId_)
    public
    view
    returns (uint256 price_)
  {
    uint256 latestPrice = uint256(getLatestPrice());

    return (
      _performConversion(latestPrice, publishedTitles[tokenId_].priceInUSD)
    );
  }

  function getBuffers()
    external
    view
    onlyOwner
    returns (uint256 bufferUp_, uint256 bufferDown_)
  {
    return (priceBufferUp, priceBufferDown);
  }

  /**
   * @dev Add name, symbol and total supply for consistency with ERC-721 NFTs.
   */
  function name() public pure returns (string memory) {
    return NAME;
  }

  function symbol() public pure returns (string memory) {
    return SYMBOL;
  }

  function totalSupply()
    public
    view
    returns (uint256 totalSupplyForAllCollections_)
  {
    for (uint256 i = 1; i <= latestEdition; ) {
      totalSupplyForAllCollections_ += totalSupply(i);
      unchecked {
        i++;
      }
    }
    return totalSupplyForAllCollections_;
  }

  /**
   * Returns the latest USD price to 8DP of 1 ETH
   */
  function getLatestPrice() public view returns (int256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return price;
  }

  /**
   * @dev _publishFirstEditions
   */
  function _publishFirstEditions(PublishedTitle[] memory firstEditions_)
    internal
  {
    for (uint256 i = 0; i < firstEditions_.length; ) {
      publishedTitles[i + 1] = firstEditions_[i];

      unchecked {
        i++;
      }
    }
    for (uint256 i = 0; i < firstEditions_.length; ) {
      emit TitlePublished(
        i + 1, // unredeemed edition
        firstEditions_[i].titleURI,
        firstEditions_[i + 1].titleURI,
        firstEditions_[i].maxSupply,
        firstEditions_[i].priceInUSD,
        firstEditions_[i].startTime,
        firstEditions_[i].endTime,
        firstEditions_[i + 1].startTime,
        firstEditions_[i + 1].endTime,
        firstEditions_[i].developerAllocation,
        firstEditions_[i].developerAllocationLocked
      );
      unchecked {
        i += 2;
      }
    }
    // Update the latest Edition number:
    latestEdition = firstEditions_.length;
  }

  /**
   * @dev perform price conversion USD to Wei at the prescribed number of significant figures (i.e. DP in ETH)
   */
  function _performConversion(uint256 _price, uint256 _value)
    internal
    pure
    returns (uint256 convertedValue)
  {
    require(_price > 0 && _price < 9999999999999, "Pricing Error");
    // The USD figure from the price feed is one eth in USD to 8 DP. We need the value of one dollar in wei/
    // The price feed has 8DP so lets add that exponent to our wei figure to give us the value of $1 in wei
    uint256 oneUSDInWei = ((10**26) / _price);
    // 2) Mutiply our dollar value by that to get our value in wei:
    uint256 valueInWei = oneUSDInWei * _value;

    // 3) And then roundup that number to 4DP of eth by removing 10**14 digits, adding 1, then multiplying by 10**14:
    valueInWei = ((valueInWei / (10**14)) + 1) * (10**14);
    return (valueInWei);
  }

  /**
   * @dev This function is called from the UI to mint NFTs for the user.
   */
  function iAmAnon(uint256 tokenId_, uint256 quantity_)
    external
    payable
    whenMintingOpen(tokenId_)
    whenNotPaused
  {
    require(quantity_ != 0, "Order must be for an item");

    // Can only mint mintables, i.e. ODD numbered token IDs. The even equivalent (minted 1 = redeemed 2 etc)
    // must be obtained on redemption of the minted
    if (!_isMintableToken(tokenId_)) {
      revert CannotMintRedeemTokens();
    }

    // Check that we aren't requesting more than is available:
    if (_orderExceedsSupply(tokenId_, quantity_)) {
      revert SupplyExceeded();
    }

    // Calculate the required price for this order:
    uint256 orderPrice = _priceOrder(tokenId_, quantity_);

    // Check the payment is correct:
    _checkPaymentToPrice(msg.value, orderPrice);

    // To reach here the price and quantity check must have passed. Mint the items:
    _mint(msg.sender, tokenId_, quantity_, "");

    emit YouAreAnon(msg.sender, tokenId_, quantity_, msg.value);
  }

  /**
   * @dev This function is called on redemption
   */
  function redeemAnon(
    uint256 tokenId_,
    uint256 quantity_,
    bytes32 dataHash_,
    bytes memory data_
  ) external whenMintingOpen(tokenId_ + 1) whenNotPaused {
    if (_isRedemptionToken(tokenId_)) {
      revert CannotRedeemRedeemTokens();
    }

    require(quantity_ != 0, "Redemption must be for an item");

    burn(msg.sender, tokenId_, quantity_);

    // All good so far? OK, mint their redeption equivalents
    _mint(msg.sender, (tokenId_ + 1), quantity_, "");

    emit YouAreRedeemedAnon(msg.sender, tokenId_, quantity_, dataHash_, data_);
  }

  /**
   * @dev _orderExceedsSupply
   */
  function _orderExceedsSupply(uint256 tokenId_, uint256 quantity_)
    internal
    view
    returns (bool)
  {
    // Note a supply set to 0 is unlimited:
    uint256 maxSupply = publishedTitles[tokenId_].maxSupply;

    if ((maxSupply != 0) && ((quantity_ + totalSupply(tokenId_)) > maxSupply)) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev _isMintableToken
   */
  function _isMintableToken(uint256 tokenId_) internal pure returns (bool) {
    return (tokenId_ % 2 != 0);
  }

  /**
   * @dev _isRedepmtionToken
   */
  function _isRedemptionToken(uint256 tokenId_) internal pure returns (bool) {
    return (tokenId_ % 2 == 0);
  }

  /**
   * @dev Get the current price of this order in the same way that it will have been assembled in the UI,
   * i.e. get the current price of each token type in ETH (including the rounding to 4DP of ETH) and then
   * multiply that by the total quantity ordered.
   */
  function _priceOrder(uint256 tokenId_, uint256 quantity_)
    internal
    view
    returns (uint256 price)
  {
    uint256 orderCostInETH = 0;

    uint256 unitPrice = getETHPriceForTokenId(tokenId_);

    orderCostInETH = (unitPrice * quantity_);

    return (orderCostInETH);
  }

  /**
   * @dev mintDeveloperAllocation
   */
  function mintDeveloperAllocation(uint256 tokenId_, uint256 quantity_)
    external
    payable
    onlyOwnerOrDeveloper
    whenDeveloperAllocationAvailable(tokenId_, quantity_)
  {
    _mint(developer, tokenId_, quantity_, "");

    developerAllocationMinted[tokenId_] += quantity_;
  }

  /**
   * @dev Determine if the passed cost is within bounds of current price:
   */
  function _checkPaymentToPrice(uint256 _passedETH, uint256 _orderPrice)
    internal
    view
  {
    // Establish upper and lower bands of price buffer and check
    uint256 orderPriceLower = (_orderPrice * priceBufferDown) / 1000;

    require(_passedETH >= orderPriceLower, "Insufficient ETH passed for order");

    uint256 orderPriceUpper = (_orderPrice * priceBufferUp) / 1000;

    require(_passedETH <= orderPriceUpper, "Too much ETH passed for order");
  }

  /**
   * @dev
   */
  function setRoyaltyPercentageBasisPoints(
    uint256 royaltyPercentageBasisPoints_
  ) external onlyOwner {
    royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
  }

  /**
   * @dev
   */
  function setRoyaltyReceipientAddress(
    address payable royaltyReceipientAddress_
  ) external onlyOwner {
    royaltyReceipientAddress = royaltyReceipientAddress_;
  }

  /**
   * @dev
   */
  function royaltyInfo(uint256, uint256 salePrice_)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    uint256 royalty = (salePrice_ * royaltyPercentageBasisPoints) / 10000;
    return (royaltyReceipientAddress, royalty);
  }

  /**
   * @dev
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155)
    returns (bool)
  {
    return
      interfaceId == _INTERFACE_ID_ERC2981 ||
      super.supportsInterface(interfaceId);
  }

  /**
   *  =======================================
   *  STANDARD FUNCTIONS
   *  =======================================
   */
  function uri(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    return publishedTitles[_tokenId].titleURI;
  }

  /**
   *
   * @dev withdrawContractBalance: onlyOwner withdrawal to the beneficiary address
   *
   */
  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiary.call{value: address(this).balance}("");
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev withdrawETH: onlyOwner withdrawal to the beneficiary address, sending
   * the amount to withdraw as an argument
   *
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = beneficiary.call{value: amount_}("");
    require(success, "Transfer failed");
  }

  /**
   * @dev The fallback function is executed on a call to the contract if
   * none of the other functions match the given function signature.
   */
  fallback() external payable {
    revert();
  }

  /**
   * @dev revert any random ETH:
   */
  receive() external payable {
    revert();
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}