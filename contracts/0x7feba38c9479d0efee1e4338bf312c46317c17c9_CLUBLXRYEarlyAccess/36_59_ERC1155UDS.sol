// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EIP712PermitUDS} from "./EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC1155 = keccak256("diamond.storage.erc1155");

function s() pure returns (ERC1155DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC1155;
    assembly {
        diamondStorage.slot := slot
    }
}

struct ERC1155DS {
    mapping(address => mapping(uint256 => uint256)) balanceOf;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

// ------------- errors

error NotAuthorized();
error LengthMismatch();
error UnsafeRecipient();

/// @title ERC1155 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate ERC1155 (https://github.com/Rari-Capital/solmate)
abstract contract ERC1155UDS is EIP712PermitUDS("ERC1155Permit", "1") {
    ERC1155DS private __storageLayout; // storage layout for upgrade compatibility checks

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    /* ------------- virtual ------------- */

    function uri(uint256 id) public view virtual returns (string memory);

    /**
     * @dev Hook that is called before any token transfer.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before any batch token transfer.
     */
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /* ------------- view ------------- */

    function balanceOf(
        address owner,
        uint256 id
    ) public view virtual returns (uint256) {
        return s().balanceOf[owner][id];
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances) {
        if (owners.length != ids.length) revert LengthMismatch();

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = s().balanceOf[owners[i]][ids[i]];
            }
        }
    }

    function isApprovedForAll(
        address operator,
        address owner
    ) public view returns (bool) {
        return s().isApprovedForAll[operator][owner];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /* ------------- public ------------- */

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (msg.sender != from && !s().isApprovedForAll[from][msg.sender])
            revert NotAuthorized();

        _beforeTokenTransfer(msg.sender, from, to, id, amount, data);

        s().balanceOf[from][id] -= amount;
        s().balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) != ERC1155TokenReceiver.onERC1155Received.selector
        ) revert UnsafeRecipient();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual {
        if (ids.length != amounts.length) revert LengthMismatch();
        if (msg.sender != from && !s().isApprovedForAll[from][msg.sender])
            revert NotAuthorized();

        _beforeBatchTokenTransfer(msg.sender, from, to, ids, amounts, data);

        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            s().balanceOf[from][id] -= amount;
            s().balanceOf[to][id] += amount;

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) != ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert UnsafeRecipient();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, 1, deadline, v, r, s_);

        s().isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    /* ------------- internal ------------- */

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        s().balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) != ERC1155TokenReceiver.onERC1155Received.selector
        ) revert UnsafeRecipient();
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            s().balanceOf[to][ids[i]] += amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) != ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert UnsafeRecipient();
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            s().balanceOf[from][ids[i]] -= amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        s().balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}