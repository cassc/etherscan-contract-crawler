// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./abstracts/ShibaCardsDealable.sol";
import "./abstracts/ShibaCardsPayable.sol";
import "./abstracts/ShibaCardsDividendsDistributable.sol";
import "./interfaces/IDealer.sol";
import "./interfaces/IBank.sol";

contract ShibaCards is
  ERC1155Pausable,
  ShibaCardsDividendsDistributable,
  ShibaCardsPayable,
  ShibaCardsDealable
{
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private nonce;

  event Gifted(address indexed to, uint256 amount);
  event Minted(address indexed to, uint256[] ids, uint256 shares);

  uint256[] internal amounts = [1,1,1];
  uint32 public constant BOOSTER = 3;
  mapping(uint256 => address) internal _requestByID;
  mapping(address => uint256) internal _freeMints;

  constructor(string memory _uri) ERC1155(_uri) {}

  /**
   * @dev See {ERC1155-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory _amounts,
    bytes memory data
  ) internal override {
    super._beforeTokenTransfer(operator, from, to, ids, _amounts, data);

    if (from != address(0) && to != address(0)) {
      for (uint256 i; i < ids.length; i++) {
          dividendsDistributer.transferShares(
            from,
            to,
            dealer.getSharesOf(ids[i]) * _amounts[i]
          );
      }
    }
  }

  function mintSpecific(
    address to,
    uint256[] memory ids,
    uint256[] memory _amounts
  ) external onlyWhitelistedOrAdmin {
    uint256 totalShares;
    for (uint256 i = 0; i < ids.length; i++) {
      totalShares += dealer.getSharesOf(ids[i]) * _amounts[i];
    }
    dividendsDistributer.addShares(to, totalShares);
    _mintBatch(to, ids, _amounts, "");
  }

  function burn(
    uint256 id,
    uint256 amount
  ) public {
    _burn(_msgSender(), id, amount);
    dividendsDistributer.removeShares(_msgSender(), dealer.getSharesOf(id).mul(amount));
  }

  function burn(
    address from,
    uint256 id,
    uint256 amount
  ) public onlyWhitelisted {
    _burn(from, id, amount);
    dividendsDistributer.removeShares(from, dealer.getSharesOf(id).mul(amount));
  }

  /**
   * @dev Mints booster packs with multiple random tokens.
   */
  function mint() public payable virtual {
    address to = _msgSender();
    uint256 payment = getFees();

    if (_freeMints[to] > 0) {
      payment = 0;
      _freeMints[to] -= 1;
    }

    if (payment > 0) {
      bank.makePayment(to, payment);
      bank.distribute(payment);
    }

    (uint256[] memory ids, uint256 shares) = dealer.getIdsAndShares(rnds(BOOSTER));

    dividendsDistributer.addShares(to, shares);

    _mintBatch(to, ids, amounts, "");

    emit Minted(to, ids, shares);
  }

  /**
   * @dev Shows free mints of account.
   */
  function getFreeMints(address account) public view returns(uint256) {
    return _freeMints[account];
  }

  /**
   * @dev gifts a free mint token to someone else
   */
  function gift(address to, uint256 amount) public {
    if (!isAdmin(_msgSender()) && !isWhitelisted(_msgSender())) {
      bank.makePayment(_msgSender(), getFees() * amount);
    }
    _freeMints[to] += amount;
    emit Gifted(to, amount);
  }

  function rnds(uint256 amount) internal returns (uint256[] memory) {
    uint256[] memory vals = new uint256[](amount);

    for (uint256 index = 0; index < amount; index++) {  
      vals[index] = uint256(keccak256(abi.encodePacked(nonce.current())));
      nonce.increment();
    }

    return vals;
  }

  /**
   * @dev Pauses transactions.
   */
  function pause() public onlyAdmin {
    _pause();
  }

  /**
   * @dev Continues transactions.
   */
  function unpause() public onlyAdmin {
    _unpause();
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC1155)
    returns (bool)
  {
    return ERC1155.supportsInterface(interfaceId);
  }

  /**
   * @dev Update URI.
   */
  function setURI(string memory _uri) public onlyAdmin {
    _setURI(_uri);
  }

  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    // Whitelist ShibaCards contract for easy trading.
    if (isWhitelisted(_operator)) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }
}