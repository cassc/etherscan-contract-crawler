// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./BitOperation.sol";

/**
 * @dev Implementation of a binary multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts
 *
 * This implementation lets addresses hold a unique instance of multiple tokens
 */
contract BinaryERC1155 is ERC1155 {
    /* ====== LIBRARY USAGE ====== */

    using BitOperation for uint256;
    using Address for address;

    /* ====== PRIVATE VARIABLES ====== */

    // Mapping from accounts to packed token ids
    mapping(address => uint256) private _balances;

    /* ====== CONSTRUCTOR ====== */

    // solhint-disable no-empty-blocks
    constructor(string memory uri_) ERC1155(uri_) {}

    /* ====== MODIFIERS ====== */

    /// @notice Checkes if a provided uint256 can be casted as a uint8
    /// @dev Verify that the provided value is within the range of uint8
    /// @param value_ The value to be checked
    modifier isUint8(uint256 value_) {
        require(value_ < 256, "BinaryERC1155: value must be less than 256");
        _;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /// @notice Give the balance of the specified token ID for the specified account
    /// @param account_ the account to check the balance for
    /// @param id_ the token ID to check the balance of. Must be less than 256
    /// @return the balance of the token ID for the specified account
    function balanceOf(address account_, uint256 id_) public view virtual override isUint8(id_) returns (uint256) {
        require(account_ != address(0), "ERC1155: balance query for the zero address");

        uint256 packedBalance = _balances[account_];

        return packedBalance.getBit(uint8(id_)) ? 1 : 0;
    }

    /// @notice Give the balance of the specified token IDs for the specified accounts
    /// @param accounts_ the accounts to check the balance for
    /// @param ids_ the token IDs to check the balance of. Must all be less than 256
    /// @return the balance of the token IDs for the specified accounts
    function balanceOfBatch(address[] memory accounts_, uint256[] memory ids_)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts_.length == ids_.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory balances = new uint256[](accounts_.length);

        for (uint256 i = 0; i < accounts_.length; i++) {
            balances[i] = balanceOf(accounts_[i], ids_[i]);
        }

        return balances;
    }

    /* ====== INTERNAL FUNCTIONS ====== */

    /// @notice Mint a new token of a specific id for a given address
    /// @param to_ the address to mint the token for
    /// @param id_ the token ID to mint
    /// @param data_ extra data
    function _mint(
        address to_,
        uint8 id_,
        bytes memory data_
    ) internal virtual {
        _safeTransferFrom(address(0), to_, id_, 1, data_);
    }

    /// @notice Mint a batch of new tokens of a specific id for a given address
    /// @param to_ the address to mint the tokens for
    /// @param packedIds_ the token ids to transfer, packed as a uint256, each token id is the bit position
    /// of the corresponding binary representation of this uint256
    /// @param data_ extra data
    function _mintBatch(
        address to_,
        uint256 packedIds_,
        bytes memory data_
    ) internal virtual {
        require(to_ != address(0), "ERC1155: transfer to the zero address");
        require(_balances[to_].negatesMask(packedIds_), "BinaryERC1155: minting of already owned tokens");

        address operator = _msgSender();
        uint256[] memory ids = packedIds_.unpackIn2Radix();
        uint256[] memory amounts = _arrayOfOnes(ids.length);

        _beforeTokenTransfer(operator, address(0), to_, ids, amounts, data_);

        // Check for origin balance and destination balances have been done,
        // now we can safely update the balances
        _balances[to_] = _balances[to_] + packedIds_;

        emit TransferBatch(operator, address(0), to_, ids, amounts);

        _afterTokenTransfer(operator, address(0), to_, ids, amounts, data_);

        _doSafeBatchTransferAcceptanceCheckCopy(operator, address(0), to_, ids, amounts, data_);
    }

    /// @notice Burn a given token id for a given address
    /// @param from_ the address to burn the token for
    /// @param id_ the token ID to burn
    function _burn(address from_, uint8 id_) internal virtual {
        require(from_ != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArrayCopy(id_);
        uint256[] memory amounts = _arrayOfOnes(1);
        _beforeTokenTransfer(operator, from_, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[from_];
        require(fromBalance.getBit(id_), "ERC1155: burn amount exceeds balance");
        _balances[from_] = fromBalance.clearBit(id_);

        emit TransferSingle(operator, from_, address(0), id_, 1);
        _afterTokenTransfer(operator, from_, address(0), ids, amounts, "");
    }

    /// @notice Burn a batch of token ids for a given address
    /// @param from_ the address to burn the token for
    /// @param packedIds_ the token ids to burn, packed as a uint256, each token id is the bit position
    /// of the corresponding binary representation of this uint256
    function _burnBatch(address from_, uint256 packedIds_) internal virtual {
        require(from_ != address(0), "ERC1155: burn from the zero address");
        require(packedIds_ > 0, "BinaryERC1155: burn of empty token ids");

        address operator = _msgSender();
        uint256[] memory ids = packedIds_.unpackIn2Radix();
        uint256[] memory amounts = _arrayOfOnes(ids.length);

        _beforeTokenTransfer(operator, from_, address(0), ids, amounts, "");

        require(_balances[from_].matchesMask(packedIds_), "ERC1155: burn amount exceeds balance");
        // Check for token balance has been done,
        // now we can safely update the balances
        _balances[from_] = _balances[from_] - packedIds_;

        emit TransferBatch(operator, from_, address(0), ids, amounts);

        _afterTokenTransfer(operator, from_, address(0), ids, amounts, "");
    }

    /// @notice Transfers a token id from one address to another
    /// @dev Also accepts a zero address for the origin address when minting the token
    /// @param from_ the address to transfer the token from, can be the zero address
    /// @param to_ the address to transfer the token to
    /// @param id_ the token ID to transfer
    /// @param amount_ the token amount of tokens to transfer, must be 1
    /// @param data_ extra data
    function _safeTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) internal virtual override isUint8(id_) {
        require(to_ != address(0), "ERC1155: transfer to the zero address");
        require(amount_ == 1, "BinaryERC1155: transfer amount must be 1");
        uint8 castedId = uint8(id_);
        require(_balances[to_].getBit(castedId) == false, "BinaryERC1155: transfer of already owned token");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArrayCopy(id_);
        uint256[] memory amounts = _asSingletonArrayCopy(amount_);

        _beforeTokenTransfer(operator, from_, to_, ids, amounts, data_);

        if (from_ != address(0)) {
            // This is not a minting transfer, let's make some operations on the source address
            bool fromOwnsToken = _balances[from_].getBit(castedId);
            require(fromOwnsToken, "ERC1155: insufficient balance for transfer");
            _balances[from_] = _balances[from_].clearBit(castedId);
        }
        _balances[to_] = _balances[to_].setBit(castedId);

        emit TransferSingle(operator, from_, to_, id_, amount_);

        _afterTokenTransfer(operator, from_, to_, ids, amounts, data_);

        _doSafeTransferAcceptanceCheckCopy(operator, from_, to_, id_, amount_, data_);
    }

    /// @notice Transfers a batch of token ids from one address to another
    /// @dev Also accepts a zero address for the origin address when minting the token
    /// @param from_ the address to transfer the token from, can be the zero address
    /// @param to_ the address to transfer the token to
    /// @param ids_ the token ids to transfer
    /// @param amounts_ the amounts of tokens to transfer, treated as being 1 for each token id
    /// @param data_ extra data
    function _safeBatchTransferFrom(
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual override {
        require(to_ != address(0), "ERC1155: transfer to the zero address");
        require(ids_.length == amounts_.length, "ERC1155: ids and amounts length mismatch");
        uint256 packedIds = _pack(ids_);
        require(_balances[to_].negatesMask(packedIds), "BinaryERC1155: transfer of already owned tokens");

        address operator = _msgSender();
        uint256[] memory amounts = _arrayOfOnes(ids_.length);

        _beforeTokenTransfer(operator, from_, to_, ids_, amounts, data_);

        // Check for origin balance and destination balances have been done,
        // now we can safely update the balances
        if (from_ != address(0)) {
            require(_balances[from_].matchesMask(packedIds), "ERC1155: insufficient balance for transfer");
            _balances[from_] = _balances[from_] - packedIds;
        }
        _balances[to_] = _balances[to_] + packedIds;

        emit TransferBatch(operator, from_, to_, ids_, amounts);

        _afterTokenTransfer(operator, from_, to_, ids_, amounts, data_);

        _doSafeBatchTransferAcceptanceCheckCopy(operator, from_, to_, ids_, amounts, data_);
    }

    /// @notice Return an array filled with ones
    /// @param length_ The length of the array
    /// @return array The array of length length_ filled with ones
    function _arrayOfOnes(uint256 length_) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](length_);

        if (length_ != 0) {
            for (uint256 i = 0; i < length_ - 1; ++i) {
                result[i] = 1;
            }
        }

        return result;
    }

    /// @notice Pack an array of uint256 into a uint256
    /// @dev Pack values into a uint256, requiring the values to be less than 256
    /// @param ids_ The values to pack
    /// @return packed uint256 The packed values
    function _pack(uint256[] memory ids_) internal pure returns (uint256 packed) {
        for (uint256 i = 0; i < ids_.length; ++i) {
            require(ids_[i] < 256, "BinaryERC1155: token id must be less than 256");
            packed = packed.setBit(uint8(ids_[i]));
        }
    }

    /* ====== ABSTRACTED INTERNAL FUNCTIONS FROM OPENZEPELLIN ====== */

    /// @notice Override OpenZeppelin method and mark it abstract since the amount_
    /// parameter is not releveant in this binary implementation
    function _mint(
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) internal virtual override {}

    /// @notice Override OpenZeppelin method and mark it abstract since the amounts_
    /// parameter is not releveant in this binary implementation
    function _mintBatch(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual override {}

    /// @notice Override OpenZeppelin method and mark it abstract since the amount_
    /// parameter is not releveant in this binary implementation
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual override {}

    /// @notice Override OpenZeppelin method and mark it abstract since the amounts_
    /// parameter is not releveant in this binary implementation
    function _burnBatch(
        address from_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) internal virtual override {}

    /* ====== COPIED PRIVATE FUNCTIONS FROM OPENZEPELLIN ====== */

    /// @notice copied from OpenZeppelin's _doSafeTransferAcceptanceCheck method
    /// The source function is private and cannot be overriden nor used
    /// we then need to rename it
    function _doSafeTransferAcceptanceCheckCopy(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
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

    /// @notice copied from OpenZeppelin's _doSafeBatchTransferAcceptanceCheck method
    /// The source function is private and cannot be overriden nor used
    /// we then need to rename it
    function _doSafeBatchTransferAcceptanceCheckCopy(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
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

    /// @notice copied from OpenZeppelin's _asSingletonArray method
    /// The source function is private and cannot be overriden nor used
    /// we then need to rename it
    function _asSingletonArrayCopy(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}