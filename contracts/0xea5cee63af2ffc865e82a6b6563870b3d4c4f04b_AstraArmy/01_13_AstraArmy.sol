// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface IAstraMetadata {
    function tokenURI(uint256 tokenId, uint256 meta, bool isLocking, string memory genesisImageUrl) external view returns (string memory);
    function generate(uint256 seed) external view returns (uint256, uint256);
}

contract AstraArmy is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 constant MAX_ALPHA_SUPPLY       = 8869;         // Maximum limit of tokens for sale by ETH
    uint256 constant MAX_TOTAL_SUPPLY       = 696969;       // Maximum limit of tokens in the collection
    uint256 constant MAX_GIVEAWAY_REVERSE   = 69;           // Maximum limit of tokens for giving away purposes
    uint256 constant BATCH_PRESALE_LIMIT    = 2;            // Maximum limit of tokens per pre-sale transaction
    uint256 constant BATCH_BORN_LIMIT       = 3;            // Maximum limit of tokens per mint by token transaction
    uint256 constant PRESALE_PRICE          = 0.050 ether;  // Price for pre-sale
    uint256 constant PUBLICSALE_PRICE       = 0.069 ether;  // Price for minting
    uint256 constant CLAIM_TIMEOUT          = 14*24*3600;   // Claim expiration time after reserve
    uint256 constant STATS_MASK             = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000000000; // Mask for separate props and stats

    uint256 public MaxSalePerAddress        = 10;           // Maximum limit of tokens per address for minting
    uint256 public LockingTime              = 2*24*3600;    // Lock metadata after mint in seconds
    uint256 public TotalSupply;                             // Current total supply
    uint256 public GiveAwaySupply;                          // Total supply for giving away purposes
    uint256 public ResevedSupply;                            // Current total supply for sale by ETH

    bytes32 public PresaleMerkleRoot;                       // Merkle root hash to verify pre-sale address 
    address public PaymentAddress;                          // The address where payment will be received
    address public MetadataAddress;                         // The address of metadata's contract
    address public BattleAddress;                           // The address of game's contract

    bool public PreSaleActived;                             // Pre-sale is activated
    bool public PublicSaleActived;                          // Public sale is activated
    bool public BornActived;                                // Mint by token is activated

    mapping (uint256 => uint256)    MintTimestampMapping;   // Mapping minting time
    mapping (uint256 => uint256)    MetadataMapping;        // Mapping token's metadata
    mapping (uint256 => bool)       MetadataExisting;       // Mapping metadata's existence
    mapping (address => bool)       PresaleClaimedMapping;  // Mapping pre-sale claimed rewards
    mapping (address => uint256)    ReserveSaleMapping;     // Mapping reservations for public sale
    mapping (address => uint256)    ReserveTimestampMapping;// Mapping minting time
    mapping (address => uint256)    ClaimedSaleMapping;     // Mapping claims for public sale

    // Initialization function will initialize the initial values
    constructor(address metadataAddress, address paymentAddress) ERC721("Astra Chipmunks Army", "ACA") {
        PaymentAddress = paymentAddress;
        MetadataAddress = metadataAddress;
        
        // Generate first tokens for Alvxns & teams
        saveMetadata(1, 0x00000a000e001c001b0011001700000000000000000000000000000000000000);
        super._safeMint(paymentAddress, 1);
        TotalSupply++;
    }

    // Randomize metadata util it's unique
    function generateMetadata(uint256 tokenId, uint256 seed) internal returns (uint256) {
        (uint256 random, uint256 meta) = IAstraMetadata(MetadataAddress).generate(seed);
        if(MetadataExisting[meta])
            return generateMetadata(tokenId, random);
        else
            return meta;
    }

    // Get the tokenURI onchain
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return IAstraMetadata(MetadataAddress).tokenURI(tokenId, MetadataMapping[tokenId], MintTimestampMapping[tokenId] + LockingTime > block.timestamp, "");
    }

    // The function that reassigns a global variable named MetadataAddress (owner only)
    function setMetadataAddress(address metadataAddress) external onlyOwner {
        MetadataAddress = metadataAddress;
    }

    // The function that reassigns a global variable named BattleAddress (owner only)
    function setBattleAddress(address battleAddress) external onlyOwner {
        BattleAddress = battleAddress;
    }

    // The function that reassigns a global variable named PaymentAddress (owner only)
    function setPaymentAddress(address paymentAddress) external onlyOwner {
        PaymentAddress = paymentAddress;
    }

    // The function that reassigns a global variable named PresaleMerkleRoot (owner only)
    function setPresaleMerkleRoot(bytes32 presaleMerkleRoot) external onlyOwner {
        PresaleMerkleRoot = presaleMerkleRoot;
    }

    // The function that reassigns a global variable named PreSaleActived (owner only)
    function setPresaleActived(bool preSaleActived) external onlyOwner {
        PreSaleActived = preSaleActived;
    }

    // The function that reassigns a global variable named BornActived (owner only)
    function setBornActived(bool bornActived) external onlyOwner {
        BornActived = bornActived;
    }

    // The function that reassigns a global variable named PublicSaleActived (owner only)
    function setPublicSaleActived(bool publicSaleActived) external onlyOwner {
        PublicSaleActived = publicSaleActived;
    }

    // The function that reassigns a global variable named LockingTime (owner only)
    function setLockingTime(uint256 lockingTime) external onlyOwner {
        LockingTime = lockingTime;
    }

    // The function that reassigns a global variable named MaxSalePerAddress (owner only)
    function setMaxSalePerAddress(uint256 maxSalePerAddress) external onlyOwner {
        MaxSalePerAddress = maxSalePerAddress;
    }

    // Pre-sale whitelist check function
    function checkPresaleProof(address buyer, bool hasFreeMint, bytes32[] memory merkleProof) public view returns (bool) {
        // Calculate the hash of leaf
        bytes32 leafHash = keccak256(abi.encode(buyer, hasFreeMint));
        // Verify leaf using openzeppelin library
        return MerkleProof.verify(merkleProof, PresaleMerkleRoot, leafHash);
    }

    // Give away minting function (owner only)
    function mintGiveAway(uint256 numberOfTokens, address toAddress) external onlyOwner {
        // Calculate current index for minting
        uint256 i = TotalSupply + 1;
        TotalSupply += numberOfTokens;
        GiveAwaySupply += numberOfTokens;

        // Exceeded the maximum total give away supply
        require(0 < numberOfTokens && GiveAwaySupply <= MAX_GIVEAWAY_REVERSE && TotalSupply <= MAX_ALPHA_SUPPLY, 'Exceed total supply!');

        for (;i <= TotalSupply; i++) {
            // To the sun
            _safeMint(toAddress, i);
        }
    }

    // Presale minting function
    function mintPreSale(uint256 numberOfTokens, bool hasFreeMint, bytes32[] memory merkleProof) external payable {
        // Calculate current index for minting
        uint256 i = TotalSupply + 1;
        TotalSupply += numberOfTokens.add(hasFreeMint ? 1 : 0);

        // The sender must be a wallet
        require(msg.sender == tx.origin, 'Not a wallet!');
        // Pre-sale is not open yet
        require(PreSaleActived, 'Not open yet!');
        // Exceeded the maximum total supply
        require(TotalSupply <= MAX_ALPHA_SUPPLY, 'Exceed total supply!');
        // Exceeded the limit for each pre-sale
        require(0 < numberOfTokens && numberOfTokens <= BATCH_PRESALE_LIMIT, 'Exceed limitation!');
        // You are not on the pre-sale whitelist
        require(this.checkPresaleProof(msg.sender, hasFreeMint, merkleProof), 'Not on the whitelist!');
        // Your promotion has been used
        require(!PresaleClaimedMapping[msg.sender], 'Promotion is over!');
        // Your ETH amount is insufficient
        require(PRESALE_PRICE.mul(numberOfTokens) <= msg.value, 'Insufficient funds!');

        // Mark the address that has used the promotion
        PresaleClaimedMapping[msg.sender] = true;

        // Make the payment to diffrence wallet
        payable(PaymentAddress).transfer(msg.value);
        
        for (; i <= TotalSupply; i++) {
            // To the moon
            _safeMint(msg.sender, i);
        }
    }

    // Getting the reserve status
    function reserveStatus(address addressOf) external view returns (uint256, uint256) {
        uint256 claimable = ReserveSaleMapping[addressOf] - ClaimedSaleMapping[addressOf];
        uint256 reservable = MaxSalePerAddress > ReserveSaleMapping[addressOf] ? MaxSalePerAddress - ReserveSaleMapping[addressOf] : 0;
        return (claimable, reservable);
    }

    // Public sale by ETH minting function
    function reserve(uint256 numberOfTokens) external payable {
        // Register for a ticket
        ReserveSaleMapping[msg.sender] = ReserveSaleMapping[msg.sender].add(numberOfTokens);
        ResevedSupply = ResevedSupply.add(numberOfTokens);
        ReserveTimestampMapping[msg.sender] = block.timestamp;

        // The sender must be a wallet
        require(msg.sender == tx.origin, 'Not a wallet!');
        // Public sale is not open yet
        require(PublicSaleActived, 'Not open yet!');
        // Exceeded the maximum total supply
        require(TotalSupply + ResevedSupply <= MAX_ALPHA_SUPPLY, 'Exceed total supply!');
        // Your ETH amount is insufficient
        require(0 < numberOfTokens && PUBLICSALE_PRICE.mul(numberOfTokens) <= msg.value, 'Insufficient funds!');
        // Exceeded the limit per address
        require(numberOfTokens <= MaxSalePerAddress && ReserveSaleMapping[msg.sender] <= MaxSalePerAddress, 'Exceed address limitation!');
        // Make the payment to diffrence wallet
        payable(PaymentAddress).transfer(msg.value);
    }

    // Public sale by ETH minting function
    function claim() external payable {
        // The sender must be a wallet
        require(msg.sender == tx.origin, 'Not a wallet!');
        // Reservetions must come first
        require(ReserveSaleMapping[msg.sender] > ClaimedSaleMapping[msg.sender], 'Already claimed!');
        // Expired claims
        require(ReserveTimestampMapping[msg.sender] + CLAIM_TIMEOUT > block.timestamp, 'Expired claims!');

        // Calculate current index for minting
        uint256 i = TotalSupply + 1;
        uint256 numberOfTokens = ReserveSaleMapping[msg.sender] - ClaimedSaleMapping[msg.sender];
        ResevedSupply -= numberOfTokens;
        TotalSupply += numberOfTokens;
        // Reassign used tickets
        ClaimedSaleMapping[msg.sender] = ReserveSaleMapping[msg.sender];
        delete(ReserveTimestampMapping[msg.sender]);


        for (; i <= TotalSupply; i++) {
            // To the moon
            _safeMint(msg.sender, i);
        }
    }

    // Public sale by token minting function
    function born(address toAddress, uint256 numberOfTokens) external {
        // Calculate current index for minting
        uint256 i = TotalSupply + 1;
        TotalSupply = TotalSupply.add(numberOfTokens);

        // Born is not open yet
        require(BornActived, 'Not open yet!');
        // Exceeded the limit for each mint egg
        require(0 < numberOfTokens && numberOfTokens <= BATCH_BORN_LIMIT, 'Exceed batch limitation!');
        // Exceeded the maximum total supply
        require(TotalSupply <= MAX_TOTAL_SUPPLY, 'Exceed total supply!');
        //  The sender must be game contract
        require(msg.sender == BattleAddress, 'Not authorized!');

        for (; i <= TotalSupply; i++) {
            // To the moon
            _safeMint(toAddress, i);
        }
    }

    // Setting the stats of the token
    function setStats(uint256 tokenId, uint256 meta) external {
        // The sender must be game contract
        require(msg.sender == BattleAddress, 'Not authorized!');
        // Put on a mask to make sure nothing can change the art, just stats
        MetadataMapping[tokenId] = (MetadataMapping[tokenId] & ~STATS_MASK) | (meta & STATS_MASK);
    }

    // Save the metadata information
    function saveMetadata(uint256 tokenId, uint256 meta) internal {
        MintTimestampMapping[tokenId] = block.timestamp;
        MetadataMapping[tokenId] = meta;
        MetadataExisting[meta] = true;
    }

    // Customize safeMint function
    function _safeMint(address to, uint256 tokenId) internal virtual override {
        // Generate and save metadata
        saveMetadata(tokenId, generateMetadata(tokenId, tokenId));

        // Call the function super
        super._safeMint(to, tokenId);
    }

    // Customize beforeTokenTransfer function
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        // Call the function super
        super._beforeTokenTransfer(from, to, tokenId);
        // Lock the tranfer of LockingTime seconds, except for the alpha generation
        require(tokenId <= MAX_ALPHA_SUPPLY || MintTimestampMapping[tokenId] + LockingTime < block.timestamp, 'Not transferable!');
    }

    // Customize totalSupply function
    function totalSupply() external virtual returns (uint256) {
        return TotalSupply;
    }
}