// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';
import '@nftculture/nftc-contract-library/contracts/token/TwoPhaseMint.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';

// ERC721A from Chiru Labs
import 'erc721a/contracts/ERC721A.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// Locals
import './ISolidarityMetadata.sol';

/**
 * @title Solidarity NFT Project For Ukraine
 * @author @NiftyMike | NFT Culture, @J | NFT Culture
 * @dev Standard ERC721a Implementation v3.1
 *
 * Solidarity features fully on-chain metadata, with NFT assets hosted in IPFS.
 * This was done to enable extremely high mint counts without having to come up with 
 * a metadata bucketing system due to the challenge of trying to pin folders in IPFS
 * that contain 50k+ files.
 *
 * The on-chain metadata is implemented in an external contract, so that errors can be
 * corrected if the need arises.
 *
 * Contract also implements NFT Cultures OnePhase/TwoPhase/ThreePhase pattern of mint
 * control functionality. Note: This makes the code really easy to work with but I'm not
 * fully convinced of the gas efficiency of this scheme.
 *
 * Visit the NFTC Labs open source repo on github to learn more about the code:
 * https://github.com/NFTCulture/nftc-open-contracts
 */
abstract contract SolidarityBase is
    ERC721A,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter,
    TwoPhaseMint,
    MerkleLeaves
{
    using MerkleClaimList for MerkleClaimList.Root;

    // Deliberately setting an impossibly high cap here, as this is a defacto "Open Edition".
    uint256 private constant MAX_NFTS_FOR_SALE = 999999;
    uint256 private constant MAX_MINT_BATCH_SIZE = 100;

    // All tokens claimed after this token was minted will be the second type.
    uint256 public lastTokenMinted = MAX_NFTS_FOR_SALE;

    uint256 private constant TOKEN_TYPE_ONE = 1;
    uint256 private constant TOKEN_TYPE_TWO = 2;

    // Used for phase 2 of the minting, to on-ramp purchasers who used fiat.
    MerkleClaimList.Root private _claimRoot;
    address private _externalClaimer;

    // External contract that manages the collection's metadata.
    ISolidarityMetadata private _solidarityMetadata;

    constructor(
        string memory __name,
        string memory __symbol,
        address __solidarityMetadata,
        address[] memory __addresses,
        uint256[] memory __splits
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        TwoPhaseMint(0 ether, 0.08 ether)
    {
        _setNewDependencies(__solidarityMetadata, address(0));
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return MAX_MINT_BATCH_SIZE;
    }

    function isOpenEdition() external pure returns (bool) {
        // Front end minting websites should treat this mint as an open edition, even though there is a hard cap.
        return true;
    }

    function setLastTokenMinted() external onlyOwner {
        // Function should be executed upon completion of phase 1 and closing of public mint, prior to opening claiming.
        lastTokenMinted = _totalMinted() - 1;
    }

    function unsetLastTokenMinted() external onlyOwner {
        // Just in case we need to revert back to the public mint phase.
        lastTokenMinted = MAX_NFTS_FOR_SALE;
    }

    function unsetExternalClaimer() external onlyOwner {
        // Can use this as a way to block externalClaimTokens() if it has issues.
        _externalClaimer = address(0);
    }

    function setNewDependencies(address __solidarityMetadata, address __externalClaimer)
        external
        onlyOwner
    {
        _setNewDependencies(__solidarityMetadata, __externalClaimer);
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

    function getMetadataAddress() external view returns (address) {
        return address(_solidarityMetadata);
    }

    function getClaimerAddress() external view returns (address) {
        return address(_externalClaimer);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        if (tokenId <= lastTokenMinted) {
            return _solidarityMetadata.getAsEncodedString(tokenId, TOKEN_TYPE_ONE);
        }

        return _solidarityMetadata.getAsEncodedString(tokenId, TOKEN_TYPE_TWO);
    }

    /**
     * @notice Owner: reserve tokens for team.
     *
     * @param friends addresses to send tokens to.
     * @param count the number of tokens to mint.
     *
     * Can be used to airdrop tokens that were purchased via fiat, if necessary.
     */
    function reserveTokens(address[] memory friends, uint256 count) external onlyOwner {
        require(0 < count && count <= MAX_MINT_BATCH_SIZE, 'Invalid count');

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], count);
        }
    }

    /**
     * @notice External Claimer: claim tokens via an external contract, to aid in
     * support of users providing alternative auth information.
     *
     * @param claimer address to send tokens to.
     * @param count the number of tokens to mint.
     */
    function externalClaimTokens(address claimer, uint256 count) external nonReentrant {
        require(_externalClaimer != address(0) && msg.sender == _externalClaimer, 'Invalid source');
        require(0 < count && count <= MAX_MINT_BATCH_SIZE, 'Invalid count');

        _internalMintTokens(claimer, count);
    }

    function claimTokens(bytes32[] calldata proof, uint256 count)
        external
        payable
        nonReentrant
        isClaiming
    {
        require(0 < count && count <= MAX_MINT_BATCH_SIZE, 'Invalid count');
        require(msg.value >= claimPricePerNft * count, 'Invalid price');

        _claimTokens(msg.sender, proof, count);
    }

    /**
     * @notice Mint tokens - purchase bound by terms & conditions of project.
     *
     * @param count the number of tokens to mint.
     */
    function mintTokens(uint256 count) external payable nonReentrant onlyUsers isPublicMinting {
        require(0 < count && count <= MAX_MINT_BATCH_SIZE, 'Invalid count');
        require(msg.value >= publicMintPricePerNft * count, 'Invalid price');

        _internalMintTokens(msg.sender, count);
    }

    function _claimTokens(
        address minter,
        bytes32[] calldata proof,
        uint256 count
    ) internal {
        // Verify proof matches expected target total number of claims.
        require(
            _claimRoot._checkLeaf(
                proof,
                _generateIndexedLeaf(minter, (_numberMinted(minter) + count) - 1) //Zero-based index.
            ),
            'Proof invalid for claim'
        );

        _internalMintTokens(minter, count);
    }

    function _internalMintTokens(address minter, uint256 count) internal {
        require(totalSupply() + count <= MAX_NFTS_FOR_SALE, 'Limit exceeded');

        _safeMint(minter, count);
    }

    function _setNewDependencies(address __solidarityMetadata, address __externalClaimer) internal {
        if (__solidarityMetadata != address(0)) {
            _solidarityMetadata = ISolidarityMetadata(__solidarityMetadata);
        }

        if (__externalClaimer != address(0)) {
            _externalClaimer = __externalClaimer;
        }
    }
}