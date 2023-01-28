// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract HangryHippoElite is ERC721, ReentrancyGuard, DefaultOperatorFilterer,Ownable {
    using Counters for Counters.Counter;
    mapping(address => bool) whitelistedAddresses;

    constructor(string memory customBaseURI_)
        ERC721("Hangy Hippo Elite", "HHE")
    {
        customBaseURI = customBaseURI_;
    }

    /** MINTING **/
    uint256 public constant MAX_SUPPLY = 555;
    uint256 public constant MAX_MULTIMINT = 555;
    uint256 public PRICE = 0;
    Counters.Counter private supplyCounter;

    function ownerMint(uint256 count) public onlyOwner payable nonReentrant {
        require(msg.value >= PRICE * count, "Insufficient payment");
        for (uint256 i = 0; i < count; i++) {
            _mint(msg.sender, nextMintId());
            supplyCounter.increment();
        }
    }

    function mint(uint256 count) public payable nonReentrant {
        require(saleIsActive, "Sale not active");
        require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");
        require(count <= MAX_MULTIMINT, "Mint at most 100 at a time");
        require(msg.value >= PRICE * count, "Insufficient payment");
        for (uint256 i = 0; i < count; i++) {
            _mint(msg.sender, nextMintId());
            supplyCounter.increment();
        }
    }

    function preMint(uint256 count)
        public
        payable
        isWhitelisted(msg.sender)
        nonReentrant
    {
        require(preSaleIsActive, "Sale not active");
        if (allowedMintCount(msg.sender) >= count) {
            updateMintCount(msg.sender, count);
        } else {
            revert("Minting limit exceeded");
        }
        require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");
        require(count <= 2, "Mint at most 2 at a time");
        require(msg.value >= PRICE * count, "Insufficient payment");
        for (uint256 i = 0; i < count; i++) {
            _mint(msg.sender, nextMintId());
            supplyCounter.increment();
        }
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    function nextMintId() public view returns (uint256) {
        return supplyCounter.current() + 1;
    }

    /** MINTING LIMITS **/
    mapping(address => uint256) private mintCountMap;
    mapping(address => uint256) private allowedMintCountMap;
    uint256 public constant MINT_LIMIT_PER_WALLET = 2;

    function allowedMintCount(address minter) public view returns (uint256) {
        return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
    }

    function updateMintCount(address minter, uint256 count) private {
        mintCountMap[minter] += count;
    }

    /** WHITELIST **/
    modifier isWhitelisted(address _address) {
        require(
            whitelistedAddresses[_address],
            "Whitelist: You need to be whitelisted"
        );
        _;
    }

    function addUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function verifyUser(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    /** ACTIVATION **/
    bool public saleIsActive = false;

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    bool public preSaleIsActive = false;

    function setPreSaleIsActive(bool preSaleIsActive_) external onlyOwner {
        preSaleIsActive = preSaleIsActive_;
    }

    /** URI HANDLING **/
    string private customBaseURI;
    mapping(uint256 => string) private tokenURIMap;

    function setTokenURI(uint256 tokenId, string memory tokenURI_)
        external
        onlyOwner
    {
        tokenURIMap[tokenId] = tokenURI_;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenURI_ = tokenURIMap[tokenId];
        if (bytes(tokenURI_).length > 0) {
            return tokenURI_;
        }
        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }

    /** PRICE & PAYOUT **/
    function setCurrentPrice(uint256 _PRICE) public onlyOwner {
        require(_PRICE > 0, "price must be greater than 0");
        PRICE = _PRICE;
    }

    function sendAll() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function sendTo(address _payee, uint256 _amount) public onlyOwner {
        require(
            _payee != address(0) && _payee != address(this),
            "pay is 0 or contract"
        );
        require(
            _amount > 0 && _amount <= address(this).balance,
            "amount is 0 or insufficiant!"
        );
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_payee), balance);
    }

    /** OPERATOR REGISTRY **/
    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}