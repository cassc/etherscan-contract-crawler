// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @title Simple ERC721 interface with only necessary function for checking presale criteria
interface PresaleContract721Interface {
  function balanceOf(address owner) external view returns (uint256 balance);
}

/// @title Simple ERC1155 interface with only necessary functions for checking presale criteria
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

struct PresaleContract {
  address contractAddress;
  uint256[] tokenIds;
}

/// @title Generative Collection contract with payment splitter, presale, reservation, and access control built in.abi
/// @dev This contract inherits both AccessControl and Ownable.
/// AccessControl is used for limiting access to the contract's functionalities.
/// Ownable is used for setting the current owner of the contract making it easier to
/// deal with secondary markets like OpenSea for claiming ownership and setting royalty info off-chain.
contract GenerativeCollectionUpdateableWhitelist is
  ERC721,
  ERC721URIStorage,
  ERC721Burnable,
  Pausable,
  AccessControl,
  PaymentSplitter,
  Ownable,
  ReentrancyGuard
{
  uint256 private _tokenIdCounter = 1;
  uint256 private _burnCount = 0;
  string private _metadataBaseURI;

  uint256 public immutable maxSupply;
  uint256 public constant MAX_NFT_PURCHASEABLE = 6;
  uint256 public constant MAX_PRESALE_MINTING = 10;

  uint256 private _reserved = 100;
  uint256 private _mintPrice = 0.05 ether;

  bool private _isPresale = true;

  PresaleContract[] private _presaleContracts;
  mapping(address => uint256) private _presaleMintedAddresses;

  uint256 private _numberOfPayees;

  // @dev maps from user address to number of mints allowed for presale
  mapping(address => uint256) public presaleWhitelistForUsers;

  constructor(
    address[] memory payees,
    uint256[] memory shares,
    address owner_,
    string memory name,
    string memory symbol_,
    string memory baseUri,
    uint256 mintPrice,
    uint256 maxSupply_,
    uint256 reservedAmount
  ) ERC721(name, symbol_) PaymentSplitter(payees, shares) {
    _transferOwnership(owner_);
    _grantRole(DEFAULT_ADMIN_ROLE, owner_);

    _numberOfPayees = payees.length;
    _metadataBaseURI = baseUri;
    _mintPrice = mintPrice;
    maxSupply = maxSupply_;
    _reserved = reservedAmount;

    _pause();
  }

  modifier whenNotExceededMaxPresaleMintLimit(
    address sender,
    uint256 numberOfTokens
  ) {
    uint256 presaleWhitelistMints = presaleWhitelistForUsers[sender];
    bool isPresale_ = _isPresale;

    if (isPresale_ && presaleWhitelistMints == 0) {
      require(
        _presaleMintedAddresses[sender] + numberOfTokens <= MAX_PRESALE_MINTING,
        'Presale mint limit reached'
      );
    } else if (isPresale_ && (presaleWhitelistMints > 0)) {
      require(
        numberOfTokens <= presaleWhitelistMints,
        'Requested more mints than allowed for presale'
      );
    }

    _;
  }

  modifier whenPresale(address sender) {
    if (_isPresale) {
      bool isEligible = determineIsEligibleForPresale(sender);

      if (!isEligible) {
        revert NotEligiblePresale();
      }
    }

    _;
  }

  modifier whenAmountIsZero(uint256 numberOfTokens) {
    require(numberOfTokens != 0, 'Mint amount cannot be zero');

    _;
  }

  modifier whenNotExceedMaxPurchaseable(uint256 numberOfTokens) {
    if (numberOfTokens < 0 || numberOfTokens > MAX_NFT_PURCHASEABLE) {
      revert ExceededMaxPurchaseable();
    }

    _;
  }

  modifier whenNotExceedMaxSupply(uint256 numberOfTokens) {
    if (
      totalSupply() + numberOfTokens > (maxSupplyWithBurnCount() - _reserved)
    ) {
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

  // @dev only being used in whenPresale modifier, to allow early returns
  // @dev could possibly be inlined
  // @return boolean, whether or not address is eligible
  function determineIsEligibleForPresale(address sender)
    internal
    view
    returns (bool)
  {
    if (presaleWhitelistForUsers[sender] > 0) {
      return true;
    }

    // caching array length
    uint256 presaleContractsLength = _presaleContracts.length;
    for (uint256 i = 0; i < presaleContractsLength; i++) {
      PresaleContract memory presaleContract = _presaleContracts[i];

      // check if presale address is a contract
      if (!(presaleContract.contractAddress.code.length > 0)) {
        break;
      }

      if (
        // ERC721 presale
        presaleContract.tokenIds.length == 0 &&
        PresaleContract721Interface(presaleContract.contractAddress).balanceOf(
          sender
        ) >
        0
      ) {
        return true;
      } else if (presaleContract.tokenIds.length > 0) {
        // ERC1155
        // compile the array of addresses for the batch call
        address[] memory addresses = new address[](
          presaleContract.tokenIds.length
        );

        uint256 addressesLength = addresses.length;
        for (uint256 j = 0; j < addressesLength; j++) {
          addresses[j] = sender;
        }

        // check balances of tokens for user
        uint256[] memory balances = PresaleContract1155Interface(
          presaleContract.contractAddress
        ).balanceOfBatch(addresses, presaleContract.tokenIds);

        uint256 balancesLength = balances.length;
        for (uint256 k = 0; k < balancesLength; k++) {
          if (balances[k] > 0) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// @dev Takes into account of the burnt tokens. This is used by etherscan to display the total supply of the NFT collection
  /// @return Total supply of the minted tokens
  function totalSupply() public view returns (uint256) {
    // token supply starts at 1
    return _tokenIdCounter - _burnCount - 1;
  }

  function maxSupplyWithBurnCount() internal view returns (uint256) {
    return maxSupply - _burnCount;
  }

  function updatePresaleWhitelist(
    address[] calldata _addresses,
    uint256[] calldata _mints
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      _addresses.length == _mints.length,
      'Addresses and mints should have same length'
    );

    uint256 length = _addresses.length;
    for (uint256 i = 0; i < length; i++) {
      presaleWhitelistForUsers[_addresses[i]] = _mints[i];
    }
  }

  /// @notice Mint the given number of NFTs to the msg.sender
  /// @param numberOfTokens The number of NFTs to be minted
  function mintNft(uint256 numberOfTokens)
    external
    payable
    whenNotPaused
    nonReentrant
    whenNotExceededMaxPresaleMintLimit(msg.sender, numberOfTokens)
    whenPresale(msg.sender)
    whenAmountIsZero(numberOfTokens)
    whenNotExceedMaxPurchaseable(numberOfTokens)
    whenNotExceedMaxSupply(numberOfTokens)
    hasEnoughEther(numberOfTokens)
  {
    // keep track of who has minted in presale to limit presale minting
    if (_isPresale) {
      _presaleMintedAddresses[msg.sender] += numberOfTokens;
      presaleWhitelistForUsers[msg.sender] -= numberOfTokens;
    }

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < maxSupplyWithBurnCount()) {
        _safeMint(msg.sender, _tokenIdCounter);

        // Safety:
        // token ID counter is never able to come close to an uint256 overflow
        unchecked {
          _tokenIdCounter++;
        }
      }
    }
  }

  /// @notice Mint directly to another wallet address
  /// @dev This is used by third party service to mint directly to another address
  /// @param numberOfTokens The number of NFTs to be minted
  /// @param recipient Address of the target wallet to mint to
  function mintNftTo(uint256 numberOfTokens, address recipient)
    external
    payable
    nonReentrant
    whenNotPaused
    whenNotExceededMaxPresaleMintLimit(recipient, numberOfTokens)
    whenPresale(recipient)
    whenAmountIsZero(numberOfTokens)
    whenNotExceedMaxPurchaseable(numberOfTokens)
    whenNotExceedMaxSupply(numberOfTokens)
    hasEnoughEther(numberOfTokens)
  {
    if (_isPresale) {
      _presaleMintedAddresses[recipient] += numberOfTokens;
      presaleWhitelistForUsers[recipient] -= numberOfTokens;
    }

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < maxSupplyWithBurnCount()) {
        _safeMint(recipient, _tokenIdCounter);

        // Safety:
        // token ID counter is never able to come close to an uint256 overflow
        unchecked {
          _tokenIdCounter++;
        }
      }
    }
  }

  /// @notice Pre-mint number of NFTs to an address. Admin only.
  /// @dev Mint reserved NFTs to a specified wallet. Decreases the number of available reserved amount.
  /// @param to Address of the target wallet to mint to
  /// @param numberOfTokens The number of NFTs to be minted
  function giveAwayNft(address to, uint256 numberOfTokens)
    external
    nonReentrant
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(numberOfTokens <= _reserved, 'Exceeds reserved supply');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < maxSupplyWithBurnCount()) {
        _safeMint(to, _tokenIdCounter);

        // Safety:
        // token ID counter is never able to come close to an uint256 overflow
        unchecked {
          _tokenIdCounter++;
        }
      }
    }

    _reserved -= numberOfTokens;
  }

  /// @notice Ends presale period to start main sale. Admin only.
  function endPresale() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_isPresale, 'Presale already ended');
    _isPresale = false;
  }

  /// @return The boolean state of presale for the contract
  function isPresale() external view virtual returns (bool) {
    return _isPresale;
  }

  /// @notice Add presale contract (ERC721 or ERC1155) for targeting during presale period. Admin only.
  /// @dev ERC721: Leave the tokenIds array as empty. ERC1155, add token IDs that we want to target
  /// @param contractAddress Address of an ERC721 or ERC1155 smart contract for presale
  /// @param tokenIds Array of token IDs to be considered for presale
  function addPresaleContract(
    address contractAddress,
    uint256[] memory tokenIds
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _presaleContracts.push(
      PresaleContract({ contractAddress: contractAddress, tokenIds: tokenIds })
    );
  }

  /// @notice Clear all of the presale contracts. Admin only.
  /// @dev For resetting the presale list of contracts and starting over
  function clearPresaleContracts() external onlyRole(DEFAULT_ADMIN_ROLE) {
    // reset the presale contracts array
    delete _presaleContracts;
  }

  /// @notice Get the list of presale contracts
  /// @return Array of presale contracts stored on-chain
  function getPresaleContracts()
    external
    view
    returns (PresaleContract[] memory)
  {
    return _presaleContracts;
  }

  /// @notice Get the current mint price for minting an NFT
  /// @return Current mint price stored on-chain
  function getMintPrice() external view returns (uint256) {
    return _mintPrice;
  }

  /// @notice Set new mint price, override the current one. Admin only.
  /// @param newPrice New mint price
  function setMintPrice(uint256 newPrice)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _mintPrice = newPrice;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataBaseURI;
  }

  /// @notice Get the current token's base URI stored on-chain
  /// @return String of the current stored base URI
  function baseURI() external view virtual returns (string memory) {
    return _baseURI();
  }

  /// @notice Set new base URI. Admin only.
  /// @param baseUri New string of the base URI for NFT
  function setBaseURI(string memory baseUri)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _metadataBaseURI = baseUri;
  }

  /// @notice Get the current token's base URI stored on-chain
  /// @return String of the current stored base URI
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  /// @notice Pause the contract disable minting. Admin only.
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpause the contract to allow minting. Admin only.
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);

    // Safety:
    // token ID counter is never able to come close to an uint256 overflow
    unchecked {
      _burnCount++;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /// @notice Withdraw the contract's fund and split the payment amongst the list of payees. Admin only.
  /// @dev Loops through all of the payees and release funding based on the payee's share
  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < _numberOfPayees; i++) {
      release(payable(payee(i)));
    }
  }

  receive() external payable override(PaymentSplitter) {
    emit PaymentReceived(_msgSender(), msg.value);
  }
}