// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/token/PrivilegedMinter.sol';
import '@nftculture/nftc-contract-library/contracts/token/ERC721A_NFTCExtended.sol';
import '@nftculture/nftc-contract-library/contracts/token/phased/PhasedMintThree.sol';
import '@nftculture/nftc-contract-library/contracts/token/phased/PhaseOneIsIndexed.sol';
import '@nftculture/nftc-contract-library/contracts/token/phased/PhaseTwoIsIndexed.sol';

// OZ Libraries
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './CosmicBloomDelegateEnforcer.sol';

// Error Codes
error ExceedsBatchSize();
error ExceedsPurchaseLimit();
error ExceedsSupplyCap();
error InvalidPayment();

/**
 * @title CosmicBloomBase
 * @author @NiftyMike | @NFTCulture
 * @dev ERC721a Implementation with @NFTCulture standardized components.
 * 
 * OperatorFilterer support via ClosedSea (by Vectorized).
 *
 * "MintTokensFor" methods are compatible with Delegate.cash (use at your own risk).
 */
abstract contract CosmicBloomBase is
    ERC721A_NFTCExtended,
    ReentrancyGuard,
    LockedPaymentSplitter,
    PhasedMintThree,
    PhaseOneIsIndexed,
    PhaseTwoIsIndexed,
    PrivilegedMinter,
    CosmicBloomDelegateEnforcer
{
    using Strings for uint256;

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;

    uint256 private constant PHASE_ONE_BATCH_SIZE = 25;
    uint256 private constant PHASE_ONE_PURCHASE_LIMIT = 1300;
    uint256 private constant PHASE_ONE_SUPPLY_CAP = 1300; // Unrestricted, since controlled by Merkletree

    uint256 private constant PHASE_TWO_BATCH_SIZE = 25;
    uint256 private constant PHASE_TWO_PURCHASE_LIMIT = 1132;
    uint256 private constant PHASE_TWO_SUPPLY_CAP = 1132; // Lower cap to allow space for studio/team/Leo mints

    uint256 private constant PUBLIC_MINT_BATCH_SIZE = 25;
    uint256 private constant PUBLIC_MINT_PURCHASE_LIMIT = 1300;
    uint256 private constant PUBLIC_MINT_SUPPLY_CAP = 1300;

    string public baseURI;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits,
        uint256 __phaseOnePricePerNft,
        uint256 __phaseTwoPricePerNft,
        uint256 __phaseThreePricePerNft
    )
        ERC721A(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        PhasedMintThree(__phaseOnePricePerNft, __phaseTwoPricePerNft, __phaseThreePricePerNft)
        PrivilegedMinter(msg.sender)
    {
        baseURI = __baseURI;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function nftcContractDefinition() external pure returns (string memory) {
        // NFTC Contract Definition for front-end websites.
        return
            string(
                abi.encodePacked('{', '"ncdVersion":1,', '"phases":3,', '"type":"Static",', '"openEdition":false', '}')
            );
    }

    function maxSupply() external pure returns (uint256) {
        return PUBLIC_MINT_SUPPLY_CAP;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function phaseOneBatchSize() external pure returns (uint256) {
        return PHASE_ONE_BATCH_SIZE;
    }

    function phaseTwoBatchSize() external pure returns (uint256) {
        return PHASE_TWO_BATCH_SIZE;
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

    function setPrivilegedMinter(address __newPrivilegedMinter) external onlyOwner {
        _setPrivilegedMinter(__newPrivilegedMinter);
    }

    function setMerkleRoots(bytes32 __indexedRootPhaseOne, bytes32 __indexedRootPhaseTwo) external onlyOwner {
        _setMerkleRoots(__indexedRootPhaseOne, __indexedRootPhaseTwo);
    }

    function _setMerkleRoots(bytes32 __phaseOneRoot, bytes32 __phaseTwoRoot) internal {
        if (__phaseOneRoot != 0) {
            _setPhaseOneRoot(__phaseOneRoot);
        }

        if (__phaseTwoRoot != 0) {
            _setPhaseTwoRoot(__phaseTwoRoot);
        }
    }

    function _getPackedPurchasesAs64(
        address wallet
    ) internal view virtual override(PhaseOneIsIndexed, PhaseTwoIsIndexed) returns (uint64) {
        return _getAux(wallet);
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

    /**
     * @notice Same as publicMintTokens(), but with a "to" for purchasing / custodial wallet platforms.
     *
     * @param count the number of tokens to mint.
     * @param to address where the new token should be sent.
     */
    function publicMintTokensTo(
        uint256 count,
        address to
    ) external payable nonReentrant isPublicMinting onlyPrivilegedMinter {
        if (0 >= count || count > PUBLIC_MINT_BATCH_SIZE) revert ExceedsBatchSize();
        if (msg.value != publicMintPricePerNft * count) revert InvalidPayment();
        if (_totalMinted() + count > PUBLIC_MINT_SUPPLY_CAP) revert ExceedsSupplyCap();

        _internalMintTokens(to, count);
    }

    /**
     * @notice Mint tokens (Phase One) - purchase bound by terms & conditions of project.
     *
     * @param proof the merkle proof for this purchase.
     * @param count the number of tokens to mint.
     */
    function phaseOneMintTokens(bytes32[] calldata proof, uint256 count) external payable nonReentrant isPhaseOne {
        if (0 >= count || count > PHASE_ONE_BATCH_SIZE) revert ExceedsBatchSize();
        if (msg.value != phaseOnePricePerNft * count) revert InvalidPayment();
        if (_totalMinted() + count > PHASE_ONE_SUPPLY_CAP) revert ExceedsSupplyCap();

        (uint32 phaseOnePurchases, uint32 otherPhase) = _unpack32(_getAux(msg.sender));

        uint256 newBalance = phaseOnePurchases + count;
        if (newBalance > PHASE_ONE_PURCHASE_LIMIT) revert ExceedsPurchaseLimit();

        _setAux(msg.sender, _pack32(uint16(newBalance), otherPhase));

        _proofMintTokens_PhaseOne(msg.sender, proof, newBalance, count, msg.sender);
    }

    /**
     * @notice Mint tokens (Phase One) - purchase bound by terms & conditions of project.
     *
     * @param proof the merkle proof for this purchase.
     * @param count the number of tokens to mint.
     * @param coldWallet The cold wallet, if caller is a delegated hot wallet.
     */
    function phaseOneMintTokensFor(
        bytes32[] calldata proof,
        uint256 count,
        address coldWallet
    ) external payable nonReentrant isPhaseOne {
        if (0 >= count || count > PHASE_ONE_BATCH_SIZE) revert ExceedsBatchSize();
        if (msg.value != phaseOnePricePerNft * count) revert InvalidPayment();
        if (_totalMinted() + count > PHASE_ONE_SUPPLY_CAP) revert ExceedsSupplyCap();

        address operator = _TryDelegate(msg.sender, coldWallet);

        (uint32 phaseOnePurchases, uint32 otherPhase) = _unpack32(_getAux(operator));

        uint256 newBalance = phaseOnePurchases + count;
        if (newBalance > PHASE_ONE_PURCHASE_LIMIT) revert ExceedsPurchaseLimit();

        _setAux(operator, _pack32(uint16(newBalance), otherPhase));

        _proofMintTokens_PhaseOne(operator, proof, newBalance, count, msg.sender);
    }

    /**
     * @notice Mint tokens (Phase Two) - purchase bound by terms & conditions of project.
     *
     * @param proof the merkle proof for this purchase.
     * @param count the number of tokens to mint.
     */
    function phaseTwoMintTokens(bytes32[] calldata proof, uint256 count) external payable nonReentrant isPhaseTwo {
        if (0 >= count || count > PHASE_TWO_BATCH_SIZE) revert ExceedsBatchSize();
        if (msg.value != phaseTwoPricePerNft * count) revert InvalidPayment();
        if (_totalMinted() + count > PHASE_TWO_SUPPLY_CAP) revert ExceedsSupplyCap();

        (uint32 otherPhase, uint32 phaseTwoPurchases) = _unpack32(_getAux(msg.sender));

        uint256 newBalance = phaseTwoPurchases + count;
        if (newBalance > PHASE_TWO_PURCHASE_LIMIT) revert ExceedsPurchaseLimit();

        _setAux(msg.sender, _pack32(otherPhase, uint16(newBalance)));

        _proofMintTokens_PhaseTwo(msg.sender, proof, newBalance, count, msg.sender);
    }

    /**
     * @notice Mint tokens (Phase Two) - purchase bound by terms & conditions of project.
     *
     * @param proof the merkle proof for this purchase.
     * @param count the number of tokens to mint.
     * @param coldWallet The cold wallet, if caller is a delegated hot wallet.
     */
    function phaseTwoMintTokensFor(
        bytes32[] calldata proof,
        uint256 count,
        address coldWallet
    ) external payable nonReentrant isPhaseTwo {
        if (0 >= count || count > PHASE_TWO_BATCH_SIZE) revert ExceedsBatchSize();
        if (msg.value != phaseTwoPricePerNft * count) revert InvalidPayment();
        if (_totalMinted() + count > PHASE_TWO_SUPPLY_CAP) revert ExceedsSupplyCap();

        address operator = _TryDelegate(msg.sender, coldWallet);

        (uint32 otherPhase, uint32 phaseTwoPurchases) = _unpack32(_getAux(operator));

        uint256 newBalance = phaseTwoPurchases + count;
        if (newBalance > PHASE_TWO_PURCHASE_LIMIT) revert ExceedsPurchaseLimit();

        _setAux(operator, _pack32(otherPhase, uint16(newBalance)));

        _proofMintTokens_PhaseTwo(operator, proof, newBalance, count, msg.sender);
    }

    function _internalMintTokens(
        address minter,
        uint256 count
    ) internal override(PhaseOneIsIndexed, PhaseTwoIsIndexed) {
        _safeMint(minter, count);
    }

    function _internalMintTokens(
        address minter,
        uint256 count,
        uint256 flavorId
    ) internal override(PhaseOneIsIndexed, PhaseTwoIsIndexed) {
        // Do nothing
    }
}