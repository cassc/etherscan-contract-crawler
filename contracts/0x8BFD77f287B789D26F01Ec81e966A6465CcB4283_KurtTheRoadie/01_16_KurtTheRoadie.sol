//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./KSDefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/**
 * @title "Kurt The Roadie" Contract
 * @author Ben Yu, rminla.eth and Itzik Lerner AKA the NFTDevz
 * @notice This contract supports the "Kurt the Roadie" NFT drop
 */

contract KurtTheRoadie is
    ERC721A,
    ERC2981,
    Ownable,
    KSDefaultOperatorFilterer
{
    using Strings for uint256;
    using SafeMath for uint256;

    // constants
    uint256 public constant MAX_SUPPLY = 5200;

    //token properties
    string public baseTokenURI;
    string public contractURI;

    // fairness properties
    uint256 public startingIndex;
    uint256 public startingIndexTimestamp;
    string public provenance =
        "3ce42f696559f86cca6a32ec60bed95153ffd66085db1d142a4e3f0c1a850663";
    uint256 public provenanceTimestamp;

    //commercial properties
    address public royaltyAddress = 0x59705Eb15a3965c75F871977976A8f053BC4B752;
    uint96 public royaltyFee = 1000;

    // Checkin 
    mapping(uint256 => bool) private checkedInTokens;
    event CheckedIn(address owner, uint256 _tokenID);
    event CheckedOut(address owner, uint256 _tokenID);

    /**
     * @param name Token name
     * @param symbol Token symbol
     * @param baseTokenURI_ Base URI for all tokens
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_
    ) ERC721A(name, symbol) {
        baseTokenURI = baseTokenURI_;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Sets a provenance hash of pregenerated tokens for fairness. Should be set before first token mints
     */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenance = _provenanceHash;
        provenanceTimestamp = block.timestamp;
    }

    /**
     * @notice Set the starting index allow list mints
     */
    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Starting index already set");

        startingIndex = generateRandomStartingIndex(MAX_SUPPLY);
        startingIndexTimestamp = block.timestamp;
    }

    /**
     * @notice Creates a random starting index to offset pregenerated tokens by for fairness
     */
    function generateRandomStartingIndex(uint256 _range)
        private
        view
        returns (uint256)
    {
        uint256 index;
        // Blockhash only works for the most 256 recent blocks.
        uint256 _block_shift = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        _block_shift = 1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        index = uint256(blockhash(_block_ref)) % _range;

        // Prevent default sequence
        // or same last digit
        if (index % 10 == 0) {
            index++;
        }

        return index;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Change starting tokenId to 1 (from ERC721A)
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev implements operator-filter-registry blocklist filtering
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev implements operator-filter-registry blocklist filtering 
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev implements operator-filter-registry blocklist filtering 
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Ensure that total supply has not been exceeded
     */
    modifier supplyNotExceeded(uint256 _numTokens) {
        require(
            totalSupply() + _numTokens <= MAX_SUPPLY,
            "Max Supply Exceeded"
        );
        _;
    }

    modifier isOwnerOf(uint256 _tokenID) {
        require(ownerOf(_tokenID) == msg.sender, "Is not your token");
        _;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function airdrop(address[] memory luckyRecipients, uint256[] memory amounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < luckyRecipients.length; i++) {
            _mint(luckyRecipients[i], amounts[i]);
        }
    }

    function checkIn(uint256 _tokenID) external isOwnerOf(_tokenID) {
        require(checkedInTokens[_tokenID] == false, "Already checked in");
        checkedInTokens[_tokenID] = true;
        emit CheckedIn(msg.sender, _tokenID);
    }

    function checkOut(uint256 _tokenID) external isOwnerOf(_tokenID) {
        require(checkedInTokens[_tokenID] == true, "Already checked out");
        checkedInTokens[_tokenID] = false;
        emit CheckedOut(msg.sender, _tokenID);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    /**
     * @notice Update the contractURI for OpenSea
     *         Update for collection-specific metadata
     *         https://docs.opensea.io/docs/contract-level-metadata
     */
    function setContractURI(string calldata _newContractURI)
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }
}