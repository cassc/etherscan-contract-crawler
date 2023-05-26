// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LuckyRooNft is Ownable, ERC721URIStorage, ReentrancyGuard {
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 3048;

  string private _tokenBaseURI = "";
  string[2] private rareNames = ["Common", "Rare"];

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  bool public mintAllowed = false;
  uint256 public oneTimeLimit = 50;

  uint256 public mintPrice = 0.5 ether;
  uint256 public totalSupply = 0;

  uint256 private numAvailableItems = 3048;
  uint256[3048] private availableItems;

  uint256 private premine;
  mapping(address => uint256[]) private premineTokenIds;
  mapping(address => bool) public preminted;

  address public treasury = 0x785466a12D832785D90D96a5229DCb104BE795d8;
  address public revenue = 0x219801ea6177acA2B6f3A812c07C8B0f6db1Ab35;
  uint256 public performanceFee = 0.0018 ether;

  event MintEnabled();
  event MintDisabled();
  event Mint(address indexed user, uint256 tokenId);
  event SetMintPrice(uint256 price);
  event SetOneTimeLimit(uint256 limit);
  event ServiceInfoUpadted(address addr, uint256 fee);
  event SetRevenueWallet(address addr);
  event BaseURIUpdated(string uri);

  modifier onlyMintable() {
    require(mintAllowed && totalSupply < MAX_SUPPLY, "Cannot mint");
    _;
  }

  constructor() ERC721("Lucky Roo", "LUCKY") {}

  function preMint(address _to) external onlyOwner {
    require(totalSupply < premine, "Premine already finished");
    require(!preminted[_to], "Already mint");
    require(premineTokenIds[_to].length > 0, "Not whitelisted");

    preminted[_to] = true;

    uint256 count = premineTokenIds[_to].length;
    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = premineTokenIds[_to][i] - 1;
      uint256 lastIndex = numAvailableItems - 1;
      if (tokenId != lastIndex) {
        uint256 lastValInArray = availableItems[lastIndex];
        if (lastValInArray == 0) {
          availableItems[tokenId] = lastIndex;
        } else {
          availableItems[tokenId] = lastValInArray;
        }
      }

      tokenId++;
      _safeMint(_to, tokenId);
      _setTokenURI(tokenId, tokenId.toString());
      super._setTokenURI(tokenId, tokenId.toString());

      totalSupply++;
      numAvailableItems--;

      emit Mint(_to, tokenId);
    }
  }

  function mint(uint256 _numToMint) external payable onlyMintable nonReentrant {
    require(_numToMint <= oneTimeLimit, "Exceed one time limit");

    if (totalSupply + _numToMint > MAX_SUPPLY) {
      _numToMint = MAX_SUPPLY - totalSupply;
    }
    require(_numToMint > 0, "Invalid count");
    require(msg.value >= mintPrice * _numToMint + performanceFee, "Try send more eth");

    payable(revenue).transfer(mintPrice * _numToMint);
    payable(treasury).transfer(performanceFee);
    if (msg.value > mintPrice * _numToMint + performanceFee) {
      payable(msg.sender).transfer(msg.value - mintPrice * _numToMint - performanceFee);
    }

    for (uint256 i = 0; i < _numToMint; i++) {
      uint256 tokenId = _randomAvailableTokenId(_numToMint, i);

      tokenId++;
      _safeMint(msg.sender, tokenId);
      _setTokenURI(tokenId, tokenId.toString());
      super._setTokenURI(tokenId, tokenId.toString());

      totalSupply++;
      if (totalSupply == MAX_SUPPLY) {
        mintAllowed = false;
      }
      numAvailableItems--;

      emit Mint(msg.sender, tokenId);
    }
  }

  function _randomAvailableTokenId(uint256 _numToFetch, uint256 _i) internal returns (uint256) {
    uint256 randomNum = uint256(
      keccak256(
        abi.encode(
          msg.sender,
          tx.gasprice,
          block.number,
          block.timestamp,
          blockhash(block.number - 1),
          _numToFetch,
          _i
        )
      )
    );

    uint256 randomIndex = randomNum % numAvailableItems;

    uint256 valAtIndex = availableItems[randomIndex];
    uint256 result;
    if (valAtIndex == 0) {
      // This means the index itself is still an available token
      result = randomIndex;
    } else {
      // This means the index itself is not an available token, but the val at that index is.
      result = valAtIndex;
    }

    uint256 lastIndex = numAvailableItems - 1;
    if (randomIndex != lastIndex) {
      // Replace the value at randomIndex, now that it's been used.
      // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
      uint256 lastValInArray = availableItems[lastIndex];
      if (lastValInArray == 0) {
        // This means the index itself is still an available token
        availableItems[randomIndex] = lastIndex;
      } else {
        // This means the index itself is not an available token, but the val at that index is.
        availableItems[randomIndex] = lastValInArray;
      }
    }

    return result;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "RabblePass: URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = _baseURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(_baseURI(), _tokenURI));
    }

    return super.tokenURI(tokenId);
  }

  function rarityOf(uint256 _tokenId) external view returns (string memory) {
    if (_tokenId <= 48) return rareNames[1];
    return rareNames[0];
  }

  function enableMint() external onlyOwner {
    require(premine > 0, "Not set premine tokenIds");
    require(totalSupply >= premine, "Premine not finished yet");
    require(!mintAllowed, "Mint already enabled");

    mintAllowed = true;
    emit MintEnabled();
  }

  function disableMint() external onlyOwner {
    require(mintAllowed, "Mint not enabled");

    mintAllowed = false;
    emit MintDisabled();
  }

  function setMintPrice(uint256 _price) external onlyOwner {
    require(!mintAllowed, "Mint already started");
    mintPrice = _price;
    emit SetMintPrice(_price);
  }

  function setOneTimeLimit(uint256 _limit) external onlyOwner {
    require(_limit > 0, "Invalid limit");
    oneTimeLimit = _limit;
    emit SetOneTimeLimit(_limit);
  }

  function setPremineTokenIds(address _user, uint256[] memory _tokenIds) external onlyOwner {
    require(totalSupply == 0, "Mint already started");

    premine += _tokenIds.length - premineTokenIds[_user].length;
    premineTokenIds[_user] = _tokenIds;
  }

  function setTokenBaseUri(string memory _uri) external onlyOwner {
    _tokenBaseURI = _uri;
    emit BaseURIUpdated(_uri);
  }

  function setServiceInfo(address _addr, uint256 _fee) external {
    require(msg.sender == treasury, "setServiceInfo: FORBIDDEN");
    require(_addr != address(0x0), "Invalid address");

    treasury = _addr;
    performanceFee = _fee;

    emit ServiceInfoUpadted(_addr, _fee);
  }

  function setRevenueWallet(address _addr) external onlyOwner {
    require(_addr != address(0x0), "Invalid address");
    revenue = _addr;
    emit SetRevenueWallet(_addr);
  }

  function rescueTokens(address _token) external onlyOwner {
    if (_token == address(0x0)) {
      uint256 _ethAmount = address(this).balance;
      payable(msg.sender).transfer(_ethAmount);
    } else {
      uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
      IERC20(_token).transfer(msg.sender, _tokenAmount);
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
    require(_exists(tokenId), "LuckyRoo: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  receive() external payable {}
}