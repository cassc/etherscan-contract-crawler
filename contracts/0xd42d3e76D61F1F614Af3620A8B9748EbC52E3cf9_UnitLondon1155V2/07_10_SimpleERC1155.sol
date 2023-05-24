// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./IOwnable.sol";

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155Receiver is IERC165 {
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4);
}

abstract contract SimpleERC1155 is DefaultOperatorFiltererUpgradeable, IOwnable {
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );
  event ApprovalForAll(address indexed account, address indexed operator, bool approved);
  event URI(string value, uint256 indexed id);

  address implementation_;
  address public admin;

  string public name;
  string public symbol;

  mapping(uint256 => mapping(address => uint256)) private _balances;
  mapping(address => mapping(address => bool)) public isApprovedForAll;

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  function owner() external view override returns (address) {
    return admin;
  }

  function transferOwnership(address newOwner) public virtual {
    require(msg.sender == admin);
    admin = newOwner;
    emit OwnershipTransferred(msg.sender, newOwner);
  }

  function supportsInterface(bytes4) external pure returns (bool supported) {
    supported = true;
  }

  function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
    require(account != address(0), "ERC1155: balance query for the zero address");
    return _balances[id][account];
  }

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    returns (uint256[] memory)
  {
    require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    require(msg.sender != operator, "ERC1155: setting approval status for self");
    isApprovedForAll[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    require(from == msg.sender || isApprovedForAll[from][msg.sender], "ERC1155: caller is not owner nor approved");
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    require(
      from == msg.sender || isApprovedForAll[from][msg.sender],
      "ERC1155: transfer caller is not owner nor approved"
    );
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

    _balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }

    emit TransferSingle(operator, from, address(0), id, amount);
  }

  function _burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = msg.sender;

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
    }

    emit TransferBatch(operator, from, address(0), ids, amounts);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.code.length != 0) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.code.length != 0) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }

  // function burn(
  //   address account,
  //   uint256 id,
  //   uint256 value
  // ) public virtual {
  //   require(
  //     account == msg.sender || isApprovedForAll[account][msg.sender],
  //     "ERC1155: caller is not owner nor approved"
  //   );

  //   _burn(account, id, value);
  // }

  // function burnBatch(
  //   address account,
  //   uint256[] memory ids,
  //   uint256[] memory values
  // ) public virtual {
  //   require(
  //     account == msg.sender || isApprovedForAll[account][msg.sender],
  //     "ERC1155: caller is not owner nor approved"
  //   );

  //   _burnBatch(account, ids, values);
  // }

  function uri(uint256) external view virtual returns (string memory);
}