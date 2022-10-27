// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "erc721a/contracts/ERC721A.sol";
import "./EIP712Whitelisting.sol";
import "./simple_splitter.sol";

contract StarBirdies is Ownable, ERC721A, EIP712Whitelisting, SimpleSplitter, VRFConsumerBaseV2{
    using Address for address;

    struct revenueShareParams {
        address payable[] payees;
        uint256[] shares;
    }

    VRFCoordinatorV2Interface immutable COORDINATOR;

    uint256 public immutable collectionSize;
    
    
    uint256 public ORDERED_PROVENANCE_HASH;
    uint256 public seed;

    uint256 public reservedAirdrops;
    uint256 public airdropped;
    uint256 public publicPrice;
    uint256 public privatePrice;
    uint256 public privateMintPerWallet;
    uint256 public publicMintPerTransaction;

    string private _baseTokenURI;

    mapping(address => uint256) private _airdropAllowed;

    event RandomSeedRequestFulfilled(uint256 timestamp, uint256 seed);

    constructor(
        uint256 collectionSize_,
        uint256 publicMintPerTransaction_,
        uint256 privateMintPerWallet_,
        uint256 reservedAirdrops_,
        address vrfCoordinator,
        revenueShareParams memory revenueShare
    ) ERC721A("Star Birdies", "SBD")
      SimpleSplitter(revenueShare.payees, revenueShare.shares)
      VRFConsumerBaseV2(vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        collectionSize = collectionSize_;
        publicMintPerTransaction = publicMintPerTransaction_;
        privateMintPerWallet = privateMintPerWallet_;
        reservedAirdrops = reservedAirdrops_;
        _airdropAllowed[msg.sender] = 0;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /* External Functions */

    function publicMint(uint256 amount) external payable callerIsUser {
        uint256 price = amount * publicPrice;
        require(price > 0, "Public sale has not begun yet");
        require(amount <= publicMintPerTransaction, "Mint exceed transaction limits");
        require(_totalMinted() + airdropOffset() + amount <= collectionSize, "Reached max supply");
        require(msg.value >= price, "Insufficient funds.");
        _safeMint(msg.sender, amount);
        refundIfOver(price);
    }

    function privateMint(uint64 amount, bytes calldata signature)
        external
        payable
        callerIsUser
        requiresWhitelist(signature)
    {
        uint256 price = amount * privatePrice;
        require(price > 0, "Private sale has not begun yet");
        require(_getAux(msg.sender) + amount <= privateMintPerWallet, "Mint limit per wallet exceeded.");
        require(_totalMinted() + airdropOffset() + amount <= collectionSize, "Reached max supply");
        require(msg.value >= price, "Insufficient funds.");
        _setAux(msg.sender, _getAux(msg.sender) + amount);
        _safeMint(msg.sender, amount);
        refundIfOver(price);
    }

    function airdrop(address[] memory addresses, uint256 amount) external callerIsUser
    {
        uint256 num_dropped = addresses.length * amount;
        require(_totalMinted() + num_dropped <= collectionSize, "Exceed max supply limit.");
        airdropped += num_dropped;
        if(msg.sender != owner()){
            require(_airdropAllowed[msg.sender] >= num_dropped, "Address cannot drop that much.");
            _airdropAllowed[msg.sender] = _airdropAllowed[msg.sender] - num_dropped;
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amount);
        }
    }

    function requestSeed(uint64 subId, bytes32 keyHash) external onlyOwner {
        COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            3,
            100000,
            1
        );
    }

    function setSeed(uint256 seed_) external onlyOwner{
        seed = seed_;
    }

    function setPrivateMintPerWallet(uint256 privateMintPerWallet_) external onlyOwner{
        privateMintPerWallet = privateMintPerWallet_;
    }

    function setPublicMintPerTransaction(uint256 publicMintPerTransaction_) external onlyOwner{
        publicMintPerTransaction = publicMintPerTransaction_;
    }

    function setAirdropRole(address addr, uint256 allowedAmount) external onlyOwner {
        _airdropAllowed[addr] = allowedAmount;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrivatePrice(uint256 privatePrice_) external onlyOwner {
        privatePrice = privatePrice_;
    }

    function setPublicPrice(uint256 publicPrice_) external onlyOwner {
        publicPrice = publicPrice_;
    }

    function setReservedAirdrops(uint256 reservedAirdrops_) external onlyOwner {
        reservedAirdrops = reservedAirdrops_;
    }

    function setOrderedProvenanceHash(uint256 hash_) external onlyOwner {
        ORDERED_PROVENANCE_HASH = hash_;
    }

    /* Public Functions */

    function getMetadataId(uint256 tokenId) public view returns (string memory){
        if (seed == 0) return "default";

        // Post reveal metadata, shuffle according to seed
        uint256[] memory metadata = new uint256[](collectionSize);

        for (uint256 i = 0; i < collectionSize; i += 1) {
            metadata[i] = i + 1;
        }

        for (uint256 i = 0; i < collectionSize; i += 1) {
            uint256 j = uint256(keccak256(abi.encode(seed, i))) % collectionSize;
            (metadata[i], metadata[j]) = (metadata[j], metadata[i]);
        }

        return Strings.toString(metadata[tokenId - 1]);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, getMetadataId(tokenId))) : '';
    }

    /* Internal Functions */

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        seed = randomWords[0];
        emit RandomSeedRequestFulfilled(block.timestamp, seed);
    }

    function airdropOffset() internal view returns (uint256) {
        if (airdropped >= reservedAirdrops) return 0;
        else return (reservedAirdrops - airdropped);
    }

    /* Private Functions */

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}