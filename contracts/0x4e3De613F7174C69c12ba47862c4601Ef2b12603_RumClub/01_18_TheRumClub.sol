//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol';

interface IBAPC {
  function balanceOf(address owner) external view returns (uint256);
}

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract RumClub is
  Initializable,
  ContextUpgradeable,
  OwnableUpgradeable,
  ERC1155SupplyUpgradeable,
  // ERC1155URIStorageUpgradeable,
  ERC1155BurnableUpgradeable,
  ERC1155PausableUpgradeable
{
  uint256 public constant MAX_SUPPLY = 5700;
  uint256 public constant MAX_BARREL_SUPPLY = 12;

  uint256 public constant PRICE_SMALL_PORTION = 0.024 ether;
  uint256 public constant PRICE_LARGE_PORTION = 0.038 ether;

  address private _verifier;
  IBAPC private _bapc;

  mapping(address => uint256) public minters;

  function initialize(
    IBAPC bapc_,
    address verifier_,
    string memory uri_
  ) public virtual initializer {
    __RumClub_init(bapc_, verifier_, uri_);
  }

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
   * deploys the contract.
   */
  function __RumClub_init(
    IBAPC bapc_,
    address verifier_,
    string memory uri_
  ) internal onlyInitializing {
    __Ownable_init();
    __ERC1155_init_unchained(uri_);
    __ERC1155Supply_init_unchained();
    __ERC1155Pausable_init_unchained();
    __ERC1155Burnable_init_unchained();

    __RumClub_init_unchained(bapc_, verifier_);
  }

  function __RumClub_init_unchained(IBAPC bapc, address verifier)
    internal
    onlyInitializing
  {
    _verifier = verifier;
    _bapc = bapc;
  }

  function _recoverSigner(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    return
      ECDSAUpgradeable.recover(
        ECDSAUpgradeable.toEthSignedMessageHash(hash),
        signature
      );
  }

  function _mintPortions(
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal {
    address wallet = _msgSender();

    require(_bapc.balanceOf(wallet) >= (p1 + p2), 'BAPC: Not enough BAPC');
    require(p3 <= 1, 'BAPC: invalid p3 amount');

    uint256 p1Supply = totalSupply(1);
    uint256 p2Supply = totalSupply(2);
    uint256 p3Supply = totalSupply(3);

    if (p3Supply + p3 > MAX_BARREL_SUPPLY) {
      p3 = 0;
    } else if (p3 > 0) {
      if (p2 > 0) {
        p2 -= 1;
      } else {
        p1 -= 1;
      }
    }

    require(
      p1Supply + p2Supply + p3Supply + p1 + p2 + p3 <= MAX_SUPPLY,
      'BAPC: max supply exceeded'
    );

    uint256[] memory ids = new uint256[](3);
    uint256[] memory amounts = new uint256[](3);

    uint256 index = 0;
    if (p1 > 0) {
      ids[index] = 1;
      amounts[index] = p1;
      index += 1;
    }
    if (p2 > 0) {
      ids[index] = 2;
      amounts[index] = p2;
      index += 1;
    }
    if (p3 > 0) {
      ids[index] = 3;
      amounts[index] = p3;
      index += 1;
    }

    uint256[] memory ids_filled = new uint256[](index);
    uint256[] memory amounts_filled = new uint256[](index);

    for (uint256 i = 0; i < index; i++) {
      ids_filled[i] = ids[i];
      amounts_filled[i] = amounts[i];
    }

    _mintBatch(wallet, ids_filled, amounts_filled, '');

    minters[wallet] += (p1 + p2 + p3);
  }

  function exchangeRum(
    uint256 amount,
    uint256 timestamp,
    bytes memory sig
  ) external {
    address wallet = _msgSender();

    require(amount <= balanceOf(wallet, 1), 'BAPC: Not enough small portions');

    bytes32 hash = keccak256(abi.encodePacked(wallet, amount, timestamp));
    require(_verifier == _recoverSigner(hash, sig), 'BAPC: invalid signature');

    _burn(wallet, 1, amount);
    _mint(wallet, 4, amount, '');
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  )
    internal
    virtual
    override(
      ERC1155Upgradeable,
      ERC1155SupplyUpgradeable,
      ERC1155PausableUpgradeable
    )
  {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function name() public pure returns (string memory) {
    return 'RumClub';
  }

  /**
   * Only Owner
   */

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC1155Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual onlyOwner {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC1155Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual onlyOwner {
    _unpause();
  }

  function mintReserved(
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) external onlyOwner {
    _mintPortions(p1, p2, p3);
  }

  function setVerifier(address verifier_) external onlyOwner {
    _verifier = verifier_;
  }

  function withdraw(uint256 amount) public onlyOwner {
    (bool success, ) = _msgSender().call{value: amount}('');
    require(success, 'Withdraw failed');
  }

  function withdrawAll() external onlyOwner {
    withdraw(address(this).balance);
  }

  function setURI(string memory newuri) external onlyOwner {
    _setURI(newuri);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}