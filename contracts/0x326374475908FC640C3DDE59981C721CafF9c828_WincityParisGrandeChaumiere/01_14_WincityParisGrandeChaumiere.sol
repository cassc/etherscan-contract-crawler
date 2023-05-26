//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

//  __          _______ _   _  _____ _____ _________     __
//  \ \        / /_   _| \ | |/ ____|_   _|__   __\ \   / /
//   \ \  /\  / /  | | |  \| | |      | |    | |   \ \_/ / 
//    \ \/  \/ /   | | | . ` | |      | |    | |    \   /  
//     \  /\  /   _| |_| |\  | |____ _| |_   | |     | |   
//      \/  \/   |_____|_| \_|\_____|_____|  |_|     |_|   
//
// Contract Type :  Revenue-based Finance Decentralised
// Operator : SAS FONCIERE WINCITY ( French company )
// Fees : They are available on wincity.com
/// @author WinCity | Emmanuel Chappat 
/// @title Wincity Paris Grande Chaumiere

contract WincityParisGrandeChaumiere is ERC1155, ERC1155Pausable, Ownable {
    using Counters for Counters.Counter;

    /**
    Triggered everytime the public / private reserve ratio is updated
    @param rarityRangeId Rarity Range Id (indexed at 0)
    @param newPublicSupply The new public supply count
    @param newFirstPrivateId The first private token in the range
    */
    event PublicReserveUpdated(
        uint8 rarityRangeId,
        uint16 newPublicSupply,
        uint16 newFirstPrivateId
    );
    event MintPriceUpdated(uint8 rarityRangeId, uint256 newPrice);

    string public name;
    string public symbol;

    /**
    Rarity is linked to token id as such:
    ID 1 = Unique
    ID 2 to ID 11 = RarityRange 1 (10 cards)
    ID 12 to ID 111 =  RarityRange 2 (100 cards)
    ID 112 to ID 1111 =  RarityRange 3 (1000 cards)
    */

    // Max supply for each rarity type
    uint16 public constant RARITY_RANGE1_SUPPLY = 1;
    uint16 public constant RARITY_RANGE2_SUPPLY = 10;
    uint16 public constant RARITY_RANGE3_SUPPLY = 100;
    uint16 public constant RARITY_RANGE4_SUPPLY = 1000;

    // Initial Public supply for each rarity type,
    // can be updated after deploy
    uint16 public constant RARITY_RANGE1_PUBLIC_SUPPLY = 1;
    uint16 public constant RARITY_RANGE2_PUBLIC_SUPPLY = 10;
    uint16 public constant RARITY_RANGE3_PUBLIC_SUPPLY = 100;
    uint16 public constant RARITY_RANGE4_PUBLIC_SUPPLY = 1000;

    uint16 public royaltyPercentage = 1;
    address public royaltyReceiver;
    uint16 public maxTokenPerTx = 100;

    bytes32 public whitelistMerkleRoot;

    struct RarityRange {
        // First token ID in this range
        uint16 firstTokenId;
        // Last token ID in this range
        uint16 lastTokenId;
        // First private token ID in this range
        uint16 firstPrivateTokenId;
        // Price for public mint in this range
        uint256 mintPrice;
    }

    // RarityRanges by id
    mapping(uint8 => RarityRange) private rarityRangeById;

    // Public mint starting time in seconds
    uint256 public publicSaleStartTimestamp;

    // Mapping to keep track of the public token minted. By RarityRange id
    mapping(uint8 => Counters.Counter) private publicMintedCounter;

    // Mapping to keep track of the tokens from the private reserve that have already been withdrawn
    mapping(uint16 => bool) private privateTokenClaimed;

    // Mapping to keep track of whitelist addresses that have already been claimed
    mapping(address => bool) private whitelistClaimed;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * CONSTRUCTOR
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(string(abi.encodePacked(_uri,  _name, "/{id}"))) {
        name = _name;
        symbol = _symbol;

        uint16 rarityRange1FirstId = 1;
        uint16 rarityRange2FirstId = rarityRange1FirstId + RARITY_RANGE1_SUPPLY;
        uint16 rarityRange3FirstId = rarityRange2FirstId + RARITY_RANGE2_SUPPLY;
        uint16 rarityRange4FirstId = rarityRange3FirstId + RARITY_RANGE3_SUPPLY;

        // Initialize the 4 rarity ranges
        rarityRangeById[0] = RarityRange(
            rarityRange1FirstId,
            rarityRange2FirstId - 1,
            rarityRange1FirstId + RARITY_RANGE1_PUBLIC_SUPPLY,
            0.04 ether
        );
        rarityRangeById[1] = RarityRange(
            rarityRange2FirstId,
            rarityRange3FirstId - 1,
            rarityRange2FirstId + RARITY_RANGE2_PUBLIC_SUPPLY,
            0.03 ether
        );
        rarityRangeById[2] = RarityRange(
            rarityRange3FirstId,
            rarityRange4FirstId - 1,
            rarityRange3FirstId + RARITY_RANGE3_PUBLIC_SUPPLY,
            0.02 ether
        );
        rarityRangeById[3] = RarityRange(
            rarityRange4FirstId,
            rarityRange4FirstId + RARITY_RANGE4_SUPPLY - 1,
            rarityRange4FirstId + RARITY_RANGE4_PUBLIC_SUPPLY,
            0.01 ether
        );

        // The -1 are because the token are not yet minted and we increment
        // the counter after the minting is successful.
        publicMintedCounter[0] = Counters.Counter(rarityRange1FirstId - 1);
        publicMintedCounter[1] = Counters.Counter(rarityRange2FirstId - 1);
        publicMintedCounter[2] = Counters.Counter(rarityRange3FirstId - 1);
        publicMintedCounter[3] = Counters.Counter(rarityRange4FirstId - 1);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * MODIFIERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen(), "Public sale not opened.");
        _;
    }
    modifier whenPreSaleActive() {
        require(isPreSaleOpen(), "Presale not opened.");
        _;
    }
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * OpenZepplin Hooks
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * GETTERS / SETTERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isPublicSaleOpen() public view returns (bool) {
        return
            block.timestamp >= publicSaleStartTimestamp &&
            publicSaleStartTimestamp != 0;
    }

    function isPreSaleOpen() public view returns (bool) {
        return publicSaleStartTimestamp > 0 ?  block.timestamp  >= (publicSaleStartTimestamp - 86400) : false;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function publicMintPrice(uint8 rarityRangeId)
        public
        view
        returns (uint256)
    {
        require(
            rarityRangeId >= 0 && rarityRangeId <= 3,
            "Invalid RarityRange ID"
        );
        return rarityRangeById[rarityRangeId].mintPrice;
    }

    function getRarityRangeById(uint8 id)
        public
        view
        returns (RarityRange memory)
    {
        require(id >= 0 && id <= 3, "Invalid RarityRange ID");
        return rarityRangeById[id];
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Setters (ownable)
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function setPublicSaleTimestamp(uint256 _timestamp) external onlyOwner {
        publicSaleStartTimestamp = _timestamp;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setUri(string calldata _uri) external onlyOwner {
        _setURI(_uri);
    }

    function setPublicMintPrice(uint8 rarityRangeId, uint256 _mintPrice)
        public
        onlyOwner
    {
        require(_mintPrice > 0, "mintPrice must be greater than 0");
        require(
            rarityRangeId >= 0 && rarityRangeId <= 3,
            "Invalid RarityRange ID"
        );
        rarityRangeById[rarityRangeId].mintPrice = _mintPrice;

        emit MintPriceUpdated(rarityRangeId, _mintPrice);
    }

    function setMaxPerTx(uint8 maxPerTx) public onlyOwner {
        require(maxPerTx > 0, "maxPerTx must be greater than 0");
        maxTokenPerTx = maxPerTx;
    }

    /**
    Set a public reserve for a given rarity range
    @param rarityRangeId The rarity range ID (indexed at 0)
    @param newPublicSupply the new count of public supply tokens
    */
    function setPublicReserve(uint8 rarityRangeId, uint16 newPublicSupply)
        public
        onlyOwner
    {
        require(
            rarityRangeId >= 0 && rarityRangeId <= 3,
            "Invalid RarityRange ID"
        );
        RarityRange memory rarityRange = getRarityRangeById(rarityRangeId);
        uint16 newFirstPrivateId = rarityRange.firstTokenId + newPublicSupply;
        require(
            newFirstPrivateId != rarityRange.firstPrivateTokenId,
            "Public supply did not change."
        );

        // The +1 bellow for when a range is fully reserved for public sale
        require(
            newFirstPrivateId <= rarityRange.lastTokenId + 1,
            "Higher than max supply."
        );
        uint256 currentPublicSupply = totalSupplyForRarityRange(rarityRangeId);
        require(
            currentPublicSupply < newFirstPrivateId,
            "Public supply too low"
        );

        rarityRangeById[rarityRangeId].firstPrivateTokenId = newFirstPrivateId;

        emit PublicReserveUpdated(
            rarityRangeId,
            newPublicSupply,
            newFirstPrivateId
        );
    }

    /**
    Return the supply count for a given rarity range ID
    @param rarityRangeId The rarity range ID (indexed at 0)
    */
    function totalSupplyForRarityRange(uint8 rarityRangeId)
        public
        view
        returns (uint256)
    {
        return publicMintedCounter[rarityRangeId].current();
    }

    /**
    Return the total of publicly minted tokens
    @dev calculations are made here to save gas on minting
    */
    function totalSupply() public view returns (uint256) {
        RarityRange memory rarityRange1 = getRarityRangeById(0);
        RarityRange memory rarityRange2 = getRarityRangeById(1);
        RarityRange memory rarityRange3 = getRarityRangeById(2);
        RarityRange memory rarityRange4 = getRarityRangeById(3);
        uint256 current1 = publicMintedCounter[0].current() + 1;
        uint256 current2 = publicMintedCounter[1].current() + 1;
        uint256 current3 = publicMintedCounter[2].current() + 1;
        uint256 current4 = publicMintedCounter[3].current() + 1;

        return
            (current1 - rarityRange1.firstTokenId) +
            (current2 - rarityRange2.firstTokenId) +
            (current3 - rarityRange3.firstTokenId) +
            (current4 - rarityRange4.firstTokenId);
    }

    /**
    Check if a private token has been previously withdrawn
    @param id The token Id to be claimed
    */
    function checkClaimStatus(uint8 id) public view virtual returns (bool) {
        return privateTokenClaimed[id];
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * MINTING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
    Used to "extract" a privately held token and mint it to a given address
    @param rarityRangeId The rarity range ID (indexed at 0)
    @param id Id of the token
    @param receiver receipient address 
    */
    function claimTokenFromPrivateReserve(
        uint8 rarityRangeId,
        uint16 id,
        address receiver
    ) external onlyOwner returns (uint256) {
        // Do we have a valid RarityRange ID
        require(
            (rarityRangeId >= 0 && rarityRangeId <= 3),
            "Invalid RarityRange ID"
        );
    
        require(tx.origin == msg.sender, "Caller should not be a contract.");


        // Make sure the token has not been previously withdrawn
        require(privateTokenClaimed[id] == false, "Token previously withdrawn");

        RarityRange memory rarityRange = getRarityRangeById(rarityRangeId);

        require(
            (id >= rarityRange.firstPrivateTokenId &&
                id <= rarityRange.lastTokenId),
            "Token ID not eligeble for claim"
        );
        privateTokenClaimed[id] = true;
        _mint(receiver, id, 1, "");
        return id;
    }


    /**
    @param rarityRangeId The rarity range ID (indexed at 0)
    @param count how many tokens to mint at once
    */
    function _purchase(uint8 rarityRangeId, uint8 count)
        internal
        whenNotPaused
    {
        require(tx.origin == msg.sender, "Caller should not be a contract.");

        // Do we have a valid RarityRange ID
        require(
            rarityRangeId >= 0 && rarityRangeId <= 3,
            "Invalid RarityRange ID"
        );

        // Do we have enough supply to fullfil the order
        RarityRange memory currentRarityRange = getRarityRangeById(
            rarityRangeId
        );
        require(
            publicMintedCounter[rarityRangeId].current() + count <
                currentRarityRange.firstPrivateTokenId,
            "Not Enough Supply"
        );

        // Is count supperior than max per wallet
        require(count > 0 && count <= maxTokenPerTx, "Invalid count");

        // Check for payment
        require(
            count * currentRarityRange.mintPrice == msg.value || msg.sender == owner(),
            "Incorrect amount of ether sent"
        );

        // All good, we can start minting.
        for (uint16 i = 0; i < count; i++) {
            publicMintedCounter[rarityRangeId].increment();
            _mint(
                msg.sender,
                publicMintedCounter[rarityRangeId].current(),
                1,
                ""
            );
        }
    }

    /**
    Public mint is only for token assigned to the public reserve. Private token can not be minted directly via ethereum. 
    @param rarityRangeId The rarity range ID (indexed at 0)
    @param count how many tokens to mint at once
    */
    function mintPublicSale(uint8 rarityRangeId, uint8 count)
        external
        payable
        whenPublicSaleActive
        whenNotPaused
    {
        _purchase(rarityRangeId, count);
    }

    /**
    Presale mint.
    @param rarityRangeId The rarity range ID (indexed at 0)
    @param count how many tokens to mint at once
    @param merkleProof The merkle proof hashes 
    */
    function mintPreSale(
        uint8 rarityRangeId,
        uint8 count,
        bytes32[] calldata merkleProof
    ) external payable whenPreSaleActive whenNotPaused {
        // check is WL has already been claimed for this user
        require(
            whitelistClaimed[msg.sender] == false,
            "Address has already claim."
        );

        // merkle tree magic
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf),
            "Address is not whitelisted."
        );

        whitelistClaimed[msg.sender] == true;
        _purchase(rarityRangeId, count);
    }

    /**
    Founder Mint
    @param rarityRangeId The rarity range ID (indexed at 0)
    @param count how many tokens to mint at once
    */
    function founderMint(uint8 rarityRangeId, uint8 count)
        external
        payable
        whenNotPaused
        onlyOwner
    {
        _purchase(rarityRangeId, count);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Withdrawls
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function withdrawAmount(address payable recipient, uint256 amount)
        public
        onlyOwner
    {
        (bool succeed, bytes memory data) = recipient.call{value: amount}("");
        require(succeed, "Failed to withdraw Ether");
    }
}