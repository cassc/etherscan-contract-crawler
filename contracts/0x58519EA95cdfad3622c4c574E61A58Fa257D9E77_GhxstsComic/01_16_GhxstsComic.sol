// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   //
//  @@@@          @@@     @@@@     @@@    @@@@@                                    @    //
//  @@       //   @@@     @@@@     @@    @@@@          @@@@   @@@    @@/      @@@* @    //
//  @     @@@@@@@@@@@     @@@@     @@     @@@    .     @@@@@@@@@@    @@@@     @@@@@@    //
//  @    /@@@@@@@@@@@     @@@@     @@@/   /     @@@      @@@@@@@@    @@@@@      @@@@    //
//       @@@@@      @              @@@@       @@@@@@@      @@@@@@    @@@@@@*      @@    //
//       @@@@@@    @@     @@@@     @@@@      @@@@@@@@@@     [email protected]@@@    @@@@@@@@@     @    //
//  @     @@@@@    @@     @@@@     @@@        @@@@@@@@@@&    @@@@    @@@@@@@@@@         //
//  @      @@@@    @@     @@@@          @     @@@@@@@@@@@     @@@    @@@@@@@@@@@        //
//  @@(      /     @@     @@@@        @@@     @@@@% [email protected]@@     @@@@    @@@@  #@@@         //
//  @@@@@         @@@     @@@@       @@@@@    (@@@%        %@@@@     @@@@         @@    //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////

/* Created with love for the Pxin Gxng, by Rxmmy */

contract GhxstsComic is ERC721Enumerable, Ownable, ERC721Burnable {
  // Datapacking all chapter data.
  struct Chapter {
    string name;
    string image;
    string description;
    string metadataURI;
    bytes32 merkleRoot; // Merkle root for each chapter.
    bool active;
    bool frozen; // These chapters can no longer be minted or modified in any way.
    bool isSaleOpen; // Is the private sale open for a chapter.
    bool isPublicSaleOpen; // Is a public sale open for a chapter.
    uint256 price; // Max price: 10 ether or 10000000000000000000 wei
    uint256 discountPrice; // Max price: 10 ether or 10000000000000000000 wei
    uint256 supply; // Current supply for each chapter.
    uint256 maxSupply; // Max supply for each chapter.
    uint256 firstTokenId; // Starting tokenId for this chapter.
  }

  struct ChapterStrings {
    string name;
    string image;
    string metadataURI;
    string description;
    bytes32 merkleRoot;
  }

  // Chapter data by ID.
  mapping(uint256 => uint256) public _chapterDetails;
  mapping(uint256 => ChapterStrings) public _chapterStrings;

  mapping(uint256 => string) public _customTokenURIs;

  // Quantity of public mints claimed by wallet.
  // Address => Chapter => Quantity
  mapping(address => mapping(uint256 => uint256)) public minted;
  mapping(address => mapping(uint256 => uint256)) public allowListMinted;
  mapping(address => mapping(uint256 => uint256)) public discountMinted;
  mapping(address => mapping(uint256 => uint256)) public auctionMinted;

  // Max mint per wallet.
  uint256 public MAX_MINT = 4;

  uint256 public latestChapter;

  string public ghxstsWebsite = "https://ghxstscomics.com";

  uint256 public TOTAL_MINTED = 0;

  constructor() ERC721("Ghxsts Cxmics", "CXMIC") {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier chapterExists(uint256 chapterId) {
    require(_chapterDetails[chapterId] > 0, "Chapter does not exist.");
    _;
  }

  // Create datapacked values in the Chapter struct.
  function setChapter(Chapter memory chapter, uint256 chapterId) internal {
    uint256 supply = chapter.supply;
    uint256 maxSupply = chapter.maxSupply;
    uint256 price = chapter.price;
    uint256 discountPrice = chapter.discountPrice;
    uint256 firstTokenId = chapter.firstTokenId;

    require(supply < 65535, "MaxSupply exceeds uint16.");
    require(maxSupply < 65535, "MaxSupply exceeds uint16.");
    require(price < 2**64, "Price exceeds uint64.");
    require(discountPrice < 2**64, "DiscountPrice exceeds uint64.");
    require(firstTokenId < 2**64, "FirstToken exceeds uint64.");

    uint256 details = chapter.active ? uint256(1) : uint256(0);
    details |= (chapter.frozen ? uint256(1) : uint256(0)) << 8;
    details |= (chapter.isSaleOpen ? uint256(1) : uint256(0)) << 16;
    details |= (chapter.isPublicSaleOpen ? uint256(1) : uint256(0)) << 24;
    details |= supply << 32;
    details |= maxSupply << 48;
    details |= price << 64;
    details |= discountPrice << 128;
    details |= firstTokenId << 192;

    // Save the chapter data
    _chapterDetails[chapterId] = details;
  }

  // Retrieve datapacked values and build the Chapter struct.
  function getChapter(uint256 chapterId) public view returns (Chapter memory _chapter) {
    uint256 chapterDetails = _chapterDetails[chapterId];
    _chapter.active = uint8(uint256(chapterDetails)) == 1;
    _chapter.frozen = uint8(uint256(chapterDetails >> 8)) == 1;
    _chapter.isSaleOpen = uint8(uint256(chapterDetails >> 16)) == 1;
    _chapter.isPublicSaleOpen = uint8(uint256(chapterDetails >> 24)) == 1;
    _chapter.supply = uint256(uint16(chapterDetails >> 32));
    _chapter.maxSupply = uint256(uint16(chapterDetails >> 48));
    _chapter.price = uint256(uint64(chapterDetails >> 64));
    _chapter.discountPrice = uint256(uint64(chapterDetails >> 128));
    _chapter.firstTokenId = uint256(uint64(chapterDetails >> 192));

    // Get _chapterStrings
    ChapterStrings memory chapterString = _chapterStrings[chapterId];
    _chapter.name = chapterString.name;
    _chapter.image = chapterString.image;
    _chapter.description = chapterString.description;
    _chapter.metadataURI = chapterString.metadataURI;
    _chapter.merkleRoot = chapterString.merkleRoot;

    return _chapter;
  }

  function createChapter(
    uint256 chapterId,
    string calldata name,
    string calldata description,
    string calldata image,
    uint256 maxSupply,
    uint256 price,
    uint256 discountPrice
  ) external onlyOwner {
    require(_chapterDetails[chapterId] == 0, "Chapter already exists.");

    if (chapterId > 1) {
      Chapter memory prevChapter = getChapter(chapterId - 1);
      require(prevChapter.frozen, "Previous chapter still open.");
    }

    Chapter memory newChapter;
    newChapter.active = true;
    newChapter.price = price;
    newChapter.discountPrice = discountPrice;
    newChapter.maxSupply = maxSupply;
    newChapter.firstTokenId = TOTAL_MINTED;

    setChapter(newChapter, chapterId);

    _chapterStrings[chapterId].name = name;
    _chapterStrings[chapterId].image = image;
    _chapterStrings[chapterId].description = description;

    latestChapter = chapterId;
  }

  // Update the supply of a chapter.
  function updateSupply(uint256 chapterId, uint256 supply) internal {
    // Check supply size
    require(supply < 65535, "Supply exceeds uint16.");
    Chapter memory chapter = getChapter(chapterId);
    chapter.supply = chapter.supply + supply;
    setChapter(chapter, chapterId);
  }

  /**
   * @notice Set the max supply for a chapter.
   */
  function updateMaxSupply(uint256 chapterId, uint256 maxSupply) external chapterExists(chapterId) onlyOwner {
    require(maxSupply < 65535, "maxSupply exceeds uint16.");
    Chapter memory chapter = getChapter(chapterId);
    require(chapter.supply <= maxSupply, "Must be higher than the existing supply");

    chapter.maxSupply = maxSupply;
    setChapter(chapter, chapterId);
  }

  /**
   * @notice Set the price for a chapter.
   */
  function updatePrice(uint256 chapterId, uint256 price) external chapterExists(chapterId) onlyOwner {
    require(price < 2**64, "Price exceeds uint64.");
    Chapter memory chapter = getChapter(chapterId);
    chapter.price = price;
    setChapter(chapter, chapterId);
  }

  /**
   * @notice Set the discount price for a chapter.
   */
  function updateDiscountPrice(uint256 chapterId, uint256 discountPrice) external chapterExists(chapterId) onlyOwner {
    require(discountPrice < 2**64, "Price exceeds uint64.");
    Chapter memory chapter = getChapter(chapterId);
    chapter.discountPrice = discountPrice;
    setChapter(chapter, chapterId);
  }

  /**
   * @notice Toggle the allowList sale on / off.
   */
  function togglePrivateSale(uint256 chapterId) external chapterExists(chapterId) onlyOwner {
    Chapter memory chapter = getChapter(chapterId);
    require(!chapter.frozen, "Chapter frozen.");
    chapter.isSaleOpen = chapter.isSaleOpen ? false : true;
    setChapter(chapter, chapterId);
  }

  /**
   * @notice Toggle the public sale on / off.
   */
  function togglePublicSale(uint256 chapterId) external chapterExists(chapterId) onlyOwner {
    Chapter memory chapter = getChapter(chapterId);
    require(!chapter.frozen, "Chapter frozen.");
    require(chapter.maxSupply > 0, "Max supply not set");
    require(chapter.price > 0, "Price not set");
    chapter.isPublicSaleOpen = chapter.isPublicSaleOpen ? false : true;
    setChapter(chapter, chapterId);
  }

  /**
   * @notice Freeze a chapter forever. Irreversible.
   */
  function freezeChapterPermanently(uint256 chapterId) external chapterExists(chapterId) onlyOwner {
    Chapter memory chapter = getChapter(chapterId);
    chapter.frozen = true; // Salute.gif
    setChapter(chapter, chapterId);
  }

  /**
   * @notice Update the name of a chapter.
   */
  function updateChapterName(uint256 chapterId, string calldata name) external chapterExists(chapterId) onlyOwner {
    Chapter memory chapter = getChapter(chapterId);
    require(!chapter.frozen, "Chapter is frozen");
    _chapterStrings[chapterId].name = name;
  }

  /**
   * @notice Update the image URL of a chapter.
   */
  function updateChapterImage(uint256 chapterId, string calldata image) external chapterExists(chapterId) onlyOwner {
    Chapter memory chapter = getChapter(chapterId);
    require(!chapter.frozen, "Chapter is frozen");
    _chapterStrings[chapterId].image = image;
  }

  /**
   * @notice Update the metadata URL of a chapter.
   */
  function updateChapterMetadataUri(uint256 chapterId, string calldata uri)
    external
    chapterExists(chapterId)
    onlyOwner
  {
    Chapter memory chapter = getChapter(chapterId);
    require(!chapter.frozen, "Chapter is frozen");
    _chapterStrings[chapterId].metadataURI = uri;
  }

  /**
   * @notice Update the metadata URL of a single token.
   */
  function updateTokenMetadataUri(uint256 tokenId, string calldata uri) external onlyOwner {
    require(_exists(tokenId), "Token does not exist.");
    Chapter memory chapter = findChapter(tokenId);
    require(!chapter.frozen, "Chapter is frozen");
    _customTokenURIs[tokenId] = uri;
  }

  /**
   * @notice Update the description of a chapter.
   */
  function updateChapterDescription(uint256 chapterId, string calldata description)
    external
    chapterExists(chapterId)
    onlyOwner
  {
    Chapter memory chapter = getChapter(chapterId);
    require(!chapter.frozen, "Chapter is frozen");
    _chapterStrings[chapterId].description = description;
  }

  /**
   * @notice Set the merkle root for a chapter.
   */
  function updateMerkleRoot(uint256 chapterId, bytes32 merkleRoot) external chapterExists(chapterId) onlyOwner {
    // chapterMerkle[chapterId] = merkleRoot;
    _chapterStrings[chapterId].merkleRoot = merkleRoot;
  }

  /**
   * @notice Mint for owner.
   */
  function ownerMint(uint256 quantity, uint256 chapterId) external chapterExists(chapterId) onlyOwner {
    Chapter memory chapter = getChapter(chapterId);
    require(!chapter.frozen, "Chapter frozen.");
    require((chapter.supply + quantity) <= chapter.maxSupply, "Exceeds chapter maximum supply.");

    // Update the supply of this chapter.
    updateSupply(chapterId, quantity);

    for (uint256 i = 0; i < quantity; i++) {
      // Mint it.
      _safeMint(msg.sender, TOTAL_MINTED);
      TOTAL_MINTED++;
    }
  }

  /**
   * @notice Mint tokens.
   */
  function mint(uint256 quantity, uint256 chapterId) external payable chapterExists(chapterId) callerIsUser {
    Chapter memory chapter = getChapter(chapterId);
    require(!chapter.frozen, "Chapter frozen.");
    require(chapter.isPublicSaleOpen, "Public sale not open");
    require(msg.value == (chapter.price * quantity), "Payment incorrect");
    require((chapter.supply + quantity) <= chapter.maxSupply, "Max purchase supply exceeded");
    require((minted[msg.sender][chapterId] + quantity) <= MAX_MINT, "Quantity exceeded");

    minted[msg.sender][chapterId] = minted[msg.sender][chapterId] + quantity;
    updateSupply(chapterId, quantity);

    for (uint256 i; i < quantity; i++) {
      _safeMint(msg.sender, TOTAL_MINTED);
      TOTAL_MINTED++;
    }
  }

  /**
   * @notice Mint tokens.
   */
  function allowListMint(
    uint256 chapterId,
    uint256 amount,
    uint256 discountAmount,
    uint256 ticket,
    uint256 maxQty,
    uint256 maxDiscountQty,
    bytes32[] calldata merkleProof
  ) external payable chapterExists(chapterId) callerIsUser {
    Chapter memory chapter = getChapter(chapterId);
    require(chapter.isSaleOpen, "Sale not open");
    require((chapter.supply + amount + discountAmount) <= chapter.maxSupply, "Max purchase supply exceeded");
    require((allowListMinted[msg.sender][chapterId] + amount) <= maxQty, "Amount exceeded.");
    require((discountMinted[msg.sender][chapterId] + discountAmount) <= maxDiscountQty, "Discount amount exceeded.");
    require(msg.value == (chapter.price * amount) + (chapter.discountPrice * discountAmount), "Payment incorrect");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, ticket, maxQty, maxDiscountQty));
    require(MerkleProof.verify(merkleProof, chapter.merkleRoot, leaf), "Invalid proof.");

    allowListMinted[msg.sender][chapterId] = allowListMinted[msg.sender][chapterId] + amount;
    discountMinted[msg.sender][chapterId] = discountMinted[msg.sender][chapterId] + discountAmount;

    // Update the supply of this chapter.
    updateSupply(chapterId, amount + discountAmount);

    for (uint256 i; i < amount + discountAmount; i++) {
      _safeMint(msg.sender, TOTAL_MINTED);
      TOTAL_MINTED++;
    }
  }

  // ** - ADMIN - ** //
  function withdrawEther(address payable _to, uint256 _amount) external onlyOwner {
    _to.transfer(_amount);
  }

  /**
   * @notice Set the maximum number of mints per wallet.
   */
  function setMAX_MINT(uint256 max) external onlyOwner {
    MAX_MINT = max;
  }

  /**
   * @notice Updated the web URL.
   */
  function setWebsite(string calldata url) external onlyOwner {
    ghxstsWebsite = url;
  }

  /**
   * @notice Find which chapter this token belongs to.
   */
  function findChapter(uint256 tokenId) public view returns (Chapter memory chapter) {
    for (uint256 i = 1; i <= latestChapter; i++) {
      chapter = getChapter(i);
      if (chapter.firstTokenId <= tokenId && chapter.firstTokenId + chapter.maxSupply > tokenId) {
        return chapter;
      }
    }
  }

  // ** - MISC - ** //
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
    Chapter memory chapter = findChapter(tokenId);
    uint256 chapterStart = chapter.firstTokenId;
    uint256 edition = tokenId - chapterStart;
    string memory editionNumber = Strings.toString(edition);
    string memory chapterUri = chapter.metadataURI;
    string memory tokenUri = _customTokenURIs[tokenId];

    // Check for token specific metadata
    if (bytes(tokenUri).length > 0) {
      return tokenUri;
    }
    // Check for chapter override metadata
    if (bytes(chapterUri).length > 0) {
      return chapterUri;
    }

    // Build default metadata.
    // Prepend any zeroes for edition numbers. Purely aesthetic.
    if (edition == 0) {
      editionNumber = "0";
    } else if (edition < 10) {
      editionNumber = string(abi.encodePacked("00", editionNumber));
    } else if (edition < 100) {
      editionNumber = string(abi.encodePacked("0", editionNumber));
    }

    // Default metadata
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            chapter.name,
            " - #",
            editionNumber,
            '", "description": "',
            chapter.description,
            '", "image": "',
            chapter.image,
            '", "external_url": "',
            ghxstsWebsite,
            '", "attributes": [{"trait_type": "Chapter","value": "',
            chapter.name,
            '"},{"trait_type": "Edition","value": "#',
            editionNumber,
            '"}]}'
          )
        )
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  mapping(uint256 => uint256) public chapterAuctionSupply;
  mapping(uint256 => uint256) public chapterAuctionMinted;
  mapping(uint256 => uint32) public chapterAuctionStartTime;
  mapping(uint256 => uint256) public chapterAuctionStartPrice;
  mapping(uint256 => uint256) public chapterAuctionEndPrice;
  mapping(uint256 => uint256) public chapterAuctionPriceCurveLength;
  mapping(uint256 => uint256) public chapterAuctionDropInterval;
  mapping(uint256 => uint256) public chapterAuctionDropPerStep;

  function auctionMint(uint256 chapterId, uint256 amount) external payable chapterExists(chapterId) callerIsUser {
    uint256 _saleStartTime = chapterAuctionStartTime[chapterId];
    require(_saleStartTime != 0 && block.timestamp >= _saleStartTime, "Sale has not started yet");
    require(
      chapterAuctionMinted[chapterId] + amount <= chapterAuctionSupply[chapterId],
      "Max auction supply exceeded."
    );
    Chapter memory chapter = getChapter(chapterId);
    require((chapter.supply + amount) <= chapter.maxSupply, "Max purchase supply exceeded");
    require(auctionMinted[msg.sender][chapterId] + amount <= MAX_MINT, "Max mint qty exceeded");
    uint256 totalCost = getAuctionPrice(chapterId, _saleStartTime) * amount;
    auctionMinted[msg.sender][chapterId] = auctionMinted[msg.sender][chapterId] + amount;

    // Update the supply of this chapter.
    updateSupply(chapterId, amount);

    for (uint256 i; i < amount; i++) {
      _safeMint(msg.sender, TOTAL_MINTED);
      TOTAL_MINTED++;
    }
    refundIfOver(totalCost);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  // getAuctionPrice
  function getAuctionPrice(uint256 chapterId, uint256 _saleStartTime)
    public
    view
    chapterExists(chapterId)
    returns (uint256)
  {
    if (block.timestamp < _saleStartTime) {
      return chapterAuctionStartPrice[chapterId];
    }
    if (block.timestamp - _saleStartTime >= chapterAuctionPriceCurveLength[chapterId]) {
      return chapterAuctionEndPrice[chapterId];
    } else {
      uint256 steps = (block.timestamp - _saleStartTime) / chapterAuctionDropInterval[chapterId];
      return chapterAuctionStartPrice[chapterId] - (steps * chapterAuctionDropPerStep[chapterId]);
    }
  }

  function createChapterAuction(
    uint256 chapterId,
    uint256 auctionSupply,
    uint32 startTime,
    uint256 startPrice,
    uint256 endPrice,
    uint256 priceCurveLength,
    uint256 dropInterval
  ) external chapterExists(chapterId) onlyOwner {
    chapterAuctionSupply[chapterId] = auctionSupply;
    chapterAuctionStartTime[chapterId] = startTime;
    chapterAuctionStartPrice[chapterId] = startPrice;
    chapterAuctionEndPrice[chapterId] = endPrice;
    chapterAuctionPriceCurveLength[chapterId] = priceCurveLength;
    chapterAuctionDropInterval[chapterId] = dropInterval;
    chapterAuctionDropPerStep[chapterId] = (startPrice - endPrice) / (priceCurveLength / dropInterval);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function getMintedQty(
    uint256 chapterId,
    address addr,
    uint256 mintType // 1: Minted, 2: allowListMinted, 3: discountMinted, 4: auctionMinted
  ) external view chapterExists(chapterId) returns (uint256) {
    if (mintType == 1) {
      return minted[addr][chapterId];
    } else if (mintType == 2) {
      return allowListMinted[addr][chapterId];
    } else if (mintType == 3) {
      return discountMinted[addr][chapterId];
    } else {
      return auctionMinted[addr][chapterId];
    }
  }
}