// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/sales/LinearDutchAuction.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract BosoTokyo is
    ERC721ACommon,
    BaseTokenURI,
    LinearDutchAuction,
    SignerManager,
    ERC2981,
    AccessControlEnumerable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    /**
    @notice Role of administrative users allowed to expel a token from the
    revving.
    @dev See expelFromRevving().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        address payable beneficiary,
        address payable royaltyReceiver
    )
        ERC721ACommon(name, symbol)
        BaseTokenURI("")
        LinearDutchAuction(
            DutchAuctionConfig(
                1659841200,  // 12:00, 7 Aug, 2022 (JST)
                1.2 ether,
                40 minutes,
                0.1 ether,
                6,
                LinearDutchAuction.AuctionIntervalUnit.Time
            ),
            0.6 ether,
            Seller.SellerConfig({
                totalInventory: 10_000,
                lockTotalInventory: true,
                maxPerAddress: 0,
                maxPerTx: 10,
                freeQuota: 10_000,
                lockFreeQuota: false,
                reserveFreeQuota: false
            }),
            beneficiary
        )
    {
        _setDefaultRoyalty(royaltyReceiver, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        _safeMint(to, n);

        assert(totalSupply() <= 10_000);
    }

    function mintPublic(
        address to,
        uint256 num
    ) external payable {
        _purchase(to, num);
    }

    /**
    @dev tokenId to revving start time (0 = not revving).
     */
    mapping(uint256 => uint256) private revvingStarted;

    /**
    @dev Cumulative per-token revving, excluding the current period.
     */
    mapping(uint256 => uint256) private revvingTotal;

    /**
    @notice Returns the length of time, in seconds, that the token has
    revved.
    @dev Revving is tied to a specific token, not to the owner, so it doesn't
    reset upon sale.
    @return revving Whether the token is currently revving. MAY be true with
    zero current revving if in the same block as revving began.
    @return current Zero if not currently revving, otherwise the length of time
    since the most recent revving began.
    @return total Total period of time for which the token has revved across
    its life, including the current period.
     */
    function revvingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool revving,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = revvingStarted[tokenId];
        if (start != 0) {
            revving = true;
            current = block.timestamp - start;
        }
        total = current + revvingTotal[tokenId];
    }

    /**
    @dev MUST only be modified by safeTransferWhileRevving(); if set to 2 then
    the _beforeTokenTransfer() block while revving is disabled.
     */
    uint256 private revvingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the token is minting,
    thus not resetting the revving period.
     */
    function safeTransferWhileRevving(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "BosoTokyo: Only owner");
        revvingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        revvingTransfer = 1;
    }

    /**
    @dev Block transfers while revving.
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
                revvingStarted[tokenId] == 0 || revvingTransfer == 2,
                "BosoTokyo: revving"
            );
        }
    }

    /**
    @dev Emitted when a token begins revving.
     */
    event Revved(uint256 indexed tokenId);

    /**
    @dev Emitted when a token stops revving; either through standard means or
    by expulsion.
     */
    event Unrevved(uint256 indexed tokenId);

    /**
    @dev Emitted when a token is expelled from the revving.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether revving is currently allowed.
    @dev If false then revving is blocked, but unrevving is always allowed.
     */
    bool public revvingOpen = false;

    /**
    @notice Toggles the `revvingOpen` flag.
     */
    function setRevvingOpen(bool open) external onlyOwner {
        revvingOpen = open;
    }

    /**
    @notice Changes the token's revving status.
    */
    function toggleRevving(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = revvingStarted[tokenId];
        if (start == 0) {
            require(revvingOpen, "BosoTokyo: revving closed");
            revvingStarted[tokenId] = block.timestamp;
            emit Revved(tokenId);
        } else {
            revvingTotal[tokenId] += block.timestamp - start;
            revvingStarted[tokenId] = 0;
            emit Unrevved(tokenId);
        }
    }

    /**
    @notice Changes the BosoTokyo' revving statuss (what's the plural of status?
    statii? statuses? status? The plural of sheep is sheep; maybe it's also the
    plural of status).
    @dev Changes the BosoTokyo' revving sheep (see @notice).
     */
    function toggleRevving(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleRevving(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a token from the revving.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has revved and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting bird to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because revving would then be all-or-nothing for all of a particular owner's
    BosoTokyo.
     */
    function expelFromRevving(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
        require(revvingStarted[tokenId] != 0, "BosoTokyo: not revved");
        revvingTotal[tokenId] += block.timestamp - revvingStarted[tokenId];
        revvingStarted[tokenId] = 0;
        emit Unrevved(tokenId);
        emit Expelled(tokenId);
    }

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

    /**
    @notice If set, contract to which tokenURI() calls are proxied.
     */
    ITokenURIGenerator public renderingContract;

    /**
    @notice Sets the optional tokenURI override contract.
     */
    function setRenderingContract(ITokenURIGenerator _contract)
        external
        onlyOwner
    {
        renderingContract = _contract;
    }

    /**
    @notice If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(renderingContract) != address(0)) {
            return renderingContract.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}