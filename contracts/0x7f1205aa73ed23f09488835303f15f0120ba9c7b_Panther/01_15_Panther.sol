// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Panther is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal operators;

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner() || operators.contains(msg.sender),
            "invalid-caller"
        );
        _;
    }

    enum Phases {
        PRIVATE, // Initial phase, private only
        WHITELIST, // Whitelist
        PUBLIC // Public Phase
    }

    Phases public phase = Phases.PRIVATE;

    uint256 public MAX_SUPPLY = 1500;

    uint256 internal ETH_MINT_PRICE = 0.10 ether;

    mapping(uint256 => bytes32) public whitelistsMerkleRoot;
    mapping(address => uint256) public mintsPerAddress;
    mapping(uint256 => uint256) public maxMintPerWallet;

    address[] public teamPayments = [
        0x7c6db7315ad9a287a7445B780ECD544bc9e36491,
        0x09Acb04ad16C1e5f3D0F5907A8Cf6fCF35148Cab
    ];

    uint256[] public teamPaymentShares = [
        780, // 78%
        220 // 22%
    ];

    string private baseURI;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        maxMintPerWallet[uint256(Phases.PRIVATE)] = 3;
        maxMintPerWallet[uint256(Phases.WHITELIST)] = 3;
        maxMintPerWallet[uint256(Phases.PUBLIC)] = 5;
    }

    function updateWhitelistMerkleRoot(Phases _phase, bytes32 _newMerkleRoot)
        external
        onlyOwnerOrOperator
    {
        whitelistsMerkleRoot[uint256(_phase)] = _newMerkleRoot;
    }

    function getCurrentMintPrice() external view returns (uint256) {
        return _getMintPrice();
    }

    function mintPrivate(
        uint256 _numberOfTokens,
        bytes32[] calldata merkleProof_
    ) external payable {
        _whitelistedMint(Phases.PRIVATE, _numberOfTokens, merkleProof_);
    }

    function mintWhitelist(
        uint256 _numberOfTokens,
        bytes32[] calldata merkleProof_
    ) external payable {
        _whitelistedMint(Phases.WHITELIST, _numberOfTokens, merkleProof_);
    }

    function mintPublic(uint256 _numberOfTokens) external payable {
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
                maxMintPerWallet[uint256(Phases.PUBLIC)],
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
                maxMintPerWallet[uint256(_phase)],
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

    function setMaxSupply(uint256 _newSupply) external onlyOwnerOrOperator {
        require(_newSupply > totalSupply(), "invalid-max-supply");
        MAX_SUPPLY = _newSupply;
    }

    function setMaxMintPerWallet(Phases _phase, uint256 _maxMint)
        external
        onlyOwnerOrOperator
    {
        maxMintPerWallet[uint256(_phase)] = _maxMint;
    }

    function setFixedMintPrice(uint256 _newPrice) external onlyOwnerOrOperator {
        ETH_MINT_PRICE = _newPrice;
    }

    function setPhase(Phases newPhase_) external onlyOwnerOrOperator {
        phase = newPhase_;
    }

    function setBaseURI(string memory newURI_) external onlyOwnerOrOperator {
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

    function _getMintPrice() internal view returns (uint256) {
        return ETH_MINT_PRICE;
    }

    function addOperator(address _newOperator) external onlyOwner {
        operators.add(_newOperator);
    }

    function withdraw() external onlyOwnerOrOperator {
        uint256 _balance = address(this).balance;
        for (uint256 i = 0; i < teamPayments.length; i++) {
            uint256 _shares = (_balance / 1000) * teamPaymentShares[i];
            uint256 _currentBalance = address(this).balance;
            _shares = (_shares < _currentBalance) ? _shares : _currentBalance;
            payable(teamPayments[i]).transfer(_shares);
        }
    }
}