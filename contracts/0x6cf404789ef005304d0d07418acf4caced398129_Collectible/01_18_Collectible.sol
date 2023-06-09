// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract Collectible is
    Initializable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    enum Phase {
        Init,
        Presale,
        PresaleEnd,
        Sale,
        Aftersale,
        End
    }

    /// @dev Current token Id counter
    CountersUpgradeable.Counter private tokenIdCounter;

    /// @dev Current sale phase
    Phase public phase;
    /// @dev Timestamp when current phase started
    uint public phaseStartTime;
    /// @dev Max tokens count this contract can issue
    uint public totalTokens;
    /// @dev Max tokens count we can sell during the Presale phase
    uint public presaleTokensLimit;
    /// @dev Seconds till the end of the Presale phase
    uint public presaleTimeLimit;
    /// @dev Total mint lock-unlock cycle length. Must be greater than saleCyclePeriodDays.
    uint public saleCyclePeriodDays;
    /// @dev Minting will be allowed during the first N days of each cycle, where N is saleUnlockPeriodDays
    uint public saleUnlockPeriodDays;
    /// @dev Tokens count for the Aftersale phase. Note that the Aftersale phase may be started earlier.
    uint public aftersaleTokensCount;

    /// @dev NFT price for sale phase
    uint256 public saleTokenPrice;
    /// @dev NFT price for presale phase
    uint256 public constant presaleTokenPrice = 0;
    /// @dev NFT minting fee
    uint256 public constant mintFee = 0.01 ether;

    /// @dev wallet which will receive minting fee
    address internal apiWallet;
    /// @dev wallet which will receive all the payments from users
    address internal payoutWallet;

    /// @dev used for whitelist proof
    bytes32 public merkleRoot;

    /// @dev Whitelisted users may claim 1 free token during the Sale phase
    /// and another one during the Aftersale phase
    mapping(Phase => mapping(address => bool)) internal freeClaims;

    bytes32 public constant API_ROLE = keccak256("API_ROLE");

    event SetTokenURI(uint256 indexed tokenId, string tokenURI);
    /// @dev refresh token metadata on OpenSea
    event MetadataUpdate(uint256 _tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _adminWallet,
        address _apiWallet,
        address _payoutWallet,
        uint _totalTokens,
        uint _presaleTokensLimit,
        uint _presaleTimeLimit, // seconds
        uint _saleCyclePeriodDays,
        uint _saleUnlockPeriodDays,
        uint _aftersaleTokensCount
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __AccessControl_init();
        __Pausable_init();
        __NFT_init_unchained(_adminWallet, _apiWallet, _payoutWallet);

        require(
            _saleCyclePeriodDays >= _saleUnlockPeriodDays,
            "_saleUnlockPeriodDays cannot be greater than _saleCyclePeriodDays"
        );

        phase = Phase.Init;
        saleTokenPrice = 0.142069 ether;
        totalTokens = _totalTokens;
        presaleTokensLimit = _presaleTokensLimit;
        presaleTimeLimit = _presaleTimeLimit;
        saleCyclePeriodDays = _saleCyclePeriodDays;
        saleUnlockPeriodDays = _saleUnlockPeriodDays;
        aftersaleTokensCount = _aftersaleTokensCount;
    }

    function __NFT_init_unchained(
        address _adminWallet,
        address _apiWallet,
        address _payoutWallet
    ) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _adminWallet);
        _grantRole(API_ROLE, _apiWallet);

        apiWallet = _apiWallet;
        payoutWallet = _payoutWallet;
    }

    modifier whitelistedUser(bytes32[] calldata _proof) {
        require(
            merkleRoot != 0,
            "Whitelist has not been set yet. Please try again later."
        );
        require(
            MerkleProofUpgradeable.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Minting denied. Invalid proof."
        );
        _;
    }

    /** ================== PUBLIC FUNCTIONS ================== */

    /// @dev Returns the ID of the next minted token (starts from 0)
    function nextTokenId() public view returns (uint256) {
        return tokenIdCounter.current();
    }

    /// @dev Set MerkleRoot for whitelist proof
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(API_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) external onlyRole(API_ROLE) {
        _setTokenURI(_tokenId, _tokenURI);

        emit SetTokenURI(_tokenId, _tokenURI);
        emit MetadataUpdate(_tokenId);
    }

    /// @dev Check whether an account has claimed a free token during the current phase
    function isAddressClaimedToken(
        address _address
    ) external view returns (bool) {
        return freeClaims[phase][_address];
    }

    /// @dev Admin MUST call this method after the initialization
    /// to start the first (Presale) phase.
    function startPresale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            phase == Phase.Init && phaseStartTime == 0,
            "Presale phrase already started."
        );

        phase = Phase.Presale;
        phaseStartTime = block.timestamp;
    }

    /// @dev Admin MUST call this method after the Presale phase has ended
    /// to start the next (Sale) phase.
    function startSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            phase == Phase.PresaleEnd ||
                (phase == Phase.Presale && checkPresalePhaseEnding()),
            "The contract must be in the PresaleEnd phase to start the Sale phase."
        );

        phase = Phase.Sale;
        phaseStartTime = block.timestamp;
        merkleRoot = 0;
    }

    /// @dev Admin MAY call this method during the Sale phase to start
    /// the Aftersale phase preliminary. Merkle root must be set after this call.
    function startAftersale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            phase == Phase.Sale,
            "The contract must be in the Sale phase to start the Aftersale phase."
        );

        phase = Phase.Aftersale;
        phaseStartTime = block.timestamp;
        merkleRoot = 0;
    }

    /// @dev Update saleTokenPrice.
    function setSaleTokenPrice(
        uint256 _saleTokenPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleTokenPrice = _saleTokenPrice;
    }

    /// @param _proof Merkle proof. Should be an empty array during the Sale phase.
    /// @dev Main minting function called by user
    function mint(bytes32[] calldata _proof) external payable whenNotPaused {
        require(
            phaseStartTime > 0 && block.timestamp >= phaseStartTime,
            "The mint has not started yet. Please try again later."
        );
        require(
            phase != Phase.End,
            "No tokens left. Minting is not allowed anymore."
        );

        if (phase == Phase.Presale && !checkPresalePhaseEnding()) {
            mintPresale(_proof);
        } else if (phase == Phase.PresaleEnd) {
            revert(
                "The Sale phase has not started yet. Please try again later."
            );
        } else if (phase == Phase.Sale) {
            mintSale(_proof);
        } else {
            mintAftersale(_proof);
        }

        // send minting fee to the API wallet address
        bool sent = payable(apiWallet).send(mintFee);
        require(sent, "Fee was not sent correctly to API wallet!");
        // send the rest of ether to the Payout wallet address
        sent = payable(payoutWallet).send(msg.value - mintFee);
        require(sent, "Funds were not sent correctly to Payout wallet!");
    }

    /** ================== ENDOF PUBLIC FUNCTIONS ================== */

    /** ================== INTERNAL FUNCTIONS ================== **/
    /// @dev Minting for PreSale phase
    function mintPresale(
        bytes32[] calldata _proof
    ) internal whitelistedUser(_proof) {
        require(
            msg.value == presaleTokenPrice + mintFee,
            "Invalid attached amount. 0.055 ETH required."
        );

        internalMint();
        checkPresalePhaseEnding();
    }

    /// @dev Minting for Sale phase
    function mintSale(bytes32[] calldata _proof) internal {
        require(isSaleMintAllowed(), "Minting is not allowed at the moment.");

        if (_proof.length != 0) {
            require(merkleRoot != 0, "Whitelist has not been set yet.");
            require(
                freeClaims[phase][msg.sender] == false,
                "You already claimed your free NFT during this phase."
            );
            require(
                _proof.length == 0 ||
                    MerkleProofUpgradeable.verify(
                        _proof,
                        merkleRoot,
                        keccak256(abi.encodePacked(msg.sender))
                    ),
                "Minting denied. Invalid proof."
            );
            require(
                msg.value == mintFee,
                "Invalid attached amount. 0.005 ETH required."
            );

            freeClaims[phase][msg.sender] = true;
        } else {
            require(
                msg.value == saleTokenPrice + mintFee,
                "Invalid attached amount. 0.085 ETH required."
            );
        }

        internalMint();
        checkSalePhaseEnding();
    }

    /// @dev Check whether NFT minting is currently allowed.
    function isSaleMintAllowed() internal view returns (bool) {
        uint256 secondsPassed = block.timestamp - phaseStartTime;

        if (secondsPassed < (saleUnlockPeriodDays * 1 days)) {
            return true;
        }

        return
            secondsPassed % (saleCyclePeriodDays * 1 days) <
            (saleUnlockPeriodDays * 1 days);
    }

    /// @dev Minting for AfterSale phase
    function mintAftersale(
        bytes32[] calldata _proof
    ) internal whitelistedUser(_proof) {
        require(
            msg.value == mintFee,
            "Invalid attached amount. 0.005 ETH required."
        );
        require(
            freeClaims[phase][msg.sender] == false,
            "You already claimed your free NFT during this phase."
        );

        freeClaims[phase][msg.sender] = true;
        internalMint();
        checkAftersalePhaseEnding();
    }

    function internalMint() internal {
        uint256 tokenId = tokenIdCounter.current();

        tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    /// @dev Ends the Presale phase if the presaleTokensLimit reached or time has come
    function checkPresalePhaseEnding() internal returns (bool) {
        if (
            nextTokenId() == presaleTokensLimit ||
            block.timestamp >= phaseStartTime + presaleTimeLimit
        ) {
            phase = Phase.PresaleEnd;
            phaseStartTime = block.timestamp;
            merkleRoot = 0;

            return true;
        } else {
            return false;
        }
    }

    /// @dev Ends the Sale phase if the totalTokens - aftersaleTokensCount reached.
    function checkSalePhaseEnding() internal {
        if (tokenIdCounter.current() == totalTokens - aftersaleTokensCount) {
            phase = Phase.Aftersale;
            phaseStartTime = block.timestamp;
            merkleRoot = 0;
        }
    }

    /// @dev Ends the Aftersale phase if all tokens sold out
    function checkAftersalePhaseEnding() internal {
        if (tokenIdCounter.current() == totalTokens) {
            phase = Phase.End;
            phaseStartTime = block.timestamp;
            merkleRoot = 0;
        }
    }

    /** ================== ENDOF INTERNAL FUNCTIONS ================== */

    /** ================== SERVICE FUNCTIONS ================== **/

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** ================== ENDOF SERVICE FUNCTIONS ================== */
}