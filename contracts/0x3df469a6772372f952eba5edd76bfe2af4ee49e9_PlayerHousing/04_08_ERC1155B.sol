// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

/// @title Minimalist and gas efficient ERC1155 implementation optimized for single supply ids
/// @author Solarbots (https://solarbots.io)
/// @notice Based on Solmate implementation (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155B.sol)
abstract contract ERC1155B {
    // ---------- CONSTANTS ----------

    /// @notice Maximum amount of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 18_000;

    /// @notice Maximum token ID
    /// @dev Inline assembly does not support non-number constants like `MAX_SUPPLY - 1`
    uint256 public constant MAX_ID = 17_999;

    string public constant ERROR_ARRAY_LENGTH_MISMATCH = "ERC1155B: Array length mismatch";
    string public constant ERROR_FROM_NOT_TOKEN_OWNER = "ERC1155B: From not token owner";
    string public constant ERROR_ID_ALREADY_MINTED = "ERC1155B: ID already minted";
    string public constant ERROR_ID_NOT_MINTED = "ERC1155B: ID not minted";
    string public constant ERROR_INVALID_AMOUNT = "ERC1155B: Invalid amount";
    string public constant ERROR_INVALID_FROM = "ERC1155B: Invalid from";
    string public constant ERROR_INVALID_ID = "ERC1155B: Invalid ID";
    string public constant ERROR_INVALID_RECIPIENT = "ERC1155B: Invalid recipient";
    string public constant ERROR_NOT_AUTHORIZED = "ERC1155B: Not authorized";
    string public constant ERROR_UNSAFE_RECIPIENT = "ERC1155B: Unsafe recipient";

    /// @dev bytes32(abi.encodePacked("ERC1155B: Invalid ID"))
    bytes32 internal constant _ERROR_ENCODED_INVALID_ID = 0x45524331313535423a20496e76616c6964204944000000000000000000000000;

    /// @dev bytes32(abi.encodePacked("ERC1155B: Invalid amount"))
    bytes32 internal constant _ERROR_ENCODED_INVALID_AMOUNT = 0x45524331313535423a20496e76616c696420616d6f756e740000000000000000;

    /// @dev bytes32(abi.encodePacked("ERC1155B: From not token owner"))
    bytes32 internal constant _ERROR_ENCODED_FROM_NOT_TOKEN_OWNER = 0x45524331313535423a2046726f6d206e6f7420746f6b656e206f776e65720000;

    /// @dev "ERC1155B: Invalid ID" is 20 characters long
    uint256 internal constant _ERROR_LENGTH_INVALID_ID = 20;

    /// @dev "ERC1155B: Invalid amount" is 24 characters long
    uint256 internal constant _ERROR_LENGTH_INVALID_AMOUNT = 24;

    /// @dev "ERC1155B: From not token owner" is 30 characters long
    uint256 internal constant _ERROR_LENGTH_FROM_NOT_TOKEN_OWNER = 30;

    /// @dev "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
    bytes32 internal constant _ERROR_FUNCTION_SIGNATURE = 0x08c379a000000000000000000000000000000000000000000000000000000000;

    /// @dev Inline assembly does not support non-number constants like `type(uint160).max`
    uint256 internal constant _BITMASK_ADDRESS = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    // ---------- STATE ----------

    address[MAX_SUPPLY] public ownerOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // ---------- EVENTS ----------

    event URI(string value, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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

    // ---------- ERC-165 ----------

    // slither-disable-next-line external-function
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    // ---------- METADATA ----------

    // slither-disable-next-line external-function
    function uri(uint256 id) public view virtual returns (string memory);

    // ---------- APPROVAL ----------

    // slither-disable-next-line external-function
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // ---------- BALANCE ----------

    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 bal) {
        address idOwner = ownerOf[id];

        assembly {
            // We avoid branching by using assembly to take
            // the bool output of eq() and use it as a uint.
            bal := eq(idOwner, owner)
        }
    }

    // slither-disable-next-line external-function
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, ERROR_ARRAY_LENGTH_MISMATCH);

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }

    // ---------- TRANSFER ----------

    // slither-disable-next-line external-function
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], ERROR_NOT_AUTHORIZED);
        require(id < MAX_SUPPLY, ERROR_INVALID_ID);
        require(amount == 1, ERROR_INVALID_AMOUNT);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Load address stored in `ownerOf[id]`
            let ownerOfId := sload(ownerOfIdSlot)
            // Make sure we're only using the first 160 bits of the storage slot
            // as the remaining 96 bits might not be zero
            ownerOfId := and(ownerOfId, _BITMASK_ADDRESS)

            // Revert with message "ERC1155B: From not token owner" if `ownerOf[id]` is not `from`
            if xor(ownerOfId, from) {
                // Load free memory position
                let freeMemory := mload(0x40)
                // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                // Store data offset
                mstore(add(freeMemory, 0x04), 0x20)
                // Store length of revert message
                mstore(add(freeMemory, 0x24), _ERROR_LENGTH_FROM_NOT_TOKEN_OWNER)
                // Store revert message
                mstore(add(freeMemory, 0x44), _ERROR_ENCODED_FROM_NOT_TOKEN_OWNER)
                revert(freeMemory, 0x64)
            }

            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // slither-disable-next-line external-function
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, ERROR_ARRAY_LENGTH_MISMATCH);
        require(msg.sender == from || isApprovedForAll[from][msg.sender], ERROR_NOT_AUTHORIZED);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate length of arrays `ids` and `amounts` in bytes
            let arrayLength := mul(ids.length, 0x20)

            // Loop over all values in `ids` and `amounts` by starting
            // with an index offset of 0 to access the first array element
            // and incrementing this index by 32 after each iteration to
            // access the next array element until the offset reaches the end
            // of the arrays, at which point all values the arrays contain
            // have been accessed
            for
                { let indexOffset := 0x00 }
                lt(indexOffset, arrayLength)
                { indexOffset := add(indexOffset, 0x20) }
            {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                let id := calldataload(add(ids.offset, indexOffset))

                // Revert with message "ERC1155B: Invalid ID" if `id` is higher than `MAX_ID`
                if gt(id, MAX_ID) {
                    // Load free memory position
                    // slither-disable-next-line variable-scope
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_INVALID_ID)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_INVALID_ID)
                    revert(freeMemory, 0x64)
                }

                // Revert with message "ERC1155B: Invalid amount" if amount is not 1
                if xor(calldataload(add(amounts.offset, indexOffset)), 1) {
                    // Load free memory position
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_INVALID_AMOUNT)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_INVALID_AMOUNT)
                    revert(freeMemory, 0x64)
                }

                // Calculate storage slot of `ownerOf[id]`
                let ownerOfIdSlot := add(ownerOf.slot, id)
                // Load address stored in `ownerOf[id]`
                let ownerOfId := sload(ownerOfIdSlot)
                // Make sure we're only using the first 160 bits of the storage slot
                // as the remaining 96 bits might not be zero
                ownerOfId := and(ownerOfId, _BITMASK_ADDRESS)

                // Revert with message "ERC1155B: From not token owner" if `ownerOf[id]` is not `from`
                if xor(ownerOfId, from) {
                    // Load free memory position
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_FROM_NOT_TOKEN_OWNER)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_FROM_NOT_TOKEN_OWNER)
                    revert(freeMemory, 0x64)
                }

                // Store address of `to` in `ownerOf[id]`
                sstore(ownerOfIdSlot, to)
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // ---------- MINT ----------

    // slither-disable-next-line dead-code
    function _mint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        // Minting twice would effectively be a force transfer.
        require(ownerOf[id] == address(0), ERROR_ID_ALREADY_MINTED);

        ownerOf[id] = to;

        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, 1, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // slither-disable-next-line dead-code
    function _batchMint(
        address to,
        uint256[] memory ids,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                // Minting twice would effectively be a force transfer.
                require(ownerOf[id] == address(0), ERROR_ID_ALREADY_MINTED);

                ownerOf[id] = to;

                amounts[i] = 1;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // ---------- BURN ----------

    // slither-disable-next-line dead-code
    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(owner != address(0), ERROR_ID_NOT_MINTED);

        ownerOf[id] = address(0);

        emit TransferSingle(msg.sender, owner, address(0), id, 1);
    }

    // slither-disable-next-line dead-code
    function _batchBurn(address from, uint256[] memory ids) internal virtual {
        // Burning unminted tokens makes no sense.
        require(from != address(0), ERROR_INVALID_FROM);

        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                require(from == ownerOf[id], ERROR_FROM_NOT_TOKEN_OWNER);

                ownerOf[id] = address(0);

                amounts[i] = 1;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }
}