// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC721S.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

interface IBurbMetadata {
    function getTrait(uint256 traitType, uint256 tokenId)
        external
        view
        returns (string memory);

    function getTraitTypeName(uint256 traitType)
        external
        view
        returns (string memory);
}

interface IBurbImageData {
    function getPNG(uint256 tokenId) external view returns (string memory);
}

/*

                  BURBURB
                BURB  BURBS
                  BURBSBURBS
                  BBBBBBBBBBBURBS
                    BURBS
                    BURBS
               BURBSBURBSBURBSSS
              BRB             BRB
            BRB                 BRB
            BRB                 BRB
            BRB                 BRB
            BRB                 BRB
            BRB                 BRB
            BRB   BU        BU  BRB
            BRB   RB        RB  BRB
            BRB                 BRB
            BRB         BURBS   BRB
            BRB       BRB   BUUURBBBS
            BRB     BRB             BRB
            BRB     BURBSSSSSSSSSSSSS
            BRB        BU     UURBS
            BRB         BURBBS BRB
            BRB               BRB
            BRB     SBRUBSBRUUB
            BRB     BRB
            BRB     BRB
 */

error ExceedsAllotment();
error SaleNotStarted();
error MintingTooMany();
error SoldOut();
error InsufficientPayment();
error InvalidPresalePass();
error BaseURIIsFrozen();
error ProvenanceHashFrozen();
error BurbMetadataFrozen();
error BurbImageDataFrozen();

/// @title CryptoBurbs II
/// @author Jacob DeHart, Mike Mitchell, The Visitors
/// @notice CryptoBurbs II ERC721 NFT
/// @custom:website https://cryptoburbs.com
contract CryptoBurbsII is
    ERC721Sequential,
    ReentrancyGuard,
    Ownable,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;
    mapping(bytes => uint256) private usedTickets;
    string public baseTokenURI;
    bool public baseTokenURIFrozen;
    uint256 public startPresaleDate;
    uint256 public startMintDate;
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MINT_PRICE = 0.042 ether;
    uint256 public constant MAX_PURCHASE_COUNT = 50;
    string public constant HASH_PREFIX = "BURBS";
    uint256 public provenanceHash =
        0x34c14f92a886482d5eec3d051519a18bbf35ab5ddf223781e42ad341ac320755;
    bool public provenanceHashFrozen;
    address private presaleSigner;
    address public burbMetadataAddress;
    bool public burbMetadataFrozen;
    address public burbImageDataAddress;
    bool public burbImageDataFrozen;

    constructor(
        uint256 _startPresaleDate,
        uint256 _startMintDate,
        string memory _baseTokenURI,
        address _presaleSigner,
        address[] memory _payees,
        uint256[] memory _shares
    )
        ERC721Sequential("CryptoBurbs II", "BURBSII")
        PaymentSplitter(_payees, _shares)
    {
        startPresaleDate = _startPresaleDate;
        startMintDate = _startMintDate;
        baseTokenURI = _baseTokenURI;
        presaleSigner = _presaleSigner;
    }

    /// @notice This function will claim `numberOfTokens` free NFT's once the presale has started
    /// @param numberOfTokens The number of tokens to claim in this transaction
    /// @param pass The authorative signature for this user's free claims
    /// @param allotment The total number of free claims this user is assigned
    function freeClaim(
        uint256 numberOfTokens,
        bytes memory pass,
        uint256 allotment
    ) public nonReentrant {
        if (!presaleActive()) revert SaleNotStarted();
        uint256 mintablePresale = validateTicket(pass, allotment);
        if (numberOfTokens > mintablePresale) revert ExceedsAllotment();
        useTicket(pass, numberOfTokens);
        mintBurbs(numberOfTokens);
    }

    /// @notice This function will purchase `numberOfTokens` NFT's
    /// @param numberOfTokens The number of tokens to claim in this transaction
    function mint(uint256 numberOfTokens) public payable nonReentrant {
        if (!saleActive()) revert SaleNotStarted();
        if (msg.value < numberOfTokens * MINT_PRICE)
            revert InsufficientPayment();
        mintBurbs(numberOfTokens);
    }

    /// @notice Helper for minting burbs used by freeClaim and mint
    function mintBurbs(uint256 numberOfTokens) internal {
        if (numberOfTokens > MAX_PURCHASE_COUNT) revert MintingTooMany();
        if (totalMinted() + numberOfTokens > MAX_SUPPLY) revert SoldOut();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    /// @notice Helper to determine if the presale is active
    /// @return presaleActive true if active
    function presaleActive() public view returns (bool) {
        return startPresaleDate <= block.timestamp;
    }

    /// @notice Helper to determine if the sale is active
    /// @return saleActive true if active
    function saleActive() public view returns (bool) {
        return startMintDate > block.timestamp;
    }

    /// @notice Overrides ERC721S to return our custom baseTokenURI
    /// @return baseTokenURI the current URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Hashes the custom prefix, sender address, and allotment for presale pass verification
    /// @return hash the 256 bit keccak hash
    function getHash(uint256 allotment) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(HASH_PREFIX, msg.sender, allotment));
    }

    /// @notice Recovers the signer of the presale pass signature for presale authorization
    /// @return address the signer address
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    /// @notice Determines if a supplied pass signature and allotment was signed by the correct address
    /// @return remainingAllotment the number of mints still available for this pass
    function validateTicket(bytes memory pass, uint256 allotment)
        internal
        view
        returns (uint256)
    {
        bytes32 hash = getHash(allotment);
        address signer = recover(hash, pass);
        if (signer != presaleSigner) revert InvalidPresalePass();
        return allotment - usedTickets[pass];
    }

    /// @notice Updates our record of how many tokens were minted with each pass
    function useTicket(bytes memory pass, uint256 quantity) internal {
        usedTickets[pass] += quantity;
    }

    /// @notice Return the number of NFT's minted with a particular pass
    /// @param pass The free claim pass used
    /// @return nftCount The number of NFT's already minted
    function usedTicketCount(bytes memory pass)
        external
        view
        returns (uint256)
    {
        return usedTickets[pass];
    }

    /// @notice Update the base URI to reveal the NFTs
    /// @param _baseTokenURI The new baseTokenURI
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        if (baseTokenURIFrozen) revert BaseURIIsFrozen();
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Owner can freeze the base token uri, if not already frozen
    function freezeBaseTokenURI() external onlyOwner {
        baseTokenURIFrozen = true;
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

    /// @notice Owner can set the provenance hash if the hash has not been frozen
    /// @param _provenanceHash The new provenance hash, if not already frozen
    function setProvenanceHash(uint256 _provenanceHash) external onlyOwner {
        if (provenanceHashFrozen) revert ProvenanceHashFrozen();
        provenanceHash = _provenanceHash;
    }

    /// @notice Owner can freeze the provenance hash once the art has been finalized
    function freezeProvenanceHash() external onlyOwner {
        provenanceHashFrozen = true;
    }

    /// @notice Owner can set the metadata address if the address has not been frozen
    /// @param _burbMetadataAddress The new burb metadata address, if not already frozen
    function setBurbMetadataAddress(address _burbMetadataAddress)
        external
        onlyOwner
    {
        if (burbMetadataFrozen) revert BurbMetadataFrozen();
        burbMetadataAddress = _burbMetadataAddress;
    }

    /// @notice Owner can freeze the on-chain metadata
    function freezeBurbMetadata() external onlyOwner {
        burbMetadataFrozen = true;
    }

    /// @notice Owner can set the image address if the address has not been frozen
    /// @param _burbImageDataAddress The new burb image address, if not already frozen
    function setBurbImageDataAddress(address _burbImageDataAddress)
        external
        onlyOwner
    {
        if (burbImageDataFrozen) revert BurbImageDataFrozen();
        burbImageDataAddress = _burbImageDataAddress;
    }

    /// @notice Owner can freeze the on-chain image data
    function freezeBurbImageData() external onlyOwner {
        burbImageDataFrozen = true;
    }

    /// @notice Get the trait `traitType` value for burb `tokenId`
    /// @param traitType The trait type
    /// @param tokenId The burb to look up
    /// @return trait the trait value of the specified type
    function getTrait(uint256 traitType, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        if (burbMetadataAddress == address(0)) {
            return "";
        }
        return IBurbMetadata(burbMetadataAddress).getTrait(traitType, tokenId);
    }

    /// @notice Get the name for trait `traitType`
    /// @param traitType The trait type
    /// @return trait the trait type name of the specified type
    function getTraitTypeName(uint256 traitType)
        external
        view
        returns (string memory)
    {
        if (burbMetadataAddress == address(0)) {
            return "";
        }
        return IBurbMetadata(burbMetadataAddress).getTraitTypeName(traitType);
    }

    /// @notice Get the PNG image data for burb `tokenId`
    /// @dev Returns BASE64 encoded PNG data
    /// @param tokenId The burb to get the image data for
    /// @return imageData the image data for the specified burb
    function getPNG(uint256 tokenId) external view returns (string memory) {
        if (burbImageDataAddress == address(0)) {
            return "";
        }
        return IBurbImageData(burbImageDataAddress).getPNG(tokenId);
    }
}