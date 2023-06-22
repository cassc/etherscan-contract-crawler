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
import "hardhat/console.sol";

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// @author
contract ScavengersWTF is
    AccessControlEnumerable,
    ERC2981,
    SignerManager,
    FixedPriceSeller,
    BaseTokenURI,
    ERC721ACommon
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    


    /**
    @notice Role of administrative users allowed to expel a  Pyrapod from the
    hibernate.
    @dev See expelFromHibernate().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    uint256 public constant MAX_SCAVENGERS = 10001;
    

    constructor(
        string memory name,
        string memory symbol,
        address payable beneficiary,
        address payable royaltyReceiver
    )
        ERC721ACommon(name, symbol, royaltyReceiver, 0)
        BaseTokenURI("")
        FixedPriceSeller(
            0 ether,
            // Not including a separate pool for HOOKS holders, taking the total
            // to 10,001. 
            // We don't enforce buyer limits here because it's already
            // done by only issuing a single signature per address, and double
            // enforcement would waste gas.
            Seller.SellerConfig({
                totalInventory: MAX_SCAVENGERS,
                lockTotalInventory: false,
                maxPerAddress: 3,
                maxPerTx: 2,
                freeQuota: 1000,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        _setDefaultRoyalty(royaltyReceiver, 0);
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
        assert(totalSupply() <= 10001);
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Flag indicating whether whitelisted wallets can mint.
     */
    bool public whitelistMintingOpen = false;

    /**
    @notice Sets whether whitelisted wallets can mint.
     */
    function setWhitelistMintingOpen(bool open) external onlyOwner {
        whitelistMintingOpen = open;
    }

    /**
    @notice Mint as a Whitelisted wallet.
    @param n Number of tokens to mint. Can not be more than 2.
     */
    function mintWhitelist(
        address to,
        uint256 n,
        bytes32 nonce,
        bytes calldata sig
    ) external payable {
        require(whitelistMintingOpen, "ScavengersWTF: Whitelist minting closed");

        _purchase(to, n);
        
        signers.requireValidSignature(
            signaturePayload(to, nonce),
            sig,
            usedMessages
        );
        
        
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
    @notice Flag indicating whether public can mint.
     */
    bool public publicMintingOpen = false;

    /**
    @notice Sets whether public can mint.
     */
    function setPublicMintingOpen(bool open) external onlyOwner {
        publicMintingOpen = open;
    }

    /**
    @notice Mint as public.
    @param n Number of tokens to mint. Total number of tokens in wallet 
    can not exceed 5.
     */
    function mintPublic(
        address to,
        uint256 n
    ) external payable {
        require(publicMintingOpen, "ScavengersWTF: Public minting closed");
        
        _purchase(to, n);
    }


    function toggleToPublicMinting() external onlyOwner {
        publicMintingOpen = true;
        uint256 newTotalInventory = MAX_SCAVENGERS;
        setPrice(0.008 ether);
        Seller.setSellerConfig(
            Seller.SellerConfig({
                totalInventory: newTotalInventory,
                lockTotalInventory: true,
                maxPerAddress: 5,
                maxPerTx: 5,
                freeQuota: 1000,
                lockFreeQuota: true,
                reserveFreeQuota: true
            })
        );
    }

    function mintAdmin(
        address to,
        uint256 n
    ) external onlyOwner {
        Seller.setSellerConfig(
            Seller.SellerConfig({
                totalInventory: MAX_SCAVENGERS,
                lockTotalInventory: true,
                maxPerAddress: 5555,
                maxPerTx: 5555,
                freeQuota: 1000,
                lockFreeQuota: true,
                reserveFreeQuota: true
            })
        );
        _purchase(to, n);
    }

    /**
    @dev tokenId to hibernating start time (0 = not hibernating).
     */
    mapping(uint256 => uint256) private hibernatingStarted;

    /**
    @dev Cumulative per-token hibernating, excluding the current period.
     */
    mapping(uint256 => uint256) private hibernatingTotal;

    /**
    @notice Returns the length of time, in seconds, that the Pyrapod has
    hibernated.
    @dev Hibernating is tied to a specific Pyrapod, not to the owner, so it doesn't
    reset upon sale.
    @return hibernating Whether the Pyrapod is currently hibernating. MAY be true with
    zero current hibernating if in the same block as hibernating began.
    @return current Zero if not currently hibernating, otherwise the length of time
    since the most recent hibernating began.
    @return total Total period of time for which the Pyrapod has hibernated across
    its life, including the current period.
     */
    function hibernatingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool hibernating,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = hibernatingStarted[tokenId];
        if (start != 0) {
            hibernating = true;
            current = block.timestamp - start;
        }
        total = current + hibernatingTotal[tokenId];
    }

    /**
    @dev Block transfers while hibernating.
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                hibernatingStarted[tokenId] == 0,
                "ScavengersWTF: hibernating"
            );
            hibernatingTotal[tokenId] = 0;
        }
    }

    /**
    @dev Emitted when a Pyrapod begins hibernating.
     */
    event Hibernated(uint256 indexed tokenId);

    /**
    @dev Emitted when a Pyrapod stops hibernating; either through standard means or
    by expulsion.
     */
    event Unhibernated(uint256 indexed tokenId);

    /**
    @dev Emitted when a Pyrapod is expelled from the hibernate.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether hibernating is currently allowed.
    @dev If false then hibernating is blocked, but unhibernating is always allowed.
     */
    bool public hibernatingOpen = false;

    /**
    @notice Toggles the `hibernatingOpen` flag.
     */
    function setHibernatingOpen(bool open) external onlyOwner {
        hibernatingOpen = open;
    }

    /**
    @notice Changes the Pyrapod's hibernating status.
    */
    function toggleHibernating(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = hibernatingStarted[tokenId];
        if (start == 0) {
            require(hibernatingOpen, "ScavengersWTF: hibernating closed");
            hibernatingStarted[tokenId] = block.timestamp;
            emit Hibernated(tokenId);
        } else {
            hibernatingTotal[tokenId] += block.timestamp - start;
            hibernatingStarted[tokenId] = 0;
            emit Unhibernated(tokenId);
        }
    }

    /**
    @notice Changes the ScavengersWTF' hibernating statuss (what's the plural of status?
    statii? statuses? status? The plural of sheep is sheep; maybe it's also the
    plural of status).
    @dev Changes the ScavengersWTF' hibernating sheep (see @notice).
     */
    function toggleHibernating(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleHibernating(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a Pyrapod from the hibernate.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has hibernated and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting bird to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because hibernating would then be all-or-nothing for all of a particular owner's
    ScavengersWTF.
     */
    function expelFromHibernate(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
        require(hibernatingStarted[tokenId] != 0, "ScavengersWTF: not hibernated");
        hibernatingTotal[tokenId] = 0;
        hibernatingStarted[tokenId] = 0;
        emit Unhibernated(tokenId);
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