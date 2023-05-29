// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* <marquee/> shelter by @0xhaiku


<marquee>Good boy!</marquee>

  ^ ^ 
ω-'' )_______o
 ^--  # # # #)
   |_|_|-|_|_|


*/

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IMarqueeArt {
  enum Mode {
    Marquee,
    CSS
  }

  function getPalette(uint256) external view returns (string[10] memory);

  function getDogString(uint256, Mode) external view returns (string memory);

  function getDogSpeed(uint256) external view returns (uint8, uint8);

  function tokenHTML(uint256, Mode) external view returns (string memory);

  function tokenSVG(uint256, Mode) external view returns (string memory);

  function tokenURI(
    uint256,
    Mode,
    uint256
  ) external view returns (string memory);
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract Marquee is ERC721, ReentrancyGuard, Ownable {
  enum Mode {
    Marquee,
    CSS
  }

  uint256 private _tokenSupply;
  mapping(uint256 => address) private _owners;
  mapping(uint256 => bool) private _isResurrectioned;
  mapping(uint256 => uint256) private _rescueDates;

  address proxyRegistryAddress;
  address public artAddress;
  bool public artLocked;

  uint256 public constant MAX_SUPPLY = 1_145;
  uint256 public constant OWNER_ALLOTMENT = 50;
  uint256 public constant SUPPLY = MAX_SUPPLY - OWNER_ALLOTMENT;
  uint256 public shelterSize = 3;
  uint256 public dutchBasePrice = 0.02 ether;
  uint256 public dutchStepPrice = 0.01 ether;
  uint256 public dutchStepTime = 30 * 60;
  uint256 public dutchEndTime = 12 * 60 * 60;
  uint256 public shelterStartTime;
  bool public shelterIsActive;

  constructor(address _proxyRegistryAddress, address _artAddress)
    ERC721("marquee shelter", "MQSLT")
  {
    proxyRegistryAddress = _proxyRegistryAddress;
    artAddress = _artAddress;
  }

  modifier costs() {
    require(msg.value >= price(), "Not enough ETH sent; check price!");
    _;
  }

  function price() public view returns (uint256) {
    uint256 endTime = today() + dutchEndTime;
    if (block.timestamp > endTime) {
      return dutchBasePrice;
    }
    uint256 timeElapsed = endTime - block.timestamp;
    uint256 steps = timeElapsed / dutchStepTime;
    if (block.timestamp == today()) {
      steps--;
    }
    return dutchBasePrice + dutchStepPrice * steps;
  }

  function ownerMint(uint256[] memory _tokenIds, address to)
    external
    nonReentrant
    onlyOwner
  {
    for (uint256 i; i < _tokenIds.length; i++) {
      uint256 _tokenId = _tokenIds[i];
      require(0 < _tokenId && _tokenId <= MAX_SUPPLY);
      require(SUPPLY < _tokenId);
      _tokenSupply++;
      _rescueDates[_tokenId] = today();
      _safeMint(to, _tokenId);
    }
  }

  /* shelter */

  function open() private view returns (bool) {
    return shelterStartTime != 0 && shelterStartTime <= block.timestamp;
  }

  function today() private view returns (uint256) {
    return (block.timestamp / 1 days) * 60 * 60 * 24;
  }

  function rescue(uint256 _tokenId) external payable nonReentrant costs {
    require(!_exists(_tokenId), "ERC721: token already minted");
    require(open(), "INACTIVE");
    require(shelterIsActive, "INACTIVE");
    require(0 < _tokenId && _tokenId <= SUPPLY, "INVALID");

    uint256[] memory ids = availableIds();
    bool available;
    for (uint256 i = 0; i < ids.length; i++) {
      if (_tokenId == ids[i]) {
        available = true;
      }
    }
    require(available, "NOT AVAILABLE");

    _tokenSupply++;
    _rescueDates[_tokenId] = today();
    _safeMint(_msgSender(), _tokenId);
  }

  function availableIds() public view returns (uint256[] memory) {
    require(open(), "INACTIVE");
    uint256[] memory _availableIds = new uint256[](shelterSize);

    uint256 day = ((block.timestamp - shelterStartTime) / 1 days) % 365;
    uint256 startId = day * shelterSize + 1;
    uint256 index = 0;
    for (uint256 i = 0; i < shelterSize; i++) {
      _availableIds[index] = startId + i;
      index++;
    }
    return _availableIds;
  }

  /** config **/

  function setShelterStartTime(uint256 _shelterStartTime) external onlyOwner {
    shelterStartTime = _shelterStartTime;
  }

  function setShelterIsActive(bool _shelterIsActive) external onlyOwner {
    shelterIsActive = _shelterIsActive;
  }

  function setShelterSize(uint256 _size) external onlyOwner {
    shelterSize = _size;
  }

  function setDutchEndTime(uint256 _time) external onlyOwner {
    dutchEndTime = _time;
  }

  function setDutchStepTime(uint256 _time) external onlyOwner {
    dutchStepTime = _time;
  }

  function setDutchBasePrice(uint256 _price) external onlyOwner {
    dutchBasePrice = _price;
  }

  function setDutchStepPrice(uint256 _price) external onlyOwner {
    dutchStepPrice = _price;
  }

  function setArtLocked() external onlyOwner {
    artLocked = true;
  }

  function setArtAddress(address _address) external onlyOwner {
    require(!artLocked);
    artAddress = _address;
  }

  function resurrection(uint256 _tokenId) external {
    require(ownerOf(_tokenId) == _msgSender());
    _isResurrectioned[_tokenId] = true;
  }

  /* artwork */

  function tokenHTML(uint256 _tokenId, Mode mode)
    external
    view
    returns (string memory)
  {
    return
      IMarqueeArt(artAddress).tokenHTML(
        _tokenId,
        mode == Mode.CSS ? IMarqueeArt.Mode.CSS : IMarqueeArt.Mode.Marquee
      );
  }

  function tokenSVG(uint256 _tokenId) external view returns (string memory) {
    return
      IMarqueeArt(artAddress).tokenSVG(
        _tokenId,
        _isResurrectioned[_tokenId]
          ? IMarqueeArt.Mode.CSS
          : IMarqueeArt.Mode.Marquee
      );
  }

  function getDogString(uint256 _tokenId)
    external
    view
    returns (string memory)
  {
    return
      IMarqueeArt(artAddress).getDogString(
        _tokenId,
        _isResurrectioned[_tokenId]
          ? IMarqueeArt.Mode.CSS
          : IMarqueeArt.Mode.Marquee
      );
  }

  // @dev speed-x, speed-y
  function getDogSpeed(uint256 _tokenId) external view returns (uint8, uint8) {
    return IMarqueeArt(artAddress).getDogSpeed(_tokenId);
  }

  // @dev name, base, sky, border, cloud1, cloud2, grass, flower1, flower2, dog
  function getPalette(uint256 _tokenId)
    external
    view
    returns (string[10] memory)
  {
    return IMarqueeArt(artAddress).getPalette(_tokenId);
  }

  /* token utility */

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    return
      IMarqueeArt(artAddress).tokenURI(
        _tokenId,
        _isResurrectioned[_tokenId]
          ? IMarqueeArt.Mode.CSS
          : IMarqueeArt.Mode.Marquee,
        _rescueDates[_tokenId]
      );
  }

  function totalSupply() external view returns (uint256) {
    return _tokenSupply;
  }

  function withdrawBalance() external onlyOwner {
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success);
  }

  function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    uint256 count;
    for (uint256 i = 1; i <= MAX_SUPPLY; i++) {
      if (_owners[i] == _owner) {
        tokensId[count] = i;
        count++;
      }
    }
    return tokensId;
  }

  function owners() external view returns (address[] memory) {
    address[] memory tokens = new address[](MAX_SUPPLY);

    for (uint256 i = 0; i < MAX_SUPPLY; i++) {
      tokens[i] = _owners[i + 1];
    }
    return tokens;
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
    _owners[tokenId] = to;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
  bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}