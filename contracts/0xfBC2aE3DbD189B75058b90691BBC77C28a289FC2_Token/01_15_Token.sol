// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Token is ERC721A,  Ownable, ReentrancyGuard {

    // ======== Metadata =========
    string public baseTokenURI;

    // ======== Provenance =========
    string public provenanceHash = "";

    // ======== Supply =========
    uint256 public maxMintsPerTX;
    uint256 public maxMintsPerAddress;
    uint256 public maxTokens;

    // ======== Cost =========
    uint256 public pricePublic;
    uint256 public priceWhitelist;

    // ======== Sale Status =========
    bool public preSaleIsActive = false;
    bool public publicSaleIsActive = false;

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;
    mapping(address => bool) public whitelistClaimed;

    // ======== Whitelist Validation =========
    bytes32 public whitelistMerkleRoot;
    
    // ======== Constructor =========
    constructor(
        string memory baseURI, 
        uint256 tokenSupply,
        uint256 _maxMintsAddress,
        uint256 _maxMintsPerTX,
        uint256 _pricePublic,
        uint256 _priceWhitelist) ERC721A ("Plug'd", "PLUGD") {
        setBaseURI(baseURI);
        maxTokens = tokenSupply;
        maxMintsPerAddress = _maxMintsAddress;
        maxMintsPerTX = _maxMintsPerTX;
        pricePublic = _pricePublic;
        priceWhitelist = _priceWhitelist;
    }

    // ======== Metadata =========
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // ======== Provenance =========
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }
    
    // ======== Modifier Checks =========
    modifier isWhitelistMerkleRootSet() {
        require(whitelistMerkleRoot != 0, "Whitelist merkle root not set!");
        _;
    }

    modifier isValidMerkleProof(address _address, bytes32[] calldata merkleProof, uint256 quantity) {
        require(
            MerkleProof.verify(
                merkleProof, 
                whitelistMerkleRoot, 
                keccak256(abi.encodePacked(keccak256(abi.encodePacked(_address, quantity)))
                )
            ), 
            "Address is not on whitelist!");
        _;

    }
    
    modifier isSupplyAvailable(uint256 numberOfTokens) {
        uint256 supply = totalSupply();
        require(supply + numberOfTokens <= maxTokens, "Exceeds max token supply!");
        _;
    }
    
    modifier isPaymentCorrectPublic(uint256 numberOfTokens) {
        require(msg.value >= pricePublic * numberOfTokens, "Invalid ETH value sent!");
        _;
    }
    
    modifier isPaymentCorrectWhitelist(uint256 numberOfTokens) {
        require(msg.value >= priceWhitelist * numberOfTokens, "Invalid ETH value sent!");
        _;
    }

    modifier isMaxMintsPerWalletExceeded(uint amount) {
        require(addressToMintCount[msg.sender] + amount <= maxMintsPerAddress, "Exceeds max mint per wallet!");
        _;
    }

    // ======== Mint Functions =========
    /// @notice Mint all available tokens on whitelist
    /// @param merkleProof The merkle proof generated offchain
    /// @param quantity The quantity user can mint
    function mintWhitelist(bytes32[] calldata merkleProof, uint256 quantity) public payable 
        isWhitelistMerkleRootSet()
        isValidMerkleProof(msg.sender, merkleProof, quantity) 
        isSupplyAvailable(quantity) 
        isPaymentCorrectWhitelist(quantity)
        isMaxMintsPerWalletExceeded(quantity)
        nonReentrant {
            require(!whitelistClaimed[msg.sender], "Whitelist is already claimed by this wallet!");
            require(preSaleIsActive, "Pre-Sale is not active!");
            require(quantity <= maxMintsPerTX, "Exceeds max mint per tx!");

            _safeMint(msg.sender, quantity);           

            addressToMintCount[msg.sender] += quantity;

            whitelistClaimed[msg.sender] = true;
    }

    /// @notice Mint tokens at public price
    /// @param quantity The amount user would like to mint
    function mintPublic(uint quantity) public payable 
        isSupplyAvailable(quantity) 
        isPaymentCorrectPublic(quantity)
        isMaxMintsPerWalletExceeded(quantity)
        nonReentrant  {
            require(msg.sender == tx.origin, "Mint: not allowed from contract");
            require(quantity <= maxMintsPerTX, "Exceeds max mint per tx!");
            require(publicSaleIsActive, "Public-Sale is not active!");
            
            _safeMint(msg.sender, quantity);          

            addressToMintCount[msg.sender] += quantity;
    }

    /// @notice Mint team tokens
    /// @param _address The address to send minted tokens
    /// @param quantity The number of tokens to be minted
    function mintTeamTokens(address _address, uint256 quantity) public 
        onlyOwner 
        isSupplyAvailable(quantity) {            
        _safeMint(_address, quantity);          
    }

    // ======== Whitelisting =========
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    /// @notice Check if user is whitelisted
    /// @param _address The whitelisted address
    /// @param merkleProof The merkle proof generated offchain
    /// @param quantity The number of tokens the user has been whitelisted for
    function isWhitelisted(address _address, bytes32[] calldata merkleProof, uint256 quantity) external view
        isValidMerkleProof(_address, merkleProof, quantity) 
        returns (bool) {            
            require(!whitelistClaimed[_address], "Whitelist is already claimed by this wallet");
            return true;
    }

    /// @notice Check if user has claimed their whitelist
    /// @param _address The whitelisted address
    function isWhitelistClaimed(address _address) external view returns (bool) {
        return whitelistClaimed[_address];
    }

    // ======== Utilities =========
    /// @notice Return number of tokens minted
    /// @param _address The whitelisted address
    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    // ======== State Management =========
    /// @notice Toggle whitelist sale state
    function flipPreSaleStatus() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /// @notice Toggle public sale state
    function flipPublicSaleStatus() public onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }
 
    // ======== Token Supply Management=========
    /// @notice Set max tokens per address
    /// @param _max The new max tokens per address
    function setMaxMintPerAddress(uint _max) public onlyOwner {
        maxMintsPerAddress = _max;
    }

    /// @notice Decrease max token supply
    /// @param newMaxTokenSupply The new max tokens supply
    function decreaseTokenSupply(uint256 newMaxTokenSupply) external onlyOwner {
        require(maxTokens > newMaxTokenSupply, "Max token supply can only be decreased!");
        require(maxTokens > totalSupply(), "Max token supply must be greated than minted count!");
        maxTokens = newMaxTokenSupply;
    }

    /// @notice Change whitelist price
    /// @param newPrice The new whitelist price
    function changePriceWhitelist(uint256 newPrice) external onlyOwner {
        priceWhitelist = newPrice;
    }

    /// @notice Change public price
    /// @param newPrice The new public price
    function changePricePublic(uint256 newPrice) external onlyOwner {
        pricePublic = newPrice;
    }

    // ======== Withdraw =========
    /// @notice Withdraw funds to contract owners address
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }
}