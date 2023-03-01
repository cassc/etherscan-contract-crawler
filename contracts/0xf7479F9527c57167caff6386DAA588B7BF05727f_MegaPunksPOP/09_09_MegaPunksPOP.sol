// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721A} from "ERC721A/contracts/ERC721A.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

error ZeroBalance();
error ContractCaller();
error InvalidInput();
error InvalidMerkleProof();
error ExceedsMaxSupply();
error PublicSaleNotActive();
error AllowlistSaleNotActive();
error InvalidPayment();
error NotAllowedToMint();
error POPFrozen();
error noWithdrawAddress();
error alreadtMinted();
error minterNotSet();
error notMinter();

contract MegaPunksPOP is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MINT_PRICE = 0.042 ether;
    uint256 public constant MAX_SUPPLY = 10000;

    bytes32 public allowlistMerkleRoot;
    bool public publicSaleActive = false;
    bool public allowlistSaleActive = false;
    address public withdrawAddress;
    address public minterAddress;
    string public baseURI;
    string public contractURI;
    string public provenanceHash;
    bool public frozen = false;

    mapping(uint256 => string) public inscriptions;

    constructor(
        address _withdrawAddress,
        string memory _newBaseURI,
        string memory _contractURI,
        string memory _provenanceHash
    ) ERC721A("MegaPunksPOP", "MP") {
        withdrawAddress = _withdrawAddress;
        baseURI = _newBaseURI;
        contractURI = _contractURI;
        provenanceHash = _provenanceHash;
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) {
            revert ContractCaller();
        }
        _;
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function getAllowlistMintCount(address _address) public view returns (uint256) {
        return _getAux(_address);
    }

    function getInscription(uint256 _tokenId) public view returns (string memory) {
        return inscriptions[_tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    function setWithdrawAddress(address _newWithdrawAddress) public onlyOwner {
        if (_newWithdrawAddress == address(0)) revert InvalidInput();
        withdrawAddress = _newWithdrawAddress;
    }

    function setAllowlistSaleStatus(bool _allowlistSaleActive, bytes32 _allowlistMerkleRoot) public onlyOwner {
        if (frozen) revert POPFrozen();
        allowlistSaleActive = _allowlistSaleActive;
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function setPublicSaleStatus(bool _publicSaleActive) public onlyOwner {
        if (frozen) revert POPFrozen();
        allowlistSaleActive = false;
        publicSaleActive = _publicSaleActive;
    }

    function setMinter(address _minterAddress) public onlyOwner {
        minterAddress = _minterAddress;
    }

    function freeze() public onlyOwner {
        publicSaleActive = false;
        allowlistSaleActive = false;
        frozen = true;
    }

    function addInscriptions(uint256[] memory keys, string[] memory values) public onlyOwner {
        if (keys.length == 0) revert InvalidInput();
        for (uint256 i = 0; i < keys.length; i++) {
            inscriptions[keys[i]] = values[i];
            if (bytes(inscriptions[keys[i]]).length == 0) {}
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroBalance();
        if (withdrawAddress == address(0)) revert noWithdrawAddress();
        payable(withdrawAddress).transfer(balance);
    }

    function firstMint() public onlyOwner {
        if (totalSupply() > 0) revert alreadtMinted();
        _safeMint(msg.sender, 1);
    }

    function publicMint(uint256 _numTokens) public payable nonReentrant callerIsUser {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (_numTokens == 0) revert InvalidInput();
        if (msg.value != MINT_PRICE * _numTokens) revert InvalidPayment();
        if (totalSupply() + _numTokens > MAX_SUPPLY) revert ExceedsMaxSupply();

        _mint(msg.sender, _numTokens);
    }

    function publicMintTo(address _to, uint256 _numTokens) public payable nonReentrant {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (_numTokens == 0) revert InvalidInput();
        if (minterAddress == address(0)) revert minterNotSet();
        if (msg.value != MINT_PRICE * _numTokens) revert InvalidPayment();
        if (totalSupply() + _numTokens > MAX_SUPPLY) revert ExceedsMaxSupply();

        if (msg.sender != minterAddress) revert notMinter();

        _mint(_to, _numTokens);
    }

    function allowlistMint(uint256 _numTokens, uint256 allowance, bytes32[] calldata proof)
        public
        payable
        nonReentrant
        callerIsUser
    {
        if (!allowlistSaleActive) revert AllowlistSaleNotActive();
        if (_numTokens == 0) revert InvalidInput();
        if (msg.value != MINT_PRICE * _numTokens) revert InvalidPayment();
        if (totalSupply() + _numTokens > MAX_SUPPLY) revert ExceedsMaxSupply();

        bytes32 node = keccak256(abi.encodePacked(string(abi.encodePacked(msg.sender)), Strings.toString(allowance)));
        if (!MerkleProof.verify(proof, allowlistMerkleRoot, node)) revert InvalidMerkleProof();

        if (allowance < (_getAux(msg.sender)) + _numTokens) revert NotAllowedToMint();

        _setAux(msg.sender, (_getAux(msg.sender)) + uint64(_numTokens));

        _mint(msg.sender, _numTokens);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
    {
        if (frozen) revert POPFrozen();
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function approve(address to, uint256 tokenId) public payable override {
        if (frozen) revert POPFrozen();
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (frozen) revert POPFrozen();
        super.setApprovalForAll(operator, approved);
    }
}