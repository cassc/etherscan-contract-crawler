// SPDX-License-Identifier: MIT
/***
 *                                                                 .';:c:,.
 *                   ;0NNNNNNX.  lNNNNNNK;       .XNNNNN.     .:d0XWWWWWWWWXOo'
 *                 lXWWWWWWWWO   XWWWWWWWWO.     :WWWWWK    ;0WWWWWWWWWWWWWWWWWK,
 *              .dNWWWWWWWWWWc  ,WWWWWWWWWWNo    kWWWWWo  .0WWWWWNkc,...;oXWWXxc.
 *            ,kWWWWWWXWWWWWW.  dWWWWWXNWWWWWX; .NWWWWW.  KWWWWW0.         ;.
 *          :KWWWWWNd.lWWWWWO   XWWWWW:.xWWWWWWOdWWWWW0  cWWWWWW.
 *        lXWWWWWXl.  0WWWWW:  ,WWWWWN   '0WWWWWWWWWWWl  oWWWWWW;         :,
 *     .dNWWWWW0;    'WWWWWN.  xWWWWWx     :XWWWWWWWWW.  .NWWWWWWkc,'';ckNWWNOc.
 *   'kWWWWWWx'      oWWWWWk   NWWWWW,       oWWWWWWW0    '0WWWWWWWWWWWWWWWWWO;
 * .d000000o.        k00000;  ,00000k         .x00000:      .lkKNWWWWWWNKko;.
 *                                                               .,;;'.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "erc721a/contracts/ERC721A.sol";
import "./EIP712Whitelisting.sol";

contract ANC is Ownable, ERC721A, EIP712Whitelisting, PaymentSplitter, VRFConsumerBaseV2{
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint64;

    struct revenueShareParams {
        address[] payees;
        uint256[] shares;
    }

    VRFCoordinatorV2Interface immutable COORDINATOR;

    uint256 public immutable collectionSize;
    uint256 public immutable publicMintPerTransaction;
    uint256 public immutable reservedAirdrops;

    uint256 public ORDERED_PROVENANCE_HASH;
    uint256 public seed;

    uint256 public airdropped;
    uint256 public publicPrice;
    uint256 public privatePrice;
    uint256 public privateMintPerWallet;

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
    ) ERC721A("Ape Night Club", "ANC")
      PaymentSplitter(revenueShare.payees, revenueShare.shares)
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
        uint256 price = amount.mul(publicPrice);
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
        uint256 price = amount.mul(privatePrice);
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
        require(_totalMinted().add(addresses.length.mul(amount)) <= collectionSize, "Exceed max supply limit.");
        airdropped += addresses.length.mul(amount);
        if(msg.sender != owner()){
            require(_airdropAllowed[msg.sender] >= addresses.length.mul(amount), "Address cannot drop that much.");
            _airdropAllowed[msg.sender] = _airdropAllowed[msg.sender] - addresses.length.mul(amount);
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

    function setOrderedProvenanceHash(uint256 hash) external onlyOwner {
        ORDERED_PROVENANCE_HASH = hash;
    }

    function withdraw() external callerIsUser {
        this.release(payable(msg.sender));
    }

    function getOwnedIDs(address address_) external view returns(uint256[] memory){
        uint256 numOwned = balanceOf(address_);
        uint256[] memory ownedIDs = new uint256[](numOwned);
        uint256 index = 0;
        address owner = address(0);
        // not using ERC721A ownerOf function because it would be very inefficient
        for (uint256 id = _startTokenId(); id < _currentIndex; id++) {
            TokenOwnership memory ownership = _ownerships[id];
            if (!ownership.burned && ownership.addr != address(0)) {
                owner = ownership.addr;
            }
            if(!ownership.burned && owner == address_){
                ownedIDs[index] = id;
                index += 1;
                if (index == numOwned) break;
            }
        }
        return ownedIDs;
    }

    /* Public Functions */

    function getMetadataId(uint256 tokenId) public view returns (string memory){
        if (seed == 0) return "default";

        // Post reveal metadata, shuffle according to seed
        uint256[] memory metadata = new uint256[](collectionSize);

        for (uint256 i = 0; i < collectionSize; i += 1) {
            metadata[i] = i;
        }

        for (uint256 i = 0; i < collectionSize; i += 1) {
            uint256 j = uint256(keccak256(abi.encode(seed, i))) % collectionSize;
            (metadata[i], metadata[j]) = (metadata[j], metadata[i]);
        }

        return Strings.toString(metadata[tokenId]);
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
}