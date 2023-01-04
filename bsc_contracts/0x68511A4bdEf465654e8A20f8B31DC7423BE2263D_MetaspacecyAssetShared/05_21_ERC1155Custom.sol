// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../access/Ownable.sol";
import "../token/ERC1155/ERC1155.sol";
import "../utils/math/SafeMath.sol";
import "../utils/libraries/Strings.sol";

import "./meta-transaction/ContextMixin.sol";
import "./meta-transaction/NativeMetaTransaction.sol";
import "../utils/Pausable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC1155Custom is ContextMixin, ERC1155, NativeMetaTransaction, Ownable, Pausable {
  using Address for address;

  address public proxyRegistryAddress;
  string public name;
  string public symbol;

  mapping(uint256 => mapping(address => uint256)) private balances;
  mapping(uint256 => uint256) private _supply;

  event URI(string _uri, uint256 indexed _id);

  modifier onlyOwnerOrProxy() {
    require(
      _isOwnerOrProxy(_msgSender()),
      "ERC1155Custom: not owner"
    );
    _;
  }

  modifier onlyApproved(address _from) {
    require(
      _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
      "ERC1155Custom: not allow"
    );
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    address _proxyRegistryAddress
  ) ERC1155(_uri) {
    name = _name;
    symbol = _symbol;
    proxyRegistryAddress = _proxyRegistryAddress;
    _initializeEIP712(name);
  }

  function _isOwnerOrProxy(address _address) internal view returns (bool) {
    return owner() == _address || _isProxyForUser(owner(), _address);
  }

  function pause() external onlyOwnerOrProxy {
    _pause();
  }

  function unpause() external onlyOwnerOrProxy {
    _unpause();
  }

  function balanceOf(address account, uint256 id)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(account != address(0), "ERC1155Custom: zero address");
    return balances[id][account];
  }

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override
    returns (uint256[] memory)
  {
    require(
      accounts.length == ids.length,
      "ERC1155Custom: accounts and ids length mismatch"
    );

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @dev Returns the total quantity for a token ID
   * @param _id Id of token to query
   * @return Amount of token in existence
   */
  function totalSupply(uint256 _id) public view returns (uint256) {
    return _supply[_id];
  }

  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    if (_isProxyForUser(_owner, _operator)) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override whenNotPaused onlyApproved(from) {
    require(to != address(0), "ERC1155Custom: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(
      operator,
      from,
      to,
      asSingletonArray(id),
      asSingletonArray(amount),
      data
    );

    uint256 fromBalance = balances[id][from];
    require(
      fromBalance >= amount,
      "ERC1155Custom: insufficient balance for transfer"
    );
    balances[id][from] = fromBalance - amount;
    balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override whenNotPaused onlyApproved(from) {
    require(
      ids.length == amounts.length,
      "ERC1155Custom: mismatch id-amount length"
    );
    require(to != address(0), "ERC1155Custom: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = balances[id][from];
      require(
        fromBalance >= amount,
        "ERC1155Custom: insufficient balance for transfer"
      );
      balances[id][from] = fromBalance - amount;
      balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    doSafeBatchTransferAcceptanceCheck(
      operator,
      from,
      to,
      ids,
      amounts,
      data
    );
  }

  /**
   * @dev Hook called before minting
   * @param _id Token ID to mint
   * @param _quantity Amount of tokens to mint
   */
  function _beforeMint(uint256 _id, uint256 _quantity) internal virtual {}

  /**
   * @dev Mints some amount of tokens to an address
   * @param _to Address of the future owner of the token
   * @param _id Token ID to mint
   * @param _quantity Amount of tokens to mint
   * @param _data Data to pass if receiver is contract
   */
  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) public virtual onlyOwnerOrProxy {
    _mint(_to, _id, _quantity, _data);
  }

  /**
   * @dev Mint tokens for each id in _ids
   * @param _to The address to mint tokens to
   * @param _ids Array of ids to mint
   * @param _quantities Array of amounts of tokens to mint per id
   * @param _data Data to pass if receiver is contract
   */
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) public virtual onlyOwnerOrProxy {
    _batchMint(_to, _ids, _quantities, _data);
  }

  /**
   * @dev Burns amount of a given token id
   * @param _from The address to burn tokens from
   * @param _id Token ID to burn
   * @param _quantity Amount to burn
   */
  function burn(
    address _from,
    uint256 _id,
    uint256 _quantity
  ) public virtual onlyApproved(_from) {
    _burn(_from, _id, _quantity);
  }

  /**
   * @dev Burns tokens for each id in _ids
   * @param _from The address to burn tokens from
   * @param _ids Array of token ids to burn
   * @param _quantities Array of the amount to be burned
   */
  function batchBurn(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _quantities
  ) public virtual onlyApproved(_from) {
    _burnBatch(_from, _ids, _quantities);
  }

  /**
   * @dev Returns whether the specified token is minted
   */
  function exists(uint256 _id) public view returns (bool) {
    return _supply[_id] > 0;
  }

  function _mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal virtual override whenNotPaused {
    address operator = _msgSender();

    _beforeTokenTransfer(
      operator,
      address(0),
      _to,
      asSingletonArray(_id),
      asSingletonArray(_amount),
      _data
    );

    _beforeMint(_id, _amount);

    balances[_id][_to] += _amount;
    _supply[_id] += _amount;

    emit TransferSingle(operator, address(0), _to, _id, _amount);

    doSafeTransferAcceptanceCheck(
      operator,
      address(0),
      _to,
      _id,
      _amount,
      _data
    );
  }

  function _batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) internal virtual whenNotPaused {
    require(
      _ids.length == _amounts.length,
      "invalid array length"
    );

    uint256 nMint = _ids.length;

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), _to, _ids, _amounts, _data);

    for (uint256 i = 0; i < nMint; i++) {
      uint256 id = _ids[i];
      uint256 amount = _amounts[i];
      _beforeMint(id, amount);
      balances[id][_to] += amount;
      _supply[id] += amount;
    }

    emit TransferBatch(operator, address(0), _to, _ids, _amounts);

    doSafeBatchTransferAcceptanceCheck(
      operator,
      address(0),
      _to,
      _ids,
      _amounts,
      _data
    );
  }

  function _burn(
    address account,
    uint256 id,
    uint256 amount
  ) internal override whenNotPaused {
    require(account != address(0), "burn from zero address");
    require(amount > 0, "burn amount <= 0");

    address operator = _msgSender();

    _beforeTokenTransfer(
      operator,
      account,
      address(0),
      asSingletonArray(id),
      asSingletonArray(amount),
      ""
    );

    uint256 accountBalance = balances[id][account];
    require(
      accountBalance >= amount,
      "burn amount > balance"
    );
    balances[id][account] = accountBalance - amount;
    _supply[id] -= amount;

    emit TransferSingle(operator, account, address(0), id, amount);
  }

  function _burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal override whenNotPaused {
    require(account != address(0), "furn from zero address");
    require(
      ids.length == amounts.length,
      "mismatch id-amount length"
    );

    address operator = _msgSender();

    _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 accountBalance = balances[id][account];
      require(
        accountBalance >= amount,
        "burn amount > balance"
      );
      balances[id][account] = accountBalance - amount;
      _supply[id] -= amount;
    }

    emit TransferBatch(operator, account, address(0), ids, amounts);
  }

  function _isProxyForUser(address _user, address _address)
    internal
    view
    virtual
    returns (bool)
  {
    if (!proxyRegistryAddress.isContract()) {
      return false;
    }
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    return address(proxyRegistry.proxies(_user)) == _address;
  }

  function doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try
        IERC1155Receiver(to).onERC1155Received(
          operator,
          from,
          id,
          amount,
          data
        )
      returns (bytes4 response) {
        if (
          response != IERC1155Receiver(to).onERC1155Received.selector
        ) {
          revert("ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("Transfer to non ERC1155Receiver");
      }
    }
  }

  function doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try
        IERC1155Receiver(to).onERC1155BatchReceived(
          operator,
          from,
          ids,
          amounts,
          data
        )
      returns (bytes4 response) {
        if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
          revert("ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("Transfer to non ERC1155Receiver");
      }
    }
  }

  function asSingletonArray(uint256 element)
    private
    pure
    returns (uint256[] memory)
  {
    uint256[] memory array = new uint256[](1);
    array[0] = element;
    return array;
  }

  function _msgSender() internal view override returns (address sender) {
    return ContextMixin.msgSender();
  }
}