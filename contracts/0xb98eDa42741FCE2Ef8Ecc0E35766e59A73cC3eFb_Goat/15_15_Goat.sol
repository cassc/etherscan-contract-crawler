// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Goat is ERC721Enumerable, Ownable {
    using Strings for uint256;

    enum Phases {
        PRIVATE, // Initial phase, private only
        WHITELIST, // Whitelist 1
        PUBLIC // Public Phase
    }

    Phases public phase = Phases.PRIVATE;

    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public MAX_MINT_PER_WALLET = 5;

    // 1000 USD in ChainLink Units
    uint256 internal USD_MINT_PRICE = 1_000 * 10**8;
    uint256 internal ETH_MINT_PRICE = 0 ether;

    mapping(uint256 => bytes32) public whitelistsMerkleRoot;
    mapping(address => uint256) public mintsPerAddress;

    address[] public teamPayments = [
        0x09Acb04ad16C1e5f3D0F5907A8Cf6fCF35148Cab,
        0x7F34a5a72Bd40c2A2fD28206877376fCE7D82c43,
        0x8E9c420c6f14b3e53d1E0942800D38eE5DD9C24C,
        0xA0e0Da37d657375Ac0Fc0e9C2a5d98277704D4cF,
        0x03c00c33F2c2c985CFe34c427819a5F99dE95767,
        0x3b4A185C9ca83D55d8496b49317fD829c4047345,
        0xB9AE558a877fFE47725A7e4DC40A47c33235F7c9,
        0xFd39AeA0C738C9b9150DBc273da88555F7e541c0,
        0xb1846FF6935ae167850C1c40B74D3FFcD239ce0d,
        0x2B561f5EfCDF71aE646EdC8B9042E4eF4Ea39c30,
        0x13F768615C233b63f78E85F254B91623B800100b
    ];

    uint256[] public teamPaymentShares = [
        100, // 10%
        50, // 5%
        30, // 3%
        20, // 2%
        20, // 2%
        10, // 1%
        10, // 1%
        300, // 30%
        100, // 10%
        300, // 30%
        60 // 6%
    ];

    string private baseURI;

    AggregatorV3Interface internal priceFeed;

    modifier noContracts(address account_) {
        uint256 size;
        assembly {
            size := extcodesize(account_)
        }
        require(size == 0, "caller-is-contract");
        _;
    }

    constructor() ERC721("GOAT Nation", "GOAT") {
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    function updateWhitelistMerkleRoot(Phases _phase, bytes32 _newMerkleRoot)
        external
        onlyOwner
    {
        whitelistsMerkleRoot[uint256(_phase)] = _newMerkleRoot;
    }

    function getCurrentMintPrice() external view returns (uint256) {
        return _getMintPrice();
    }

    function mintPrivate(
        uint256 _numberOfTokens,
        bytes32[] calldata merkleProof_
    ) external payable noContracts(msg.sender) {
        _whitelistedMint(Phases.PRIVATE, _numberOfTokens, merkleProof_);
    }

    function mintWhitelist(
        uint256 _numberOfTokens,
        bytes32[] calldata merkleProof_
    ) external payable noContracts(msg.sender) {
        _whitelistedMint(Phases.WHITELIST, _numberOfTokens, merkleProof_);
    }

    function mintPublic(uint256 _numberOfTokens)
        external
        payable
        noContracts(msg.sender)
    {
        require(phase == Phases.PUBLIC, "invalid-mint-phase");
        require(
            msg.value == _getMintPrice() * _numberOfTokens,
            "incorrect-ether-value"
        );
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
            "max-supply-reached"
        );
        require(
            mintsPerAddress[msg.sender] + _numberOfTokens <=
                MAX_MINT_PER_WALLET,
            "max-mint-limit"
        );

        mintsPerAddress[msg.sender] += _numberOfTokens;
        for (uint256 i; i < _numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function _whitelistedMint(
        Phases _phase,
        uint256 _numberOfTokens,
        bytes32[] calldata merkleProof_
    ) internal {
        // Private whitelist is always open (and free)
        if (_phase != Phases.PRIVATE) {
            require(_phase == phase, "invalid-mint-phase");
            require(
                msg.value == _getMintPrice() * _numberOfTokens,
                "incorrect-ether-value"
            );
        }
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
            "max-supply-reached"
        );
        require(
            mintsPerAddress[msg.sender] + _numberOfTokens <=
                MAX_MINT_PER_WALLET,
            "max-mint-limit"
        );

        bool isWhitelisted = MerkleProof.verify(
            merkleProof_,
            whitelistsMerkleRoot[uint256(_phase)],
            keccak256(abi.encodePacked(msg.sender))
        );

        require(isWhitelisted, "invalid-proof");

        mintsPerAddress[msg.sender] += _numberOfTokens;
        for (uint256 i; i < _numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function setFixedMintPrice(uint256 _newPrice) external onlyOwner {
        // Set this to 0 to enable chainlink feed
        // Set this > 0 to enable a fixed ETH price
        ETH_MINT_PRICE = _newPrice;
    }
    function setPhase(Phases newPhase_) external onlyOwner {
        phase = newPhase_;
    }

    function setBaseURI(string memory newURI_) external onlyOwner {
        baseURI = newURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId_.toString()));
    }

    function _getMintPrice() internal view returns (uint256 _price) {
        if (ETH_MINT_PRICE > 0) _price = ETH_MINT_PRICE;
        else {
            (
                ,
                /*uint80 roundID*/
                int256 _ethPrice,
                ,
                ,

            ) = /*uint startedAt*/
                /*uint timeStamp*/
                /*uint80 answeredInRound*/
                priceFeed.latestRoundData();

            _price = (USD_MINT_PRICE * 1e18) / uint256(_ethPrice);
        }
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        for (uint256 i = 0; i < teamPayments.length; i++) {
            uint256 _shares = (_balance / 1000) * teamPaymentShares[i];
            uint256 _currentBalance = address(this).balance;
            _shares = (_shares < _currentBalance) ? _shares : _currentBalance;
            payable(teamPayments[i]).transfer(_shares);
        }
    }
}