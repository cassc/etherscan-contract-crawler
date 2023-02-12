//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//  ▒█████   ██▀███  ▓█████▄  ██▓ ███▄    █  ▄▄▄       ██▓        ▄▄▄▄   ▓█████ ▄▄▄       ██▀███    ██████ 
// ▒██▒  ██▒▓██ ▒ ██▒▒██▀ ██▌▓██▒ ██ ▀█   █ ▒████▄    ▓██▒       ▓█████▄ ▓█   ▀▒████▄    ▓██ ▒ ██▒▒██    ▒ 
// ▒██░  ██▒▓██ ░▄█ ▒░██   █▌▒██▒▓██  ▀█ ██▒▒██  ▀█▄  ▒██░       ▒██▒ ▄██▒███  ▒██  ▀█▄  ▓██ ░▄█ ▒░ ▓██▄   
// ▒██   ██░▒██▀▀█▄  ░▓█▄   ▌░██░▓██▒  ▐▌██▒░██▄▄▄▄██ ▒██░       ▒██░█▀  ▒▓█  ▄░██▄▄▄▄██ ▒██▀▀█▄    ▒   ██▒
// ░ ████▓▒░░██▓ ▒██▒░▒████▓ ░██░▒██░   ▓██░ ▓█   ▓██▒░██████▒   ░▓█  ▀█▓░▒████▒▓█   ▓██▒░██▓ ▒██▒▒██████▒▒
// ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░ ▒▒▓  ▒ ░▓  ░ ▒░   ▒ ▒  ▒▒   ▓▒█░░ ▒░▓  ░   ░▒▓███▀▒░░ ▒░ ░▒▒   ▓▒█░░ ▒▓ ░▒▓░▒ ▒▓▒ ▒ ░
//   ░ ▒ ▒░   ░▒ ░ ▒░ ░ ▒  ▒  ▒ ░░ ░░   ░ ▒░  ▒   ▒▒ ░░ ░ ▒  ░   ▒░▒   ░  ░ ░  ░ ▒   ▒▒ ░  ░▒ ░ ▒░░ ░▒  ░ ░
// ░ ░ ░ ▒    ░░   ░  ░ ░  ░  ▒ ░   ░   ░ ░   ░   ▒     ░ ░       ░    ░    ░    ░   ▒     ░░   ░ ░  ░  ░  
//     ░ ░     ░        ░     ░           ░       ░  ░    ░  ░    ░         ░  ░     ░  ░   ░           ░  
//                    ░                                                ░                                   

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract OrdinalBears is ERC721A, ERC2981, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    bytes32 private HOLDER_MERKLE_ROOT;
    bytes32 private COLLAB_MERKLE_ROOT;
     string private BASE_URI;

    uint256 public PRICE = 0.02 ether;
    uint256 public MAX_SUPPLY = 1111;
    uint256 public MAX_MINT_FOR_PUBLIC = 5;
    uint256 public MINT_PHASE = 0;
    uint256 public BURN_FEE = 0.001 ether;
       bool public BURN_ACTIVE = false;

    event OrdinalBearBurnt(uint256 indexed tokenId, string indexed bitcoinAddress);

    mapping(address => uint256) private holderMinters;
    mapping(address => uint256) private collabMinters;
    mapping(address => uint256) private publicMinters;
    
    mapping(uint256 => string) public tokenIdToBTCAddress;
    mapping(uint256 => string) public tokenIdToInscription;

    constructor(address royaltyReceiver) ERC721A("ordinal bears", "ordb") {
        _setDefaultRoyalty(royaltyReceiver, 500);
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "ordb: contract calls not allowed.");
        _;
    }
    
    modifier validateMint() {
        require(MINT_PHASE > 0, "ordb: mint is not live.");
        require(_totalMinted() + 1 <= MAX_SUPPLY, "ordb: sold out.");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function holderMint(uint256 quantity, uint256 allocation, bytes32[] calldata proof) external payable nonReentrant callerIsUser validateMint {
        require(MINT_PHASE == 1, "ordb: holder mint is not live.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "ordb: quantity will exceed supply.");
        require(MerkleProof.verify(proof, HOLDER_MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender, allocation))), "ordb: invalid proof.");
        require(holderMinters[msg.sender] + 1 <= allocation, "ordb: already max minted allowlist allocation.");
        require(holderMinters[msg.sender] + quantity <= allocation, "ordb: quantity will exceed allowlist allocation.");
        require(msg.value == PRICE * quantity, "ordb: incorrect ether value.");
        
        holderMinters[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function allowlistMint(uint256 quantity, uint256 allocation, bytes32[] calldata proof) external payable nonReentrant callerIsUser validateMint {
        require(MINT_PHASE == 2, "ordb: allowlist mint is not live.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "ordb: quantity will exceed supply.");
        require(MerkleProof.verify(proof, COLLAB_MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender, allocation))), "ordb: invalid proof.");
        require(collabMinters[msg.sender] + 1 <= allocation, "ordb: already max minted allowlist allocation.");
        require(collabMinters[msg.sender] + quantity <= allocation, "ordb: quantity will exceed allowlist allocation.");
        require(msg.value == PRICE * quantity, "ordb: incorrect ether value.");
        
        collabMinters[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable nonReentrant callerIsUser validateMint {
        require(MINT_PHASE == 3, "ordb: public mint is not live.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "ordb: quantity will exceed supply.");
        require(publicMinters[msg.sender] + 1 <= MAX_MINT_FOR_PUBLIC, "ordb: already max minted.");
        require(publicMinters[msg.sender] + quantity <= MAX_MINT_FOR_PUBLIC, "ordb: quantity will exceed max mints.");
        require(msg.value == PRICE * quantity, "ordb: incorrect ether value.");

        publicMinters[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(_totalMinted() + 1 <= MAX_SUPPLY, "ordb: sold out.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "ordb: quantity will exceed supply.");
        _mint(msg.sender, quantity);
    }

    function burn(uint256 tokenId, string memory bitcoinAddress) external payable nonReentrant callerIsUser {
        require(BURN_ACTIVE, "ordb: burning is disabled.");
        require(msg.value == BURN_FEE, "ordb: must send correct amount of ether for the burn fee.");

        tokenIdToBTCAddress[tokenId] = bitcoinAddress;
        _burn(tokenId, true);

        emit OrdinalBearBurnt(tokenId, bitcoinAddress);
    }

    function burnMany(uint256[] memory tokenIds, string[] memory bitcoinAddresses) external payable nonReentrant callerIsUser {
        require(BURN_ACTIVE, "ordb: burning is disabled.");
        require(msg.value >= BURN_FEE * tokenIds.length, "ordb: must send correct amount of ether for the burn fee.");

        for (uint i=0; i < tokenIds.length; i++) {
          tokenIdToBTCAddress[tokenIds[i]] = bitcoinAddresses[i];
          _burn(tokenIds[i], true);
          emit OrdinalBearBurnt(tokenIds[i], bitcoinAddresses[i]);
        }
    }

    function setRoyalty(address receiver, uint96 value) external onlyOwner {
        _setDefaultRoyalty(receiver, value);
    }

    function setHolderMerkleRoot(bytes32 newHolderMerkleRoot) external onlyOwner {
        HOLDER_MERKLE_ROOT = newHolderMerkleRoot;
    }

    function setCollabMerkleRoot(bytes32 newCollabMerkleRoot) external onlyOwner {
        COLLAB_MERKLE_ROOT = newCollabMerkleRoot;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        BASE_URI = newBaseURI;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        MAX_SUPPLY = newMaxSupply;
    }

    function setMaxMintForPublic(uint256 newMaxMintForPublic) external onlyOwner {
        MAX_MINT_FOR_PUBLIC = newMaxMintForPublic;
    }

    function setMintPhase(uint256 newMintPhase) external onlyOwner {
        MINT_PHASE = newMintPhase;
    }

    function setBurnFee(uint256 newBurnFee) external onlyOwner {
        BURN_FEE = newBurnFee;
    }

    function setBurnStatus(bool newBurnStatus) external onlyOwner {
        BURN_ACTIVE = newBurnStatus;
    }

    function setInscriptions(uint256[] memory tokenIds, string[] memory inscriptions) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenIdToInscription[tokenIds[i]] = inscriptions[i];
        }
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}