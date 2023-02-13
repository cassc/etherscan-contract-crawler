// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "./IReceiptOwnerV1.sol";
import "./IReceiptV1.sol";

import {ERC1155Upgradeable as ERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @dev the ERC1155 URI is always the pinned metadata on ipfs.
string constant RECEIPT_METADATA_URI = "ipfs://bafkreih7cvpjocgrk7mgdel2hvjpquc26j4jo2jkez5y2qdaojfil7vley";

/// @title Receipt
/// @notice The `IReceiptV1` for a `ReceiptVault`. Standard implementation allows
/// receipt information to be emitted and mints/burns according to ownership and
/// owner authorization.
contract Receipt is IReceiptV1, Ownable, ERC1155 {
    /// Disables initializers so that the clonable implementation cannot be
    /// initialized and used directly outside a factory deployment.
    constructor() {
        _disableInitializers();
    }

    /// Initializes the `Receipt` so that it is usable as a clonable
    /// implementation in `ReceiptFactory`.
    function initialize() external initializer {
        __Ownable_init();
        __ERC1155_init(RECEIPT_METADATA_URI);
    }

    /// @inheritdoc IReceiptV1
    function owner()
        public
        view
        virtual
        override(IReceiptV1, Ownable)
        returns (address)
    {
        return Ownable.owner();
    }

    /// @inheritdoc IReceiptV1
    function ownerMint(
        address sender_,
        address account_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external virtual onlyOwner {
        _receiptInformation(sender_, id_, data_);
        _mint(account_, id_, amount_, data_);
    }

    /// @inheritdoc IReceiptV1
    function ownerBurn(
        address sender_,
        address account_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external virtual onlyOwner {
        _receiptInformation(sender_, id_, data_);
        _burn(account_, id_, amount_);
    }

    /// @inheritdoc IReceiptV1
    function ownerTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external virtual onlyOwner {
        _safeTransferFrom(from_, to_, id_, amount_, data_);
    }

    /// Checks with the owner before authorizing transfer IN ADDITION to `super`
    /// inherited checks.
    /// @inheritdoc ERC1155
    function _beforeTokenTransfer(
        address operator_,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual override {
        super._beforeTokenTransfer(
            operator_,
            from_,
            to_,
            ids_,
            amounts_,
            data_
        );
        IReceiptOwnerV1(owner()).authorizeReceiptTransfer(from_, to_);
    }

    /// Emits `ReceiptInformation` if there is any data after checking with the
    /// receipt owner for authorization.
    /// @param account_ The account that is emitting receipt information.
    /// @param id_ The id of the receipt this information is for.
    /// @param data_ The data being emitted as information for the receipt.
    function _receiptInformation(
        address account_,
        uint256 id_,
        bytes memory data_
    ) internal virtual {
        // No data is noop.
        if (data_.length > 0) {
            emit ReceiptInformation(account_, id_, data_);
        }
    }

    /// @inheritdoc IReceiptV1
    function receiptInformation(
        uint256 id_,
        bytes memory data_
    ) external virtual {
        _receiptInformation(msg.sender, id_, data_);
    }
}