// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title ArcadeLand contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract ArcadeLand is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounterStandardLands;
    Counters.Counter private _tokenIdCounterLargeLands;
    Counters.Counter private _tokenIdCounterXLargeLands;
    Counters.Counter private _tokenIdCounterMegaLands;

    bool public onlyWhitelisted = false;
    bool public openMint = false;

    mapping (address => uint256) whitelist;
    mapping (address => uint256) addressList;


    struct LandSpec {
        uint256 price;
        uint256 maxSupply;
        uint256 startingTokenId;
    }

    enum Size {
        Standard,
        Large,
        XLarge,
        Mega
    }

    mapping (Size => LandSpec) landSpecs;

    string private _contractURI;
    string public baseURI = "";

    uint256 public maxMintPerTx = 3;
    uint256 public maxMintPerWL = 2;
    uint256 public maxMintPerAddress = 5;

    bytes32 public whitelistMerkleRoot;

    constructor() ERC721("Arcade Land", "ARCLAND") {
        landSpecs[Size.Mega] = LandSpec(3 ether, 100, 1);
        landSpecs[Size.XLarge] = LandSpec(.75 ether, 1900, 101);
        landSpecs[Size.Large] = LandSpec(.5 ether, 3000, 2001);
        landSpecs[Size.Standard] = LandSpec(.25 ether, 5000, 5001);
    }

    function setMaxMintPerWL(uint256 _maxMint) external onlyOwner {
        maxMintPerWL = _maxMint;
    }

    function setMaxMintPerTx(uint256 _maxMint) external onlyOwner {
        maxMintPerTx = _maxMint;
    }

    function setMaxMintPerAddress(uint256 _maxMint) external onlyOwner {
        maxMintPerAddress = _maxMint;
    }

    //Set Base URI
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function getSpec(Size size) private view returns (LandSpec memory) {
        return landSpecs[size];
    }

    function setPrice(Size size, uint256 _newPrice) external onlyOwner {
        landSpecs[size].price = _newPrice;
    }

    function setSupply(Size size, uint256 _newSupply) external onlyOwner {
        require(_newSupply < landSpecs[size].maxSupply, "supply cannot be greater");
        landSpecs[size].maxSupply = _newSupply;       
    }

    function flipWhitelistedState() public onlyOwner {
        onlyWhitelisted = !onlyWhitelisted;
    }

    function flipMintState() public onlyOwner {
        openMint = !openMint;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId))) : "";
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "no contracts please");
        _;
    }

    modifier mintCompliance(Size size, uint256 quantity) {
        require(openMint, "public sale not open");
        require(quantity <= maxMintPerTx, "over limit");
        require(addressList[msg.sender] + quantity <= maxMintPerAddress, "over address limit");
        LandSpec memory land = landSpecs[size];
        require(totalSupplyBySize(size) + quantity <= land.maxSupply, "over supply");
        require(msg.value >= land.price * quantity, "not enough ether sent");
        _;       
    }

    modifier mintComplianceWithWL(Size size, uint256 quantity) {
        require(onlyWhitelisted, "whitelist mint not open");
        require(whitelist[msg.sender] + quantity <= maxMintPerWL, "over WL limit");
        LandSpec memory land = landSpecs[size];
        require(totalSupplyBySize(size) + quantity <= land.maxSupply, "over supply");
        require(msg.value >= land.price * quantity, "not enough ether sent");
        _;       
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }
    
    function mintStandardLands(uint256 quantity) external payable {
        _mint(Size.Standard, quantity);
    }

    function mintStandardLandsWhitelist(bytes32[] calldata merkleProof, uint256 quantity) external payable { 
        _mintWithWL(Size.Standard, quantity, merkleProof);
    }

    function mintStandardLandsForAddress(uint256 quantity, address receiver) external onlyOwner {
        _mintForAddress(Size.Standard, quantity, receiver);
    }

    function mintLargeLands(uint256 quantity) external payable {
        _mint(Size.Large, quantity);
    }

    function mintLargeLandsWhitelist(bytes32[] calldata merkleProof, uint256 quantity) external payable {
        _mintWithWL(Size.Large, quantity, merkleProof);
    }

    function mintLargeLandsForAddress(uint256 quantity, address receiver) external onlyOwner {
        _mintForAddress(Size.Large, quantity, receiver);
    }

    function mintXLargeLands(uint256 quantity) external payable {
        _mint(Size.XLarge, quantity);
    }

    function mintXLargeLandsWhitelist(bytes32[] calldata merkleProof, uint256 quantity) external payable {
        _mintWithWL(Size.XLarge, quantity, merkleProof);
    }
    
    function mintXLargeLandsForAddress(uint256 quantity, address receiver) external onlyOwner {
        _mintForAddress(Size.XLarge, quantity, receiver);
    }

    function mintMegaLands(uint256 quantity) external payable {
        _mint(Size.Mega, quantity);
    }
    
    function mintMegaLandsWhitelist(bytes32[] calldata merkleProof, uint256 quantity) external payable {
        _mintWithWL(Size.Mega, quantity, merkleProof);
    }
    
    function mintMegaLandsForAddress(uint256 quantity, address receiver) external onlyOwner {
        _mintForAddress(Size.Mega, quantity, receiver);
    }

    function _mint(Size size, uint256 quantity) internal onlyEOA mintCompliance(size, quantity) {
        addressList[msg.sender] += quantity;
        _safeMintLoop(size, quantity, msg.sender);
    }

    function _mintWithWL(
        Size size,
        uint256 quantity,
        bytes32[] calldata merkleProof
    )
        internal
        onlyEOA
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        mintComplianceWithWL(size, quantity)
    {
        whitelist[msg.sender] += quantity;
        _safeMintLoop(size, quantity, msg.sender);
    }
   
    function _mintForAddress(Size size, uint256 quantity, address receiver) internal onlyOwner {
        LandSpec memory land = landSpecs[size];
        require(totalSupplyBySize(size) + quantity <= land.maxSupply, "over supply");
        _safeMintLoop(size, quantity, receiver);        
    }

    function _safeMintLoop(Size size, uint256 quantity, address to) internal {
        for (uint256 i = 0; i < quantity; i++) {           
            uint256 tokenId = totalSupplyBySize(size) + getSpec(size).startingTokenId;
            increaseSupplyBySize(size);
            _safeMint(to, tokenId); 
        }
    }

    function getCounter(Size size) private view returns (Counters.Counter storage) {
        if (size == Size.Mega) {
            return _tokenIdCounterMegaLands;
        }
        if (size == Size.XLarge) {
            return _tokenIdCounterXLargeLands;
        }
        if (size == Size.Large) {
            return _tokenIdCounterLargeLands;
        }
        if (size == Size.Standard) {
            return _tokenIdCounterStandardLands;
        }
        revert("invalid size");        
    }

    function totalSupplyBySize(Size size) public view returns (uint) {
        return getCounter(size).current();
    }

    function increaseSupplyBySize(Size size) internal {
        getCounter(size).increment();
    }

    function maxSupplyBySize(Size size) public view returns (uint) {
        return getSpec(size).maxSupply;
    }

    function priceBySize(Size size) external view returns (uint) {
        return getSpec(size).price;
    }

    function withdraw(address receiver) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(receiver).transfer(balance);
    }
}