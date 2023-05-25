// SPDX-License-Identifier: MIT

/*

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//// 01011010 01010101 01000011 01010111 01001001 01011000 ////

██   ██ ██ ██      ██       █████  ██████   ██ ████████ ███████ 
██  ██  ██ ██      ██      ██   ██ ██   ██  ██    ██    ██      
█████   ██ ██      ██      ███████ ██████   ██    ██    ███████ 
██  ██  ██ ██      ██      ██   ██ ██   ██  ██    ██         ██ 
██   ██ ██ ███████ ███████ ██   ██ ██████   ██    ██    ███████ 

//// 01001011 01001001 01001100 01001100 01000001 01010011 ////
//// 01110101 01101110 01101001 01110100 01100101 01100100 ////
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/* ------------
    Interfaces
   ------------ */

interface IERC721 {
    function ownerOf(uint256) external returns (address);
}

interface ITraitTokenizer {
    function tokenize(
        address,
        uint256,
        uint256
    ) external;

    function detokenize(
        address,
        uint256,
        uint256
    ) external;
}

/* ---------
    Structs
   --------- */

struct TokenInfo {
    uint64 upgrade;
    uint64 requestTimestamp;
}

/* --------
    Errors
   -------- */

error SupplyOverflow();
error UpgradingNotStarted();
error TokensAreTheSame();
error NotYourToken();
error UpgradePending();
error TokenAlreadyUpgraded();
error TokenNotMarkedForUpgrade();
error UpgradeRequestTooRecent();
error TokenHasNoUpgrade();
error TraitsContractNotConfigured();
error IncompatibleUpgrade();

/* ------
    Main
   ------ */

contract KILLABITS is ERC721A, Ownable, VRFConsumerBaseV2 {
    IERC721 public immutable killabearsContract;
    VRFCoordinatorV2Interface public immutable chainlinkContract;
    ITraitTokenizer public traitsContract;

    mapping(uint256 => string) public baseURIs;

    uint64[] public upgradeRarity;
    mapping(uint256 => bool) public compatibleUpgrades;
    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(uint256 => uint256) public requestIdToToken;

    bool public upgradingEnabled;

    bytes32 public chainlinkKeyHash;
    uint64 public chainlinkSubscriptionId;
    uint16 public chainlinkConfirmations;
    uint32 public chainlinkGasLimit;

    /* --------
        Events
       -------- */

    event TokenUpgradeRequested(
        uint256 indexed token,
        uint256 indexed requestId,
        uint256 indexed sacrifice
    );
    event TokenUpgraded(uint256 indexed token, uint64 indexed upgrade);
    event UpgradeTokenized(uint256 indexed token, uint64 indexed upgrade);

    /* ----------------
        Initialization
       ---------------- */

    constructor(address killabearsAddress, address chainlinkAddress)
        ERC721A("KILLABITS", "KILLABITS")
        VRFConsumerBaseV2(chainlinkAddress)
    {
        baseURIs[0] = "https://bits.killabears.com/nft/";
        killabearsContract = IERC721(killabearsAddress);
        chainlinkContract = VRFCoordinatorV2Interface(chainlinkAddress);
    }

    /* ---------
        Minting
       --------- */

    /// @notice Airdrop to KB holders
    function airdrop(uint256 qty) external onlyOwner {
        uint256 token = _nextTokenId();
        uint256 last = token + qty - 1;
        if (last > 3333) revert SupplyOverflow();
        uint256 cnt = 0;
        address prevOwner = killabearsContract.ownerOf(token);
        while (token <= last) {
            address owner = killabearsContract.ownerOf(token);
            if (owner != prevOwner || cnt == 32) {
                _mint(prevOwner, cnt);
                cnt = 1;
                prevOwner = owner;
            } else cnt++;
            if (token == last) _mint(owner, cnt);
            token++;
        }
    }

    /* -----------------
        Badassification
       ---------------- */

    /// @notice Initiates an upgrade for one token while burning another token
    function upgrade(uint256 token, uint256 sacrifice) external {
        if (!upgradingEnabled && msg.sender != owner())
            revert UpgradingNotStarted();

        if (token == sacrifice) revert TokensAreTheSame();

        if (ownerOf(token) != msg.sender || ownerOf(sacrifice) != msg.sender)
            revert NotYourToken();

        if (
            tokenInfo[token].requestTimestamp != 0 ||
            tokenInfo[sacrifice].requestTimestamp != 0
        ) revert UpgradePending();

        if (tokenInfo[token].upgrade > 0 || tokenInfo[sacrifice].upgrade > 0)
            revert TokenAlreadyUpgraded();

        uint256 requestId = chainlinkContract.requestRandomWords(
            chainlinkKeyHash,
            chainlinkSubscriptionId,
            chainlinkConfirmations,
            chainlinkGasLimit,
            1
        );
        requestIdToToken[requestId] = token;
        tokenInfo[token].requestTimestamp = uint64(block.timestamp);

        _burn(sacrifice, false);
        emit TokenUpgradeRequested(token, requestId, sacrifice);
    }

    /// @notice Callback invoked by chainlink
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 token = requestIdToToken[requestId];
        TokenInfo memory info = tokenInfo[token];

        if (info.requestTimestamp == 0) revert TokenNotMarkedForUpgrade();
        if (info.upgrade > 0) revert TokenAlreadyUpgraded();

        uint64 upgradeId = upgradeRarity[randomWords[0] % upgradeRarity.length];
        tokenInfo[token].upgrade = upgradeId;
        tokenInfo[token].requestTimestamp = 0;
        emit TokenUpgraded(token, upgradeId);
    }

    /// @notice Failsafe in case a request wasn't fulfilled by chainlink
    /// @dev Can only be called by contract owner after 24h,
    /// @dev by which time the request will have been cancelled by chainlink.
    /// @dev This uses the blockhash of the previous block as a source of randomness,
    /// @dev which is acceptable in this case because all requests will come from the
    /// @dev contract owner.
    function forceUpgrade(uint256 requestId) external onlyOwner {
        uint256 token = requestIdToToken[requestId];
        TokenInfo memory info = tokenInfo[token];
        uint256 ts = info.requestTimestamp;

        if (ts == 0) revert TokenNotMarkedForUpgrade();
        if (info.upgrade > 0) revert TokenAlreadyUpgraded();
        if (block.timestamp - ts < 86400) revert UpgradeRequestTooRecent();

        // Invalidate chainlink request
        tokenInfo[token].requestTimestamp = 0;

        uint64 upgradeId = upgradeRarity[
            uint256(blockhash(block.number - 1)) % upgradeRarity.length
        ];

        tokenInfo[token].upgrade = upgradeId;

        emit TokenUpgraded(token, upgradeId);
    }

    /// @notice Detaches an upgrade
    function detachUpgrade(uint256 token) external {
        if (ownerOf(token) != msg.sender) revert NotYourToken();
        TokenInfo memory info = tokenInfo[token];
        if (info.upgrade == 0) revert TokenHasNoUpgrade();
        if (address(traitsContract) == address(0))
            revert TraitsContractNotConfigured();

        uint64 upgradeId = info.upgrade;

        tokenInfo[token].upgrade = 0;
        traitsContract.tokenize(msg.sender, upgradeId, 1);

        emit UpgradeTokenized(token, upgradeId);
    }

    /// @notice Attaches an upgrade
    function attachUpgrade(uint256 token, uint64 upgradeId) external {
        if (ownerOf(token) != msg.sender) revert NotYourToken();
        TokenInfo memory info = tokenInfo[token];

        if (info.upgrade > 0) revert TokenAlreadyUpgraded();
        if (!compatibleUpgrades[upgradeId]) revert IncompatibleUpgrade();
        if (info.requestTimestamp > 0) revert UpgradePending();
        if (address(traitsContract) == address(0))
            revert TraitsContractNotConfigured();

        tokenInfo[token].upgrade = upgradeId;
        traitsContract.detokenize(msg.sender, upgradeId, 1);

        emit TokenUpgraded(token, upgradeId);
    }

    /// @notice Get the current upgrade for a given token
    function tokenUpgrade(uint256 token) external view returns (uint64) {
        return tokenInfo[token].upgrade;
    }

    /* --------
        Config
       -------- */

    /// @notice Sets the trait tokenizer contract
    function setTraitTokenizerContract(address _addr) external onlyOwner {
        traitsContract = ITraitTokenizer(_addr);
    }

    /// @notice Configures upgrade rarity
    function configureUpgrades(uint64[] memory upgrades, uint64[] memory rarity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < upgrades.length; i++) {
            uint64 upgradeId = upgrades[i];
            uint64 amount = rarity[i];
            while (amount > 0) {
                upgradeRarity.push(upgradeId);
                amount--;
            }
            compatibleUpgrades[upgradeId] = true;
        }
    }

    /// @notice Adds a compatible upgrade. Does not make it available through the sacrifice mechanism
    function addCompatibleUpgrade(uint256 upgradeId) external onlyOwner {
        compatibleUpgrades[upgradeId] = true;
    }

    /// @notice Enables upgrading
    function enableUpgrading() external onlyOwner {
        upgradingEnabled = true;
    }

    /// @notice Disables upgrading
    function disableUpgrading() external onlyOwner {
        upgradingEnabled = false;
    }

    /// @notice Configures chainlink
    function configureChainlink(
        bytes32 _keyHash,
        uint64 _subscription,
        uint16 _confirmations,
        uint32 _gasLimit
    ) external onlyOwner {
        chainlinkKeyHash = _keyHash;
        chainlinkSubscriptionId = _subscription;
        chainlinkConfirmations = _confirmations;
        chainlinkGasLimit = _gasLimit;
    }

    /// @notice Sets base URIs per upgradeId
    function setBaseURIs(uint256[] memory upgradeIds, string[] memory uris)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < upgradeIds.length; i++) {
            baseURIs[upgradeIds[i]] = uris[i];
        }
    }

    /* -------
        Other
       ------- */

    /// @dev Used to get the URI for a given token
    function tokenURI(uint256 token)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(token)) revert URIQueryForNonexistentToken();

        string memory baseURI = baseURIs[tokenInfo[token].upgrade];
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _toString(token)))
                : "";
    }

    /// @dev Collection starts at 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}