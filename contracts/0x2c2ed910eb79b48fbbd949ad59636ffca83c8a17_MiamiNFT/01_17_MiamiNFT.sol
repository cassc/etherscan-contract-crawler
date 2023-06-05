//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract MiamiNFT is ERC721A, Ownable, ReentrancyGuard, VRFConsumerBase {

    // Type Declarations
    struct VipMerkleRoots {
        bytes32 first;
        bytes32 second;
    }
    
    struct VrfConstructorParameters {
        address coordinator;
        address linkToken;
        bytes32 keyHash;
        uint256 fee;
    }

    // State Variables
    uint256 public immutable MAX_MINT_PER_BLOCK = 100;

    bytes32 public firstVipMerkleRoot;
    bytes32 public secondVipMerkleRoot;
    string private _baseTokenURI;

    bytes32 public immutable keyHash;
    uint256 public immutable fee;
    uint256 public immutable totalLimit;
    uint256 public immutable saleLimitPerAddress;
    uint256 public start;
    uint256 public immutable firstVipTotalLimit;
    uint256 public firstVipDuration;
    uint256 public secondVipDuration;
    bytes32 public provenanceHash;
    uint256 public priceInWeiFirstPresale;
    uint256 public priceInWeiSecondPresale;
    uint256 public priceInWeiPublicSale;
    uint256 public firstVipMinted;
    uint256 public remainingOwnerMintableAmount;
    uint256 public startingIndex;
    bool public isOwnerClaimActive;
    bool public isStartingIndexRequested;
    bool public active = true;

    // Mappings
    mapping (address => uint8) public purchasedByAddress;

    // Events
    event StartingIndexSet(uint256 startingIndex);
    event TokenMint(address indexed target, uint256 amount);
    event ActiveSet(bool active);
    event DurationSet(uint256 start, uint256 firstVipDuration, uint256 secondVipDuration);

    // Modifiers
    modifier onlyActive() {
        require(active, "Inactive");
        _;
    }

    modifier onlyInactive() {
        require(!active, "Public sale is active");
        _;
    }

    modifier onlyPublicSale(uint256 _amount) {
        require(msg.sender == tx.origin, "Buyer must be EOA");
        uint256 secondVipEnd = start + firstVipDuration + secondVipDuration;
        require(block.timestamp > secondVipEnd, "Public sale hasn't started");
        require(purchasedByAddress[msg.sender] + _amount <= saleLimitPerAddress, "Maximum mintable amount exceed");
        _;
    }

    modifier onlyAllowListed(bytes32[] calldata _merkleProof, uint8 _amount) {
        uint256 firstVipEnd = start + firstVipDuration;

        if(block.timestamp < start || block.timestamp > firstVipEnd + secondVipDuration) {
            revert("AllowList sale hasn't started or finished already");
        }

        require(purchasedByAddress[msg.sender] + _amount <= saleLimitPerAddress, "Maximum mintable amount exceed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if(block.timestamp >= start && block.timestamp <= firstVipEnd) {
            firstVipMinted += _amount;
            require(firstVipMinted <= firstVipTotalLimit, "Maximum mintable amount exceed");
            require(MerkleProof.verify(_merkleProof, firstVipMerkleRoot, leaf), "Not allowListed");
        } else if(block.timestamp > firstVipEnd && block.timestamp <= firstVipEnd + secondVipDuration) {
            require(MerkleProof.verify(_merkleProof, secondVipMerkleRoot, leaf), "Not allowListed");
        } 
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256[3] memory _pricesInWei,
        uint256[4] memory _limits,
        uint256 _start,
        uint256 _firstVipDuration,
        uint256 _secondVipDuration,
        VipMerkleRoots memory vipMerkleRoots,
        bytes32 _provenanceHash,
        VrfConstructorParameters memory vrf
    ) ERC721A(name, symbol) VRFConsumerBase(vrf.coordinator, vrf.linkToken) {
        require(_limits[2] + _limits[3] <= _limits[0], "Sum of limits must not be bigger then total limit");

        _baseTokenURI = baseTokenURI;
        priceInWeiFirstPresale = _pricesInWei[0];
        priceInWeiSecondPresale = _pricesInWei[1];
        priceInWeiPublicSale = _pricesInWei[2];
        totalLimit = _limits[0];
        saleLimitPerAddress = _limits[1];
        firstVipTotalLimit = _limits[2];
        remainingOwnerMintableAmount = _limits[3];
        start = _start;
        firstVipDuration = _firstVipDuration;
        secondVipDuration = _secondVipDuration;
        firstVipMerkleRoot = vipMerkleRoots.first;
        secondVipMerkleRoot = vipMerkleRoots.second;
        provenanceHash = _provenanceHash;
        keyHash = vrf.keyHash;
        fee = vrf.fee;
    }

    // External Functions
    function flipActive() external onlyOwner {
        active = !active;
        emit ActiveSet(active);
    }

    function flipOwnerClaimActive() external onlyOwner {
        isOwnerClaimActive = !isOwnerClaimActive;
    }

    function setFirstVipMerkleRoot(bytes32 _firstVipMerkleRoot) external onlyOwner {
        firstVipMerkleRoot = _firstVipMerkleRoot;
    }

    function setPriceFirstPresale(uint256 _priceInWei) external onlyOwner {
        priceInWeiFirstPresale = _priceInWei;
    }

    function setSecondVipMerkleRoot(bytes32 _secondVipMerkleRoot) external onlyOwner {
        secondVipMerkleRoot = _secondVipMerkleRoot;
    }

    function setPriceSecondPresale(uint256 _priceInWei) external onlyOwner {
        priceInWeiSecondPresale = _priceInWei;
    }

    function setPricePublicSale(uint256 _priceInWei) external onlyOwner {
        priceInWeiPublicSale = _priceInWei;
    }

    function setDurationValues(uint256 _start, uint256 _firstVipDuration, uint256 _secondVipDuration) external onlyOwner {
        start = _start;
        firstVipDuration = _firstVipDuration;
        secondVipDuration = _secondVipDuration;

        emit DurationSet(start, firstVipDuration, secondVipDuration);
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setProvenanceHash(bytes32 _provenanceHash) external onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function buyTokensFromAllowList(bytes32[] calldata _merkleProof, uint8 _amount) external payable onlyAllowListed(_merkleProof, _amount) {
        buyTokens(_amount);
    }

    function buyTokensFromPublicSale(uint8 _amount) external payable onlyPublicSale(_amount) {
        buyTokens(_amount);
    }

    function mintUnsold(address _to, uint256 _amount) external onlyOwner onlyInactive {
        require(_amount <= MAX_MINT_PER_BLOCK, "Amount cannot exceed MAX_MINT_PER_BLOCK");
        require(totalSupply() + _amount <= totalLimit, "Global limit amount reached");

        _safeMint(_to, _amount);
        emit TokenMint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function ownerClaim(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= MAX_MINT_PER_BLOCK, "Amount cannot exceed MAX_MINT_PER_BLOCK");
        require(isOwnerClaimActive, "Claim by owner is not active");
        require(_amount <= remainingOwnerMintableAmount, "Owner mintable amount limit reached");

        remainingOwnerMintableAmount -= _amount;
        _safeMint(_to, _amount);
    }

    function requestRandomness() external onlyOwner returns (bytes32 requestId) {
        require(!isStartingIndexRequested, "Starting Index already requested");
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        isStartingIndexRequested = true;
        return requestRandomness(keyHash, fee);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    // Internal Functions
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        startingIndex = randomness % totalSupply();
        emit StartingIndexSet(startingIndex);
    }

    // Private Functions
    function buyTokens(uint8 _amount) private onlyActive nonReentrant {
        require(_amount > 0, "Invalid amount of NFT");
        uint256 mintPrice = getPrice() * _amount;
        require(msg.value >= mintPrice, "There is not enough funds to buy NFT");
        require(totalSupply() + _amount <= totalLimit, "Global limit amount reached");

        purchasedByAddress[msg.sender] += _amount;

        if(msg.value - mintPrice > 0) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }

        _safeMint(msg.sender, _amount);
        emit TokenMint(msg.sender, _amount);
    }

    
    function getPrice() private view returns(uint256) {
        // First Vip Sale
        uint256 firstVipEnd = start + firstVipDuration;
        if(block.timestamp >= start && block.timestamp <= firstVipEnd){
            return priceInWeiFirstPresale;
        } 
        // Second Vip Sale
        if(block.timestamp > firstVipEnd && block.timestamp <= firstVipEnd + secondVipDuration) {
            return priceInWeiSecondPresale;
        }

        // Public sale
        return priceInWeiPublicSale;
    }
}