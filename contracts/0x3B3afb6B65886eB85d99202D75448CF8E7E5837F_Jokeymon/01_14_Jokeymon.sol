pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Jokeymon
 */
contract Jokeymon is ERC721, ERC2981, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  event NewRoyalty(uint96 _newRoyalty);
  event NewURI(string _newURI);
  event URIFrozen(string _finalURI);
  event PublicMintStatus(bool _status);

  string public baseURI;
  bool public frozen;

  Counters.Counter private nextId;

  mapping(address => uint256) public claimed;
  uint256 public constant maxPerWallet = 2;

  uint256 public constant maxSupply = 10_000;
  uint256 public constant maxAdminSupply = 1_000;
  uint256 public adminMinted;

  bool public publicMintActive;

  /**
   * @param   _owner          Owner address
   * @param   _royaltyBPS     Royalty in basis points, max is 15% (1500 BPS)
   */
  constructor(address _owner, uint96 _royaltyBPS) ERC721("Jokeymon", "JKYMON") {
    require(_owner != address(0), "!addr");
    require(_royaltyBPS <= 1500, "!bps");

    // Set Ownership
    _transferOwnership(_owner);

    // Setup royalty
    _setDefaultRoyalty(owner(), _royaltyBPS);

    // Start at 1
    nextId.increment();
  }

  // ----- Public Functions -----

  /**
   * @notice  Mint an NFT
   * @dev     Maximum per wallet enforced
   * @param   _qty Number of NFTs to mint
   */
  function mint(uint256 _qty) external {
    require(publicMintActive, "!phase");
    require((_qty > 0) && (claimed[msg.sender] + _qty <= maxPerWallet), "!qty");
    require(nextId.current() + _qty < maxSupply, "!supply");

    claimed[msg.sender] += _qty;

    uint256 tokenId;
    for (uint256 i; i < _qty; ) {
      tokenId = nextId.current();
      nextId.increment();
      // Mint
      _mint(msg.sender, tokenId);
      unchecked {
        i++;
      }
    }
  }

  // ----- View Functions -----

  function totalSupply() external view returns (uint256) {
    return nextId.current() - 1;
  }

  // ----- Overrides -----

  /// @inheritdoc ERC721
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC2981)
    returns (bool)
  {
    return
      interfaceId == type(ERC2981).interfaceId ||
      ERC721.supportsInterface(interfaceId);
  }

  // ----- Admin Functions -----

  /**
   * @notice  Admin mint an NFT
   * @param   _qty  Number to mint
   * @param   _to   Destination address
   */
  function adminMint(uint256 _qty, address _to) external onlyOwner {
    require((_qty > 0) && (adminMinted + _qty <= maxAdminSupply), "!qty");
    require(nextId.current() + _qty < maxSupply, "!supply");

    adminMinted += _qty;

    uint256 tokenId;
    for (uint256 i; i < _qty; ) {
      tokenId = nextId.current();
      nextId.increment();
      // Mint
      _mint(_to, tokenId);
      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Start a public sale
   */
  function togglePublicSale() external onlyOwner {
    publicMintActive = !publicMintActive;
    emit PublicMintStatus(publicMintActive);
  }

  /**
   * @notice  Set a new base URI
   * @param   _newURI new URI string
   */
  function setURI(string memory _newURI) external onlyOwner {
    require(!frozen, "!frozen");
    baseURI = _newURI;
    emit NewURI(_newURI);
  }

  /**
   * @notice Freeze the URI, preventing any further modifications
   */
  function freezeURI() external onlyOwner {
    require(!frozen, "!frozen");
    frozen = true;
    emit URIFrozen(baseURI);
  }

  /**
   * @notice  Sets a new royalty numerator
   * @dev     Cannot exceed 15%
   * @param   _royaltyBPS   New royalty, denominated in BPS (10000 = 100%)
   * @return  True on success
   */
  function setRoyalty(uint96 _royaltyBPS) external onlyOwner returns (bool) {
    require(_royaltyBPS <= 1500, "!bps");

    _setDefaultRoyalty(owner(), _royaltyBPS);

    emit NewRoyalty(_royaltyBPS);
    return true;
  }
}