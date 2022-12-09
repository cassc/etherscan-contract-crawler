// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PriceFeed.sol";
import "./Whitelist.sol";
import "./Error.sol";

contract DKeyNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721RoyaltyUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    CountersUpgradeable.Counter private _tokenIdCounter;

    string public baseURI;
    address public signer;
    address public treasuryAddress;
    uint256 public keyPrice;
    uint256 public minimumDNFTTokenRequire;
    uint256 public totalSold;
    uint256 public buyTime;

    IERC20 public BUSDToken;
    IERC721 public DNFTToken;
    address public priceFeed;

    mapping(address => uint256) public nonces;

    /*---------- CONSTANTS -----------*/
    uint256 public constant ONE_HUNDRED_PERCENT = 10000;
    uint256 public constant TAX_RATE = 800; // 8%

    /*---------- EVENTS -----------*/
    event RoyaltyChanged(uint256 _feeRate);
    event SignerChanged(address _signer);
    event BaseURIChanged(string _baseURI);
    event DNFTTokenChanged(address _dnftToken);
    event KeyPriceChanged(uint256 _keyPrice);
    event PriceFeedChanged(address _priceFeed);
    event TreasuryAddressChanged(address _treasuryAddress);
    event MinimumGalactixTokenRequireChanged(uint256 _minimumGalactixTokenRequire);
    event BuyWithBUSD(address _to, uint256 indexed _tokenId);
    event BuyWithBNB(address _to, uint256 indexed _tokenId);
    event BuyTimeChanged(uint256 _buyTime);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    function initialize(
        string memory baseURI_,
        address _signer,
        IERC20 _BUSDToken
    ) external initializer {
        __ERC721_init("Galactix Zone Maha Avian", "GMA");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __ReentrancyGuard_init();

        // Token ID starts from 1
        _tokenIdCounter.increment();

        /**
         * Network: BSC Mainnet
         * Aggregator: BUSD/BNB
         * Address: 0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941
         */
        priceFeed = 0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941;

        if (_signer == address(0)) revert ZERO_ADDRESS();
        if (address(_BUSDToken) == address(0)) revert ZERO_ADDRESS();

        baseURI = baseURI_;
        signer = _signer;
        BUSDToken = _BUSDToken;
    }

    /*---------- MODIFIERS -----------*/
    modifier hasTreasuryAddress() {
        if (treasuryAddress == address(0)) revert TREASURY_ADDRESS_NOT_SET();
        _;
    }

    /*---------- CONFIG FUNCTIONS -----------*/
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRoyalty(uint96 _feeRate) external hasTreasuryAddress onlyOwner {
        if (_feeRate > ONE_HUNDRED_PERCENT) revert INVALID_ROYALTY_FEE_RATE();
        _setDefaultRoyalty(treasuryAddress, _feeRate);
        emit RoyaltyChanged(_feeRate);
    }

    function setSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) revert ZERO_ADDRESS();
        signer = _signer;
        emit SignerChanged(_signer);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    function setDNFTToken(IERC721 _DNFTToken) external onlyOwner {
        if (address(_DNFTToken) == address(0)) revert ZERO_ADDRESS();
        DNFTToken = _DNFTToken;
        emit DNFTTokenChanged(address(_DNFTToken));
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        if (_treasuryAddress == address(0)) revert ZERO_ADDRESS();
        treasuryAddress = _treasuryAddress;
        emit TreasuryAddressChanged(_treasuryAddress);
    }

    function setMinimumDNFTTokenRequire(uint256 _minimumDNFTTokenRequire) external onlyOwner {
        minimumDNFTTokenRequire = _minimumDNFTTokenRequire;
        emit MinimumGalactixTokenRequireChanged(_minimumDNFTTokenRequire);
    }

    function setKeyPrice(uint256 _keyPrice) external onlyOwner {
        if (_keyPrice == 0) revert INVALID_KEY_PRICE();
        keyPrice = _keyPrice;
        emit KeyPriceChanged(_keyPrice);
    }

    function setPriceFeed(address _priceFeed) external onlyOwner {
        if (_priceFeed == address(0)) revert ZERO_ADDRESS();
        priceFeed = _priceFeed;
        emit PriceFeedChanged(_priceFeed);
    }

    function setBuyTime(uint256 _buyTime) external onlyOwner {
        if (_buyTime < block.timestamp) revert INVALID_BUY_TIME();
        buyTime = _buyTime;
        emit BuyTimeChanged(_buyTime);
    }

    /*---------- MINT FUNCTIONS -----------*/
    function buyUsingBUSD(address _buyer, bytes memory _signature)
        external
        whenNotPaused
        hasTreasuryAddress
        nonReentrant
    {
        if (block.timestamp < buyTime) revert NOT_YET_OPEN_FOR_SALE();
        if (keyPrice == 0) revert KEY_PRICE_NOT_SET();
        if (!verifySignature(_buyer, _signature)) revert INVALID_SIGNATURE();
        if (!canBuy(msg.sender)) revert CANNOT_BUY();

        uint256 BUSDBalance = BUSDToken.balanceOf(msg.sender);
        uint256 taxAmount = getTaxAmount(keyPrice);
        if (BUSDBalance < keyPrice + taxAmount) revert INSUFFICIENT_BUSD();

        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, keyPrice + taxAmount);
        uint256 tokenId = safeMint(msg.sender);
        totalSold++;
        nonces[msg.sender]++;

        emit BuyWithBUSD(msg.sender, tokenId);
    }

    function buyUsingBNB(address _buyer, bytes memory _signature)
        external
        payable
        whenNotPaused
        hasTreasuryAddress
        nonReentrant
    {
        if (block.timestamp < buyTime) revert NOT_YET_OPEN_FOR_SALE();
        if (keyPrice == 0) revert KEY_PRICE_NOT_SET();
        if (!verifySignature(_buyer, _signature)) revert INVALID_SIGNATURE();
        if (!canBuy(msg.sender)) revert CANNOT_BUY();

        uint256 priceInBNB = PriceFeed.convertBUSDToBNB(keyPrice, priceFeed);
        if (msg.value < priceInBNB) revert INSUFFICIENT_BNB();

        uint256 taxAmount = getTaxAmount(keyPrice);
        uint256 BUSDBalanceOfBuyer = BUSDToken.balanceOf(msg.sender);
        if (BUSDBalanceOfBuyer < taxAmount) revert INSUFFICIENT_BUSD();
        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, taxAmount);

        uint256 tokenId = safeMint(msg.sender);
        totalSold++;
        nonces[msg.sender]++;

        if (msg.value > priceInBNB) {
            Address.sendValue(payable(msg.sender), msg.value - priceInBNB);
            Address.sendValue(payable(treasuryAddress), priceInBNB);
        } else {
            Address.sendValue(payable(treasuryAddress), msg.value);
        }

        emit BuyWithBNB(msg.sender, tokenId);
    }

    /*---------- HELPER FUNCTIONS -----------*/
    function safeMint(address _to) private returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());
        return tokenId;
    }

    function canBuy(address _to) private view returns (bool) {
        return DNFTToken.balanceOf(_to) >= minimumDNFTTokenRequire;
    }

    function getTaxAmount(uint256 _priceInBUSD) public pure returns (uint256) {
        return (_priceInBUSD * TAX_RATE) / ONE_HUNDRED_PERCENT;
    }

    function verifySignature(address _buyer, bytes memory _signature) private view returns (bool) {
        if (msg.sender != _buyer) revert WRONG_CANDIDATE();
        return (Whitelist.verifySignatureWhenBuyKey(signer, nonces[_buyer], _buyer, _signature));
    }

    /*---------- OVERRIDE FUNCTIONS -----------*/
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable) whenNotPaused {
        uint256 taxAmount = getTaxAmount(keyPrice);
        if (BUSDToken.balanceOf(msg.sender) < taxAmount) revert INSUFFICIENT_BUSD();
        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, taxAmount);

        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) whenNotPaused {
        uint256 taxAmount = getTaxAmount(keyPrice);
        if (BUSDToken.balanceOf(msg.sender) < taxAmount) revert INSUFFICIENT_BUSD();
        BUSDToken.safeTransferFrom(msg.sender, treasuryAddress, taxAmount);

        super.transferFrom(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*---------- HOOKS -----------*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /*---------- GETTERS -----------*/
    function getAllTokenIdsOfAddress(address _address) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokenIds;
    }
}