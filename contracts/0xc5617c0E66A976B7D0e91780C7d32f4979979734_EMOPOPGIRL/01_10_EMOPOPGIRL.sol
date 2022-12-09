// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 ████████ ████     ████   ███████     ███████    ███████   ███████      ████████  ██ ███████   ██
░██░░░░░ ░██░██   ██░██  ██░░░░░██   ░██░░░░██  ██░░░░░██ ░██░░░░██    ██░░░░░░██░██░██░░░░██ ░██
░██      ░██░░██ ██ ░██ ██     ░░██  ░██   ░██ ██     ░░██░██   ░██   ██      ░░ ░██░██   ░██ ░██
░███████ ░██ ░░███  ░██░██      ░██  ░███████ ░██      ░██░███████   ░██         ░██░███████  ░██
░██░░░░  ░██  ░░█   ░██░██      ░██  ░██░░░░  ░██      ░██░██░░░░    ░██    █████░██░██░░░██  ░██
░██      ░██   ░    ░██░░██     ██   ░██      ░░██     ██ ░██        ░░██  ░░░░██░██░██  ░░██ ░██
░████████░██        ░██ ░░███████    ░██       ░░███████  ░██         ░░████████ ░██░██   ░░██░████████
░░░░░░░░ ░░         ░░   ░░░░░░░     ░░         ░░░░░░░   ░░           ░░░░░░░░  ░░ ░░     ░░ ░░░░░░░░
**/

// Author: blacktanktop
// Twitter: https://twitter.com/black_tank_top

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";

contract EMOPOPGIRL is ERC721A, Ownable, DefaultOperatorFilterer{
    using Strings for uint256;

    string private baseURI = "";
    string constant private URI_SUFFIX = ".json";

    uint256 public preCost = 0.001 ether;
    uint256 public tsubasaCost = 0.003 ether;
    uint256 public publicCost = 0.003 ether;
    uint256 public publicMintMax = 30;
    uint256 constant public MAX_SUPPLY = 10000;

    bytes32 public merkleRootPreMint;
    bytes32 public merkleRootTsubasaMint;
    uint16 internal constant NOT_SALE_FLAG = 0;
    uint16 internal constant PRE_SALE_FLAG = 1;
    uint16 internal constant TSUBASA_SALE_FLAG = 2;  
    uint16 internal constant PUBLIC_SALE_FLAG = 3;
    uint16 public saleState = NOT_SALE_FLAG;
    mapping(address => uint256) private _preMintClaimed;
    mapping(address => uint256) private _tsubasaMintClaimed;
    mapping(address => uint256) private _publicMintClaimed;

    constructor() ERC721A("EMOPOPGIRL", "EPOP") {}

    // Only real humans can access
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Mint function
    function preMint(uint256 _mintAmount, uint256 _preMintMax, bytes32[] calldata _merkleProof)
        public
        payable
        callerIsUser
    {
        uint256 cost = preCost * _mintAmount;
        mintCheck(_mintAmount,  cost);
        require(saleState == PRE_SALE_FLAG, "PreSale is not open.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _preMintMax));
        require(
            MerkleProof.verify(_merkleProof, merkleRootPreMint, leaf),
            "Invalid Merkle Proof"
        );

        require(
            _preMintClaimed[msg.sender] + _mintAmount < _preMintMax + 1,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
        _preMintClaimed[msg.sender] += _mintAmount;
    }

    function tsubasaMint(uint256 _mintAmount, uint256 _tsubasaMintMax, bytes32[] calldata _merkleProof)
        public
        payable
        callerIsUser
    {
        uint256 cost = tsubasaCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(saleState == TSUBASA_SALE_FLAG, "TSUBASA SALE is not open.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tsubasaMintMax));
        require(
            MerkleProof.verify(_merkleProof, merkleRootTsubasaMint, leaf),
            "Invalid Merkle Proof"
        );
        require(
            _tsubasaMintClaimed[msg.sender] + _mintAmount < _tsubasaMintMax + 1,
            "Already claimed max"
        );
        _mint(msg.sender, _mintAmount);
        _tsubasaMintClaimed[msg.sender] += _mintAmount;
    }

    function publicMint(uint256 _mintAmount) public
        payable
        callerIsUser
    {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(saleState == PUBLIC_SALE_FLAG, "publicSale is not open.");
        require(
            _publicMintClaimed[msg.sender] + _mintAmount < publicMintMax + 1,
            "Already claimed max"
        );

        _mint(msg.sender, _mintAmount);
        _publicMintClaimed[msg.sender] += _mintAmount;
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 cost
    ) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(
            totalSupply() + _mintAmount < MAX_SUPPLY + 1,
            "MAXSUPPLY over"
        );
        require(msg.value >= cost, "Not enough funds");
    }

    // internal
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // view
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), URI_SUFFIX));
    }

    function getCurrentCost() public view returns (uint256) {
        if (saleState == PRE_SALE_FLAG) {
            return preCost;
        } else {
            return publicCost;
        }
    }

    function preMintAmount(address addr) public view returns (uint256) {
        return _preMintClaimed[addr];
    }

    function tsubasaMintAmount(address addr) public view returns (uint256) {
        return _tsubasaMintClaimed[addr];
    }

    function publicMintAmount(address addr) public view returns (uint256) {
        return _publicMintClaimed[addr];
    }

    function getSaleState() public view returns (uint256) {
        return saleState;
    }

    // onlyOwner
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRootPreMint(bytes32 _merkleRoot) external onlyOwner {
        merkleRootPreMint = _merkleRoot;
    }

    function setMerkleRootTsubasaMint(bytes32 _merkleRoot) external onlyOwner {
        merkleRootTsubasaMint = _merkleRoot;
    }

    function ownerMint(address _address, uint256 count) public onlyOwner {
       _mint(_address, count);
    }

    function inactivateSale() external onlyOwner {
        saleState = NOT_SALE_FLAG;
    }

    function activatePreSale() external onlyOwner {
        saleState = PRE_SALE_FLAG;
    }

    function activateTsubasaSale() external onlyOwner {
        saleState = TSUBASA_SALE_FLAG;
    }
    
    function activatePublicSale() external onlyOwner {
        saleState = PUBLIC_SALE_FLAG;
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setTsubasaCost(uint256 _tsubasaCost) public onlyOwner {
        tsubasaCost = _tsubasaCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setPublicMintMax(uint256 _publicMintMax) external onlyOwner {
        publicMintMax = _publicMintMax;
    }

    function withdrawTeamShare() external onlyOwner {
        uint256 sendBalance = address(this).balance;
        address artist = payable(0xAF9D23cD50177E03EBcE1A18B7c6aa2F9D155c06);
        address teamWallet = payable(0xFCe44742B4BB9d25534f8099dF81955013301E26);
        bool success;
        (success, ) = artist.call{value: (sendBalance * 900/1000)}("");
        require(success, "Failed to withdraw for artist");
        (success, ) = teamWallet.call{value: (sendBalance * 100/1000)}("");
        require(success, "Failed to withdraw for teamWallet");
    }

    // OpenSea operator-filter-registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
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

    // supportsInterface
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        return
            ERC721A.supportsInterface(interfaceId);
    }
}