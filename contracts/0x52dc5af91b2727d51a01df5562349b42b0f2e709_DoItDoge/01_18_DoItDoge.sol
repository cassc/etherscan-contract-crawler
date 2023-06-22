// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract DoItDoge is
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    bool public saleIsActive = false;
    bool public whitelistIsActive = false;
    string public baseTokenURI;
    bytes32 public merkleRoot;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT_TX = 10;
    uint256 public constant PUBLIC_PRICE = 0.025 ether;
    uint256 public constant WHITELIST_PRICE = 0.02 ether;

    mapping(address => uint256) private _whitelistAllowance;
    mapping(address => bool) public whitelistClaimed;

    constructor(
        string memory baseURI,
        bytes32 merkleTreeRoot
    ) ERC721A("DoItDoge", "DOITDOGE") {
        _safeMint(msg.sender, 5);
        _setDefaultRoyalty(msg.sender, 690);
        setMerkleRoot(merkleTreeRoot);
        setBaseURI(baseURI);
    }

    modifier whitelistIsOpen() {
        require(_totalMinted() < MAX_SUPPLY, "Sale end");
        require(whitelistIsActive, "Whitelist sale is not active");
        _;
    }

    modifier saleIsOpen() {
        require(_totalMinted() < MAX_SUPPLY, "Sale end");
        require(saleIsActive, "Sale is not active");
        _;
    }

    function setWhitelistActive(bool _whitelistIsActive) public onlyOwner {
        whitelistIsActive = _whitelistIsActive;
    }

    function setSaleActive(bool _saleIsActive) public onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function mintWhitelist(
        bytes32[] memory whitelistProof,
        uint256 grantedAmount,
        uint256 _tokenCount
    ) external payable whitelistIsOpen {
        uint256 userAllowance = getWhitelistAllowance(
            whitelistProof,
            msg.sender,
            grantedAmount
        );

        require(
            _tokenCount + _totalMinted() <= MAX_SUPPLY,
            "Exceeds max token supply"
        );
        require(msg.value >= whitelistPrice(_tokenCount), "Insufficient value");
        require(userAllowance > 0, "No whitelist allowance");
        require(_tokenCount <= userAllowance, "Exceeds whitelist allowance");

        _whitelistAllowance[msg.sender] = userAllowance - _tokenCount;
        whitelistClaimed[msg.sender] = true;

        _safeMint(msg.sender, _tokenCount);
    }

    function getWhitelistAllowance(
        bytes32[] memory whitelistProof,
        address Address,
        uint256 grantedAmount
    ) public view returns (uint256) {
        if (_whitelistAllowance[Address] != 0) {
            return _whitelistAllowance[Address];
        }
        
        if (!verifyWhitelist(whitelistProof, Address, grantedAmount)) {
            return 0;
        }
        
        if (whitelistClaimed[Address]) {
            return 0;
        }
        
        return grantedAmount;
    }

    function verifyWhitelist(
        bytes32[] memory proof,
        address whitelistAddress,
        uint256 grantedAmount
    ) public view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(whitelistAddress, grantedAmount)))
        );
        return (MerkleProof.verify(proof, merkleRoot, leaf));
    }

    function setMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setWhitelistAllowance(
        address[] calldata addresses,
        uint256 tokenAllowance
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistAllowance[addresses[i]] = tokenAllowance;
        }
    }

    function mintPublic(uint256 _tokenCount) external payable saleIsOpen {
        require(
            _totalMinted() + _tokenCount <= MAX_SUPPLY,
            "Exceeds max token supply"
        );
        require(
            _tokenCount <= MAX_PUBLIC_MINT_TX,
            "Exceeds max token count in 1 mint"
        );
        require(msg.value >= publicPrice(_tokenCount), "Insufficient value");

        _safeMint(msg.sender, _tokenCount);
    }

    function publicPrice(uint256 _tokenCount) public pure returns (uint256) {
        return PUBLIC_PRICE * _tokenCount;
    }

    function whitelistPrice(uint256 _tokenCount) public pure returns (uint256) {
        return WHITELIST_PRICE * _tokenCount;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}