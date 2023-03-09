// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";

contract FurryCrew is ERC721A, Ownable, RevokableDefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public maxSupply = 2222;
    uint256 public maxPublicSupply = 1778;
    uint256 public maxWhitelistSupply = 422;

    uint256 public maxPublicMintPerTx = 3;
    uint256 public maxWhitelistMintPerWallet = 1;

    uint256 public totalWhitelistMint = 0;
    uint256 public totalPublicMint = 0;

    uint256 public publicSalePrice = .0069 ether;
    uint256 public whitelistSalePrice = .0033 ether;

    bool public paused = true;

    string private baseTokenURI;
    string public hiddenTokenURI;

    bytes32 private merkleRoot;

    mapping(address => uint256) public claimedWhitelist;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerWalletReached();
    error MaxPerTxReached();
    error NotEnoughETH();
    error AlreadyMintedMore();
    error NotAllowedToMint();

    constructor(string memory _initHiddenTokenURI) ERC721A("Furry Crew", "FC") {
        hiddenTokenURI = _initHiddenTokenURI;
    }

    function mint(uint256 _amount) external payable {
        if (paused) revert SaleNotActive();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        if (totalPublicMint + _amount > maxPublicSupply)
            revert MaxSupplyReached();
        if (_amount > maxPublicMintPerTx) revert MaxPerTxReached();
        if (msg.value < publicSalePrice * _amount) revert NotEnoughETH();

        totalPublicMint += _amount;
        _mint(msg.sender, _amount);
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _amount)
        external
        payable
    {
        if (paused) revert SaleNotActive();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        if (totalWhitelistMint + _amount > maxWhitelistSupply)
            revert MaxSupplyReached();
        if (claimedWhitelist[msg.sender] + _amount > maxWhitelistMintPerWallet)
            revert MaxPerWalletReached();
        if (msg.value < whitelistSalePrice * _amount) revert NotEnoughETH();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf))
            revert NotAllowedToMint();

        claimedWhitelist[msg.sender] += _amount;
        totalWhitelistMint += _amount;
        _mint(msg.sender, _amount);
    }

    function reserveMint(address _to, uint256 _amount) external onlyOwner {
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        _mint(_to, _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(baseTokenURI, _tokenId.toString(), ".json")
                )
                : hiddenTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setHiddenTokenURI(string memory _hiddenTokenURI)
        external
        onlyOwner
    {
        hiddenTokenURI = _hiddenTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function releaseMint() external onlyOwner {
        maxPublicSupply = maxSupply;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply >= maxSupply) revert MaxSupplyReached();
        if (_totalMinted() > _maxSupply) revert AlreadyMintedMore();
        maxSupply = _maxSupply;
    }

    function setPublicPrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setWhitelistPrice(uint256 _whitelistSalePrice) external onlyOwner {
        whitelistSalePrice = _whitelistSalePrice;
    }

    function setMaxPublicMintPerTx(uint256 _maxPublicMintPerTx)
        external
        onlyOwner
    {
        maxPublicMintPerTx = _maxPublicMintPerTx;
    }

    function setMaxWhitelistMintPerWallet(uint256 _maxWhitelistMintPerWallet)
        external
        onlyOwner
    {
        maxWhitelistMintPerWallet = _maxWhitelistMintPerWallet;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}