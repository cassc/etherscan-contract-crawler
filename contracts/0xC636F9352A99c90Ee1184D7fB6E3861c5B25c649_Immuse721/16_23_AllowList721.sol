// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./MinterACLs.sol";
import "./OwnableRoyalties.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title Immuse721
 * Immuse721 - ERC721 contract that has limited quantity minting functionality.
 */
contract Immuse721 is
    DefaultOperatorFilterer,
    ERC721Enumerable,
    OwnableRoyalties,
    ReentrancyGuard,
    MinterACLs
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    mapping(address => uint256) private _successfulBuys;

    string baseURI;
    address proxyRegistryAddress;
    string contractURL;
    address public buyContract;
    address public payoutAddress;
    bytes32 public merkleRoot;
    uint256 private _requireAllowlist = 0;
    uint256 private _requirePerAddressLimit = 0;
    uint256 private _limitPerAddress = 1;

    uint256 private _startIndex = 0;

    uint256 public price = .015 ether;
    uint256 public paused = 1;
    uint256 public mintingEnabled = 1;
    uint256 public maxNFTs = 1;
    string public baseExtension = ".json";

    // Royality fee BPS (1/100ths of a percent, eg 1000 = 10%)
    uint16 private immutable _feeBps = 500;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _limit,
        address _proxyRegistryAddress,
        string memory _IPFSURL
    )
        ERC721(_name, _symbol)
        DefaultOperatorFilterer()
        OwnableRoyalties()
        MinterACLs()
    {
        proxyRegistryAddress = _proxyRegistryAddress;
        maxNFTs = _limit;
        setBaseURI(string(abi.encodePacked("ipfs://", _IPFSURL, "/")));
        setContractURI(
            string(abi.encodePacked("ipfs://", _IPFSURL, "/metadata.json"))
        );
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function allowlistMint(bytes32[] memory _proof) public payable {
        require(
            _requireAllowlist == 1 && isOnAllowlist(_proof, _msgSender()),
            "Unable to mint if not on the allowlist"
        );
        require(
            _requirePerAddressLimit == 0 ||
                (_requirePerAddressLimit != 0 &&
                    _successfulBuys[_msgSender()] < _limitPerAddress),
            "Already minted max"
        );
        _mint();
    }

    function publicMint() public payable {
        require(
            _requirePerAddressLimit == 0 ||
                (_requirePerAddressLimit != 0 &&
                    _successfulBuys[_msgSender()] < _limitPerAddress),
            "Already minted max"
        );
        require(
            _requireAllowlist == 0,
            "Unable to mint if not on the allowlist"
        );
        _mint();
    }

    function _mint() private {
        uint256 _id = _tokenId.current() + _startIndex;
        require(paused == 0, "Contract is currently paused.");
        require(mintingEnabled == 1, "Minting is not enabled for this yet.");
        require(this.totalSupply() < maxNFTs, "All have been minted.");
        require(msg.value >= price, "Not enough to pay for that.");

        _safeMint(_msgSender(), _id);
        emitRaribleInfo(_id);
        _tokenId.increment();
        _successfulBuys[_msgSender()] += 1;
    }

    function isOnAllowlist(bytes32[] memory _proof, address _claimer)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_claimer));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function pause(uint256 _state) public onlyOwner {
        paused = _state;
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        require(payoutAddress != address(0), "Payout address not set");
        (bool success, ) = payoutAddress.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setPayoutAddress(address _newPayoutAddress) public onlyOwner {
        payoutAddress = _newPayoutAddress;
    }

    function _payoutAddress() public view virtual returns (address) {
        return payoutAddress;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     * Update it with setProxyAddress
     */
    function setProxyAddress(address _a) public onlyOwner {
        proxyRegistryAddress = _a;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function setLimitPerAddress(uint256 _newLimit) public onlyOwner {
        _limitPerAddress = _newLimit;
    }

    function isAddressLimited() public view virtual returns (uint256) {
        return _requirePerAddressLimit;
    }

    function togglePerAddressLimit(uint256 _require) public onlyOwner {
        _requirePerAddressLimit = _require;
    }

    function toggleAllowlistRequired(uint256 _enabled) public onlyOwner {
        _requireAllowlist = _enabled;
    }

    function allStats() public view virtual returns (uint256, uint256) {
        uint256 remaining = maxNFTs - this.totalSupply();
        uint256 cost = price;
        return (cost, remaining);
    }

    function allowListRequired() public view virtual returns (uint256) {
        return _requireAllowlist;
    }

    function maxAmountMinted() public view virtual returns (uint256) {
        require(
            _requirePerAddressLimit == 0 ||
                (_requirePerAddressLimit != 0 &&
                    _successfulBuys[_msgSender()] < _limitPerAddress),
            "Already minted max"
        );
        return 0;
    }
}