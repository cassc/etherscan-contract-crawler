// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "erc721a/contracts/ERC721A.sol";
import "./EIP712Whitelisting.sol";

contract SENSHI is Ownable, ERC721A, EIP712Whitelisting, PaymentSplitter, VRFConsumerBaseV2{
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 public ORDERED_PROVENANCE_HASH;

    VRFCoordinatorV2Interface COORDINATOR;
    uint256 public seed;

    uint256 public immutable collectionSize;

    uint256 public reservedAirdrops = 100;
    uint256 public maxPublicSaleAmount = 455;
    uint256 public airdropped;
    uint256 public mintedPublic;
    uint256 public publicPrice;
    uint256 public privatePrice;

    uint8 public privateMintPerWallet = 2;
    uint8 public publicMintPerWallet = 3;

    string private _baseTokenURI;

    struct revenueShareParams {
        address[] payees;
        uint256[] shares;
    }

    event RandomSeedRequestFulfilled(uint256 timestamp, uint256 seed);

    constructor(
        uint256 collectionSize_,
        address vrfCoordinator,
        revenueShareParams memory revenueShare
    ) ERC721A("SENSHI", "SENSHI")
      PaymentSplitter(revenueShare.payees, revenueShare.shares)
      VRFConsumerBaseV2(vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        collectionSize = collectionSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function privateMint(uint8 amount, bytes calldata signature) external payable callerIsUser requiresWhitelist(signature)
    {
        uint256 price = amount.mul(privatePrice);
        require(price > 0, "private sale has not begun yet");
        uint64 aux = _getAux(msg.sender);
        uint8 currentlyPrivateMinted = uint8(aux >> 8);
        require(currentlyPrivateMinted + amount <= privateMintPerWallet, "Private mint per wallet exceeded");
        require(_totalMinted() + reservedAirdrops + amount <= collectionSize, "reached max supply");
        require(msg.value >= price, "Insufficient funds.");
        _setAux(msg.sender, (aux & 0xFFFFFFFFFFFF00FF) | (uint16(currentlyPrivateMinted + amount) << 8));
        _safeMint(msg.sender, amount);
        refundIfOver(price);
    }

    function publicMint(uint8 amount) external payable callerIsUser {
        uint256 price = amount.mul(publicPrice);
        require(price > 0, "public sale has not begun yet");
        require(mintedPublic + amount <= maxPublicSaleAmount, "Reached Public sale limit");
        uint64 aux = _getAux(msg.sender);
        uint8 currentlyPublicMinted = uint8(aux);
        require(currentlyPublicMinted + amount <= publicMintPerWallet, "Public mint per wallet exceeded");
        require(_totalMinted() + reservedAirdrops + amount <= collectionSize, "reached max supply");
        require(msg.value >= price, "Insufficient funds.");
        mintedPublic += amount;
        _setAux(msg.sender, (aux & 0xFFFFFFFFFFFFFF00) | (currentlyPublicMinted + amount));
        _safeMint(msg.sender, amount);
        refundIfOver(price);
    }


    function airdrop(address[] memory addresses, uint256 amount) external onlyOwner
    {
        require(addresses.length.mul(amount) + airdropped <= reservedAirdrops, "Exceeded Airdrop Limit");
        require(_totalMinted().add(addresses.length.mul(amount)) <= collectionSize, "Exceed max supply limit.");
        airdropped = airdropped + addresses.length.mul(amount);
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amount);
        }
    }

    function burnRemainingUnmintedTokens(uint256 maxAmountBurned) external onlyOwner
    {
        require(collectionSize != _totalMinted());
        uint256 from = _totalMinted();
        uint256 numberMintedAndBurned = collectionSize - _totalMinted() >= maxAmountBurned ? maxAmountBurned : collectionSize - _totalMinted();
        _safeMint(address(msg.sender), numberMintedAndBurned);
        for(uint256 i = from; i < from + numberMintedAndBurned; i++){
            _burn(i + 1);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

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

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override{
        seed = randomWords[0];
        emit RandomSeedRequestFulfilled(block.timestamp, seed);
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

    function setOrderedProvenanceHash(uint256 hash) external onlyOwner {
        ORDERED_PROVENANCE_HASH = hash;
    }

    function withdraw() external callerIsUser {
        this.release(payable(msg.sender));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}