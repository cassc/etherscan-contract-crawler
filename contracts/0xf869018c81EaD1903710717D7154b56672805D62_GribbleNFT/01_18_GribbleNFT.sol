// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2Upgradeable.sol";

contract GribbleNFT is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    VRFConsumerBaseV2Upgradeable
{
    using StringsUpgradeable for string;
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;

    // Core Data Structures that will never change
    // WARNING: You must not reorder any data nor initialize it via assignment
    struct Gribble {
        uint256 geneSeed;
        uint256 bornAt;
        uint256 generation;
    }

    Gribble[] public gribbles;

    // Max Token Supply
    uint256 public maxMintSupply;
    uint256 public maxClaimSupply;

    // Used Token Supply
    uint256 public currentMintSupply;
    uint256 public currentClaimSupply;

    // Metadata URI
    string public baseTokenURI;

    // Raw Mint Price
    uint256 public rawMintPrice;

    // Contract Flags
    bool public isClaimOpen;
    bool public isAllowListOpen;
    bool public isFCFSMintOpen;

    uint256 private constant MAX_INT = type(uint256).max;

    // Chainlink Systems
    // Chainlink subscription ID.
    uint64 private s_subscriptionId;
    // Chainlink Coordinator
    // solhint-disable var-name-mixedcase
    VRFCoordinatorV2Interface private COORDINATOR;
    // Chainlink Gas Lane
    bytes32 private s_keyHash;
    // Chainlink Gas Limit
    uint32 private callbackGasLimit;
    // Chainlink Confirmations Needed
    uint16 private requestConfirmations;
    // map a request ID to a tokenID
    mapping(uint256 => uint256) private s_geneRequests;

    // Genesis Holder mapping from ID to amount remaining to mint
    mapping(address => uint256) private _genesisHolders;
    // Play to Mint and Partner Access
    mapping(address => uint256) private _play2MintAllowlist;
    // Events
    event GenomeRolled(uint256 indexed requestId, uint256 indexed gribbleId);
    event GenomeLanded(uint256 indexed requestId, uint256 indexed result);
    event Mint(address indexed user, bool indexed isClaimMint, uint256 amount);

    // initialize is the replacement for a constructor
    function initialize(
        string memory name,
        string memory symbol,
        string memory default_uri,
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 vrfKeyhash
    ) public initializer {
        // Global statics are here instead of in contract due to needing to keep datastructure uninitialized
        //address vrfCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;

        // With no Constructors, parents must be manually initialized
        __ReentrancyGuard_init();
        __ERC721Enumerable_init();
        __ERC721_init(name, symbol);
        __Ownable_init();
        __VRFConsumerBaseV2_init(vrfCoordinator);
        // Set the API
        setBaseURI(default_uri);
        // Setup Chainlink
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = vrfKeyhash;
        s_subscriptionId = subscriptionId;
        callbackGasLimit = 40000;
        requestConfirmations = 3;
        rawMintPrice = 0.03 ether;
        maxMintSupply = 10000;
        maxClaimSupply = 10000;
    }

    // Token URI overrides
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Contract Ops Section
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function setMaxMintSupply(uint256 _supply) public onlyOwner {
        maxMintSupply = _supply;
    }

    function setMaxClaimSupply(uint256 _supply) public onlyOwner {
        maxClaimSupply = _supply;
    }

    function setClaimMints(bool _status) public onlyOwner {
        isClaimOpen = _status;
    }

    function setAllowlistMints(bool _status) public onlyOwner {
        isAllowListOpen = _status;
    }

    function setFCFSMints(bool _status) public onlyOwner {
        isFCFSMintOpen = _status;
    }

    // Chainlink variables

    function setKeyhash(bytes32 _keyhash) public onlyOwner {
        s_keyHash = _keyhash;
    }

    function setVrfCoordinator(address _coordinator) public onlyOwner {
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
    }

    function setCallbackGasLimit(uint32 _gaslimit) public onlyOwner {
        callbackGasLimit = _gaslimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations)
        public
        onlyOwner
    {
        requestConfirmations = _requestConfirmations;
    }

    // Genetics Section
    function _rollGenetics(uint256 _gribbleId)
        private
        returns (uint256 requestId)
    {
        require(
            gribbles[_gribbleId].geneSeed == 0 ||
                gribbles[_gribbleId].geneSeed == MAX_INT,
            "Already rolled"
        );
        require(_gribbleId <= totalSupply(), "Can't roll yet");
        uint32 numWords = 1;
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_geneRequests[requestId] = _gribbleId;
        // Need a sentinal value to check if someone is rolling that is non zero
        gribbles[_gribbleId].geneSeed = MAX_INT;
        emit GenomeRolled(requestId, _gribbleId);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWord)
        internal
        override
    {
        // Got our randomness
        // Find which gribble we are talking about
        uint256 gribbleId = s_geneRequests[_requestId];

        uint256 finalSeed = _randomWord[0];

        // Ensure non-reuse of sentinal
        finalSeed = _randomWord[0] % MAX_INT.sub(1);
        // assign the transformed value to the address in the geneSeed
        // It should never be 0 nor MAX_INT

        gribbles[gribbleId].geneSeed = finalSeed.add(1);

        // emitting event to signal that Gene landed
        emit GenomeLanded(_requestId, gribbles[gribbleId].geneSeed);
    }

    function gribbleGeneSeed(uint256 _gribbleId) public view returns (uint256) {
        require(gribbles[_gribbleId].geneSeed != 0, "No seed");
        require(
            gribbles[_gribbleId].geneSeed != MAX_INT,
            "In progress"
        );
        return gribbles[_gribbleId].geneSeed;
    }

    // Allowlist/Claimlist Section

    // add amounts to Holder Lists
    function addToClaimlist(address[] calldata _addresses, uint256[] calldata _values)
        external
        onlyOwner
    {
        require(_addresses.length == _values.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            _genesisHolders[_addresses[i]] += _values[i];
        }
    }

    function addToPlay2Mint(address[] calldata _addresses, uint256[] calldata _values)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Bad address");
            _play2MintAllowlist[_addresses[i]] += _values[i];
        }
    }

    // Mint Section

    // Claim mints for Breaker Holders
    function claimMint(uint256 _numberOfTokens) public nonReentrant {
        claimListOpen();
        // Claim Amount Checks
        require(_numberOfTokens > 0 && _numberOfTokens < 21, "1 to 20 only");

        // Check max supply
        require(hasClaimSupply(_numberOfTokens), "Max supply");

        // Check Claim Size and List
        require(_numberOfTokens <= _genesisHolders[msg.sender], "Claim less");

        _genesisHolders[msg.sender] -= _numberOfTokens;
        currentClaimSupply += _numberOfTokens;
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _generateGribble(msg.sender);
        }
        
        emit Mint(msg.sender, true, _numberOfTokens);
    }

    // Genesis Mint a number of NFTs
    function genesisMint(uint256 _numberOfTokens) public payable nonReentrant {
        publicMintOpen();
        // Mint Amount Checks
        require(_numberOfTokens > 0 && _numberOfTokens < 21, "1 to 20 only");

        // Check max supply
        require(hasMintSupply(_numberOfTokens), "Max supply");

        // Money Checks
        require(rawMintPrice.mul(_numberOfTokens) <= msg.value, "ETH too low");

        // Play2Mint Checks
        if (!isFCFSMintOpen) {
            require(
                _numberOfTokens <= _play2MintAllowlist[msg.sender],
                "Bad mint amount"
            );
            // If they are on the allow list, use up their slots
            _play2MintAllowlist[msg.sender] -= _numberOfTokens;
        }

        currentMintSupply += _numberOfTokens;

        // All clear let's mint
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _generateGribble(msg.sender);
        }

        emit Mint(msg.sender, false, _numberOfTokens);
    }

    // Private NFT Generator
    function _generateGribble(address _owner) private {
        // Create a gribble with a 0 seed and a timestamp
        Gribble memory gribble = Gribble(0, block.timestamp,0);
        gribbles.push(gribble);

        // Get next token id
        uint256 gribbleId = totalSupply();

        _safeMint(_owner, gribbleId);
        _rollGenetics(gribbleId);
    }

    // Modifiers
    // Set to functions to lower code size
    function claimListOpen() private view {
        require(isClaimOpen, "Claims closed");
    }

    function publicMintOpen() private view {
        require(isAllowListOpen || isFCFSMintOpen, "Mints closed");
    }

    function hasAnySupply(uint256 _numberOfTokens) public view returns (bool) {
        uint256 gribbleSupply = totalSupply();
        return gribbleSupply.add(_numberOfTokens) <= maxMintSupply.add(maxClaimSupply);
    }

    function hasClaimSupply(uint256 _numberOfTokens) public view returns (bool) {
        return currentClaimSupply.add(_numberOfTokens) <= maxClaimSupply;
    }
    function hasMintSupply(uint256 _numberOfTokens) public view returns (bool) {
        return currentMintSupply.add(_numberOfTokens) <= maxMintSupply;
    }

    // Views
    function canAllowlistMint(uint256 _amount)
        public
        view
        returns (bool allowed)
    {
        if (
            _amount > 0 &&
            hasMintSupply(_amount) &&
            _amount <= _play2MintAllowlist[msg.sender]
        ) {
            allowed = true;
        }
    }

    function canClaimListMint(uint256 _amount)
        public
        view
        returns (bool allowed)
    {
        if (
            _amount > 0 &&
            hasClaimSupply(_amount) &&
            _amount <= _genesisHolders[msg.sender]
        ) {
            allowed = true;
        }
    }

    // From wallet to number of mints
    function getAllowlistMintsRemaining(address _address)
        public
        view
        returns (uint256)
    {
        return _play2MintAllowlist[_address];
    }

    function getClaimlistMintsRemaining(address _address)
        public
        view
        returns (uint256)
    {
        return _genesisHolders[_address];
    }

    // Web3 Economics
    // TODO: Decide on if we want a treasury withdrawal address
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Empty");
        payable(msg.sender).transfer(balance);
    }

}