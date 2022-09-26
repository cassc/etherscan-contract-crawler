//                   _____       _____
//      .........   {     }     {     }
//     (>>\zzzzzz [======================]
//     ( <<<\lllll_\\ _        _____    \\
//    _,`-,\<   __#:\\::_    __#:::_:__  \\
//   /    . `--,#::::\\:::___#::::/__+_\ _\\
//  /  _  .`-    `--,/_~~~~~~~~~~~~~~~~~~~~  -,_
// :,// \ .         .  '--,____________   ______`-,
//  :: o |.         .  ___ \_____||____\+/     ||~ \
//  :;   ;-,_       . ,' _`,""""""""""""""""""""""""\
//  \ \_/ _ :`-,_   . ; / \\ ====================== /
//   \__/~ /     `-,.; ; o |\___[~~~]_ASCII__[~~~]__:
//      ~~~          ; :   ;~ ;  ~~~         ;~~~::;
//                    \ \_/ ~/               ::::::;
//                     \_/~~/                 \:::/
//                       ~~~                   ~~~
//  ______               __              ______         __ __                   
// |   __ \.--.--.-----.|  |_.--.--.    |   __ \.-----.|  |  |.-----.----.-----.
// |      <|  |  |__ --||   _|  |  |    |      <|  _  ||  |  ||  -__|   _|__ --|
// |___|__||_____|_____||____|___  |    |___|__||_____||__|__||_____|__| |_____|
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract RustyRollers is ERC721A, Ownable, ReentrancyGuard {

    // Variables
    // ---------------------------------------------------------------

    uint256 public immutable collectionSize;
    uint256 public immutable maxPerWallet;

    bytes32 public freeMintMerkleRoot;

    bool public isFreeMintActive = false;
    bool public isMintActive = false;

    uint256 private mintPrice = 0.025 ether;
    string private _baseTokenURI;

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

    modifier mintLeft(uint256 quantity) {
        require(
            totalSupply() + quantity <=
                collectionSize,
            "There are no tokens left."
        );
        _;
    }

    modifier mintNotZero(uint256 quantity){
        require(
            quantity != 0, "You cannont mint 0 tokens."
        );
        _;
    }

    modifier hasNotClaimedFreeMint(uint256 quantity) {
        uint64 senderFreeMints;
        senderFreeMints = _getAux(msg.sender);
        require(
            senderFreeMints + quantity <= 2,
            "This wallet cannot claim more than 2 tokens from free mint."
        );
        _;
    }

    modifier lessThanMaxPerWallet(uint256 quantity) {
        require(
            _numberMinted(msg.sender) + quantity <=
                maxPerWallet,
            "The maximum number of minted tokens per wallet is 10."
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
        uint256 maxPerWallet_
    ) ERC721A("RustyRollers", "ROLLER") {
        collectionSize = collectionSize_;
        maxPerWallet = maxPerWallet_;
    }

    // Public minting functions
    // ---------------------------------------------------------------

    // Free mint from allowlist
    function freeMint(bytes32[] calldata merkleProof, uint256 quantity)
        external
        nonReentrant
        callerIsUser
        freeMintActive
        isValidMerkleProof(merkleProof, freeMintMerkleRoot)
        hasNotClaimedFreeMint(quantity)
        mintLeft(quantity)
        mintNotZero(quantity)
    {
        uint256 senderFreeMints;
        senderFreeMints =_getAux(msg.sender);
        senderFreeMints += quantity;
        _setAux(msg.sender, uint64(senderFreeMints));
        _safeMint(msg.sender, quantity);
    }

    // Public mint
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
        mintActive
        lessThanMaxPerWallet(quantity)
        isCorrectPayment(mintPrice, quantity)
        mintLeft(quantity)
        mintNotZero(quantity)
    {
        _safeMint(msg.sender, quantity);
    }


    // Public read-only functions
    // ---------------------------------------------------------------

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function getFreeMintCount(address owner) public view returns (uint64) {
        uint64 ownerFreeMints;
        ownerFreeMints = _getAux(owner);
        return ownerFreeMints;
    }

    function getUserVerifed(bytes32[] calldata merkleProof, address user) public view returns(bool) {
         bool verified = MerkleProof.verify(
                merkleProof,
                freeMintMerkleRoot,
                keccak256(abi.encodePacked(user))
            );
        return verified;
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

    function setFreeMintActive(bool _isFreeMintActive) external onlyOwner {
        isFreeMintActive = _isFreeMintActive;
    }

    function setMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setFreeMintMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        freeMintMerkleRoot = merkleRoot;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawTokens(IERC20 token) external onlyOwner nonReentrant {
        token.transfer(msg.sender, (token.balanceOf(address(this))));
    }

    function ownerMint(uint256 quantity) external onlyOwner 
        mintLeft(quantity){
        _safeMint(msg.sender, quantity);
    }

    
}