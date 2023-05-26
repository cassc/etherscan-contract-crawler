// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import '@nftculture/nftc-contracts/contracts/financial/LockedPaymentSplitter.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contracts-private/contracts/token/ERC721A_NFTCExtended_Expandable.sol';
import '@nftculture/nftc-contracts-private/contracts/token/phased/expandable/ExpandablePhasedMintThree.sol';
import '@nftculture/nftc-contracts-private/contracts/token/phased/PhaseOneIsIndexed.sol';
import '@nftculture/nftc-contracts-private/contracts/token/phased/PhaseTwoIsIndexed.sol';
import '@nftculture/nftc-contracts-private/contracts/token/PrivilegedMinter.sol';
import '@nftculture/nftc-contracts-private/contracts/custody/ERC721TransferableHolder.sol';

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
 * @title NeonIstByDevrimErbilBase
 * @author @NFTCulture
 * @dev ERC721a Implementation with @NFTCulture standardized components.
 *
 * Public Mint is Phase Three.
 */
abstract contract NeonIstByDevrimErbilBase is
    ERC721A_NFTCExtended_Expandable,
    ReentrancyGuard,
    LockedPaymentSplitter,
    ExpandablePhasedMintThree,
    PhaseOneIsIndexed,
    PrivilegedMinter,
    ERC721TransferableHolder
{
    using Strings for uint256;

    bytes32 public constant PRODUCT_MANAGER_ROLE = keccak256('PRODUCT_MANAGER_ROLE');

    uint256 private constant MAX_RESERVE_BATCH_SIZE = 100;

    uint256 private constant PUBLIC_MINT_BATCH_SIZE = 10;
    uint256 private constant PUBLIC_MINT_SUPPLY_CAP = 321; // Enforced per-flavor

    string public baseURI;

    address private constant CROSSMINT = address(0xdAb1a1854214684acE522439684a145E62505233);

    address private _tmpMsgSender;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory __addresses,
        uint256[] memory __splits
    )
        ERC721A_NFTCExtended_Expandable(__name, __symbol)
        SlimPaymentSplitter(__addresses, __splits)
        ExpandablePhasedMintThree()
        ExpandableTypedTokenExtension(true)
        PrivilegedMinter(CROSSMINT)
        ERC721TransferableHolder(address(this))
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
                    '"phases":3,', // # of mint phases?
                    '"type":"Expandable",', // do tokens have a type? [Static | Expandable]
                    '"openEdition":false', // is collection an open edition? [true | false]
                    '}'
                )
            );
    }

    function publicMintBatchSize() external pure returns (uint256) {
        return PUBLIC_MINT_BATCH_SIZE;
    }

    function getPhaseOnePricePerNft(uint256 flavorId) external view virtual override returns (uint256) {
        return _getFlavorInfo(flavorId).price;
    }

    function getPhaseTwoPricePerNft(uint256 flavorId) external view virtual override returns (uint256) {
        return _getFlavorInfo(flavorId).price;
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

    function setPrivilegedMinter(address __newPrivilegedMinter) external onlyOwner {
        _privilegedMinter = __newPrivilegedMinter;
    }

    function _getPackedPurchasesAs64(
        address wallet
    ) internal view virtual override(PhaseOneIsIndexed) returns (uint64) {
        return _getAux(wallet);
    }

    /**
     * @notice Owner: reserve tokens for team.
     *
     * @param friends addresses to send tokens to.
     * @param count the number of tokens to mint.
     * @param flavorId the type of tokens to mint.
     */
    function reserveTokens(address[] memory friends, uint256 count, uint256 flavorId) external payable onlyOwner {
        if (0 >= count || count > MAX_RESERVE_BATCH_SIZE) revert ExceedsBatchSize();

        FlavorInfo memory updatedFlavor = _canMint(count * friends.length, flavorId, false, 0);
        _saveFlavorInfo(updatedFlavor);

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _internalMintTokensOfFlavor(friends[idx], count, flavorId);
        }
    }

    /**
     * @notice Premint function, to programattically mint batches of tokens
     *
     * @dev The purpose of this function is to premint all of the Unique / 1 of 1 tokens, so that they have a reserved
     * tokenId, which makes management of the metadata easier.
     *
     * Reserve tokens function will be used to mint the initial Token #0.
     * Premint function will be used to mint unique tokens 1 -> 30.
     * So a total of 31 Unique Tokens will be minted in two txs.
     */
    function premintUniqueTokens(uint256 start, uint256 end, uint256 count, address destination) external onlyOwner {
        uint64[] memory flavorIds = _getFlavors();

        // Mint the 31 unique 1/1s to this contract
        for (uint256 i = start; i <= end; i++) {
            FlavorInfo memory flavorInfo = _getFlavorInfo(flavorIds[i]);
            _saveFlavorInfo(_canMint(count, flavorInfo.flavorId, false, flavorInfo.price));
            _internalMintTokensOfFlavor(destination, count, flavorInfo.flavorId);
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

    /**
     * @notice Claim a Unique token - purchase bound by terms & conditions of project.
     *
     * @param flavorId the type of tokens to mint.
     *
     * @dev Guarding this function with isPhaseOne so that this workflow can be shut off independently from the
     * public mint function. It is labelled to reflect that.
     */
    function phaseOneClaimUniqueTokens(uint256 tokenId, uint256 flavorId) external payable nonReentrant isPhaseOne {
        _claimTokenViaTransfer(tokenId, flavorId, msg.sender);
    }

    /**
     * @notice Same as phaseOneClaimUniqueTokens(), but with a "to" for purchasing / custodial wallet platforms.
     *
     */
    function phaseOneClaimUniqueTokensTo(
        uint256 tokenId,
        uint256 flavorId,
        address to
    ) external payable nonReentrant isPhaseOne onlyPrivilegedMinter {
        _claimTokenViaTransfer(tokenId, flavorId, to);
    }

    function _claimTokenViaTransfer(uint256 tokenId, uint256 flavorId, address to) internal {
        // Make sure the passed in tokenId matches the passed in flavor.
        require(_getFlavorForToken(tokenId) == flavorId, 'Flavor mismatch');

        // Lookup the flavor info that was requested.
        FlavorInfo memory uniqueFlavor = _getFlavorInfo(flavorId);

        // Confirm its a 1 of 1, and thus this is the only tokenId of this type.
        require(uniqueFlavor.maxSupply == 1, 'Not one of one');

        // Check we passed in enough eth.
        if (msg.value != uniqueFlavor.price) revert InvalidValuePayment();

        require(ownerOf(tokenId) == address(this), 'Token not owned');

        // Transfer the token to the caller.
        _tmpMsgSender = address(this);
        ERC721A.safeTransferFrom(address(this), to, tokenId, '');
        _tmpMsgSender = address(0);
    }

    /**
     * @notice Transfer some quantity of a fungible token from caller to a single friend.
     *
     * @param friend address to send tokens to.
     * @param tokenId the ID of the fungible token.
     */
    function transferUniqueToken(address friend, uint256 tokenId) external {
        if (!hasRole(PRODUCT_MANAGER_ROLE, msg.sender)) revert InvalidAccess();

        _tmpMsgSender = address(this);
        ERC721A.safeTransferFrom(address(this), friend, tokenId, '');
        _tmpMsgSender = address(0);
    }

    function _internalMintTokens(address minter, uint256 count) internal override(PhaseOneIsIndexed) {
        // Do nothing
    }

    function _internalMintTokens(address minter, uint256 count, uint256 flavorId) internal override(PhaseOneIsIndexed) {
        _internalMintTokensOfFlavor(minter, count, flavorId);
    }

    function _msgSenderERC721A() internal view override returns (address) {
        if (_tmpMsgSender == address(0)) {
            return msg.sender;
        } else {
            return _tmpMsgSender;
        }
    }
}