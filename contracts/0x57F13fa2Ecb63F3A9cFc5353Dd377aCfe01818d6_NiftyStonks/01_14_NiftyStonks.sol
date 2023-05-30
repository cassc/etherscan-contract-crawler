// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NiftyStonks is ERC721, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  uint256 public constant MAX_SUPPLY = 666;
  uint256 public MINT_PRICE = 0.1 ether;
  uint256 public MAX_MINTS_PER_TX = 1;
  uint256 public MAX_ITEMS_PER_WALLET = 1;
  uint256 public AVAILABLE_FOR_MINT = 35;

  bool public presaleStarted = false;
  bool public publicSaleStarted = false;

  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;

  modifier whenPresaleStarted() {
    require(presaleStarted, "Presale has not been started");
    _;
  }

  modifier whenPublicSaleStarted() {
    require(publicSaleStarted, "Public sale has not been started");
    _;
  }

  event PresaleMint(address minter, uint256 quantity);
  event PublicSaleMint(address minter, uint256 quantity);

  constructor() ERC721("NiftyStonks", "NS") {
    // Make sure we start from 1, not from 0
    _tokenIdCounter.increment();
  }

  function addToAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add empty address");

      _allowList[addresses[i]] = true;
      _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
    }
  }

  function removeFromAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add empty address");

      _allowList[addresses[i]] = false;

      // Don't want to reset possible _allowListClaimed numbers.
    }
  }

  function onAllowList(address wallet) public view returns (bool) {
    return _allowList[wallet];
  }

  function allowListClaimedBy(address owner) public view returns (uint256) {
    require(owner != address(0), "Empty address is not on allowlist");

    return _allowListClaimed[owner];
  }

  function togglePresaleStarted() public onlyOwner {
    presaleStarted = !presaleStarted;
  }

  function togglePublicSaleStarted() public onlyOwner {
    publicSaleStarted = !publicSaleStarted;
  }

  function setMaxMintsPerTx(uint256 _maxMintsPerTx) public onlyOwner {
    MAX_MINTS_PER_TX = _maxMintsPerTx;
  }

  function setMaxItemsPerWallet(uint256 _maxItemsPerWallet) public onlyOwner {
    MAX_ITEMS_PER_WALLET = _maxItemsPerWallet;
  }

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    MINT_PRICE = _mintPrice;
  }

  function setAvailableForMint(uint256 _availableForMint) public onlyOwner {
    AVAILABLE_FOR_MINT = _availableForMint;
  }

  function withdraw() public onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success, "transfer failed");
  }

  function mintPresaleKey(uint256 quantity) public payable whenPresaleStarted {
    require(_allowList[msg.sender], "You are not on the allowlist");
    require(quantity >= 1, "Requested quantity cannot be zero");
    require(quantity <= MAX_MINTS_PER_TX, "Requested quantity more than maximum per transaction");
    require(
      quantity <= MAX_ITEMS_PER_WALLET,
      "Requested quantity more than maximum allowed per wallet"
    );
    require(
      AVAILABLE_FOR_MINT >= quantity,
      "Requested quantity will exceed the limit of available for sale"
    );
    // Transaction must have at least quantity * price (any more is considered a tip)
    require(quantity * MINT_PRICE <= msg.value, "Not enough ether sent");
    require(super.totalSupply() + quantity <= MAX_SUPPLY, "Total supply will exceed the limit");

    require(
      balanceOf(msg.sender) < MAX_ITEMS_PER_WALLET,
      "Wallet already owns maximum allowed items"
    );

    for (uint256 i = 0; i < quantity; i++) {
      _safeMint(msg.sender, _tokenIdCounter.current());
      _tokenIdCounter.increment();
      _allowListClaimed[msg.sender] += 1;
      AVAILABLE_FOR_MINT = AVAILABLE_FOR_MINT - 1;
    }

    emit PresaleMint(msg.sender, quantity);
  }

  function mintKey(uint256 quantity) public payable whenPublicSaleStarted {
    require(quantity >= 1, "Requested quantity cannot be zero");
    require(quantity <= MAX_MINTS_PER_TX, "Requested quantity more than maximum per transaction");
    require(
      quantity <= MAX_ITEMS_PER_WALLET,
      "Requested quantity more than maximum allowed per wallet"
    );
    require(
      AVAILABLE_FOR_MINT >= quantity,
      "Requested quantity will exceed the limit of available for sale"
    );
    // Transaction must have at least quantity * price (any more is considered a tip)
    require(quantity * MINT_PRICE <= msg.value, "Not enough ether sent");
    require(super.totalSupply() + quantity <= MAX_SUPPLY, "Total supply will exceed the limit");

    require(
      balanceOf(msg.sender) < MAX_ITEMS_PER_WALLET,
      "Wallet already owns maximum allowed items"
    );

    for (uint256 i = 0; i < quantity; i++) {
      _safeMint(msg.sender, _tokenIdCounter.current());
      _tokenIdCounter.increment();
      AVAILABLE_FOR_MINT = AVAILABLE_FOR_MINT - 1;
    }

    emit PublicSaleMint(msg.sender, quantity);
  }

  function _baseURI() internal view virtual override(ERC721) returns (string memory) {
    return "https://niftystonks.io/api/licenses/";
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    require(presaleStarted || publicSaleStarted, "Sale has not been started");

    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}