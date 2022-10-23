// SPDX-License-Identifier: GPL-3.0

/// @title The VesselVerseGenesis ERC-721 token

// .
// .
// .
// .                                                                      ........
// .                                                             .‘;codxxkkO0KK0kkkxxdoc:‘.
// .                                                        .,cdxkkxol:;,..oNWNd’.‘’;:loxkkkdl,.
// .                                                     ‘cxKNMWKl.        lWN0:        .,oONMWKkl’
// .                                                  ‘lkOdlclokXNk’      .dWKx,       ;kXNXKKKXXNXOl’
// .                                               .:xOx:.      ;0WO.     .OMKd,     .oNWk;......’;lk0k:.
// .                                             .cOOl.        .’xWWOooodx0WMWXKOkkkkKWMNx,..        ’o0Oc.
// .                                           .:OOc.   ..,coxOKXWMMNK0OkkKWMN0kddddkXWMWNNX0koc,.     .o0Oc.
// .                                          ‘x0o. .,cx0XNX0kdldXMK:.    :XWx,.     :KM0:,cox0XNKkl;.   .dKk,
// .                                         c0O;‘:xKNXOdc,..   cXNo      ;XWo.      .xWK,    ..;oOXNKx:.  ;0Kc.
// .                                       .oKkldKN0d:.        ;KWk.      :NWl.       ;KWx.        .:xKNKd,..xXd.
// .                                      .dNNKNKx;.          ;0WO’       cNNc         cXNd.          .:kXNOc,xXx.
// .                                     .dNMWKo.            :KWk’        lNNc          cXNx.            ‘dKN0x0Nd.
// .                                     lNMNd’            .lXWx.         lWX:           :KWO,             .oXWNWNl
// .                                    ,KMK:             .dNNo.          oWX:            ’kWKc              ‘xNMMK;
// .                                   .xW0,             ,OWK:            oWX;             .dNNo.              :0WWx.
// .                                   ;K0,             cKWk’            .dWK,               cKWk’              .dNX;
// .                                   lXl            .dNNo.              dWK,                ;0W0,              .xWo
// .                                  .xK;           ’kWKc               .dWK,                 ’kWK:              lNk.
// .                                  .kK,          ’OW0;                .dWK,                  .xWXc             :NO.
// .                                  .OK,         ‘OW0,                 .dWK,                   .dNXl            :X0’
// .                                  .kX;        .kWK;                  .dWK,                    .dNXl           cNO.
// .                                  .dNl       .dWX:                   .dWK,                     .dWX:         .dWx.
// .                                   :Xk.      cNNl                     dWK;                      .xWK;        .ONc
// .                                   .OK;     ’0Wk.                    .dWK,                       ‘0Wk.       cN0’
// .                                    cXx.    oWX:                      dWK;                        cXNo      .ONl
// .                                    .xXl   ‘0Mk.                      oWX;                        .kM0’    .dNk.
// .                                     ,0K:  :XWl                       oWX:                         cNNc    lX0,
// .                                      ;0K; cNN:                       lNX:                         ,KWd.  cXK;
// .                                       ;0KloNN:                       cNNc                         ,KMd..oX0;
// .                                        ‘kXXWWo                       cNNc                         ;XWd,xNO,
// .                                         .oXMM0’                      :XWl.                        oWWKKXd.
// .                                           ;OWWx.                     ;XWo.                       ,0MMWO;
// .                                            .c0Nk,                    ,KWd..                     .xWW0c.
// .                                              .:OKkc.                 ’0Mx,.                   .l0XOc.
// .                                                .,d0Kxc.              .OMk;.                ‘ckKKd;.
// .                                                   .;d0KOo:‘.         .OMOc.           .‘:dOK0x:.
// .                                                      .,lx0K0koc;‘..  .kM0o,   ...,;cdk0K0xl,.
// .                                                          .‘:ldk0000OOOXMWX0kkO00KK0Odl:‘.
// .                                                                ..‘,;:ccllllcc:;,’..
// .
// .

pragma solidity ^0.8.17;

import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VesselVerseGenesis is
    ERC721ACommon,
    BaseTokenURI,
    FixedPriceSeller,
    SignerManager,
    AccessControlEnumerable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    enum MintPhase {
        NONE,
        PAUSED,
        ALLOWLIST_SALE,
        PUBLIC_SALE,
        SOLD_OUT
    }

    /**
    @notice Role of administrative users allowed to expel a VesselVerseGenesis from the
    rack.
    @dev See expelFromRack().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    MintPhase public mintPhase = MintPhase.NONE;

    constructor(
        string memory name,
        string memory symbol,
        address payable beneficiary,
        address payable royaltyReciever,
        uint256 totalInventory,
        uint256 maxPerAddress,
        uint256 maxPerTx,
        uint248 freeQuota
    )
        ERC721ACommon(name, symbol, royaltyReciever, 500)
        BaseTokenURI("")
        FixedPriceSeller(
            0 ether,
            Seller.SellerConfig({
                totalInventory: totalInventory,
                lockTotalInventory: true,
                maxPerAddress: maxPerAddress,
                maxPerTx: maxPerTx,
                freeQuota: freeQuota,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    /**
     * @notice Ensure function cannot be called outside of a given mint phase
     * @param _mintPhase Correct mint phase for function to execute
     */
    modifier inMintPhase(MintPhase _mintPhase) {
        if (mintPhase != _mintPhase) {
            revert IncorrectMintPhase();
        }
        _;
    }

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        _safeMint(to, n);
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Allowlist Mint Function
     */
    function mintAllowlist(
        address to,
        bytes32 nonce,
        bytes calldata sig
    ) external payable inMintPhase(MintPhase.ALLOWLIST_SALE) {
        signers.requireValidSignature(
            signaturePayload(to, nonce),
            sig,
            usedMessages
        );
        _purchase(to, 1);
    }

    /**
    @notice Public Mint Function
     */
    function mintPublic(address to)
        external
        payable
        inMintPhase(MintPhase.PUBLIC_SALE)
    {
        _purchase(to, 1);
    }

    /**
    @notice Returns whether the address has minted with the particular nonce. If
    true, future calls to mint() with the same parameters will fail.
    @dev In production we will never issue more than a single nonce per address,
    but this allows for testing with a single address.
     */
    function alreadyMinted(address to, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return
            usedMessages[
                SignatureChecker.generateMessage(signaturePayload(to, nonce))
            ];
    }

    /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
     */
    function signaturePayload(address to, bytes32 nonce)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(to, nonce);
    }

    /**
     * @notice Set the mint phase
     * @notice Use restricted to contract owner
     * @param _mintPhase New mint phase
     */
    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    ////////////////////////
    // STAKING //
    ////////////////////////

    /**
    @dev tokenId to racking start time (0 = not racking).
     */
    mapping(uint256 => uint256) private rackingStarted;

    /**
    @dev Cumulative per-token racking, excluding the current period.
     */
    mapping(uint256 => uint256) private rackingTotal;

    /**
    @notice Returns the length of time, in seconds, that the VesselVerseGenesis has
    racked.
    @dev Racking is tied to a specific VesselVerseGenesis, not to the owner, so it doesn't
    reset upon sale.
    @return racking Whether the VesselVerseGenesis is currently racking. MAY be true with
    zero current racking if in the same block as racking began.
    @return current Zero if not currently racking, otherwise the length of time
    since the most recent racking began.
    @return total Total period of time for which the VesselVerseGenesis has racked across
    its life, including the current period.
     */
    function rackingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool racking,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = rackingStarted[tokenId];
        if (start != 0) {
            racking = true;
            current = block.timestamp - start;
        }
        total = current + rackingTotal[tokenId];
    }

    /**
    @dev MUST only be modified by safeTransferWhileRacking(); if set to 2 then
    the _beforeTokenTransfer() block while racking is disabled.
     */
    uint256 private rackingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the VesselVerseGenesis is minting,
    thus not resetting the racking period.
     */
    function safeTransferWhileRacking(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(
            ownerOf(tokenId) == _msgSender(),
            "VesselVerseGenesis: Only owner"
        );
        rackingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        rackingTransfer = 1;
    }

    /**
    @dev Block transfers while racking.
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                rackingStarted[tokenId] == 0 || rackingTransfer == 2,
                "VesselVerseGenesis: racking"
            );
        }
    }

    /**
    @dev Emitted when a VesselVerseGenesis begins racking.
     */
    event Racked(uint256 indexed tokenId); // Racked

    /**
    @dev Emitted when a VesselVerseGenesis stops racking; either through standard means or
    by expulsion.
     */
    event Unracked(uint256 indexed tokenId); // Unracked

    /**
    @dev Emitted when a VesselVerseGenesis is expelled.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether racking is currently allowed.
    @dev If false then racking is blocked, but unracking is always allowed.
     */
    bool public rackingOpen = false; // rackingOpen

    /**
    @notice Toggles the `rackingOpen` flag.
     */
    function setRackingOpen(bool open) external onlyOwner {
        rackingOpen = open;
    }

    /**
    @notice Changes the VesselVerseGenesis's racking status.
    */
    function toggleRacking(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = rackingStarted[tokenId];
        if (start == 0) {
            require(rackingOpen, "VesselVerseGenesis: racking closed");
            rackingStarted[tokenId] = block.timestamp;
            emit Racked(tokenId);
        } else {
            rackingTotal[tokenId] += block.timestamp - start;
            rackingStarted[tokenId] = 0;
            emit Unracked(tokenId);
        }
    }

    /**
    @notice Changes multiple VesselVerseGenesis's racking status
     */
    function toggleRacking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleRacking(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a VesselVerseGenesis from the rack.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has racked and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting bird to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because racking would then be all-or-nothing for all of a particular owner's
    VesselVerse.
     */
    function expelFromRack(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
        require(rackingStarted[tokenId] != 0, "VesselVerse: not racked");
        rackingTotal[tokenId] += block.timestamp - rackingStarted[tokenId];
        rackingStarted[tokenId] = 0;
        emit Unracked(tokenId);
        emit Expelled(tokenId);
    }

    ////////////////////////
    // BURNING //
    ////////////////////////

    /**
    @notice Whether burning is currently allowed.
    @dev If false then burning is blocked
     */
    bool public burningOpen = false; // burningOpen

    /**
    @notice Toggles the `burningOpen` flag.
     */
    function setBurningOpen(bool open) external onlyOwner {
        burningOpen = open;
    }

    function burn(uint256 tokenId) public virtual onlyApprovedOrOwner(tokenId) {
        require(burningOpen, "VesselVerseGenesis: burning not enabled");
        _burn(tokenId);
    }

    ////////////////////////
    // MISC. //
    ////////////////////////

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////////////////////////
    // ERRORS //
    ////////////////////////

    /**
     * Incorrect mint phase for action
     */
    error IncorrectMintPhase();
}