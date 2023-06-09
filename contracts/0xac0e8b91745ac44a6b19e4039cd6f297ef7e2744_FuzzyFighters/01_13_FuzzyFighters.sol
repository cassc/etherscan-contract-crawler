// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FuzzyFighters is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;

    // ===== Variables =====
    address public constant DISBURSEMENT_WALLET = 0x75939AfEDCc483F2775ebB5A192b93127fA05891;
    string private _contractURI;
    string private _tokenBaseURI;
    uint256 public constant PRE_SALES_PRICE = 0.088 ether;
    uint256 public constant PUBLIC_SALES_PRICE = 0.088 ether;
    uint256 public constant TOTAL_COLLECTION_QTY = 2222;
    uint256 public constant PRESALE_MAX_QTY = 2000;
    uint256 public constant AIRDROP_MAX_QTY  = 50;
    uint256 public constant RESERVED_MAX_QTY  = 30;
    uint256 public constant SALES_MAX_QTY = TOTAL_COLLECTION_QTY - AIRDROP_MAX_QTY;
    uint256 public constant MAX_QTY_PER_MINTER = 2;
    uint256 public preSalesMintedQty; 
    uint256 public publicSalesMintedQty; 
    uint256 public giftMintedQty;
    uint256 public reservedMintedQty;

    bytes32 whitelistMerkleRoot;
    bytes32 reservedListMerkleRoot;

    enum Status {
        Pending,
        ReservedSale,
        PreSale,
        PublicSale,
        Finished
    }
    Status public status;

    mapping(address => uint256) public whitelistMintedAmount;
    mapping(address => uint256) public publicMintedAmount;
    mapping(address => bool) public reservedClaimed;

    // ===== Constructor =====
    constructor(bytes32 _whitelistMerkleRoot, bytes32 _reservedListMerkleRoot) ERC721A("Fuzzy Fighters", "FuzzyFighters") {
        whitelistMerkleRoot = _whitelistMerkleRoot;
        reservedListMerkleRoot = _reservedListMerkleRoot;
    }

    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier onlySender() {
        require(msg.sender == tx.origin, "caller is not the sender.");
        _;
    }

    function getPrice() public view returns (uint256) {
        
        if (status == Status.PreSale) {
          return PRE_SALES_PRICE;
        }

        return PUBLIC_SALES_PRICE;
    }


    // ===== Whitelist mint =====
    function presaleMint(bytes32[] memory proof,uint quantity,uint allowance) external payable onlySender nonReentrant {
        require(status == Status.PreSale, "The presale is not active.");
        require(_verify(whitelistMerkleRoot,_leaf(msg.sender, allowance), proof), "You are not Fuzzlisted.");
        require(preSalesMintedQty + publicSalesMintedQty + quantity  <= SALES_MAX_QTY, "Minting exceed the sale allocation.");
        require(preSalesMintedQty + quantity <= PRESALE_MAX_QTY, "Minting exceed the presale allocation.");
        require(whitelistMintedAmount[msg.sender] + quantity <= allowance, "Max allowance exceeded.");
        require(getPrice() * quantity == msg.value, "ETH sent not match with total purchase.");

        preSalesMintedQty += quantity;
        whitelistMintedAmount[msg.sender] += quantity;
        
        _safeMint(msg.sender, quantity);
    }


    function publicMint(uint quantity) external payable onlySender nonReentrant {
        require(status == Status.PublicSale, "The public sale is not active.");
        require(preSalesMintedQty + publicSalesMintedQty + quantity  <= SALES_MAX_QTY, "Minting exceed the sale allocation.");
        require(publicMintedAmount[msg.sender] + quantity <= MAX_QTY_PER_MINTER,
            "Minting amount exceeds allowance per wallet"
        );
        require(getPrice() * quantity == msg.value, "ETH sent not match with total purchase.");

        publicMintedAmount[msg.sender] += quantity;
        publicSalesMintedQty += quantity;
        
        _safeMint(msg.sender, quantity);
    }

    function reservedMint(bytes32[] memory proof) external onlySender nonReentrant {
        require(status == Status.ReservedSale, "The reserved mint is not active.");
        require(_verify(reservedListMerkleRoot,_leafReserved(msg.sender), proof), "You are not Fuzzlisted.");
        require(reservedMintedQty + giftMintedQty + 1 <= AIRDROP_MAX_QTY, "Minting exceed the airdrop allocation.");
        require(reservedMintedQty + 1 <= RESERVED_MAX_QTY, "Max supply reserved exceeded.");
        require(!reservedClaimed[msg.sender], "Address Already Claim.");

        reservedClaimed[msg.sender] = true;
        reservedMintedQty += 1;

        _safeMint(msg.sender, 1);
    }

    function gift(address recipient,uint quantity) external onlyOwner nonReentrant {
        require(
           reservedMintedQty + giftMintedQty + quantity <= AIRDROP_MAX_QTY,
            "Minting exceed the airdrop allocation."
        );

        giftMintedQty += quantity;

        _safeMint(recipient, quantity);
    }

    // ===== Setter (owner only) =====
    function setStatus(Status _status) external onlyOwner{
        status = _status;
    }

    function setWhitelistMintMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner{
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setReservedListMerkleRoot(bytes32 _reservedListMerkleRoot) external onlyOwner{
        reservedListMerkleRoot = _reservedListMerkleRoot;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function _baseURI() internal view override(ERC721A) returns (string memory){
        return _tokenBaseURI;
    }

    // ===== Withdraw to DISBURSEMENT_WALLET =====
    function withdraw() external onlyOwner {
        Address.sendValue(payable(DISBURSEMENT_WALLET), address(this).balance);
    }

    function tokensOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }

    function _leaf(address account, uint256 allowance)internal pure returns (bytes32){
        return keccak256(abi.encodePacked(account,allowance));
    }

    function _leafReserved(address account)internal pure returns (bytes32){
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) internal pure returns (bool){
        return MerkleProof.verify(proof, root, leaf);
    }

}