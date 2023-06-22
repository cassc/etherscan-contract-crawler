// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleLeaves.sol';
import '@nftculture/nftc-contract-library/contracts/token/TwoPhaseAlternateMint.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '@nftculture/nftc-contract-library/contracts/whitelisting/MerkleClaimList.sol';

// ERC721A from Chiru Labs
import 'erc721a/contracts/ERC721A.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// Error Codes
error ExceedsMaxSupply();
error ExceedsPresaleSupply();
error ProofInvalidPresale();

/**
 * @title MCGenesisBase
 * @author @J | NFT Culture, @NiftyMike | NFT Culture
 * @dev Standard ERC721a Implementation with 2 Phase Mint
 *
 * Visit the NFTC Labs open source repo on github to learn more about the code:
 * https://github.com/NFTCulture/nftc-open-contracts
 */
abstract contract MCGenesisBase is
    ERC721A,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter,
    TwoPhaseAlternateMint,
    MerkleLeaves
{
    using Strings for uint256;
    using MerkleClaimList for MerkleClaimList.Root;

    uint256 private constant MAX_NFTS_FOR_SALE = 9999;
    uint256 private constant MAX_NFTS_FOR_PRESALE = 7777;

    uint256 private constant MAX_PRESALE_BATCH_SIZE = 20;
    uint256 private constant MAX_PUBLIC_BATCH_SIZE = 20;

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;

    string public baseURI;

    MerkleClaimList.Root private _presaleRoot;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        TwoPhaseAlternateMint(0.069 ether, 0.069 ether)
    {
        baseURI = __baseURI;
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_NFTS_FOR_SALE;
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return MAX_PUBLIC_BATCH_SIZE;
    }

    function isOpenEdition() external pure returns (bool) {
        // Front end minting websites should treat this mint as an open edition, even though there is a hard cap.
        return false;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setMerkleRoot(bytes32 __presaleRoot) external onlyOwner {
        if (__presaleRoot != 0) {
            _presaleRoot._setRoot(__presaleRoot);
        }
    }

    function checkPresale(bytes32[] calldata proof, address wallet) external view returns (bool) {
        return _presaleRoot._checkLeaf(proof, _generateLeaf(wallet));
    }

    function getNextPresaleIndex(address wallet) external view returns (uint256) {
        // No need to specifically track presale purchases with aux, since this is an open presale.
        return this.balanceOf(wallet);
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
    function reserveTokens(address[] memory friends, uint256 count) external onlyOwner {
        require(0 < count && count <= MAX_RESERVE_BATCH_SIZE, 'Invalid count');

        uint256 totalMinted = _totalMinted(); // track locally to save gas.

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokens(friends[idx], totalMinted, count);
            totalMinted += count;
        }
    }

    /**
     * @notice Presale tokens - purchase bound by terms & conditions of project.
     *
     * @param proof merkle proof for presale.
     * @param count the number of tokens to mint.
     */
    function presaleTokens(bytes32[] calldata proof, uint256 count) external payable nonReentrant onlyUsers isPresale {
        require(0 < count && count <= MAX_PRESALE_BATCH_SIZE, 'Invalid count');
        require(msg.value == presalePricePerNft * count, 'Invalid price');

        uint256 totalMinted = _totalMinted(); // track locally to save gas.
        if (totalMinted + count > MAX_NFTS_FOR_PRESALE) revert ExceedsPresaleSupply();

        _presaleTokens(msg.sender, proof, totalMinted, count);
    }

    /**
     * @notice Mint tokens - purchase bound by terms & conditions of project.
     *
     * @param count the number of tokens to mint.
     */
    function mintTokens(uint256 count) external payable nonReentrant onlyUsers isPublicMinting {
        require(0 < count && count <= MAX_PUBLIC_BATCH_SIZE, 'Invalid count');
        require(msg.value == publicMintPricePerNft * count, 'Invalid price');

        _internalMintTokens(msg.sender, _totalMinted(), count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId) internal pure virtual returns (string memory) {
        return tokenId.toString();
    }

    function _presaleTokens(
        address minter,
        bytes32[] calldata proof,
        uint256 totalMinted,
        uint256 count
    ) internal {
        // Verify address is eligible for presale mints.
        if (!_presaleRoot._checkLeaf(proof, _generateLeaf(minter))) revert ProofInvalidPresale();

        _internalMintTokens(minter, totalMinted, count);
    }

    function _internalMintTokens(
        address minter,
        uint256 totalMinted,
        uint256 count
    ) internal {
        if (totalMinted + count > MAX_NFTS_FOR_SALE) revert ExceedsMaxSupply();

        _safeMint(minter, count);
    }
}