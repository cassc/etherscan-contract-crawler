// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';
import '@nftculture/nftc-contract-library/contracts/token/phased/PhasedMintTwo.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';

// ERC721A from Chiru Labs
import 'erc721a/contracts/ERC721A.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

// Error Codes
error ExceedsMaxSupply();
error ExceedsReserveBatchSize();
error ProofInvalidClaim();
error ExceedsClaimBatchSize();
error InvalidClaimPayment();
error ExceedsPublicMintBatchSize();
error InvalidPublicMintPayment();

/**
 * @title MoonrayComicChapterTwoBase
 * @author @NiftyMike | @NFTCulture
 * @dev ERC721a Implementation with @NFTCulture standardized components.
 */
abstract contract MoonrayComicChapterTwoBase is
    ERC721A,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter,
    PhasedMintTwo,
    MerkleLeaves
{
    using Strings for uint256;
    using MerkleClaimList for MerkleClaimList.Root;

    uint256 private constant MAX_NFTS_FOR_SALE = 2073;
    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;

    uint256 private constant MAX_PUBLIC_BATCH_SIZE = 20;
    uint256 private constant MAX_CLAIM_BATCH_SIZE = 20; 

    string public baseURI;

    MerkleClaimList.Root private _claimRoot;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits,
        uint256 __phaseOnePricePerNft,
        uint256 __publicMintPricePerNft
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        PhasedMintTwo(__phaseOnePricePerNft, __publicMintPricePerNft)
    {
        baseURI = __baseURI;
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function claimBatchSize() external pure returns (uint256) {
        return MAX_CLAIM_BATCH_SIZE;
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return MAX_PUBLIC_BATCH_SIZE;
    }

    function isOpenEdition() external pure returns (bool) {
        // Front end minting websites should treat this mint as an open edition, even though there is a hard cap.
        return false;
    }

    function isClaimingActive() external view returns (bool) {
        return _isPhaseOneActive();
    }

    function claimPricePerNft() external view returns (uint256) {
        return phaseOnePricePerNft;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setMerkleRoot(bytes32 __claimRoot) external onlyOwner {
        if (__claimRoot != 0) {
            _claimRoot._setRoot(__claimRoot);
        }
    }

    function checkClaim(
        bytes32[] calldata proof,
        address wallet,
        uint256 index
    ) external view returns (bool) {
        return _claimRoot._checkLeaf(proof, _generateIndexedLeaf(wallet, index));
    }

    function getNextClaimIndex(address wallet) external view returns (uint256) {
        return _numberMinted(wallet);
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
     * @param friends addresses to send tokens  to.
     * @param count the number of tokens to mint.
     */
    function reserveTokens(address[] memory friends, uint256 count) external payable onlyOwner {
        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsReserveBatchSize();

        uint256 totalMinted = _totalMinted(); // track locally to save gas.

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], totalMinted, count);
            totalMinted += count;
        }
    }

    /**
     * @notice Claim tokens - purchase bound by terms & conditions of project.
     *
     * @param count the number of tokens to mint.
     */
    function claimTokens(bytes32[] calldata proof, uint256 count) external payable nonReentrant onlyUsers isPhaseOne {
        if (0 >= count || count > MAX_CLAIM_BATCH_SIZE) revert ExceedsClaimBatchSize();
        if (msg.value < phaseOnePricePerNft * count) revert InvalidClaimPayment();

        uint256 newBalance = _numberMinted(msg.sender) + count;

        _claimTokens(msg.sender, proof, newBalance, count);
    }

    /**
     * @notice Mint tokens - purchase bound by terms & conditions of project.
     *
     * @param count the number of tokens to mint.
     */
    function mintTokens(uint256 count) external payable nonReentrant onlyUsers isPublicMinting {
        if (0 >= count || count > MAX_PUBLIC_BATCH_SIZE) revert ExceedsPublicMintBatchSize();
        if (msg.value < publicMintPricePerNft * count) revert InvalidPublicMintPayment();

        _internalMintTokens(msg.sender, _totalMinted(), count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal pure virtual returns (string memory) {
        return tokenId.toString();
    }

    function _internalMintTokens(
        address minter,
        uint256 totalMinted,
        uint256 count
    ) internal {
        if (totalMinted + count > MAX_NFTS_FOR_SALE) revert ExceedsMaxSupply();

        _safeMint(minter, count);
    }

    function _claimTokens(
        address minter,
        bytes32[] calldata proof,
        uint256 newBalance,
        uint256 count
    ) internal {
        // Verify proof matches expected target total number of claim mints.
        if (!_claimRoot._checkLeaf(proof, _generateIndexedLeaf(minter, newBalance - 1)))
            //Zero-based index.
            revert ProofInvalidClaim();

        _internalMintTokens(minter, _totalMinted(), count);
    }
}