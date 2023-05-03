// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10 <0.9.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./utils/URITemplate.sol";
import "./ITablelandRigs.sol";
import "./ITablelandRigPilots.sol";
import "./interfaces/IERC4906.sol";
import "./interfaces/IDelegationRegistry.sol";

/**
 * @dev Implementation of {ITablelandRigs}.
 */
contract TablelandRigs is
    ITablelandRigs,
    URITemplate,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    IERC4906,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable
{
    // The maximum number of tokens that can be minted.
    uint256 public maxSupply;

    // The price of minting a token.
    uint256 public mintPrice;

    // The address receiving mint revenue.
    address payable public beneficiary;

    // The allowClaims merkletree root.
    bytes32 public allowlistRoot;

    // The waitClaims merkletree root.
    bytes32 public waitlistRoot;

    // Flag specifying whether or not claims.
    MintPhase public mintPhase;

    // URI for contract info.
    string private _contractInfoURI;

    // Pilots implementation.
    ITablelandRigPilots private _pilots;

    // Allow transfers while flying, only by token owner
    bool private _allowTransferWhileFlying;

    // Admin address
    address private _admin;

    // Delegate.cash registry address
    IDelegationRegistry private constant _delegateCash =
        IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    function initialize(
        uint256 _maxSupply,
        uint256 _mintPrice,
        address payable _beneficiary,
        address payable royaltyReceiver,
        bytes32 _allowlistRoot,
        bytes32 _waitlistRoot
    ) public initializerERC721A initializer {
        __ERC721A_init("Tableland Rigs", "RIG");
        __ERC721AQueryable_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();

        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        setBeneficiary(_beneficiary);
        _setDefaultRoyalty(royaltyReceiver, 500);
        allowlistRoot = _allowlistRoot;
        waitlistRoot = _waitlistRoot;
        mintPhase = MintPhase.CLOSED;
    }

    // =============================
    //        ITABLELANDRIGS
    // =============================

    /**
     * @dev See {ITablelandRigs-mint}.
     */
    function mint(uint256 quantity) external payable whenNotPaused {
        bytes32[] memory proof;
        _verifyMint(quantity, 0, 0, proof);
    }

    /**
     * @dev See {ITablelandRigs-mint}.
     */
    function mint(
        uint256 quantity,
        uint256 freeAllowance,
        uint256 paidAllowance,
        bytes32[] calldata proof
    ) external payable whenNotPaused {
        _verifyMint(quantity, freeAllowance, paidAllowance, proof);
    }

    /**
     * @dev Verifies mint against current mint phase.
     *
     * quantity - the number of Rigs to mint
     * freeAllowance - the number of free Rigs allocated to `msg.sender`
     * paidAllowance - the number of paid Rigs allocated to `msg.sender`
     * proof - merkle proof proving `msg.sender` has said `freeAllowance` and `paidAllowance`
     *
     * Requirements:
     *
     * - `mintPhase` must not be `CLOSED`
     * - quantity must not be zero
     * - current supply must be less than `maxSupply`
     * - if `mintPhase` is `ALLOWLIST` or `WAITLIST`, proof must be valid for `msg.sender`, `freeAllowance`, and `paidAllowance`
     * - if `mintPhase` is `ALLOWLIST` or `WAITLIST`, `msg.sender` must have sufficient unused allowance
     */
    function _verifyMint(
        uint256 quantity,
        uint256 freeAllowance,
        uint256 paidAllowance,
        bytes32[] memory proof
    ) private {
        // Ensure mint phase is not closed
        if (mintPhase == MintPhase.CLOSED) revert MintingClosed();

        // Check quantity is non-zero
        if (quantity == 0) revert ZeroQuantity();

        // Check quantity doesn't exceed remaining quota
        quantity = MathUpgradeable.min(quantity, maxSupply - totalSupply());
        if (quantity == 0) revert SoldOut();

        if (mintPhase == MintPhase.PUBLIC) {
            _mint(quantity, quantity);
        } else {
            // Get merkletree root for mint phase
            bytes32 root = mintPhase == MintPhase.ALLOWLIST
                ? allowlistRoot
                : waitlistRoot;

            // Verify proof against mint phase root
            if (
                !_verifyProof(
                    proof,
                    root,
                    _getLeaf(_msgSenderERC721A(), freeAllowance, paidAllowance)
                )
            ) revert InvalidProof();

            // Ensure allowance available
            uint16 allowClaims;
            uint16 waitClaims;
            (allowClaims, waitClaims) = getClaimed(_msgSenderERC721A());
            uint256 claimed = mintPhase == MintPhase.ALLOWLIST
                ? allowClaims
                : waitClaims;
            quantity = MathUpgradeable.min(
                quantity,
                freeAllowance + paidAllowance - claimed
            );
            if (
                quantity == 0 ||
                // Disallow claims from waitlist if already claimed on allowlist
                (mintPhase == MintPhase.WAITLIST && allowClaims > 0)
            ) revert InsufficientAllowance();

            // Get quantity that must be paid for
            uint256 freeSurplus = freeAllowance > claimed
                ? freeAllowance - claimed
                : 0;
            uint256 costQuantity = quantity < freeSurplus
                ? 0
                : quantity - freeSurplus;

            // Update allowance claimed
            claimed = claimed + quantity;
            if (mintPhase == MintPhase.ALLOWLIST) allowClaims = uint16(claimed);
            else waitClaims = uint16(claimed);
            _setClaimed(_msgSenderERC721A(), allowClaims, waitClaims);

            _mint(quantity, costQuantity);

            // Sanity check for tests
            assert(claimed <= freeAllowance + paidAllowance);
        }
    }

    /**
     * @dev Returns merkletree leaf node for given params.
     *
     * account - address for leaf
     * freeAllowance - free allowance for leaf
     * paidAllowance - paid allowance for leaf
     */
    function _getLeaf(
        address account,
        uint256 freeAllowance,
        uint256 paidAllowance
    ) private pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(account, freeAllowance, paidAllowance));
    }

    /**
     * @dev Verifies that `proof` is a valid path to `leaf` in `root`.
     *
     * proof - merkle proof proving `msg.sender` has said `freeAllowance` and `paidAllowance`
     * root - merkletree root to verify against
     * leaf - leaf node that must exist in `root` via `proof`
     */
    function _verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) private pure returns (bool) {
        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }

    /**
     * @dev Mints Rigs and send revenue to `beneficiary`, refunding surplus to `msg.sender`.
     *
     * Borrows logic from https://github.com/divergencetech/ethier/blob/main/contracts/sales/Seller.sol.
     *
     * quantity - the number of Rigs to mint
     * costQuantity - the number of Rigs that must be paid for
     *
     * Requirements:
     *
     * - `msg.value` must be greater than or equal to `costQuantity`
     */
    function _mint(
        uint256 quantity,
        uint256 costQuantity
    ) private nonReentrant {
        // Check sufficient value
        uint256 cost = _cost(costQuantity);
        if (msg.value < cost) revert InsufficientValue(cost);

        // Mint effect and interaction
        _safeMint(_msgSenderERC721A(), quantity);

        // Handle funds
        if (cost > 0) {
            AddressUpgradeable.sendValue(beneficiary, cost);
            emit Revenue(beneficiary, costQuantity, cost);
        }
        if (msg.value > cost) {
            address payable reimburse = payable(_msgSenderERC721A());
            uint256 refund = msg.value - cost;
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = reimburse.call{
                value: refund
            }("");
            require(success, string(returnData));
            emit Refund(reimburse, refund);
        }
    }

    /**
     * @dev Returns mint cost for `quantity`.
     *
     * quantity - number of Rigs to calculate cost for
     */
    function _cost(uint256 quantity) private view returns (uint256) {
        return quantity * mintPrice;
    }

    /**
     * @dev See {ITablelandRigs-getClaimed}.
     */
    function getClaimed(
        address by
    ) public view returns (uint16 allowClaims, uint16 waitClaims) {
        uint64 packed = _getAux(by);
        allowClaims = uint16(packed);
        waitClaims = uint16(packed >> 16);
    }

    /**
     * @dev Sets allowlist and waitlist claims for `by` address.
     */
    function _setClaimed(
        address by,
        uint16 allowClaims,
        uint16 waitClaims
    ) private {
        _setAux(by, (uint64(waitClaims) << 16) | uint64(allowClaims));
    }

    /**
     * @dev See {ITablelandRigs-setMintPhase}.
     */
    function setMintPhase(uint256 _mintPhase) external onlyOwner {
        mintPhase = MintPhase(_mintPhase);
        emit MintPhaseChanged(mintPhase);
    }

    /**
     * @dev See {ITablelandRigs-setBeneficiary}.
     */
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    /**
     * @dev See {ITablelandRigs-setURITemplate}.
     */
    function setURITemplate(string[] memory uriTemplate) external onlyOwner {
        _setURITemplate(uriTemplate);
    }

    /**
     * @dev See {ITablelandRigs-contractURI}.
     */
    function contractURI() public view returns (string memory) {
        return _contractInfoURI;
    }

    /**
     * @dev See {ITablelandRigs-setContractURI}.
     */
    function setContractURI(string memory uri) external onlyOwner {
        _contractInfoURI = uri;
    }

    /**
     * @dev See {ITablelandRigs-setRoyaltyReceiver}.
     */
    function setRoyaltyReceiver(address receiver) external onlyOwner {
        _setDefaultRoyalty(receiver, 500);
    }

    /**
     * @dev See {ITablelandRigs-admin}.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev See {ITablelandRigs-setAdmin}.
     */
    function setAdmin(address adminAddress) external onlyOwner {
        _admin = adminAddress;
    }

    /**
     * @dev See {ITablelandRigs-pause}.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev See {ITablelandRigs-unpause}.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // =============================
    //      PARKING ADMIN LOGIC
    // =============================

    /**
     * @dev Throws if called by any account other than parking admin.
     */
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    /**
     * @dev Throws if the sender is not the admin or if admin has not
     * been initialized.
     */
    function _checkAdmin() private view {
        address adminAddress = admin();
        require(
            adminAddress != address(0) && adminAddress == _msgSender(),
            "Caller is not the admin"
        );
    }

    // =============================
    //      ITABLELANDRIGPILOTS
    // =============================

    /**
     * @dev See {ITablelandRigs-initPilots}.
     */
    function initPilots(address pilotsAddress) external onlyOwner {
        _pilots = ITablelandRigPilots(pilotsAddress);
    }

    /**
     * @dev See {ITablelandRigs-pilotSessionsTable}.
     */
    function pilotSessionsTable() external view returns (string memory) {
        return _pilots.pilotSessionsTable();
    }

    /**
     * @dev See {ITablelandRigs-pilotInfo}.
     */
    function pilotInfo(
        uint256 tokenId
    ) public view returns (ITablelandRigPilots.PilotInfo memory) {
        // Check the Rig `tokenId` exists
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        return _pilots.pilotInfo(tokenId);
    }

    /**
     * @dev See {ITablelandRigs-pilotInfo}.
     */
    function pilotInfo(
        uint256[] calldata tokenIds
    ) external view returns (ITablelandRigPilots.PilotInfo[] memory) {
        // For each token, call `pilotInfo`
        ITablelandRigPilots.PilotInfo[]
            memory allPilotInfo = new ITablelandRigPilots.PilotInfo[](
                tokenIds.length
            );
        for (uint8 i = 0; i < tokenIds.length; i++) {
            allPilotInfo[i] = pilotInfo(tokenIds[i]);
        }
        return allPilotInfo;
    }

    /**
     * @notice Returns the token owner and the sender. Useful for authorization
     * checks that take delegation into account.
     *
     * @dev If `msg.sender` is registered as a delegate for the address that owns
     * the rig in the delegate.cash registry (= msg.sender is allowed to act
     * on behalf of the owner), the owning address will be returned as sender.
     *
     * tokenId - the unique Rig token identifier
     */
    function _getTokenOwnerAndSenderWithDelegationCheck(
        uint256 tokenId
    ) private view returns (address tokenOwner, address sender) {
        sender = _msgSenderERC721A();
        tokenOwner = ownerOf(tokenId);

        if (
            _delegateCash.checkDelegateForToken(
                sender,
                tokenOwner,
                address(this),
                tokenId
            )
        ) {
            sender = tokenOwner;
        }
    }

    /**
     * @dev See {ITablelandRigs-trainRig}.
     */
    function trainRig(uint256 tokenId) public whenNotPaused {
        // Check the Rig `tokenId` exists
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // Verify `msg.sender` is authorized to train the specified Rig
        (
            address tokenOwner,
            address sender
        ) = _getTokenOwnerAndSenderWithDelegationCheck(tokenId);
        if (tokenOwner != sender) revert ITablelandRigPilots.Unauthorized();

        _pilots.trainRig(sender, tokenId);
        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev See {ITablelandRigs-trainRig}.
     */
    function trainRig(uint256[] calldata tokenIds) external whenNotPaused {
        // Ensure the array is non-empty & only allow a batch to be an arbitrary max length of 255
        // Clients should restrict this further to avoid gas exceeding limits
        if (tokenIds.length == 0 || tokenIds.length > type(uint8).max)
            revert ITablelandRigPilots.InvalidBatchPilotAction();

        // For each token, call `trainRig`
        for (uint8 i = 0; i < tokenIds.length; i++) {
            trainRig(tokenIds[i]);
        }
    }

    /**
     * @dev See {ITablelandRigs-pilotRig}.
     */
    function pilotRig(
        uint256 tokenId,
        address pilotAddr,
        uint256 pilotId
    ) public whenNotPaused {
        // Check the Rig `tokenId` exists
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // Verify `msg.sender` is authorized to pilot the specified Rig
        (
            address tokenOwner,
            address sender
        ) = _getTokenOwnerAndSenderWithDelegationCheck(tokenId);
        if (tokenOwner != sender) revert ITablelandRigPilots.Unauthorized();

        // If the supplied pilot address is `0x0`, then assume a trainer pilot
        // (note: `pilotId` has no impact here). Otherwise, proceed with a
        // custom pilot. The overloaded methods direct changes accordingly.
        pilotAddr == address(0)
            ? _pilots.pilotRig(sender, tokenId)
            : _pilots.pilotRig(sender, tokenId, pilotAddr, pilotId);

        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev See {ITablelandRigs-pilotRig}.
     */
    function pilotRig(
        uint256[] calldata tokenIds,
        address[] calldata pilotAddrs,
        uint256[] calldata pilotIds
    ) external whenNotPaused {
        // Ensure the arrays are non-empty
        if (
            tokenIds.length == 0 ||
            pilotAddrs.length == 0 ||
            pilotIds.length == 0
        ) revert ITablelandRigPilots.InvalidBatchPilotAction();

        // Ensure there is a 1:1 relationship between Rig `tokenIds` and pilots
        // Only allow a batch to be an arbitrary max length of 255
        // Clients should restrict this further (e.g., <=5) to avoid gas exceeding limits
        if (
            tokenIds.length != pilotAddrs.length ||
            tokenIds.length != pilotIds.length ||
            tokenIds.length > type(uint8).max
        ) revert ITablelandRigPilots.InvalidBatchPilotAction();

        // For each token, call `pilotRig`
        for (uint8 i = 0; i < tokenIds.length; i++) {
            pilotRig(tokenIds[i], pilotAddrs[i], pilotIds[i]);
        }
    }

    /**
     * @dev See {ITablelandRigs-parkRig}.
     */
    function parkRig(uint256 tokenId) public whenNotPaused {
        // Check the Rig `tokenId` exists
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // Verify `msg.sender` is authorized to park the specified Rig
        (
            address tokenOwner,
            address sender
        ) = _getTokenOwnerAndSenderWithDelegationCheck(tokenId);
        if (tokenOwner != sender) revert ITablelandRigPilots.Unauthorized();

        // Pass `false` to indicate a standard (non-force) park
        _pilots.parkRig(tokenId, false);
        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev See {ITablelandRigs-parkRig}.
     */
    function parkRig(uint256[] calldata tokenIds) external whenNotPaused {
        // Ensure the array is non-empty & only allow a batch to be an arbitrary max length of 255
        // Clients should restrict this further to avoid gas exceeding limits
        if (tokenIds.length == 0 || tokenIds.length > type(uint8).max)
            revert ITablelandRigPilots.InvalidBatchPilotAction();

        // For each token, call `parkRig`
        for (uint8 i = 0; i < tokenIds.length; i++) {
            parkRig(tokenIds[i]);
        }
    }

    function _forceParkRigs(uint256[] calldata tokenIds) private {
        // Ensure the array is non-empty & only allow a batch to be an arbitrary max length of 255
        // Clients should restrict this further to avoid gas exceeding limits
        if (tokenIds.length == 0 || tokenIds.length > type(uint8).max)
            revert ITablelandRigPilots.InvalidBatchPilotAction();

        // For each token, call `parkRig`
        for (uint8 i = 0; i < tokenIds.length; i++) {
            // Check the Rig `tokenId` exists
            if (!_exists(tokenIds[i])) revert OwnerQueryForNonexistentToken();
            // Pass `true` to indicate a force park
            _pilots.parkRig(tokenIds[i], true);
            emit MetadataUpdate(tokenIds[i]);
        }
    }

    /**
     * @dev See {ITablelandRigs-parkRigAsOwner}.
     */
    function parkRigAsOwner(uint256[] calldata tokenIds) external onlyOwner {
        _forceParkRigs(tokenIds);
    }

    /**
     * @dev See {ITablelandRigs-parkRigAsAdmin}.
     */
    function parkRigAsAdmin(uint256[] calldata tokenIds) external onlyAdmin {
        _forceParkRigs(tokenIds);
    }

    // =============================
    //            ERC721A
    // =============================

    /**
     * @dev See {ERC721A-_startTokenId}.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _getTokenURI(_toString(tokenId));
    }

    /**
     * @dev See {IERC721Metadata-safeTransferWhileFlying}.
     */
    function safeTransferWhileFlying(
        address from,
        address to,
        uint256 tokenId
    ) external {
        // Verify `msg.sender` is the token owner (prevent transfers by approved address or operator)
        if (ownerOf(tokenId) != _msgSenderERC721A())
            revert ITablelandRigPilots.Unauthorized();
        // Temporaritly set the transfer flag to allow a transfer to occur
        _allowTransferWhileFlying = true;
        safeTransferFrom(from, to, tokenId);
        // Reset the transfer flag to block transfers
        _allowTransferWhileFlying = false;
        // Update the value of `owner` in the current pilot's session
        _pilots.updateSessionOwner(tokenId, to);
    }

    /**
     * @dev See {ERC721A-_beforeTokenTransfers}.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        _requireNotPaused();
        // Block transfers by approved operators while a Rig is being piloted, but allow transfers *only* by the owner
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            // If the pilot's `startTime` is not zero, then the Rig is in-flight
            if (
                !(_pilots.pilotStartTime(tokenId) == 0 ||
                    _allowTransferWhileFlying == true)
            ) revert ITablelandRigPilots.InvalidPilotStatus();
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // =============================
    //           IERC165
    // =============================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == bytes4(0x49064906); // See EIP-4096
    }

    // =============================
    //       UUPSUpgradeable
    // =============================

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(address) internal view override onlyOwner {} // solhint-disable no-empty-blocks
}