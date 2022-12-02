// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/token/ERC721A_NFTCExtended.sol';
import '@nftculture/nftc-contract-library/contracts/token/phased/PhasedMintOne.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

// Error Codes
error ExceedsBatchSize();
error ExceedsPurchaseLimit();
error ExceedsSupplyCap();
error InvalidPayment();

/**
 * @title Dr3amLabsComingSoonBase
 * @author @NiftyMike | @NFTCulture
 * @dev ERC721a Implementation with @NFTCulture standardized components.
 *
 * Public Mint is Phase One.
 */
abstract contract Dr3amLabsComingSoonBase is
    ERC721A_NFTCExtended,
    ReentrancyGuard,
    LockedPaymentSplitter,
    PhasedMintOne
{
    using Strings for uint256;

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 1;

    uint256 private constant PUBLIC_MINT_BATCH_SIZE = 1;
    uint256 private constant PUBLIC_MINT_PURCHASE_LIMIT = 1; // Not Used
    uint256 private constant PUBLIC_MINT_SUPPLY_CAP = 1;

    string public baseURI;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits,
        uint256 __phaseOnePricePerNft
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        PhasedMintOne(__phaseOnePricePerNft)
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
                    '"type":"Static",', // do tokens have a type? [Static | Expandable]
                    '"openEdition":false', // is collection an open edition? [true | false]
                    '}'
                )
            );
    }

    function maxSupply() external pure returns (uint256) {
        return PUBLIC_MINT_SUPPLY_CAP;
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

    function _tokenFilename(uint256 tokenId) internal pure virtual returns (string memory) {
        return tokenId.toString();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        return string(abi.encodePacked(base, _tokenFilename(tokenId)));
    }

    /**
    * @notice Owner: reserve tokens for team.
    *
    * @param friends addresses to send tokens to.
    * @param count the number of tokens to mint.
    */
    function reserveTokens(address[] memory friends, uint256 count) external payable onlyOwner {
        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsBatchSize();
        if (_totalMinted() + (friends.length * count) > PUBLIC_MINT_SUPPLY_CAP) revert ExceedsSupplyCap();

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], count);
        }
    }

    /**
    * @notice Mint tokens - purchase bound by terms & conditions of project.
    *
    * @param count the number of tokens to mint.
    */
    function publicMintTokens(uint256 count) external payable nonReentrant isPublicMinting {
        if (0 >= count || count > PUBLIC_MINT_BATCH_SIZE) revert ExceedsBatchSize();
        if (msg.value != publicMintPricePerNft * count) revert InvalidPayment();
        if (_totalMinted() + count > PUBLIC_MINT_SUPPLY_CAP) revert ExceedsSupplyCap();

        _internalMintTokens(msg.sender, count);
    }

    function _internalMintTokens(address minter, uint256 count) internal {
        _safeMint(minter, count);
    }
}