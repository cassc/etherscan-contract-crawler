// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IMintableVillain.sol";
import "@limit-break/presets/BlacklistedTransferAdventureNFT.sol";
import "@limit-break/utils/tokens/SequentialRoleBasedMint.sol";

error VillainInputArrayLengthMismatch();
error UseOfMintEntrypointProhibittedUseUnmaskVillainsBatch();

/**
 * @title DigiDaigakuVillains
 * @author Limit Break, Inc.
 * @notice Villains unmasked by going on the DigiDaigaku Unmasking Quest.
 */
contract DigiDaigakuVillains is BlacklistedTransferAdventureNFT, SequentialRoleBasedMint, IMintableVillain {

    uint256 private constant ENTRYPOINT_UNMASK = 1;
    uint256 private constant ENTRYPOINT_UNMASK_VILLAINS_BATCH = 2;

    uint256 private unmaskFunctionEntrypoint;

    /// @dev Emitted when a villain is minted
    event UnmaskVillain(address indexed to, uint256 indexed superVillainId, uint256 maskedVillainId, uint256 potionTokenId);

    constructor(uint256 maxSupply_, address royaltyReceiver_, uint96 royaltyFeeNumerator_) ERC721("", "") {
        initializeERC721("DigiDaigakuVillains", "DIDV");
        initializeURI("https://digidaigaku.com/villains/metadata/", ".json");
        initializeAdventureERC721(100);
        initializeRoyalties(royaltyReceiver_, royaltyFeeNumerator_);
        initializeMaxSupply(maxSupply_);
        initializeOperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);

        unmaskFunctionEntrypoint = ENTRYPOINT_UNMASK;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
        return interfaceId == type(IMaxSupplyInitializer).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Mints multiple villains unmasked with the specified masked villain tokens.
    ///
    /// Throws if `to` address is zero address.
    /// Throws if the quantity is zero.
    /// Throws if the caller is not a whitelisted minter.
    /// Throws if minting would exceed the max supply.
    ///
    /// Postconditions:
    /// ---------------
    /// `quantity` villains have been minted to the specified `to` address, where `quantity` is the length of the token id arrays.
    /// `quantity` UnmaskVillain events has been emitted, where `quantity` is the length of the token id arrays.
    function unmaskVillainsBatch(address to, uint256[] calldata maskedVillainTokenIds, uint256[] calldata potionTokenIds) external override {

        if(maskedVillainTokenIds.length != potionTokenIds.length) {
            revert VillainInputArrayLengthMismatch();
        }

        unmaskFunctionEntrypoint = ENTRYPOINT_UNMASK_VILLAINS_BATCH;
        (uint256 firstVillainId,) = mint(to, potionTokenIds.length);
        unmaskFunctionEntrypoint = ENTRYPOINT_UNMASK;
        
        unchecked {
            for(uint256 i = 0; i < potionTokenIds.length; ++i) {
                if(potionTokenIds[i] > 0) { 
                    emit UnmaskVillain(to, firstVillainId + i, maskedVillainTokenIds[i], potionTokenIds[i]);
                }
            }
        }
    }

    /// @notice Direct use of the mint function is prohibitted in this contract.
    /// Throws if not called from unmaskVillainsBatch.
    /// Otherwise, functions according to the base contract mint implementation.
    function mint(address to, uint256 quantity) public override returns (uint256 firstTokenId, uint256 lastTokenId) {
        if(unmaskFunctionEntrypoint != ENTRYPOINT_UNMASK_VILLAINS_BATCH) {
            revert UseOfMintEntrypointProhibittedUseUnmaskVillainsBatch();
        }

        return super.mint(to, quantity);
    }

    /// @dev Mints a token
    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}