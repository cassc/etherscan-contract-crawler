// SPDX-License-Identifier: GPL-3.0

/// @title The VesselVerse ERC-721 token

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
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IVesselVerse} from "./interfaces/IVesselVerse.sol";

contract VesselVerse is
    ERC721ACommon,
    BaseTokenURI,
    AccessControlEnumerable,
    IVesselVerse
{
    // An address who has permissions to mint VesselVerse
    address public minter;

    // Whether the minter can be updated
    bool public isMinterLocked;

    /// VesselVerse treasury
    address payable public beneficiary;

    // The internal VesselVerse ID tracker
    uint256 private _currentVesselVerseId;

    // Total token supply
    uint256 public supply;

    /**
    @notice Role of administrative users allowed to expel a VesselVerse from the
    rack.
    @dev See expelFromRack().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, "Minter is locked");
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address payable _beneficiary,
        address payable royaltyReciever,
        address _minter,
        uint256 _supply
    ) ERC721ACommon(name, symbol, royaltyReciever, 500) BaseTokenURI("") {
        minter = _minter;
        beneficiary = _beneficiary;
        supply = _supply;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    /**
     * @notice Mint a VesselVerse to the minter
     * @dev Call _safeMint with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        require(totalSupply() < supply, "Exceeds Maximum VesselVerse supply");
        if (_currentVesselVerseId % 25 == 0) {
            _mintTo(beneficiary, _currentVesselVerseId++);
        }
        return _mintTo(minter, _currentVesselVerseId++);
    }

    /**
     * @notice Mint a VesselVerse to the provided `to` address.
     */
    function _mintTo(address to, uint256 vesselVerseId)
        internal
        returns (uint256)
    {
        _safeMint(to, 1);
        emit VesselVerseCreated(vesselVerseId);

        return vesselVerseId;
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter)
        external
        override
        onlyOwner
        whenMinterNotLocked
    {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /// @notice Sets the VesselVerse treasury address.
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    // @notice Returns if there is any supply left
    function supplyLeft() public view returns (bool) {
        if (totalSupply() < supply) {
            return true;
        }
        return false;
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
    @notice Returns the length of time, in seconds, that the VesselVerse has
    racked.
    @dev Racking is tied to a specific VesselVerse, not to the owner, so it doesn't
    reset upon sale.
    @return racking Whether the VesselVerse is currently racking. MAY be true with
    zero current racking if in the same block as racking began.
    @return current Zero if not currently racking, otherwise the length of time
    since the most recent racking began.
    @return total Total period of time for which the VesselVerse has racked across
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
    @notice Transfer a token between addresses while the VesselVerse is minting,
    thus not resetting the racking period.
     */
    function safeTransferWhileRacking(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "VesselVerse: Only owner");
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
                "VesselVerse: racking"
            );
        }
    }

    /**
    @dev Emitted when a VesselVerse begins racking.
     */
    event Racked(uint256 indexed tokenId); // Racked

    /**
    @dev Emitted when a VesselVerse stops racking; either through standard means or
    by expulsion.
     */
    event Unracked(uint256 indexed tokenId); // Unracked

    /**
    @dev Emitted when a VesselVerse is expelled.
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
    @notice Changes the VesselVerse's racking status.
    */
    function toggleRacking(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = rackingStarted[tokenId];
        if (start == 0) {
            require(rackingOpen, "VesselVerse: racking closed");
            rackingStarted[tokenId] = block.timestamp;
            emit Racked(tokenId);
        } else {
            rackingTotal[tokenId] += block.timestamp - start;
            rackingStarted[tokenId] = 0;
            emit Unracked(tokenId);
        }
    }

    /**
    @notice Changes multiple VesselVerses' racking status
     */
    function toggleRacking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleRacking(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a VesselVerse from the rack.
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
        require(burningOpen, "VesselVerse: burning not enabled");
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
        override(ERC721ACommon, AccessControlEnumerable, IERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}