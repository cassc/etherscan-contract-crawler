// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice Gas optimized airdrop extension with SSTORE2 technique for ERC721Psi Upgradeable.
/// @author 0xedy

import "../ERC721Psi/ERC721PsiUpgradeable.sol";
import "./storage/ERC721PsiAirdropStorage.sol";
import "solidity-bits/contracts/BitMaps.sol";
import "../libs/ImmutableArray.sol";

abstract contract ERC721PsiAirdropUpgradeable is ERC721PsiUpgradeable {
    using ERC721PsiAirdropStorage for ERC721PsiAirdropStorage.Layout;
    using BitMaps for BitMaps.BitMap;
    using ImmutableArray for address;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev constant variable of Zero Address.
    address private constant _ZERO_ADDRESS = address(0);

    /// @dev Pointer should not be Zero Address.
    error SetPointerAsZeroAddress();
    /// @dev Pointers length should not be zero.
    error SetNoPointer();
    /// @dev Pointers length should not be under max of uint16.
    error SetExceededPointers();
    /// @dev Pointer cannot be overrided after airdroped.
    error OverrideAirdroppedPointer();
    /// @dev There is no pointers which are not airdropped.
    error UnairdroppedPointersNonExistent();
    /// @dev Specified function parameter is not valid.
    error InvalidParameter();
    /// @dev Specified pointer is not Immutable Array.
    error InvalidArrayPointer();
    /// @dev `addressLengthInPointer` can only be set once.
    error AddressLengthInPointerAlreadySet();
    /// @dev Address length should be non-zero
    error ZeroAddressLength();
    /// @dev Address length should be match with `addressLengthInPointer`
    error InvalidAddressLength(uint256 index);
    /// Airdrop should be done continously but the state is incontinous.
    error AirdropConsistencyBroken();
    /// @dev Specified `tokenId` is not existent.
    error NonExistentTokenId(uint256 tokenId);
    /// @dev Airdrop to Zero Address
    error AirdropZeroAddress(uint256 tokenId);
    /// @dev Transfer of token that is not own.
    error TransferForNotOwnToken();
    /// @dev Transfer of token to zero address.
    error TransferToZeroAddress();

    // =============================================================
    //     CONSTRUCTOR
    // =============================================================
    function __ERC721PsiAirdrop_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721Psi_init_unchained(name_, symbol_);
        __ERC721PsiAirdrop_init_unchain();
    }

    function __ERC721PsiAirdrop_init_unchain() internal onlyInitializing {
    }

    // =============================================================
    //     INTERNAL SETTER FUNCTIONS
    // =============================================================
    function _addAirdropListPointers(address[] memory pointers) internal virtual {
        uint256 len = pointers.length;
        if (len == 0) revert SetNoPointer();
        if (len > type(uint16).max) revert SetExceededPointers();
        for (uint256 i; i < len;) {
            if (pointers[i] == address(0)) revert SetPointerAsZeroAddress();
            ERC721PsiAirdropStorage.layout().airdropListPointers.push(pointers[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _updateAirdropListPointer(uint256 index, address pointer) internal virtual {
        if (pointer == address(0)) revert SetPointerAsZeroAddress();
        // Airdroped index cannot be changed.
        if (index < uint256(ERC721PsiAirdropStorage.layout().nextPointerIndex))
            revert OverrideAirdroppedPointer();
        ERC721PsiAirdropStorage.layout().airdropListPointers[index] = pointer;
    }

    function _setAddressLengthInPointer(uint16 value) internal virtual {
        if (ERC721PsiAirdropStorage.layout().addressLengthInPointer != 0)
            revert AddressLengthInPointerAlreadySet();
        if (value > 1228) revert InvalidParameter();
        if (value == 0) revert InvalidParameter();
        ERC721PsiAirdropStorage.layout().addressLengthInPointer = value;
    }

    // =============================================================
    //     PUBLIC GETTER FUNCTIONS
    // =============================================================
    function startAirdropIndex() public view virtual returns (uint32) {
        return ERC721PsiAirdropStorage.layout().startAirdropIndex;
    }

    function addressLengthInPointer() public view virtual returns (uint16) {
        return ERC721PsiAirdropStorage.layout().addressLengthInPointer;
    }

    function airdropListPointers(uint256 index) public view virtual returns (address) {
        return ERC721PsiAirdropStorage.layout().airdropListPointers[index];
    }

    function nextPointerIndex() public view virtual returns (uint16) {
        return ERC721PsiAirdropStorage.layout().nextPointerIndex;
    }

    function airdropListPointersLength() external view virtual returns (uint256) {
        return ERC721PsiAirdropStorage.layout().airdropListPointers.length;
    }

    // =============================================================
    //     AIRDROP MINT FUNCTION
    // =============================================================
    /**
     * @dev Internal airdrop mint function with airdrop list pointers
     * @param airdropPointerCount Count of pointers to be airdroped
     */
    function _airdropMint(uint256 airdropPointerCount) internal virtual {
        // If count is 0, revert.
        if (airdropPointerCount == 0) revert InvalidParameter();

        uint256 currentPointerIndex_ = uint256(ERC721PsiAirdropStorage.layout().nextPointerIndex);
        uint256 totalPointers = ERC721PsiAirdropStorage.layout().airdropListPointers.length;
        // If there are no airdropped pointers, revert.
        if (currentPointerIndex_ + 1 > totalPointers) revert UnairdroppedPointersNonExistent();
        // If last pointer index is out of bound, override index
        if (currentPointerIndex_ + airdropPointerCount > totalPointers) {
            airdropPointerCount = totalPointers - currentPointerIndex_;
        }
        // Preserve and iterate tokneId
        uint256 currentIndex_ = _currentIndex_().value;
        // Address length in pointer at stuck
        uint256 addressLengthInPointer_ = ERC721PsiAirdropStorage.layout().addressLengthInPointer;

        if (currentPointerIndex_ > 0) {
            // If airdrop has already started, currentIndex should be equal to estimated token ID.
            if (currentIndex_ != 
                ERC721PsiAirdropStorage.layout().startAirdropIndex
                + addressLengthInPointer_ * currentPointerIndex_
            ) revert AirdropConsistencyBroken();
        } else {
            // If airdrop does not start yet, set start airdrop tokenID as currentIndex.
            ERC721PsiAirdropStorage.layout().startAirdropIndex = uint32(currentIndex_);
        }

        // Address count contained in a pointer
        uint256 addressCount;
        // Return value from array property
        uint256 format;
        // Return value from array property
        uint256 codeSize;
        // Current processed pointer
        address currentPointer;
        // Owner for airdrop
        address currentOwner;

        // Until here, gas used : about 5200-5500 (optimizer 200)

        // Outer loop for address list
        for (uint256 i; i < airdropPointerCount; ) {
            // Get pointer
            currentPointer = ERC721PsiAirdropStorage.layout().airdropListPointers[currentPointerIndex_];
            // Read property of ImmutableArray
            (format, addressCount, codeSize) = currentPointer.readProperty();
            // Check consistency
            if (format != 20) revert InvalidArrayPointer();
            if (addressCount == 0) revert ZeroAddressLength();
            // Check address count
            if (currentPointerIndex_ < airdropPointerCount -1) {
                if (addressCount != addressLengthInPointer_) revert InvalidAddressLength(currentPointerIndex_);
            }

            // In outer loop, until here, gas used : about 1000 (optimizer 200)

            // Inner loop for token ID to emit `Transfer`.
            for (uint256 j; j < addressCount; ) { 
                currentOwner = currentPointer.readAddress_unchecked(j);
                if (currentOwner != _ZERO_ADDRESS) {
                    // This assembly emitting saves gas 39 and uses 2008 in each token.
                    assembly {
                        // Emit the `Transfer` event.
                        log4(
                            0, // Start of data (0, since no data).
                            0, // End of data (0, since no data).
                            _TRANSFER_EVENT_SIGNATURE, // Signature.
                            0x00, // `from`.
                            currentOwner, // `to`.
                            currentIndex_ // `tokenId`.
                        )
                    }
                } else {
                    _beforeAirdropZeroAddress(currentIndex_);
                }
                // increments
                unchecked {
                    ++j;
                    ++currentIndex_;
                }
            }
            // increments
            unchecked {
                ++i;
                ++currentPointerIndex_;
            }

        }
        // Set batchHead to all airdropped tokens
        //_batchHead_().setBatch(startIndex_, currentIndex_ - startIndex_);
        // Update currentIndex
        _currentIndex_().value = currentIndex_;
        // Update nextPointerIndex
        ERC721PsiAirdropStorage.layout().nextPointerIndex = uint16(currentPointerIndex_);
    }

    /**
     * @dev Internal before processing when token is airdropped to zero address.
     * Without burn, airdropping to zero address should be revert.
     * @param tokenId Airdropping token ID to zero address
     */
    function _beforeAirdropZeroAddress(uint256 tokenId) internal virtual {
        revert AirdropZeroAddress(tokenId);
    }

    // =============================================================
    //     ERC721Psi Override function
    // =============================================================
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) 
        internal 
        virtual 
        override
    {
        // Since this function is always called with quantity 1 when not minting,
        // only check bit of `startTokenId`.
        if (from != _ZERO_ADDRESS ) {
            if (!ERC721PsiAirdropStorage.layout().transferred.get(startTokenId)) {
                // If not transferred after airdropped, set bit as trasnferred.
                ERC721PsiAirdropStorage.layout().transferred.set(startTokenId);
            }
        } else {
            // If minting, set all bits as transferred.
            ERC721PsiAirdropStorage.layout().transferred.setBatch(startTokenId, quantity);
        }
        // Call parent function.
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        // Calculate airdropIndex because there is difference between it and token ID.
        // If not transferred, 
        if (!ERC721PsiAirdropStorage.layout().transferred.get(tokenId)) {
            // Check exisitence
            if (!_exists(tokenId)) revert NonExistentTokenId(tokenId);
            uint256 addressLength = uint256(ERC721PsiAirdropStorage.layout().addressLengthInPointer);
            uint256 nextPointerIndex_ = ERC721PsiAirdropStorage.layout().nextPointerIndex;
            uint256 airdropIndex = _getAirdropIndex(tokenId);
            uint256 pointerIndex = airdropIndex / addressLength;
            unchecked{
                // Check airdropped. If not, the airdrop consistency is broken.
                if ((pointerIndex + 1) > nextPointerIndex_) revert AirdropConsistencyBroken();
                uint256 addressIndex = airdropIndex % addressLength;
                return ERC721PsiAirdropStorage.layout()
                    .airdropListPointers[pointerIndex].readAddress_unchecked(addressIndex);
            }
        } else {
            return super.ownerOf(tokenId);
        }
    }

    function _getAirdropIndex(uint256 tokenId) internal view virtual returns (uint256) {
        return tokenId - ERC721PsiAirdropStorage.layout().startAirdropIndex;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721PsiUpgradeable) {
        if (!ERC721PsiAirdropStorage.layout().transferred.get(tokenId)) {
            address owner = ownerOf(tokenId);

            if (owner != from) revert TransferForNotOwnToken();
            if (to == address(0)) revert TransferToZeroAddress();

            _beforeTokenTransfers(from, to, tokenId, 1);

            // Clear approvals from the previous owner
            _approve(address(0), tokenId);   

            _owners[tokenId] = to;
            _batchHead_().set(tokenId);
            ERC721PsiAirdropStorage.layout().transferred.set(tokenId);
            _afterTokenTransfers(from, to, tokenId, 1);

            emit Transfer(from, to, tokenId);
        } else {
            ERC721PsiUpgradeable._transfer(from, to, tokenId);
        }

    }
}