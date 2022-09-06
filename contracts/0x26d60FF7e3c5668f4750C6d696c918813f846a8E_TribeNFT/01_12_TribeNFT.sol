//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TribeNFT is ERC721, IERC721Receiver, IERC2981, Ownable {
  using Strings for uint256;
  using Address for address;

  event MintedTribe(
    address indexed to,
    string name,
    uint256 tokenId
  );

  event BatchMintedTribe(
    address indexed to,
    string name,
    uint256 quantity,
    uint256[] tokenIds
  );

  event TradeInLootBox(
    address indexed from,
    uint256 lootboxTokenId
  );

  struct TribeToken {
    uint8   tribeIndex;
    uint256 tribeId;
  }

  struct Tribe {
    string  name;
    uint256 supply;
    string  baseURI;
    bool    isUnlocked;
    bool    isTradeable;
  }

  // Receiver of all mint revenue (payment splitter)
  address payable private immutable _receiver;

  IERC721 private LOOTBOX = IERC721(0xB3246C9BD4EF9D9178F87B80fE488104440c3Bd6);

  // Each tokenId will have a corresponding TribeToken and tribeId
  mapping(uint256 => TribeToken) internal _tribeTokens;

  mapping(uint8 => Tribe) internal _tribes;

  uint256 internal immutable _numOfTribes;

  uint256 public constant maxSupplyPerTribe = 1111;

  uint256 public constant mintPrice = 0.1 ether;

  uint256 public totalSupply;


  constructor(address payable receiver_, address owner_, string[] memory tribeNames_) ERC721("Galaxii Online Tribes", "GOT") {
    require(receiver_ != address(0), "TribeNFT: receiver_ cannot be null address");
    require(owner_ != address(0), "TribeNFT: owner_ cannot be null address");

    _receiver = receiver_;

    for(uint8 i=0; i < tribeNames_.length; i++) {
      require(bytes(tribeNames_[i]).length > 0, "TribeNFT: tribe name is empty string");
      _tribes[i] = Tribe(tribeNames_[i], 0, "", false, false);
    }

    _numOfTribes = tribeNames_.length;

    transferOwnership(owner_);
  }

  modifier isTribe(uint8 index) {
		require(index < _numOfTribes, "TribeNFT: no tribe exists at index");
    _;
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
      return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Mint token via msg.value payment
   */
  function mint(uint8 index) payable public isTribe(index) {
    require(_tribes[index].isUnlocked, "TribeNFT: tribe is locked and cannot pay to mint");
    require(msg.value >= mintPrice, "TribeNFT: msg.value is below 0.1 ETH");

		string memory tribeName = _tribes[index].name;

    uint256 tokenId = totalSupply;
    uint256 tribeId = _tribes[index].supply + 1;

    require(_tribes[index].supply < maxSupplyPerTribe, "TribeNFT: each tribe cannot exceed 1111 max supply");

    TribeToken memory token = TribeToken(index, tribeId);
    
    Address.sendValue(_receiver, msg.value);

    _tribeTokens[tokenId] = token;
    _tribes[index].supply++;
    totalSupply++;

    _safeMint(msg.sender, tokenId);
    emit MintedTribe(msg.sender, tribeName, tokenId);
  }

  /**
   * @dev Mint token via trading in a Loot Box token
   */
  function mint(uint8 index, uint256 lootBoxId) public isTribe(index) {
    require(_tribes[index].isTradeable, "TribeNFT: tribe is not mintable for trade-in");
    require(LOOTBOX.ownerOf(lootBoxId) == msg.sender, "TribeNFT: must be lootbox owner to trade in for mint");
    require(
			LOOTBOX.getApproved(lootBoxId) == address(this) || LOOTBOX.isApprovedForAll(msg.sender, address(this)), 
			"TribeNFT: not approved to trade in lootbox token"
		);

		string memory tribeName = _tribes[index].name;
		
    uint256 tokenId = totalSupply;
    uint256 tribeId = _tribes[index].supply + 1;

    require(_tribes[index].supply < maxSupplyPerTribe, "TribeNFT: each tribe cannot exceed 1111 max supply");

    TribeToken memory token = TribeToken(index, tribeId);
    
    LOOTBOX.safeTransferFrom(msg.sender, address(this), lootBoxId);
    emit TradeInLootBox(msg.sender, lootBoxId);

    _tribeTokens[tokenId] = token;
    _tribes[index].supply++;
    totalSupply++;

    _safeMint(msg.sender, tokenId);
    emit MintedTribe(msg.sender, tribeName, tokenId);
  }

  /**
   * @dev Mint token via msg.value payment
   */
  function mintBatch(uint8 index, uint256 quantity) payable public isTribe(index) {
    require(_tribes[index].isUnlocked, "TribeNFT: tribe is locked and cannot pay to mint");
    require(quantity <= 5, "TribeNFT: only mint up to 5 tokens at a time");
    
    uint256 payment = mintPrice * quantity;
    require(msg.value >= payment, "TribeNFT: msg.value is below amount owed");

    uint256 newSupply = _tribes[index].supply + quantity;
    require(newSupply < maxSupplyPerTribe, "TribeNFT: each tribe cannot exceed 1111 max supply");

    Address.sendValue(_receiver, msg.value);
		_mintBatch(msg.sender, index, quantity);
  }

  /**
   * @dev Mint token via msg.value payment
   */
  function mintBatchAsOwner(address to, uint8 index, uint256 quantity) payable public onlyOwner isTribe(index) {
    require(
      bytes(_tribes[index].baseURI).length > 0, 
      "TribeNFT: tribe has no baseURI"
    );
    require(quantity <= 100, "TribeNFT: quantity limit of 100 tokens per mint");

    uint256 newSupply = _tribes[index].supply + quantity;
    require(newSupply < maxSupplyPerTribe, "TribeNFT: each tribe cannot exceed 1111 max supply");

    if (msg.value >= 0) {
      Address.sendValue(_receiver, msg.value);
    }
    _mintBatch(to, index, quantity);
  }

  /**
  * @dev See {IERC721Metadata-tokenURI}.
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    (uint8 index, uint256 tribeId) = _tribeOf(tokenId);

    string memory baseURI = _tribes[index].baseURI;
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tribeId.toString(), ".json")) : "";
  }

  function tribeOf(uint256 tokenId) external view returns (uint8 index, uint256 tribeId) {
    (index, tribeId) = _tribeOf(tokenId);
  }

  function setTradeable(uint8 index) external onlyOwner isTribe(index) {
    string memory baseURI = _tribes[index].baseURI;
    require(bytes(baseURI).length > 0, "TribeNFT: no baseURI exists for tribe");

    _tribes[index].isTradeable = true;
  }

  function unlockTribe(uint8 index) external onlyOwner isTribe(index) {
    string memory baseURI = _tribes[index].baseURI;
    require(bytes(baseURI).length > 0, "TribeNFT: no baseURI exists for tribe");

    if (!_tribes[index].isTradeable) {
      _tribes[index].isTradeable = true;
    }

    _tribes[index].isUnlocked = true;
  }

  function setTokenURI(uint8 index, string memory tribeURI) external onlyOwner {
    _tribes[index].baseURI = tribeURI;
  }

  function getAllTribes() public view returns (Tribe[] memory) {
    Tribe[] memory tribes = new Tribe[](_numOfTribes);
    for(uint8 i=0; i < _numOfTribes; i++) {
      tribes[i] = _tribes[i];
    }
    return tribes;
  }

  function getReceiver() public view returns (address) {
    return _receiver;
  }

  /**
    * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
    * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
    */
  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    receiver = getReceiver();
    royaltyAmount = (salePrice * 750) / 10000;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external override pure returns(bytes4) {
    return this.onERC721Received.selector;
  }

  function _tribeOf(uint256 tokenId) internal view returns (uint8, uint256) {
    TribeToken memory token = _tribeTokens[tokenId];
    return (token.tribeIndex, token.tribeId);
  }

  function _mintBatch(address to, uint8 index, uint256 quantity) private {
    string memory tribeName = _tribes[index].name;
    uint256 tokenId = totalSupply;
    uint256 tribeId = _tribes[index].supply + 1;
    uint256[] memory ids = new uint256[](quantity);

    for(uint256 i=0; i < quantity; i++) {
      TribeToken memory token = TribeToken(index, tribeId);
      ids[i] = tokenId;

      _tribeTokens[tokenId] = token;
      _tribes[index].supply++;
      
      _safeMint(to, tokenId);
      
      tokenId += 1;
      tribeId += 1;
    }

    totalSupply += quantity;

    emit BatchMintedTribe(to, tribeName, quantity, ids);
  }
}