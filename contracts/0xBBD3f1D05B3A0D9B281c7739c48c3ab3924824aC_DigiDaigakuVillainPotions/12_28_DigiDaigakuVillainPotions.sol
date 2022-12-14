// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IMintablePotion.sol";
import "limit-break-contracts/contracts/adventures/AdventureNFT.sol";
import "limit-break-contracts/contracts/utils/tokens/SequentialRoleBasedMint.sol";

error BatchSizeMustBeGreaterThanOne();
error InputArrayLengthMismatch();
error UseOfMintEntrypointProhibittedUseMintPotionsBatch();

/**
 * @title DigiDaigakuVillainsPotions
 * @author Limit Break, Inc.
 * @notice An Adventure ERC-721 token that upgrades villains.
 */
contract DigiDaigakuVillainPotions is AdventureNFT, SequentialRoleBasedMint, IMintablePotion {

    uint256 private constant ENTRYPOINT_MINT = 1;
    uint256 private constant ENTRYPOINT_MINT_POTIONS_BATCH = 2;

    uint256 private mintFunctionEntrypoint;

    /// @dev Emitted when a potion is minted
    event MintPotion(address indexed to, uint256 indexed potionId, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId);

    constructor(uint256 maxSupply_, address royaltyReceiver_, uint96 royaltyFeeNumerator_) ERC721("", "") {
        initializeERC721("DigiDaigakuVillainPotions", "DIDVP");
        initializeURI("https://digidaigaku.com/villainpotions/metadata/", ".json");
        initializeAdventureERC721(10);
        initializeRoyalties(royaltyReceiver_, royaltyFeeNumerator_);
        initializeMaxSupply(maxSupply_);
        
        mintFunctionEntrypoint = ENTRYPOINT_MINT;
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
        return
        interfaceId == type(IMaxSupplyInitializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /// @notice Mints multiple potions crafted with the specified dark spirit and dark hero spirit tokens.
    ///
    /// Throws if `to` address is zero address.
    /// Throws if the quantity is zero.
    /// Throws if the caller is not a whitelisted minter.
    /// Throws if minting would exceed the max supply.
    /// Throws if token id array lengths don't match.
    ///
    /// Postconditions:
    /// ---------------
    /// `quantity` potions have been minted to the specified `to` address, where `quantity` is the length of the token id arrays.
    /// `quantity` MintPotion events has been emitted, where `quantity` is the length of the token id arrays.
    function mintPotionsBatch(address to, uint256[] calldata darkSpiritTokenIds, uint256[] calldata darkHeroSpiritTokenIds) external override {
        if(darkHeroSpiritTokenIds.length != darkSpiritTokenIds.length) {
            revert InputArrayLengthMismatch();
        }

        mintFunctionEntrypoint = ENTRYPOINT_MINT_POTIONS_BATCH;
        (uint256 firstPotionId,) = mint(to, darkSpiritTokenIds.length);
        mintFunctionEntrypoint = ENTRYPOINT_MINT;
        
        unchecked {
            for(uint256 i = 0; i < darkSpiritTokenIds.length; ++i) {
                emit MintPotion(to, firstPotionId + i, darkSpiritTokenIds[i], darkHeroSpiritTokenIds[i]);
            }
        }
    }

    /// @notice Direct use of the mint function is prohibitted in this contract.
    /// Throws if not called from mintPotionsBatch.
    /// Otherwise, functions according to the base contract mint implementation.
    function mint(address to, uint256 quantity) public override returns (uint256 firstTokenId, uint256 lastTokenId) {
        if(mintFunctionEntrypoint == ENTRYPOINT_MINT) {
            revert UseOfMintEntrypointProhibittedUseMintPotionsBatch();
        }

        return super.mint(to, quantity);
    }

    /// @dev Mints a token
    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}