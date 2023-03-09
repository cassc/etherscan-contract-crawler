// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract Gasoline is ERC721A, VRFConsumerBaseV2, AccessControl {
    VRFCoordinatorV2Interface public immutable COORDINATOR;

    uint64 public immutable s_subscriptionId;
    bytes32 public immutable s_keyHash;
    uint32 public constant CALLBACK_GAS_LIMIT = 100000;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;

    mapping(uint256 => address) public vrfRequestIdToAddress;
    mapping(address => bool) public allowlistMinted;

    uint256 public constant MAX_TOKEN_SUPPLY = 3333;
    uint256 public constant MAX_STANDARD_TOKEN_SUPPLY = 3000;
    uint256 public constant MAX_SUPER_TOKEN_SUPPLY = 333;
    bool public paused = true;
    bool public publicMintPhase = false;
    bytes32 public allowlistMerkleRoot = 0x0;
    bytes32 public freeClaimMerkleRoot = 0x0;
    uint256 public price = 0.22 ether;
    bool public staking = false;

    event RandomMintRequested(uint256 _requestId);

    event RandomMintFulfilled(
        uint256 _requestId,
        address _minter,
        uint256 _roll
    );

    string private baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _uri;
    }

    // NON-SEQUENTIAL STUFF
    uint256 private _currentIndexStandard;
    uint256 private _currentIndexSuper;

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) ERC721A("Gasoline", "GAS") VRFConsumerBaseV2(_vrfCoordinator) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);

        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;

        _currentIndexStandard = _standardStartTokenId();
        _currentIndexSuper = _superStartTokenId();
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowlistMerkleRoot = _merkleRoot;
    }

    function setFreeClaimMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        freeClaimMerkleRoot = _merkleRoot;
    }

    function pause(bool _pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = _pause;
    }

    function setPublicMintPhase(bool _publicMintPhase)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        publicMintPhase = _publicMintPhase;
    }

    // =============================================================
    //   MINT OPERATIONS
    // =============================================================

    modifier supplyCheck() {
        require(paused == false, "Minting is paused.");
        require(
            _totalMinted() <= MAX_TOKEN_SUPPLY,
            "Max token supply reached."
        );

        _;
    }

    /**
     * @notice Each allowlisted address can mint one token (randomly rolled).
     */
    function allowlistMint(bytes32[] calldata _merkleProof)
        public
        payable
        supplyCheck
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            allowlistMinted[msg.sender] == false,
            "Already minted allowlist."
        );
        require(_numberMinted(msg.sender) == 0, "Already minted.");
        require(
            MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf),
            "Invalid Merkle proof."
        );
        require(msg.value >= price, "Incorrect ether sent.");

        uint256 requestId = requestRandomMint();
        vrfRequestIdToAddress[requestId] = msg.sender;
        allowlistMinted[msg.sender] = true;
    }

    /**
     * @notice Public mint is still 1 mint per tx (still randomly rolled).
     */
    function publicMint() public payable supplyCheck {
        require(publicMintPhase == true, "Public mint is not open.");
        require(msg.value >= price, "Incorrect ether sent.");

        // If one supply is tapped out, then default to the other.
        if (totalMintedStandard() >= MAX_STANDARD_TOKEN_SUPPLY) {
            _superMint(msg.sender, 1);
        } else if (totalMintedSuper() >= MAX_SUPER_TOKEN_SUPPLY) {
            _standardMint(msg.sender, 1);
        } else {
            uint256 requestId = requestRandomMint();
            vrfRequestIdToAddress[requestId] = msg.sender;
        }
    }

    uint256 public constant STANDARD_MINT_COST = 5;
    uint256 public constant SUPER_MINT_COST = 10;

    function freeClaimMint(
        bytes32[] calldata _merkleProof,
        uint256 _numberOfStandardMints,
        uint256 _numberOfSuperMints
    ) public supplyCheck {
        require(_numberOfSuperMints <= 1, "Only 1 super allowed.");
        require(_numberMinted(msg.sender) == 0, "Already minted.");

        bytes32 leaf = keccak256(
            abi.encodePacked(
                msg.sender,
                _numberOfStandardMints *
                    STANDARD_MINT_COST +
                    _numberOfSuperMints *
                    SUPER_MINT_COST
            )
        );

        require(
            MerkleProof.verify(_merkleProof, freeClaimMerkleRoot, leaf),
            "Invalid Merkle proof."
        );

        if (_numberOfStandardMints > 0) {
            _standardMint(msg.sender, _numberOfStandardMints);
        }
        if (_numberOfSuperMints > 0) {
            _superMint(msg.sender, _numberOfSuperMints);
        }
    }

    function adminMint(
        uint256 _numberOfStandardMints,
        uint256 _numberOfSuperMints
    ) external supplyCheck onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_numberOfStandardMints > 0) {
            _standardMint(msg.sender, _numberOfStandardMints);
        }
        if (_numberOfSuperMints > 0) {
            _superMint(msg.sender, _numberOfSuperMints);
        }
    }

    function _standardMint(address _to, uint256 _mintAmount) private {
        // mint 1-3000
        require(
            totalMintedStandard() + _mintAmount <= MAX_STANDARD_TOKEN_SUPPLY,
            "Will exceed token supply."
        );

        _safeMint(_to, _mintAmount, _currentIndexStandard);
        _currentIndexStandard = _currentIndexStandard + _mintAmount;
    }

    function _superMint(address _to, uint256 _mintAmount) private {
        // mint 3001-3333
        require(
            totalMintedSuper() + _mintAmount <= MAX_SUPER_TOKEN_SUPPLY,
            "Will exceed token supply."
        );
        _safeMint(_to, _mintAmount, _currentIndexSuper);
        _currentIndexSuper = _currentIndexSuper + _mintAmount;
    }

    function requestRandomMint() public returns (uint256) {
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        emit RandomMintRequested(requestId);

        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // This will choose a minting path based on what `randomWords` are returned.
        uint256 roll = randomWords[0] % 1000; // [0..999]

        address minter = vrfRequestIdToAddress[requestId];

        if (minter == address(0)) {
            revert MintToZeroAddress();
        }

        if (roll >= 901) {
            // if roll is [901..999]
            // then superMint
            _superMint(minter, 1);
        } else {
            // standardMint
            _standardMint(minter, 1);
        }

        emit RandomMintFulfilled(requestId, minter, roll);
    }

    // =============================================================
    //   TOKEN COUNTING OPERATIONS
    // =============================================================

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _standardStartTokenId() internal view virtual returns (uint256) {
        return _startTokenId();
    }

    function _superStartTokenId() internal view virtual returns (uint256) {
        return 3001;
    }

    function totalMintedStandard() public view virtual returns (uint256) {
        unchecked {
            return _currentIndexStandard - _standardStartTokenId();
        }
    }

    function totalMintedSuper() public view virtual returns (uint256) {
        unchecked {
            return _currentIndexSuper - _superStartTokenId();
        }
    }

    function _totalMinted() internal view virtual override returns (uint256) {
        unchecked {
            return totalMintedStandard() + totalMintedSuper();
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalMinted();
    }

    // =============================================================
    //   STAKING OPERATIONS
    // =============================================================

    mapping(uint256 => uint256) private tokenIdToStakingStartTime;
    event Staked(uint256 indexed _tokenId, uint256 _stakingStartTime);
    event Unstaked(uint256 indexed _tokenId, uint256 _stakingEndTime);

    function setStaking(bool _staking) external onlyRole(DEFAULT_ADMIN_ROLE) {
        staking = _staking;
    }

    function _stake(uint256 tokenId) private {
        require(ownerOf(tokenId) == msg.sender, "Not owner.");

        uint256 timestamp = block.timestamp;

        tokenIdToStakingStartTime[tokenId] = timestamp;
        emit Staked(tokenId, timestamp);
    }

    function stake(uint256[] calldata tokenIds) external {
        require(staking == true, "Staking is not enabled.");

        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            _stake(tokenIds[i]);
        }
    }

    function _unstake(uint256 tokenId, bool _expel) private {
        if (!_expel) {
            require(ownerOf(tokenId) == msg.sender, "Not owner.");
        }
        tokenIdToStakingStartTime[tokenId] = 0;
        emit Unstaked(tokenId, block.timestamp);
    }

    function unstake(uint256[] calldata tokenIds) external {
        require(staking == true, "Staking is not enabled.");

        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            _unstake(tokenIds[i], false);
        }
    }

    function expel(uint256[] calldata tokenIds)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            _unstake(tokenIds[i], true);
        }
    }

    function timeStaked(uint256 tokenId) external view returns (uint256) {
        if (tokenIdToStakingStartTime[tokenId] == 0) {
            return 0;
        }

        return block.timestamp - tokenIdToStakingStartTime[tokenId];
    }

    function stakingStartTime(uint256 tokenId) external view returns (uint256) {
        return tokenIdToStakingStartTime[tokenId];
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;

        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                tokenIdToStakingStartTime[tokenId] == 0,
                "Token is staking."
            );
        }
    }

    // =============================================================
    //   ADMIN OPERATIONS
    // =============================================================

    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os);
    }

    function setPrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _price;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId); // ERC165 interface ID for ERC721Metadata.
    }
}