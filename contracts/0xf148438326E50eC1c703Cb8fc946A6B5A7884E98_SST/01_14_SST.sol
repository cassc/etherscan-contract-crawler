// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Space Suit Token (SST) contract for Mars Cats Voyage project
 *
 * @notice Smart Contract provides ERC721 functionality with additional options
 * to handle "wear" mechanic that allow to MCV owners to mint new SST tokens and wear it
 */
contract SST is ERC721Enumerable, Ownable {
  // use safeMath library for doing arithmetic with uint256 numbers
  using SafeMath for uint256;

  // suits id should be in this range
  uint8 public constant SUITS_VARIATIONS = 15;

  // freeze contract tokens have immortal tokenURI that can not be changed forever
  bool public isFreeze;

  // SST tokens max supply. Also used as MCV token range that able to mint SSY
  uint256 public maxSuits;

  // additional MCV tokens ids that whitelisted for SST minting
  mapping(uint256 => bool) private _whitelistedMCV;

  // all token URI's map
  mapping(uint256 => string) private _tokenURIs;

  // map that used to check if SST already dressed
  mapping(uint256 => bool) private _dressed;

  // map that used to check what exactly suit bind to token
  mapping(uint256 => uint8) private _suitsId;

  // map that used to check if MCV have already dressed
  mapping(uint256 => bool) private _mcvDressed;

  // map that used to check if MCV token have already used to mint new SST
  mapping(uint256 => bool) private _mcvUsed;

  // base (default) token URI
  string private _baseTokenURI;

  // MCV ERC721 contract address
  address private _mcvAddress;

  // event that emits after new SST have minted
  event sstMint(uint256 sstID, uint256 mcvID);

  // event that emits when new MCV dressed with SST
  event sstWear(uint256 sstID, uint256 mcvID, uint8 suitID);

  /**
  * @dev contract constructor
  *
  * @param name is contract name
  * @param symbol is contract basic symbol
  * @param baseTokenURI is base (default) tokenURI with metadata
  * @param mcvAddress is address of MCV ERC721 contract
  * @param maxSupply is SST tokens max supply. Also used as MCV token range that able to mint SSY
  */
  constructor (
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    address mcvAddress,
    uint256  maxSupply
  ) ERC721(name,symbol) {
    _baseTokenURI = baseTokenURI;
    _mcvAddress = mcvAddress;
    maxSuits = maxSupply;
  }

  /**
  * @dev freeze contract to prevent any tokenURI changes
  * Requirements:
  *
  * - `sender` must be contract owner
  */
  function freeze() external onlyOwner {
    require(!isFreeze, "contract have already frozen!");
    isFreeze = true;
  }

  /**
  * @dev add MCV id's to whitelist and make
  * them able to mint new SST
  *
  * @param mcvs uint256[] array of MCV tokens id's that need to be whitelisted
  */
  function whiteListMCV(uint256[] calldata mcvs) external onlyOwner {
    for (uint256 i = 0; i < mcvs.length; i++) {
      if (mcvs[i] != 0) {
        _whitelistedMCV[mcvs[i]] = true;
      }
    }
  }

  /**
  * @dev Sets public function that will set
  * `_tokenURI` as the tokenURI of `tokenId`.
  *
  * Requirements:
  *
  * - `tokenId` must exist.
  * - `sender` must be contract owner
  */
  function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
    require(!isFreeze, "contract have already frozen!");
    _setTokenURI(tokenId, _tokenURI);
  }

  /**
  * @dev See {IERC721Metadata-tokenURI}.
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = _baseURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    return super.tokenURI(tokenId);
  }

  /**
  * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
  *
  * Requirements:
  *
  * - `tokenId` must exist.
  */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  /**
  * @dev Destroys `tokenId`.
  * The approval is cleared when the token is burned.
  *
  * Requirements:
  *
  * - `tokenId` must exist.
  *
  * Emits a {Transfer} event.
  */
  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);

    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }

  /**
  * @dev mint new SST token to given MCV
  * user able to wear it immediately
  * on MCV by given token ID
  *
  * Requirements:
  *
  * - `sender` should be a MCV owner
  * - `mcvID` should not be already used to mint SST
  * - `mcvID` should be one of the first or whitelisted MCV
  *
  * @param mcvID is MCV token ID that will be used to mint SST
  * @param suitID is Suit ID that will be bind with SST. Should be 0 for mint packed (free) suit
  */
  function mint(uint256 mcvID, uint8 suitID) public {
    require(suitID <= SUITS_VARIATIONS, "Suits is not in valid range!");
    require(IERC721Enumerable(_mcvAddress).ownerOf(mcvID) == msg.sender, "Sender is not an owner of MCV!");
    require(!_mcvUsed[mcvID], "Suit for this cat have already minted!");
    require(mcvID <= maxSuits || _whitelistedMCV[mcvID], "MCV is not able to mint suit!");

    uint256 sstID = totalSupply().add(1);
    _mint(msg.sender, sstID);
    _setTokenURI(sstID, _formatURI(_baseTokenURI, _uint2str(sstID)));
    _mcvUsed[mcvID] = true;

    if (suitID > 0) {
      _wear(sstID, mcvID, suitID);
    } else {
      emit sstMint(sstID, mcvID);
    }
  }

  /**
  * @dev return bind suit ID
  *
  * @param sstID is SST id to interact with
  * @return uit8 suit id
  */
  function suitIdOf(uint256 sstID) view public returns(uint8) {
    return _suitsId[sstID];
  }

  /**
  * @dev wear MCV with SST
  * it's just a wrapper and validator to call internal method
  *
  * Requirements:
  *
  * - `sstID` should be owned by sender
  * - `mcvID` should be owned by sender
  * - `mcvID` should not be already dressed
  *
  * @param sstID is SST token ID that user want to wear
  * @param mcvID is MCV token ID that user want to be dressed
  * @param suitID is Suit ID that will be bind with SST
  */
  function wearSuit(uint256 sstID, uint256 mcvID, uint8 suitID) public {
    require(IERC721Enumerable(_mcvAddress).ownerOf(mcvID) == msg.sender, "Sender is not an owner of MCV!");
    require(ownerOf(sstID) == msg.sender, "Sender is not an owner of SST!");
    require(suitID > 0 && suitID <= SUITS_VARIATIONS, "Suits is not in valid range!");

    _wear(sstID, mcvID, suitID);
  }

  /**
  * @dev wear MCV with SST
  *
  * Requirements:
  *
  * - `sstID` should not be already wear
  * - `mcvID` should not be already dressed
  *
  * @param sstID is SST token ID that user want to wear
  * @param mcvID is MCV token ID that user want to be dressed
  * @param suitID is Suit ID that will be bind with SST
  */
  function _wear(uint256 sstID, uint256 mcvID, uint8 suitID) internal {
    require(!_dressed[sstID], "Suit have already dressed!");
    require(!_mcvDressed[mcvID], "Cat already with suit!");

    _suitsId[sstID] = suitID;
    _dressed[sstID] = true;
    _mcvDressed[mcvID] = true;

    emit sstWear(sstID, mcvID, suitID);
  }

  /**
  * @dev check us sst have already dressed
  *
  * @param sstID is SST token ID to check wear
  * @return bool show is sst dressed or not
  */
  function isWear(uint256 sstID) public view returns(bool) {
    return _dressed[sstID];
  }

  /**
   * @dev format token URI for given token ID
   *
   * @param basePath is tokenURI base path
   * @param sstID is string representation of SST token ID
   * @return string is formatted tokenURI with metadata
   */
  function _formatURI(string memory basePath, string memory sstID) internal pure returns (string memory) {
    return string(abi.encodePacked(basePath, sstID, ".json"));
  }

  /**
   * @dev format given uint to memory string
   *
   * @param _i uint to convert
   * @return string is uint converted to string
   */
  function _uint2str(uint _i) internal pure returns (string memory) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
}