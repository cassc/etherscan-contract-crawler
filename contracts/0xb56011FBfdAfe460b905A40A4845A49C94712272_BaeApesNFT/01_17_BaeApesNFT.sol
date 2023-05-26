// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/*
██████╗  █████╗ ███████╗     █████╗ ██████╗ ███████╗███████╗
██╔══██╗██╔══██╗██╔════╝    ██╔══██╗██╔══██╗██╔════╝██╔════╝
██████╔╝███████║█████╗      ███████║██████╔╝█████╗  ███████╗
██╔══██╗██╔══██║██╔══╝      ██╔══██║██╔═══╝ ██╔══╝  ╚════██║
██████╔╝██║  ██║███████╗    ██║  ██║██║     ███████╗███████║
╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

~ See you in Banana Coast!

Developed By: @richTheCreator
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract BaeApesNFT is ERC721, Ownable, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public baseURI;
    bytes32 public merklerootWL = 0;
    bytes32 public merklerootGifts = 0;
    uint256 public cost = 0.05 ether;
    uint256 public presaleCost = 0.03 ether;
    uint256 public maxPerWallet = 9;
    uint256 public maxPerTx = 3;
    uint256 public maxSupply = 5000;
    uint256 public reservedTokens = 125;

    Counters.Counter public _totalMinted;

    bool public saleActive = false;
    bool public presaleActive = false;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) private _addressMintedBalance;
    mapping(address => bool) private _giftsClaimed;

    address public proxyRegistryAddress;
    address[] public _team;

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) PaymentSplitter(_payees, _shares) {
        baseURI = _initBaseURI;
        _team = _payees;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // PUBLIC SALE MINT
    function mintBae(uint256 _mintAmount) public payable nonReentrant {
        uint256 ownerMintedCount = _addressMintedBalance[msg.sender];
        require(saleActive, "Sale must be active");
        require(
            _totalMinted.current() + _mintAmount <=
                (maxSupply - reservedTokens),
            "Exceeds max supply"
        );
        require(_mintAmount < maxPerTx + 1, "Exceeds max per transaction");
        require(
            ownerMintedCount + _mintAmount <= maxPerWallet,
            "Exceeds max per wallet"
        );
        require(msg.value == cost * _mintAmount, "Insufficient funds");
        delete ownerMintedCount;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _totalMinted.increment();
            _addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, _totalMinted.current());
        }
    }

    // WHITELIST MINT - VERIFIED VIA MERKLE PROOFS
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        uint256 ownerMintedCount = _addressMintedBalance[msg.sender];
        require(msg.value == presaleCost * _mintAmount, "Insufficient funds");
        require(presaleActive, "Sale must be active");
        require(
            _totalMinted.current() + _mintAmount <=
                (maxSupply - reservedTokens),
            "Exceeds max supply"
        );
        require(
            ownerMintedCount + _mintAmount < maxPerTx + 1,
            "Exceeds max for WL"
        );

        // Verify the address is on WL via merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merklerootWL, leaf),
            "Invalid Proof"
        );
        delete ownerMintedCount;
        delete leaf;
        // Mint WL
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _totalMinted.increment();
            _addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, _totalMinted.current());
        }
    }

    // CLAIM AND MINT NFT GIFTS - NON ADMIN
    function claimGift(uint256 _giftAmount, bytes32[] calldata _merkleProof)
        public
        nonReentrant
    {
        require(saleActive || presaleActive, "Sale must be active");
        require(!_giftsClaimed[msg.sender], "Address already claimed");
        require(_giftAmount <= reservedTokens, "Not enough reserve remaining");
        // Verify the address has gifts via merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _giftAmount));
        require(
            MerkleProof.verify(_merkleProof, merklerootGifts, leaf),
            "Invalid Proof"
        );
        delete leaf;
        reservedTokens = reservedTokens - _giftAmount;
        // Set Address to Claimed
        _giftsClaimed[msg.sender] = true;
        // Mint Gifts
        for (uint256 i = 1; i <= _giftAmount; i++) {
            _totalMinted.increment();
            _safeMint(msg.sender, _totalMinted.current());
        }
    }

    // CLAIM ALL REMAINING GIFTS FOR ADMIN TEAM
    function adminClaim() public onlyOwner {
        require(saleActive || presaleActive, "Sale must be active");
        require(reservedTokens != 0, "No reserved tokens");

        for (uint256 i = 1; i <= reservedTokens; i++) {
            _totalMinted.increment();
            _safeMint(msg.sender, _totalMinted.current());
        }
        reservedTokens = 0;
    }

    // RELEASE FUNDS VIA PAYMENTSPLITTER
    function releaseFunds() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            release(payable(_team[i]));
        }
    }

    //@dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json")); /// 0.json 135.json
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMerklerootWL(bytes32 root) public onlyOwner {
        merklerootWL = root;
    }

    function setMerklerootGifts(bytes32 root) public onlyOwner {
        merklerootGifts = root;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setMaxPerWallet(uint256 _limit) public onlyOwner {
        maxPerWallet = _limit;
    }

    function setMaxPerTx(uint256 _limit) public onlyOwner {
        maxPerTx = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}