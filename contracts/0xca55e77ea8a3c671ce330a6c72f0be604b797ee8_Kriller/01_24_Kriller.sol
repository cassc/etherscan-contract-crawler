// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721Sequential} from "./ERC721Sequential.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IMetadata {
    function getTrait(
        uint256 traitType,
        uint256 tokenId
    ) external view returns (string memory);

    function getTraitTypeName(
        uint256 traitType
    ) external view returns (string memory);
}

/*

◜╭───────────────────────────────────╮◝
 │ ◸    █▄▀ █▀█ █ █  █  ███ █▀█    ◹ │
 │ ◺    █ █ █▀▙ █ █▄ █▄ █▄▄ █▀▙    ◿ │
 ├───┬───────────────────────────┬───┤
 │ ▧ │  ▁▂▃▅▇██▇▅▃▂▁▂▃▅▇██▇▅▃▂▁  │ ▨ │
 │╾─╼│  ╾─────────────────────╼  │╾─╼│
 │ ◰ │  ▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄  │ ◳ │
 │╾─╼│  ╾─────────────────────╼  │╾─╼│
 │ ♯ │  ♩ ♯ ♫ ♬ ♪ ♭ ♭ ♪ ♬ ♫ ♯ ♩  │ ♯ │
 │╾─╼│  ╾─────────────────────╼  │╾─╼│
 │ ▢ │  █▓▓▓▒▓▒▒░▒░░░▒░▒▒▓▒▓▓▓█  │ ▢ │
 ├───┼───────────────────────────┼───┤
 │ $ │  KRILLER.COM @KRILLERXYZ  │ $ │
◟╰───┴───────────────────────────┴───╯◞

*/
/// @title KRILLER NFT
/// @author Jacob DeHart <[email protected]>
/// @notice An ambient audio-visual art project by James, Stephen, Greg, and Jacob
contract Kriller is
    ERC721Sequential,
    ERC2981,
    ReentrancyGuard,
    PaymentSplitter,
    RevokableDefaultOperatorFilterer,
    Ownable
{
    using ECDSA for bytes32;
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ExceedsAllotment();
    error SaleNotStarted();
    error MintingTooMany();
    error SoldOut();
    error InsufficientPayment();
    error InvalidPresalePass();
    error InvalidPresaleBalance();
    error BaseURIIsFrozen();
    error NoTokensOwned();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    /// https://eips.ethereum.org/EIPS/eip-4906
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /*//////////////////////////////////////////////////////////////
                           SUPPLY CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of cassettes mintable
    uint256 public immutable MAX_SUPPLY;

    /// @notice Price per cassette
    uint256 public immutable MINT_PRICE;

    /// @notice Maximum number of cassettes purchasable per transaction
    uint256 public constant MAX_PURCHASE_COUNT = 63;

    /*//////////////////////////////////////////////////////////////
                              METADATA
    //////////////////////////////////////////////////////////////*/

    /// @notice Base Token URI for each NFT
    string public baseTokenURI;

    /// @notice Whether the Base Token URI has been frozen
    bool public baseTokenURIFrozen;

    /// @notice Future on-chain metadata address
    address public metadataAddress;

    /// @notice Extra token data to store
    mapping(uint256 => uint256) private extraTokenData;

    /// @notice bitmask for the 160 bit minter address
    uint256 private constant BITMASK_MINTER = (1 << 160) - 1;
    /// @notice offset, 0, for the 160 bit minter address
    uint256 private constant BITMASK_MINTER_OFFSET = 0;
    /// @notice bitmask for the 31 bit mint date
    uint256 private constant BITMASK_MINT_DATE = (1 << 31) - 1;
    /// @notice offset, 160,  for the 31 bit mint date
    uint256 private constant BITMASK_MINT_DATE_OFFSET = 160;
    /// @notice bitmask for the 32 bit transfer date
    uint256 private constant BITMASK_TRANSFER_DATE = (1 << 32) - 1;
    /// @notice offset, 191,  for the 32 bit transfer date
    uint256 private constant BITMASK_TRANSFER_DATE_OFFSET = 191;
    /// @notice bitmask for the 33 bit remainder data
    uint256 private constant BITMASK_EXTRA = (1 << 33) - 1;
    /// @notice offset, 223,  for the 33 bit remainder data
    uint256 private constant BITMASK_EXTRA_OFFSET = 223;

    /*//////////////////////////////////////////////////////////////
                           SALE & PRESALE
    //////////////////////////////////////////////////////////////*/

    /// @notice The start of the presale
    uint256 public startPresaleDate = 1685824200;

    /// @notice The start of the public sale
    uint256 public startMintDate = 1685831400;

    /// @notice Mapping to track used presale tickets
    mapping(bytes => uint256) private usedTickets;

    /// @notice Message prefix used before hashing to verify presale tickets
    string public constant HASH_PREFIX = "KRILLER";

    /// @notice Authoritative wallet used for creating presale tickets
    address private presaleSigner;

    /// @notice Free tokens available for the team
    uint256 public availableTokensForTeam = 63;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets
    /// @param _name Token Name
    /// @param _symbol Token symbol
    /// @param _baseTokenURI Base Token URI for each NFT
    /// @param _maxSupply Collection size
    /// @param _mintPrice Price per token
    /// @param _presaleSigner Authoritative wallet used for creating presale tickets
    /// @param _payees List of creator wallets for payment splitting
    /// @param _shares Shares for creator wallets for payment splitting
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _maxSupply,
        uint256 _mintPrice,
        address _presaleSigner,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721Sequential(_name, _symbol) PaymentSplitter(_payees, _shares) {
        baseTokenURI = _baseTokenURI;
        MAX_SUPPLY = _maxSupply;
        MINT_PRICE = _mintPrice;
        presaleSigner = _presaleSigner;
        _setDefaultRoyalty(address(this), 630);
    }

    /*//////////////////////////////////////////////////////////////
                          EXTRA PACKED DATA
    //////////////////////////////////////////////////////////////*/

    struct TokenDetail {
        address minter;
        uint256 mintDate;
        address owner;
        uint256 transferDate;
        uint256 transferCount;
    }

    function setMinter(uint256 tokenId, address value) internal {
        uint resetMask = BITMASK_MINTER << BITMASK_MINTER_OFFSET;
        extraTokenData[tokenId] &= ~resetMask;
        extraTokenData[tokenId] |=
            uint256(uint160(value)) <<
            BITMASK_MINTER_OFFSET;
    }

    function setMintDate(uint256 tokenId, uint256 value) internal {
        uint resetMask = BITMASK_MINT_DATE << BITMASK_MINT_DATE_OFFSET;
        extraTokenData[tokenId] &= ~resetMask;
        extraTokenData[tokenId] |=
            (value & BITMASK_MINT_DATE) <<
            BITMASK_MINT_DATE_OFFSET;
    }

    function setTransferDate(uint256 tokenId, uint256 value) internal {
        uint resetMask = BITMASK_TRANSFER_DATE << BITMASK_TRANSFER_DATE_OFFSET;
        extraTokenData[tokenId] &= ~resetMask;
        extraTokenData[tokenId] |=
            (value & BITMASK_TRANSFER_DATE) <<
            BITMASK_TRANSFER_DATE_OFFSET;
    }

    function setTransferCount(uint256 tokenId, uint256 value) internal {
        uint resetMask = BITMASK_EXTRA << BITMASK_EXTRA_OFFSET;
        extraTokenData[tokenId] &= ~resetMask;
        extraTokenData[tokenId] |=
            (value & BITMASK_EXTRA) <<
            BITMASK_EXTRA_OFFSET;
    }

    function minterOf(uint256 tokenId) public view returns (address) {
        return address(uint160(extraTokenData[tokenId] & BITMASK_MINTER));
    }

    function mintDateOf(uint256 tokenId) public view returns (uint256) {
        return
            (extraTokenData[tokenId] >> BITMASK_MINT_DATE_OFFSET) &
            BITMASK_MINT_DATE;
    }

    function transferDateOf(uint256 tokenId) public view returns (uint256) {
        return
            (extraTokenData[tokenId] >> BITMASK_TRANSFER_DATE_OFFSET) &
            BITMASK_TRANSFER_DATE;
    }

    function transferCountOf(uint256 tokenId) public view returns (uint256) {
        return
            (extraTokenData[tokenId] >> BITMASK_EXTRA_OFFSET) & BITMASK_EXTRA;
    }

    function extraDataOf(
        uint256 tokenId
    ) public view returns (TokenDetail memory) {
        return
            TokenDetail(
                minterOf(tokenId),
                mintDateOf(tokenId),
                ownerOf(tokenId),
                transferDateOf(tokenId),
                transferCountOf(tokenId)
            );
    }

    /*//////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice This function will purchase `numberOfTokens` NFT's once the presale has started
    /// @param numberOfTokens The number of tokens to purchase in this transaction
    /// @param pass The authorative signature for this user's presale purchases
    /// @param allotment The total number of presale purchases this user is assigned
    function presaleMint(
        uint256 numberOfTokens,
        bytes memory pass,
        uint256 allotment
    ) external payable nonReentrant {
        if (!presaleActive()) revert SaleNotStarted();
        uint256 mintablePresale = validateTicket(pass, allotment, msg.sender);
        if (numberOfTokens > mintablePresale) revert ExceedsAllotment();
        if (msg.value < numberOfTokens * MINT_PRICE)
            revert InsufficientPayment();
        useTicket(pass, numberOfTokens);
        _mintNFT(numberOfTokens, msg.sender);
    }

    /// @notice This function will purchase `numberOfTokens` NFT's once the presale has started
    /// @param numberOfTokens The number of tokens to purchase in this transaction
    /// @param allotment The total number of presale purchases this user is assigned
    /// @param collection The NFT collection they must hold
    function presaleMintCollection(
        uint256 numberOfTokens,
        bytes memory pass,
        uint256 allotment,
        address collection
    ) external payable nonReentrant {
        if (!presaleActive()) revert SaleNotStarted();
        uint256 mintablePresale = validateTicket(pass, allotment, collection);
        if (numberOfTokens > mintablePresale) revert ExceedsAllotment();
        if (ERC721Sequential(collection).balanceOf(msg.sender) == 0)
            revert InvalidPresaleBalance();
        if (msg.value < numberOfTokens * MINT_PRICE)
            revert InsufficientPayment();
        useTicket(pass, numberOfTokens);
        _mintNFT(numberOfTokens, msg.sender);
    }

    /// @notice This function will purchase `numberOfTokens` NFT's
    /// @param numberOfTokens The number of tokens to purchase in this transaction
    function mint(uint256 numberOfTokens) external payable nonReentrant {
        if (!saleActive()) revert SaleNotStarted();
        if (msg.value < numberOfTokens * MINT_PRICE)
            revert InsufficientPayment();
        _mintNFT(numberOfTokens, msg.sender);
    }

    /// @notice This function will mint `numberOfTokens` to the specified address for free
    /// @param to The receiver of the tokens
    function ownerMint(uint256 numberOfTokens, address to) external onlyOwner {
        if (numberOfTokens > availableTokensForTeam) revert MintingTooMany();
        availableTokensForTeam -= availableTokensForTeam;
        _mintNFT(numberOfTokens, to);
    }

    /// @notice Helper for minting NFT's used by presaleMint and mint
    function _mintNFT(uint256 numberOfTokens, address to) internal {
        if (numberOfTokens > MAX_PURCHASE_COUNT) revert MintingTooMany();
        if (totalMinted() + numberOfTokens > MAX_SUPPLY) revert SoldOut();
        uint256 time = block.timestamp;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to);
            uint256 tokenId = totalSupply();
            setMinter(tokenId, to);
            setMintDate(tokenId, time);
        }
    }

    /// @notice Helper to determine if the presale is active
    /// @return presaleActive true if active
    function presaleActive() public view returns (bool) {
        return
            startPresaleDate > 0 &&
            startPresaleDate <= block.timestamp &&
            startMintDate > block.timestamp;
    }

    /// @notice Helper to determine if the sale is active
    /// @return saleActive true if active
    function saleActive() public view returns (bool) {
        return startMintDate > 0 && startMintDate <= block.timestamp;
    }

    /// @notice Hashes the custom prefix, sender address, and allotment for presale pass verification
    /// @return hash the 256 bit keccak hash
    function getHash(
        uint256 allotment,
        address addr
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(HASH_PREFIX, msg.sender, allotment, addr)
            );
    }

    /// @notice Recovers the signer of the presale pass signature for presale authorization
    /// @return address the signer address
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    /// @notice Determines if a supplied pass signature and allotment was signed by the correct address
    /// @return remainingAllotment the number of mints still available for this pass
    function validateTicket(
        bytes memory pass,
        uint256 allotment,
        address collection
    ) internal view returns (uint256) {
        bytes32 hash = getHash(allotment, collection);
        address signer = recover(hash, pass);
        if (signer != presaleSigner) revert InvalidPresalePass();
        return allotment - usedTickets[pass];
    }

    /// @notice Updates our record of how many tokens were minted with each pass
    function useTicket(bytes memory pass, uint256 quantity) internal {
        usedTickets[pass] += quantity;
    }

    /// @notice Return the number of NFT's minted with a particular pass
    /// @param pass The claim pass used
    /// @return nftCount The number of NFT's already minted
    function usedTicketCount(
        bytes memory pass
    ) external view returns (uint256) {
        return usedTickets[pass];
    }

    /*//////////////////////////////////////////////////////////////
                          TOKEN METADATA
    //////////////////////////////////////////////////////////////*/

    /// @notice Overrides ERC721S to return our custom baseTokenURI
    /// @return baseTokenURI the current URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Update the base URI to reveal the NFTs
    /// @param _baseTokenURI The new baseTokenURI
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        if (baseTokenURIFrozen) revert BaseURIIsFrozen();
        baseTokenURI = _baseTokenURI;
        emit BatchMetadataUpdate(1, totalSupply());
    }

    /// @notice Owner can freeze the base token uri, if not already frozen
    function freezeBaseTokenURI() external onlyOwner {
        baseTokenURIFrozen = true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /// @notice Owner can set the metadata address if the address has not been frozen
    /// @param _metadataAddress The new metadata address
    function setMetadataAddress(address _metadataAddress) external onlyOwner {
        metadataAddress = _metadataAddress;
    }

    /// @notice Get the trait `traitType` value for `tokenId`
    /// @param traitType The trait type
    /// @param tokenId The token to look up
    /// @return trait the trait value of the specified type
    function getTrait(
        uint256 traitType,
        uint256 tokenId
    ) external view returns (string memory) {
        if (metadataAddress == address(0)) {
            return "";
        }
        return IMetadata(metadataAddress).getTrait(traitType, tokenId);
    }

    /// @notice Get the name for trait `traitType`
    /// @param traitType The trait type
    /// @return trait the trait type name of the specified type
    function getTraitTypeName(
        uint256 traitType
    ) external view returns (string memory) {
        if (metadataAddress == address(0)) {
            return "";
        }
        return IMetadata(metadataAddress).getTraitTypeName(traitType);
    }

    /// @notice Owner can update the presale date
    /// @param _startPresaleDate The new presale Start Date
    function setStartPresaleDate(uint256 _startPresaleDate) external onlyOwner {
        startPresaleDate = _startPresaleDate;
    }

    /// @notice Owner can update the public sale date
    /// @param _startMintDate The new public Start Date
    function setStartMintDate(uint256 _startMintDate) external onlyOwner {
        startMintDate = _startMintDate;
    }

    /*//////////////////////////////////////////////////////////////
                              ROYALTIES
    //////////////////////////////////////////////////////////////*/

    // EIP2981 Override
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Sequential, ERC2981) returns (bool) {
        // Support EIP-4906
        if (interfaceId == bytes4(0x49064906)) return true;
        return super.supportsInterface(interfaceId);
    }

    /// @notice Set the default royalty values for the collection
    /// @param receiver The receiver of the royalties
    /// @param feeNumerator The royalty amount
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Removes default royalty information.
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @notice Sets the royalty information for a specific token id, overriding the global default.
    /// @param tokenId The specific token id
    /// @param receiver The receiver of the royalties
    /// @param feeNumerator The royalty amount
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @notice Resets royalty information for the token id back to the global default.
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    // Operator Filter Overrides

    function owner()
        public
        view
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        setTransferCount(tokenId, transferCountOf(tokenId) + 1);
        setTransferDate(tokenId, block.timestamp);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        setTransferCount(tokenId, transferCountOf(tokenId) + 1);
        setTransferDate(tokenId, block.timestamp);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        setTransferCount(tokenId, transferCountOf(tokenId) + 1);
        setTransferDate(tokenId, block.timestamp);
        super.safeTransferFrom(from, to, tokenId, data);
    }
}