// SPDX-License-Identifier: MIT


// by: 0xQueue

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

error SaleNotStarted();
error SaleInProgress();
error InsufficientPayment();
error IncorrectPayment();
error AccountNotWhitelisted();
error AccountNotOglisted();
error AmountExceedsSupply();
error WhitelistAlreadyClaimed();
error AmountExceedsTransactionLimit();
error OnlyExternallyOwnedAccountsAllowed();
error InvalidToken();
error NotTokenIDOwner();
error SaleNotConcluded();

contract EtherRoom is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public wlMerkleRoot = 0xf56432d53b629e8f5988f00ddc7cc196fa72abcb48f8e9ef55e8adea2a69820a;
    bytes32 public freeMerkleRoot = 0xf56432d53b629e8f5988f00ddc7cc196fa72abcb48f8e9ef55e8adea2a69820a;

    uint256 public constant MAX_SUPPLY = 6666;
    uint256 private constant FAR_FUTURE = 0xFFFFFFFFF;
    uint256 private constant MAX_MINTS_PER_TX = 4;
    uint256 private constant MAX_MINTS_PER_WL_TX = 3;
    uint256 private constant MAX_MINTS_PER_FREE_TX = 1;

    uint256 private _wlSaleStart = FAR_FUTURE;
    uint256 private _freeSaleStart = FAR_FUTURE;
    uint256 private _publicSaleStart = FAR_FUTURE;
    uint256 private _marketingSupply = 250;
    uint256 private _salePrice = 0.025 ether;

    bool private _saleConcluded = false;

    string private _baseTokenURI = "https://etherroom.mypinata.cloud/ipfs/QmUUJMrF57yPhSKfqYTFv5kwUWkEfRKUNr2vw5eDFHdZiu/";
    mapping(address => bool) private _mintedWhitelist;
    mapping(address => bool) private _mintedFree;

    event PresaleStart(uint256 price, uint256 supplyRemaining);
    event FreesaleStart(uint256 price, uint256 supplyRemaining);
    event PublicSaleStart(uint256 price, uint256 supplyRemaining);
    event SalePaused();

    constructor() ERC721A("EtherRoom", "ETHRM") { }

    // WHITELIST PRESALE
    function isPresaleActive() public view returns (bool) {
        return block.timestamp > _wlSaleStart;
    }

    function isFreeSaleActive() public view returns (bool) {
        return block.timestamp > _freeSaleStart;
    }

    function freeSaleMint(bytes32[] calldata _merkleProof) external nonReentrant onlyEOA {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!isFreeSaleActive())                                     revert SaleNotStarted();
        if (!MerkleProof.verify(_merkleProof, freeMerkleRoot, leaf)) revert AccountNotWhitelisted();
        if (hasMintedFreesale(msg.sender))                           revert WhitelistAlreadyClaimed();
        if (totalSupply() + MAX_MINTS_PER_FREE_TX > MAX_SUPPLY)  revert AmountExceedsSupply();
    
        _mintedFree[msg.sender] = true;
        _safeMint(msg.sender, MAX_MINTS_PER_FREE_TX);
    }

    function presaleMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable nonReentrant onlyEOA {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!isPresaleActive())                                     revert SaleNotStarted();
        if (!MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf))  revert AccountNotWhitelisted();
        if (hasMintedPresale(msg.sender))                           revert WhitelistAlreadyClaimed();
        if (quantity > MAX_MINTS_PER_WL_TX)                         revert AmountExceedsTransactionLimit();
        if (totalSupply() + quantity > MAX_SUPPLY)                  revert AmountExceedsSupply();
        if (msg.value < getSalePrice() * quantity)                  revert IncorrectPayment();

        _mintedWhitelist[msg.sender] = true;
        _safeMint(msg.sender, quantity);
    }

    function hasMintedPresale(address account) public view returns (bool) {
        return _mintedWhitelist[account];
    }

    function hasMintedFreesale(address account) public view returns (bool) {
        return _mintedFree[account];
    }

    // PUBLIC SALE
    function isPublicSaleActive() public view returns (bool) {
        return block.timestamp > _publicSaleStart;
    }

    function publicMint(uint256 quantity) external payable nonReentrant onlyEOA {
        if (!isPublicSaleActive())                  revert SaleNotStarted();
        if (totalSupply() + quantity > MAX_SUPPLY)  revert AmountExceedsSupply();
        if (msg.value < getSalePrice() * quantity)  revert IncorrectPayment();
        if (quantity > MAX_MINTS_PER_TX)            revert AmountExceedsTransactionLimit();

        _safeMint(msg.sender, quantity);
    }

    // METADATA
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        wlMerkleRoot = root;
    }

    function setFreeMerkleRoot(bytes32 root) external onlyOwner {
        freeMerkleRoot = root;
    }

    function startFreesale() external onlyOwner {
        if (isPublicSaleActive()) revert SaleInProgress();

        _freeSaleStart = block.timestamp;

        emit FreesaleStart(getSalePrice(), MAX_SUPPLY - totalSupply());
    }

    function startPresale() external onlyOwner {
        if (isPublicSaleActive()) revert SaleInProgress();

        _wlSaleStart = block.timestamp;

        emit PresaleStart(getSalePrice(), MAX_SUPPLY - totalSupply());
    }

    function startPublicSale() external onlyOwner {
        if (isPresaleActive() || isFreeSaleActive()) revert SaleInProgress();

        _publicSaleStart = block.timestamp;

        emit PublicSaleStart(getSalePrice(), MAX_SUPPLY - totalSupply());
    }

    function pauseSale() external onlyOwner {
        _wlSaleStart = FAR_FUTURE;
        _publicSaleStart = FAR_FUTURE;

        emit SalePaused();
    }

    function pauseFreeSale() external onlyOwner {
        _freeSaleStart = FAR_FUTURE; 

        emit SalePaused();
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert OnlyExternallyOwnedAccountsAllowed();
        _;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), '.json'));
    }

    // BURNING
    function burnToken(uint256 tokenId) external {
        if (isPresaleActive() || isPublicSaleActive()) revert SaleInProgress();
        if (msg.sender != ownerOf(tokenId)) revert NotTokenIDOwner();
        if (!_saleConcluded) revert SaleNotConcluded();

        _burn(tokenId);
    }

    function concludeSale(bool conclude) external onlyOwner {
        if (isPresaleActive() || isPublicSaleActive()) revert SaleInProgress();

        _saleConcluded = conclude;
    }


    // TEAM
    function marketingMint(uint256 quantity) external onlyOwner {
        if (quantity > _marketingSupply)           revert AmountExceedsSupply();
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();

        _marketingSupply -= quantity;
        _safeMint(owner(), quantity);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}