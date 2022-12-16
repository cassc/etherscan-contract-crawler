// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155} from "./../interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "./../interfaces/IERC1155MetadataURI.sol";
import {IERC1155Mintable} from "./../interfaces/IERC1155Mintable.sol";
import {IERC1155Deliverable} from "./../interfaces/IERC1155Deliverable.sol";
import {IERC1155Burnable} from "./../interfaces/IERC1155Burnable.sol";
import {IERC1155TokenReceiver} from "./../interfaces/IERC1155TokenReceiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC1155Storage {
    using Address for address;
    using ERC1155Storage for ERC1155Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operators;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC1155.ERC1155.storage")) - 1);

    bytes4 internal constant ERC1155_SINGLE_RECEIVED = IERC1155TokenReceiver.onERC1155Received.selector;
    bytes4 internal constant ERC1155_BATCH_RECEIVED = IERC1155TokenReceiver.onERC1155BatchReceived.selector;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155MetadataURI.
    function initERC1155MetadataURI() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155MetadataURI).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Mintable.
    function initERC1155Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Deliverable.
    function initERC1155Deliverable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Deliverable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Burnable.
    function initERC1155Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Burnable).interfaceId, true);
    }

    /// @notice Safely transfers some token by a sender.
    /// @dev Note: This function implements {ERC1155-safeTransferFrom(address,address,uint256,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param from Current token owner.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to transfer.
    /// @param value Amount of token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 id, uint256 value, bytes calldata data) internal {
        require(to != address(0), "ERC1155: transfer to address(0)");
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        _transferToken(s, from, to, id, value);

        emit TransferSingle(sender, from, to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(sender, from, to, id, value, data);
        }
    }

    /// @notice Safely transfers a batch of tokens by a sender.
    /// @dev Note: This function implements {ERC1155-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155BatchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param sender The message sender.
    /// @param from Current tokens owner.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to transfer.
    /// @param values Amounts of tokens to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchTransferFrom(
        Layout storage s,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) internal {
        require(to != address(0), "ERC1155: transfer to address(0)");
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");

        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _transferToken(s, from, to, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, from, to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(sender, from, to, ids, values, data);
        }
    }

    /// @notice Safely mints some token by a sender.
    /// @dev Note: This function implements {ERC1155Mintable-safeMint(address,uint256,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance of `id` overflows.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to mint.
    /// @param value Amount of token to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeMint(Layout storage s, address sender, address to, uint256 id, uint256 value, bytes memory data) internal {
        require(to != address(0), "ERC1155: mint to address(0)");

        _mintToken(s, to, id, value);

        emit TransferSingle(sender, address(0), to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(sender, address(0), to, id, value, data);
        }
    }

    /// @notice Safely mints a batch of tokens by a sender.
    /// @dev Note: This function implements {ERC1155Mintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance overflows for one of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param sender The message sender.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchMint(Layout storage s, address sender, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        require(to != address(0), "ERC1155: mint to address(0)");
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _mintToken(s, to, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, address(0), to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(sender, address(0), to, ids, values, data);
        }
    }

    /// @notice Safely mints tokens to multiple recipients by a sender.
    /// @dev Note: This function implements {ERC1155Deliverable-safeDeliver(address[],uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `recipients`, `ids` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `recipients` balance overflows.
    /// @dev Reverts if one of `recipients` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event from the zero address for each transfer.
    /// @param sender The message sender.
    /// @param recipients Addresses of the new tokens owners.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeDeliver(
        Layout storage s,
        address sender,
        address[] memory recipients,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        uint256 length = recipients.length;
        require(length == ids.length && length == values.length, "ERC1155: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                s.safeMint(sender, recipients[i], ids[i], values[i], data);
            }
        }
    }

    /// @notice Burns some token by a sender.
    /// @dev Reverts `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param from Address of the current token owner.
    /// @param id Identifier of the token to burn.
    /// @param value Amount of token to burn.
    function burnFrom(Layout storage s, address sender, address from, uint256 id, uint256 value) internal {
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");
        _burnToken(s, from, id, value);
        emit TransferSingle(sender, from, address(0), id, value);
    }

    /// @notice Burns multiple tokens by a sender.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param sender The message sender.
    /// @param from Address of the current tokens owner.
    /// @param ids Identifiers of the tokens to burn.
    /// @param values Amounts of tokens to burn.
    function batchBurnFrom(Layout storage s, address sender, address from, uint256[] calldata ids, uint256[] calldata values) internal {
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _burnToken(s, from, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    /// @notice Enables or disables an operator's approval by a sender.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param sender The message sender.
    /// @param operator Address of the operator.
    /// @param approved True to approve the operator, false to revoke its approval.
    function setApprovalForAll(Layout storage s, address sender, address operator, bool approved) internal {
        require(operator != sender, "ERC1155: self-approval for all");
        s.operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @notice Retrieves the approval status of an operator for a given owner.
    /// @param owner Address of the authorisation giver.
    /// @param operator Address of the operator.
    /// @return approved True if the operator is approved, false if not.
    function isApprovedForAll(Layout storage s, address owner, address operator) internal view returns (bool approved) {
        return s.operators[owner][operator];
    }

    /// @notice Retrieves the balance of `id` owned by account `owner`.
    /// @param owner The account to retrieve the balance of.
    /// @param id The identifier to retrieve the balance of.
    /// @return balance The balance of `id` owned by account `owner`.
    function balanceOf(Layout storage s, address owner, uint256 id) internal view returns (uint256 balance) {
        require(owner != address(0), "ERC1155: balance of address(0)");
        return s.balances[id][owner];
    }

    /// @notice Retrieves the balances of `ids` owned by accounts `owners`.
    /// @dev Reverts if `owners` and `ids` have different lengths.
    /// @param owners The addresses of the token holders
    /// @param ids The identifiers to retrieve the balance of.
    /// @return balances The balances of `ids` owned by accounts `owners`.
    function balanceOfBatch(Layout storage s, address[] calldata owners, uint256[] calldata ids) internal view returns (uint256[] memory balances) {
        uint256 length = owners.length;
        require(length == ids.length, "ERC1155: inconsistent arrays");

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i; i != length; ++i) {
                balances[i] = s.balanceOf(owners[i], ids[i]);
            }
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Returns whether an account is authorised to make a transfer on behalf of an owner.
    /// @param owner The token owner.
    /// @param account The account to check the operatability of.
    /// @return operatable True if `account` is `owner` or is an operator for `owner`, false otherwise.
    function _isOperatable(Layout storage s, address owner, address account) private view returns (bool operatable) {
        return (owner == account) || s.operators[owner][account];
    }

    function _transferToken(Layout storage s, address from, address to, uint256 id, uint256 value) private {
        if (value != 0) {
            unchecked {
                uint256 fromBalance = s.balances[id][from];
                uint256 newFromBalance = fromBalance - value;
                require(newFromBalance < fromBalance, "ERC1155: insufficient balance");
                if (from != to) {
                    uint256 toBalance = s.balances[id][to];
                    uint256 newToBalance = toBalance + value;
                    require(newToBalance > toBalance, "ERC1155: balance overflow");

                    s.balances[id][from] = newFromBalance;
                    s.balances[id][to] = newToBalance;
                }
            }
        }
    }

    function _mintToken(Layout storage s, address to, uint256 id, uint256 value) private {
        if (value != 0) {
            unchecked {
                uint256 balance = s.balances[id][to];
                uint256 newBalance = balance + value;
                require(newBalance > balance, "ERC1155: balance overflow");
                s.balances[id][to] = newBalance;
            }
        }
    }

    function _burnToken(Layout storage s, address from, uint256 id, uint256 value) private {
        if (value != 0) {
            unchecked {
                uint256 balance = s.balances[id][from];
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC1155: insufficient balance");
                s.balances[id][from] = newBalance;
            }
        }
    }

    /// @notice Calls {IERC1155TokenReceiver-onERC1155Received} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param id Identifier of the token transferred.
    /// @param value Value transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC1155Received(address sender, address from, address to, uint256 id, uint256 value, bytes memory data) private {
        require(IERC1155TokenReceiver(to).onERC1155Received(sender, from, id, value, data) == ERC1155_SINGLE_RECEIVED, "ERC1155: transfer rejected");
    }

    /// @notice Calls {IERC1155TokenReceiver-onERC1155BatchReceived} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param ids Identifiers of the tokens transferred.
    /// @param values Values transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC1155BatchReceived(
        address sender,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        require(
            IERC1155TokenReceiver(to).onERC1155BatchReceived(sender, from, ids, values, data) == ERC1155_BATCH_RECEIVED,
            "ERC1155: transfer rejected"
        );
    }
}