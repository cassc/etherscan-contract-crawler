// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "./HMN5.sol";

contract HMN5ResidentCapsule is ERC721ABurnable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    mapping(address => uint256) public freeMintTracker;
    mapping(address => uint256) public reservedMintTracker;
    mapping(address => uint256) public freeHmn5Tracker;
    mapping(address => uint256) public paidHmn5Tracker;

    constructor() ERC721A("HMN5 Resident Capsule", "RC") {
    }

    function hmn5Mint(uint256[] memory tokenIds) external payable nonReentrant {
        uint256 quantity = tokenIds.length;
        require(createHmn5Enabled, "Mint is not enabled yet");
        require(quantity <= hmn5MintTransactionLimit, "Over transaction limit");
        require(msg.sender == tx.origin, "No contracts");
        require(msg.value == hmn5Price * quantity, "Invalid ETH Amount");

        for(uint256 x = 0; x < quantity; x++) {
            burn(tokenIds[x]);
        }

        _mintHmn5(msg.sender, quantity);
    }

    function reservedHmn5Mint(uint256[] memory tokenIds, uint256 freeLimit, uint256 paidLimit, uint256 price, bytes32[] memory proof) external payable nonReentrant {
        uint256 quantity = tokenIds.length;
        uint256 quantityPaid;
        require(reservedHmn5MintEnabled, "Mint is not enabled");
        require(quantity <= hmn5MintTransactionLimit, "Over transaction limit");
        require(createHmn5MerkleRoot != bytes32(0), "Merkle root not set");
        require(MerkleProof.verify(proof, createHmn5MerkleRoot, keccak256(abi.encodePacked(msg.sender, freeLimit, paidLimit, price))), "Invalid proof");

        if(freeLimit > 0) {
            uint256 freeRemaining = freeLimit - freeHmn5Tracker[msg.sender];
            quantityPaid = freeRemaining >= quantity ? 0 : quantity - freeRemaining;
            uint256 freeAmount = quantity - quantityPaid;
            freeHmn5Tracker[msg.sender] += freeAmount;
        } else {
            quantityPaid = quantity;
        }

        if(quantityPaid > 0) {
            require(paidHmn5Tracker[msg.sender] + quantityPaid <= paidLimit, "Exceeds amount you are eligible to purchase");
            require(msg.value == price * quantityPaid, "Invalid ETH Amount");
            paidHmn5Tracker[msg.sender] += quantityPaid;
        }
     
        for(uint256 x = 0; x < quantity; x++) {
            burn(tokenIds[x]);
        }

        _mintHmn5(msg.sender, quantity);
    }
    
    function freeMint(uint256 quantity) external nonReentrant {
        require(mintEnabled, "Minting is not enabled");
        require(msg.sender == tx.origin, "No contracts");
        require(quantity <= mintTransactionLimit, "Exceeds transaction limit");
        require(freeMintTracker[msg.sender] + quantity <= walletLimit, "Exceeds wallet limit");
        freeMintTracker[msg.sender] += quantity;
        _mintTokens(msg.sender, quantity);
    }

    function reservedMint( 
        uint256 quantity,
        uint256 totalReserved,
        bytes32[] calldata proof) external nonReentrant {
        
        require(merkleRoot != bytes32(0), "Merkle root not set");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, totalReserved))), "Invalid proof");
        require(reservedMintTracker[msg.sender] + quantity <= totalReserved, "You have no more tokens left to claim");
        require(reservedMintEnabled, "Not eligible to mint yet");
        
        reservedMintTracker[msg.sender] += quantity;

        _mintTokens(msg.sender, quantity);
    }

    function _mintTokens(address account, uint256 quantity) internal {
        require(quantity > 0, "Quantity must be more than 0");
        require(_totalMinted() + quantity <= maxSupply, "Exceeds Supply");
        _mint(account, quantity);
    }

    function _mintHmn5(address account, uint256 quantity) internal {
        if(hmn5.owner() == address(this)) {
            hmn5.giftMint(account, quantity);
            currentHmn5TokenId += quantity;
        } else {
            hmn5.specialMint(quantity, 0, true, false, hmn5Proof);
            for(uint256 x = 0; x < quantity; x++) {
                hmn5.transferFrom(address(this), account, ++currentHmn5TokenId);
            }
        }
    }

    function giftMint(address account, uint256 total) external onlyOwner {
        _mintTokens(account, total);
    }

    function giftHmn5Mint(address account, uint256 total) external onlyOwner {
        hmn5.giftMint(account, total);
    }

    HMN5 public hmn5;
    function setHmn5(address addr_) public onlyOwner{
        hmn5 = HMN5(addr_);
    }

    bytes32[] public hmn5Proof;
    function setHmn5Proof(bytes32[] calldata proof_) public onlyOwner {
        hmn5Proof = proof_;
    }

    function returnHmn5Ownership() external onlyOwner {
        hmn5.transferOwnership(0xFCb55C98c6D6D30B805CC388dc18468e01F5773B);
    }

    bytes32 public merkleRoot;
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    bytes32 public createHmn5MerkleRoot;
    function setCreateHmn5MerkleRoot(bytes32 createHmn5MerkleRoot_) external onlyOwner {
        createHmn5MerkleRoot = createHmn5MerkleRoot_;
    }

    uint256 public hmn5Price = 0.069 ether;
    function setHmn5Price(uint256 hmn5Price_) public onlyOwner {
        hmn5Price = hmn5Price_;
    }

    bool public reservedMintEnabled;
    function setReservedMintEnabled(bool reservedMintEnabled_) public onlyOwner {
        reservedMintEnabled = reservedMintEnabled_;
    }

    uint256 public lastTokenId;
    function setLastTokenId(uint256 lastTokenId_) public onlyOwner {
        lastTokenId = lastTokenId_;
    }

    bool public createHmn5Enabled;
    function setCreateHmn5Enabled(bool createHmn5Enabled_) public onlyOwner {
        createHmn5Enabled = createHmn5Enabled_;
    }

    bool public reservedHmn5MintEnabled;
    function setReservedHmn5MintEnabled(bool reservedHmn5MintEnabled_) public onlyOwner {
        reservedHmn5MintEnabled = reservedHmn5MintEnabled_;
    }

    uint256 public mintTransactionLimit = 21;
    function setMintTransactionLimit(uint256 mintTransactionLimit_) public onlyOwner {
        mintTransactionLimit = mintTransactionLimit_;
    }

    uint256 public hmn5MintTransactionLimit = 21;
    function setHmn5MintTransactionLimit(uint256 hmn5MintTransactionLimit_) public onlyOwner {
        hmn5MintTransactionLimit = hmn5MintTransactionLimit_;
    }

    uint256 public currentHmn5TokenId = 0;
    function setCurrentHmn5TokenId(uint256 currentHmn5TokenId_) public onlyOwner {
        currentHmn5TokenId = currentHmn5TokenId_;
    }

    uint256 public walletLimit = 42;
    function setWalletLimit(uint256 walletLimit_) public onlyOwner {
        walletLimit = walletLimit_;
    }

    bool public mintEnabled;
    function setMintEnabled(bool mintEnabled_) public onlyOwner {
        mintEnabled = mintEnabled_;
    }

    uint256 maxSupply = 4444;
    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        require(maxSupply_ < maxSupply, "Supply cannot be increased");
        maxSupply = maxSupply_;
    }

    string public baseURI = "";
    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }

    function releaseFunds() external onlyOwner {
        Address.sendValue(payable(0x6569E6B8B90A2d9290Ea07Fe98E24aE393C71783), address(this).balance);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}