// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Land is ERC721Enumerable, Ownable, ReentrancyGuard, VRFConsumerBase {
    using SafeERC20 for IERC20;

    // attributes
    string private baseURI;
    address public operator;

    bool public publicSaleActive;
    uint256 public publicSaleStartTime;
    uint256 public publicSalePriceLoweringDuration;
    uint256 public publicSaleStartPrice;
    uint256 public publicSaleEndingPrice;
    uint256 public currentNumLandsMintedPublicSale;
    uint256 public mintIndexPublicSaleAndContributors;
    address public tokenContract;
    bool private isKycCheckRequired;
    bytes32 public kycMerkleRoot;

    uint256 public maxMintPerTx;
    uint256 public maxMintPerAddress;
    mapping(address => uint256) public mintedPerAddress;

    bool public claimableActive; 
    bool public adminClaimStarted;
    
    address public alphaContract; 
    mapping(uint256 => bool) public alphaClaimed;
    uint256 public alphaClaimedAmount;

    address public betaContract; 
    mapping(uint256 => bool) public betaClaimed;
    uint256 public betaClaimedAmount;
    uint256 public betaNftIdCurrent;

    bool public contributorsClaimActive;
    mapping(address => uint256) public contributors;
    uint256 public futureLandsNftIdCurrent;

    address public futureMinter;

    Metadata[] public metadataHashes;
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public publicSaleAndContributorsOffset;
    uint256 public alphaOffset;
    uint256 public betaOffset;
    mapping(bytes32 => bool) public isRandomRequestForPublicSaleAndContributors;
    bool public publicSaleAndContributorsRandomnessRequested;
    bool public ownerClaimRandomnessRequested;
    
    // constants
    uint256 immutable public MAX_LANDS;
    uint256 immutable public MAX_LANDS_WITH_FUTURE;
    uint256 immutable public MAX_ALPHA_NFT_AMOUNT;
    uint256 immutable public MAX_BETA_NFT_AMOUNT;
    uint256 immutable public MAX_PUBLIC_SALE_AMOUNT;
    uint256 immutable public RESERVED_CONTRIBUTORS_AMOUNT;
    uint256 immutable public MAX_FUTURE_LANDS;
    uint256 constant public MAX_MINT_PER_BLOCK = 150;

    // structs
    struct LandAmount {
        uint256 alpha;
        uint256 beta;
        uint256 publicSale;
        uint256 future;
    }
    struct ContributorAmount {
        address contributor;
        uint256 amount;
    }

    struct Metadata {
        bytes32 metadataHash;
        bytes32 shuffledArrayHash;
        uint256 startIndex;
        uint256 endIndex;
    }

    struct ContractAddresses {
        address alphaContract;
        address betaContract;
        address tokenContract;
    }

    // modifiers
    modifier whenPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }
    modifier whenContributorsClaimActive() {
        require(contributorsClaimActive, "Contributors Claim is not active");
        _;
    }
    modifier whenClaimableActive() {
        require(claimableActive && !adminClaimStarted, "Claimable state is not active");
        _;
    }
    modifier checkMetadataRange(Metadata memory _landMetadata){
        require(_landMetadata.endIndex < MAX_LANDS_WITH_FUTURE, "Range upper bound cannot exceed MAX_LANDS_WITH_FUTURE - 1");
        _;
    }

    modifier onlyContributors(address _contributor){
        require(contributors[_contributor] > 0, "Only contributors can call this method");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender , "Only operator can call this method");
        _;
    }

    modifier onlyFutureMinter() {
        require(futureMinter == msg.sender , "Only futureMinter can call this method");
        _;
    }

    modifier checkFirstMetadataRange(uint256 index, uint256 startIndex, uint256 endIndex) {
        if(index == 0){
            require(startIndex == 0, "For first metadata range lower bound should be 0");
            require(endIndex == MAX_LANDS - 1, "For first metadata range upper bound should be MAX_LANDS - 1");
        }
        _;
    }

    // events
    event LandPublicSaleStart(
        uint256 indexed _saleDuration,
        uint256 indexed _saleStartTime
    );
    event LandPublicSaleStop(
        uint256 indexed _currentPrice,
        uint256 indexed _timeElapsed
    );
    event ClaimableStateChanged(bool indexed claimableActive);

    event ContributorsClaimStart(uint256 _timestamp);
    event ContributorsClaimStop(uint256 _timestamp);

    event StartingIndexSetPublicSale(uint256 indexed _startingIndex);
    event StartingIndexSetAlphaBeta(uint256 indexed _alphaOffset, uint256 indexed _betaOffset);

    event PublicSaleMint(address indexed sender, uint256 indexed numLands, uint256 indexed mintPrice);

    constructor(string memory name, string memory symbol,
        ContractAddresses memory addresses,
        LandAmount memory amount,
        ContributorAmount[] memory _contributors,
        address _vrfCoordinator, address _linkTokenAddress,
        bytes32 _vrfKeyHash, uint256 _vrfFee,
        address _operator
    ) ERC721(name, symbol) VRFConsumerBase(_vrfCoordinator, _linkTokenAddress) {

        alphaContract = addresses.alphaContract;
        betaContract = addresses.betaContract;
        tokenContract = addresses.tokenContract;

        MAX_ALPHA_NFT_AMOUNT = amount.alpha;
        MAX_BETA_NFT_AMOUNT = amount.beta;
        MAX_PUBLIC_SALE_AMOUNT = amount.publicSale;
        MAX_FUTURE_LANDS = amount.future;

        betaNftIdCurrent = amount.alpha; //beta starts after alpha
        mintIndexPublicSaleAndContributors = amount.alpha + amount.beta; //public sale starts after beta

        uint256 tempSum;
        for(uint256 i; i<_contributors.length; ++i){
            contributors[_contributors[i].contributor] = _contributors[i].amount;
            tempSum += _contributors[i].amount;
        }
        RESERVED_CONTRIBUTORS_AMOUNT = tempSum;

        MAX_LANDS = amount.alpha + amount.beta + amount.publicSale + RESERVED_CONTRIBUTORS_AMOUNT;
        MAX_LANDS_WITH_FUTURE = MAX_LANDS + amount.future;
        futureLandsNftIdCurrent = MAX_LANDS; //future starts after public sale

        keyHash  = _vrfKeyHash;
        fee = _vrfFee;

        operator = _operator;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory uri) external onlyOperator {
        baseURI = uri;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOperator {
        maxMintPerTx = _maxMintPerTx;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) external onlyOperator {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function setKycCheckRequired(bool _isKycCheckRequired) external onlyOperator {
        isKycCheckRequired = _isKycCheckRequired;
    }

    function setKycMerkleRoot(bytes32 _kycMerkleRoot) external onlyOperator {
        kycMerkleRoot = _kycMerkleRoot;
    }

    // Public Sale Methods
    function startPublicSale(
        uint256 _publicSalePriceLoweringDuration, 
        uint256 _publicSaleStartPrice, 
        uint256 _publicSaleEndingPrice,
        uint256 _maxMintPerTx,
        uint256 _maxMintPerAddress,
        bool _isKycCheckRequired
    ) external onlyOperator {
        require(!publicSaleActive, "Public sale has already begun");
        
        publicSalePriceLoweringDuration = _publicSalePriceLoweringDuration;
        publicSaleStartPrice = _publicSaleStartPrice;
        publicSaleEndingPrice = _publicSaleEndingPrice;
        publicSaleStartTime = block.timestamp;
        publicSaleActive = true;

        maxMintPerTx = _maxMintPerTx;
        maxMintPerAddress = _maxMintPerAddress;

        isKycCheckRequired = _isKycCheckRequired;

        emit LandPublicSaleStart(publicSalePriceLoweringDuration, publicSaleStartTime);
    }

    function stopPublicSale() external onlyOperator whenPublicSaleActive {
        emit LandPublicSaleStop(getMintPrice(), getElapsedSaleTime());
        publicSaleActive = false;
    }

    function getElapsedSaleTime() private view returns (uint256) {
        return publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
    }

    function getMintPrice() public view whenPublicSaleActive returns (uint256) {
        uint256 elapsed = getElapsedSaleTime();
        uint256 price;

        if(elapsed < publicSalePriceLoweringDuration) {
            // Linear decreasing function
            price =
                publicSaleStartPrice -
                    ( ( publicSaleStartPrice - publicSaleEndingPrice ) * elapsed ) / publicSalePriceLoweringDuration ;
        } else {
            price = publicSaleEndingPrice;
        }

        return price;
    }

    function mintLands(uint256 numLands, bytes32[] calldata merkleProof) external whenPublicSaleActive nonReentrant {
        require(numLands > 0, "Must mint at least one beta");
        require(currentNumLandsMintedPublicSale + numLands <= MAX_PUBLIC_SALE_AMOUNT, "Minting would exceed max supply");
        require(numLands <= maxMintPerTx, "numLands should not exceed maxMintPerTx");
        require(numLands + mintedPerAddress[msg.sender] <= maxMintPerAddress, "sender address cannot mint more than maxMintPerAddress lands");
        if(isKycCheckRequired) {
            require(MerkleProof.verify(merkleProof, kycMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Sender address is not in KYC allowlist");
        } else {
            require(msg.sender == tx.origin, "Minting from smart contracts is disallowed");
        }
     
        uint256 mintPrice = getMintPrice();
        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), mintPrice * numLands);
        currentNumLandsMintedPublicSale += numLands;
        mintedPerAddress[msg.sender] += numLands;
        emit PublicSaleMint(msg.sender, numLands, mintPrice);
        mintLandsCommon(numLands, msg.sender);
    }

    function mintLandsCommon(uint256 numLands, address recipient) private {
        for (uint256 i; i < numLands; ++i) {
            _safeMint(recipient, mintIndexPublicSaleAndContributors++);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0){
            Address.sendValue(payable(owner()), balance);
        }

        balance = IERC20(tokenContract).balanceOf(address(this));
        if(balance > 0){
            IERC20(tokenContract).safeTransfer(owner(), balance);
        }
    }

    // Alpha/Beta Claim Methods
    function flipClaimableState() external onlyOperator {
        claimableActive = !claimableActive;
        emit ClaimableStateChanged(claimableActive);
    }

    function nftOwnerClaimLand(uint256[] calldata alphaTokenIds, uint256[] calldata betaTokenIds) external whenClaimableActive {
        require(alphaTokenIds.length > 0 || betaTokenIds.length > 0, "Should claim at least one land");
        require(alphaTokenIds.length + betaTokenIds.length <= MAX_MINT_PER_BLOCK, "Input length should be <= MAX_MINT_PER_BLOCK");

        alphaClaimLand(alphaTokenIds);
        betaClaimLand(betaTokenIds);
    }

    function alphaClaimLand(uint256[] calldata alphaTokenIds) private {
        for(uint256 i; i < alphaTokenIds.length; ++i){
            uint256 alphaTokenId = alphaTokenIds[i];
            require(!alphaClaimed[alphaTokenId], "ALPHA NFT already claimed");
            require(ERC721(alphaContract).ownerOf(alphaTokenId) == msg.sender, "Must own all of the alpha defined by alphaTokenIds");
            
            alphaClaimLandByTokenId(alphaTokenId);    
        }
    }

    function alphaClaimLandByTokenId(uint256 alphaTokenId) private {
        alphaClaimed[alphaTokenId] = true;
        ++alphaClaimedAmount;        
        _safeMint(msg.sender, alphaTokenId);
    }

    function betaClaimLand(uint256[] calldata betaTokenIds) private {
        for(uint256 i; i < betaTokenIds.length; ++i){
            uint256 betaTokenId = betaTokenIds[i];
            require(!betaClaimed[betaTokenId], "BETA NFT already claimed");
            require(ERC721(betaContract).ownerOf(betaTokenId) == msg.sender, "Must own all of the beta defined by betaTokenIds");
            
            betaClaimLandByTokenId(betaTokenId);    
        }
    }

    function betaClaimLandByTokenId(uint256 betaTokenId) private {
        betaClaimed[betaTokenId] = true;
        ++betaClaimedAmount;
        _safeMint(msg.sender, betaNftIdCurrent++);
    }

    // Contributors Claim Methods
    function startContributorsClaimPeriod() onlyOperator external {
        require(!contributorsClaimActive, "Contributors claim is already active");
        contributorsClaimActive = true;
        emit ContributorsClaimStart(block.timestamp);
    }

    function stopContributorsClaimPeriod() onlyOperator external whenContributorsClaimActive {
        contributorsClaimActive = false;
        emit ContributorsClaimStop(block.timestamp);
    }

    function contributorsClaimLand(uint256 amount, address recipient) external onlyContributors(msg.sender) whenContributorsClaimActive {
        require(amount > 0, "Must mint at least one land");
        require(amount <= MAX_MINT_PER_BLOCK, "amount should not exceed MAX_MINT_PER_BLOCK");
        require(amount <= contributors[msg.sender], "Contributor cannot claim other lands");

        contributors[msg.sender] -= amount;
        mintLandsCommon(amount, recipient);
    }

    function claimUnclaimedAndUnsoldLands(address recipient) external onlyOwner {
        claimUnclaimedAndUnsoldLandsWithAmount(recipient, MAX_MINT_PER_BLOCK);
    }

    function claimUnclaimedAndUnsoldLandsWithAmount(address recipient, uint256 maxAmount) public onlyOwner {
        require (publicSaleStartTime > 0 && !claimableActive && !publicSaleActive && !contributorsClaimActive,
            "Cannot claim the unclaimed if claimable or public sale are active");
        require(maxAmount <= MAX_MINT_PER_BLOCK, "maxAmount cannot exceed MAX_MINT_PER_BLOCK");
        require(alphaClaimedAmount < MAX_ALPHA_NFT_AMOUNT || betaClaimedAmount < MAX_BETA_NFT_AMOUNT
                    || mintIndexPublicSaleAndContributors < MAX_LANDS, "Max NFT amount already claimed or sold");

        uint256 totalMinted;
        adminClaimStarted = true;
        //claim beta
        if(betaClaimedAmount < MAX_BETA_NFT_AMOUNT) {
            uint256 leftToBeMinted = MAX_BETA_NFT_AMOUNT - betaClaimedAmount;
            uint256 toMint = leftToBeMinted < maxAmount ? leftToBeMinted : 
                maxAmount; //take the min

            uint256 target = betaNftIdCurrent + toMint;
            for(; betaNftIdCurrent < target; ++betaNftIdCurrent){
                ++betaClaimedAmount;
                ++totalMinted;
                _safeMint(recipient, betaNftIdCurrent);
            }
        }

        //claim alpha
        if(alphaClaimedAmount < MAX_ALPHA_NFT_AMOUNT) {
            uint256 leftToBeMinted = MAX_ALPHA_NFT_AMOUNT - alphaClaimedAmount;
            uint256 toMint = maxAmount < leftToBeMinted + totalMinted ? 
                            maxAmount :
                            leftToBeMinted + totalMinted; //summing totalMinted avoid to use another counter
            
            uint256 lastAlphaNft = MAX_ALPHA_NFT_AMOUNT - 1;
            for(uint256 i; i <= lastAlphaNft && totalMinted < toMint; ++i) {
                if(!alphaClaimed[i]){
                    ++alphaClaimedAmount;
                    ++totalMinted;
                    alphaClaimed[i] = true;
                    _safeMint(recipient, i);
                }
            }
        }

        //claim unsold
        if(mintIndexPublicSaleAndContributors < MAX_LANDS){
            uint256 leftToBeMinted = MAX_LANDS - mintIndexPublicSaleAndContributors; 
            uint256 toMint = maxAmount < leftToBeMinted + totalMinted ? 
                            maxAmount :
                            leftToBeMinted + totalMinted; //summing totalMinted avoid to use another counter

            for(; mintIndexPublicSaleAndContributors < MAX_LANDS && totalMinted < toMint; ++mintIndexPublicSaleAndContributors) {
                    ++totalMinted;
                    _safeMint(recipient, mintIndexPublicSaleAndContributors);
            }              
        }
    }

    //future
    function setFutureMinter(address _futureMinter) external onlyOwner {
        futureMinter = _futureMinter;
    }

    function mintFutureLands(address recipient) external onlyFutureMinter {
        mintFutureLandsWithAmount(recipient, MAX_MINT_PER_BLOCK);
    }

    function mintFutureLandsWithAmount(address recipient, uint256 maxAmount) public onlyFutureMinter {
        require(maxAmount <= MAX_MINT_PER_BLOCK, "maxAmount cannot exceed MAX_MINT_PER_BLOCK");    
        require(futureLandsNftIdCurrent < MAX_LANDS_WITH_FUTURE, "All future lands were already minted");
        for(uint256 claimed; claimed < maxAmount && futureLandsNftIdCurrent < MAX_LANDS_WITH_FUTURE; ++claimed){

            _safeMint(recipient, futureLandsNftIdCurrent++);
        }
    }
     
    // metadata
    function loadLandMetadata(Metadata memory _landMetadata)
        external onlyOperator checkMetadataRange(_landMetadata)
        checkFirstMetadataRange(metadataHashes.length, _landMetadata.startIndex, _landMetadata.endIndex)
    {
        metadataHashes.push(_landMetadata);
    } 

    function putLandMetadataAtIndex(uint256 index, Metadata memory _landMetadata)
        external onlyOperator checkMetadataRange(_landMetadata)
        checkFirstMetadataRange(index, _landMetadata.startIndex, _landMetadata.endIndex)
    {
        metadataHashes[index] = _landMetadata;
    }     

    // randomness
    function requestRandomnessForPublicSaleAndContributors() external onlyOperator returns (bytes32 requestId) {
        require(!publicSaleAndContributorsRandomnessRequested, "Public Sale And Contributors Offset already requested");
        publicSaleAndContributorsRandomnessRequested = true;
        requestId = requestRandomnessPrivate();
        isRandomRequestForPublicSaleAndContributors[requestId] = true;
    }

    function requestRandomnessForOwnerClaim() external onlyOperator returns (bytes32 requestId) {
        require(!ownerClaimRandomnessRequested, "Owner Claim Offset already requested");
        ownerClaimRandomnessRequested = true;
        requestId = requestRandomnessPrivate();
        isRandomRequestForPublicSaleAndContributors[requestId] = false;
    }

    function requestRandomnessPrivate() private returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if(isRandomRequestForPublicSaleAndContributors[requestId]){
            publicSaleAndContributorsOffset = (randomness % (MAX_PUBLIC_SALE_AMOUNT + RESERVED_CONTRIBUTORS_AMOUNT));
            emit StartingIndexSetPublicSale(publicSaleAndContributorsOffset);
        } else {
            alphaOffset = (randomness % MAX_ALPHA_NFT_AMOUNT);
            betaOffset = (randomness % MAX_BETA_NFT_AMOUNT);
            emit StartingIndexSetAlphaBeta(alphaOffset, betaOffset);
        }
    }
}