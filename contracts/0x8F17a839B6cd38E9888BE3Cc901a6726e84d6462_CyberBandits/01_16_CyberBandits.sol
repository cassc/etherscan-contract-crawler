// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC721S.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/*

                    $$$$$$$$$$$$$$$$
              $$$$$$$$$$$$$$$$$$$$$$$$$$$$
           $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
     $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$       $$$$$$$$$$$$$$$$$$$$       $$$$
$$$$$$$$$$$$$$$$$         $$$$$$$$$$$$$$$$$$         $$$
$$$$$$$$$$$$$$$$$$       $$$$$$$$$$$$$$$$$$$$       $$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$   $$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$     $$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$      $$$$$$$$$$$$$$$$$
  $  $$$$$$$$$$$$$$$$$$$$$$$$$$$   $    $$$$$$$$$$$$$$$$
 $$$$  $$$$$$$$$$$$$$$$$$$$$$$$$   $$    $$$$$$$$$$$$$
  $$$$$$$$      $$$$$$$$$$$$$$$    $$   $$$$$$$$$$
  $$$$$$$$        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$          $$$$$    $$$$$$$$$$$$$$$$$$$$
   $$$$$$$$         $$$$$    $$$$$$$ $$$$$ $$$$$$
   $$$$$$$$$$$                               $$$$
   $$$$$$$$$$$$$$$$$     $$$$$$$$$ $$$$ $$$$$$$$$
   $$$$$$$$$$$$$$$$$$$$  $$$$$$$$$$$$$$$$$$$$$$$$$
     $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
          $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
              $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                        $$$$$$$$$$$$$$$$$$$$$
                               $$$$$$$$$$$

 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $          Cyber Bandits ~ By Michael Reeder          $
 $  cyber-bandits.com • michael-reeder.com • 0x420.io  $
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 */

/// @title CyberBandits
/// @author Jacob DeHart
/// @notice CyberBandits ERC721 NFT
/// @custom:website https://cyber-bandits.com/
contract CyberBandits is
    ERC721Sequential,
    ReentrancyGuard,
    Ownable,
    PaymentSplitter
{
    error ExceedsAllotment();
    error SaleNotStarted();
    error MintingTooMany();
    error SoldOut();
    error InsufficientPayment();
    error InvalidPresalePass();
    error BaseURIIsFrozen();
    error ProvenanceHashFrozen();
    error NotEnoughFreebiesLeft();

    using Strings for uint256;
    using ECDSA for bytes32;
    mapping(bytes => uint256) private usedTickets;
    string public baseTokenURI;
    bool public baseTokenURIFrozen;
    uint256 public startPresaleDate;
    uint256 public startMintDate;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_PURCHASE_COUNT = 25;
    uint256 private artistFreebies = 25;
    string public constant HASH_PREFIX = "CYBERBANDITS";
    uint256 public provenanceHash =
        0xeb2d24e20e33ec21cfbc5a08551f9bfad183c52bad0acbe9c1a00317ae7ec2f1;
    bool public provenanceHashFrozen;
    address private presaleSigner;

    constructor(
        uint256 _startPresaleDate,
        uint256 _startMintDate,
        string memory _baseTokenURI,
        address _presaleSigner,
        address[] memory _payees,
        uint256[] memory _shares
    )
        ERC721Sequential("Cyber Bandits", "BANDIT")
        PaymentSplitter(_payees, _shares)
    {
        startPresaleDate = _startPresaleDate;
        startMintDate = _startMintDate;
        baseTokenURI = _baseTokenURI;
        presaleSigner = _presaleSigner;
    }

    /// @notice This function will purchase `numberOfTokens` free NFT's once the presale has started
    /// @param numberOfTokens The number of tokens to purchase in this transaction
    /// @param pass The authorative signature for this user's presale purchases
    /// @param allotment The total number of presale purchases this user is assigned
    function presaleMint(
        uint256 numberOfTokens,
        bytes memory pass,
        uint256 allotment
    ) external payable nonReentrant {
        if (!presaleActive()) revert SaleNotStarted();
        uint256 mintablePresale = validateTicket(pass, allotment);
        if (numberOfTokens > mintablePresale) revert ExceedsAllotment();
        if (msg.value < numberOfTokens * MINT_PRICE)
            revert InsufficientPayment();
        useTicket(pass, numberOfTokens);
        _mintNFT(numberOfTokens);
    }

    /// @notice This function will purchase `numberOfTokens` NFT's
    /// @param numberOfTokens The number of tokens to purchase in this transaction
    function mint(uint256 numberOfTokens) external payable nonReentrant {
        if (!saleActive()) revert SaleNotStarted();
        if (msg.value < numberOfTokens * MINT_PRICE)
            revert InsufficientPayment();
        _mintNFT(numberOfTokens);
    }

    /// @notice Helper for minting NFT's used by presaleMint and mint
    function _mintNFT(uint256 numberOfTokens) internal {
        if (numberOfTokens > MAX_PURCHASE_COUNT) revert MintingTooMany();
        if (totalMinted() + numberOfTokens > MAX_SUPPLY) revert SoldOut();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    /// @notice This function will mint up to `artistFreebies` free NFT's for the contract owner
    function mintArtistFreebies(uint256 numberOfTokens) external payable onlyOwner {
      if (numberOfTokens > artistFreebies) revert NotEnoughFreebiesLeft();
      artistFreebies -= numberOfTokens;
      _mintNFT(numberOfTokens);
    }

    /// @notice Helper to determine if the presale is active
    /// @return presaleActive true if active
    function presaleActive() public view returns (bool) {
        return startPresaleDate <= block.timestamp;
    }

    /// @notice Helper to determine if the sale is active
    /// @return saleActive true if active
    function saleActive() public view returns (bool) {
        return startMintDate <= block.timestamp;
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
}