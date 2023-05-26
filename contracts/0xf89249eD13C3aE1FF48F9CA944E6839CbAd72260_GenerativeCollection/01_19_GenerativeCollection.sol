// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface PresaleContract721Interface {
  function balanceOf(address owner) external view returns (uint256 balance);
}

interface PresaleContract1155Interface {
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    external
    view
    returns (uint256[] memory);
}

error NotEnoughEther();
error NotEligiblePresale();
error ExceededMaxSupply();
error ExceededMaxPurchaseable();

contract GenerativeCollection is
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  ERC721Burnable,
  ReentrancyGuard,
  Pausable,
  AccessControl
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  string private _metadataBaseURI;

  uint256 public constant MAX_SUPPLY = 4444;
  uint256 public constant MAX_NFT_PURCHASEABLE = 20;
  uint256 public constant MAX_PRESALE_MINTING = 10;

  uint256 private _reserved = 200;
  uint256 private _mintPrice = 0.08 ether;

  bool private _isPresale = false;

  struct PresaleContract {
    address contractAddress;
    uint256[] tokenIds;
  }
  PresaleContract[] private _presaleContracts;
  mapping(address => uint256) private _presaleMintedAddresses;

  constructor() ERC721("Kevin The Monkey", "KTM") {
    _metadataBaseURI = "/";

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    // increment so first minted ID is 1
    _tokenIdCounter.increment();

    pause();
  }

  modifier whenNotExceededMaxPresaleMintLimit(
    address sender,
    uint256 numberOfTokens
  ) {
    if (_isPresale) {
      require(
        _presaleMintedAddresses[sender] + numberOfTokens <= MAX_PRESALE_MINTING,
        "Presale mint limit reached"
      );
    }

    _;
  }

  modifier whenPresale(address sender) {
    if (_isPresale) {
      bool isEligible = false;
      for (uint256 i = 0; i < _presaleContracts.length; i++) {
        // check if presale address is a contract
        if (!(_presaleContracts[i].contractAddress.code.length > 0)) {
          break;
        }

        if (
          // ERC721 presale
          _presaleContracts[i].tokenIds.length == 0 &&
          PresaleContract721Interface(_presaleContracts[i].contractAddress)
            .balanceOf(sender) >
          0
        ) {
          isEligible = true;
          break;
        } else if (_presaleContracts[i].tokenIds.length > 0) {
          // ERC1155
          // compile the array of addresses for the batch call
          address[] memory addresses = new address[](
            _presaleContracts[i].tokenIds.length
          );
          for (uint256 j = 0; j < addresses.length; j++) {
            addresses[j] = sender;
          }

          // check balances of tokens for user
          uint256[] memory balances = PresaleContract1155Interface(
            _presaleContracts[i].contractAddress
          ).balanceOfBatch(addresses, _presaleContracts[i].tokenIds);

          for (uint256 k = 0; k < balances.length; k++) {
            if (balances[k] > 0) {
              isEligible = true;
              break;
            }
          }
        }
      }

      if (!isEligible) {
        revert NotEligiblePresale();
      }
    }

    _;
  }

  modifier whenAmountIsZero(uint256 numberOfTokens) {
    require(numberOfTokens != 0, "Mint amount cannot be zero");

    _;
  }

  modifier whenNotExceedMaxPurchaseable(uint256 numberOfTokens) {
    if (numberOfTokens < 0 || numberOfTokens > MAX_NFT_PURCHASEABLE) {
      revert ExceededMaxPurchaseable();
    }

    _;
  }

  modifier whenNotExceedMaxSupply(uint256 numberOfTokens) {
    if (totalSupply() + numberOfTokens > (MAX_SUPPLY - _reserved)) {
      revert ExceededMaxSupply();
    }

    _;
  }

  modifier hasEnoughEther(uint256 numberOfTokens) {
    if (msg.value < _mintPrice * numberOfTokens) {
      revert NotEnoughEther();
    }

    _;
  }

  function mintNft(uint256 numberOfTokens)
    public
    payable
    nonReentrant
    whenNotExceededMaxPresaleMintLimit(msg.sender, numberOfTokens)
    whenPresale(msg.sender)
    whenNotPaused
    whenAmountIsZero(numberOfTokens)
    whenNotExceedMaxPurchaseable(numberOfTokens)
    whenNotExceedMaxSupply(numberOfTokens)
    hasEnoughEther(numberOfTokens)
  {
    // keep track of who has minted in presale to limit presale minting
    if (_isPresale) {
      _presaleMintedAddresses[msg.sender] += numberOfTokens;
    }

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < MAX_SUPPLY) {
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
      }
    }
  }

  function mintNftTo(uint256 numberOfTokens, address recipient)
    public
    payable
    nonReentrant
    whenNotPaused
    whenAmountIsZero(numberOfTokens)
    whenNotExceedMaxPurchaseable(numberOfTokens)
    whenNotExceedMaxSupply(numberOfTokens)
    hasEnoughEther(numberOfTokens)
  {
    if (_isPresale) {
      revert NotEligiblePresale();
    }

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < MAX_SUPPLY) {
        _safeMint(recipient, _tokenIdCounter.current());
        _tokenIdCounter.increment();
      }
    }
  }

  function giveAwayNft(address to, uint256 numberOfTokens)
    public
    nonReentrant
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(numberOfTokens <= _reserved, "Exceeds reserved supply");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < MAX_SUPPLY) {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
      }
    }

    _reserved -= numberOfTokens;
  }

  function endPresale() public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_isPresale, "Presale already ended");
    _isPresale = false;
  }

  function isPresale() public view virtual returns (bool) {
    return _isPresale;
  }

  function addPresaleContract(
    address contractAddress,
    uint256[] memory tokenIds
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _presaleContracts.push(
      PresaleContract({ contractAddress: contractAddress, tokenIds: tokenIds })
    );
  }

  function clearPresaleContracts() public onlyRole(DEFAULT_ADMIN_ROLE) {
    // reset the presale contracts array
    delete _presaleContracts;
  }

  function getPresaleContracts()
    public
    view
    returns (PresaleContract[] memory)
  {
    return _presaleContracts;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokenIds;
  }

  function getMintPrice() public view returns (uint256) {
    return _mintPrice;
  }

  function setMintPrice(uint256 newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _mintPrice = newPrice;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataBaseURI;
  }

  function baseURI() public view virtual returns (string memory) {
    return _baseURI();
  }

  function setBaseURI(string memory baseUri)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _metadataBaseURI = baseUri;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = address(this).balance;
    // This forwards all available gas. Be sure to check the return value!
    (bool success, ) = msg.sender.call{ value: balance }("");

    require(success, "Transfer failed.");
  }

  receive() external payable {}
}