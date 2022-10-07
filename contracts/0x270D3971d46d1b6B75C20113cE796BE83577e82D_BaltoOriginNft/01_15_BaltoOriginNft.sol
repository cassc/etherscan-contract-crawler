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
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BaltoOriginNft is Ownable, ERC721URIStorage, ReentrancyGuard {
  using Strings for uint256;

  uint256 private constant MAX_SUPPLY = 5000;
  bool public mintAllowed = false;

  string private _tokenBaseURI = "";
  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  bytes32 private merkleRoot;
  mapping(address => uint256) public numOfMints;

  uint256 public totalSupply = 0;
  uint256 public currentPhase;

  uint256 public oneTimeMintLimit = 40;
  uint256[7] public lastTokenIds = [350, 850, 1700, 2550, 3400, 4250, 5000];
  uint256[7] public prices = [0.03 ether, 0.04 ether, 0.04 ether, 0.04 ether, 0.05 ether, 0.05 ether, 0.06 ether];

  address public treasury = 0x2874054656ab183BCe742deF5994d0B3BD6f6aF8;
  address public feeWallet = 0x2874054656ab183BCe742deF5994d0B3BD6f6aF8;
  uint256 public performanceFee = 0.0023 ether;

  event MintEnabled();
  event MoveToNextPhase(uint256 phase);
  event Mint(address indexed user, uint256 tokenId);
  event BaseURIUpdated(string uri);

  event SetMintPrice(uint256 phase, uint256 price);
  event SetLastTokenId(uint256 phase, uint256 lastTokenId);
  event SetOneTimeMintLimit(uint256 limit);
  event SetWhitelist(bytes32 whitelistMerkleRoot);

  event SetFeeWallet(address wallet);
  event ServiceInfoUpadted(address wallet, uint256 fee);
  event AdminTokenRecovered(address tokenRecovered, uint256 amount);

  modifier onlyMintable() {
    require(mintAllowed && totalSupply < MAX_SUPPLY, "cannot mint");
    _;
  }

  constructor() ERC721("Balto Origin NFT", "BaltoAlpha") {}

  function mint(
    bytes32[] memory _merkleProof,
    uint256 _numToMint,
    uint256 _maxToMint
  ) external payable onlyMintable nonReentrant {
    require(_numToMint > 0, "invalid amount");
    require(_numToMint <= oneTimeMintLimit, "exceed one-time mint limit");
    require(totalSupply + _numToMint <= lastTokenIds[currentPhase - 1], "Exceed current phase limit");

    uint256 price = prices[currentPhase - 1] * _numToMint;

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxToMint));
    if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
      if (numOfMints[msg.sender] < _maxToMint) {
        uint256 remainedFreeMint = _maxToMint - numOfMints[msg.sender];
        if (remainedFreeMint >= _numToMint) {
          price = 0;
        } else {
          price -= prices[currentPhase - 1] * remainedFreeMint;
        }
      }
    }
    require(msg.value >= price + performanceFee, "insufficient eth amount for mint");

    payable(feeWallet).transfer(price);
    payable(treasury).transfer(performanceFee);
    if (msg.value > price + performanceFee) {
      payable(msg.sender).transfer(msg.value - price - performanceFee);
    }

    numOfMints[msg.sender] += _numToMint;
    for (uint256 i = 0; i < _numToMint; i++) {
      uint256 tokenId = totalSupply + i + 1;

      _safeMint(msg.sender, tokenId);
      _setTokenURI(tokenId, tokenId.toString());
      super._setTokenURI(tokenId, tokenId.toString());

      emit Mint(msg.sender, tokenId);
    }

    totalSupply += _numToMint;
    if (totalSupply == MAX_SUPPLY) {
      mintAllowed = false;
    } else {
      if (totalSupply >= lastTokenIds[currentPhase - 1]) currentPhase += 1;
    }
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

  function enableMint() external onlyOwner {
    require(merkleRoot != "", "Whitelist not set");
    require(!mintAllowed, "already enabled");
    require(currentPhase == 0, "mint already finished");

    currentPhase = 1;
    mintAllowed = true;

    emit MintEnabled();
  }

  function moveToNextPhase() external onlyOwner {
    require(mintAllowed, "mint not enabled");
    require(currentPhase < 7, "reached last phase");

    lastTokenIds[currentPhase - 1] = totalSupply;
    currentPhase++;
    emit MoveToNextPhase(currentPhase);
  }

  function setMintPrice(uint256 _phase, uint256 _price) external onlyOwner {
    require(_phase <= 7 && _phase > 0, "invalid phase");
    require(_phase >= currentPhase, "cannot update mint price of previous phase");
    prices[_phase - 1] = _price;

    emit SetMintPrice(_phase, _price);
  }

  function setLastTokenIdForPhase(uint256 _phase, uint256 _lastTokenId) external onlyOwner {
    require(_phase <= 7 && _phase > 0, "invalid phase");
    require(_phase < 7, "cannot set last tokenId for last phase");
    require(_phase >= currentPhase, "cannot update last tokenId of previous phase");

    require(_lastTokenId <= MAX_SUPPLY, "exceed max supply");
    require(_lastTokenId >= totalSupply, "use upcoming tokenId");
    require(_lastTokenId < lastTokenIds[_phase], "use a tokenId less than last tokenId in next phase");
    if(_phase > 1) {
      require(_lastTokenId > lastTokenIds[_phase - 2], "use a tokenId greater than last tokenId in prev phase");
    }

    lastTokenIds[_phase - 1] = _lastTokenId;
    emit SetLastTokenId(_phase, _lastTokenId);
  }

  function setOneTimeMintLimit(uint256 _limit) external onlyOwner {
    require(_limit <= 150, "cannot exceed 150");
    oneTimeMintLimit = _limit;
    emit SetOneTimeMintLimit(_limit);
  }

  function setAdminWallet(address _wallet) external onlyOwner {
    require(_wallet != address(0x0), "invalid address");
    feeWallet = _wallet;
    emit SetFeeWallet(_wallet);
  }

  function setServiceInfo(address _treasury, uint256 _fee) external onlyOwner {
    require(_treasury != address(0x0), "invalid address");
    treasury = _treasury;
    performanceFee = _fee;
    emit ServiceInfoUpadted(_treasury, _fee);
  }

  function setWhiteList(bytes32 _merkleRoot) external onlyOwner {
    require(_merkleRoot != "", "invalid merkle root");
    merkleRoot = _merkleRoot;
    emit SetWhitelist(_merkleRoot);
  }

  function rescueTokens(address _token, uint256 _amount) external onlyOwner {
    if (_token == address(0x0)) {
      payable(msg.sender).transfer(_amount);
    } else {
      IERC20(_token).transfer(address(msg.sender), _amount);
    }

    emit AdminTokenRecovered(_token, _amount);
  }

  function setTokenBaseUri(string memory _uri) external onlyOwner {
    _tokenBaseURI = _uri;
    emit BaseURIUpdated(_uri);
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
    require(_exists(tokenId), "BaltoOriginNft: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  receive() external payable {}
}