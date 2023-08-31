// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//                                      ╓▓███▓╩▀▀                           impossibletrios@nightwatch
//                                      █▓▓█╕                               ----------
//                                     █▓▄█░░▒                              OS: Ethereum Virtual Machine
//                                    █████▒░░                              Standard: ERC721
//                   ┌╖╥╖░▄▓▓╖       ╒▓▓██░░░▒                              Unique Trios: (n=15, r=3)=455
//            ╓░░ ░░▒▓▓▓▓▓█▓▓▓       █▌██▓▒░▒╢                              Total Frames: 455x15=6825
//         ▄▄▓▓▓▒╥▓▓██▒▒▒██▓█▓▌      ████▓▒▒╫    ▄███████████▓▓▓            Web2: https://impossibletrios.art
//        ▐██████████▓╣▓▀▀██▌       ▐███▓▓▒▒╝  ╓█████████████▓█▓▓           Bird App: https://x.com/nightwatchwalks
//         ███████▀█▓▓     ▀█▓      ▐███▒▒╫▓   ▓█▓▓▓▓▓▓█████▀▀▀███          Strolling Since: 2023
//      ╓▄▄███▀▀████▓▀      ▀█▓╗    ▐███▌▒╩    ▌██▓▓██▀█████    █▀─         Dreamer: @KaybidSteps
//    ▐█▀▀▀▀     ▀▓▓           ▀▓  ▄███▀█▒     ▀█▀ █    ████    █           Dream Maker: @YigitDuman
//               ╓▓███▄         ██╩  ██▄╓▀█▄▄  ▐█  ▐█═ █▀▀█▌    █           Steps: Silent

import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC721ABurnable, ERC721A, IERC721A} from "erc721a/extensions/ERC721ABurnable.sol";
import {NightWatchUtils} from "./NightWatchUtils.sol";
import {NightWatchMetadata} from "./NightWatchMetadata.sol";
import {IERC4906} from "./interfaces/IERC4906.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ERC20} from "solady/tokens/ERC20.sol";

/// @title Night Watch - Impossible Trios
/// @notice An experimental, unique and deflationary art collection of animal crews walking around the night.
/// @author @YigitDuman
/// 🐳🦁🐵🦒🦌🦬🐘🦏🐢🐬🐾🐧🐼🦭🦄
contract NightWatch is
    ERC721ABurnable,
    Owned,
    IERC4906,
    OperatorFilterer,
    ERC2981,
    ReentrancyGuard
{
    /*//////////////////////////////////////////////////////////////
                               TOKEN DATA
    //////////////////////////////////////////////////////////////*/

    /// @notice Frame and set data of each token.
    /// @dev Token set/frame bitmap array. Each token uses 24 bits:
    /// [0-9] - Set id in binary. Sets start from 1. 0 represents burned.
    /// [9-23] - Each digit represents a frame. 1 means frame is filled, 0 means empty.
    uint24[] private _tokenData;

    /*//////////////////////////////////////////////////////////////
                           OWNERSHIP MAPPING
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping of addresses and their owned token ids.
    /// @dev Value mapping represents index of the token in the owners tokens -> token ID.
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    /// @notice Mapping from token ID to index of the token in the owners tokens.
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /*//////////////////////////////////////////////////////////////
                             MINT VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The initial maximum supply of the collection.
    /// Also reflects total amount of unique frames. (455 sets of animals * 15 frames)
    uint256 public immutable maxSupply = 6825;

    /*//////////////////////////////////////////////////////////////
                                 STATES
    //////////////////////////////////////////////////////////////*/

    /// @notice Manual token data manipulation lock (will be locked after reveal)
    bool private _tokenDataLocked;

    /// @notice Changing metadata contract lock (will be locked after an on-chain, decentralized metadata generation contract made)
    bool private _metadataLocked;

    /// @notice Merge pause lock (will be locked after reveal)
    bool private _mergePauseLocked;

    /// @notice Transfer pause lock (will be locked after reveal)
    bool private _transferPauseLocked;

    /// @notice Vault change lock
    bool private _vaultChangeLocked;

    /// @notice State of transfer pause.
    bool private _transfersPaused;

    /// @notice State of merge pause.
    bool private _mergePaused = true;

    /// @notice State of operator filtering.
    bool private _operatorFiltering = true;

    /// @notice Operator filtering lock.
    bool private _operatorFilteringLocked;

    /// @notice Total merge count
    uint256 public totalMergeCount;

    /*//////////////////////////////////////////////////////////////
                               ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Metadata contract to provide tokenURI.
    NightWatchMetadata private _nightWatchMetadata;

    /// @notice Address of the vault contract.
    address private _vaultAddress;

    /// @notice Address of the priority operator.
    address private _priorityOperator =
        address(0x1E0049783F008A0085193E00003D00cd54003c71);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event FirstStep();
    event Merge(
        uint256 indexed tokenId,
        uint256 indexed tokenIdBurned,
        uint256 oldTokenData,
        uint256 updatedTokenData,
        address owner
    );
    event MergePaused(bool isPaused);
    event TransfersPaused(bool isPaused);
    event MetadataAddressChanged(address newAddress);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error CannotBurnDuringMergePause();
    error CannotTransferDuringTransferPause();
    error CannotQueryZeroAddress();
    error CannotQueryVaultAddress();
    error MergePauseLocked();
    error TransferPauseLocked();
    error MetadataLocked();
    error MaxSupplyExceeded();
    error TokenDataChangeLocked();
    error TokenDataNotFound();
    error CannotMergeForVaultAddress();
    error CannotWithdrawToZeroAddress();
    error TokenDataNotFilled();
    error WrongTokenOrder();
    error SetMismatch();
    error TokenOwnerMismatch();
    error VaultChangeLocked();
    error TogglingOperatorFilteringLocked();
    error NoFunds();
    error NoZeroAddress();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the metadata contract address and emit the FirstStep event in constructor.
    constructor(
        address nightWatchMetadataAddress,
        address vaultAddress,
        uint96 defaultRoyalties,
        address royaltyReceiver
    ) ERC721A("Night Watch", "NW") Owned(msg.sender) {
        // Register for operator filtering.
        _registerForOperatorFiltering();

        // Set default royalty.
        _setDefaultRoyalty(royaltyReceiver, defaultRoyalties);

        // Set metadata contract address.
        _nightWatchMetadata = NightWatchMetadata(nightWatchMetadataAddress);

        // Ensure vault address is not zero.
        if (vaultAddress == address(0)) revert NoZeroAddress();
        // Set vault address.
        _vaultAddress = vaultAddress;

        // Hello world! 🐾
        emit FirstStep();
    }

    /*//////////////////////////////////////////////////////////////
                            CONTRACT STATES
    //////////////////////////////////////////////////////////////*/

    /// @notice Owner only function to lock certain variables.
    /// @param tokenData Lock token data manipulation.
    /// @param metadata Lock metadata contract change.
    /// @param mergePause Lock merge pause.
    /// @param transferPause Lock transfer pause.
    /// @param vaultChange Lock vault change.
    /// @param operatorFiltering Lock operator filtering toggle.
    function lockState(
        bool tokenData,
        bool metadata,
        bool mergePause,
        bool transferPause,
        bool vaultChange,
        bool operatorFiltering
    ) external onlyOwner {
        // Set variables and ensure locked state can't change after being locked.
        _tokenDataLocked = tokenData || _tokenDataLocked;
        _metadataLocked = metadata || _metadataLocked;
        _mergePauseLocked = mergePause || _mergePauseLocked;
        _transferPauseLocked = transferPause || _transferPauseLocked;
        _vaultChangeLocked = vaultChange || _vaultChangeLocked;
        _operatorFilteringLocked =
            operatorFiltering ||
            _operatorFilteringLocked;

        // Cancel pauses if they are locked.
        _mergePaused = !_mergePauseLocked && _mergePaused;
        _transfersPaused = !_transferPauseLocked && _transfersPaused;
        _operatorFiltering = !_operatorFilteringLocked && _operatorFiltering;
    }

    /// @notice Owner only function to pause merge events.
    /// @param state Merge pause state.
    function setMergePaused(bool state) external onlyOwner {
        // Ensure merge pause is not locked.
        if (_mergePauseLocked) revert MergePauseLocked();

        _mergePaused = state;

        emit MergePaused(state);
    }

    /// @notice Owner only function to pause transfer events.
    /// @param state Transfer pause state.
    function setTransfersPaused(bool state) external onlyOwner {
        // Ensure transfer pause is not locked.
        if (_transferPauseLocked) revert TransferPauseLocked();

        _transfersPaused = state;

        emit TransfersPaused(state);
    }

    /// @notice Owner only function to toggle operator filtering.
    /// @param state Operator filtering state.
    function setOperatorFilteringEnabled(bool state) external onlyOwner {
        // Ensure operator filtering is not locked.
        if (_operatorFilteringLocked) revert TogglingOperatorFilteringLocked();

        _operatorFiltering = state;
    }

    /// @notice Owner only function to set the default royalty.
    /// @param receiver Address of the royalty receiver.
    /// @param feeNumerator Numerator of the royalty fee.
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /*//////////////////////////////////////////////////////////////
                           CONTRACT ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Owner only function to set metadata address.
    /// @param nightWatchMetadataAddress Address of the metadata contract.
    function setMetadataAddress(
        address nightWatchMetadataAddress
    ) external onlyOwner {
        // Ensure metadata is not locked.
        if (_metadataLocked) revert MetadataLocked();

        _nightWatchMetadata = NightWatchMetadata(nightWatchMetadataAddress);

        emit MetadataAddressChanged(nightWatchMetadataAddress);
        if (_nextTokenId() > 0) {
            emit BatchMetadataUpdate(0, _nextTokenId() - 1);
        }
    }

    /// @notice Owner only function to set the vault address.
    /// @param vaultAddress Address of the vault.
    function setVaultAddress(address vaultAddress) external onlyOwner {
        // Ensure transfer pause is not locked.
        if (_vaultChangeLocked) revert VaultChangeLocked();

        // Ensure vault address is not 0.
        if (vaultAddress == address(0)) revert NoZeroAddress();

        _vaultAddress = vaultAddress;
    }

    /// @notice Owner only function to set the priority operator.
    /// @param priorityOperator Address of the priority operator.
    function setPriorityOperator(address priorityOperator) external onlyOwner {
        _priorityOperator = priorityOperator;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Owner only function to mint new tokens to a specified address.
    /// To be used for testing and failover purposes.
    /// @param to Address to mint tokens to.
    /// @param amount Amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        // Ensure we are not exceeding the max supply.
        if (_nextTokenId() + amount > maxSupply) revert MaxSupplyExceeded();

        _mint(to, amount);
    }

    /// @notice Mint all the remaining tokens in batches to the vault.
    /// Minting in batches to keep the transfer gas low after mint out.
    /// Magic numbers below are tweaked for an acceptable gas usage for both owners and the holders.
    function mintRemainingSupplyToVault() external onlyOwner {
        // Check if the remaining supply is more than 0
        uint256 remainingSupply = maxSupply - _nextTokenId();
        if (remainingSupply == 0) revert MaxSupplyExceeded();

        // Get the leftover supply by getting the modulo of 50.
        uint256 leftOver = remainingSupply % 50;

        // Get the remaining supply without the leftover.
        uint256 remainingSupplyWithoutLeftOver = remainingSupply - leftOver;

        // Mint the remaining supply without the leftover in batches of 50.
        if (remainingSupplyWithoutLeftOver > 0) {
            uint256 iterationSize = remainingSupplyWithoutLeftOver / 50;
            for (uint256 i; i < iterationSize; ) {
                _mint(_vaultAddress, 50);
                unchecked {
                    ++i;
                }
            }
        }

        // Mint the leftover supply.
        if (leftOver > 0) {
            _mint(_vaultAddress, leftOver);
        }
    }

    /// @dev Transfers `tokenId` from `from` to `to`.
    /// @param from Current owner of the token.
    /// @param to Address to receive the token.
    /// @param tokenId Which token to transfer.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        virtual
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        // Revert transfers if the transfers are paused.
        if (_transfersPaused) {
            revert CannotTransferDuringTransferPause();
        }

        super.transferFrom(from, to, tokenId);
    }

    /// @notice Function to run before token transfers.
    /// @param from Address of the sender.
    /// @param to Address of the receiver.
    /// @param startTokenId Starting token ID.
    /// @param quantity Amount of tokens.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // Revert burning if the merge is paused.
        if (_mergePaused && to == address(0)) {
            revert CannotBurnDuringMergePause();
        }

        // Update ownership mappings.
        _updateOwnership(from, to, startTokenId, quantity);
    }

    /// @notice Function to run after token transfers.
    /// @param to Address of the receiver.
    /// @param startTokenId Id of the first token transferred.
    /// @param quantity Number of tokens transferred.
    function _afterTokenTransfers(
        address,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // Check if the token is burned.
        if (to == address(0)) {
            // Check if tokenData exists.
            if (_tokenData.length <= startTokenId) return;

            // Clear tokenData.
            _tokenData[startTokenId] = 0;
            return;
        }

        // Return if merge is paused.
        if (_mergePaused) return;

        // Check if the tokenData is filled, revert if not.
        unchecked {
            if (_tokenData.length <= startTokenId + quantity - 1)
                revert TokenDataNotFilled();
        }

        // Return if transferred to the vault to prevent merge.
        if (to == _vaultAddress) {
            return;
        }

        // Try to merge the token transferred
        _tryMerge(startTokenId, getSet(startTokenId), to);
    }

    /// @notice Add ERC-4906 support
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == bytes4(0x49064906) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /// @notice Get token URI for specified token.
    /// @param tokenId Token ID
    /// @return string Token URI
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return _nightWatchMetadata.tokenURI(tokenId);
    }

    /// @notice Get the next token id that will be minted. (unless max supply exceeded)
    function getNextToken() external view returns (uint256) {
        return _nextTokenId();
    }

    /// @notice Get the number of tokens minted by the address.
    /// @param addr Address to get the number of minted tokens.
    /// @return uint256 Number of minted tokens.
    function getNumberMinted(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    /// @notice Overriden set approval for all function to activate operator filtering.
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @notice Overriden approve function to activate operator filtering.
    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            TOKEN OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the amount of tokens the address minted.
    /// @param addr Address to check.
    function getOwnedTokens(
        address addr
    ) public view returns (uint256[] memory tokens) {
        // Ensure address is not zero.
        if (addr == address(0)) revert CannotQueryZeroAddress();

        // Ensure address is not vault.
        if (addr == _vaultAddress) revert CannotQueryVaultAddress();

        // Get the balance of the address.
        uint256 balance = balanceOf(addr);

        // Initialize the array.
        tokens = new uint256[](balance);
        for (uint256 i; i < balance; ) {
            tokens[i] = _ownedTokens[addr][i];
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Update token ownership mappings before transfers.
    /// @param from Address of the sender.
    /// @param to Address of the receiver.
    /// @param startTokenId Starting token ID.
    /// @param quantity Amount of tokens.
    function _updateOwnership(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) private {
        // Return if minted to the vault.
        // Vault address is not included in the ownership enumeration to keep the gas reasonable and to prevent merge.
        if (from == address(0) && to == _vaultAddress) {
            return;
        }

        // Initialize the balance.
        uint256 balance;
        if (to != address(0)) {
            balance = balanceOf(to);
        }

        // Get the end token id.
        uint256 endTokenId;
        unchecked {
            endTokenId = startTokenId + quantity;
        }

        // Loop through the tokens and update the owner enumerations.
        for (uint256 i = startTokenId; i < endTokenId; ) {
            uint256 tokenId = i;
            if (from != to) {
                if (from != address(0) && from != _vaultAddress) {
                    _removeTokenFromOwnerEnumeration(from, tokenId);
                }
                if (to != address(0) && to != _vaultAddress) {
                    _addTokenToOwnerEnumeration(to, tokenId, balance);
                }
            }
            unchecked {
                ++balance;
                ++i;
            }
        }
    }

    /**
     * @dev Add a token to the ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(
        address to,
        uint256 tokenId,
        uint256 length
    ) private {
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Remove a token from the ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws the funds from the contract.
    /// @param withdrawAddress Address to withdraw the funds to.
    /// @param amount Amount of funds to withdraw.
    function withdraw(
        address withdrawAddress,
        uint256 amount
    ) external onlyOwner {
        // Check if the withdraw address is valid.
        if (withdrawAddress == address(0)) revert CannotWithdrawToZeroAddress();

        uint256 balance = address(this).balance;

        // Revert if there are no funds
        if (balance == 0) {
            revert NoFunds();
        }

        // Limit the amount to the contract balance.
        if (amount > balance) {
            amount = balance;
        }

        // Send the funds.
        SafeTransferLib.safeTransferETH(withdrawAddress, amount);
    }

    /// @notice Withdraws the ERC20 funds from the contract.
    function withdrawERC20(
        address withdrawAddress,
        uint256 amount,
        ERC20 token
    ) external onlyOwner nonReentrant {
        // Check if the withdraw address is valid.
        if (withdrawAddress == address(0)) revert CannotWithdrawToZeroAddress();

        uint256 balance = token.balanceOf(address(this));
        // Revert if there are no funds
        if (balance == 0) {
            revert NoFunds();
        }

        // Limit the amount to the contract balance.
        if (amount > balance) {
            amount = balance;
        }

        // Send the funds.
        token.transfer(withdrawAddress, amount);
    }

    /*//////////////////////////////////////////////////////////////
                         MERGE TOKEN DATA LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Owner only function to fill token data.
    /// @param tokenData Array of token data.
    function fillTokenData(uint24[] calldata tokenData) external onlyOwner {
        // Revert if the manual token data manipulation is locked.
        if (_tokenDataLocked) revert TokenDataChangeLocked();

        // Fill token data.
        uint256 tokenDataLength = tokenData.length;
        unchecked {
            for (uint256 i; i < tokenDataLength; ++i) {
                _tokenData.push(tokenData[i]);
            }
        }
    }

    /// @notice Owner only function to clear token data.
    /// Might be useful to fix a mistaken token data fill.
    function clearTokenData() external onlyOwner {
        // Revert if the manual token data manipulation is locked.
        if (_tokenDataLocked) revert TokenDataChangeLocked();

        // Clear token data.
        delete _tokenData;
    }

    /// @notice Owner only function to replace token data.
    /// @param tokenId Id of the token to replace its data
    /// @param data New data to replace the old one.
    function replaceTokenData(uint256 tokenId, uint24 data) external onlyOwner {
        // Revert if the manual token data manipulation is locked.
        if (_tokenDataLocked) revert TokenDataChangeLocked();

        // Revert if the token data is not found.
        if (_tokenData.length <= tokenId) revert TokenDataNotFound();

        // Replace token data.
        _tokenData[tokenId] = data;
    }

    /*//////////////////////////////////////////////////////////////
                             MERGE GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the set id of the specified token.
    /// @param tokenId Id of the token to get its set.
    /// @return uint24 Set id of the token.
    function getSet(uint256 tokenId) public view returns (uint24) {
        // Revert if the token data is not found.
        if (_tokenData.length <= tokenId) revert TokenDataNotFound();

        // Return the set id by bit shifting.
        return _tokenData[tokenId] >> 15;
    }

    /// @notice Get the frames of the specified token.
    /// @param tokenId Id of the token to get its frames.
    /// @return frames Array of binary integers that specifies frames.
    function getFrames(
        uint256 tokenId
    ) external view returns (uint256[15] memory frames) {
        // Revert if the token data is not found.
        if (_tokenData.length <= tokenId) revert TokenDataNotFound();

        // Get the token data.
        uint24 data = _tokenData[tokenId];

        // Iterate over the frames and set them.
        for (uint256 i; i < 15; ) {
            frames[i] = data & (1 << i) > 0 ? 1 : 0;
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              MERGE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Iterate over all tokens of the address and try to merge them with the provided token.
    /// @param tokenId The token id of the token to merge.
    /// @param set The set id of the token.
    /// @param tokenOwner The address of the token owner.
    function _tryMerge(
        uint256 tokenId,
        uint24 set,
        address tokenOwner
    ) private {
        // Get all tokens of the address.
        uint256[] memory tokensOfAddress = getOwnedTokens(tokenOwner);

        // Get the length of the tokens of address.
        uint256 tokensOfAddressLength = tokensOfAddress.length;

        // Iterate over all tokens of the address.
        for (uint256 i; i < tokensOfAddressLength; ) {
            // Get the token id of the looped token.
            uint256 otherTokenId = tokensOfAddress[i];

            // Skip if the looped token is the same with the provided token.
            if (tokenId != otherTokenId) {
                // Skip if the looped token's set is not the same with the provided token's set.
                if (getSet(otherTokenId) == set) {
                    // Sort the token ids.
                    (uint256 smallTokenId, uint256 bigTokenId) = NightWatchUtils
                        .sortTokens(tokenId, otherTokenId);

                    // Merge the tokens.
                    _merge(smallTokenId, bigTokenId, tokenOwner);

                    // This function will only be used after single token transfers, thus we don't need to complete iteration.
                    return;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Merge the provided tokens.
    /// @dev It is assumed that the token ids are sorted, and all the checks made.
    /// @param smallTokenId The token id of the smaller token.
    /// @param bigTokenId The token id of the bigger token.
    /// @param tokenOwner The address of the token owner.
    function _merge(
        uint256 smallTokenId,
        uint256 bigTokenId,
        address tokenOwner
    ) private {
        // Get the old token's data.
        uint256 oldTokenData = _tokenData[smallTokenId];

        // Merge the frames of the two tokens.
        _tokenData[smallTokenId] |= _tokenData[bigTokenId];

        // Burn the token with the big id.
        _burn(bigTokenId);

        // Clear token data.
        _tokenData[bigTokenId] = 0;

        // Increase total merge count.
        totalMergeCount++;

        // Emit Merge event.
        emit Merge(
            smallTokenId,
            bigTokenId,
            oldTokenData,
            _tokenData[smallTokenId],
            tokenOwner
        );

        // Emit MetadataUpdate event
        emit MetadataUpdate(smallTokenId);
        emit MetadataUpdate(bigTokenId);
    }

    /*//////////////////////////////////////////////////////////////
                 EXTERNAL MERGE FUNCTIONS FOR FAILOVERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Merge the provided tokens.
    /// @param tokenArray Array of tokens to merge array
    /// It is assumed that all the tokens are sorted ascendingly.
    function tryMergeTokenArray(uint256[][] calldata tokenArray) external {
        uint256 tokenArrayLength = tokenArray.length;

        // Iterate over the token arrays.
        for (uint256 i; i < tokenArrayLength; ) {
            uint256[] memory tokens = tokenArray[i];
            uint256 tokensCount = tokens.length;

            // Set the small token id as the first token of the array.
            uint256 smallTokenId = tokens[0];

            // Iterate over the tokens
            for (uint256 j = 1; j < tokensCount; ) {
                uint256 tokenId = tokens[j];

                // Merge the tokens.
                tryMergeTwoTokens(smallTokenId, tokenId);
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Try to merge provided tokens.
    /// @param smallTokenId The token id of the smaller token.
    /// @param bigTokenId The token id of the bigger token.
    function tryMergeTwoTokens(
        uint256 smallTokenId,
        uint256 bigTokenId
    ) public {
        // Revert if the tokens are sorted incorrectly.
        if (smallTokenId >= bigTokenId) {
            revert WrongTokenOrder();
        }

        // Revert if the token data is not filled.
        if (_tokenData.length <= bigTokenId) revert TokenDataNotFilled();

        // Get the set of the tokens.
        uint24 set = getSet(smallTokenId);
        uint24 setOfBigTokenId = getSet(bigTokenId);

        // Revert if the sets are not the same.
        if (setOfBigTokenId != set) {
            revert SetMismatch();
        }

        // Get the owner of the tokens.
        address tokenOwner = ownerOf(smallTokenId);

        // Revert if the owners are not the same.
        if (tokenOwner != ownerOf(bigTokenId)) {
            revert TokenOwnerMismatch();
        }

        // Not checking if the owner is zero address since ownerOf can't return address(0)
        // Revert if the owner is vault address
        if (tokenOwner == _vaultAddress) {
            revert CannotMergeForVaultAddress();
        }

        // Merge if all checks passed
        _merge(smallTokenId, bigTokenId, tokenOwner);
    }

    /*//////////////////////////////////////////////////////////////
                           OPERATOR FILTERING
    //////////////////////////////////////////////////////////////*/

    /// @notice Override the _operatorFiltering.
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return _operatorFiltering;
    }

    /// @notice Override the _isPriorityOperator.
    function _isPriorityOperator(
        address operator
    ) internal view override returns (bool) {
        return operator == _priorityOperator;
    }
}