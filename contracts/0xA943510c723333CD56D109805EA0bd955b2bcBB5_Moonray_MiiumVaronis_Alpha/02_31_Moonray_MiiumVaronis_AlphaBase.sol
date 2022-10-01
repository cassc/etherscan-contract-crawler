// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-open-contracts/contracts/security/GuardedAgainstContracts.sol';
import '@nftculture/nftc-open-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contract-library/contracts/token/phased/PhasedMintThree.sol';
import '@nftculture/nftc-contract-library/contracts/token/phased/PhaseOneIsIndexed.sol';
import '@nftculture/nftc-contract-library/contracts/token/phased/PhaseTwoIsIndexed.sol';
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
 * @title Moonray_MiiumVaronis_AlphaBase
 * @author @NiftyMike | @NFTCulture
 * @dev ERC721a Implementation with @NFTCulture standardized components.
 *
 * Public Mint is Phase Three.
 */
abstract contract Moonray_MiiumVaronis_AlphaBase is
    ERC721AExpandable,
    Ownable,
    GuardedAgainstContracts,
    ReentrancyGuard,
    LockedPaymentSplitter,
    PhasedMintThree,
    PhaseOneIsIndexed,
    PhaseTwoIsIndexed
{
    using Strings for uint256;

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;

    uint256 private constant PHASE_ONE_BATCH_SIZE = 10;
    uint256 private constant PHASE_ONE_PURCHASE_LIMIT = 1000; // Not Used
    uint256 private constant PHASE_ONE_SUPPLY_CAP = 10000; // Not Used

    uint256 private constant PHASE_TWO_BATCH_SIZE = 10;
    uint256 private constant PHASE_TWO_PURCHASE_LIMIT = 1000; // Not Used
    uint256 private constant PHASE_TWO_SUPPLY_CAP = 10000; // Not Used

    uint256 private constant PUBLIC_MINT_BATCH_SIZE = 10;
    uint256 private constant PUBLIC_MINT_PURCHASE_LIMIT = 1000; // Not Used
    uint256 private constant PUBLIC_MINT_SUPPLY_CAP = 10000; // Enforced per-flavor

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
        ERC721AExpandable(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        PhasedMintThree(__phaseOnePricePerNft, __phaseTwoPricePerNft, __phaseThreePricePerNft)
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
                    '"phases":3,', // # of mint phases?
                    '"type":"Expandable",', // do tokens have a type? [Static | Expandable]
                    '"openEdition":false', // is collection an open edition? [true | false]
                    '}'
                )
            );
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

    function setMerkleRoots(bytes32 __indexedRoot1, bytes32 __indexedRoot2) external onlyOwner {
        _setMerkleRoots(__indexedRoot1, __indexedRoot2);
    }

    function _setMerkleRoots(bytes32 __phaseOneRoot, bytes32 __phaseTwoRoot) internal {
        if (__phaseOneRoot != 0) {
            _setPhaseOneRoot(__phaseOneRoot);
        }

        if (__phaseTwoRoot != 0) {
            _setPhaseTwoRoot(__phaseTwoRoot);
        }
    }

    function _getPackedPurchasesAs64(address wallet)
        internal
        view
        virtual
        override(PhaseOneIsIndexed, PhaseTwoIsIndexed)
        returns (uint64)
    {
        return _getAux(wallet);
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

    /**
     * @notice Mint tokens (Phase One) - purchase bound by terms & conditions of project.
     *
     * @param proof the merkle proof for this purchase.
     * @param count the number of tokens to mint.
     * @param flavorId the type of tokens to mint.
     */
    function phaseOneMintTokens(
        bytes32[] calldata proof,
        uint256 count,
        uint256 flavorId
    ) external payable nonReentrant isPhaseOne {
        if (0 >= count || count > PHASE_ONE_BATCH_SIZE) revert ExceedsBatchSize();

        TokenFlavor memory updatedFlavor = _canMint(count, flavorId, true, msg.value);
        _saveTokenFlavor(updatedFlavor);

        (uint32 phaseOnePurchases, uint32 otherPhase) = _unpack32(_getAux(msg.sender));
        uint256 newBalance = phaseOnePurchases + count;
        if (newBalance > PHASE_ONE_PURCHASE_LIMIT) revert ExceedsPurchaseLimit();
        _setAux(msg.sender, _pack32(uint16(newBalance), otherPhase));

        _proofMintTokensOfFlavor_PhaseOne(msg.sender, proof, newBalance, count, flavorId);
    }

    /**
     * @notice Mint tokens (Phase Two) - purchase bound by terms & conditions of project.
     *
     * @param proof the merkle proof for this purchase.
     * @param count the number of tokens to mint.
     * @param flavorId the type of tokens to mint.
     */
    function phaseTwoMintTokens(
        bytes32[] calldata proof,
        uint256 count,
        uint256 flavorId
    ) external payable nonReentrant isPhaseTwo {
        if (0 >= count || count > PHASE_TWO_BATCH_SIZE) revert ExceedsBatchSize();

        TokenFlavor memory updatedFlavor = _canMint(count, flavorId, true, msg.value);
        _saveTokenFlavor(updatedFlavor);

        (uint32 otherPhase, uint32 phaseTwoPurchases) = _unpack32(_getAux(msg.sender));
        uint256 newBalance = phaseTwoPurchases + count;
        if (newBalance > PHASE_TWO_PURCHASE_LIMIT) revert ExceedsPurchaseLimit();
        _setAux(msg.sender, _pack32(otherPhase, uint16(newBalance)));

        _proofMintTokensOfFlavor_PhaseTwo(msg.sender, proof, newBalance, count, flavorId);
    }

    function _internalMintTokens(address minter, uint256 count)
        internal
        override(PhaseOneIsIndexed, PhaseTwoIsIndexed)
    {
        // Do nothing
    }

    function _internalMintTokens(
        address minter,
        uint256 count,
        uint256 flavorId
    ) internal override(PhaseOneIsIndexed, PhaseTwoIsIndexed) {
        _internalMintTokensOfFlavor(minter, count, flavorId);
    }
}