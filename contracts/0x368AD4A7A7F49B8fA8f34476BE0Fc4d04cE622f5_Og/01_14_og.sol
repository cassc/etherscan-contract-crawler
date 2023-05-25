// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Organic Grow Crystals contract
 *
 * @notice Smart Contract provides ERC721 functionality with public and private sales options.
 * @author Andrey Skurlatov
 */
contract Og is ERC721Enumerable, Ownable {
  // Use safeMath library for doing arithmetic with uint256 and uint8 numbers
  using SafeMath for uint256;
  using SafeMath for uint8;

  // address to withdraw funds from contract
  address payable private withdrawAddress;

  // maximum number of tokens that can be purchased in one transaction
  uint8 public constant MAX_PURCHASE = 10;

  // price of a single crystal in wei
  uint256 public constant OG_PRICE = 103010000000000000 wei;

  // color id should be in this range
  uint8 public constant COLORS_VARIATIONS = 6;

  // freeze contract tokens have persistence tokenURI that can not be changed
  bool public isFreeze;

  // maximum number of crystals that can be minted on this contract
  uint256 public maxTotalSupply;

  // base uri for token metadata
  string private _baseTokenURI;

  // private sale current status - active or not
  bool private _privateSale;

  // public sale current status - active or not
  bool private _publicSale;

  // whitelisted addresses that can participate in the presale event
  mapping(address => uint8) private _whiteList;

  // used minting slots for public sale
  mapping(address => uint8) private _publicSlots;

  // all token URI's map
  mapping(uint256 => string) private _tokenURIs;

  // token colors storage
  mapping(uint256 => uint8) private _tokenColors;

  // event that emits when private sale changes state
  event privateSaleState(bool active);

  // event that emits when public sale changes state
  event publicSaleState(bool active);

  // event that emits when user bought crystals on private sale
  event addressPrivateSlotsChange(address addr, uint256 slots);

  // event that emits when user bought crystals on public sale
  event addressPublicSlotsChange(address addr, uint256 slots, uint256 totalRemaining);

  /**
  * @dev contract constructor
  *
  * @param name is contract name
  * @param symbol is contract basic symbol
  * @param baseTokenURI is base (default) tokenURI with metadata
  * @param maxSupply is Crystals tokens max supply
  * @param _withDrawAddress is address to withdraw funds from contract
  */
  constructor (
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256 maxSupply,
    address payable _withDrawAddress
  ) ERC721(name,symbol) {
    _baseTokenURI = baseTokenURI;
    maxTotalSupply = maxSupply;
    withdrawAddress = _withDrawAddress;
  }

  /**
  * @dev check if private sale is active now
  *
  * @return bool if private sale active
  */
  function isPrivateSaleActive() public view virtual returns (bool) {
    return _privateSale;
  }

  /**
  * @dev switch private sale state
  */
  function flipPrivateSaleState() external onlyOwner {
    _privateSale = !_privateSale;
    emit privateSaleState(_privateSale);
  }

  /**
  * @dev check if public sale is active now
  *
  * @return bool if private sale active
  */
  function isPublicSaleActive() public view virtual returns (bool) {
    return _publicSale;
  }

  /**
  * @dev check if public sale is already finished
  *
  * @return bool if private sale active
  */
  function isPublicSaleEnded() public view virtual returns (bool) {
    return maxTotalSupply == totalSupply();
  }

  /**
  * @dev switch public sale state
  */
  function flipPublicSaleState() external onlyOwner {
    _publicSale = !_publicSale;
    emit publicSaleState(_publicSale);
  }

  /**
  * @dev add ETH addresses to whitelist
  *
  * Requirements:
  * - private sale must be inactive
  * - numberOfTokens should be less than MAX_PURCHASE value
  *
  * @param addresses address[] array of ETH addresses that need to be whitelisted
  * @param numberOfTokens uint8 tokens amount for private sale per address
  */
  function addWhitelistAddresses(uint8 numberOfTokens, address[] calldata addresses) external onlyOwner {
    require(!isFreeze, "contract have already frozen!");
    require(!_privateSale, "Private sale is now running!!!");
    require(numberOfTokens <= MAX_PURCHASE, "numberOfTokens is higher that MAX PURCHASE limit!");

    for (uint256 i = 0; i < addresses.length; i++) {
      if (addresses[i] != address(0)) {
        _whiteList[addresses[i]] = numberOfTokens;
      }
    }
  }

  /**
  * @dev remove ETH addresses from whitelist
  *
  * Requirements:
  * - private sale must be inactive
  *
  * @param addresses address[] array of ETH addresses that need to be removed from whitelist
  */
  function removeWhitelistAddresses(address[] calldata addresses) external onlyOwner {
    require(!isFreeze, "contract have already frozen!");
    require(!_privateSale, "Private sale is now running!!!");

    for (uint256 i = 0; i < addresses.length; i++) {
      _whiteList[addresses[i]] = 0;
    }
  }

  /**
  * @dev check if address whitelisted
  *
  * @param _address address ETH address to check
  * @return bool whitelist status
  */
  function isWhitelisted(address _address) public view returns (bool) {
    return (_whiteList[_address] > 0 || balanceOf(_address) > 0)
      ? true
      : false;
  }

  /**
  * @dev check address remaining mint slots for private sale
  *
  * @param _address address ETH address to check
  * @return uint8 remaining slots
  */
  function addressPrivateSaleSlots(address _address) public view returns (uint256) {
    return _whiteList[_address];
  }

  /**
  * @dev check address remaining mint slots for public sale
  *
  * @param _address address ETH address to check
  * @return uint8 remaining slots
  */
  function addressPublicSaleSlots(address _address) public view returns (uint8) {
    return MAX_PURCHASE - _publicSlots[_address];
  }

  /**
  * @dev mint new Crystal token with given
  * color to provided address
  *
  * Requirements:
  * - private sale should be active
  * - color should be in a valid range
  * - sender should have private sale minting slots
  * - sender should pay OG price for each token
  *
  * @param numberOfTokens is an amount of tokens to mint
  * @param colors is array with Crystal colors
  */
  function mintPrivate(uint8 numberOfTokens, uint8[] memory colors) public payable {
    require(_privateSale, "Private sale is not active!");
    require(numberOfTokens > 0, "Number of tokens cannot be lower than, or equal to 0!");
    require(totalSupply() + numberOfTokens <= maxTotalSupply, "Total Supply limit have reached!");
    require(numberOfTokens <= _whiteList[msg.sender], "Not enough presale slots to mint tokens!");
    require(OG_PRICE * numberOfTokens == msg.value, "Ether value sent is not correct!");

    _whiteList[msg.sender] = uint8(_whiteList[msg.sender].sub(numberOfTokens));
    _mintTokens(msg.sender, numberOfTokens, colors);

    payable(withdrawAddress).transfer(msg.value);

    emit addressPrivateSlotsChange(msg.sender, _whiteList[msg.sender]);
  }

  /**
  * @dev mint new Crystal token with given
  * color to provided address
  *
  * Requirements:
  * - public sale should be active
  * - color should be in a valid range
  * - sender should have public sale minting slots
  * - sender should pay OG price for each token
  *
  * @param numberOfTokens is an amount of tokens to mint
  * @param colors is array with Crystal colors
  */
  function mintPublic(uint8 numberOfTokens, uint8[] memory colors) public payable {
    require(_publicSale, "Public sale is not active!");
    require(numberOfTokens > 0, "Number of tokens cannot be lower than, or equal to 0!");
    require(numberOfTokens <= MAX_PURCHASE, "Trying to mint too many tokens!");
    require(totalSupply() + numberOfTokens <= maxTotalSupply, "Total Supply limit have reached!");
    require(numberOfTokens + _publicSlots[msg.sender] <= MAX_PURCHASE, "Address limit have reached!");
    require(OG_PRICE * numberOfTokens == msg.value, "Ether value sent is not correct!");

    _publicSlots[msg.sender] = uint8(_publicSlots[msg.sender].add(numberOfTokens));
    _mintTokens(msg.sender, numberOfTokens, colors);

    payable(withdrawAddress).transfer(msg.value);

    emit addressPublicSlotsChange(msg.sender, MAX_PURCHASE - _publicSlots[msg.sender], maxTotalSupply - totalSupply());
  }

  /**
  * @dev mint gift Crystal tokens with given URI
  *
  * Requirements:
  * - sender must be contract owner
  *
  * @param to is address where to mint new token
  * @param numberOfTokens is an amount of tokens to mint
  * @param colors is array with Crystal colors
  */
  function mintGiftToken(address to, uint8 numberOfTokens, uint8[] memory colors) public onlyOwner {
    require(numberOfTokens > 0, "Number of tokens cannot be lower than, or equal to 0!");
    require(totalSupply() + numberOfTokens <= maxTotalSupply, "Total Supply limit have reached!");

    _mintTokens(to, numberOfTokens, colors);
  }

  /**
  * @dev mint new Crystal tokens with given
  * color to sender
  *
  * @param numberOfTokens is an amount of tokens to mint
  * @param colors is array with Crystal colors
  */
  function _mintTokens(address to, uint8 numberOfTokens, uint8[] memory colors) private {
    require(!isFreeze, "contract have already frozen!");
    require(numberOfTokens == colors.length, "Colors array length should be equal to numberOfTokens!");

    for (uint8 i = 0; i < numberOfTokens; i++) {
      uint256 tokenId = totalSupply().add(1);
      _safeMint(to, tokenId);
      _setTokenURI(tokenId, _formatURI(_baseTokenURI, _uint2str(tokenId)));
      _tokenColors[tokenId] = colors[i];
    }
  }

  /**
  * @dev return color of given crystal
  */
  function tokenColor(uint256 tokenId) public view virtual returns (uint8) {
    require(_exists(tokenId), "ERC721URIStorage: Color query for nonexistent token");

    return _tokenColors[tokenId];
  }

  /**
  * @dev freeze contract to prevent any tokenURI changes
  * and set maxTotalSupply as current total supply
  *
  * Requirements:
  *
  * - `sender` must be contract owner
  */
  function freeze() external onlyOwner {
    require(!isFreeze, "contract have already frozen!");
    isFreeze = true;
    maxTotalSupply = totalSupply();
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

    delete _tokenColors[tokenId];
  }

  /**
  * @dev check how many tokens is available for mint
  *
  * @return uint256 remaining tokens
  */
  function availableForMint() public view virtual returns (uint256) {
    return (maxTotalSupply - totalSupply());
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /**
   * @dev format token URI for given token ID
   *
   * @param basePath is tokenURI base path
   * @param tokenID is string representation of SST token ID
   * @return string is formatted tokenURI with metadata
   */
  function _formatURI(string memory basePath, string memory tokenID) internal pure returns (string memory) {
    return string(abi.encodePacked(basePath, tokenID, ".json"));
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