// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract ProjectGatto is ERC721, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 666;
    uint256 private _currentId;
    uint256 public maxPerWallet = 5;

    string public baseURI;
    string private _contractURI;

    uint256 public publicPrice = 0.039 ether;
    uint256 public whitelistPrice = 0.026 ether;

    mapping(address => uint256) private _alreadyMinted;

    address signer = 0xb040BB7D3e65Ab76Fb5e77aCc810dFa86b124E01;

    bool public started;

    modifier onlyStarted() {
        require(started, "Sale hasn't started yet");
        _;
    }

    constructor(
        string memory _initialBaseURI,
        string memory _initialContractURI
    ) ERC721("Project Gatto", "Gatto") {
        baseURI = _initialBaseURI;
        _contractURI = _initialContractURI;
    }

    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }

    function setWhitelistPrice(uint256 _newPrice) external onlyOwner {
        whitelistPrice = _newPrice;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function currentSupply() external view returns (uint) {
        return _currentId;
    }

    function flipStart() external onlyOwner {
        started = !started;
    }

    function setMaxPerWallet(uint n) external onlyOwner {
        maxPerWallet = n;
    }

    // Accessors

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString()))
                : "";
    }

    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    // Metadata

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    // Minting

    function mintPublic(uint256 amount) external payable nonReentrant onlyStarted {
        require(
            _alreadyMinted[msg.sender] + amount <= maxPerWallet,
            "You have already minted the max amount"
        );
        require(msg.value == amount * publicPrice, "Incorrect payable amount");

        _alreadyMinted[msg.sender] += amount;
        _internalMint(msg.sender, amount);
    }

    function mintWL(uint256 amount, bytes calldata signature)
        external
        payable
        nonReentrant
        onlyStarted
    {
        require(_validateData(msg.sender, signature), "Invalid signature");
        require(
            _alreadyMinted[msg.sender] + amount <= maxPerWallet,
            "You have already minted the max amount"
        );
        require(
            msg.value == amount * whitelistPrice,
            "Incorrect payable amount"
        );

        _alreadyMinted[msg.sender] += amount;
        _internalMint(msg.sender, amount);
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _internalMint(to, amount);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _internalMint(address to, uint256 amount) private {
        require(
            _currentId + amount <= MAX_SUPPLY,
            "Will exceed maximum supply"
        );

        for (uint256 i = 1; i <= amount; i++) {
            _currentId++;
            _safeMint(to, _currentId);
        }
    }

    function _validateData(address _user, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        bytes32 dataHash = keccak256(abi.encodePacked(_user));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) && receivedAddress == signer);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}