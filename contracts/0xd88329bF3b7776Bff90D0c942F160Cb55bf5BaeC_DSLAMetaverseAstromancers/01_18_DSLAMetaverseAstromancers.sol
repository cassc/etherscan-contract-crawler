// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';

contract DSLAMetaverseAstromancers is
    Ownable,
    ERC721Enumerable,
    VRFConsumerBaseV2,
    Pausable
{
    using Counters for Counters.Counter;

    address public DSLA;
    address[] public dTokens;

    uint256 public tokenHoldThreshold;
    uint256 public walletThreshold;
    uint256 public whitelistSlots = 1000;
    uint256 public whitelistMintPeriod = 4 weeks;
    uint256 public maxSupply = 10000;

    string private _baseTokenURI;

    // Chainlink VRF States
    VRFCoordinatorV2Interface public immutable coordinator;
    uint64 public subscriptionId;
    bytes32 public keyHash;

    uint256 totalRequests;
    mapping(uint256 => address) vrfRequests;
    mapping(address => uint256) requestsPerWallet;
    mapping(address => bool) public whitelisted;

    event RequestedRandomness(uint256 requestId);
    event Minted(uint256 tokenId, address account);

    bool public initialized;
    uint256 public startTimestamp;
    uint256[] tokenIdsLeft;

    modifier whenNotStarted() {
        require(!initialized, 'Minting started.');
        _;
    }

    modifier whenStarted() {
        require(initialized, 'Minting not started.');
        _;
    }

    constructor(
        address dsla_,
        address[] memory dTokens_,
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 walletThreshold_,
        uint256 tokenHoldThreshold_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_
    ) VRFConsumerBaseV2(vrfCoordinator_) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        walletThreshold = walletThreshold_;

        tokenHoldThreshold = tokenHoldThreshold_;
        DSLA = dsla_;
        dTokens = dTokens_;

        subscriptionId = subscriptionId_;
        keyHash = keyHash_;
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    }

    function setMaxSupply(uint256 newMaxSupply, uint256 newSlots)
        external
        onlyOwner
        whenNotStarted
    {
        require(newSlots < newMaxSupply, 'Slot allocation exceeds max supply.');
        maxSupply = newMaxSupply;
        whitelistSlots = newSlots;
    }

    function setWhitelistMintPeriod(uint256 newPeriod)
        external
        onlyOwner
        whenNotStarted
    {
        whitelistMintPeriod = newPeriod;
    }

    function whitelistUsers(address[] memory users, bool whitelist)
        external
        onlyOwner
        whenNotStarted
    {
        for (uint256 i = 0; i < users.length; i++) {
            whitelisted[users[i]] = whitelist;
        }
    }

    function initTokenIdIndex(uint256 num)
        external
        onlyOwner
        whenNotStarted
        whenNotPaused
    {
        // Gas fee optimized
        unchecked {
            uint256 index = tokenIdsLeft.length;
            uint256 max = index + num;
            require(
                max <= maxSupply,
                'Token id allocation exceeds max supply.'
            );

            for (uint256 i = index; i < max; i++) {
                tokenIdsLeft.push(i);
            }
        }
    }

    function startMinting() external onlyOwner whenNotStarted {
        require(tokenIdsLeft.length == maxSupply, 'Token ids not initialized.');
        initialized = true;
        startTimestamp = block.timestamp;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    function getRemainingSlots() external view returns (uint256) {
        return tokenIdsLeft.length;
    }

    function _checkTokenHolding(address user) internal view returns (bool) {
        // Check DSLA token holding
        if (IERC20(DSLA).balanceOf(user) >= tokenHoldThreshold) return true;

        // Check StakingSLA LP/SP tokens
        for (uint256 i = 0; i < dTokens.length; i++) {
            if (IERC20(dTokens[i]).balanceOf(user) >= tokenHoldThreshold)
                return true;
        }

        return false;
    }

    function mint() external whenStarted {
        require(msg.sender != address(0), 'Invalid user account.');
        require(
            ++requestsPerWallet[msg.sender] <= walletThreshold,
            'exceed limit'
        );
        require(_checkTokenHolding(msg.sender), 'Insufficient token holdings.');
        require(++totalRequests <= maxSupply, 'No available slots to mint.');

        if (whitelisted[msg.sender]) {
            // Should be in guaranteed minting period
            require(
                block.timestamp <= startTimestamp + whitelistMintPeriod,
                'Whitelist has expired.'
            );
            whitelistSlots--;
        } else {
            // Should leave guaranteed slots until guaranteed period expires
            if (block.timestamp <= startTimestamp + whitelistMintPeriod) {
                require(
                    totalRequests <= maxSupply - whitelistSlots,
                    'Remaining minting slots are for whitelisted users.'
                );
            }
        }

        uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            3, // minimumRequestConfirmations
            200000, // callbackGasLimit
            uint32(1) // numWords
        );

        vrfRequests[requestId] = msg.sender;

        emit RequestedRandomness(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address account = vrfRequests[requestId];
        require(account != address(0), 'Invalid user account.');
        uint256 numberOfLeft = tokenIdsLeft.length;
        uint256 indexToMint = randomWords[0] % numberOfLeft;

        // Swap remaining token ids
        uint256 tokenIdToMint = tokenIdsLeft[indexToMint];
        tokenIdsLeft[indexToMint] = tokenIdsLeft[numberOfLeft - 1];
        tokenIdsLeft.pop();

        _safeMint(account, tokenIdToMint);
        vrfRequests[requestId] = address(0);

        emit Minted(tokenIdToMint, account);
    }
}