// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {Util} from "./Util.sol";

interface IADiscSystem {
  function tokenIdToAttributes(uint256 tokenId)
    external
    view
    returns (
      bytes32,
      string memory,
      string memory,
      string memory,
      string memory,
      uint256,
      uint256,
      uint256,
      uint256,
      bool
    );

  function ownerOf(uint256 tokenId) external view returns (address);

  function mint(uint256 quantity) external payable;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function mintedTokenIdList() external view returns (uint256[] memory);
}

contract ConnectedWindows is
  ERC721,
  IERC721Receiver,
  ReentrancyGuard,
  Ownable,
  Util,
  DefaultOperatorFilterer
{
  uint256 public constant DISC_PRICE = 0.02 ether;

  struct Attribute {
    bytes32 hash;
    string palette;
    string image;
    string message;
    string shape;
    uint256 speed;
    uint256 size;
    uint256 weight;
    uint256 offset;
    bool dynamic;
  }

  IADiscSystem public discSystem;

  bool public isOnSale;
  bool public isMetadataFrozen;
  mapping(uint256 => uint256) public tokenIdToDiscTokenId;
  mapping(uint256 => Attribute) public tokenIdToAttribute;
  mapping(uint256 => bool) public usedDiscTokenId;
  uint256 public completeCycleInSec = 60;
  uint256 public breakInSec = 2;
  uint256[] private _mintedTokenIdList;

  string private _baseThumbnailURI;
  string private _artCodeURI;
  uint256 private EMPTY_DISC_TOKEN_ID = 9999;

  constructor(
    string memory baseThumbnailURI,
    string memory artCodeURI,
    address discSystemAddress
  ) ERC721("Connected Windows", "CW") {
    _baseThumbnailURI = baseThumbnailURI;
    _artCodeURI = artCodeURI;
    discSystem = IADiscSystem(discSystemAddress);
  }

  function mintedTokenIdList() external view returns (uint256[] memory) {
    return _mintedTokenIdList;
  }

  function totalCount() public view returns (uint256) {
    return _mintedTokenIdList.length;
  }

  function mint(uint256 discTokenId) external {
    require(isOnSale, "Connected Windows: Not on sale");
    require(
      usedDiscTokenId[discTokenId] == false,
      "Connected Windows: The disc token ID is already used"
    );
    _mintAndTransfer(_msgSender(), discTokenId);
  }

  function mintTokenAndDisc() external payable nonReentrant {
    require(isOnSale, "Connected Windows: Not on sale");
    require(msg.value == DISC_PRICE, "Connected Windows: Invalid value");

    discSystem.mint{value: DISC_PRICE}(1);
    uint256 discTokenId = discSystem.mintedTokenIdList().length - 1;
    require(
      address(this) == discSystem.ownerOf(discTokenId),
      "Connected Windows: Not owner"
    );
    // Transfer the token from contract address to the user
    discSystem.safeTransferFrom(address(this), _msgSender(), discTokenId);
    _mintAndTransfer(_msgSender(), discTokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "not exists");
    string memory tokenIdStr = Strings.toString(tokenId);
    uint256 discTokenId = tokenIdToDiscTokenId[tokenId];
    Attribute memory attrs;
    if (discTokenId == EMPTY_DISC_TOKEN_ID) {
      attrs = tokenIdToAttribute[tokenId];
    } else {
      attrs = _getAttribute(discTokenId);
    }

    string memory image = string(
      bytes.concat(
        bytes(_baseThumbnailURI),
        bytes(Strings.toString(tokenId)),
        bytes(".png")
      )
    );
    string memory animationUrlObj = _getAnimationUrl(tokenId, attrs);

    return
      string.concat(
        "data:application/json;base64,",
        Base64.encode(
          abi.encodePacked(
            '{"name":"Connected Windows #',
            tokenIdStr,
            '","description":"',
            "Artist: NIINOMI\\n\\nConnected Windows is an artwork that explores the theme of connections formed through a collection of NFTs, with the motif being computer user interfaces called windows. Within this collection, there exist digital creatures called ANIMA, which traverse between the windows of NFTs generated within the collection. As the number of owners in the collection increases, the time ANIMA stays in one window becomes shorter, leaving only the windows on the screen. While computer windows serve as interfaces for displaying information, in Connected Windows, they also serve as a space for ANIMA to visit. Owning one edition in the NFT collection signifies the formation of a loose connection with other owners. Becoming an owner of this collection means becoming a member who shares ANIMA, and the visitation of ANIMA to the window is a testament to the formation of these subtle connections.",
            '","image":"',
            image,
            '","animation_url":"',
            animationUrlObj,
            '","discTokenId":',
            Strings.toString(discTokenId),
            ",",
            _attributesText(attrs),
            "}"
          )
        )
      );
  }

  function setDisc(uint256 tokenId, uint256 discTokenId) external {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "Connected Windows: caller is not token owner"
    );
    require(
      _msgSender() == discSystem.ownerOf(discTokenId),
      "Connected Windows: Not owner"
    );
    tokenIdToDiscTokenId[tokenId] = discTokenId;
  }

  function setIsOnSale(bool _isOnSale) external onlyOwner {
    isOnSale = _isOnSale;
  }

  function setIsMetadataFrozen(bool _isMetadataFrozen) external onlyOwner {
    require(
      !isMetadataFrozen,
      "Connected Windows: isMetadataFrozen cannot be changed"
    );
    isMetadataFrozen = _isMetadataFrozen;
  }

  function setBaseThumbnailURI(string memory baseThumbnailURI)
    external
    onlyOwner
  {
    require(!isMetadataFrozen, "Connected Windows: Metadata is already frozen");
    _baseThumbnailURI = baseThumbnailURI;
  }

  function setArtCodeURI(string memory artCodeURI) external onlyOwner {
    require(!isMetadataFrozen, "Connected Windows: Metadata is already frozen");
    _artCodeURI = artCodeURI;
  }

  function setCompleteCycleInSec(uint256 _completeCycleInSec)
    external
    onlyOwner
  {
    completeCycleInSec = _completeCycleInSec;
  }

  function setBreakInSec(uint256 _breakInSec) external onlyOwner {
    breakInSec = _breakInSec;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function _mintAndTransfer(address to, uint256 discTokenId) internal {
    uint256 nextTokenId = _mintedTokenIdList.length + 1;
    require(
      to == discSystem.ownerOf(discTokenId),
      "Connected Windows: Not owner"
    );
    usedDiscTokenId[discTokenId] = true;

    tokenIdToDiscTokenId[nextTokenId] = discTokenId;

    _mintedTokenIdList.push(nextTokenId);
    _safeMint(to, nextTokenId);
  }

  function _getAttribute(uint256 discTokenId)
    internal
    view
    returns (Attribute memory)
  {
    (
      bytes32 hash,
      string memory palette,
      string memory image,
      string memory message,
      string memory shape,
      uint256 speed,
      uint256 size,
      uint256 weight,
      uint256 offset,
      bool dynamic
    ) = discSystem.tokenIdToAttributes(discTokenId);
    return
      Attribute(
        hash,
        palette,
        image,
        message,
        shape,
        speed,
        size,
        weight,
        offset,
        dynamic
      );
  }

  function _getAnimationUrl(uint256 tokenId, Attribute memory attrs)
    internal
    view
    returns (string memory)
  {
    string memory attrObj = _getAttrObj(attrs);
    uint256 _totalCount = totalCount();
    string memory htmlData = string.concat(
      "<html>",
      "<head>",
      '<meta name="viewport" width="device-width," initial-scale="1.0," maximum-scale="1.0," user-scalable="0" />',
      "<style> body { margin: 0; } .artCanvas { width: 100%;height: 100%;position: fixed;overflow: hidden;display: flex;justify-content: center;align-items: center;</style>",
      "\n<script>\n",
      _embedVariable("attributes", attrObj),
      _embedVariable("id", Strings.toString(tokenId)),
      _embedVariable("totalNum", Strings.toString(_totalCount)),
      _embedVariable(
        "completeCycleInSec",
        Strings.toString(completeCycleInSec)
      ),
      _embedVariable("breakInSec", Strings.toString(breakInSec)),
      "\n</script>\n",
      "</head>",
      "<body>",
      '<canvas id="canvas" class="artCanvas"></canvas><canvas id="canvas2" class="artCanvas"></canvas>',
      _embedScript(_artCodeURI),
      "</body>",
      "</html>"
    );
    return
      string.concat(
        "data:text/html;charset=UTF-8;base64,",
        Base64.encode(bytes(htmlData))
      );
  }

  function _getAttrObj(Attribute memory attrs)
    internal
    pure
    returns (string memory)
  {
    string memory hash = string.concat("0x", bytes32ToHexString(attrs.hash));
    string memory json1 = string(
      abi.encodePacked(
        "{",
        '"hash":"',
        hash,
        '","palette":"',
        attrs.palette,
        '","image":"',
        attrs.image,
        '","message":"',
        attrs.message,
        '","shape":"',
        attrs.shape,
        '","speed":',
        Strings.toString(attrs.speed)
      )
    );

    string memory json2 = string(
      abi.encodePacked(
        ',"size":',
        Strings.toString(attrs.size),
        ',"weight":',
        Strings.toString(attrs.weight),
        ',"offset":',
        Strings.toString(attrs.offset),
        ',"dynamic":',
        attrs.dynamic ? "true" : "false",
        "}"
      )
    );

    return string(abi.encodePacked(json1, json2));
  }

  function _embedVariable(string memory name, string memory value)
    private
    pure
    returns (string memory)
  {
    return string.concat(name, " = ", value, ";\n");
  }

  function _embedScript(string memory src)
    private
    pure
    returns (string memory)
  {
    return string.concat('<script src="', src, '"></script>');
  }

  function _attributesText(Attribute memory attrs)
    internal
    pure
    returns (string memory)
  {
    return
      string.concat(
        '"attributes":[{"trait_type":"palette","value":"',
        attrs.palette,
        '"},{"trait_type":"image","value":"',
        attrs.image,
        '"},{"trait_type":"message","value":"',
        attrs.message,
        '"},{"trait_type":"shape","value":"',
        attrs.shape,
        '"},{"trait_type":"speed","value":',
        Strings.toString(attrs.speed),
        '},{"trait_type":"size","value":',
        Strings.toString(attrs.size),
        '},{"trait_type":"weight","value":',
        Strings.toString(attrs.weight),
        '},{"trait_type":"offset","value":',
        Strings.toString(attrs.offset),
        '},{"trait_type":"dynamic","value":"',
        attrs.dynamic ? "true" : "false",
        '"}]'
      );
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
    if (from != address(0)) {
      uint256 discTokenId = tokenIdToDiscTokenId[tokenId];
      if (discTokenId != EMPTY_DISC_TOKEN_ID) {
        tokenIdToDiscTokenId[tokenId] = EMPTY_DISC_TOKEN_ID;
        Attribute memory attribute = _getAttribute(discTokenId);
        tokenIdToAttribute[tokenId] = attribute;
      }
    }
  }

  /**
   * Operator Filter Registry
   */
  function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}