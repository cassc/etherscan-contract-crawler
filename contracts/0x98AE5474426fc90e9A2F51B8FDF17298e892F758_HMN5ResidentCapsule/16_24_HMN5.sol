// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";

contract HMN5 is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    mapping(uint256 => uint256) public steezyCloneLookup;
    mapping(uint256 => uint256) public cloneOf;
    mapping(address => uint256) public freeMintTracker;

    constructor(
        address steezyApeGangAddress,
        address okinaLabsAddress
    ) ERC721A("HMN5", "HMN5") {
       setSteezyApeGang(steezyApeGangAddress);
       setOkinaLabs(okinaLabsAddress);
    }

    function mint(uint256 quantity) external nonReentrant payable {
        require(mintEnabled, "Minting is not enabled");
        require(msg.sender == tx.origin, "No contracts");
        require(msg.value == mintPrice * quantity, "Invalid ETH Amount");
        require(quantity <= mintTransactionLimit, "Exceeds transaction limit");

        _mintTokens(msg.sender, quantity);
    }

    function specialMint(
        uint256 quantity, 
        uint256 totalFree, 
        bool presaleEligible,
        bool discountedPricing,
        bytes32[] calldata proof) external nonReentrant payable {
        
        require(quantity <= mintTransactionLimit, "Exceeds transaction limit");
        require(merkleRoot != bytes32(0), "Merkle root not set");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, totalFree, presaleEligible, discountedPricing))), "Invalid proof");
        require(mintEnabled || presaleEnabled && presaleEligible, "Not eligible to mint yet");
        
        if(totalFree > 0) {
            uint256 freeRemaining = totalFree - freeMintTracker[msg.sender];
            uint quantityPaid = freeRemaining >= quantity ? 0 : quantity - freeRemaining;
            uint256 freeAmount = quantity - quantityPaid;
            freeMintTracker[msg.sender] += freeAmount;
            if(quantityPaid > 0) {
                uint256 price = discountedPricing ? discountPrice : mintPrice;
                require(msg.value == price * quantityPaid, "Invalid ETH Amount");
            }
        } else {
            uint256 price = discountedPricing ? discountPrice : mintPrice;
            require(msg.value == price * quantity, "Invalid ETH Amount");
        }
        
        _mintTokens(msg.sender, quantity);
    }

    function clone(uint256[] calldata steezyTokenIds) external nonReentrant payable {    
        require(msg.sender == tx.origin, "No contracts");
        require(cloneEnabled, "Cloning is not enabled");
        uint256 quantity = steezyTokenIds.length;
        require(quantity <= cloneTransactionLimit, "Over clone transaction limit");
        require(msg.value == clonePrice * quantity, "Invalid ETH Amount");

        _burnPills(msg.sender, quantity);
        _setCloneData(msg.sender, steezyTokenIds);
        _mintTokens(msg.sender, quantity);
    }

    function specialClone(
        uint256[] calldata steezyTokenIds, 
        uint256 totalFree, 
        bool presaleEligible,
        bool discountedPricing,
        bytes32[] calldata proof) external nonReentrant payable {
            
        uint256 quantity = steezyTokenIds.length;
        require(quantity <= cloneTransactionLimit, "Exceeds transaction limit");
        require(merkleRoot != bytes32(0), "Merkle root not set");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, totalFree, presaleEligible, discountedPricing))), "Invalid proof");
        require(cloneEnabled || presaleEnabled && presaleEligible, "Not eligible to mint yet");
       
        uint256 freeRemaining = totalFree - freeMintTracker[msg.sender];
        uint quantityPaid = freeRemaining >= quantity ? 0 : quantity - freeRemaining;
        freeMintTracker[msg.sender] += quantity - quantityPaid;
        require(msg.value == discountPrice * quantityPaid, "Invalid ETH Amount");

        _burnPills(msg.sender, quantity);
        _setCloneData(msg.sender, steezyTokenIds);
        _mintTokens(msg.sender, quantity);
    }

    function pioneerClone(uint256[] calldata pioneerTokenIds, bytes32[][] calldata proofs) external nonReentrant {
        require(presaleEnabled || cloneEnabled, "Cannot clone yet");
        require(pioneerMerkleRoot != bytes32(0), "Merkle root not set");
        for(uint256 x = 0; x < proofs.length; x++) {
            uint256 pioneerTokenId = pioneerTokenIds[x];
            bytes32[] calldata proof = proofs[x];
            require(MerkleProof.verify(proof, pioneerMerkleRoot, keccak256(abi.encodePacked(pioneerTokenId))), "Invalid proof");
        }
        _burnPills(msg.sender, pioneerTokenIds.length);
        _setCloneData(msg.sender, pioneerTokenIds);
        _mintTokens(msg.sender, pioneerTokenIds.length);
    }
    
    function giftMint(address account, uint256 total) external onlyOwner {
        _mintTokens(account, total);
    }

    function giftClone(address account, uint256[] calldata steezyTokenIds) external onlyOwner {
        _setCloneData(account, steezyTokenIds);
        _mintTokens(account, steezyTokenIds.length);
    }

    function _setCloneData(address account, uint256[] calldata steezyTokenIds) internal {
        uint256 quantity = steezyTokenIds.length;
        for (uint256 i = 0; i < quantity; i++) {
            uint256 steezyTokenId = steezyTokenIds[i];
            require(steezyApeGang.ownerOf(steezyTokenId) == account, "You do not own this SteezyApeGang token");
            require(steezyCloneLookup[steezyTokenId] == 0, "This SteezyApeGang has already been cloned");
            uint256 nextId = _totalMinted() + i + 1;
            steezyCloneLookup[steezyTokenId] = nextId;
            cloneOf[nextId] = steezyTokenId;
        }
    }

    function _mintTokens(address account, uint256 quantity) internal {
        require(quantity > 0, "Quantity must be more than 0");
        require(_totalMinted() + quantity <= maxSupply, "Exceeds Supply");
        _mint(account, quantity);
    }

    function _burnPills(address account, uint256 quantity) internal {
        if(address(okinaLabs) != address(0)) {
            okinaLabs.burn(account, 1, quantity);
        }
    }

    IERC721 public steezyApeGang;
    function setSteezyApeGang(address steezyApeGangAddress) public onlyOwner {
        steezyApeGang = IERC721(steezyApeGangAddress);
    }

    ERC1155Burnable public okinaLabs;
    function setOkinaLabs(address okinaLabsAddress) public onlyOwner {
       okinaLabs = ERC1155Burnable(okinaLabsAddress);
    }

    bytes32 public merkleRoot;
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    bytes32 public pioneerMerkleRoot;
    function setPioneerMerkleRoot(bytes32 pioneerMerkleRoot_) external onlyOwner {
        pioneerMerkleRoot = pioneerMerkleRoot_;
    }

    uint256 public clonePrice = 0.0420 ether;
    function setClonePrice(uint256 clonePrice_) public onlyOwner {
        clonePrice = clonePrice_;
    }

    bool public cloneEnabled;
    function setCloneEnabled(bool cloneEnabled_) public onlyOwner {
        cloneEnabled = cloneEnabled_;
    }

    bool public presaleEnabled;
    function setPresaleEnabled(bool presaleEnabled_) public onlyOwner {
        presaleEnabled = presaleEnabled_;
    }

    uint256 public cloneTransactionLimit = 21;
    function setCloneTransactionLimit(uint256 cloneTransactionLimit_) public onlyOwner {
        cloneTransactionLimit = cloneTransactionLimit_;
    }

    uint256 public mintTransactionLimit = 21;
    function setMintTransactionLimit(uint256 mintTransactionLimit_) public onlyOwner {
        mintTransactionLimit = mintTransactionLimit_;
    }

    uint256 public mintPrice = 0.069 ether;
    function setMintPrice(uint256 mintPrice_) public onlyOwner {
        mintPrice = mintPrice_;
    }

    uint256 public discountPrice = 0.0420 ether;
    function setDiscountPrice(uint256 discountPrice_) public onlyOwner {
        discountPrice = discountPrice_;
    }

    bool public mintEnabled;
    function setMintEnabled(bool mintEnabled_) public onlyOwner {
        mintEnabled = mintEnabled_;
    }

    uint256 maxSupply = 8888;
    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        require(maxSupply_ < maxSupply, "Supply cannot be increased");
        maxSupply = maxSupply_;
    }

    function setCloneOf(uint256 tokenId, uint256 steezyApeGangTokenId) external onlyOwner {
        cloneOf[tokenId] = steezyApeGangTokenId;
        if(steezyApeGangTokenId == 0) {
            steezyCloneLookup[steezyApeGangTokenId] = 0;
        } else {
            steezyCloneLookup[steezyApeGangTokenId] = tokenId;
        }
    }

    string public baseURI = "";
    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    string public prerevealBaseURI = "";
    function setPrerevealBaseURI(string memory prerevealBaseUri_) external onlyOwner {
        prerevealBaseURI = prerevealBaseUri_;
    }

    function releaseFunds() external onlyOwner {
        Address.sendValue(payable(0x6569E6B8B90A2d9290Ea07Fe98E24aE393C71783), address(this).balance);
    }
    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        if(bytes(baseURI).length > 0) {
            return string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
        } else {
            if(cloneOf[_tokenId] > 0) {
                return bytes(prerevealBaseURI).length > 0 ? string(
                    abi.encodePacked(
                        prerevealBaseURI,
                        Strings.toString(_tokenId),
                        ".json?cloneOf=",
                        Strings.toString(cloneOf[_tokenId])
                    )
                ) : "";
            } else {
                return bytes(prerevealBaseURI).length > 0 ? string(
                    abi.encodePacked(
                        prerevealBaseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                ) : "";
            }
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}