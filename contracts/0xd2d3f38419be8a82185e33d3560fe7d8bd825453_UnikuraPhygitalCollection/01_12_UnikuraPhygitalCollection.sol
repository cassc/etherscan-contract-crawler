// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC721AStorage} from "erc721a-upgradeable/contracts/ERC721AStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IUnikuraPhygitalCollection.sol";
import "../UnikuraMothership/IUnikuraMothership.sol";

library UnikuraPhygitalCollectionStorage {
    struct Layout {
        /// @notice The addresses for the UnikuraMothership contracts.
        IUnikuraMothership _unikuraMothership;
        /// @notice The only address nominated to recieve proceeds of a sale and to store tokens
        address payable _salesAddress;
        /// @notice The price to mint a token in the collection. This is stored in wei.
        uint256 _mintPrice;
        /// @notice Maximum about of tokens allowed in the collection.
        uint256 _maxTokens;
        /// @notice Keeps track of number of tokens minted
        uint256 _totalMintedTokens;
        /// @notice Base URI for token metadata
        string _baseURI;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("unikura.contracts.storage.unikuraPhygitalCollection");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/*
 * @notice This contract uses ERC721AUpgradeable
 */
contract UnikuraPhygitalCollection is
    IUnikuraPhygitalCollection,
    ERC721AUpgradeable,
    OwnableUpgradeable
{
    using UnikuraPhygitalCollectionStorage for UnikuraPhygitalCollectionStorage.Layout;

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    function initialize(
        string memory name_,
        string memory symbol_,
        address unikuraMothership_,
        address payable salesAddress_,
        uint8 maxTokens_,
        uint256 mintPrice_
    ) external initializer initializerERC721A {
        __ERC721A_init(name_, symbol_);
        __Ownable_init();

        UnikuraPhygitalCollectionStorage
            .layout()
            ._unikuraMothership = IUnikuraMothership(unikuraMothership_);

        UnikuraPhygitalCollectionStorage.layout()._salesAddress = salesAddress_;

        UnikuraPhygitalCollectionStorage.layout()._mintPrice = mintPrice_;
        UnikuraPhygitalCollectionStorage.layout()._maxTokens = maxTokens_;
        UnikuraPhygitalCollectionStorage.layout()._totalMintedTokens = 0;

        // Mint all tokens to the deployer of the contract
        _mint(
            UnikuraPhygitalCollectionStorage.layout()._salesAddress,
            UnikuraPhygitalCollectionStorage.layout()._maxTokens
        );
    }

    // =============================================================
    //                    ACCESS MODIFIERS
    // =============================================================

    /**
     * @notice Modifier to ensure the `from` and `to` addresses involved in a transfer
     * @dev If the `from` or `to` address is either the zero address or `salesAddress`, or if the mothership approves of the addresses
     * @param from The address from which tokens are being transferred.
     * @param to The address to which tokens are being transferred.
     */
    modifier isAllowed(address from, address to) {
        require(
            from == address(0) ||
                from ==
                UnikuraPhygitalCollectionStorage.layout()._salesAddress ||
                UnikuraPhygitalCollectionStorage
                    .layout()
                    ._unikuraMothership
                    .isAllowed(from),
            "You do not have access to Unikura"
        );
        require(
            to == address(0) ||
                to == UnikuraPhygitalCollectionStorage.layout()._salesAddress ||
                UnikuraPhygitalCollectionStorage
                    .layout()
                    ._unikuraMothership
                    .isAllowed(to),
            "You do not have access to Unikura"
        );
        _;
    }

    // =============================================================
    //                    Events
    // =============================================================

    event TokenMinted(
        uint256 totalPrice,
        uint256 mintPrice,
        uint256 totalMintPrice,
        uint256 serviceFee
    );

    event BaseURIChanged(string oldBaseURI, string newBaseURI);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        require(bytes(baseURI_).length != 0, "The new URI must not be empty");
        string memory oldBaseURI = UnikuraPhygitalCollectionStorage
            .layout()
            ._baseURI;
        UnikuraPhygitalCollectionStorage.layout()._baseURI = baseURI_;
        emit BaseURIChanged(oldBaseURI, baseURI_);
    }

    function _baseURI() internal view override returns (string memory) {
        return UnikuraPhygitalCollectionStorage.layout()._baseURI;
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @notice Gets the starting token ID for the collection.
     * @dev This is an internal, pure function that is overridden from a parent contract.
     * @return Returns the starting token ID, which is 1 in this case.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Calculates the next token ID to be minted.
     * @dev This is an internal, view function that is overridden from a parent contract. It checks if the total number of minted tokens is less than the maximum token limit. If so, it increments the total number of minted tokens by 1. If the limit is reached, it returns 0.
     * @return Returns the next token ID to be minted, or 0 if the maximum token limit has been reached.
     */
    function _nextTokenId() internal view override returns (uint256) {
        return
            (UnikuraPhygitalCollectionStorage.layout()._totalMintedTokens !=
                UnikuraPhygitalCollectionStorage.layout()._maxTokens)
                ? UnikuraPhygitalCollectionStorage.layout()._totalMintedTokens +
                    1
                : 0;
    }

    /**
     * @notice Gets the total supply of tokens for the collection.
     * @dev This is a public, view function that is overridden from a parent contract. It returns the maximum number of tokens that can be minted.
     * @return Returns the total supply of tokens for the collection.
     */
    function totalSupply()
        public
        view
        virtual
        override(ERC721AUpgradeable, IUnikuraPhygitalCollection)
        returns (uint256)
    {
        unchecked {
            return UnikuraPhygitalCollectionStorage.layout()._maxTokens;
        }
    }

    /**
     * @notice Gets the total number of tokens that have been minted so far.
     * @dev This is a public, view function. It returns the total number of tokens that have already been minted.
     * @return Returns the total number of minted tokens.
     */
    function totalMinted() public view returns (uint256) {
        unchecked {
            return UnikuraPhygitalCollectionStorage.layout()._totalMintedTokens;
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @notice Hook that is called before a token transfer takes place.
     * @dev This function enforces the `isAllowed` modifier for both `from` and `to` addresses.
     * @param from The address tokens are being transferred from.
     * @param to The address tokens are being transferred to.
     * @param startTokenId The starting token ID of the transfer.
     * @param quantity The number of tokens being transferred.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override isAllowed(from, to) {}

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev This function mints tokens and transfers them from the wallet of the deployer (the contract creator) to another address.
     * The mint function handles the necessary business logic for the minting process, including checking if the maximum tokens are already minted, validating the payment details, and actually minting the tokens.
     * @param to The recipient address that will receive the newly minted tokens.
     * @param quantity The number of tokens to be minted and transferred.
     */
    function mint(address to, uint256 quantity) public payable {
        // Check if max tokens reached
        require(
            UnikuraPhygitalCollectionStorage.layout()._totalMintedTokens +
                quantity <=
                UnikuraPhygitalCollectionStorage.layout()._maxTokens,
            "Max tokens reached"
        );

        // Check sales price + fee
        uint256 totalPrice = UnikuraPhygitalCollectionStorage
            .layout()
            ._mintPrice * quantity;

        uint256 totalFee = calculateFee(totalPrice);
        require(msg.value >= (totalPrice + totalFee), "Insufficient payment");
        require(
            UnikuraPhygitalCollectionStorage.layout()._salesAddress !=
                address(0),
            "Must have valid salesAddress set"
        );

        // Transfer sales price + fee
        UnikuraPhygitalCollectionStorage.layout()._salesAddress.transfer(
            totalPrice
        );
        velvettFeeRecipient().transfer(totalFee);

        // Mint tokens
        for (uint256 i = 0; i < quantity; i++) {
            _mintTransferFrom(to, _nextTokenId());
            UnikuraPhygitalCollectionStorage.layout()._totalMintedTokens++;
        }

        emit TokenMinted(
            totalPrice + totalFee,
            UnikuraPhygitalCollectionStorage.layout()._mintPrice,
            totalPrice,
            totalFee
        );
    }

    /**
     * @dev This function calculates the fee to be paid for minting tokens.
     * The fee is calculated as a percentage of the mint price, and this percentage is retrieved from the unikuraMothershipContract.
     * @param totalPrice The total price at which the tokens is being minted.
     * @return Returns the calculated fee as an uint256.
     */
    function calculateFee(uint256 totalPrice) public view returns (uint256) {
        uint8 feePercentage = UnikuraPhygitalCollectionStorage
            .layout()
            ._unikuraMothership
            .feePercentage();

        return (totalPrice * feePercentage) / 100;
    }

    /**
     * @dev This function retrieves the address of the recipient to receive the minting fee.
     * The address is retrieved from the unikuraMothershipContract.
     * @return Returns the address of the fee recipient.
     */
    function velvettFeeRecipient() public view returns (address payable) {
        return
            UnikuraPhygitalCollectionStorage
                .layout()
                ._unikuraMothership
                .velvettFeeRecipient();
    }

    /**
     * @dev This function transfers tokens from a given address to another address and skips ownership checks
     * It involves several checks for the validity of the transfer operation and maintains the transfer history by emitting a Transfer event.
     * @param to The recipient of the token transfer.
     * @param tokenId The id of the token to be transferred.
     */
    function _mintTransferFrom(address to, uint256 tokenId) private {
        uint256 prevOwnershipPacked = _packedOwnershipOfLocal(tokenId);

        if (
            address(uint160(prevOwnershipPacked)) !=
            UnikuraPhygitalCollectionStorage.layout()._salesAddress
        ) revert TransferFromIncorrectOwner();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(
            UnikuraPhygitalCollectionStorage.layout()._salesAddress,
            to,
            tokenId,
            1
        );

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddressLocal(tokenId);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --ERC721AStorage.layout()._packedAddressData[
                UnikuraPhygitalCollectionStorage.layout()._salesAddress
            ]; // Updates: `balance -= 1`.
            ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[
                    tokenId
                ] = _packOwnershipDataLocal(
                to,
                _BITMASK_NEXT_INITIALIZED |
                    _nextExtraDataLocal(
                        UnikuraPhygitalCollectionStorage.layout()._salesAddress,
                        to,
                        prevOwnershipPacked
                    )
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (
                    ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0
                ) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[
                                nextTokenId
                            ] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(
            UnikuraPhygitalCollectionStorage.layout()._salesAddress,
            to,
            tokenId
        );
        _afterTokenTransfers(
            UnikuraPhygitalCollectionStorage.layout()._salesAddress,
            to,
            tokenId,
            1
        );
    }

    /**
     * @dev This function retrieves the packed ownership data for a given token ID.
     * The packed data contains a variety of information about the token and its ownership.
     * @param tokenId The id of the token whose packed ownership data is to be retrieved.
     * @return packed Returns the packed ownership data of the token.
     */
    function _packedOwnershipOfLocal(
        uint256 tokenId
    ) private view returns (uint256 packed) {
        if (_startTokenId() <= tokenId) {
            packed = ERC721AStorage.layout()._packedOwnerships[tokenId];
            // If not burned.
            if (packed & _BITMASK_BURNED == 0) {
                // If the data at the starting slot does not exist, start the scan.
                if (packed == 0) {
                    if (tokenId >= ERC721AStorage.layout()._currentIndex)
                        revert OwnerQueryForNonexistentToken();
                    // Invariant:
                    // There will always be an initialized ownership slot
                    // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                    // before an unintialized ownership slot
                    // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                    // Hence, `tokenId` will not underflow.
                    //
                    // We can directly compare the packed value.
                    // If the address is zero, packed will be zero.
                    for (;;) {
                        unchecked {
                            packed = ERC721AStorage.layout()._packedOwnerships[
                                --tokenId
                            ];
                        }
                        if (packed == 0) continue;
                        return packed;
                    }
                }
                // Otherwise, the data exists and is not burned. We can skip the scan.
                // This is possible because we have already achieved the target condition.
                // This saves 2143 gas on transfers of initialized tokens.
                return packed;
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev This function packs the ownership data into a single uint256 value.
     * This includes the owner's address, timestamp of transfer and certain flags.
     * @param owner The address of the token's owner.
     * @param flags A uint256 representing various binary flags.
     * @return result Returns the packed ownership data.
     */
    function _packOwnershipDataLocal(
        address owner,
        uint256 flags
    ) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    /**
     * @dev This function retrieves the extra data for the packed ownership data. The extra data may include additional flags or attributes about the token.
     * @param from The address from which the token is transferred.
     * @param to The address to which the token is transferred.
     * @param prevOwnershipPacked The previously packed ownership data.
     * @return Returns the extra data for the packed ownership data.
     */
    function _nextExtraDataLocal(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    /**
     * @dev This function retrieves the storage slot and value for the approved address of a given token ID.
     * The function returns the data storage slot and the approved address for the token transfer.
     * @param tokenId The id of the token whose approval data is to be retrieved.
     * @return approvedAddressSlot Returns the storage slot and value for the approved address.
     * @return approvedAddress Returns the storage slot and value for the approved address.
     */
    function _getApprovedSlotAndAddressLocal(
        uint256 tokenId
    )
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        ERC721AStorage.TokenApprovalRef storage tokenApproval = ERC721AStorage
            .layout()
            ._tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                        UNIKURA OPERATIONS
    // =============================================================

    /**
     * @notice Returns the current address of the Unikura Mothership contract.
     * @dev A view function that does not mutate the state of the contract.
     * @return An address type that holds the address of the Unikura Mothership contract.
     */
    function unikuraMothership() public view returns (address) {
        return
            address(
                UnikuraPhygitalCollectionStorage.layout()._unikuraMothership
            );
    }

    /**
     * @notice Updates the address of the Unikura Mothership contract.
     * @dev This function is restricted to the owner of the contract only.
     * @param unikuraMothership_ The new address of the Unikura Mothership contract.
     */
    function setUnikuraMothershipContract(
        address unikuraMothership_
    ) external onlyOwner {
        UnikuraPhygitalCollectionStorage
            .layout()
            ._unikuraMothership = IUnikuraMothership(unikuraMothership_);

        // Emit an event with the update.
        emit UnikuraMothershipContract(unikuraMothership_);
    }

    /**
     * @notice Retrieves the current sales address.
     * @dev A view function that does not modify the state of the contract.
     * @return The sales address.
     */
    function salesAddress() public view returns (address) {
        return UnikuraPhygitalCollectionStorage.layout()._salesAddress;
    }

    /**
     * @notice Updates the sales address.
     * @dev This function can only be called by the contract owner.
     * @param salesAddress_ The new sales address.
     */
    function setSalesAddress(address payable salesAddress_) external onlyOwner {
        UnikuraPhygitalCollectionStorage.layout()._salesAddress = salesAddress_;

        // Emit an event with the update.
        emit SalesAddress(salesAddress_);
    }

    /**
     * @notice Retrieves the price of minting a new token.
     * @dev A view function that does not modify the state of the contract.
     * @return The mint price.
     */
    function mintPrice() public view returns (uint256) {
        return UnikuraPhygitalCollectionStorage.layout()._mintPrice;
    }

    /**
     * @notice Updates the mint price.
     * @dev This function can only be called by the contract owner.
     * @param mintPrice_ The new mint price.
     */
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        UnikuraPhygitalCollectionStorage.layout()._mintPrice = mintPrice_;

        // Emit an event with the update.
        emit MintPrice(mintPrice_);
    }

    /**
     * @notice Retrieves the maximum number of tokens that can be minted.
     * @dev A view function that does not mutate the state of the contract.
     * @return The maximum number of tokens.
     */
    function maxTokens() public view returns (uint256) {
        return UnikuraPhygitalCollectionStorage.layout()._maxTokens;
    }

    /**
     * @notice Retrieves the total number of tokens minted so far.
     * @dev A view function that does not mutate the state of the contract.
     * @return The total number of minted tokens.
     */

    function totalMintedTokens() public view returns (uint256) {
        return UnikuraPhygitalCollectionStorage.layout()._totalMintedTokens;
    }
}