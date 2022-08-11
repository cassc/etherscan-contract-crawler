// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

//                        :+%%+:
//                    .-*@@@@@@@@#=.
//                 :+%@@@@@@@@@@@@@@%+:
//              -*@@@@@@@%+:  :=#@@@@@@@*-.
//          :+#@@@@@@@*-       :+%@@@@@@@@@%+:
//       -*@@@@@@@%+:       -*@@@@@@@%*%@@@@@@@*-
//   .=#@@@@@@@*=.      :+%@@@@@@@*=.   .-*@@@@@@@#=.
//  @@@@@@@%+:       -*@@@@@@@%+:       -+%@@@@@@%+:
//  @@@@@=.      :=#@@@@@@@#=.      .=#@@@@@@@*-.  :+%
//  @@@@%     -*@@@@@@@%+-       :+%@@@@@@%+:  .=#@@@@
//  @@@@%    [email protected]@@@@@#=.      .=#@@@@@@@#=.  :+%@@@@@@@
//  @@@@%    [email protected]@@@+       :+%@@@@@@%+:  .-*@@@@@@@@@@@
//  @@@@%    [email protected]@@@-    =*@@@@@@@#=.  :+%@@@@@@%*-#@@@@
//  @@@@%    [email protected]@@@-    @@@@@%+:  .=*@@@@@@@#=.   *@@@@
//  @@@@%    [email protected]@@@-    @@@@#  :+%@@@@@@@*-       *@@@@
//  @@@@%    [email protected]@@@-    @@@@#  #@@@@@#+:          *@@@@
//  @@@@%    [email protected]@@@-    @@@@#  #@@@@.      :+=    *@@@@
//  @@@@%    [email protected]@@@-    @@@@#  #@@@@.    *@@@*    *@@@@
//  @@@@%    [email protected]@@@-    @@@@#  #@@@@.   [email protected]@@@+    *@@@@
//  @@@@%    [email protected]@@@-    @@@@#  #@@@@.   [email protected]%+:     *@@@@
//  @@@@%    [email protected]@@@-    @@@@#  #@@@@.    .      .=%@@@@
//  %@@@%    [email protected]@@@-    @@@@#  #@@@@.        :+%@@@@@@%
//   .-*#    [email protected]@@@-    @@@@#  #@@@@.    .=#@@@@@@@*=.
//           [email protected]@@@-    @@@@#  #@@@@. :+%@@@@@@%+:
//           :*@@@-    @@@@#  #@@@@#@@@@@@@#=.
//              :+:    @@@@#  #@@@@@@@@%+:
//                     @@@@#  #@@@@@#=.
//                     :+%@#  #@%+:
//
//        _  _ ____ ___ ____ _  _ ____ _  _ ____ ____
//        |\/| |___  |  |__| |__| |  | |\/| |___ [__
//        |  | |___  |  |  | |  | |__| |  | |___ ___]
//
//
// Contract by loltapes.eth

contract MetaHomes is ERC4907A, ERC2981, Ownable {

  uint256 public constant SUPPLY = 1000;

  string public constant PROVENANCE = "ee98122b5e61d5643fa0e91c3854f5a10a31d16419cc501134ba47e1a4c84cd6";

  // @dev determined using VRF with a ranged result via 0xe85d6149cdcad3c82b963a67c621d67a4e352e74
  uint256 public OFFSET;

  // @dev the request id used to get the VRF result via 0xe85d6149cdcad3c82b963a67c621d67a4e352e74
  uint256 public OFFSET_REQUEST_ID;

  string public baseUri;

  bool public metadataFrozen;

  error AlreadyRevealed();
  error DistributionPending();
  error DistributionComplete();
  error InvalidBatch();
  error InvalidOffset();
  error MetadataFrozen();
  error OverRoyaltyLimit();
  error OverSupply();

  modifier whenMetadataNotFrozen {
    if (metadataFrozen) revert MetadataFrozen();
    _;
  }

  constructor(
    address _royaltyAddress,
    string memory _baseUri
  ) ERC721A("MetaHomes", "METAHOME") {
    baseUri = _baseUri;

    // default 5% royalties
    _setDefaultRoyalty(_royaltyAddress, 500);
  }

  function freezeMetadata() external onlyOwner whenMetadataNotFrozen {
    if (_totalMinted() < SUPPLY) revert DistributionPending();
    metadataFrozen = true;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseUri;
  }

  function setBaseUri(string memory _baseUri) external onlyOwner whenMetadataNotFrozen {
    baseUri = _baseUri;
  }

  function reveal(uint256 offset, uint256 requestId, string memory _baseUri) external onlyOwner whenMetadataNotFrozen {
    if (_totalMinted() < SUPPLY) revert DistributionPending();
    if (OFFSET > 0) revert AlreadyRevealed();
    if (offset == 0 || offset > SUPPLY) revert InvalidOffset();

    baseUri = _baseUri;
    OFFSET = offset;
    OFFSET_REQUEST_ID = requestId;
  }

  function distributeBatch(address[] calldata to, uint256[] calldata amounts) external onlyOwner {
    if (_totalMinted() == SUPPLY) revert DistributionComplete();
    if (to.length != amounts.length) revert InvalidBatch();

    for (uint i = 0; i < to.length;) {
      if (_totalMinted() + amounts[i] > SUPPLY) revert OverSupply();
      _safeMint(to[i], amounts[i], "");
    unchecked {++i;}
    }
  }

  // @notice Set token royalties
  // @param recipient recipient of the royalties
  // @param value points (using 2 decimals - 10_000 = 100, 0 = 0)
  function setRoyalties(address recipient, uint24 value) external onlyOwner {
    if (value > 1000) revert OverRoyaltyLimit();
    _setDefaultRoyalty(recipient, value);
  }

  // Supports the following `interfaceId`s:
  // - IERC165: 0x01ffc9a7
  // - IERC721: 0x80ac58cd
  // - IERC721Metadata: 0x5b5e139f
  // - IERC2981: 0x2a55205a
  // - ERC4907: 0xad092b5c
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC4907A, ERC2981) returns (bool) {
    return ERC4907A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}

/* Contract by loltapes.eth
          _       _ _
    ____ | |     | | |
   / __ \| | ___ | | |_ __ _ _ __   ___  ___
  / / _` | |/ _ \| | __/ _` | '_ \ / _ \/ __|
 | | (_| | | (_) | | || (_| | |_) |  __/\__ \
  \ \__,_|_|\___/|_|\__\__,_| .__/ \___||___/
   \____/                   | |
                            |_|
*/