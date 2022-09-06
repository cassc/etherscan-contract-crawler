// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// @author divergence.xyz
contract Moonbirds is
    AccessControlEnumerable,
    BaseTokenURI,
    FixedPriceSeller,
    SignerManager,
    ERC2981,
    ERC721ACommon
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    /**
    @notice Role of administrative users allowed to expel a Moonbird from the
    nest.
    @dev See expelFromNest().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");
    string public storefrontURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory tknURI,
        string memory _storefrontURI,
        uint supplyCap,
        address payable beneficiary,
        address payable royaltyReceiver
    )
        BaseTokenURI(tknURI)
        FixedPriceSeller(
            0, // price of 0 wei
            Seller.SellerConfig({
                totalInventory: supplyCap,
                maxPerAddress: 2,
                maxPerTx: 2,
                freeQuota: 0,
                reserveFreeQuota: false,
                lockFreeQuota: false,
                lockTotalInventory: true
            }),
            beneficiary
        )
        ERC721ACommon(
            name, // token name
            symbol, // token symbol
            beneficiary, // royalty receiver
            500 // royalties, bps
        )
    {
        setStorefrontURI(_storefrontURI);
        _setDefaultRoyalty(royaltyReceiver, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EXPULSION_ROLE, msg.sender);
    }

    function setStorefrontURI(string memory uri) onlyOwner public {
        storefrontURI = uri;
    }

    function contractURI() public view returns(string memory) {
        return storefrontURI;
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

        // We're using two separate pools (one from Seller, and one for PROOF
        // minting), so add an extra layer of checks for this invariant. This
        // should never fail as each pool has its own restriction, and is in
        // place purely for tests (hence assert).
        assert(totalSupply() <= 10_000);
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Mint as a non-holder of PROOF tokens.
     */
    function mintPublic(
        address to,
        uint amt
    ) external payable {
        _purchase(to, amt);
    }

    /**
    @notice Flag indicating whether holders of PROOF passes can mint.
     */
    bool public proofMintingOpen = false;

    /**
    @notice Sets whether holders of PROOF passes can mint.
     */
    function setPROOFMintingOpen(bool open) external onlyOwner {
        proofMintingOpen = open;
    }

    /**
    @notice Mint unclaimed tokens from the PROOF-holder pool.
     */
    function mintUnclaimed(address to, uint256 n)
        external
        onlyOwner
    {
        _handlePurchase(to, n, true);
    }

    /**
    @dev tokenId to nesting start time (0 = not nesting).
     */
    mapping(uint256 => uint256) private nestingStarted;

    /**
    @dev Cumulative per-token nesting, excluding the current period.
     */
    mapping(uint256 => uint256) private nestingTotal;

    /**
    @notice Returns the length of time, in seconds, that the Moonbird has
    nested.
    @dev Nesting is tied to a specific Moonbird, not to the owner, so it doesn't
    reset upon sale.
    @return nesting Whether the Moonbird is currently nesting. MAY be true with
    zero current nesting if in the same block as nesting began.
    @return current Zero if not currently nesting, otherwise the length of time
    since the most recent nesting began.
    @return total Total period of time for which the Moonbird has nested across
    its life, including the current period.
     */
    function nestingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = nestingStarted[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        total = current + nestingTotal[tokenId];
    }

    /**
    @dev MUST only be modified by safeTransferWhileNesting(); if set to 2 then
    the _beforeTokenTransfer() block while nesting is disabled.
     */
    uint256 private nestingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the Moonbird is minting,
    thus not resetting the nesting period.
     */
    function safeTransferWhileNesting(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "Moonbirds: Only owner");
        nestingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        nestingTransfer = 1;
    }

    /**
    @dev Block transfers while nesting.
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
                nestingStarted[tokenId] == 0 || nestingTransfer == 2,
                "Moonbirds: nesting"
            );
        }
    }

    /**
    @dev Emitted when a Moonbird begins nesting.
     */
    event Nested(uint256 indexed tokenId);

    /**
    @dev Emitted when a Moonbird stops nesting; either through standard means or
    by expulsion.
     */
    event Unnested(uint256 indexed tokenId);

    /**
    @dev Emitted when a Moonbird is expelled from the nest.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether nesting is currently allowed.
    @dev If false then nesting is blocked, but unnesting is always allowed.
     */
    bool public nestingOpen = false;

    /**
    @notice Toggles the `nestingOpen` flag.
     */
    function setNestingOpen(bool open) external onlyOwner {
        nestingOpen = open;
    }

    /**
    @notice Changes the Moonbird's nesting status.
    */
    function toggleNesting(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = nestingStarted[tokenId];
        if (start == 0) {
            require(nestingOpen, "Moonbirds: nesting closed");
            nestingStarted[tokenId] = block.timestamp;
            emit Nested(tokenId);
        } else {
            nestingTotal[tokenId] += block.timestamp - start;
            nestingStarted[tokenId] = 0;
            emit Unnested(tokenId);
        }
    }

    /**
    @notice Changes the Moonbirds' nesting statuss (what's the plural of status?
    statii? statuses? status? The plural of sheep is sheep; maybe it's also the
    plural of status).
    @dev Changes the Moonbirds' nesting sheep (see @notice).
     */
    function toggleNesting(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleNesting(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a Moonbird from the nest.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has nested and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting bird to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because nesting would then be all-or-nothing for all of a particular owner's
    Moonbirds.
     */
    function expelFromNest(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
        require(nestingStarted[tokenId] != 0, "Moonbirds: not nested");
        nestingTotal[tokenId] += block.timestamp - nestingStarted[tokenId];
        nestingStarted[tokenId] = 0;
        emit Unnested(tokenId);
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