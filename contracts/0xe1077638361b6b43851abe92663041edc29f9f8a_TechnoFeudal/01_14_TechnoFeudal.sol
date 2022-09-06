// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@                  @@@@@@                  @@@@@@@                  @@@@@@@@@@@@@          
// @@@@@@@@@@@@@                  @@@@@@                  @@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@                  @@@@@@      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@            @@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@            @@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TechnoFeudal is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI;

    string private collectionURI;

    string public PROVENANCE_HASH;

    bytes32 public preSaleListMerkleRoot;
    bytes32 public mintListRoot;

    enum SaleState {
        Inactive,
        PreSale,
        PublicSale,
        MintList
    }

    SaleState public saleState = SaleState.Inactive;

    address public royaltyReceiverAddress;
    address public beneficiary;

    // ============ CUSTOMIZE VALUES BELOW ============
    uint256 public constant MAX_TOTAL_SUPPLY = 3333;
    uint256 public constant MAX_PUBLIC_SUPPLY = 3000;

    uint256 public constant MAX_MINT_LIST_MINTS = 1; 

    uint256 public constant MAX_PRE_SALE_MINTS = 1;
    uint256 public constant PRE_SALE_PRICE = 0.04 ether;

    uint256 public constant MAX_PUBLIC_SALE_MINTS = 5;
    uint256 public constant PUBLIC_SALE_PRICE = 0.08 ether;

    uint256 public constant ROYALTY_PERCENTAGE = 5;
    // ================================================

    constructor(
        address _royaltyReceiverAddress
        )
        ERC721A("Techno-Feudal Citizens", "TFC")
    {
        royaltyReceiverAddress = _royaltyReceiverAddress;
        ownerMint(7); 
    }

    // ============ ACCESS CONTROL MODIFIERS ============

    modifier preSaleActive() {
        require(saleState == SaleState.PreSale, "Pre sale is not open");
        _;
    }

    modifier publicSaleActive() {
        require(saleState == SaleState.PublicSale, "Public sale is not open");
        _;
    }

    modifier mintListActive() {
        require(saleState == SaleState.MintList, "Mintlist is not open");
        _;
    }

    modifier canMint(uint256 quantity) {
        require(
            tokenCounter.current() + quantity <=
                MAX_TOTAL_SUPPLY,
            "Insufficient tokens remaining"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(
            price * quantity == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidPreSaleAddress(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                preSaleListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address is not whitelisted"
        );
        _;
    }

    modifier isValidMintListAddress(bytes32[] calldata proof) {
        require(
            MerkleProof.verify(
                proof,
                mintListRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address is not mintlisted"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mintPublicSale(uint256 quantity)
        external
        payable
        nonReentrant
        publicSaleActive
        isCorrectPayment(PUBLIC_SALE_PRICE, quantity)
        canMint(quantity)
    {

        require(totalSupply() + quantity <= MAX_PUBLIC_SUPPLY, "reached max supply");
        require(
        numberMinted(msg.sender) + quantity <=  MAX_PUBLIC_SALE_MINTS,
           "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
    }

    function mintPreSale(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleActive
        isCorrectPayment(PRE_SALE_PRICE, quantity)
        canMint(quantity)
        isValidPreSaleAddress(merkleProof)
    {

        require(totalSupply() + quantity <= MAX_TOTAL_SUPPLY, "reached max supply");
        require(
            numberMinted(msg.sender) + quantity <= MAX_PRE_SALE_MINTS,
            "Exceeds max number for pre sale mint"
        );

        _safeMint(msg.sender, quantity);
    }

    function mintMintList(uint256 quantity, bytes32[] calldata proof)
        external
        nonReentrant
        mintListActive
        canMint(quantity)
        isValidMintListAddress(proof)
    {

        require(totalSupply() + quantity <= MAX_TOTAL_SUPPLY, "reached max supply");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_LIST_MINTS,
            "Exceeds max number for mintlist mint"
        );

        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) public canMint(quantity) onlyOwner {

        require(totalSupply() + quantity <= MAX_TOTAL_SUPPLY, "reached max supply");
        _safeMint(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getContractURI() external view returns (string memory) {
        return collectionURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ SUPPORTING FUNCTIONS ============
    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    function setProvenanceHash(string calldata hash) public onlyOwner {
        PROVENANCE_HASH = hash;
    }

    // ============ FUNCTION OVERRIDES ============
    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non-existent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    /**
     * @dev support EIP-2981 interface for royalties
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (
            royaltyReceiverAddress,
            SafeMath.div(SafeMath.mul(salePrice, ROYALTY_PERCENTAGE), 100)
        );
    }

    /**
     * @dev support EIP-2981 interface for royalties
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual override (ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setPublicSaleActive() external onlyOwner {
        saleState = SaleState.PublicSale;
    }

    function setPreSaleActive() external onlyOwner {
        saleState = SaleState.PreSale;
    }
    
    function setMintListActive() external onlyOwner {
        saleState = SaleState.MintList;
    }

    function setSaleInactive() external onlyOwner {
        saleState = SaleState.Inactive;
    }

    /**
     * @dev used for allowlisting pre sale addresses
     */
    function setPreSaleListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        preSaleListMerkleRoot = merkleRoot;
    }

    function setMintListRoot(bytes32 merkleRoot) external onlyOwner {
        mintListRoot = merkleRoot;
    }
    /**
     * @dev used for art reveals
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setCollectionURI(string memory _collectionURI) external onlyOwner {
        collectionURI = _collectionURI;
    }

    function setRoyaltyReceiverAddress(address _royaltyReceiverAddress)
        external
        onlyOwner
    {
        royaltyReceiverAddress = _royaltyReceiverAddress;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }


    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    /**
     * @dev enable contract to receive ethers in royalty
     */
    receive() external payable {}
}