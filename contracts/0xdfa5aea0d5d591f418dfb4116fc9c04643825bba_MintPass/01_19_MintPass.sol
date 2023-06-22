// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

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

error TokenNonexistent();
error NotEnoughEther();
error InputLengthsNotMatching();
error AmountCannotBeZero();
error ExceededMaxSupply();
error ExceededMaxPurchaseable();
error ExceededPresaleMintLimit();
error PresaleNotEligible();

struct MintPassInfo {
  uint256 maxSupply;
  uint256 currentSupply;
  uint256 mintPrice;
  uint256 mintLimit; // mint limit per tx. 0 works as pause.
}

struct PresaleContract {
  address contractAddress;
  uint256[] tokenIds;
}

contract MintPass is
  ERC1155,
  ERC1155Burnable,
  ERC1155Supply,
  AccessControl,
  PaymentSplitter,
  Ownable,
  ReentrancyGuard
{
  uint256 public constant MAX_PRESALE_MINTING = 1;
  string public name;
  string public symbol;

  string internal _baseURI;
  uint256 private _tokenIdCounter = 1;
  bool private _isPresale = true;

  mapping(uint256 => MintPassInfo) public mintPasses;

  PresaleContract[] private _presaleContracts;
  mapping(address => uint256) private _presaleMintedAddresses;

  uint256 private _numberOfPayees;

  constructor(
    address[] memory payees,
    uint256[] memory shares,
    address owner_,
    string memory name_,
    string memory symbol_,
    string memory baseUri
  ) ERC1155('') PaymentSplitter(payees, shares) {
    _transferOwnership(owner_);
    _grantRole(DEFAULT_ADMIN_ROLE, owner_);

    _numberOfPayees = payees.length;

    name = name_;
    symbol = symbol_;

    _baseURI = baseUri;
  }

  /*** Presale ***/

  modifier whenNotExceededMaxPresaleMintLimit(
    address sender,
    uint256 numberOfTokens
  ) {
    if (
      _isPresale &&
      _presaleMintedAddresses[sender] + numberOfTokens > MAX_PRESALE_MINTING
    ) {
      revert ExceededPresaleMintLimit();
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

      if (!isEligible) revert PresaleNotEligible();
    }

    _;
  }

  function endPresale() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_isPresale, 'Presale already ended');
    _isPresale = false;
  }

  function isPresale() external view virtual returns (bool) {
    return _isPresale;
  }

  function addPresaleContract(
    address contractAddress,
    uint256[] memory tokenIds
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _presaleContracts.push(
      PresaleContract({ contractAddress: contractAddress, tokenIds: tokenIds })
    );
  }

  function clearPresaleContracts() external onlyRole(DEFAULT_ADMIN_ROLE) {
    // reset the presale contracts array
    delete _presaleContracts;
  }

  function getPresaleContracts()
    external
    view
    returns (PresaleContract[] memory)
  {
    return _presaleContracts;
  }

  /*** Minting ***/

  /**
   * @notice Adds new mint pass.
   */
  function addMintPass(
    uint256[] calldata maxSupplies,
    uint256[] calldata mintPrices
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (maxSupplies.length != mintPrices.length) {
      revert InputLengthsNotMatching();
    }

    for (uint256 i = 0; i < maxSupplies.length; i++) {
      uint256 tokenId = _tokenIdCounter;
      unchecked {
        ++_tokenIdCounter;
      }

      mintPasses[tokenId] = MintPassInfo({
        maxSupply: maxSupplies[i],
        currentSupply: 0,
        mintPrice: mintPrices[i],
        mintLimit: 0 // default to 0 or pause state
      });
    }
  }

  /**
   * @notice Sets `mintLimit` of `tokenIds`.
   *
   * Setting `mintLimit` from 0 is equivalent to pausing mint for specified token ID.
   */
  function setMintLimit(
    uint256[] calldata tokenIds,
    uint256[] calldata mintLimits
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      tokenIds.length == mintLimits.length,
      'input array lengths must be the same'
    );

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (tokenId >= _tokenIdCounter) {
        revert TokenNonexistent();
      }

      mintPasses[tokenId].mintLimit = mintLimits[i];
    }
  }

  /**
   * @notice Mints ignoring the mint limit and price.
   */
  function devMint(
    address account,
    uint256 id,
    uint256 amount
  ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (id >= _tokenIdCounter) {
      revert TokenNonexistent();
    }

    MintPassInfo storage mintPassInfo = mintPasses[id];
    uint256 newSupply = mintPassInfo.currentSupply + amount;

    if (newSupply > mintPassInfo.maxSupply) {
      revert ExceededMaxSupply();
    }

    mintPassInfo.currentSupply = newSupply;

    _mint(account, id, amount, '');
  }

  /**
   * @dev Mint Passes.
   */
  function mint(
    address account,
    uint256 id,
    uint256 amount
  )
    external
    payable
    nonReentrant
    whenNotExceededMaxPresaleMintLimit(msg.sender, amount)
    whenPresale(msg.sender)
  {
    if (amount == 0) {
      revert AmountCannotBeZero();
    }

    if (id >= _tokenIdCounter) {
      revert TokenNonexistent();
    }

    MintPassInfo storage mintPassInfo = mintPasses[id];

    // can only mint up to mint limit set per tier of NFT per tx
    // admin can mint more than limit per tx
    if (
      amount > mintPassInfo.mintLimit &&
      !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())
    ) {
      revert ExceededMaxPurchaseable();
    }

    if (msg.value < mintPassInfo.mintPrice * amount) {
      revert NotEnoughEther();
    }

    uint256 newSupply = mintPassInfo.currentSupply + amount;
    if (newSupply > mintPassInfo.maxSupply) {
      revert ExceededMaxSupply();
    }

    mintPassInfo.currentSupply = newSupply;

    _mint(account, id, amount, '');

    // keep track of who has minted in presale to limit presale minting
    if (_isPresale) {
      _presaleMintedAddresses[msg.sender] += amount;
    }
  }

  /*** Token URI setter and getter ***/

  function setURI(string memory newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _baseURI = newuri;
  }

  function baseURI() external view virtual returns (string memory) {
    return _baseURI;
  }

  function uri(uint256 _id) public view override returns (string memory) {
    require(_id < _tokenIdCounter, 'Nonexistent token');

    return string(abi.encodePacked(_baseURI, Strings.toString(_id)));
  }

  /*** The following functions are overrides required by Solidity ***/

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
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