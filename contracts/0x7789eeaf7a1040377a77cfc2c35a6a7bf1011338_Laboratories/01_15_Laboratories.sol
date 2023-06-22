// contracts/Laboratories.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract Laboratories is ERC721AQueryable, Ownable {
    // The collection is limited to 1000. +1 is used in order to save on gas
    uint256 private constant MAX_SUPPLY = 1001;

    uint256 private price = 0.1 ether;

    // +1 in order to save on gas
    uint256 private walletLimit = 2 + 1;

    bytes32 private root;

    string private tokenUri;

    enum SalePhase {
        LOCKED,
        PRIVATE,
        PUBLIC
    }

    SalePhase private salePhase = SalePhase.LOCKED;

    constructor(string memory _tokenUri)
        ERC721A("The Digital Pets Company", "LABORATORY")
    {
        tokenUri = _tokenUri;
    }

    function airdrop(address[] calldata _to, uint256[] calldata _quantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            require(
                _totalMinted() + _quantity[i] < MAX_SUPPLY,
                "Purchase would exceed max supply."
            );
            _safeMint(_to[i], _quantity[i]);
        }
    }

    function mint(uint256 _quantity) external onlyOwner checkSupply(_quantity) {
        _safeMint(msg.sender, _quantity);
    }

    function mintPrivate(uint256 _quantity, bytes32[] calldata _proof)
        external
        payable
        checkSupply(_quantity)
        checkSalePhase(SalePhase.PRIVATE)
        checkWalletLimit(msg.sender, _quantity, walletLimit)
        checkAllowlist(msg.sender, _proof)
        checkFunds(_quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    function mintPublic(uint256 _quantity)
        external
        payable
        checkSupply(_quantity)
        checkSalePhase(SalePhase.PUBLIC)
        checkWalletLimit(msg.sender, _quantity, walletLimit)
        checkFunds(_quantity)
    {
        _safeMint(msg.sender, _quantity);
    }

    function setTokenUri(string memory _tokenUri) external onlyOwner {
        tokenUri = _tokenUri;
    }

    function getTokenUri() external view returns (string memory) {
        return tokenUri;
    }

    function setSalePhase(SalePhase _salePhase) external onlyOwner {
        salePhase = _salePhase;
    }

    function getSalePhase() external view returns (SalePhase) {
        return salePhase;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function getRoot() external view returns (bytes32) {
        return root;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function setWalletLimit(uint256 _walletLimit) external onlyOwner {
        // +1 optimization to save on gas
        walletLimit = _walletLimit + 1;
    }

    function getWalletLimit() external view returns (uint256) {
        // -1 optimization to save on gas
        return walletLimit - 1;
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function createLeaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function verifyProof(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, root, _leaf);
    }

    function getMaxSupply() external pure returns (uint256) {
        // MAX_SUPPLY was increased by 1 in order to save on gas. We extract 1 to get real supply.
        return MAX_SUPPLY - 1;
    }

    modifier checkSupply(uint256 _quantity) {
        require(
            _totalMinted() + _quantity < MAX_SUPPLY,
            "Purchase would exceed max supply."
        );
        _;
    }

    modifier checkWalletLimit(
        address _account,
        uint256 _quantity,
        uint256 _limit
    ) {
        require(
            _numberMinted(_account) + _quantity < _limit,
            "Purchase would exceed wallet limit."
        );
        _;
    }

    modifier checkSalePhase(SalePhase _salePhase) {
        require(salePhase == _salePhase, "Wrong sale phase.");
        _;
    }

    modifier checkAllowlist(address _account, bytes32[] calldata _proof) {
        require(
            verifyProof(createLeaf(_account), _proof),
            "Allowlist verification failed."
        );
        _;
    }

    modifier checkFunds(uint256 _quantity) {
        require(_quantity * price == msg.value, "Invalid funds.");
        _;
    }

    /** OVERRIDES */
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}