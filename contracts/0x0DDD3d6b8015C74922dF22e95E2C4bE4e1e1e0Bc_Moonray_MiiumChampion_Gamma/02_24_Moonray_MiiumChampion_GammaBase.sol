// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/token/phased/PhasedMintOne.sol';
import '@nftculture/nftc-contract-library/contracts/token/ERC721AExpandable.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

// Error Codes
error ExceedsBatchSize();
error ExceedsPurchaseLimit();
error ExceedsSupplyCap();
error InvalidPayment();

/**
 * @title Moonray_MiiumChampion_GammaBase
 * @author @NFTCulture
 * @dev ERC721a Implementation with @NFTCulture standardized components.
 *
 * Public Mint is Phase One.
 */
abstract contract Moonray_MiiumChampion_GammaBase is
    ERC721AExpandable,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter,
    PhasedMintOne
{
    using Strings for uint256;

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;

    uint256 private constant PUBLIC_MINT_BATCH_SIZE = 10;
    uint256 private constant PUBLIC_MINT_PURCHASE_LIMIT = 1000;
    uint256 private constant PUBLIC_MINT_SUPPLY_CAP = 10000;

    string public baseURI;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits,
        uint256 __phaseOnePricePerNft
    )
        ERC721AExpandable(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        PhasedMintOne(__phaseOnePricePerNft)
        ExpandableTypedTokenExtension(true)
    {
        baseURI = __baseURI;
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
                    '"openEdition":false', // is collection an open edition? [true | false]
                    '}'
                )
            );
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return PUBLIC_MINT_BATCH_SIZE;
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

        TokenFlavor memory updatedFlavor = _canMint(count * friends.length, flavorId, false, 0);
        _saveTokenFlavor(updatedFlavor);

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
    function publicMintTokens(uint256 count, uint256 flavorId) external payable nonReentrant onlyUsers isPublicMinting {
        if (0 >= count || count > PUBLIC_MINT_BATCH_SIZE) revert ExceedsBatchSize();

        TokenFlavor memory updatedFlavor = _canMint(count, flavorId, true, msg.value);
        _saveTokenFlavor(updatedFlavor);

        _internalMintTokensOfFlavor(msg.sender, count, flavorId);
    }
}