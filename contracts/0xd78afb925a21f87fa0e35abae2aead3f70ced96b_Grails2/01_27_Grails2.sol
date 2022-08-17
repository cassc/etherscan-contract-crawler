// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Grails2MintPass.sol";

import "./IGrailsRoyaltyRouter.sol";
import "./IERC721TransferListener.sol";
import "./GrailsRevenues2.sol";

/**
 * @title Grails II
 * @author PROOF
 */
contract Grails2 is ERC721ACommon, BaseTokenURI {
    using Address for address;
    using Address for address payable;

    // =========================================================================
    //                           Errors
    // =========================================================================

    error CallerNotAllowedToRedeemPass();
    error DisallowedByCurrentStage();
    error InvalidGrailId();
    error ParameterLengthMismatch();
    error InvalidFunds();
    error ReserveAlreadyMinted();
    error TreasuryReserveNotYetMinted();
    error InsufficientInterface();

    // =========================================================================
    //                           Events
    // =========================================================================

    /**
     * @notice Emitted when the specific Grail is minted.
     */
    event GrailMinted(address indexed from, uint8 indexed grailId);

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice The different stages of the Grails II contract.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     */
    enum Stage {
        BeforeOpen,
        Open
    }

    /**
     * @notice Each minted token corresponds to an edition of a Grail.
     * @dev See also {_grailByTokenId}.
     */
    struct Grail {
        uint8 id;
        uint16 edition;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The current Grails season.
     */
    uint256 public constant SEASON = 2;

    /**
     * @notice The number of different Grails in this season.
     */
    uint8 public constant NUM_GRAILS = 25;

    /**
     * @notice The price of purchasing a Grail by burning a mint pass.
     */
    uint256 public constant PRICE = 0.05 ether;

    /**
     * @notice The address to the mintPass contract.
     */
    Grails2MintPass public immutable mintPass;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Flag to indicate if the treasury reserve was already minted.
     * @dev See {mintTreasuryReserve}.
     */
    bool public treasuryReserveMinted;

    /**
     * @notice Flag to indicate if the artist allocation was already minted.
     * @dev See {mintArtistAllocation}.
     */
    bool public artistAllocationMinted;

    /**
     * @notice The current stage of the contract.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     */
    Stage public stage;

    /**
     * @notice The Grail id and edition of a given token.
     */
    mapping(uint256 => Grail) internal _grailByTokenId;

    /**
     * @notice Number of editions of a given Grail the were already minted.
     */
    mapping(uint8 => uint16) public numEditionsByGrailId;

    /**
     * @notice Implements ERC2981 royalties for grails.
     */
    IGrailsRoyaltyRouter public royaltyRouter;

    /**
     * @notice Contract that is notified on token transfers.
     */

    IERC721TransferListener public transferListener;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        string memory name,
        string memory symbol,
        address mintPass_,
        string memory baseTokenURI_
    )
        ERC721ACommon(name, symbol, payable(address(0xdeadface)), 0)
        BaseTokenURI(baseTokenURI_)
    {
        royaltyRouter = new GrailsRevenues2(msg.sender);
        mintPass = Grails2MintPass(mintPass_);
    }

    // =========================================================================
    //                           Minting
    // =========================================================================

    /**
     * @notice Mints the treasury reseverve.
     * This includes:
     * - 25 x Genesis tokens for artists
     * - 25 tokens for the treasury
     *     = 50 tokens
     * @dev Can only be called once.
     */
    function mintTreasuryReserve(address to) external onlyOwner {
        if (treasuryReserveMinted) revert ReserveAlreadyMinted();
        treasuryReserveMinted = true;

        uint256 nextTokenId = totalSupply();
        for (uint256 round = 0; round < 2; ++round) {
            for (uint8 grailId = 0; grailId < NUM_GRAILS; ++grailId) {
                _grailByTokenId[nextTokenId++] = Grail({
                    id: grailId,
                    edition: numEditionsByGrailId[grailId]++
                });
                emit GrailMinted(to, grailId);
            }
        }

        _mint(to, 2 * NUM_GRAILS);
    }

    /**
     * @notice Mints the artist allocation to a given address (treasury).
     * This includes one freely chosen token per artist (25).
     * @dev We perform the mints on behalf of the artists to obfruscate their
     * identity before the reveal.
     * @dev Can only be called once.
     */
    function mintArtistAllocation(
        address to,
        uint8[NUM_GRAILS] calldata choices
    ) external onlyOwner onlyAfterTreasuryReserveMinted {
        if (artistAllocationMinted) revert ReserveAlreadyMinted();
        artistAllocationMinted = true;

        uint256 nextTokenId = totalSupply();
        for (uint256 idx = 0; idx < NUM_GRAILS; ++idx) {
            uint8 grailId = choices[idx];
            _grailByTokenId[nextTokenId++] = Grail({
                id: grailId,
                edition: numEditionsByGrailId[grailId]++
            });
            emit GrailMinted(to, grailId);
        }

        _mint(to, NUM_GRAILS);
    }

    /**
     * @notice Redeems a given list of mint passes for a list of Grails.
     * @dev The Grail II tokens will be minted to the caller address.
     * @dev Can only be called if the contract is set to the open state.
     * @dev Passing controll to our own contracts is effectively not an interaction,
     * so we are safe to go without reentrancy protection.
     */
    function redeemPasses(uint256[] calldata passIds, uint8[] calldata grailIds)
        external
        payable
        onlyDuring(Stage.Open)
    {
        if (passIds.length != grailIds.length) revert ParameterLengthMismatch();

        uint256 num = grailIds.length;
        if (msg.value != PRICE * num) revert InvalidFunds();

        uint256 nextTokenId = totalSupply();

        for (uint256 idx = 0; idx < num; ++idx) {
            uint8 grailId = grailIds[idx];

            _requirePassApproval(passIds[idx]);
            if (grailId >= NUM_GRAILS) revert InvalidGrailId();

            mintPass.redeem(passIds[idx]);
            _grailByTokenId[nextTokenId++] = Grail({
                id: grailId,
                edition: numEditionsByGrailId[grailId]++
            });
            emit GrailMinted(msg.sender, grailId);
        }

        payable(address(royaltyRouter)).sendValue(msg.value);

        // Using unsafe mints here. The sender has already proven that it can
        // safely receive and handle ERC721 token.
        _mint(msg.sender, num);
    }

    // =========================================================================
    //                           Metadata
    // =========================================================================

    /**
     * @notice Returns the Grail id + edition for a given token.
     */
    function grailByTokenId(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (Grail memory)
    {
        return _grailByTokenId[tokenId];
    }

    /**
     * @notice Computes a pseudo-random seed for relics.
     */
    function relicSeed(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(address(this), tokenId, _grailByTokenId[tokenId])
            );
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Advances the stage of the contract.
     * @dev Can only be advanced after the treasury reserve has been minted to
     * ensure the genesis tokens are minted.
     * @dev Is locked after closing the contract.
     */
    function setStage(Stage stage_)
        external
        onlyOwner
        onlyAfterTreasuryReserveMinted
    {
        stage = stage_;
    }

    /**
     * @notice Ensures that the contract is in a given stage.
     */
    modifier onlyDuring(Stage stage_) {
        if (stage_ != stage) revert DisallowedByCurrentStage();
        _;
    }

    /**
     * @notice Ensures that the treasure has already been minted.
     */
    modifier onlyAfterTreasuryReserveMinted() {
        if (!treasuryReserveMinted) revert TreasuryReserveNotYetMinted();
        _;
    }

    /**
     * @notice Sets the token transfer listener contract.
     */
    function setTransferListener(IERC721TransferListener transferListener_)
        external
        onlyOwner
    {
        transferListener = transferListener_;
    }

    // =========================================================================
    //                           Secondary Royalties
    // =========================================================================

    /**
     * @notice Computes the creator royalty for a secondary token sale.
     * @dev The implementation is delegated to our royalty router contract.
     */
    function royaltyInfo(uint256 tokenId, uint256 price)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return
            royaltyRouter.royaltyInfo(
                SEASON,
                _grailByTokenId[tokenId].id,
                tokenId,
                price
            );
    }

    /**
     * @notice Changes the royalty router address.
     */
    function setRoyaltyRouter(IGrailsRoyaltyRouter router) external onlyOwner {
        if (!router.supportsInterface(type(IGrailsRoyaltyRouter).interfaceId))
            revert InsufficientInterface();
        royaltyRouter = router;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Checks if a given mint pass can be spent by the caller.
     * @dev Reverts if not.
     */
    function _requirePassApproval(uint256 passId) internal view {
        if (
            mintPass.ownerOf(passId) != msg.sender &&
            mintPass.getApproved(passId) != msg.sender
        ) revert CallerNotAllowedToRedeemPass();
    }

    /**
     * @dev Inheritance resolution.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
     * @notice Hook called after each token transfer.
     * @dev Notifies the transfer listener contract.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._afterTokenTransfers(from, to, startTokenId, quantity);

        // Trying to notify EOAs would result in reverts that would block
        // transfers. We hence return early if there is no contract behind the
        // transferListener.
        if (!address(transferListener).isContract()) {
            return;
        }

        uint256 end = startTokenId + quantity;
        for (uint256 tokenId = startTokenId; tokenId < end; ) {
            // We catch all reverts from the transfer listener and set the gas
            // limit for the notification to 100k. This prevents malicious
            // listeners from blocking token transfers by deliberately reverting
            // or cosuming huge amounts of gas.
            try
                transferListener.onTransfer{gas: 100000}(from, to, tokenId)
            {} catch {}

            // tokenId will never overflow
            unchecked {
                ++tokenId;
            }
        }
    }
}