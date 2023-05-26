// SPDX-License-Identifier: UNLICENCED
// Implementation Copyright 2021, the author; All rights reserved
//
// This contract is an on-chain implementation of a concept created and
// developed by John F Simon Jr in partnership with e•a•t•works and
// @fingerprintsDAO
pragma solidity 0.8.10;

import "./EveryIconLib.sol";
import "base64-sol/base64.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721CommonEnumerable.sol";
import "@divergencetech/ethier/contracts/sales/LinearDutchAuction.sol";
import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Every Icon
/// @author @divergenceharri (@divergence_art)
contract EveryIcon is ERC721CommonEnumerable, LinearDutchAuction {
    using DynamicBuffer for bytes;
    using EveryIconLib for EveryIconLib.Repository;
    using Strings for uint256;

    /// @notice Contracts containing base icons from which designs are built.
    EveryIconLib.Repository private repo;

    constructor(
        string memory name,
        string memory symbol,
        EveryIconLib.Repository memory repo_,
        address[] memory payees,
        uint256[] memory shares
    )
        ERC721CommonEnumerable(name, symbol)
        LinearDutchAuction(
            LinearDutchAuction.DutchAuctionConfig({
                startPoint: 0, // disabled upon deployment
                startPrice: 5.12 ether,
                unit: AuctionIntervalUnit.Time,
                decreaseInterval: 300, // 5 minutes
                decreaseSize: 0.128 ether,
                numDecreases: 36
            }),
            0.512 ether,
            Seller.SellerConfig({
                totalInventory: 512,
                maxPerAddress: 0, // unlimited
                maxPerTx: 1,
                freeQuota: 42,
                reserveFreeQuota: true,
                lockTotalInventory: true,
                lockFreeQuota: true
            }),
            payable(0)
        )
    {
        setRepository(repo_);
        setBeneficiary(payable(new PaymentSplitter(payees, shares)));
    }

    /**** TOKEN AND SALES CONTROLS ****/

    /// @dev The current cost of a single mint can be fetched with cost(1).
    function buy() external payable {
        Seller._purchase(msg.sender, 1);
    }

    /// @dev Flag to signal permanent locking of the icon repository.
    bool public repositoryLocked;

    /// @dev Require that icon repository isn't locked yet.
    modifier repositoryUnlocked() {
        require(!repositoryLocked, "Repository locked");
        _;
    }

    /// @dev Sets addresses of icon-repository contracts.
    function setRepository(EveryIconLib.Repository memory repo_)
        public
        onlyOwner
        repositoryUnlocked
    {
        repo = repo_;
    }

    /// @dev Permanently locks the icon repository addresses.
    function lockRepository() external onlyOwner repositoryUnlocked {
        repositoryLocked = true;
    }

    /// @dev Base URI for returning iframe address in tokenURI().
    string public animationURIBase;

    /// @dev Sets current animationURIBase.
    function setAnimationURIBase(string memory base) external onlyOwner {
        animationURIBase = base;
    }

    /// @notice Hash of transaction in which front-end code is archived for
    /// on-chain provenance.
    bytes32 public codeStorageTxHash;

    /// @dev Sets codeStorageTxHash for front-code archival.
    function setCodeStorageTxHash(bytes32 txHash) external onlyOwner {
        codeStorageTxHash = txHash;
    }

    /// @notice Returns metadata as a JSON-encoded data URI.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bytes memory buf = DynamicBuffer.allocate(2**16);
        bytes memory tokenIdStr = bytes(tokenId.toString());

        buf.appendSafe("{");
        buf.appendSafe('"name":"Every Icon #');
        buf.appendSafe(tokenIdStr);
        buf.appendSafe('","image":"data:image/svg+xml,');
        buf.appendSafe(renderSVG(tokenId, 0));
        buf.appendSafe('","animation_url":"');
        buf.appendSafe(bytes(animationURIBase));
        buf.appendSafe(tokenIdStr);
        buf.appendSafe('"}');

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(buf)
                )
            );
    }

    /// @dev Required override for LinearDutchAuction's underlying Seller;
    /// effectively the minting function.
    function _handlePurchase(
        address to,
        uint256 num,
        bool
    ) internal override {
        for (uint256 i = 0; i < num; i++) {
            _safeMint(to, totalSupply());
            EveryIconLib.Token memory token;
            token.combMethod = INVALID_COMB_METHOD;
            tokens.push(token);
            mintingBlocks.push(
                uint32(block.number & EveryIconLib.MINTING_BLOCK_MASK)
            );
        }
    }

    /**** EVERY ICON-SPECIFIC FUNCTIONS ****/

    /// @notice Metadata describing every token's icon. The block in which a
    /// token is minted is also encoded in the image.
    EveryIconLib.Token[] public tokens;
    uint32[] public mintingBlocks;

    /// @notice Used to identify an unset EveryIconLib.Token. All new instances
    /// have this value.
    uint8 private constant INVALID_COMB_METHOD = 255;

    /// @notice Checks whether a token has already had its icon set by the owner
    function iconIsSet(uint256 tokenId) public view returns (bool) {
        return tokens[tokenId].combMethod != INVALID_COMB_METHOD;
    }

    /// @notice Time from which the front-end "ticks" icons. If an icon design
    /// isn't set by a collector within the allowed window, a random token is
    /// used and defaultSettingTime replaces iconSettingTimes.
    mapping(uint256 => uint256) public iconSettingTimes;
    uint256 defaultSettingTime;

    /// @notice Closes the window for token owners to set their own icons. After
    /// this point, unset tokens will be randomly allocated icons.
    function closeIconSettingWindow() public onlyOwner {
        defaultSettingTime = block.timestamp;
    }

    /// @notice Sets the 'starting icon'. This is only available if it has not
    /// already been set (either by the owner, or automatically by the contract
    /// when the setting window closed).
    function setIcon(uint256 tokenId, EveryIconLib.Token memory token)
        public
        whenNotPaused
        onlyApprovedOrOwner(tokenId)
    {
        require(!iconIsSet(tokenId), "Icon already set");
        require(defaultSettingTime == 0, "Icon randomly set");
        require(token.designIcon0 < 100, "Design icon 0 invalid");
        require(token.designIcon1 < 100, "Design icon 1 invalid");
        require(token.designIcon0 != token.designIcon1, "Repeated design icon");
        require(token.randIcon < 28, "Random icon invalid");
        require(token.combMethod < 3, "Combination method invalid");

        tokens[tokenId] = token;
        iconSettingTimes[tokenId] = block.timestamp;
    }

    /// @notice Default icon to show in thumbnails before a design is set. The
    /// actual icon has first and last words set to 0.
    uint256[2] private defaultIcon = [
        18609191942226762260243923200536250640,
        1923275577535336623121870409490058871001437930765964941608582343745444249600
    ];

    /// @notice Returns data required to render an icon in the browser.
    /// @return icon Bit-wise representation of the token.
    /// @return iconSettingTime The time from which the icon ticks, if non-zero.
    /// Zero value indicates the token is a placeholder
    function iconData(uint256 tokenId, uint256 ticks)
        public
        view
        returns (uint256[4] memory icon, uint256 iconSettingTime)
    {
        if (!iconIsSet(tokenId) && defaultSettingTime == 0) {
            icon[1] = defaultIcon[0];
            icon[2] = defaultIcon[1];
            return (icon, iconSettingTime);
        }

        EveryIconLib.Token memory token;

        if (iconIsSet(tokenId) == true) {
            token = tokens[tokenId];
            iconSettingTime = iconSettingTimes[tokenId];
        } else {
            token = EveryIconLib.randomToken(tokenId, mintingBlocks[tokenId]);
            iconSettingTime = defaultSettingTime;
        }

        icon = repo.startingBits(token, mintingBlocks[tokenId], ticks);

        return (icon, iconSettingTime);
    }

    /// @notice Ticks per second, as used by peekSVG.
    uint8 constant TICKS_PER_SECOND = 100;

    /// @notice Returns an SVG of the icon as it would be at the moment the function
    /// was called, having 'ticked' ever since being set at the rate TICKS_PER_SECOND
    function peekSVG(uint256 tokenId) external view returns (bytes memory) {
        uint256 startTime = iconIsSet(tokenId)
            ? iconSettingTimes[tokenId]
            : defaultSettingTime;

        return
            renderSVG(
                tokenId,
                (block.timestamp - startTime) * TICKS_PER_SECOND
            );
    }

    /// @notice Returns static SVG for a particular token. This is used for thumbnails
    /// and in the OpenSea listing, before the viewer clicks into the animated version of
    /// a piece
    function renderSVG(uint256 tokenId, uint256 ticks)
        public
        view
        returns (bytes memory)
    {
        (uint256[4] memory icon, ) = iconData(tokenId, ticks);
        return EveryIconLib.renderSVG(icon);
    }
}