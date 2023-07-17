// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import '@nftculture/nftc-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contracts-private/contracts/token/ERC721A_NFTCExtended_Expandable.sol';
import '@nftculture/nftc-contracts-private/contracts/token/phased/expandable/ExpandablePhasedMintOne.sol';
import '@nftculture/nftc-contracts-private/contracts/token/PrivilegedMinter.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

// Error Codes
error ExceedsBatchSize();
error ExceedsPurchaseLimit();
error ExceedsSupplyCap();
error InvalidPayment();

/**
 * @title NeonIstOpenEditionBase
 * @author @NFTCulture
 * @dev ERC721a Implementation with @NFTCulture standardized components.
 *
 * Public Mint is Phase One.
 */
abstract contract NeonIstOpenEditionBase is
    ERC721A_NFTCExtended_Expandable,
    ReentrancyGuard,
    LockedPaymentSplitter,
    ExpandablePhasedMintOne,
    PrivilegedMinter
{
    using Strings for uint256;

    bytes32 public constant PRODUCT_MANAGER_ROLE = keccak256('PRODUCT_MANAGER_ROLE');

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;
    uint256 private constant PUBLIC_MINT_BATCH_SIZE = 10;
    uint256 private constant PUBLIC_MINT_SUPPLY_CAP = 99999; // Open edition

    string public baseURI;

    address private constant CROSSMINT = address(0xdAb1a1854214684acE522439684a145E62505233);

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits
    )
        ERC721A_NFTCExtended_Expandable(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        ExpandablePhasedMintOne()
        ExpandableTypedTokenExtension(true)
        PrivilegedMinter(CROSSMINT)
    {
        _grantRole(PRODUCT_MANAGER_ROLE, msg.sender);
        
        baseURI = __baseURI;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function nftcContractDefinition() external pure returns (string memory) {
        // NFTC Contract Definition for front-end websites.
        return
            string(
                abi.encodePacked(
                    '{',
                    '"ncdVersion":1,', // NFTC Contract Definition version.
                    '"phases":1,', // # of mint phases?
                    '"type":"Expandable",', // do tokens have a type? [Static | Expandable]
                    '"openEdition":true', // is collection an open edition? [true | false]
                    '}'
                )
            );
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return PUBLIC_MINT_BATCH_SIZE;
    }

    function getPublicMintPricePerNft(uint256 flavorId) external view virtual override returns (uint256) {
        return _getFlavorInfo(flavorId).price;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri; 
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
    * @notice Owner: reserve tokens for team.
    *
    * @param friends addresses to send tokens to.
    * @param count the number of tokens to mint.
    * @param flavorId the type of tokens to mint.
    */
    function reserveTokens(  
        address[] memory friends,
        uint256 count,
        uint256 flavorId
    ) external payable onlyOwner {
        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsBatchSize();

        FlavorInfo memory updatedFlavor = _canMint(count * friends.length, flavorId, false, 0);
        _saveFlavorInfo(updatedFlavor);

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokensOfFlavor(friends[idx], count, flavorId);
        }
    }

    /**
    * @notice Mint tokens - purchase bound by terms & conditions of project.
    *
    * @param count the number of tokens to mint.
    * @param flavorId the type of tokens to mint.
    */
    function publicMintTokens(uint256 count, uint256 flavorId) external payable nonReentrant isPublicMinting {
        if (0 >= count || count > PUBLIC_MINT_BATCH_SIZE) revert ExceedsBatchSize();

        FlavorInfo memory updatedFlavor = _canMint(count, flavorId, true, msg.value);
        _saveFlavorInfo(updatedFlavor);

        _internalMintTokensOfFlavor(msg.sender, count, flavorId);
    }

    /**
     * @notice Same as publicMintTokens(), but with a "to" for purchasing / custodial wallet platforms.
     *
     * @param count the number of tokens to mint.
     * @param flavorId the type of tokens to mint.
     * @param to address where the new token should be sent.
     */
    function publicMintTokensTo(
        uint256 count,
        uint256 flavorId,
        address to
    ) external payable nonReentrant isPublicMinting onlyPrivilegedMinter {
        if (0 >= count || count > PUBLIC_MINT_BATCH_SIZE) revert ExceedsBatchSize();

        FlavorInfo memory updatedFlavor = _canMint(count, flavorId, true, msg.value);
        _saveFlavorInfo(updatedFlavor);

        _internalMintTokensOfFlavor(to, count, flavorId);
    }
}