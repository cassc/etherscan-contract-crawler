// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IDataChunkCompiler {
  function BEGIN_JSON() external view returns (string memory);

  function END_JSON() external view returns (string memory);

  function HTML_HEAD() external view returns (string memory);

  function BEGIN_SCRIPT() external view returns (string memory);

  function END_SCRIPT() external view returns (string memory);

  function BEGIN_SCRIPT_DATA() external view returns (string memory);

  function END_SCRIPT_DATA() external view returns (string memory);

  function SCRIPT_VAR(
    string memory name,
    string memory value,
    bool omitQuotes
  ) external pure returns (string memory);

  function BEGIN_METADATA_VAR(string memory name, bool omitQuotes)
    external
    pure
    returns (string memory);

  function END_METADATA_VAR(bool omitQuotes)
    external
    pure
    returns (string memory);
}

contract Reincarnation is
  ERC721,
  EIP712,
  ReentrancyGuard,
  Ownable,
  DefaultOperatorFilterer
{
  using ECDSA for bytes32;

  uint256 public constant MAX_SUPPLY = 666;
  uint256 public constant PRICE = 0.03 ether;

  IDataChunkCompiler private compiler;

  struct Attribute {
    uint256 tokenId;
    string name;
    uint256 gender;
    uint256 height;
    uint256 weight;
    string bloodType;
    string hometown;
    uint256 character;
    uint256 inheritedChildId;
    string madeFrom;
  }

  bytes32 private constant _TYPEHASH =
    keccak256(
      "Attribute(uint256 tokenId,string name,uint256 gender,uint256 height,uint256 weight,string bloodType,string hometown,uint256 character,uint256 inheritedChildId,string madeFrom)"
    );

  bool public isOnSale;
  bool public isMetadataFrozen;
  mapping(uint256 => Attribute) public tokenIdToAttributes;
  uint256[] private _mintedTokenIdList;

  string private _baseThumbnailURI;
  string private _artCodeURI;
  address private _verifyAddress;

  constructor(
    string memory baseThumbnailURI,
    string memory artCodeURI,
    address compilerAddress,
    address verifyAddress
  ) ERC721("Reincarnation", "REINC") EIP712("Reincarnation", "1.0.0") {
    _baseThumbnailURI = baseThumbnailURI;
    _artCodeURI = artCodeURI;
    _verifyAddress = verifyAddress;
    compiler = IDataChunkCompiler(compilerAddress);
  }

  function verifyParams(Attribute calldata params, bytes calldata signature)
    public
    view
    returns (bool)
  {
    bytes memory b = abi.encode(
      _TYPEHASH,
      params.tokenId,
      keccak256(bytes(params.name)),
      params.gender,
      params.height,
      params.weight,
      keccak256(bytes(params.bloodType)),
      keccak256(bytes(params.hometown)),
      params.character,
      params.inheritedChildId,
      keccak256(bytes(params.madeFrom))
    );
    address signer = _hashTypedDataV4(keccak256(b)).recover(signature);
    return signer == _verifyAddress;
  }

  function mintedTokenIdList() external view returns (uint256[] memory) {
    return _mintedTokenIdList;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory tokenIdStr = Strings.toString(tokenId);

    Attribute memory attribute = tokenIdToAttributes[tokenId];

    string memory attributeObj1 = string.concat(
      string.concat(
        _beginAttributeData("tokenId", true),
        Strings.toString(tokenId),
        _endAttributeData(true)
      ),
      string.concat(
        _beginAttributeData("name", false),
        attribute.name,
        _endAttributeData(false)
      ),
      string.concat(
        _beginAttributeData("gender", true),
        Strings.toString(attribute.gender),
        _endAttributeData(true)
      ),
      string.concat(
        _beginAttributeData("height", true),
        Strings.toString(attribute.height),
        _endAttributeData(true)
      )
    );
    string memory attributeObj2 = string.concat(
      string.concat(
        _beginAttributeData("weight", true),
        Strings.toString(attribute.weight),
        _endAttributeData(true)
      ),
      string.concat(
        _beginAttributeData("bloodType", false),
        attribute.bloodType,
        _endAttributeData(false)
      ),
      string.concat(
        _beginAttributeData("hometown", false),
        attribute.hometown,
        _endAttributeData(false)
      ),
      string.concat(
        _beginAttributeData("character", true),
        Strings.toString(attribute.character),
        _endAttributeData(true)
      ),
      string.concat(
        _beginAttributeData("inheritedChildId", true),
        Strings.toString(attribute.inheritedChildId),
        _endAttributeData(true)
      ),
      string.concat(
        _beginAttributeData("madeFrom", false),
        attribute.madeFrom,
        "%2522"
      )
    );

    string memory attributeObj = string(
      abi.encodePacked("%257B", attributeObj1, attributeObj2, "%257D") // {}
    );

    string
      memory metaTag = "%253Cmeta%2520name%253D%2522viewport%2522%2520content%253D%2522width%253Ddevice-width%252C%2520initial-scale%253D1%2522%252F%253E";
    string
      memory styleTag = "%253Cstyle%2520type%253D%2522text%252Fcss%2522%253E%250A%2520%2520%2520%2520%2520%2520%2520%2520body%2520%257B%250A%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520margin%253A%25200%253B%250A%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520overflow%253A%2520hidden%253B%250A%2520%2520%2520%2520%2520%2520%2520%2520%257D%250A%253C%252Fstyle%253E";
    string memory htmlCode = "%253Cbody%253E%253C%252Fbody%253E";

    string memory uri = string.concat(
      compiler.BEGIN_JSON(),
      string.concat(
        // name
        string.concat(
          compiler.BEGIN_METADATA_VAR("name", false),
          "Reincarnation%20%23",
          tokenIdStr,
          compiler.END_METADATA_VAR(false)
        ),
        // description
        string.concat(
          compiler.BEGIN_METADATA_VAR("description", false),
          "Artists: NEORT / NOLL / Junni",
          compiler.END_METADATA_VAR(false)
        )
      ),
      // image
      string.concat(
        compiler.BEGIN_METADATA_VAR("image", false),
        string(
          bytes.concat(
            bytes(_baseThumbnailURI),
            bytes(Strings.toString(tokenId)),
            bytes(".png")
          )
        ),
        compiler.END_METADATA_VAR(false)
      ),
      // animation_url
      string.concat(
        compiler.BEGIN_METADATA_VAR("animation_url", false),
        compiler.HTML_HEAD(),
        metaTag,
        styleTag,
        string.concat(
          compiler.BEGIN_SCRIPT(),
          compiler.SCRIPT_VAR("attribute", attributeObj, true),
          compiler.END_SCRIPT()
        ),
        htmlCode,
        string.concat(
          compiler.BEGIN_SCRIPT_DATA(),
          _artCodeURI,
          compiler.END_SCRIPT_DATA()
        ),
        compiler.END_METADATA_VAR(false)
      ),
      // attributes
      _attributesText(attribute),
      compiler.END_JSON()
    );
    return uri;
  }

  function mint(Attribute calldata params, bytes calldata signature)
    external
    payable
    nonReentrant
  {
    require(isOnSale, "Reincarnation: Not on sale");
    require(_mintedTokenIdList.length < MAX_SUPPLY, "Reincarnation: Sold out");
    require(
      verifyParams(params, signature),
      "Reincarnation: Invalid signature"
    );
    require(msg.value == PRICE, "Reincarnation: Invalid value");

    _doMint(_msgSender(), params);
  }

  function mintForFree(
    address to,
    Attribute calldata params,
    bytes calldata signature
  ) external onlyOwner {
    require(
      verifyParams(params, signature),
      "Reincarnation: Invalid signature"
    );
    _doMint(to, params);
  }

  function createAttribute(
    Attribute calldata attribute,
    Attribute calldata inheritedChildAttribute
  ) public view returns (Attribute memory) {
    uint256 id1 = uint256(
      keccak256(abi.encodePacked(attribute.tokenId, block.timestamp))
    ) % 6;
    uint256 id2 = uint256(
      keccak256(abi.encodePacked(attribute.name, block.timestamp))
    ) % 6;
    return
      Attribute(
        attribute.tokenId,
        attribute.name,
        _shouldInherit(0, id1, id2)
          ? inheritedChildAttribute.gender
          : attribute.gender,
        _shouldInherit(1, id1, id2)
          ? inheritedChildAttribute.height
          : attribute.height,
        _shouldInherit(2, id1, id2)
          ? inheritedChildAttribute.weight
          : attribute.weight,
        _shouldInherit(3, id1, id2)
          ? inheritedChildAttribute.bloodType
          : attribute.bloodType,
        _shouldInherit(4, id1, id2)
          ? inheritedChildAttribute.hometown
          : attribute.hometown,
        _shouldInherit(5, id1, id2)
          ? inheritedChildAttribute.character
          : attribute.character,
        inheritedChildAttribute.tokenId,
        attribute.madeFrom
      );
  }

  function setIsOnSale(bool _isOnSale) external onlyOwner {
    isOnSale = _isOnSale;
  }

  function setIsMetadataFrozen(bool _isMetadataFrozen) external onlyOwner {
    require(
      !isMetadataFrozen,
      "Reincarnation: isMetadataFrozen cannot be changed"
    );
    isMetadataFrozen = _isMetadataFrozen;
  }

  function setBaseThumbnailURI(string memory baseThumbnailURI)
    external
    onlyOwner
  {
    require(!isMetadataFrozen, "Reincarnation: Metadata is already frozen");
    _baseThumbnailURI = baseThumbnailURI;
  }

  function setArtCodeURI(string memory artCodeURI) external onlyOwner {
    require(!isMetadataFrozen, "Reincarnation: Metadata is already frozen");
    _artCodeURI = artCodeURI;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function _beginAttributeData(string memory name, bool omitQuotes)
    internal
    pure
    returns (string memory)
  {
    if (omitQuotes) {
      return string(abi.encodePacked("%2522", name, "%2522%253A")); // "name":
    }
    return string(abi.encodePacked("%2522", name, "%2522%253A%2522")); // "name":"
  }

  function _endAttributeData(bool omitQuotes)
    internal
    pure
    returns (string memory)
  {
    if (omitQuotes) {
      return "%252C"; // ,
    }
    return "%2522%252C"; // ",
  }

  function _attributesText(Attribute memory attribute)
    internal
    view
    returns (string memory)
  {
    return
      string.concat(
        compiler.BEGIN_METADATA_VAR("attributes", true),
        string.concat(
          "%5B", // [
          _attributeObject("name", attribute.name, false, true),
          string.concat(
            _attributeObject(
              "gender",
              Strings.toString(attribute.gender),
              true,
              true
            ),
            _attributeObject(
              "height",
              Strings.toString(attribute.height),
              true,
              true
            ),
            _attributeObject(
              "weight",
              Strings.toString(attribute.weight),
              true,
              true
            )
          ),
          string.concat(
            _attributeObject("bloodType", attribute.bloodType, false, true),
            _attributeObject("hometown", attribute.hometown, false, true),
            _attributeObject(
              "character",
              Strings.toString(attribute.character),
              true,
              true
            ),
            _attributeObject(
              "inheritedChildId",
              Strings.toString(attribute.inheritedChildId),
              false,
              true
            ),
            _attributeObject("madeFrom", attribute.madeFrom, false, false)
          ),
          "%5D" // ]
        )
      );
  }

  function _attributeObject(
    string memory traitType,
    string memory value,
    bool omitQuotes,
    bool endComma
  ) internal view returns (string memory) {
    return
      string.concat(
        "%7B",
        string.concat(
          compiler.BEGIN_METADATA_VAR("trait_type", false),
          traitType,
          compiler.END_METADATA_VAR(false)
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("value", omitQuotes),
          value,
          omitQuotes ? "" : "%22"
        ),
        "%7D",
        endComma ? "%2C" : ""
      );
  }

  function _doMint(address to, Attribute calldata params) internal {
    uint256 tokenId = params.tokenId;

    tokenIdToAttributes[tokenId] = params;

    _mintedTokenIdList.push(tokenId);
    _safeMint(to, tokenId);
  }

  function _shouldInherit(
    uint256 id,
    uint256 id1,
    uint256 id2
  ) internal pure returns (bool) {
    return id == id1 || id == id2;
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