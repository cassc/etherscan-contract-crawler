// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

///-------------------------------------------------------------------
///  __          ___          _____  __          ___
///  \ \        / / |        |_   _| \ \        / / |
///   \ \  /\  / /| |__   ___  | |  __\ \  /\  / /| |__   ___
///    \ \/  \/ / | '_ \ / _ \ | | / __\ \/  \/ / | '_ \ / _ \
///     \  /\  /  | | | | (_) || |_\__ \\  /\  /  | | | | (_) |
///      \/  \/   |_| |_|\___/_____|___/ \/  \/   |_| |_|\___/
///
///-------------------------------------------------------------------
///
/// wagmi

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./MultiConfirm.sol";

error WhoIsWho__ZeroMintAmount();
error WhoIsWho__MaxMint();
error WhoIsWho__InsufficientFunds();
error WhoIsWho__StageNotReady();
error WhoIsWho__InvalidProof();
error WhoIsWho__NonExistentTokenId();

contract WhoIsWho is ERC721A, MultiConfirm, Ownable, AccessControl, ReentrancyGuard {
    using Strings for uint256;

    enum SaleStage {
        IDLE,
        PRESALE_OG,
        PRESALE_WL,
        PUBLIC_SALE
    }

    ///////////////////////////////////////////////
    /// Constants
    //////////////////////////////////////////////

    /// Operator role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// Presale price for OG members
    uint256 public constant PRESALE_PRICE_OG = 0.02 ether;

    /// Presale price for whitelist members
    uint256 public constant PRESALE_PRICE_WL = 0.025 ether;

    /// Public sale price
    uint256 public constant PUBLIC_SALE_PRICE = 0.025 ether;

    /// Presale date - Friday, May 19, 2023 3:00 PM GMT
    uint64 public constant PRESALE_DATE = 1684508400;

    /// Public sale date - Friday, May 19, 2023 8:00 PM GMT
    uint64 public constant PUBLIC_SALE_DATE = 1684526400;

    /// Reveal date - Friday, May 26, 2023 8:00 PM
    uint64 public constant REVEAL_DATE = 1685131200;

    /// Total supply
    uint32 public constant TOTAL_SUPPLY = 5000;

    /// Interval for OG members to mint their token during presale
    uint32 public constant PRESALE_INTERVAL = 15 minutes;

    /// Number of reserved tokens
    uint16 public constant RESERVED_TOKENS = 50;

    /// Max number of tokens per OG wallet
    uint16 public constant PRESALE_MAX_TOKEN_PER_OG = 3;

    /// Max number of tokens per WL wallet
    uint16 public constant PRESALE_MAX_TOKEN_PER_WL = 2;

    /// Max number of tokens per WL wallet
    uint16 public constant PUBLIC_SALE_MAX_TOKEN = 5;

    ///////////////////////////////////////////////
    /// Storage
    //////////////////////////////////////////////

    /// Merkle roots for OG
    bytes32 public immutable ogMerkleRoot;

    /// Merkle roots for whitelist members
    bytes32 public immutable wlMerkleRoot;

    /// Metadata URI
    string private metadataBaseURI;

    /// Owner's balance during public sale
    mapping(address => uint256) public publicSaleBalances;

    /// Custom metadata URI for OG
    mapping(uint256 => string) public customMetadataURI;

    /// Custom metadata URI checker
    mapping(uint256 => bool) public isTokenHasCustomMetadataURI;

    ///////////////////////////////////////////////
    /// Events
    //////////////////////////////////////////////

    event SetCustomMetadataURI(uint256 indexed _token, string _uri);

    event SetMetadataBaseURI(string indexed _uri);

    event Withdraw(uint256 indexed _dateWithdrew, uint256 _amount);

    ///////////////////////////////////////////////
    /// Constructor
    //////////////////////////////////////////////

    constructor(
        address _owner,
        bytes32 _ogMerkleRoot,
        bytes32 _wlMerkleRoot,
        address[] memory _operators
    ) ERC721A("Who Is Who", "WhoIsWho") MultiConfirm(_operators) {
        ogMerkleRoot = _ogMerkleRoot;
        wlMerkleRoot = _wlMerkleRoot;

        for (uint256 i = 0; i < _operators.length; i++) {
            _grantRole(OPERATOR_ROLE, _operators[i]);
        }

        /// @dev Owner's address should be included in the operators array
        require(hasRole(OPERATOR_ROLE, _owner), "owner should be an operator");

        /// Transfer ownership
        _grantRole(OPERATOR_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _transferOwnership(_owner);

        /// Mint reserved tokens to the owner
        _safeMint(_owner, RESERVED_TOKENS + 1);
    }

    ///////////////////////////////////////////////
    /// Modifiers
    //////////////////////////////////////////////
    modifier stageCompliance(SaleStage _stage) {
        SaleStage stage = getSaleStage();
        if (
            (_stage == SaleStage.PRESALE_OG && stage != SaleStage.PRESALE_OG && stage != SaleStage.PRESALE_WL) ||
            (_stage != SaleStage.PRESALE_OG && stage != _stage)
        ) {
            revert WhoIsWho__StageNotReady();
        }
        _;
    }

    /**
     * @dev THIS MODIFIER SHOULD BE STRICTLY PLACED FIRST AMONG ALL OTHER RELATED
     * MINT COMPLIANCE MODIFIERS TO AVOID OVERFLOW ON THE `_mintAmount` VARIABLE.
     */
    modifier mintCompliance(uint256 _mintAmount, uint256 _maxTokenPerMint) {
        if (_mintAmount > _maxTokenPerMint) {
            revert WhoIsWho__MaxMint();
        }

        if (_mintAmount == 0) {
            revert WhoIsWho__ZeroMintAmount();
        }

        /**
         * @dev Overflow is impossible because `_mintAmount` is check first if it
         * is greater than `_maxTokenPerMint` and `_maxTokenPerMint` is static
         */
        unchecked {
            uint256 totalSupplyAfterMint = totalSupply() + _mintAmount;
            if (totalSupplyAfterMint > TOTAL_SUPPLY) {
                revert WhoIsWho__MaxMint();
            }
        }
        _;
    }

    modifier mintComplianceForPresale(uint256 _mintAmount, uint256 _presaleMaxTokenPerMint) {
        /**
         * @dev Overflow is impossible because `_mintAmount` is validated first in the
         * `mintCompliance` modifier
         */
        unchecked {
            uint256 totalBalanceAfterMint = balanceOf(_msgSender()) + _mintAmount;
            if (totalBalanceAfterMint > _presaleMaxTokenPerMint) {
                revert WhoIsWho__MaxMint();
            }
        }
        _;
    }

    modifier mintComplianceForPublicSale(uint256 _mintAmount) {
        /**
         * @dev Overflow is impossible because `_mintAmount` is validated first in the
         * `mintCompliance` modifier
         */
        unchecked {
            uint256 totalBalanceAfterMint = publicSaleBalances[_msgSender()] + _mintAmount;
            if (totalBalanceAfterMint > PUBLIC_SALE_MAX_TOKEN) {
                revert WhoIsWho__MaxMint();
            }
        }
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount, uint256 _price) {
        /**
         * @dev Overflow is impossible because `_mintAmount` is validated first in the
         * `mintCompliance` modifier
         */
        unchecked {
            uint256 totalCost = _price * _mintAmount;
            if (totalCost > msg.value) {
                revert WhoIsWho__InsufficientFunds();
            }
        }
        _;
    }

    ///////////////////////////////////////////////
    /// Public methods
    //////////////////////////////////////////////

    function ogMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        nonReentrant
        stageCompliance(SaleStage.PRESALE_OG)
        mintCompliance(_mintAmount, PRESALE_MAX_TOKEN_PER_OG)
        mintComplianceForPresale(_mintAmount, PRESALE_MAX_TOKEN_PER_OG)
        mintPriceCompliance(_mintAmount, PRESALE_PRICE_OG)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        if (!MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf)) {
            revert WhoIsWho__InvalidProof();
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function wlMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        nonReentrant
        stageCompliance(SaleStage.PRESALE_WL)
        mintCompliance(_mintAmount, PRESALE_MAX_TOKEN_PER_WL)
        mintComplianceForPresale(_mintAmount, PRESALE_MAX_TOKEN_PER_WL)
        mintPriceCompliance(_mintAmount, PRESALE_PRICE_WL)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        if (!MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf)) {
            revert WhoIsWho__InvalidProof();
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(
        uint256 _mintAmount
    )
        external
        payable
        nonReentrant
        stageCompliance(SaleStage.PUBLIC_SALE)
        mintCompliance(_mintAmount, PUBLIC_SALE_MAX_TOKEN)
        mintComplianceForPublicSale(_mintAmount)
        mintPriceCompliance(_mintAmount, PUBLIC_SALE_PRICE)
    {
        publicSaleBalances[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert WhoIsWho__NonExistentTokenId();
        }

        if (!isReveal()) {
            return hiddenTokenURI();
        }

        if (isTokenHasCustomMetadataURI[_tokenId]) {
            return customMetadataURI[_tokenId];
        }

        string memory currentBaseURI = _baseURI();

        if (bytes(currentBaseURI).length > 0) {
            return string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"));
        }

        return "";
    }

    function getSaleStage() public view returns (SaleStage stage) {
        uint256 timeNow = block.timestamp;

        if (timeNow >= PUBLIC_SALE_DATE) {
            return SaleStage.PUBLIC_SALE;
        }

        uint64 interval;

        /**
         * @dev Overflow is impossible because `presaleDate` is set by the admin and
         * `PRESALE_INTERVAL` is a constant
         */
        unchecked {
            /**
             * @dev Adding `PRESALE_INTERVAL` to the presale date, it means that the minting
             * timeframe for OG members has elapsed
             */
            interval = PRESALE_DATE + PRESALE_INTERVAL;
        }

        if (timeNow >= interval) {
            return SaleStage.PRESALE_WL;
        }

        /**
         * @notice During presale, OG members will have the first access to minting their
         * tokens, followed by whitelist members who can start minting only after a
         * specified time period defined in `PRESALE_INTERVAL`
         */
        if (timeNow >= PRESALE_DATE) {
            return SaleStage.PRESALE_OG;
        }

        return SaleStage.IDLE;
    }

    function getPublicSaleBalance(address _account) public view returns (uint256) {
        return publicSaleBalances[_account];
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.whoiswho.io/contractURI.json";
    }

    function hiddenTokenURI() public pure returns (string memory) {
        return "https://www.whoiswho.io/hidden.json";
    }

    ///////////////////////////////////////////////
    /// Internal methods
    //////////////////////////////////////////////

    function isReveal() internal view returns (bool) {
        return uint64(block.timestamp) >= REVEAL_DATE;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURI;
    }

    ///////////////////////////////////////////////
    /// Operator methods
    //////////////////////////////////////////////

    /// Allow operator to airdrop token in any sale stage
    function mint(address _recipient, uint256 _mintAmount) external payable onlyRole(OPERATOR_ROLE) {
        _safeMint(_recipient, _mintAmount);
    }

    /// Sets custom metadata URI for a specific token
    function setCustomMetadataURI(uint256 _token, string memory _uri) external onlyRole(OPERATOR_ROLE) {
        customMetadataURI[_token] = _uri;
        isTokenHasCustomMetadataURI[_token] = true;
        emit SetCustomMetadataURI(_token, _uri);
    }

    /// Sets token medata uri
    function setMetadataBaseURI(string memory _uri) external onlyRole(OPERATOR_ROLE) {
        metadataBaseURI = _uri;
        emit SetMetadataBaseURI(_uri);
    }

    function submitWithdrawTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyRole(OPERATOR_ROLE) stageCompliance(SaleStage.PUBLIC_SALE) {
        /// @inheritdoc `MultiConfirm.sol`
        _submitTransaction(_to, _value, _data);
    }

    function confirmWithdrawTransaction(
        uint256 _txIndex
    ) external onlyRole(OPERATOR_ROLE) stageCompliance(SaleStage.PUBLIC_SALE) {
        /// @inheritdoc `MultiConfirm.sol`
        _confirmTransaction(_txIndex);
    }

    function revokeConfirmation(
        uint256 _txIndex
    ) external onlyRole(OPERATOR_ROLE) stageCompliance(SaleStage.PUBLIC_SALE) {
        /// @inheritdoc `MultiConfirm.sol`
        _revokeConfirmation(_txIndex);
    }

    /** @notice The owner can withdraw the funds if the base uri is already set, approved
     *  by the approvers, and if it's already in the public sale stage
     */
    function withdraw(uint256 _txIndex) external onlyOwner stageCompliance(SaleStage.PUBLIC_SALE) {
        string memory currentBaseURI = _baseURI();
        require(bytes(currentBaseURI).length > 0, "Base URI not set");

        /// @inheritdoc `MultiConfirm.sol`
        _executeTransaction(_txIndex);
    }

    /// @dev Override `supportsInterface`
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}