//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GhostRealm is ERC721A, ReentrancyGuard, Ownable {
    /* =================================== SALE STATES =================================== */
    enum SaleState {
        PAUSED,
        WHITELIST_SALE,
        PUBLIC_SALE
    }
    SaleState private saleState = SaleState.PAUSED;

    /* =================================== STATE VARIABLES =================================== */
    bytes32 private merkleRoot = 0x0;
    string private baseURL;
    string private unrevealedURL;
    string private URLSuffix = ".json";
    bool private revealed = false;
    uint256 private constant TOTAL_SUPPLY = 2222;
    uint256 private mintPrice = 0.009 ether;
    uint256 private maxPerWallet = 5;
    uint256 private maxPerTx = 5;
    uint256 private constant WHITELIST_SUPPLY = 222;
    address private developerWallet;
    mapping(address => bool) private hasClaimedWhitelist;
    mapping(address => uint256) private amountMinted;

    /* Safety */
    receive() external payable {}

    /* Constructor */
    constructor(
        string memory _baseUrl,
        string memory _unrevealedUrl,
        address _developerWallet
    ) ERC721A("Ghost Realm", "GR") {
        baseURL = _baseUrl;
        unrevealedURL = _unrevealedUrl;
        developerWallet = _developerWallet;
    }

    /* =================================== PUBLIC FUNCTIONS =================================== */
    // Whitelist mint function.
    function whitelistMint(bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        generalRequirements(1)
        whitelistMintRequirements(_merkleProof)
    {
        _safeMint(msg.sender, 1);
        hasClaimedWhitelist[msg.sender] = true;
    }

    // Public mint function.
    function publicMint(uint256 _quantity)
        external
        payable
        nonReentrant
        generalRequirements(_quantity)
        publicMintRequirements(_quantity)
    {
        _safeMint(msg.sender, _quantity);
        amountMinted[msg.sender] += _quantity;
    }

    /* =================================== GETTERS =================================== */
    // Get max NFT's allowed per transaction.
    function getMaxPerTx() public view returns (uint256) {
        return maxPerTx;
    }

    // Get the total supply of NFT's
    function getTotalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    // Get the mint price.
    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    // Get max allowed per wallet.
    function getMaxPerWallet() public view returns (uint256) {
        return maxPerWallet;
    }

    // Get has claimed free NFT status for caller.
    function getHasClaimedWhitelist() public view returns (bool) {
        return hasClaimedWhitelist[msg.sender];
    }

    // Get amount of NFT's minted by caller.
    function getAmountMinted() public view returns (uint256) {
        return amountMinted[msg.sender];
    }

    // Get the whitelist supply.
    function getWhitelistSupply() public pure returns (uint256) {
        return WHITELIST_SUPPLY;
    }

    // Get the developer wallet.
    function getDeveloperWallet() public view returns (address) {
        return developerWallet;
    }

    // Get the current sale state
    function getSaleState() public view returns (SaleState) {
        return saleState;
    }

    // Gets the revealed status
    function getRevealedStatus() public view returns (bool) {
        return revealed;
    }

    /* =================================== INHERITED FUNCTIONS =================================== */
    // Returns the base URL.
    function _baseURI() internal view override returns (string memory) {
        return baseURL;
    }

    //Returns the url of an individual token.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) return unrevealedURL;

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), URLSuffix)
                )
                : "";
    }

    //What token the collection starts at.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /* =================================== OWNER ONLY =================================== */
    // Mint function for owner.
    function ownerMint(uint256 _quantity) public onlyOwner {
        require(
            totalSupply() + _quantity <= TOTAL_SUPPLY,
            "You are minting too many"
        );
        _safeMint(msg.sender, _quantity);
    }

    // Owner mint to specified address.
    function ownerMintForAddress(address _addressToMintFor, uint256 _quantity)
        public
        onlyOwner
    {
        require(
            totalSupply() + _quantity <= TOTAL_SUPPLY,
            "You are minting too many"
        );
        _safeMint(_addressToMintFor, _quantity);
    }

    // Pause the contract.
    function pauseContract() public onlyOwner {
        saleState = SaleState.PAUSED;
    }

    // Start whitelist sale.
    function startWhitelistSale() public onlyOwner {
        saleState = SaleState.WHITELIST_SALE;
    }

    // Start public sale.
    function startPublicSale() public onlyOwner {
        saleState = SaleState.PUBLIC_SALE;
    }

    // Set a new mint price.
    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    // Set a new max per wallet
    function setMaxPerWallet(uint256 _newMaxPerWallet) public onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    //Set a new max per transaction.
    function setMaxPerTx(uint256 _newMaxPerTx) public onlyOwner {
        maxPerTx = _newMaxPerTx;
    }

    // Reveal the collection.
    function reveal() public onlyOwner {
        revealed = !revealed;
    }

    // Set a new unrevealed url.
    function setUnrevealedUrl(string memory _newUnrevealedUrl)
        public
        onlyOwner
    {
        unrevealedURL = _newUnrevealedUrl;
    }

    // Set a new base URL.
    function setBaseUrl(string memory _newBaseUrl) public onlyOwner {
        baseURL = _newBaseUrl;
    }

    // Set a new merkle root.
    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    // Withdraw the contract's funds.
    function withdrawFunds() public payable nonReentrant onlyOwner {
        require(address(this).balance > 0, "The contract has no ETH");

        uint256 contractBalance = address(this).balance;

        (bool withdrawOneSuccess, ) = payable(owner()).call{
            value: (contractBalance * 85) / 100
        }("");
        (bool withdrawTwoSuccess, ) = payable(developerWallet).call{
            value: (contractBalance * 15) / 100
        }("");
        require(withdrawOneSuccess && withdrawTwoSuccess, "Withdraw failed");
    }

    /* =================================== MODIFIERS =================================== */
    // General requirements to be able to mint.
    modifier generalRequirements(uint256 _quantity) {
        require(saleState != SaleState.PAUSED, "Minting is paused");
        require(totalSupply() < TOTAL_SUPPLY, "Sold out");
        require(_quantity <= maxPerTx, "Max 5 per transaction");
        require(
            amountMinted[msg.sender] + _quantity <= maxPerWallet,
            "Max per wallet exceeded"
        );
        require(totalSupply() + _quantity <= TOTAL_SUPPLY, "Sold out");
        _;
    }

    // Requirements for the whitelist mint.
    modifier whitelistMintRequirements(bytes32[] calldata _merkleProof) {
        require(totalSupply() < WHITELIST_SUPPLY, "Whitelist sale is sold out");
        require(
            hasClaimedWhitelist[msg.sender] == false,
            "You have already claimed your FREE NFT"
        );
        bytes32 leafNode = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leafNode),
            "You are not whitelisted!"
        );
        _;
    }

    // Requirements for the public mint.
    modifier publicMintRequirements(uint256 _quantity) {
        require(
            saleState == SaleState.PUBLIC_SALE,
            "Public sale has not started yet"
        );
        require(msg.value >= (mintPrice * _quantity), "To little ETH was sent");
        _;
    }
}