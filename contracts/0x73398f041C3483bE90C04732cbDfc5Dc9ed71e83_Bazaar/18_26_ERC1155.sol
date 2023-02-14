// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


/**
 * @dev Implementation of the basic standard multi-token.
 * see https://eips.ethereum.org/EIPS/eip-1155
 * based on https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155
 */
contract ERC1155 is ERC165, IERC1155, ReentrancyGuard {
    using Address for address;

    /// cannot use the zero address
    error InvalidAddress();

    /// owner `owner` does not have sufficient amount of token `id`; requested `requested`, but has only `owned` is owned
    error InsufficientTokens(uint id, address owner, uint owned, uint requested);

    /// sender `operator` is not owner nor approved to transfer
    error UnauthorizedTransfer(address operator);

    /// receiver `receiver` has rejected token(s) transfer`
    error ERC1155ReceiverRejectedTokens(address receiver);

    mapping(uint => mapping(address => uint)) internal balances; // tokenId => account => balance
    mapping(address => mapping(address => bool)) internal operatorApprovals; // account => operator => approval

    modifier valid(address account) { if (account == address(0)) revert InvalidAddress(); _; }

    modifier canTransfer(address from) { if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert UnauthorizedTransfer(msg.sender); _; }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address account, uint id) public view virtual override valid(account) returns (uint) {
        return balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint[] memory ids) external view virtual override returns (uint[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint[] memory batchBalances = new uint[](accounts.length);
        for (uint i = 0; i < accounts.length; ++i) batchBalances[i] = balanceOf(accounts[i], ids[i]);
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev Approve `operator` to operate on all of `owner` tokens
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return operatorApprovals[account][operator];
    }

    /**
     * @dev transfer `amount` tokens of token type `id` from `from` to `to`.
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received}
     *   and return the acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) external virtual override nonReentrant canTransfer(from) valid(to) {
        _safeTransferFrom(from, to, id, amount, data);
        emit TransferSingle(msg.sender, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function _safeTransferFrom(address from, address to, uint id, uint amount, bytes memory) internal virtual {
        uint balance = balances[id][from];
        if (balance < amount) revert InsufficientTokens(id, from, balance, amount);
        balances[id][from] = balance - amount;
        balances[id][to] += amount;
    }

    function safeBatchTransferFrom(address from, address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external virtual override nonReentrant canTransfer(from) valid(to) {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for (uint i = 0; i < ids.length; ++i) _safeTransferFrom(from, to, ids[i], amounts[i], data);
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) revert ERC1155ReceiverRejectedTokens(to);
            } catch Error(string memory reason) {
                revert(reason);
            } // otherwise do nothing
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) revert ERC1155ReceiverRejectedTokens(to);
            } catch Error(string memory reason) {
                revert(reason);
            } // otherwise do nothing
        }
    }
}