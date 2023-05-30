// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
████████╗██████╗░░█████╗░██████╗░███╗░░░███╗░█████╗░███╗░░██╗██╗░░██╗██╗███████╗
╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗████╗░████║██╔══██╗████╗░██║██║░██╔╝██║██╔════╝
░░░██║░░░██████╔╝███████║██████╔╝██╔████╔██║██║░░██║██╔██╗██║█████═╝░██║█████╗░░
░░░██║░░░██╔══██╗██╔══██║██╔═══╝░██║╚██╔╝██║██║░░██║██║╚████║██╔═██╗░██║██╔══╝░░
░░░██║░░░██║░░██║██║░░██║██║░░░░░██║░╚═╝░██║╚█████╔╝██║░╚███║██║░╚██╗██║███████╗
░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═╝╚══════╝  
*/

contract TrapMonkie8888 is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // ======== SUPPLY ========
    uint256 public constant MAX_SUPPLY = 8888; 

    // ======== MAX MINTS ========
    uint256 public maxPremintGenesisMob = 4;
    uint256 public maxPremintMutant = 3;
    uint256 public maxPremintOG = 2;
    uint256 public maxPremintTraplist = 1;
    uint256 public maxPublicSaleMint = 10;

    // ======== PRICE & TIME ========
    struct SaleConfig {
      uint32 PremintTime; 
      uint32 PublicTime; 
      uint32 GenesisMobTime;
      uint256 PremintGenesisMobPrice; 
      uint256 PremintMutantPrice;
      uint256 PremintOGPrice;
      uint256 PremintTraplistPrice;
      uint256 publicPrice;
    }

    SaleConfig public saleConfig;

    // ======== METADATA ========
    string private uriPrefix = '';
    string private uriSuffix = '.json';
    string private hiddenMetadataUri;
    bool public revealed = false;

    // ======== MERKLE ROOT ========
    bytes32 public GenesisMobMerkleRoot;
    bytes32 public MutantMerkleRoot;
    bytes32 public OGMerkleRoot;
    bytes32 public TraplistMerkleRoot;

    // ======== MINTED ========
    mapping(address => uint256) public PremintGenesisMobMinted;
    mapping(address => uint256) public PremintMutantMinted;
    mapping(address => uint256) public PremintOGMinted;
    mapping(address => uint256) public PremintTraplistMinted;
    mapping(address => uint256) public PublicMinted;

    // ======== CONSTRUCTOR ========   
    constructor(string memory _hiddenMetadataUri) ERC721A("TrapMonkie", "TM") {}

    // Modifier
     modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ======== MINTING ========
    /**
     * GENESIS/MOB MINT
     */
    function PremintGenesisMob(uint256 _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(saleConfig.PremintGenesisMobPrice);
        uint256 GenesisMobTime = uint256(config.GenesisMobTime);
        require(isGenesisMOBOn(price, GenesisMobTime),"Minting for Genesis/MOB has not yet begun.");
        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bool isValidProof = MerkleProof.verify(_proof, GenesisMobMerkleRoot, sender);
        require(isValidProof, "INVALID PROOF");

        require(totalSupply() + _quantity <= MAX_SUPPLY, "Claim amount exceeds collection size" );
        require(PremintGenesisMobMinted[msg.sender] + _quantity <= maxPremintGenesisMob , "Exceeded claim limit"); 
        require(price * _quantity == msg.value, "Incorrect ETH Amount Submitted");

        PremintGenesisMobMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }
    /**
     * MUTANT MINT
     */
    function PremintMutant(uint256 _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(saleConfig.PremintMutantPrice);
        uint256 PremintTime = uint256(config.PremintTime);
        require(isPremintOn(price, PremintTime),"Minting for Mutants has not yet begun.");
        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bool isValidProof = MerkleProof.verify(_proof, MutantMerkleRoot, sender);
        require(isValidProof, "INVALID PROOF");

        require(totalSupply() + _quantity <= MAX_SUPPLY, "Claim amount exceeds collection size" );
        require(PremintMutantMinted[msg.sender] + _quantity <= maxPremintMutant , "Exceeded claim limit"); 
        require(price * _quantity == msg.value, "Incorrect ETH Amount Submitted");

        PremintMutantMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }
    /**
     * OG MINT
     */
    function PremintOG(uint256 _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(saleConfig.PremintOGPrice);
        uint256 PremintTime = uint256(config.PremintTime);
        require(isPremintOn(price, PremintTime),"Minting for OG has not yet begun.");
        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bool isValidProof = MerkleProof.verify(_proof, OGMerkleRoot, sender);
        require(isValidProof, "INVALID PROOF");

        require(totalSupply() + _quantity <= MAX_SUPPLY, "Claim amount exceeds collection size" );
        require(PremintOGMinted[msg.sender] + _quantity <= maxPremintOG , "Exceeded claim limit"); 
        require(price * _quantity == msg.value, "Incorrect ETH Amount Submitted");

        PremintOGMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }
    /**
     * TRAPLIST MINT
     */
    function PremintTraplist(uint256 _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(saleConfig.PremintTraplistPrice);
        uint256 PremintTime = uint256(config.PremintTime);
        require(isPremintOn(price, PremintTime),"Minting for Traplist has not yet begun.");
        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bool isValidProof = MerkleProof.verify(_proof, TraplistMerkleRoot, sender);
        require(isValidProof, "INVALID PROOF");

        require(totalSupply() + _quantity <= MAX_SUPPLY, "Claim amount exceeds collection size" );
        require(PremintTraplistMinted[msg.sender] + _quantity <= maxPremintTraplist , "Exceeded claim limit"); 
        require(price * _quantity == msg.value, "Incorrect ETH Amount Submitted");

        PremintTraplistMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }
    /**
     * PUBLIC MINT
     */
    function publicMint(uint256 _quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(saleConfig.publicPrice);
        uint256 PublicTime = uint256(config.PublicTime);
        require(isPublicOn(price, PublicTime),"Minting for public has not yet begun.");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Claim amount exceeds collection size" );
        require(PublicMinted[msg.sender] + _quantity <= maxPublicSaleMint , "Exceeded claim limit"); 
        require(price * _quantity == msg.value, "Incorrect ETH Amount Submitted");

        PublicMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // ======== MERKLE ROOT SETTERS ========
    /**
     * Set GENESIS/MOB merkle root
     */
    function setGenesisMobMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        GenesisMobMerkleRoot = _merkleRoot;
    }

    /**
     * Set MUTANT merkle root
     */
    function setMutantMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        MutantMerkleRoot = _merkleRoot;
    }

    /**
     * Set OG merkle root
     */
    function setOGMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        OGMerkleRoot = _merkleRoot;
    }

    /**
     * Det TRAPLIST merkle root
     */
    function setTraplistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        TraplistMerkleRoot = _merkleRoot;
    }


    //======== MINT STATUS ========
    // PUBLIC SALE
    function isPublicOn(
        uint256 publicPriceWei,
        uint256 PublicTime
    ) public view returns (bool) {
        return
        publicPriceWei != 0 &&
        block.timestamp >= PublicTime;
    }
    
    // PREMINT SALE
    function isPremintOn(
        uint256 publicPriceWei,
        uint256 PremintTime
    ) public view returns (bool) {
        return
        publicPriceWei != 0 &&
        block.timestamp >= PremintTime;
    }

    // GENESIS/MOB
    function isGenesisMOBOn(
        uint256 publicPriceWei,
        uint256 GenesisMobTime
    ) public view returns (bool) {
        return
        publicPriceWei != 0 &&
        block.timestamp >= GenesisMobTime;
    }

    // ======== METADATA URI ========
    /** 
    * set startTokenId to 1
    */
    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (revealed == false) {
        return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }


    // ======== MINT SETUP ======== 
    function SetupSaleInfo(
        uint32 PremintTime,
        uint32 PublicTime,
        uint32 GenesisMobTime,
        uint256 PremintGenesisMobPriceWei, 
        uint256 PremintMutantPriceWei,
        uint256 PremintOGPriceWei,
        uint256 PremintTraplistPriceWei,
        uint256 publicPriceWei

    ) external onlyOwner {
        saleConfig = SaleConfig(
            PremintTime,
            PublicTime,
            GenesisMobTime, 
            PremintGenesisMobPriceWei, 
            PremintMutantPriceWei,
            PremintOGPriceWei,
            PremintTraplistPriceWei,
            publicPriceWei
        );
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // ======== WITHDRAW ========

    //ADDRESS LIST - GNOSIS VAULT % IS INCLUDED IN FOUNDER
    address FOUNDER_WALLET = 0xEbB31f4e2A1CdE56A59bFEA5F225aC10426a914b;
    address MARKETING_WALLET = 0x5cA6930006A3069a60AA88e8B0E992609f93e394;
    address DEVELOPER_1_WALLET = 0xeB25d89C262b9B850EF442a6E7065fE240106A51;
    address LEAD_ARTIST_WALLET = 0x70D5c23F4E410B76284CF8B7F1c65e0d7c79015D;
    address ARTIST_1_WALLET = 0x74DeF6d79DA09d94D3971FA60a22bd8D11534dAc;
    address ARTIST_2_WALLET = 0x5610B0AfA7586B9156848D728a64BD8Fbdb7DE96;
    address DEVELOPER_B_WALLET = 0x5f22a3002b96061f02f0B8921298457AD336BA3E;

    // FULL WITHDRAW
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO FUNDS AVAILABLE");
        payable(FOUNDER_WALLET).transfer((balance * 52)/100);
        payable(MARKETING_WALLET).transfer((balance * 12)/100);
        payable(DEVELOPER_1_WALLET).transfer((balance * 12)/100);
        payable(LEAD_ARTIST_WALLET).transfer((balance * 10)/100);
        payable(ARTIST_1_WALLET).transfer((balance * 5)/100);
        payable(ARTIST_2_WALLET).transfer((balance * 5)/100);
        payable(DEVELOPER_B_WALLET).transfer((balance * 4)/100);
    }

    // PARTIAL WITHDRAW
    function withdrawAmount(uint256 _amount) public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO FUNDS AVAILABLE");
        payable(FOUNDER_WALLET).transfer((_amount * 52)/100);
        payable(MARKETING_WALLET).transfer((_amount * 12)/100);
        payable(DEVELOPER_1_WALLET).transfer((_amount * 12)/100);
        payable(LEAD_ARTIST_WALLET).transfer((_amount * 10)/100);
        payable(ARTIST_1_WALLET).transfer((_amount * 5)/100);
        payable(ARTIST_2_WALLET).transfer((_amount * 5)/100);
        payable(DEVELOPER_B_WALLET).transfer((_amount * 4)/100);
    }

}