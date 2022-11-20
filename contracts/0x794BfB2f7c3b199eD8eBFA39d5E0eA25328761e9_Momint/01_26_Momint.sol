// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./Whitelist.sol";

import './operator-registry/DefaultOperatorFiltererUpgradeable.sol';

contract Momint is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // counter for generating IDs
    CountersUpgradeable.Counter private _tokenIdCounter;

    // whitelist contract
    Whitelist public whitelist;

    // treasury address
    // treasury can manage the funds of this contract
    address public treasury;

    // total capacity
    uint256 public CAPACITY;

    // mint price in wei ETH
    uint256 public MINT_PRICE;

    // how many passes can one single address mint
    uint256 public ADDRESS_ALLOWANCE;
    mapping (address => uint256) private addressMintCount;

    // base uri
    string public BASE_URI;

    // flags indicate the sale stage
    bool public preMint;
    bool public publicSale;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        Whitelist whitelistAddress,
        uint256 capacity, 
        uint256 mintPrice,
        uint256 addressAllowance,
        string calldata baseURI
    ) initializer public {
        __ERC721_init("Momint", "MOMI");
        __ERC721Enumerable_init();
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();

        require(
            address(whitelistAddress) != address(0),
            "Whitelist cannot be 0x0"
        );
        whitelist = whitelistAddress;

        require(
            capacity > 0,
            "Capacity must not be zero"
        );
        require(
            mintPrice > 0,
            "Mint price must not be zero"
        );
        require(
            addressAllowance > 0,
            "Address allowance must not be zero"
        );

        CAPACITY = capacity;
        MINT_PRICE = mintPrice;
        ADDRESS_ALLOWANCE = addressAllowance;
        BASE_URI = baseURI;

        // treasury is initially set to owner
        treasury = msg.sender;

        preMint = false;
        publicSale = false;
    }

    // -- owner methods

    function setWhitelist(Whitelist newWhitelist) external onlyOwner {
        require(
            address(newWhitelist) != address(0),
            "Whitelist cannot be 0x0"
        );
        whitelist = newWhitelist;
    }

    function startPreMint() external onlyOwner {
        require(
            !preMint && !publicSale,
            "Cannot start pre mint now"
        );
        preMint = true;
    }

    function startPublicSale() external onlyOwner {
        require(
            preMint && !publicSale,
            "Cannot start public sale now"
        );
        preMint = false;
        publicSale = true;
    }

    // -- treasury methods

    modifier onlyTreasury() {
        require(
            msg.sender == treasury,
            "Not treasury"
        );
        _;
    }

    function changeTreasury(address newTreasury) external onlyTreasury {
        require(
            newTreasury != address(0),
            "Treasury cannot be 0x0"
        );
        treasury = newTreasury;
    }

    function withdraw() external onlyTreasury {
        uint256 balance = address(this).balance;
        (bool sent, ) = treasury.call{value: balance}("");
        require(sent, "Failed to withdraw Ether");
    }

    // -- public methods

    // mint a new pass
    function mint() public payable {
        address sender = msg.sender;
        require(
            totalSupply() < CAPACITY,
            "Capacity reached"
        );
        require(
            addressMintCount[sender] < ADDRESS_ALLOWANCE,
            "Allowance per address reached"
        );
        require(
            preMint || publicSale,
            "Mint has not started yet"
        );

        if (preMint) {
            require(
                whitelist.inWhitelist(sender),
                "You are not in whitelist"
            );
        }

        require(
            msg.value == MINT_PRICE,
            "Bad deposit value"
        );

        uint256 tokenId = _tokenIdCounter.current() + 1;
        _tokenIdCounter.increment();
        addressMintCount[sender] += 1;
        _safeMint(sender, tokenId);
    }


    // for mint pass, all tokens have the same uri
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return _baseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // -- override methods for operator filter registry

    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        override(ERC721Upgradeable, IERC721Upgradeable) 
        onlyAllowedOperator(from) 
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public 
        override(ERC721Upgradeable, IERC721Upgradeable) 
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // -- internal methods

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}