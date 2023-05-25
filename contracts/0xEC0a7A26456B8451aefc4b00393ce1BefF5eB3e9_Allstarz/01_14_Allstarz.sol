//
//
//    ____      .---.     .---.       .-'''-. ,---------.    ____    .-------.      ____..--'
//  .'  __ `.   | ,_|     | ,_|      / _     \\          \ .'  __ `. |  _ _   \    |        |
// /   '  \  \,-./  )   ,-./  )     (`' )/`--' `--.  ,---'/   '  \  \| ( ' )  |    |   .-'  '
// |___|  /  |\  '_ '`) \  '_ '`)  (_ o _).       |   \   |___|  /  ||(_ o _) /    |.-'.'   /
//    _.-`   | > (_)  )  > (_)  )   (_,_). '.     :_ _:      _.-`   || (_,_).' __     /   _/
// .'   _    |(  .  .-' (  .  .-'  .---.  \  :    (_I_)   .'   _    ||  |\ \  |  |  .'._( )_
// |  _( )_  | `-'`-'|___`-'`-'|___\    `-'  |   (_(=)_)  |  _( )_  ||  | \ `'   /.'  (_'o._)
// \ (_ o _) /  |        \|        \\       /     (_I_)   \ (_ o _) /|  |  \    / |    (_,_)|
//  '.(_,_).'   `--------``--------` `-...-'      '---'    '.(_,_).' ''-'   `'-'  |_________|
//
//
//                                         /\
//                                   .--._/  \_.--.
//                                    `)        (`
//                                 _.-'          '-._
//                                '-.              .-'
//                                   `)          ('
//                                   /.-"-.  .-"-.\
//                                   `     \/
//
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO: Set up contract optimization

import "hardhat/console.sol";

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Allstarz is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // Variables
    // ---------------------------------------------------------------

    uint256 public immutable collectionSize;
    uint256 public immutable reservedGifts;
    uint256 public immutable maxPerWallet;
    uint256 public immutable maxPerTx;

    uint256 public numFreeMint;
    uint256 public numGifts;
    bytes32 public freeMintMerkleRoot;

    bool public isFreeMintActive = false;
    bool public isMintActive = false;

    uint256 private reservedFreeMint = 1000;
    uint256 private mintPrice = 0.03 ether;
    string private _baseTokenURI;

    // Helper functions
    // ---------------------------------------------------------------
    function pack(uint32 a, uint32 b) private pure returns (uint64) {
        return (uint64(a) << 32) | uint64(b);
    }

    function unpack(uint64 c) private pure returns (uint32 a, uint32 b) {
        a = uint32(c >> 32);
        b = uint32(c);
    }

    // Modifiers
    // ---------------------------------------------------------------

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier freeMintActive() {
        require(isFreeMintActive, "Free mint is not open.");
        _;
    }

    modifier mintActive() {
        require(isMintActive, "Mint is not open.");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in free mint allowlist."
        );
        _;
    }

    modifier freeMintLeft() {
        require(
            numFreeMint + 1 <= reservedFreeMint,
            "There are no free mint tokens left."
        );
        _;
    }

    modifier giftsLeft(uint256 quantity) {
        require(
            numGifts + quantity <= reservedGifts,
            "There are not enough gift tokens."
        );
        _;
    }

    modifier mintLeft(uint256 quantity) {
        require(
            totalSupply() + quantity <=
                collectionSize -
                    (reservedGifts - numGifts) -
                    (reservedFreeMint - numFreeMint),
            "There are no public mint tokens left."
        );
        _;
    }

    modifier hasNotClaimedFreeMint() {
        uint32 senderFreeMints;
        uint32 senderGifts;
        (senderFreeMints, senderGifts) = unpack(_getAux(msg.sender));
        require(
            senderFreeMints == 0,
            "This wallet has already claimed from free mint."
        );
        _;
    }

    modifier lessThanMaxPerWallet(uint256 quantity) {
        uint32 senderFreeMints;
        uint32 senderGifts;
        (senderFreeMints, senderGifts) = unpack(_getAux(msg.sender));
        require(
            _numberMinted(msg.sender) + quantity <=
                maxPerWallet + senderFreeMints + senderGifts,
            "The maximum number of minted tokens per wallet is 10."
        );
        _;
    }

    modifier lessThanMaxPerTx(uint256 quantity) {
        require(
            quantity <= maxPerTx,
            "The maximum number of minted tokens per transaction is 10."
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(price * quantity == msg.value, "Incorrect amount of ETH sent.");
        _;
    }

    // Constructor
    // ---------------------------------------------------------------

    constructor(
        uint256 collectionSize_,
        uint256 reservedGifts_,
        uint256 maxPerWallet_,
        uint256 maxPerTx_
    ) ERC721A("Allstarz", "ALLSTAR") {
        collectionSize = collectionSize_;
        reservedGifts = reservedGifts_;
        maxPerWallet = maxPerWallet_;
        maxPerTx = maxPerTx_;
    }

    // Public minting functions
    // ---------------------------------------------------------------

    // Free mint from allowlist
    function freeMint(bytes32[] calldata merkleProof)
        external
        nonReentrant
        callerIsUser
        freeMintActive
        isValidMerkleProof(merkleProof, freeMintMerkleRoot)
        hasNotClaimedFreeMint
        freeMintLeft
    {
        uint32 senderFreeMints;
        uint32 senderGifts;
        numFreeMint += 1;
        (senderFreeMints, senderGifts) = unpack(_getAux(msg.sender));
        senderFreeMints++;
        _setAux(msg.sender, pack(senderFreeMints, senderGifts));
        _safeMint(msg.sender, 1);
    }

    // Public mint
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
        mintActive
        lessThanMaxPerWallet(quantity)
        lessThanMaxPerTx(quantity)
        isCorrectPayment(mintPrice, quantity)
        mintLeft(quantity)
    {
        _safeMint(msg.sender, quantity);
    }

    // Gift Allstarz
    function gift(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        giftsLeft(addresses.length)
    {
        uint256 numToGift = addresses.length;
        uint32 senderFreeMints;
        uint32 senderGifts;
        numGifts += numToGift;
        for (uint256 i = 0; i < numToGift; i++) {
            (senderFreeMints, senderGifts) = unpack(_getAux(addresses[i]));
            senderGifts++;
            _setAux(addresses[i], pack(senderFreeMints, senderGifts));
            _safeMint(addresses[i], 1);
        }
    }

    // Public read-only functions
    // ---------------------------------------------------------------

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function getReservedFreeMint() public view returns (uint256) {
        return reservedFreeMint;
    }

    function getFreeMintCount(address owner) public view returns (uint32) {
        uint32 ownerFreeMints;
        uint32 ownerGifts;
        (ownerFreeMints, ownerGifts) = unpack(_getAux(owner));
        return ownerFreeMints;
    }

    function getGiftCount(address owner) public view returns (uint32) {
        uint32 ownerFreeMints;
        uint32 ownerGifts;
        (ownerFreeMints, ownerGifts) = unpack(_getAux(owner));
        return ownerGifts;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    // Internal read-only functions
    // ---------------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Owner only administration functions
    // ---------------------------------------------------------------

    function setFreeMintActive(bool _isFreeMintActive) external onlyOwner {
        isFreeMintActive = _isFreeMintActive;
    }

    function setMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setReservedFreeMint(uint256 _reservedFreeMint) external onlyOwner {
        require(
            numFreeMint <= _reservedFreeMint,
            "Cannot set reserved free mint to more than the current number of free mints."
        );
        reservedFreeMint = _reservedFreeMint;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setFreeMintMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        freeMintMerkleRoot = merkleRoot;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}