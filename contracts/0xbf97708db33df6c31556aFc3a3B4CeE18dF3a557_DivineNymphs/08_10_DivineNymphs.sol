//  ▓█████▄  ██▓ ██▒   █▓ ██▓ ███▄    █ ▓█████     ███▄    █▓██   ██▓ ███▄ ▄███▓ ██▓███   ██░ ██   ██████ 
// ▒██▀ ██▌▓██▒▓██░   █▒▓██▒ ██ ▀█   █ ▓█   ▀     ██ ▀█   █ ▒██  ██▒▓██▒▀█▀ ██▒▓██░  ██▒▓██░ ██▒▒██    ▒ 
// ░██   █▌▒██▒ ▓██  █▒░▒██▒▓██  ▀█ ██▒▒███      ▓██  ▀█ ██▒ ▒██ ██░▓██    ▓██░▓██░ ██▓▒▒██▀▀██░░ ▓██▄   
// ░▓█▄   ▌░██░  ▒██ █░░░██░▓██▒  ▐▌██▒▒▓█  ▄    ▓██▒  ▐▌██▒ ░ ▐██▓░▒██    ▒██ ▒██▄█▓▒ ▒░▓█ ░██   ▒   ██▒
// ░▒████▓ ░██░   ▒▀█░  ░██░▒██░   ▓██░░▒████▒   ▒██░   ▓██░ ░ ██▒▓░▒██▒   ░██▒▒██▒ ░  ░░▓█▒░██▓▒██████▒▒
//  ▒▒▓  ▒ ░▓     ░ ▐░  ░▓  ░ ▒░   ▒ ▒ ░░ ▒░ ░   ░ ▒░   ▒ ▒   ██▒▒▒ ░ ▒░   ░  ░▒▓▒░ ░  ░ ▒ ░░▒░▒▒ ▒▓▒ ▒ ░
//  ░ ▒  ▒  ▒ ░   ░ ░░   ▒ ░░ ░░   ░ ▒░ ░ ░  ░   ░ ░░   ░ ▒░▓██ ░▒░ ░  ░      ░░▒ ░      ▒ ░▒░ ░░ ░▒  ░ ░
//  ░ ░  ░  ▒ ░     ░░   ▒ ░   ░   ░ ░    ░         ░   ░ ░ ▒ ▒ ░░  ░      ░   ░░        ░  ░░ ░░  ░  ░  
//    ░     ░        ░   ░           ░    ░  ░            ░ ░ ░            ░             ░  ░  ░      ░  
//  ░               ░                                       ░ ░                                           

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "closedsea/src/OperatorFilterer.sol";

contract DivineNymphs is ERC721A, OperatorFilterer, ReentrancyGuard, Ownable {
    
    // Variables
    // ---------------------------------------------------------------

    uint256 public immutable reservedGifts;
    uint256 public immutable maxPerWallet;
    uint256 public immutable maxPerTx;

    uint256 public numGifts;
    uint256 public numFreeMintNymphs;
    uint256 public numFreeMintFriends;
    bytes32 public merkleRootNymphs;
    bytes32 public merkleRootFriends;

    bool public operatorFilteringEnabled;
    bool public isFreeMintActiveNymphs = false;
    bool public isFreeMintActiveFriends = false;
    bool public isMintActive = false;

    uint256 private collectionSize;
    uint256 private reservedFreeMintNymphs;
    uint256 private reservedFreeMintFriends;
    uint256 private mintPrice = 0.05 ether;
    address private devAddress = 0xe5A7a206E9a8769f90ca792EbB68E9268231F717;
    string private _baseTokenURI;

    // Helper functions
    // ---------------------------------------------------------------
    
    function pack(uint16 a, uint16 b, uint16 c) internal pure returns (uint64) {
        return uint64(a) << 32 | uint64(b) << 16 | uint64(c);
    }

    function unpack(uint64 a) internal pure returns (uint16, uint16, uint16) {
        return (uint16(a >> 32), uint16(a >> 16), uint16(a));
    }

    // Modifiers
    // ---------------------------------------------------------------

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier freeMintActiveNymphs() {
        require(isFreeMintActiveNymphs, "Free mint for Divine Nymphs holders is not open.");
        _;
    }
    
    modifier freeMintActiveFriends() {
        require(isFreeMintActiveFriends, "Free mint for friend projects is not open.");
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
            "Address does not exist in this allowlist."
        );
        _;
    }

    modifier freeMintLeftNymphs() {
        require(
            numFreeMintNymphs + 1 <= reservedFreeMintNymphs,
            "There are no free mint tokens left for Divine Nymphs holders."
        );
        _;
    }
    
    modifier freeMintLeftFriends() {
        require(
            numFreeMintFriends + 1 <= reservedFreeMintFriends,
            "There are no free mint tokens left for friend projects."
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
                collectionSize
                    - (reservedGifts - numGifts)
                    - (reservedFreeMintNymphs - numFreeMintNymphs)
                    - (reservedFreeMintFriends - numFreeMintFriends),
            "There are no public mint tokens left."
        );
        _;
    }

    modifier hasNotClaimedFreeMintNymphs() {
        (uint16 senderFreeMintsNymphs, uint16 senderFreeMintsFriends, uint16 senderGifts) = unpack(_getAux(msg.sender));
        require(
            senderFreeMintsNymphs == 0,
            "This wallet has already claimed from Divine Nymphs holders free mint."
        );
        _;
    }
    
    modifier hasNotClaimedFreeMintFriends() {
        (uint16 senderFreeMintsNymphs, uint16 senderFreeMintsFriends, uint16 senderGifts) = unpack(_getAux(msg.sender));
        require(
            senderFreeMintsFriends == 0,
            "This wallet has already claimed from project friends free mint."
        );
        _;
    }

    modifier lessThanMaxPerWallet(uint256 quantity) {
        (uint16 senderFreeMintsNymphs, uint16 senderFreeMintsFriends, uint16 senderGifts) = unpack(_getAux(msg.sender));
        require(
            _numberMinted(msg.sender) + quantity <=
                maxPerWallet + senderFreeMintsNymphs + senderFreeMintsFriends + senderGifts,
            "The maximum number of minted tokens per wallet is 11."
        );
        _;
    }


    modifier lessThanMaxPerTx(uint256 quantity) {
        require(
            quantity <= maxPerTx,
            "The maximum number of minted tokens per transaction is 11."
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
        uint256 reservedFreeMintNymphs_,
        uint256 reservedFreeMintFriends_,
        uint256 reservedGifts_,
        uint256 maxPerWallet_,
        uint256 maxPerTx_
    ) ERC721A("Divine Nymphs", "NYMPH") {
        collectionSize = collectionSize_;
        reservedFreeMintNymphs = reservedFreeMintNymphs_;
        reservedFreeMintFriends = reservedFreeMintFriends_;
        reservedGifts = reservedGifts_;
        maxPerWallet = maxPerWallet_;
        maxPerTx = maxPerTx_;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    // Public minting functions
    // ---------------------------------------------------------------

    // Free mint from Divine Nymphs allowlist
    function freeMintNymphs(bytes32[] calldata merkleProof)
        external
        nonReentrant
        callerIsUser
        freeMintActiveNymphs
        isValidMerkleProof(merkleProof, merkleRootNymphs)
        hasNotClaimedFreeMintNymphs
        freeMintLeftNymphs
    {
        (uint16 senderFreeMintsNymphs, uint16 senderFreeMintsFriends, uint16 senderGifts) = unpack(_getAux(msg.sender));
        numFreeMintNymphs++;
        senderFreeMintsNymphs++;
        _setAux(msg.sender, pack(senderFreeMintsNymphs, senderFreeMintsFriends, senderGifts));
        _safeMint(msg.sender, 1);
    }
    
    // Free mint from project friends allowlist
    function freeMintFriends(bytes32[] calldata merkleProof)
        external
        nonReentrant
        callerIsUser
        freeMintActiveFriends
        isValidMerkleProof(merkleProof, merkleRootFriends)
        hasNotClaimedFreeMintFriends
        freeMintLeftFriends
    {
        (uint16 senderFreeMintsNymphs, uint16 senderFreeMintsFriends, uint16 senderGifts) = unpack(_getAux(msg.sender));
        numFreeMintFriends++;
        senderFreeMintsFriends++;
        _setAux(msg.sender, pack(senderFreeMintsNymphs, senderFreeMintsFriends, senderGifts));
        _safeMint(msg.sender, 1);
    }

    // Public mint
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
        mintActive
        lessThanMaxPerTx(quantity)
        isCorrectPayment(mintPrice, quantity)
        mintLeft(quantity)
        lessThanMaxPerWallet(quantity)
    {
        _safeMint(msg.sender, quantity);
    }
    
    // Gift
    function gift(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        giftsLeft(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGifts += numToGift;
        for (uint256 i = 0; i < numToGift; i++) {
            (uint16 ownerFreeMintsNymphs, uint16 ownerFreeMintsFriends, uint16 ownerGifts) = unpack(_getAux(addresses[i]));
            ownerGifts++;
            _setAux(addresses[i], pack(ownerFreeMintsNymphs, ownerFreeMintsFriends, ownerGifts));
            _safeMint(addresses[i], 1);
        }
    }

    // Gift multipe
    function giftMultiple(address[] calldata addresses, uint256[] calldata quantities)
        external
        nonReentrant
        onlyOwner
    {
        require(addresses.length == quantities.length, "The number of recipients and quantities must be the same.");
        uint256 totalGifts = 0;
        for (uint256 i = 0; i < quantities.length; i++) {
            totalGifts += quantities[i];
        }
        require(
            numGifts + totalGifts <= reservedGifts,
            "There are not enough gift tokens."
        );
        numGifts += totalGifts;
        for (uint256 i = 0; i < addresses.length; i++) {
            (uint16 ownerFreeMintsNymphs, uint16 ownerFreeMintsFriends, uint16 ownerGifts) = unpack(_getAux(addresses[i]));
            ownerGifts += uint16(quantities[i]);
            _setAux(addresses[i], pack(ownerFreeMintsNymphs, ownerFreeMintsFriends, ownerGifts));
            _safeMint(addresses[i], quantities[i]);
        }
    }

    // Public read-only functions
    // ---------------------------------------------------------------

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getDevAddress() public view returns (address) {
        return devAddress;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function getReservedFreeMintNymphs() public view returns (uint256) {
        return reservedFreeMintNymphs;
    }

    function getReservedFreeMintFriends() public view returns (uint256) {
        return reservedFreeMintFriends;
    }

    function getCollectionSize() public view returns (uint256) {
        return collectionSize;
    }

    function getOwnerFreeMintCountNymphs(address owner) public view returns (uint32) {
        (uint16 ownerFreeMintsNymphs, , ) = unpack(_getAux(owner));
        return ownerFreeMintsNymphs;
    }

    function getOwnerFreeMintCountFriends(address owner) public view returns (uint32) {
        (, uint16 ownerFreeMintsFriends, ) = unpack(_getAux(owner));
        return ownerFreeMintsFriends;
    }

    function getOwnerGiftsCount(address owner) public view returns (uint32) {
        (, , uint16 ownerGifts) = unpack(_getAux(owner));
        return ownerGifts;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
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
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    // Internal read-only functions
    // ---------------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Owner only administration functions
    // ---------------------------------------------------------------

    function setFreeMintActiveNymphs(bool _isFreeMintActiveNymphs) external onlyOwner {
        isFreeMintActiveNymphs = _isFreeMintActiveNymphs;
    }

    function setFreeMintActiveFriends(bool _isFreeMintActiveFriends) external onlyOwner {
        isFreeMintActiveFriends = _isFreeMintActiveFriends;
    }

    function setMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setReservedFreeMintNymphs(uint256 _reservedFreeMintNymphs) external onlyOwner {
        require(
            numFreeMintNymphs <= _reservedFreeMintNymphs,
            "Cannot set reserved free mint to more than the current number of free mints."
        );
        reservedFreeMintNymphs = _reservedFreeMintNymphs;
    }
    
    function setReservedFreeMintFriends(uint256 _reservedFreeMintFriends) external onlyOwner {
        require(
            numFreeMintFriends <= _reservedFreeMintFriends,
            "Cannot set reserved free mint to more than the current number of free mints."
        );
        reservedFreeMintFriends = _reservedFreeMintFriends;
    }

    function setCollectionSize(uint256 _collectionSize) external onlyOwner {
        require(
            _collectionSize <= collectionSize,
            "Cannot increase collection size."
        );
        collectionSize = _collectionSize;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setFreeMintMerkleRootNymphs(bytes32 merkleRoot) external onlyOwner {
        merkleRootNymphs = merkleRoot;
    }
    function setFreeMintMerkleRootFriends(bytes32 merkleRoot) external onlyOwner {
        merkleRootFriends = merkleRoot;
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool ownerWithdrawSuccess, ) = msg.sender.call{
            value: (address(this).balance * 85) / 100
        }("");
        require(ownerWithdrawSuccess, "Owner transfer failed");
        (bool devWithdrawSuccess, ) = devAddress.call{
            value: address(this).balance
        }("");
        require(devWithdrawSuccess, "Dev transfer failed");
    }

    function withdrawTokens(IERC20 token) external onlyOwner nonReentrant {
        token.transfer(msg.sender, (token.balanceOf(address(this)) * 85) / 100);
        token.transfer(devAddress, token.balanceOf(address(this)));
    }

    // ClosedSea functions
    // ---------------------------------------------------------------

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

}